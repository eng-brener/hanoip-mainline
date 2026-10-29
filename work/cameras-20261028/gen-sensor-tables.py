#!/usr/bin/env python3
"""Generate C register tables from a CamX sensormodule.bin (via decode-regs-v3).

    gen-sensor-tables.py BIN PREFIX OUT.h NAME=LIST [NAME=LIST ...]

Every entry keeps its data width (dt 1 = 8 bit, 2 = 16 bit) and its delay,
so one table may mix widths (the S5KHM2 init does). Burst writes come out
already expanded by decode-regs-v3.
"""
import importlib.util
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location("v3", here / "decode-regs-v3.py")
v3 = importlib.util.module_from_spec(spec)
spec.loader.exec_module(v3)

binf, prefix, out = sys.argv[1], sys.argv[2], sys.argv[3]
want = [a.split("=") for a in sys.argv[4:]]
d = open(binf, "rb").read()
L, S = v3.lists(d), v3.sections(d)
with open(out, "w") as f:
    f.write("/* SPDX-License-Identifier: GPL-2.0 */\n")
    f.write(f"/* Generated from {Path(binf).name} by gen-sensor-tables.py. */\n\n")
    for name, idx in want:
        o, regs = L[int(idx) - 1]
        sec = S[int(idx) - 1][1] if int(idx) - 1 < len(S) else "?"
        f.write(f"/* list {idx} ({sec}), {len(regs)} writes */\n")
        f.write(f"static const struct {prefix}_reg {prefix}_{name}[] = {{\n")
        for addr, data, delay, at, dt, op in regs:
            assert op in (0, 1) and addr <= 0xffff and data <= 0xffff, (addr, data, op)
            w = 16 if dt == 2 else 8
            f.write(f"\t{{ 0x{addr:04x}, 0x{data:0{w // 4}x}, {w}, {delay} }},\n")
        f.write("};\n\n")
