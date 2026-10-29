#!/usr/bin/env python3
"""Per-mode parameters of CamX sensormodule resolution lists.

Layout found on the S5K4H7 (29/10), relative to the frame rate double:
  -0x38 lineLengthPixelClock, -0x30 frameLengthLines, -0x28 min HBlank,
  -0x20 min VBlank, -0x18 outputPixelClock (MIPI throughput), +0x08 lanes.
The stream configurations sit between that block and the register list; the
LAST [x, y, width, height, bitWidth] before the list is the main pixel stream
when its data type is 0x2b (RAW10) or 0x2c (RAW12).
    mode-params.py FILE
"""
import struct
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import importlib.util
spec = importlib.util.spec_from_file_location("v3", Path(__file__).resolve().parent / "decode-regs-v3.py")
v3 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v3)

d = open(sys.argv[1], "rb").read()
Q = lambda o: struct.unpack_from("<Q", d, o)[0]
F = lambda o: struct.unpack_from("<d", d, o)[0]
L, S = v3.lists(d), v3.sections(d)
modes = [(o, regs) for i, (o, regs) in enumerate(L) if i < len(S) and "integrationInfo" in S[i][1]]
# All mode headers come first (in mode order), then [stream dims, list] pairs.
first = modes[0][0]
heads = []
for p in range(max(first - 0x4000, 8), first, 8):
    f = F(p)
    if 1.0 <= f <= 480.0 and Q(p + 8) in (1, 2, 3, 4) and 1e6 < Q(p - 0x18) < 1e10:
        heads.append(p)
heads = heads[-len(modes):]
for n, ((o, regs), h) in enumerate(zip(modes, heads)):
    dims = None
    for p in range(o - 0x28, o - 0x400, -8):
        w, ht, b = Q(p), Q(p + 8), Q(p + 16)
        if 64 <= w <= 16384 and 64 <= ht <= 16384 and b in (8, 10, 12, 14):
            dims = (w, ht, b, Q(p - 0x18))
            break
    ll, fl, clk = Q(h - 0x38), Q(h - 0x30), Q(h - 0x18)
    print(f"modo {n + 1}: lista {len(regs)} escritas @ {o:#x}  "
          + (f"{dims[0]}x{dims[1]} {dims[2]}b dt={dims[3]:#x}  " if dims else "")
          + f"fps {F(h):.3f} lanes {Q(h + 8)} line {ll} frame {fl} "
          f"minHB {Q(h - 0x28)} minVB {Q(h - 0x20)} outClk {clk / 1e6:.1f} MHz "
          f"(link {clk * 10 / 2 / Q(h + 8) / 1e6:.1f} MHz/lane DDR se RAW10)")
