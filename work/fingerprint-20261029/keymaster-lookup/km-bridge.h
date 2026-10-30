/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef FPC_KM_BRIDGE_H
#define FPC_KM_BRIDGE_H
#include <stddef.h>
#include <stdint.h>
#include <string.h>
#include "km-response.h"

#define KM_REQUEST_LEN 0x40u
#define KM_RESPONSE_LEN 0x3c0u

/* Pure frame encoding only: does not perform an ioctl or call a secure app. */
static inline int km_prepare_request(uint8_t *req, size_t len)
{
	if (!req || len != KM_REQUEST_LEN)
		return -1;
	memset(req, 0, len);
	req[0] = 0x05;
	req[1] = 0x02;
	req[4] = 0x02;
	return 0;
}

static inline int km_make_fpc_frame(uint8_t *frame, size_t frame_len,
				     const uint8_t *rsp, size_t rsp_len)
{
	const uint8_t *blob;
	size_t blob_len;

	if (!frame || frame_len < 12 || rsp_len != KM_RESPONSE_LEN ||
	    km_response_blob(rsp, rsp_len, &blob, &blob_len) ||
	    blob_len > frame_len - 12 || blob_len > UINT32_MAX)
		return -1;
	/* The caller must supply disjoint buffers and clear them after use. */
	memset(frame, 0, frame_len);
	frame[0] = 3;
	frame[4] = 5;
	frame[8] = (uint8_t)blob_len;
	frame[9] = (uint8_t)(blob_len >> 8);
	frame[10] = (uint8_t)(blob_len >> 16);
	frame[11] = (uint8_t)(blob_len >> 24);
	memcpy(frame + 12, blob, blob_len);
	return 0;
}
#endif
