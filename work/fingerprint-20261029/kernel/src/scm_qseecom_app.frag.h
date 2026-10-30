int qcom_scm_qseecom_app_start(phys_addr_t image, size_t mdt_len,
			       size_t img_len, u32 *app_id);
int qcom_scm_qseecom_app_shutdown(u32 app_id);
int qcom_scm_qseecom_app_send_phys(u32 app_id, phys_addr_t req, size_t req_size,
				   phys_addr_t rsp, size_t rsp_size,
				   u64 *ta_result);
int qcom_scm_qseecom_app_send_phys_wl(u32 app_id, phys_addr_t req,
				      size_t req_size, phys_addr_t rsp,
				      size_t rsp_size, phys_addr_t sglist,
				      size_t sglist_len, u64 *ta_result);
int qcom_scm_qseecom_app_region_notify(phys_addr_t addr, size_t size);
int qcom_scm_qseecom_listener_register(u32 listener_id, phys_addr_t sb,
				       size_t sb_len);
int qcom_scm_qseecom_listener_resp(u32 listener_id, u32 rsp_status,
				   phys_addr_t sglist, size_t sglist_len);
int qcom_scm_qseecom_listener_deregister(u32 listener_id);
extern u32 qcom_scm_qseecom_last_blocked_listener;
