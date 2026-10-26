#!/usr/bin/env python3
"""Pull CCI register sequences out of a CamX com.qti.sensormodule.*.bin.

The data area is a stream of 8-byte words. Each register write shows up as
three tagged groups with consecutive tags t, t+1, t+2:
    [t,   regAddr, regData]
    [t+1, regAddrType, regDataType, operation, x]
    [t+2, delayUs]
Runs of such writes are the vendor's regSetting lists (power, init, modes,
stream on/off). Read-only on a local copy of the blob.
    decode-regs.py FILE [MIN_RUN]
"""
import struct
import sys


def words(path):
    d = open(path, "rb").read()
    # The tagged stream starts after the type table (nodes of 72 bytes).
    off = 0
    while off + 72 <= len(d):
        u = struct.unpack_from("<2I", d, off)
        name = d[off + 32:off + 64].split(b"\x00")[0]
        if u[0] == 0xFFFFFFFF and u[1] == 0 and len(name) >= 2 and all(32 <= c < 127 for c in name):
            last = off
            off += 72
        else:
            off += 1
    base = last + 72
    n = (len(d) - base) // 8
    return base, [struct.unpack_from("<Q", d, base + 8 * i)[0] for i in range(n)]


def writes_at(q, i):
    """Decode consecutive writes starting at index i; return (list, next i)."""
    out = []
    while i + 10 < len(q):
        t = q[i]
        if not (q[i + 3] == t + 1 and q[i + 8] == t + 2):
            break
        addr, data = q[i + 1], q[i + 2]
        atype, dtype, op = q[i + 4], q[i + 5], q[i + 6]
        if atype not in (1, 2) or dtype not in (1, 2) or addr > 0xffff or data > 0xffff:
            break
        out.append((addr, data, atype, dtype, op, q[i + 9]))
        i += 10
    return out, i


def main():
    path = sys.argv[1]
    min_run = int(sys.argv[2]) if len(sys.argv) > 2 else 2
    base, q = words(path)
    i = 0
    n = 0
    while i < len(q):
        run, j = writes_at(q, i)
        if len(run) >= min_run:
            n += 1
            print(f"# lista {n}: {len(run)} escritas @ {base + 8 * i:#x}")
            for a, v, at, dt, op, dl in run:
                w = 4 if at == 2 else 2
                print(f"  0x{a:0{w}x} 0x{v:02x}" + (f"  op={op}" if op else "") + (f"  delay={dl}us" if dl else ""))
            i = j
        else:
            i += 1


if __name__ == "__main__":
    main()
