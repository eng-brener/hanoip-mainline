#!/usr/bin/env python3
"""Sharpness of a RAW10-packed frame: mean squared difference between
horizontally/vertically adjacent same-colour (G at even row, odd col) pixels
in the central third. Usage: sharp.py FILE WIDTH HEIGHT [STRIDE]"""
import sys
f, W, H = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
d = open(f, "rb").read()
st = int(sys.argv[4]) if len(sys.argv) > 4 else W * 10 // 8


def px(y, x):
    o = y * st + (x // 4) * 5
    return (d[o + x % 4] << 2) | ((d[o + 4] >> (2 * (x % 4))) & 3)


s = n = m = 0
for y in range(H // 3 & ~1, 2 * H // 3, 8):
    for x in range((W // 3 & ~1) + 1, 2 * W // 3, 8):
        v = px(y, x)
        s += (v - px(y, x + 2)) ** 2 + (v - px(y + 2, x)) ** 2
        m += v
        n += 1
print(f"{s / n:.1f} {m / n:.1f}")
