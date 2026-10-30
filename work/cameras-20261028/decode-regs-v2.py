#!/usr/bin/env python3
"""Decode CamX com.qti.sensormodule.*.bin register lists (v2).

Each list is N writes of 10 words (80 bytes):
    [t, regAddr, nData] [t+1, addrType, dataType, op, ?] [t+2, ?]
and is followed by a pool of N 16-byte entries [regData, delayUs].
Found on 2026-10-28 by aligning the OV02B1B init list against known values
(0x24=0x02, 0x25=0x06, 0x29=0x03, 0x2a=0x34, 0x1e=0x17, ...): data(k) is the
first word of entry k when the pool starts 8 bytes before the list end.
    decode-regs-v2.py FILE [MIN_RUN]
"""
import struct
import sys

sys.path.insert(0, __file__.rsplit("/", 1)[0])


def main():
    path = sys.argv[1]
    min_run = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    d = open(path, "rb").read()
    W = lambda o: struct.unpack_from("<Q", d, o)[0] if o + 8 <= len(d) else None
    o = 0
    n = 0
    while o + 80 <= len(d):
        k = 0
        p = o
        while W(p) is not None and W(p + 24) == W(p) + 1 and W(p + 64) == W(p) + 2 \
                and W(p + 8) <= 0xffff and W(p + 32) in (1, 2) and W(p + 40) in (1, 2) and W(p) > 0:
            k += 1
            p += 80
        if k >= min_run:
            n += 1
            pool = p - 8
            print(f"# lista {n}: {k} escritas @ {o:#x} (pool @ {pool:#x})")
            for i in range(k):
                addr = W(o + 80 * i + 8)
                at = W(o + 80 * i + 32)
                data, delay = W(pool + 16 * i), W(pool + 16 * i + 8)
                w = 4 if at == 2 else 2
                print(f"  0x{addr:0{w}x} 0x{data:02x}" + (f"  delay={delay}us" if delay else ""))
            o = p
        else:
            o += 8


if __name__ == "__main__":
    main()
