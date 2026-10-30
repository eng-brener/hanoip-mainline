// SPDX-License-Identifier: MIT
// Fixed-mode streaming bridge for this OV02B1B test, not a general V4L2 app.
// stdin: 1600x1200 Y10P, 2000 bytes/line; stdout: GRAY8, 1600x1200.
// Input RAW10 upper 8 bits are scaled after subtracting the 10-bit black
// level 64. The low two bits are intentionally discarded for preview.
#include <errno.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

enum { WIDTH = 1600, HEIGHT = 1200, INPUT_SIZE = WIDTH * HEIGHT * 5 / 4,
       OUTPUT_SIZE = WIDTH * HEIGHT };

int main(void)
{
	uint8_t *in = malloc(INPUT_SIZE), *out = malloc(OUTPUT_SIZE);
	if (!in || !out) {
		fprintf(stderr, "allocation failed\n");
		return 1;
	}
	for (;;) {
		size_t off = 0;
		while (off < INPUT_SIZE) {
			ssize_t n = read(STDIN_FILENO, in + off, INPUT_SIZE - off);
			if (n < 0 && errno == EINTR)
				continue;
			if (n <= 0) {
				if (n == 0 && off == 0)
					return 0;
				fprintf(stderr, "incomplete frame or input error\n");
				return 1;
			}
			off += n;
		}
		for (size_t i = 0, j = 0; i < INPUT_SIZE; i += 5) {
			for (size_t k = 0; k < 4; k++) {
				unsigned int v = in[i + k];
				out[j++] = v <= 16 ? 0 : (v - 16) * 255 / 239;
			}
		}
		off = 0;
		while (off < OUTPUT_SIZE) {
			ssize_t n = write(STDOUT_FILENO, out + off, OUTPUT_SIZE - off);
			if (n < 0 && errno == EINTR)
				continue;
			if (n <= 0) {
				fprintf(stderr, "output error\n");
				return 1;
			}
			off += n;
		}
	}
}
