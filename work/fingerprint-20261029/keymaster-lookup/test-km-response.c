// SPDX-License-Identifier: GPL-2.0-only
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "km-response.h"

static void put32(uint8_t *p, uint32_t n)
{
	p[0] = n; p[1] = n >> 8; p[2] = n >> 16; p[3] = n >> 24;
}

int main(void)
{
	uint8_t rsp[0x3c0] = { 0 };
	const uint8_t *blob;
	size_t len;

	put32(rsp + 4, 12); put32(rsp + 8, 4);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) == 0);
	assert(blob == rsp + 12 && len == 4);
	put32(rsp + 4, sizeof(rsp) - 1); put32(rsp + 8, 1);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) == 0);
	put32(rsp + 8, 2);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) < 0);
	put32(rsp + 4, UINT32_MAX); put32(rsp + 8, UINT32_MAX);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) < 0);
	put32(rsp + 4, 8); put32(rsp + 8, 1);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) < 0);
	put32(rsp + 4, 12); put32(rsp + 8, 0);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) < 0);
	put32(rsp + 8, 1); put32(rsp, 1);
	assert(km_response_blob(rsp, sizeof(rsp), &blob, &len) < 0);
	assert(km_response_blob(rsp, 11, &blob, &len) < 0);
	puts("KM parser: boundary tests passed (synthetic data only)");
	return 0;
}
