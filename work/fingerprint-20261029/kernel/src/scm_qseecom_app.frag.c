/*
 * Legacy QSEECOM app management and a physical-address variant of app_send.
 *
 * The upstream helpers above assume the buffers live in the QSEECOM shared
 * memory pool (qcom_tzmem / shm bridge) and that the app was already loaded by
 * firmware. The Android-era QSEECOM ABI used by this device is older: the TA is
 * loaded from the non-secure world with QSEOS_APP_START_COMMAND and the data
 * region is described by a plain physical address.
 *
 * Call descriptors, from include/soc/qcom/qseecomi.h (Qualcomm's TZ syscall
 * encoding, SMC_ID = (owner << 24) | (svc << 8) | fn):
 *
 *   TZ_OS_APP_START_ID  = owner QSEE_OS(50), svc APP_MGR(1), fn 1
 *                         args (mdt_len, img_len, phys), all TZ type VAL
 *   TZ_OS_APP_SHUTDOWN_ID = same owner/svc, fn 2, args (app_id), VAL
 *   TZ_APP_QSAPP_SEND_DATA_ID = owner TZ_APPS(48), svc 0, fn 1,
 *                         args (app_id, req, req_len, rsp, rsp_len),
 *                         types (VAL, BUF_RW, VAL, BUF_RW, VAL)
 *   TZ_APP_QSAPP_SEND_DATA_WITH_WHITELIST_ID = same owner/svc, fn 6,
 *                         args + (sglist, sglist_len), extra BUF_RW
 */

/*
 * Último listener em que o TEE bloqueou (resp.data de um INCOMPLETE). Fica
 * visível para o módulo que chamou o send, que precisa responder ao pedido
 * para não deixar o TEE parado.
 */
u32 qcom_scm_qseecom_last_blocked_listener;
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_last_blocked_listener);

/*
 * Igual a qcom_scm_qseecom_call(), mas sem o WARN_ON para INCOMPLETE: aqui
 * INCOMPLETE é esperado (o TEE pede um listener e quem chama atende), então o
 * aviso só sujaria o log e marcaria o kernel como tainted a cada pedido.
 */
static int qcom_scm_qseecom_call_lstn(const struct qcom_scm_desc *desc,
				      struct qcom_scm_qseecom_resp *res)
{
	int status;

	mutex_lock(&qcom_scm_qseecom_call_lock);
	status = __qcom_scm_qseecom_call(desc, res);
	mutex_unlock(&qcom_scm_qseecom_call_lock);
	if (status)
		dev_err(__scm->dev, "qseecom: scm call failed with error %d\n",
			status);
	return status;
}

/**
 * qcom_scm_qseecom_app_start() - Load a QSEE app image into the secure world.
 * @image:    physical address of the image; the MDT header sits at the end
 *            of the buffer (segments first, then .mdt)
 * @mdt_len:  size of the MDT header
 * @img_len:  total size of the MDT header plus the segments
 * @app_id:   out, the id assigned by the secure world
 *
 * Returns: 0 on success, negative error code otherwise. A rejected image
 * (bad signature, app not permitted) surfaces as -EIO.
 */
int qcom_scm_qseecom_app_start(phys_addr_t image, size_t mdt_len,
			       size_t img_len, u32 *app_id)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
	desc.svc = QSEECOM_TZ_SVC_APP_MGR;
	desc.cmd = QSEECOM_TZ_CMD_APP_START;
	desc.arginfo = QCOM_SCM_ARGS(3, QCOM_SCM_VAL, QCOM_SCM_VAL,
				     QCOM_SCM_VAL);
	desc.args[0] = mdt_len;
	desc.args[1] = img_len;
	desc.args[2] = image;

	status = qcom_scm_qseecom_call(&desc, &res);
	if (status) {
		/*
		 * The secure world answers a duplicate load with its own error
		 * code; it is remapped here, so -EIO/-EINVAL both mean "not
		 * loaded by this call". The TA then stays loaded until reboot.
		 */
		return status;
	}

	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	/*
	 * TZ reports the new app id in the response (type QSEOS_APP_ID). This is
	 * the only reliable way to get it: the name lookup used by
	 * qcom_scm_qseecom_app_get_id() does not resolve apps loaded this way on
	 * this firmware.
	 */
	if (res.resp_type != QSEECOM_SCM_RES_APP_ID || !app_id)
		return -EPROTO;

	*app_id = res.data;
	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_start);

/**
 * qcom_scm_qseecom_app_shutdown() - Unload a QSEE app image.
 * @app_id: ID returned when the app was loaded.
 *
 * Returns: 0 on success, negative error code otherwise.
 */
int qcom_scm_qseecom_app_shutdown(u32 app_id)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
	desc.svc = QSEECOM_TZ_SVC_APP_MGR;
	desc.cmd = QSEECOM_TZ_CMD_APP_SHUTDOWN;
	desc.arginfo = QCOM_SCM_ARGS(1, QCOM_SCM_VAL);
	desc.args[0] = app_id;

	status = qcom_scm_qseecom_call(&desc, &res);
	if (status)
		return status;

	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_shutdown);

/**
 * qcom_scm_qseecom_app_send_phys() - Send to/receive from a QSEE app using
 * physical addresses.
 * @app_id:   ID of the target app.
 * @req:      physical address of the request buffer.
 * @req_size: size of the request buffer (64 B in the legacy ABI).
 * @rsp:      physical address of the response buffer.
 * @rsp_size: size of the response buffer (64 B in the legacy ABI).
 * @ta_result: out, SCM completion result (not the TA's response word).
 *
 * Same SCM call as qcom_scm_qseecom_app_send(), but the caller owns the
 * memory: it must be physically contiguous and TZ-visible (coherent DMA
 * allocations are). This is what the legacy ABI needs, because the TA is
 * handed the address of a separate "external region" through the request.
 *
 * Returns: 0 only for a completed SCM call; TA status is in @rsp. An
 * incomplete call (TEE waiting on a listener) returns -EOPNOTSUPP with the
 * listener id in qcom_scm_qseecom_last_blocked_listener; a listener-blocked
 * call returns -EBUSY.
 */
int qcom_scm_qseecom_app_send_phys(u32 app_id, phys_addr_t req, size_t req_size,
				   phys_addr_t rsp, size_t rsp_size,
				   u64 *ta_result)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_TZ_APPS;
	desc.svc = QSEECOM_TZ_SVC_APP_ID_PLACEHOLDER;
	desc.cmd = QSEECOM_TZ_CMD_APP_SEND;
	desc.arginfo = QCOM_SCM_ARGS(5, QCOM_SCM_VAL, QCOM_SCM_RW,
				     QCOM_SCM_VAL, QCOM_SCM_RW, QCOM_SCM_VAL);
	desc.args[0] = app_id;
	desc.args[1] = req;
	desc.args[2] = req_size;
	desc.args[3] = rsp;
	desc.args[4] = rsp_size;

	status = qcom_scm_qseecom_call(&desc, &res);
	if (status)
		return status;

	/* SCM completion is distinct from the TA status in its response buffer. */
	/*
	 * INCOMPLETE: o TEE parou à espera de um listener (id em res.data) e
	 * precisa de uma resposta. BLOCKED_ON_LISTENER é outra coisa (o listener
	 * está ocupado com outro app) e não se resolve respondendo.
	 */
	if (res.result == QSEECOM_RESULT_INCOMPLETE) {
		qcom_scm_qseecom_last_blocked_listener = res.data;
		return -EOPNOTSUPP;
	}
	if (res.result == QSEECOM_RESULT_BLOCKED_ON_LISTENER)
		return -EBUSY;
	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;
	if (ta_result)
		*ta_result = res.result;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_send_phys);

/**
 * qcom_scm_qseecom_app_send_phys_wl() - Send to a QSEE app with a whitelist.
 * @app_id:      ID of the target app.
 * @req:         physical address of the 64-byte request buffer.
 * @req_size:    size of the request buffer.
 * @rsp:         physical address of the 64-byte response buffer.
 * @rsp_size:    size of the response buffer.
 * @sglist:      physical address of the sglist table (struct sglist_info[]).
 * @sglist_len:  size of the table in bytes.
 * @ta_result:   out, SCM completion result (not the TA's response word).
 *
 * This is TZ_APP_QSAPP_SEND_DATA_WITH_WHITELIST_ID (owner TZ_APPS, svc 0,
 * function 0x06, seven arguments). Firmware that reports qseecom whitelist
 * support rejects the five-argument variant, and the sglist is what tells TZ
 * which out-of-band region the request refers to (a {phys,size} pair placed at
 * an offset inside the request buffer, here offset 4).
 *
 * Returns: 0 only for a completed SCM call; TA status is in @rsp. An
 * incomplete call (TEE waiting on a listener) returns -EOPNOTSUPP with the
 * listener id in qcom_scm_qseecom_last_blocked_listener; a listener-blocked
 * call returns -EBUSY.
 */
int qcom_scm_qseecom_app_send_phys_wl(u32 app_id, phys_addr_t req,
				      size_t req_size, phys_addr_t rsp,
				      size_t rsp_size, phys_addr_t sglist,
				      size_t sglist_len, u64 *ta_result)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_TZ_APPS;
	desc.svc = QSEECOM_TZ_SVC_APP_ID_PLACEHOLDER;
	desc.cmd = QSEECOM_TZ_CMD_APP_SEND_WL;
	desc.arginfo = QCOM_SCM_ARGS(7, QCOM_SCM_VAL, QCOM_SCM_RW,
				     QCOM_SCM_VAL, QCOM_SCM_RW,
				     QCOM_SCM_VAL, QCOM_SCM_RW,
				     QCOM_SCM_VAL);
	desc.args[0] = app_id;
	desc.args[1] = req;
	desc.args[2] = req_size;
	desc.args[3] = rsp;
	desc.args[4] = rsp_size;
	desc.args[5] = sglist;
	desc.args[6] = sglist_len;

	status = qcom_scm_qseecom_call_lstn(&desc, &res);
	if (status)
		return status;
	/*
	 * INCOMPLETE: o TEE parou à espera de um listener (id em res.data) e
	 * precisa de uma resposta. BLOCKED_ON_LISTENER é outra coisa (o listener
	 * está ocupado com outro app) e não se resolve respondendo.
	 */
	if (res.result == QSEECOM_RESULT_INCOMPLETE) {
		qcom_scm_qseecom_last_blocked_listener = res.data;
		return -EOPNOTSUPP;
	}
	if (res.result == QSEECOM_RESULT_BLOCKED_ON_LISTENER)
		return -EBUSY;
	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	if (ta_result)
		*ta_result = res.result;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_send_phys_wl);

/*
 * Serviço de listener (TZ owner QSEE_OS=50, svc LISTENER=2), conforme
 * include/soc/qcom/qseecomi.h:
 *   TZ_OS_REGISTER_LISTENER_ID    = (50, 2, 0x01)  args (VAL, BUF_RW, VAL)
 *   TZ_OS_DEREGISTER_LISTENER_ID  = (50, 2, 0x02)  args (VAL)
 *   TZ_OS_LISTENER_RESPONSE_HANDLER_ID = (50, 2, 0x03), args (VAL, VAL)
 */
#define QSEECOM_TZ_SVC_LISTENER			2
/* TZ_OS_REGISTER_LISTENER_SMCINVOKE_ID = (50, 2, 0x06) */
#define QSEECOM_TZ_CMD_LISTENER_REGISTER	6
#define QSEECOM_TZ_CMD_LISTENER_DEREGISTER	2
/* TZ_OS_LISTENER_RESPONSE_HANDLER_ID = (50, 2, 0x03) */
#define QSEECOM_TZ_CMD_LISTENER_RESP		3
/* TZ_OS_LISTENER_RESPONSE_HANDLER_WITH_WHITELIST_ID = (50, 2, 0x05) */
#define QSEECOM_TZ_CMD_LISTENER_RESP_WL		5

/**
 * qcom_scm_qseecom_listener_register() - Registra um serviço de listener.
 * @listener_id: id do serviço (RPMB = 0x2000, SSD = 0x3000)
 * @sb:          endereço físico do buffer compartilhado do listener
 * @sb_len:      tamanho desse buffer
 *
 * Depois de registrado, o TEE passa a poder devolver QSEOS_RESULT_INCOMPLETE
 * nas chamadas a apps que precisam de dados seguros, com o id em resp.data.
 *
 * Returns: 0 on success, negative error code otherwise.
 */
int qcom_scm_qseecom_listener_register(u32 listener_id, phys_addr_t sb,
				       size_t sb_len)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
	desc.svc = QSEECOM_TZ_SVC_LISTENER;
	desc.cmd = QSEECOM_TZ_CMD_LISTENER_REGISTER;
	desc.arginfo = QCOM_SCM_ARGS(3, QCOM_SCM_VAL, QCOM_SCM_RW,
				     QCOM_SCM_VAL);
	desc.args[0] = listener_id;
	desc.args[1] = sb;
	desc.args[2] = sb_len;

	status = qcom_scm_qseecom_call(&desc, &res);
	if (status)
		return status;

	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_listener_register);

/**
 * qcom_scm_qseecom_listener_resp() - Responde a um pedido de listener.
 * @listener_id: id do serviço que está respondendo
 * @rsp_status:  QSEOS_RESULT_SUCCESS (0) ou QSEOS_RESULT_FAILURE (0xffffffff)
 *
 * @sglist:      tabela sglist DO LISTENER (zerada quando ele não passa
 *               regiões extras); nunca a tabela do app que bloqueou
 * @sglist_len:  tamanho da tabela (SGLISTINFO_TABLE_SIZE = 32 B)
 *
 * A resposta desta chamada SCM é a continuação da resposta do app que ficou
 * bloqueado (__qseecom_process_incomplete_cmd do driver Qualcomm repete
 * enquanto vier INCOMPLETE).
 *
 * Returns: 0 quando o app terminou; -EOPNOTSUPP quando o TEE pediu de novo
 * um listener (id em qcom_scm_qseecom_last_blocked_listener); outro erro
 * negativo em falha.
 */
int qcom_scm_qseecom_listener_resp(u32 listener_id, u32 rsp_status,
				   phys_addr_t sglist, size_t sglist_len)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
	desc.svc = QSEECOM_TZ_SVC_LISTENER;
	desc.cmd = QSEECOM_TZ_CMD_LISTENER_RESP_WL;
	/* (VAL, VAL, BUF_RW, VAL) */
	desc.arginfo = QCOM_SCM_ARGS(4, QCOM_SCM_VAL, QCOM_SCM_VAL,
				     QCOM_SCM_RW, QCOM_SCM_VAL);
	desc.args[0] = listener_id;
	desc.args[1] = rsp_status;
	desc.args[2] = sglist;
	desc.args[3] = sglist_len;

	status = qcom_scm_qseecom_call_lstn(&desc, &res);
	if (status == -EINVAL) {
		/* firmware antigo: variante sem whitelist, (VAL, VAL) */
		memset(&res, 0, sizeof(res));
		memset(&desc, 0, sizeof(desc));
		desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
		desc.svc = QSEECOM_TZ_SVC_LISTENER;
		desc.cmd = QSEECOM_TZ_CMD_LISTENER_RESP;
		desc.arginfo = QCOM_SCM_ARGS(2, QCOM_SCM_VAL, QCOM_SCM_VAL);
		desc.args[0] = listener_id;
		desc.args[1] = rsp_status;
		status = qcom_scm_qseecom_call_lstn(&desc, &res);
	}
	if (status)
		return status;

	if (res.result == QSEECOM_RESULT_INCOMPLETE) {
		qcom_scm_qseecom_last_blocked_listener = res.data;
		return -EOPNOTSUPP;
	}
	if (res.result == QSEECOM_RESULT_BLOCKED_ON_LISTENER)
		return -EBUSY;
	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_listener_resp);

/**
 * qcom_scm_qseecom_listener_deregister() - Remove um serviço de listener.
 * @listener_id: id registrado antes com qcom_scm_qseecom_listener_register()
 *
 * TZ_OS_DEREGISTER_LISTENER_ID = (50, 2, 0x02), args (VAL). Só pode ser
 * chamado com nenhum app bloqueado neste listener.
 *
 * Returns: 0 on success, negative error code otherwise.
 */
int qcom_scm_qseecom_listener_deregister(u32 listener_id)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
	desc.svc = QSEECOM_TZ_SVC_LISTENER;
	desc.cmd = QSEECOM_TZ_CMD_LISTENER_DEREGISTER;
	desc.arginfo = QCOM_SCM_ARGS(1, QCOM_SCM_VAL);
	desc.args[0] = listener_id;

	status = qcom_scm_qseecom_call(&desc, &res);
	if (status)
		return status;

	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_listener_deregister);

/**
 * qcom_scm_qseecom_app_region_notify() - Tell the secure world about the
 * region reserved for secure apps.
 * @addr: physical base of the region
 * @size: size of the region
 *
 * TZ_OS_APP_REGION_NOTIFICATION_ID (owner QSEE_OS, svc APP_MGR, fn 5). The
 * Android driver issues this from qseecom_probe() unless the firmware
 * bootloader already did it (qcom,appsbl-qseecom-support).
 *
 * Returns: 0 on success, negative error code otherwise.
 */
int qcom_scm_qseecom_app_region_notify(phys_addr_t addr, size_t size)
{
	struct qcom_scm_qseecom_resp res = {};
	struct qcom_scm_desc desc = {};
	int status;

	desc.owner = QSEECOM_TZ_OWNER_QSEE_OS;
	desc.svc = QSEECOM_TZ_SVC_APP_MGR;
	desc.cmd = QSEECOM_TZ_CMD_APP_REGION_NOTIFY;
	desc.arginfo = QCOM_SCM_ARGS(2, QCOM_SCM_RW, QCOM_SCM_VAL);
	desc.args[0] = addr;
	desc.args[1] = size;

	status = qcom_scm_qseecom_call(&desc, &res);
	if (status)
		return status;

	if (res.result != QSEECOM_RESULT_SUCCESS)
		return -EIO;

	return 0;
}
EXPORT_SYMBOL_GPL(qcom_scm_qseecom_app_region_notify);
