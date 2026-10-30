// SPDX-License-Identifier: GPL-2.0-only
#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "hat-frame.h"

int main(void)
{
	uint8_t frame[112], hat[FPC_HAT_SIZE] = { 0 };

	for (unsigned int i = 1; i < sizeof(hat); i++)
		hat[i] = (uint8_t)i;
	assert(fpc_make_authorize_frame(frame, sizeof(frame), hat, sizeof(hat)) == 0);
	assert(frame[0] == 3 && frame[4] == 3 && frame[8] == 69);
	assert(memcmp(frame + 12, hat, sizeof(hat)) == 0);
	assert(frame[81] == 0);
	assert(fpc_make_authorize_frame(frame, 80, hat, sizeof(hat)) < 0);
	assert(fpc_make_authorize_frame(frame, sizeof(frame), hat, 68) < 0);
	hat[0] = 1;
	assert(fpc_make_authorize_frame(frame, sizeof(frame), hat, sizeof(hat)) < 0);
	puts("HAT frame: synthetic layout and boundary tests passed; authentication not tested");
	return 0;
}
