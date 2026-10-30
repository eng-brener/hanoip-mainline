// SPDX-License-Identifier: GPL-2.0-only
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "km-bridge.h"

int main(void)
{
	uint8_t req[KM_REQUEST_LEN], rsp[KM_RESPONSE_LEN] = {0}, frame[112];
	const uint8_t payload[] = { 0xa1, 0xb2, 0xc3, 0xd4 };

	assert(km_prepare_request(req, sizeof(req)) == 0);
	assert(km_get_le32(req) == 0x205 && km_get_le32(req + 4) == 2);
	assert(km_prepare_request(req, sizeof(req) - 1) < 0);
	rsp[4] = 12; rsp[8] = sizeof(payload);
	memcpy(rsp + 12, payload, sizeof(payload));
	assert(km_make_fpc_frame(frame, sizeof(frame), rsp, sizeof(rsp)) == 0);
	assert(km_get_le32(frame) == 3 && km_get_le32(frame + 4) == 5);
	assert(km_get_le32(frame + 8) == sizeof(payload));
	assert(memcmp(frame + 12, payload, sizeof(payload)) == 0);
	assert(km_make_fpc_frame(frame, 15, rsp, sizeof(rsp)) < 0);
	rsp[8] = 0xff; rsp[9] = 0xff; rsp[10] = 0xff; rsp[11] = 0xff;
	assert(km_make_fpc_frame(frame, sizeof(frame), rsp, sizeof(rsp)) < 0);
	puts("KM bridge: synthetic encoding and bounds tests passed; no TEE call");
	return 0;
}
