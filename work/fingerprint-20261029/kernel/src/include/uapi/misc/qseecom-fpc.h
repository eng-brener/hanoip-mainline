/* SPDX-License-Identifier: GPL-2.0-only WITH Linux-syscall-note */
/*
 * Minimal legacy QSEECOM transport, for TAs that must be loaded by the
 * non-secure world (here: Motorola's fpctzapp on the Moto G60).
 *
 * The ABI is deliberately small: load an app image from a buffer, then send
 * 64-byte control blocks plus one out-of-band data region ("frame").
 */
#ifndef _UAPI_MISC_QSEECOM_FPC_H
#define _UAPI_MISC_QSEECOM_FPC_H

#include <linux/types.h>
#include <linux/ioctl.h>

#define QSEECOM_FPC_MAX_IMAGE	(8U * 1024 * 1024)
#define QSEECOM_FPC_MAX_FRAME	(2U * 1024 * 1024)
#define QSEECOM_FPC_CTRL_LEN	64
#define QSEECOM_FPC_RSP_LEN	64

struct qseecom_fpc_load {
	__u64 image;		/* user pointer: [.mdt][b00..bNN] */
	__u32 image_len;	/* total bytes in @image */
	__u32 mdt_len;		/* bytes of the .mdt header at the start */
	__u32 app_id;		/* out: TEE app id */
	__u32 reserved;
};

struct qseecom_fpc_send {
	__u64 req;		/* user pointer: 64-byte control block (in) */
	__u64 rsp;		/* user pointer: 64-byte response block (out) */
	__u64 frame;		/* user pointer: external data region */
	__u32 frame_len;	/* bytes in @frame (the TA sees this size) */
	__u32 app_id;		/* in: 0 = use the app loaded by this device */
	__s32 status;		/* out: first word of the response block */
	__s32 reserved;
	__s64 ta_result;	/* out: value returned by the TA (module-specific) */
};

struct qseecom_fpc_info {
	__u32 app_id;
	__u32 app_loaded;
	__u32 frame_len;	/* size of the internal frame buffer */
	__u32 reserved;
};

/* Envio genérico a um app residente (ex.: keymaster64), sem região externa. */
#define QSEECOM_FPC_MAX_RAW	(64U * 1024)

struct qseecom_fpc_send_raw {
	__u64 req;		/* user pointer: request bytes (in) */
	__u64 rsp;		/* user pointer: response bytes (out) */
	__u32 req_len;
	__u32 rsp_len;
	__u32 app_id;		/* from QSEECOM_FPC_GET_APP_ID */
	__u32 reserved;
};

struct qseecom_fpc_app_id {
	char name[64];		/* in: app name, e.g. "keymaster64" */
	__u32 app_id;		/* out */
	__u32 reserved;
};

#define QSEECOM_FPC_LOAD_APP	_IOWR('q', 1, struct qseecom_fpc_load)
#define QSEECOM_FPC_UNLOAD_APP	_IO('q', 2)
#define QSEECOM_FPC_SEND	_IOWR('q', 3, struct qseecom_fpc_send)
#define QSEECOM_FPC_INFO	_IOR('q', 4, struct qseecom_fpc_info)
#define QSEECOM_FPC_SEND_RAW	_IOWR('q', 5, struct qseecom_fpc_send_raw)
#define QSEECOM_FPC_GET_APP_ID	_IOWR('q', 6, struct qseecom_fpc_app_id)

#endif /* _UAPI_MISC_QSEECOM_FPC_H */
