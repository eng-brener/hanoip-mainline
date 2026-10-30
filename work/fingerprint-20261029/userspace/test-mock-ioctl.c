// SPDX-License-Identifier: GPL-2.0-only
/* Host-only mock for the client's ioctl result handling. Never accesses a TA. */
#define _GNU_SOURCE
#include <errno.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include "qseecom-fpc.h"

int ioctl(int fd, unsigned long op, ...)
{
	va_list ap;
	void *p;
	const char *mode = getenv("FPC_MOCK");
	(void)fd;
	va_start(ap, op);
	p = va_arg(ap, void *);
	va_end(ap);
	if (op == QSEECOM_FPC_INFO) {
		struct qseecom_fpc_info *info = p;
		memset(info, 0, sizeof(*info));
		info->app_id = 1;
		info->app_loaded = 1;
		info->frame_len = QSEECOM_FPC_MAX_FRAME;
		return 0;
	}
	if (op == QSEECOM_FPC_SEND) {
		struct qseecom_fpc_send *send = p;
		unsigned char *frame = (void *)(uintptr_t)send->frame;
		if (mode && !strcmp(mode, "transport")) {
			errno = EINVAL;
			return -1;
		}
		if (mode && !strcmp(mode, "old-driver"))
			return 0;
		send->status = mode && !strcmp(mode, "ta-error") ?
			(int32_t)0xe850002a : 0;
		if (!send->status) {
			memcpy(frame + 0x18, "mock", 5);
			*(uint32_t *)(frame + 0x14) = 5;
		}
		return 0;
	}
	errno = ENOTTY;
	return -1;
}
