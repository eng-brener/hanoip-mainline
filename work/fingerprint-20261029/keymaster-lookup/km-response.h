/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef FPC_KM_RESPONSE_H
#define FPC_KM_RESPONSE_H
#include <stddef.h>
#include <stdint.h>

/* Parse an untrusted little-endian Keymaster response without copying the blob. */
static inline uint32_t km_get_le32(const uint8_t *p)
{
	return (uint32_t)p[0] | (uint32_t)p[1] << 8 |
		(uint32_t)p[2] << 16 | (uint32_t)p[3] << 24;
}

static inline int km_response_blob(const uint8_t *rsp, size_t rsp_len,
				   const uint8_t **blob, size_t *blob_len)
{
	uint32_t offset, length;

	if (!rsp || !blob || !blob_len || rsp_len < 12)
		return -1;
	*blob = NULL;
	*blob_len = 0;
	if (km_get_le32(rsp) != 0)
		return -1;
	offset = km_get_le32(rsp + 4);
	length = km_get_le32(rsp + 8);
	/* Fail closed: header overlap, empty blob, arithmetic wrap or truncation. */
	if (offset < 12 || offset > rsp_len || length == 0 ||
	    length > rsp_len - offset)
		return -1;
	*blob = rsp + offset;
	*blob_len = length;
	return 0;
}
#endif
