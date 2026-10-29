#!/usr/bin/env python3
"""Decode CamX com.qti.sensormodule.*.bin register lists WITH their section.

v2 (decode-regs-v2.py) finds the lists by layout only, and the bare "list N"
numbering made us write the S5K4H7 OTP-read list as if it were the init
table. v3 pairs the lists, in file order, with the regSetting records of the
symbol table (parse-sensormodule.py), in record order, and names each list by
the section record that precedes its regSetting (resolutionData, initSettings,
streamOn..., EEPROM/actuator blocks).

Verified on the S5K4H7: resolution = 50 writes (3264x2448 mode), init = 44,
EEPROM regSetting = 497 (OTP read), actuator regSetting = 6.

Data pool (29/10, from the S5KHM2 burst writes): after the N 80-byte entries,
each entry owns registerData as nData u32 values padded to 8 bytes, then a u64
delayUs. Entry word 2 is nData and word 6 the operation (0 write, 1 burst
write of nData words to the same address, 3 = power/other). With nData = 1
this is the old fixed 16-byte [data, delay] pool. Burst writes to the
auto-incrementing 0x6f12 window are printed expanded, one write per word.

    decode-regs-v3.py FILE [--regs]
"""
import importlib.util
import struct
import sys
from pathlib import Path

here = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location(
    "psm", here.parent / "cameras-20261026" / "parse-sensormodule.py")
psm = importlib.util.module_from_spec(spec)
spec.loader.exec_module(psm)

SKIP = {"registerData", "delayUs", "slaveAddr", "registerAddr", "regAddrType",
        "regDataType", "operation", "[0]", "[1]", "[2]", "[3]", "[4]"}


def lists(d):
    """Register lists by layout, including 1-write lists (as in v2)."""
    W = lambda o: struct.unpack_from("<Q", d, o)[0] if o + 8 <= len(d) else None
    out, o = [], 0
    while o + 80 <= len(d):
        k, p = 0, o
        while W(p) is not None and W(p + 24) == W(p) + 1 and W(p + 64) == W(p) + 2 \
                and W(p + 8) <= 0xffff and W(p + 32) in (1, 2) and W(p + 40) in (1, 2) and W(p) > 0:
            k += 1
            p += 80
        if k:
            q = p - 8
            regs = []
            for i in range(k):
                addr, n = W(o + 80 * i + 8), W(o + 80 * i + 16)
                at, dt = W(o + 80 * i + 32), W(o + 80 * i + 40)
                op = W(o + 80 * i + 48)
                vals = [struct.unpack_from("<I", d, q + 4 * j)[0] for j in range(n)]
                q += (n * 4 + 7) // 8 * 8
                delay = W(q)
                q += 8
                for j, v in enumerate(vals):
                    regs.append((addr, v, delay if j == n - 1 else 0, at, dt, op))
            out.append((o, regs))
            o = p
        else:
            o += 8
    return out


def sections(d):
    """regSetting records in order, each labelled by the path of open sections."""
    out, ctx = [], []
    for off, name, v, a, c in psm.records(d):
        if name in SKIP:
            continue
        if name == "regSetting":
            out.append((off, "/".join(ctx[-2:]) or "?"))
        else:
            ctx.append(name)
    return out


def main():
    path = sys.argv[1]
    show = "--regs" in sys.argv
    d = open(path, "rb").read()
    L, S = lists(d), sections(d)
    print(f"# {Path(path).name}: {len(L)} listas, {len(S)} regSetting")
    if len(L) != len(S):
        print("# AVISO: contagens diferentes; o pareamento abaixo é só por ordem")
    for i, (o, regs) in enumerate(L):
        sec = S[i][1] if i < len(S) else "?"
        print(f"# lista {i + 1}: {len(regs)} escritas @ {o:#x}  seção: {sec}")
        if show:
            for addr, data, delay, at, dt, op in regs:
                w = 4 if at == 2 else 2
                dw = 4 if dt == 2 else 2
                print(f"  0x{addr:0{w}x} 0x{data:0{dw}x}  dt={dt} op={op}"
                      + (f"  delay={delay}us" if delay else ""))


if __name__ == "__main__":
    main()
