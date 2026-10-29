#!/usr/bin/env python3
"""Small colour previews of a RAW10-packed Bayer frame, one per Bayer order,
grey-world white balance, black 64. Prints the 2x2 quad means.
Usage: preview.py FILE WIDTH HEIGHT STRIDE OUTPREFIX [STEP]"""
import statistics, struct, sys, zlib
fn, W, H, st, pre = sys.argv[1], int(sys.argv[2]), int(sys.argv[3]), int(sys.argv[4]), sys.argv[5]
S = int(sys.argv[6]) if len(sys.argv) > 6 else 5
d = open(fn, "rb").read()


def px(y, x):
    o = y * st + (x // 4) * 5
    return (d[o + x % 4] << 2) | ((d[o + 4] >> (2 * (x % 4))) & 3)


Q = [[(px(2 * qy, 2 * qx), px(2 * qy, 2 * qx + 1), px(2 * qy + 1, 2 * qx), px(2 * qy + 1, 2 * qx + 1))
      for qx in range(0, W // 2, S)] for qy in range(0, H // 2, S)]
fl = [q for r in Q for q in r]
print("quad means 00,01,10,11:", [round(statistics.mean(q[i] for q in fl), 1) for i in range(4)])
for order in ("GRBG", "GBRG", "BGGR", "RGGB"):
    idx = {c: [i for i, ch in enumerate(order) if ch == c] for c in "RGB"}
    pix = [[tuple(max(sum(q[i] for i in idx[c]) / len(idx[c]) - 64, 0) for c in "RGB") for q in r] for r in Q]
    f = [p for r in pix for p in r]
    m = [sum(p[i] for p in f) / len(f) for i in range(3)]
    g = [m[1] / max(x, .5) for x in m]
    top = sorted(max(p[i] * g[i] for i in range(3)) for p in f)[int(len(f) * .995)] or 1
    raw = b"".join(b"\0" + bytes(int(255 * min(1, p[i] * g[i] / top) ** (1 / 2.2)) for p in r for i in range(3)) for r in pix)
    ch = lambda t, b: struct.pack(">I", len(b)) + t + b + struct.pack(">I", zlib.crc32(t + b))
    open(f"{pre}-{order}.png", "wb").write(b"\x89PNG\r\n\x1a\n" + ch(b"IHDR", struct.pack(">IIBBBBB", len(pix[0]), len(pix), 8, 2, 0, 0, 0)) + ch(b"IDAT", zlib.compress(raw, 9)) + ch(b"IEND", b""))
