// SPDX-License-Identifier: GPL-2.0-only
/*
 * qseecom-fpc - minimal legacy QSEECOM transport for TAs loaded by HLOS.
 *
 * Why this exists: the mainline QSEECOM support (drivers/firmware/qcom/
 * qcom_qseecom.c) only talks to apps that the firmware bootloader already
 * loaded (qcom.tz.uefisecapp) on machines listed in an allowlist. The FPC
 * fingerprint TA on the Motorola hanoip (fpctzapp) is *not* preloaded: Android
 * loads it at boot with QSEOS_APP_START_COMMAND and then talks to it with
 * 64-byte control blocks plus one out-of-band data region described by a
 * physical address patched into the control block.
 *
 * This driver exposes exactly that: load an image, then send/receive. It knows
 * nothing about fingerprints and never parses TA payloads.
 *
 * Layout of the data region as seen by the TA (documented in
 * docs/kernel/PROTOCOLO-FPC-TA-20261029.md):
 *   external region starts with {u32 module_id, u32 command_id}; the rest is
 *   per module. The control block is {u32 region_len, u32 region_phys} plus
 *   zeros; the response block's first word is the TEE status.
 *
 * Buffers are allocated with dma_alloc_coherent() so the secure world always
 * sees the same bytes the CPU wrote (the legacy downstream driver needed
 * explicit cache maintenance; coherent memory makes that unnecessary).
 *
 * Listeners (RPMB/SSD) are only registered for the duration of one send. The
 * RPMB listener (0x2000) is served in-kernel through the UFS RPMB W-LUN, with
 * the same request/response layout as Qualcomm's librpmb; writes are refused
 * unless rpmb_writes=1. Keymaster and disk encryption are not implemented.
 */

#include <linux/dma-mapping.h>
#include <linux/firmware/qcom/qcom_scm.h>
#include <linux/fs.h>
#include <linux/io.h>
#include <linux/slab.h>
#include <linux/gfp.h>
#include <linux/mm.h>
#include <linux/miscdevice.h>
#include <linux/module.h>
#include <linux/mutex.h>
#include <linux/platform_device.h>
#include <linux/slab.h>
#include <linux/uaccess.h>
#include <linux/unaligned.h>
#include <scsi/scsi_device.h>
#include <scsi/scsi_host.h>
#include <scsi/scsi_proto.h>
#include <ufs/ufshcd.h>

#include <uapi/misc/qseecom-fpc.h>

#define QSEECOM_FPC_NAME	"qseecom-fpc"
#define QSEECOM_FPC_APP		"fpctzapp"

/*
 * Whitelist support in the firmware changes the send contract: the caller must
 * describe every out-of-band region in a table of {indexAndFlags, sizeOrCount}
 * entries. Bit 31 means "one physical address", bit 30 means 64-bit, and the
 * low bits are the offset inside the request buffer where that address sits.
 */
#define QSEECOM_SGLIST_MAX	4	/* MAX_ION_FD in the Android driver */
#define QSEECOM_SG_SINGLE_32BIT	0x80000000u
#define QSEECOM_SG_ADDR_OFFSET	4	/* control[4] = region physical address */

/*
 * The secure world only touches memory it knows about. On this board the
 * reserved "qseecom" carveout (0x9e400000, 20 MiB in sm7150.dtsi) is the
 * region the firmware was configured with, so the buffers must live there.
 * Set carveout_phys=0 to fall back to coherent allocations (kept for boards
 * where plain RAM works).
 */
static unsigned long carveout_phys;
module_param(carveout_phys, ulong, 0444);
MODULE_PARM_DESC(carveout_phys, "physical base of the QSEECOM carveout (0 = use dma_alloc_coherent)");

static unsigned long carveout_size = 0x1400000;
module_param(carveout_size, ulong, 0444);
MODULE_PARM_DESC(carveout_size, "size of the QSEECOM carveout");

/*
 * Region reserved for secure apps. Android's qseecom driver announces it once
 * at probe (see qseecom_probe) unless the bootloader already did. The mainline
 * device tree has no qseecom node, so nothing announces it -- do it here.
 * 0 disables the notification.
 *
 * Padrão 0: neste aparelho o ABL já anunciou a região (o TEE recusa com
 * -22) e forçar 0x86d00000 travou o aparelho, porque essa faixa é RAM do
 * kernel aqui. Só ligar em outra placa e sabendo o que faz.
 */
static unsigned long region_phys;
module_param(region_phys, ulong, 0444);
MODULE_PARM_DESC(region_phys, "physical base of the secure-app region (0 = skip)");

static unsigned long region_size = 0x2200000;
module_param(region_size, ulong, 0444);
MODULE_PARM_DESC(region_size, "size of the secure-app region");

/*
 * Android hands the TEE a *cached* ION buffer and does explicit cache
 * maintenance around the call; coherent (non-cached) memory is rejected by the
 * TEE shared-buffer registration. Keep both paths for A/B testing.
 */
static unsigned int frame_size = QSEECOM_FPC_MAX_FRAME;
module_param(frame_size, uint, 0444);
MODULE_PARM_DESC(frame_size, "size of the data region in bytes");

static unsigned int frame_cached;
module_param(frame_cached, uint, 0644);
MODULE_PARM_DESC(frame_cached, "0=coherent, 1=normal pages (cached), 2=CMA non-coherent (cached)");

/* Diagnóstico: força o endereço/tamanho da região passada ao TEE. */
static unsigned long force_region_phys;
module_param(force_region_phys, ulong, 0644);
MODULE_PARM_DESC(force_region_phys, "override the region address in the control block");

static unsigned int force_region_size;
module_param(force_region_size, uint, 0644);
MODULE_PARM_DESC(force_region_size, "override the region size in the control block (0 = keep)");

static bool debug_send;
module_param(debug_send, bool, 0644);
MODULE_PARM_DESC(debug_send, "poison the response buffer and log what comes back");

static bool use_whitelist = true;
module_param(use_whitelist, bool, 0644);
MODULE_PARM_DESC(use_whitelist,
		 "use the whitelist send variant (needed on firmware with whitelist support)");

/*
 * Serviço de listener do TEE. 0 = desligado. 0x2000 = RPMB, 0x3000 = SSD.
 * O registro vive SÓ dentro de um send: registrar -> enviar -> responder a
 * cada INCOMPLETE -> desregistrar. Um listener registrado e ocioso deixa o
 * TEE esperando por quem nunca atende, e o watchdog reinicia o aparelho
 * (incidente de 29/10). O RPMB (0x2000) é atendido aqui mesmo, pelo W-LUN
 * do UFS; qualquer outro id recebe FAILURE.
 */
static unsigned int listener_id;
module_param(listener_id, uint, 0444);
MODULE_PARM_DESC(listener_id,
		 "TEE listener service id to register (0x2000 = RPMB, 0 = off)");

static unsigned int listener_size = 0x8000;
module_param(listener_size, uint, 0444);
MODULE_PARM_DESC(listener_size, "shared buffer size for the listener service");

/*
 * Escrever no RPMB muda o estado seguro do TEE, que é o MESMO do Android
 * (Gatekeeper/Keymaster). Desligado, todo pedido de escrita do TEE recebe
 * erro sem tocar o dispositivo. PROGRAM_KEY é recusado sempre.
 */
static bool rpmb_writes;
module_param(rpmb_writes, bool, 0444);
MODULE_PARM_DESC(rpmb_writes,
		 "let the TEE write authenticated RPMB frames (default: refuse)");

static unsigned int rpmb_host;
module_param(rpmb_host, uint, 0444);
MODULE_PARM_DESC(rpmb_host, "SCSI host number of the UFS controller");

static bool listener_in_carveout;
module_param(listener_in_carveout, bool, 0444);
MODULE_PARM_DESC(listener_in_carveout,
		 "put the listener buffer in the qseecom carveout (default: normal memory)");

struct qseecom_fpc {
	struct device *dev;
	struct miscdevice misc;
	struct mutex lock;	/* serialises the single open file */
	void *ctrl;		/* 64 B request + 64 B response, coherent */
	dma_addr_t ctrl_phys;
	void *frame;		/* out-of-band data region */
	dma_addr_t frame_phys;
	size_t frame_len;
	void *sglist;		/* whitelist table */
	dma_addr_t sglist_phys;
	size_t sglist_len;
	void __iomem *carveout;	/* set when carveout_phys is used */
	void *bounce;		/* cached staging buffer for the carveout */
	unsigned int slot;	/* rotaciona a região dentro do carveout */
	void *lbuf;		/* buffer compartilhado do listener */
	phys_addr_t lphys;
	bool lbuf_coherent;	/* alocado com dma_alloc_coherent */
	void *lsglist;		/* tabela sglist do listener, sempre zerada */
	dma_addr_t lsglist_phys;
	void *image;		/* carveout image slot */
	dma_addr_t image_phys;
	size_t image_len;
	u32 app_id;
	bool app_loaded;
	bool open;
};

/* Carveout layout: 0x0000 control, 0x1000 sglist, 0x10000 image, frame after. */
#define QSEECOM_CV_CTRL		0x000000
#define QSEECOM_CV_SGLIST	0x001000
#define QSEECOM_CV_IMAGE	0x010000
#define QSEECOM_CV_FRAME	0x400000
#define QSEECOM_CV_LISTENER	0xC00000	/* depois dos 8 slots de frame */

/*
 * Limite de idas e voltas INCOMPLETE por send. O driver Qualcomm não tem
 * limite; aqui ele só existe para não girar para sempre se o TEE insistir.
 */
#define QSEECOM_LISTENER_MAX_ROUNDS	64

#define QSEOS_RESULT_FAILURE		0xffffffffu

static int qseecom_fpc_load(struct qseecom_fpc *q, void __user *uarg)
{
	struct qseecom_fpc_load arg;
	void *image;
	dma_addr_t image_phys;
	int ret;

	if (copy_from_user(&arg, uarg, sizeof(arg)))
		return -EFAULT;

	if (!arg.image || arg.image_len < arg.mdt_len || !arg.mdt_len)
		return -EINVAL;
	if (arg.image_len > QSEECOM_FPC_MAX_IMAGE)
		return -EINVAL;
	if (q->app_loaded)
		return -EBUSY;

	/*
	 * The TA is a 32-bit app: every buffer it is handed must live below
	 * 4 GiB, otherwise the secure world refuses the call.
	 */
	/*
	 * The app image itself must come from normal memory: loading from the
	 * carveout is rejected by the secure world. Only the shared data region
	 * has to live there.
	 */
	image = dma_alloc_coherent(q->dev, arg.image_len, &image_phys,
				   GFP_KERNEL | GFP_DMA32);
	if (!image)
		return -ENOMEM;

	ret = copy_from_user(image, u64_to_user_ptr(arg.image), arg.image_len);
	if (ret) {
		ret = -EFAULT;
		goto out_free;
	}

	/*
	 * The legacy SCM call takes (mdt_len, img_len, phys); the buffer layout
	 * expected by TZ is [.mdt][b00..bNN] and img_len covers both.
	 */
	ret = qcom_scm_qseecom_app_start(image_phys, arg.mdt_len,
					 arg.image_len, &q->app_id);
	if (ret)
		goto out_free;

	q->app_loaded = true;
	arg.app_id = q->app_id;

	if (copy_to_user(uarg, &arg, sizeof(arg)))
		ret = -EFAULT;

out_free:
	/* The secure world copies the image in; the HLOS buffer is not needed. */
	dma_free_coherent(q->dev, arg.image_len, image, image_phys);
	return ret;
}

/*
 * Serviço RPMB (listener 0x2000), no formato do librpmb.so do Android
 * (rpmb_start, rpmb_ufs_read/write; work/fingerprint-20261029/listener/).
 * O pedido fica no início do buffer do listener:
 *   {cmd, num_sectors, req_buff_len, req_buff_offset, version, rel_wr_count}
 * e a resposta é escrita por cima: {cmd, status, res_buff_len, res_off=0x14},
 * com os dados a partir de +0x14. Os frames chegam já assinados pelo TEE; o
 * mundo normal só os transporta (SECURITY PROTOCOL OUT/IN, protocolo 0xEC).
 */
#define TZ_RPMB_INIT		0x101
#define TZ_RPMB_READ		0x102
#define TZ_RPMB_WRITE		0x103
#define TZ_RPMB_PARTITION	0x104
#define TZ_RPMB_RSP_OFF		0x14
#define TZ_RPMB_DEV_UFS		9

#define RPMB_FRAME_LEN		512
#define RPMB_WLUN		49476	/* scsi_device 0:0:0:49476 */
#define RPMB_SEC_PROTOCOL	0xec
#define RPMB_SPSP		0x0001	/* região 0 */

#define RPMB_REQ_GET_COUNTER	0x0002
#define RPMB_REQ_WRITE_DATA	0x0003
#define RPMB_REQ_READ_DATA	0x0004
#define RPMB_REQ_RESULT_READ	0x0005

static u16 rpmb_frame_req(const u8 *frame)
{
	return get_unaligned_be16(frame + RPMB_FRAME_LEN - 2);
}

static int rpmb_sec_cmd(struct scsi_device *sdev, void *buf, u32 len,
			bool out)
{
	u8 cdb[12] = { };
	int ret = 0, tries;

	cdb[0] = out ? SECURITY_PROTOCOL_OUT : SECURITY_PROTOCOL_IN;
	cdb[1] = RPMB_SEC_PROTOCOL;
	put_unaligned_be16(RPMB_SPSP, &cdb[2]);
	put_unaligned_be32(len, &cdb[6]);

	/* librpmb tenta 3 vezes (com REQUEST SENSE entre elas). */
	for (tries = 0; tries < 3; tries++) {
		ret = scsi_execute_cmd(sdev, cdb,
				       out ? REQ_OP_DRV_OUT : REQ_OP_DRV_IN,
				       buf, len, 30 * HZ, 0, NULL);
		if (!ret)
			return 0;
	}
	return ret < 0 ? ret : -EIO;
}

static struct scsi_device *rpmb_get_sdev(struct qseecom_fpc *q)
{
	struct Scsi_Host *shost = scsi_host_lookup(rpmb_host);
	struct scsi_device *sdev;

	if (!shost) {
		dev_err(q->dev, "rpmb: SCSI host %u não existe\n", rpmb_host);
		return NULL;
	}
	sdev = scsi_device_lookup(shost, 0, 0, RPMB_WLUN);
	scsi_host_put(shost);
	if (!sdev)
		dev_err(q->dev, "rpmb: W-LUN %u não existe\n", RPMB_WLUN);
	return sdev;
}

/* READ: um frame de pedido por bloco de rel_wr_count setores. */
static int rpmb_do_read(struct scsi_device *sdev, u8 *req, u32 n, u32 rel,
			u8 *out)
{
	u32 left = n, chunk;
	int ret;

	while (left) {
		u16 type = rpmb_frame_req(req);

		/* O caminho de leitura nunca pode levar um frame de escrita. */
		if (type != RPMB_REQ_READ_DATA && type != RPMB_REQ_GET_COUNTER)
			return -EPERM;
		chunk = min(left, rel);
		ret = rpmb_sec_cmd(sdev, req, RPMB_FRAME_LEN, true);
		if (ret)
			return ret;
		ret = rpmb_sec_cmd(sdev, out, chunk * RPMB_FRAME_LEN, false);
		if (ret)
			return ret;
		req += RPMB_FRAME_LEN;
		out += chunk * RPMB_FRAME_LEN;
		left -= chunk;
	}
	return 0;
}

/* WRITE: blocos de frames assinados, cada um seguido de RESULT_READ. */
static int rpmb_do_write(struct scsi_device *sdev, u8 *req, u32 n, u32 rel,
			 u8 *out)
{
	u32 i, left = n, chunk;
	int ret;

	for (i = 0; i < n; i++)
		if (rpmb_frame_req(req + i * RPMB_FRAME_LEN) !=
		    RPMB_REQ_WRITE_DATA)
			return -EPERM;	/* PROGRAM_KEY e afins: nunca */

	while (left) {
		chunk = min(left, rel);
		ret = rpmb_sec_cmd(sdev, req, chunk * RPMB_FRAME_LEN, true);
		if (ret)
			return ret;
		memset(out, 0, RPMB_FRAME_LEN);
		put_unaligned_be16(RPMB_REQ_RESULT_READ,
				   out + RPMB_FRAME_LEN - 2);
		ret = rpmb_sec_cmd(sdev, out, RPMB_FRAME_LEN, true);
		if (ret)
			return ret;
		ret = rpmb_sec_cmd(sdev, out, RPMB_FRAME_LEN, false);
		if (ret)
			return ret;
		req += chunk * RPMB_FRAME_LEN;
		left -= chunk;
	}
	return 0;
}

/*
 * Atende um pedido RPMB no buffer do listener. Devolve 0 quando a resposta
 * foi escrita (mesmo que com status de erro para o TEE), negativo quando o
 * pedido não pôde nem ser interpretado.
 */
static int qseecom_fpc_rpmb_serve(struct qseecom_fpc *q)
{
	u32 *w = q->lbuf;
	u32 cmd = w[0];
	struct scsi_device *sdev;
	struct ufs_hba *hba;
	u32 n, off, rel, size, chunks, frames;
	u8 *kreq = NULL, *kout = NULL;
	s32 status;

	if (cmd == TZ_RPMB_PARTITION) {
		/* Sem rpmb_parti.cfg: a mesma resposta do librpmb. */
		w[1] = (u32)-1;
		w[2] = 0;
		w[3] = 0x10;
		dev_info(q->dev, "rpmb: PARTITION -> sem configuração\n");
		return 0;
	}
	if (cmd != TZ_RPMB_INIT && cmd != TZ_RPMB_READ &&
	    cmd != TZ_RPMB_WRITE) {
		w[1] = (u32)-7;
		w[2] = 0;
		w[3] = TZ_RPMB_RSP_OFF;
		dev_warn(q->dev, "rpmb: comando %#x desconhecido\n", cmd);
		return 0;
	}

	sdev = rpmb_get_sdev(q);
	if (!sdev)
		return -ENODEV;
	hba = shost_priv(sdev->host);
	rel = hba->dev_info.rpmb_io_size;
	/* Mesma conta do librpmb: qLogicalBlockCount (256 B) / 2. */
	size = hba->dev_info.rpmb_region_size[0] * (SZ_128K / 512);

	if (cmd == TZ_RPMB_INIT) {
		u32 version = w[1];

		status = (rel && size) ? 0 : -1;
		if (!version) {
			w[1] = 1;
			w[2] = (u32)-1;
			w[3] = 0;
			w[4] = 0;
		} else if (version == 1) {
			w[2] = status;
			w[3] = size;
			w[4] = rel;
		} else {
			memset(&w[1], 0, 9 * sizeof(u32));
			w[1] = 2;
			w[2] = status;
			w[3] = size;
			w[4] = rel;
			w[5] = TZ_RPMB_DEV_UFS;
		}
		dev_info(q->dev, "rpmb: INIT v%u -> setores %u, rel_wr %u, status %d\n",
			 version, size, rel, status);
		scsi_device_put(sdev);
		return 0;
	}

	n = w[1];
	off = w[3];
	if (!rel || !n) {
		status = -EINVAL;
		goto reply;
	}
	if (cmd == TZ_RPMB_WRITE && w[5])
		rel = min(rel, w[5]);
	chunks = DIV_ROUND_UP(n, rel);
	frames = cmd == TZ_RPMB_READ ? chunks : n;
	if (off < sizeof(u32) * 6 ||
	    off + (size_t)frames * RPMB_FRAME_LEN > listener_size ||
	    TZ_RPMB_RSP_OFF + (size_t)n * RPMB_FRAME_LEN > listener_size) {
		status = -EINVAL;
		goto reply;
	}

	/* A resposta se sobrepõe ao pedido: copiar antes de responder. */
	kreq = kmemdup((u8 *)q->lbuf + off, frames * RPMB_FRAME_LEN,
		       GFP_KERNEL);
	kout = kzalloc(cmd == TZ_RPMB_READ ? n * RPMB_FRAME_LEN :
		       RPMB_FRAME_LEN, GFP_KERNEL);
	if (!kreq || !kout) {
		status = -ENOMEM;
		goto reply;
	}

	dev_info(q->dev, "rpmb: %s %u setor(es), frame %#06x addr %u cnt %u\n",
		 cmd == TZ_RPMB_READ ? "READ" : "WRITE", n,
		 rpmb_frame_req(kreq),
		 get_unaligned_be16(kreq + RPMB_FRAME_LEN - 8),
		 get_unaligned_be16(kreq + RPMB_FRAME_LEN - 6));

	if (cmd == TZ_RPMB_READ) {
		status = rpmb_do_read(sdev, kreq, n, rel, kout);
		if (!status) {
			memcpy((u8 *)q->lbuf + TZ_RPMB_RSP_OFF, kout,
			       n * RPMB_FRAME_LEN);
			w[2] = n * RPMB_FRAME_LEN;
		}
	} else if (!rpmb_writes) {
		dev_warn(q->dev, "rpmb: escrita RECUSADA (rpmb_writes=0)\n");
		status = -EPERM;
	} else {
		status = rpmb_do_write(sdev, kreq, n, rel, kout);
		if (!status) {
			memcpy((u8 *)q->lbuf + TZ_RPMB_RSP_OFF, kout,
			       RPMB_FRAME_LEN);
			w[2] = RPMB_FRAME_LEN;
			dev_info(q->dev, "rpmb: WRITE resultado %#06x\n",
				 get_unaligned_be16(kout + RPMB_FRAME_LEN - 4));
		}
	}

reply:
	if (status)
		w[2] = 0;
	w[1] = status;
	w[3] = TZ_RPMB_RSP_OFF;
	dev_info(q->dev, "rpmb: cmd %#x -> status %d\n", cmd, status);
	kfree(kreq);
	kfree(kout);
	scsi_device_put(sdev);
	return 0;
}

/*
 * Responde aos pedidos de listener até o TEE terminar o comando. Devolve 0
 * quando o app terminou; o resultado do TA continua no bloco de resposta.
 */
static int qseecom_fpc_serve_listener(struct qseecom_fpc *q)
{
	unsigned int n;
	int ret = -EOPNOTSUPP;

	for (n = 0; n < QSEECOM_LISTENER_MAX_ROUNDS; n++) {
		u32 lid = qcom_scm_qseecom_last_blocked_listener;

		u32 status = QSEOS_RESULT_FAILURE;

		if (q->lbuf && lid == listener_id) {
			print_hex_dump(KERN_INFO, "qseecom-fpc lreq: ",
				       DUMP_PREFIX_OFFSET, 16, 4, q->lbuf, 32,
				       false);
			if (lid == 0x2000 && !qseecom_fpc_rpmb_serve(q))
				status = 0;	/* QSEOS_RESULT_SUCCESS */
		}
		if (status)
			dev_warn(q->dev,
				 "TEE pediu listener %#x (volta %u); respondendo FAILURE\n",
				 lid, n);

		ret = qcom_scm_qseecom_listener_resp(lid, status,
						     q->lsglist_phys,
						     8 * QSEECOM_SGLIST_MAX);
		dev_info(q->dev, "listener %#x rsp %#x -> %d\n", lid, status,
			 ret);
		if (ret != -EOPNOTSUPP)
			break;
	}
	if (ret == -EOPNOTSUPP)
		dev_err(q->dev, "TEE continua pedindo listener após %u voltas\n",
			QSEECOM_LISTENER_MAX_ROUNDS);
	return ret;
}

/*
 * Uma chamada whitelist completa: registra o listener (se houver), envia,
 * atende cada INCOMPLETE e desregistra. É o único lugar onde o listener
 * existe, para nunca ficar registrado e ocioso.
 */
static int qseecom_fpc_call_wl(struct qseecom_fpc *q, u32 app_id,
			       phys_addr_t req, size_t req_len,
			       phys_addr_t rsp, size_t rsp_len,
			       phys_addr_t sglist, size_t sglist_len,
			       u64 *ta_result)
{
	int ret, dret;

	if (listener_id) {
		if (!q->lbuf)
			return -ENOMEM;
		memset(q->lsglist, 0, 8 * QSEECOM_SGLIST_MAX);
		ret = qcom_scm_qseecom_listener_register(listener_id, q->lphys,
							 listener_size);
		if (ret) {
			dev_err(q->dev, "listener %#x: register -> %d\n",
				listener_id, ret);
			return ret;
		}
	}

	ret = qcom_scm_qseecom_app_send_phys_wl(app_id, req, req_len, rsp,
						rsp_len, sglist, sglist_len,
						ta_result);
	/*
	 * QSEOS_RESULT_INCOMPLETE: o TEE parou no meio do comando porque precisa
	 * de um serviço de listener (RPMB/SSD). Cada resposta é a continuação do
	 * mesmo comando, então repete enquanto ele pedir. O pedido que não temos
	 * como atender (inclusive de um id não registrado) recebe FAILURE, como
	 * faz o driver Qualcomm.
	 */
	if (ret == -EOPNOTSUPP)
		ret = qseecom_fpc_serve_listener(q);

	if (!listener_id)
		return ret;
	dret = qcom_scm_qseecom_listener_deregister(listener_id);
	if (dret)
		dev_err(q->dev, "listener %#x: deregister -> %d\n",
			listener_id, dret);
	return ret ? ret : dret;
}

/*
 * Envio genérico para um app já residente (ex.: keymaster64): req e rsp
 * contíguos num buffer coerente abaixo de 4 GiB, sem região externa, com a
 * tabela sglist zerada -- o mesmo que __qseecom_send_cmd faz no Android.
 */
static int qseecom_fpc_send_raw(struct qseecom_fpc *q, void __user *uarg)
{
	struct qseecom_fpc_send_raw arg;
	dma_addr_t phys, sgl_phys;
	size_t len, rsp_off;
	void *buf, *sgl;
	u64 ta_result = 0;
	int ret;

	if (copy_from_user(&arg, uarg, sizeof(arg)))
		return -EFAULT;
	if (!arg.app_id || !arg.req || !arg.rsp || !arg.req_len ||
	    !arg.rsp_len || arg.req_len > QSEECOM_FPC_MAX_RAW ||
	    arg.rsp_len > QSEECOM_FPC_MAX_RAW)
		return -EINVAL;

	/*
	 * Igual ao KeymasterUtils::sendCmd do Android: a resposta começa no
	 * múltiplo de 4 seguinte ao fim do pedido, no mesmo buffer.
	 */
	rsp_off = ALIGN(arg.req_len, 4);
	len = PAGE_ALIGN(rsp_off + arg.rsp_len);
	buf = dma_alloc_coherent(q->dev, len, &phys, GFP_KERNEL | GFP_DMA32);
	if (!buf)
		return -ENOMEM;
	sgl = dma_alloc_coherent(q->dev, 8 * QSEECOM_SGLIST_MAX, &sgl_phys,
				 GFP_KERNEL | GFP_DMA32);
	if (!sgl) {
		ret = -ENOMEM;
		goto out_buf;
	}
	memset(sgl, 0, 8 * QSEECOM_SGLIST_MAX);
	memset(buf, 0, len);
	if (copy_from_user(buf, u64_to_user_ptr(arg.req), arg.req_len)) {
		ret = -EFAULT;
		goto out;
	}

	ret = qseecom_fpc_call_wl(q, arg.app_id, phys, arg.req_len,
				  phys + rsp_off, arg.rsp_len, sgl_phys,
				  8 * QSEECOM_SGLIST_MAX, &ta_result);
	dev_info(q->dev, "send_raw app %u cmd %#x -> %d, rsp[0] %#x\n",
		 arg.app_id, *(u32 *)buf, ret,
		 *(u32 *)((u8 *)buf + rsp_off));
	if (ret)
		goto out;

	if (copy_to_user(u64_to_user_ptr(arg.rsp), (u8 *)buf + rsp_off,
			 arg.rsp_len))
		ret = -EFAULT;
out:
	/* A resposta pode ter material sensível: não deixar no pool. */
	memzero_explicit(buf, len);
	dma_free_coherent(q->dev, 8 * QSEECOM_SGLIST_MAX, sgl, sgl_phys);
out_buf:
	dma_free_coherent(q->dev, len, buf, phys);
	return ret;
}

static int qseecom_fpc_get_app_id(void __user *uarg)
{
	struct qseecom_fpc_app_id arg;
	int ret;

	if (copy_from_user(&arg, uarg, sizeof(arg)))
		return -EFAULT;
	arg.name[sizeof(arg.name) - 1] = '\0';
	ret = qcom_scm_qseecom_app_get_id(arg.name, &arg.app_id);
	if (ret)
		return ret;
	return copy_to_user(uarg, &arg, sizeof(arg)) ? -EFAULT : 0;
}

static int qseecom_fpc_send(struct qseecom_fpc *q, void __user *uarg)
{
	struct qseecom_fpc_send arg;
	u8 *ctrl = q->ctrl;
	u64 ta_result = 0;
	u32 region_len;
	int ret;

	if (copy_from_user(&arg, uarg, sizeof(arg)))
		return -EFAULT;

	if (!arg.req || !arg.rsp)
		return -EINVAL;
	if (!arg.frame || !arg.frame_len || arg.frame_len > q->frame_len)
		return -EINVAL;
	if (!arg.app_id)
		arg.app_id = q->app_id;
	if (!arg.app_id)
		return -ENODEV;

	if (q->carveout) {
		/*
		 * Rotaciona a região: o secure world parece recusar uma segunda
		 * invocação que reusa o mesmo endereço.
		 */
		q->slot = (q->slot + 1) & 7;
		q->frame = q->carveout + QSEECOM_CV_FRAME + q->slot * 0x100000;
		q->frame_phys = carveout_phys + QSEECOM_CV_FRAME + q->slot * 0x100000;
		memset(q->frame, 0, arg.frame_len);
		if (copy_from_user(q->bounce, u64_to_user_ptr(arg.frame),
				   arg.frame_len))
			return -EFAULT;
		memcpy_toio(q->frame, q->bounce, arg.frame_len);
	} else if (copy_from_user(q->frame, u64_to_user_ptr(arg.frame),
				  arg.frame_len)) {
		return -EFAULT;
	}

	if (frame_cached)
		dma_sync_single_for_device(q->dev, q->frame_phys, q->frame_len,
					   DMA_TO_DEVICE);

	/*
	 * Control block: length of the external region, then its physical
	 * address (what the downstream kernel used to patch in via
	 * QSEECom_ion_fd_info{cmd_id = 4}).
	 */
	memset(ctrl, 0, QSEECOM_FPC_CTRL_LEN + QSEECOM_FPC_RSP_LEN);
	if (debug_send) {
		memset(ctrl + QSEECOM_FPC_CTRL_LEN, 0xAA, QSEECOM_FPC_RSP_LEN);
		dev_info(q->dev, "send dbg: ctrl0=%#x frame_phys=%pad frame[0..1]=%#x/%#x\n",
			 arg.frame_len, &q->frame_phys,
			 *(u32 *)q->frame, *(u32 *)(q->frame + 4));
	}
	/*
	 * control[0] is the size of the whole region, not the size of this
	 * command: the TA hands it to the TEE when it maps the region, and that
	 * call requires a page-aligned length (the Android HAL passes the ION
	 * allocation size here, which is page-rounded).
	 */
	/* o tamanho da região é o que o TA registra: precisa ser o mesmo da sglist */
	region_len = PAGE_SIZE > arg.frame_len ? PAGE_SIZE :
		     (u32)PAGE_ALIGN(arg.frame_len);
	*(u32 *)(ctrl + 0) = region_len;
	if (force_region_size)
		*(u32 *)(ctrl + 0) = force_region_size;
	*(u32 *)(ctrl + 4) = force_region_phys ?
			     lower_32_bits(force_region_phys) :
			     lower_32_bits(q->frame_phys);

	if (use_whitelist) {
		/*
		 * The sglist is what the TEE maps; it must describe exactly the
		 * same region size that the TA is told to register (control[0]),
		 * otherwise the TA's registration falls outside the mapping.
		 */
		*(u32 *)(q->sglist + 0) = QSEECOM_SG_SINGLE_32BIT |
					  QSEECOM_SG_ADDR_OFFSET;
		*(u32 *)(q->sglist + 4) = region_len;

		ret = qseecom_fpc_call_wl(q, arg.app_id, q->ctrl_phys,
					  QSEECOM_FPC_CTRL_LEN,
					  q->ctrl_phys + QSEECOM_FPC_CTRL_LEN,
					  QSEECOM_FPC_RSP_LEN, q->sglist_phys,
					  q->sglist_len, &ta_result);
	} else {
		ret = qcom_scm_qseecom_app_send_phys(arg.app_id, q->ctrl_phys,
						     QSEECOM_FPC_CTRL_LEN,
						     q->ctrl_phys +
						     QSEECOM_FPC_CTRL_LEN,
						     QSEECOM_FPC_RSP_LEN,
						     &ta_result);
	}
	if (ret)
		return ret;

	arg.ta_result = ta_result;

	if (frame_cached)
		dma_sync_single_for_cpu(q->dev, q->frame_phys, q->frame_len,
					DMA_FROM_DEVICE);

	arg.status = *(s32 *)(ctrl + QSEECOM_FPC_CTRL_LEN);

	if (debug_send)
		dev_info(q->dev, "send dbg: ret=%d rsp=%#x %#x %#x %#x frame[0..1]=%#x/%#x\n",
			 ret, *(u32 *)(ctrl + QSEECOM_FPC_CTRL_LEN),
			 *(u32 *)(ctrl + QSEECOM_FPC_CTRL_LEN + 4),
			 *(u32 *)(ctrl + QSEECOM_FPC_CTRL_LEN + 8),
			 *(u32 *)(ctrl + QSEECOM_FPC_CTRL_LEN + 12),
			 *(u32 *)q->frame, *(u32 *)(q->frame + 4));

	if (copy_to_user(u64_to_user_ptr(arg.rsp), ctrl + QSEECOM_FPC_CTRL_LEN,
			 QSEECOM_FPC_RSP_LEN))
		return -EFAULT;
	if (copy_to_user(u64_to_user_ptr(arg.req), ctrl, QSEECOM_FPC_CTRL_LEN))
		return -EFAULT;
	if (q->carveout) {
		memcpy_fromio(q->bounce, q->frame, arg.frame_len);
		if (copy_to_user(u64_to_user_ptr(arg.frame), q->bounce,
				 arg.frame_len))
			return -EFAULT;
	} else if (copy_to_user(u64_to_user_ptr(arg.frame), q->frame,
				arg.frame_len)) {
		return -EFAULT;
	}
	if (copy_to_user(uarg, &arg, sizeof(arg)))
		return -EFAULT;

	return 0;
}

static long qseecom_fpc_ioctl(struct file *file, unsigned int cmd,
			      unsigned long arg)
{
	struct qseecom_fpc *q = file->private_data;
	void __user *uarg = (void __user *)arg;
	struct qseecom_fpc_info info;
	int ret = 0;

	mutex_lock(&q->lock);
	switch (cmd) {
	case QSEECOM_FPC_LOAD_APP:
		ret = qseecom_fpc_load(q, uarg);
		break;
	case QSEECOM_FPC_SEND:
		ret = qseecom_fpc_send(q, uarg);
		break;
	case QSEECOM_FPC_SEND_RAW:
		ret = qseecom_fpc_send_raw(q, uarg);
		break;
	case QSEECOM_FPC_GET_APP_ID:
		ret = qseecom_fpc_get_app_id(uarg);
		break;
	case QSEECOM_FPC_UNLOAD_APP:
		if (!q->app_loaded) {
			ret = -ENODEV;
			break;
		}
		/* Best effort: a failed shutdown must not wedge the device. */
		qcom_scm_qseecom_app_shutdown(q->app_id);
		q->app_loaded = false;
		q->app_id = 0;
		break;
	case QSEECOM_FPC_INFO:
		info.app_id = q->app_id;
		info.app_loaded = q->app_loaded;
		info.frame_len = q->frame_len;
		info.reserved = 0;
		if (copy_to_user(uarg, &info, sizeof(info)))
			ret = -EFAULT;
		break;
	default:
		ret = -ENOTTY;
	}
	mutex_unlock(&q->lock);

	return ret;
}

static int qseecom_fpc_open(struct inode *inode, struct file *file)
{
	struct qseecom_fpc *q = container_of(file->private_data,
					     struct qseecom_fpc, misc);

	mutex_lock(&q->lock);
	if (q->open) {
		mutex_unlock(&q->lock);
		return -EBUSY;
	}
	q->open = true;
	mutex_unlock(&q->lock);

	file->private_data = q;
	return 0;
}

static int qseecom_fpc_release(struct inode *inode, struct file *file)
{
	struct qseecom_fpc *q = file->private_data;

	mutex_lock(&q->lock);
	q->open = false;
	mutex_unlock(&q->lock);
	return 0;
}

static const struct file_operations qseecom_fpc_fops = {
	.owner = THIS_MODULE,
	.open = qseecom_fpc_open,
	.release = qseecom_fpc_release,
	.unlocked_ioctl = qseecom_fpc_ioctl,
	.compat_ioctl = qseecom_fpc_ioctl,
};

static int qseecom_fpc_probe(struct platform_device *pdev)
{
	struct qseecom_fpc *q;
	int ret;

	q = devm_kzalloc(&pdev->dev, sizeof(*q), GFP_KERNEL);
	if (!q)
		return -ENOMEM;

	q->dev = &pdev->dev;
	mutex_init(&q->lock);

	/*
	 * The legacy QSEECOM ABI passes 32-bit physical addresses and TZ rejects
	 * buffers above 4 GiB for 32-bit apps (the Android driver has the same
	 * check). A 32-bit coherent mask makes the allocator stay below 4 GiB.
	 */
	ret = dma_set_mask_and_coherent(q->dev, DMA_BIT_MASK(32));
	if (ret) {
		dev_err(q->dev, "no usable DMA mask: %d\n", ret);
		return ret;
	}

	if (carveout_phys) {
		/*
		 * Uncacheable mapping: this memory is shared with the secure
		 * world, and a write-back mapping over a no-map region cannot be
		 * kept coherent with it.
		 */
		q->carveout = memremap(carveout_phys, carveout_size,
				       MEMREMAP_WC);
		if (!q->carveout) {
			dev_err(q->dev, "cannot map carveout %#lx\n",
				carveout_phys);
			return -ENOMEM;
		}
		/*
		 * Only the shared data region lives in the carveout; the request
		 * and response blocks must stay in normal coherent memory (a
		 * control block inside the carveout makes the secure world ignore
		 * the call).
		 */
		q->frame = q->carveout + QSEECOM_CV_FRAME;
		q->frame_phys = carveout_phys + QSEECOM_CV_FRAME;
		q->frame_len = carveout_size - QSEECOM_CV_FRAME;
		if (q->frame_len > QSEECOM_FPC_MAX_FRAME)
			q->frame_len = QSEECOM_FPC_MAX_FRAME;
		q->bounce = kzalloc(QSEECOM_FPC_MAX_FRAME, GFP_KERNEL);
		if (!q->bounce) {
			memunmap(q->carveout);
			return -ENOMEM;
		}
		dev_info(q->dev, "using carveout %#lx (%lu MiB) for the data region\n",
			 carveout_phys, carveout_size >> 20);
	}

	q->ctrl = dma_alloc_coherent(q->dev,
				     QSEECOM_FPC_CTRL_LEN + QSEECOM_FPC_RSP_LEN,
				     &q->ctrl_phys, GFP_KERNEL | GFP_DMA32);
	if (!q->ctrl) {
		ret = -ENOMEM;
		goto err_carveout;
	}

	q->frame_len = frame_size;
	if (q->frame_len < PAGE_SIZE || q->frame_len > QSEECOM_FPC_MAX_FRAME)
		return -EINVAL;
	if (q->carveout) {
		/* frame já aponta para o carveout */
	} else if (frame_cached == 2) {
		/*
		 * CMA-backed but *cacheable*: the TEE shared-buffer registration
		 * appears to need cacheable pages, while the call itself is only
		 * accepted for a reserved (CMA) range. DMA_ATTR_NON_CONSISTENT
		 * gives exactly that combination; cache maintenance is explicit.
		 */
		q->frame = dma_alloc_noncoherent(q->dev, q->frame_len,
						 &q->frame_phys,
						 DMA_BIDIRECTIONAL,
						 GFP_KERNEL);
	} else if (frame_cached) {
		void *va = alloc_pages_exact(q->frame_len,
					     GFP_KERNEL | GFP_DMA32);

		if (va) {
			q->frame = va;
			q->frame_phys = virt_to_phys(va);
		}
	} else {
		q->frame = dma_alloc_coherent(q->dev, q->frame_len, &q->frame_phys,
					      GFP_KERNEL | GFP_DMA32);
	}
	if (!q->frame) {
		ret = -ENOMEM;
		goto err_ctrl;
	}

	q->sglist_len = 8 * QSEECOM_SGLIST_MAX;
	q->sglist = dma_alloc_coherent(q->dev, q->sglist_len, &q->sglist_phys,
				       GFP_KERNEL | GFP_DMA32);
	if (!q->sglist) {
		ret = -ENOMEM;
		goto err_frame;
	}
	memset(q->sglist, 0, q->sglist_len);

have_buffers:
	q->misc.minor = MISC_DYNAMIC_MINOR;
	q->misc.name = QSEECOM_FPC_NAME;
	q->misc.fops = &qseecom_fpc_fops;
	q->misc.parent = q->dev;
	ret = misc_register(&q->misc);
	if (ret)
		goto err_sglist;

	platform_set_drvdata(pdev, q);

	if (region_phys) {
		ret = qcom_scm_qseecom_app_region_notify(region_phys, region_size);
		dev_info(q->dev, "app region notify %#lx+%#lx: %d\n",
			 region_phys, region_size, ret);
	}

	/* Só aloca: o registro acontece dentro de cada send. */
	if (listener_id && PAGE_ALIGNED(listener_size)) {
		dma_addr_t dphys;

		q->lsglist = dma_alloc_coherent(q->dev, 8 * QSEECOM_SGLIST_MAX,
						&q->lsglist_phys,
						GFP_KERNEL | GFP_DMA32);
		if (q->lsglist && q->carveout && listener_in_carveout) {
			q->lbuf = q->carveout + QSEECOM_CV_LISTENER;
			q->lphys = carveout_phys + QSEECOM_CV_LISTENER;
			memset_io(q->lbuf, 0, listener_size);
		} else if (q->lsglist) {
			q->lbuf = dma_alloc_coherent(q->dev, listener_size,
						     &dphys,
						     GFP_KERNEL | GFP_DMA32);
			q->lphys = dphys;
			q->lbuf_coherent = !!q->lbuf;
		}
		dev_info(q->dev, "listener %#x: buffer %pa+%#x (registro por send)\n",
			 listener_id, &q->lphys, listener_size);
	} else if (listener_id) {
		dev_err(q->dev, "listener_size %#x não é múltiplo de página\n",
			listener_size);
	}

	dev_info(q->dev, "ready: frame %zu B at %pad, control at %pad, whitelist %d\n",
		 q->frame_len, &q->frame_phys, &q->ctrl_phys, use_whitelist);
	return 0;

err_carveout:
	if (q->carveout)
		memunmap(q->carveout);
err_sglist:
	dma_free_coherent(q->dev, q->sglist_len, q->sglist, q->sglist_phys);
err_frame:
	dma_free_coherent(q->dev, q->frame_len, q->frame, q->frame_phys);
err_ctrl:
	dma_free_coherent(q->dev, QSEECOM_FPC_CTRL_LEN + QSEECOM_FPC_RSP_LEN,
			  q->ctrl, q->ctrl_phys);
	return ret;
}

static void qseecom_fpc_remove(struct platform_device *pdev)
{
	struct qseecom_fpc *q = platform_get_drvdata(pdev);

	misc_deregister(&q->misc);
	if (q->app_loaded)
		qcom_scm_qseecom_app_shutdown(q->app_id);
	if (q->lbuf_coherent)
		dma_free_coherent(q->dev, listener_size, q->lbuf, q->lphys);
	if (q->lsglist)
		dma_free_coherent(q->dev, 8 * QSEECOM_SGLIST_MAX, q->lsglist,
				  q->lsglist_phys);
	if (q->carveout) {
		kfree(q->bounce);
		memunmap(q->carveout);
		return;
	}
	dma_free_coherent(q->dev, q->sglist_len, q->sglist, q->sglist_phys);
	if (frame_cached == 2)
		dma_free_noncoherent(q->dev, q->frame_len, q->frame,
				     q->frame_phys, DMA_BIDIRECTIONAL);
	else if (frame_cached)
		free_pages_exact(q->frame, q->frame_len);
	else
		dma_free_coherent(q->dev, q->frame_len, q->frame, q->frame_phys);
	dma_free_coherent(q->dev, QSEECOM_FPC_CTRL_LEN + QSEECOM_FPC_RSP_LEN,
			  q->ctrl, q->ctrl_phys);
}

static struct platform_driver qseecom_fpc_driver = {
	.probe = qseecom_fpc_probe,
	.remove = qseecom_fpc_remove,
	.driver = {
		.name = QSEECOM_FPC_NAME,
	},
};

static struct platform_device *qseecom_fpc_pdev;

static int __init qseecom_fpc_init(void)
{
	int ret;

	/*
	 * No device tree node on purpose: everything comes from the SCM
	 * interface and coherent allocations, so the driver works on any
	 * board with a usable QSEECOM/TZ call path.
	 */
	qseecom_fpc_pdev = platform_device_register_simple(QSEECOM_FPC_NAME, -1,
							   NULL, 0);
	if (IS_ERR(qseecom_fpc_pdev))
		return PTR_ERR(qseecom_fpc_pdev);

	ret = platform_driver_register(&qseecom_fpc_driver);
	if (ret) {
		platform_device_unregister(qseecom_fpc_pdev);
		return ret;
	}

	return 0;
}

static void __exit qseecom_fpc_exit(void)
{
	platform_driver_unregister(&qseecom_fpc_driver);
	platform_device_unregister(qseecom_fpc_pdev);
}

module_init(qseecom_fpc_init);
module_exit(qseecom_fpc_exit);

MODULE_DESCRIPTION("Legacy QSEECOM transport for HLOS-loaded TAs (FPC)");
MODULE_LICENSE("GPL");
