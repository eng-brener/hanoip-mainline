/* SPDX-License-Identifier: GPL-2.0-only */
#ifndef FPC_HAT_FRAME_H
#define FPC_HAT_FRAME_H
#include <stddef.h>
#include <stdint.h>
#include <string.h>

#define FPC_HAT_SIZE 69u
#define FPC_AUTH_FRAME_SIZE (12u + FPC_HAT_SIZE)

/* Marshal an opaque HAT to module 3/cmd 3, without claiming it is authentic. */
static inline int fpc_make_authorize_frame(uint8_t *frame, size_t frame_len,
					   const uint8_t *hat, size_t hat_len)
{
	if (!frame || !hat || frame_len < FPC_AUTH_FRAME_SIZE ||
	    hat_len != FPC_HAT_SIZE || hat[0] != 0)
		return -1;
	memset(frame, 0, frame_len);
	frame[0] = 3;
	frame[4] = 3;
	frame[8] = FPC_HAT_SIZE;
	memcpy(frame + 12, hat, FPC_HAT_SIZE);
	return 0;
}
#endif
