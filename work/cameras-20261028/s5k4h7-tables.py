#!/usr/bin/env python3
"""Convert the decoded S5K4H7 vendor register lists into C tables.

The dump comes from decode-regs-v2.py. Samsung sensors use 16-bit register
addresses with 8-bit data, so entries with wider data are skipped and counted.
"""
import re
import sys

src, out = sys.argv[1], sys.argv[2]
text = open(src).read()
lists = re.split(r"^# lista ", text, flags=re.M)[1:]
tables = {}
for block in lists:
    index, body = block.split(":", 1)
    regs, skipped = [], 0
    for line in body.splitlines()[1:]:
        line = line.strip()
        if not line.startswith("0x"):
            continue
        addr, data = line.split()[:2]
        addr, data = int(addr, 16), int(data, 16)
        if addr > 0xffff or data > 0xffff:
            skipped += 1
            continue
        regs.append((addr, data))
    tables[int(index)] = (regs, skipped)

with open(out, "w") as f:
    f.write("/* SPDX-License-Identifier: GPL-2.0 */\n")
    f.write("/* Generated from com.qti.sensormodule.qtech_mot_hanoip_s5k4h7.bin"
            " by s5k4h7-tables.py. */\n\n")
    for index in sorted(tables):
        regs, skipped = tables[index]
        f.write(f"/* List {index}: {len(regs)} usable writes")
        if skipped:
            f.write(f", {skipped} skipped (wider than 8-bit data)")
        f.write(" */\n")
        name = f"s5k4h7_list{index}"
        wide = [r for r in regs if r[1] > 0xff]
        narrow = [r for r in regs if r[1] <= 0xff]
        if narrow:
            f.write(f"static const struct s5k4h7_reg {name}[] = {{\n")
            for addr, data in narrow:
                f.write(f"\t{{ 0x{addr:04x}, 0x{data:02x} }},\n")
            f.write("};\n\n")
        if wide:
            f.write(f"static const struct s5k4h7_reg16 {name}_w16[] = {{\n")
            for addr, data in wide:
                f.write(f"\t{{ 0x{addr:04x}, 0x{data:04x} }},\n")
            f.write("};\n\n")
        print(f"list {index}: {len(narrow)} x 8-bit, {len(wide)} x 16-bit, "
              f"{skipped} skipped")
