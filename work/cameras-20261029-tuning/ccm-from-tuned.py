#!/usr/bin/env python3
"""Extract the colour correction matrices (Qualcomm cc13) from a CamX
com.qti.tuned.*.bin and print a libcamera softISP tuning file.

Layout found on the S5K4H7 tuning (29/10): CCT regions are 0x48-byte
entries, the region bounds [start, end] stored as two floats in 8-byte slots
right before nine packed floats (row-major RGB CCM, rows sum to 1) followed
by three zero offsets. The longest run of regions with increasing CCT bounds
(1500..12000 K) is a normal-light table; the FIRST such table is the
sensor's own (the later ones repeat the S5KHM2 table); every region becomes one ct entry
at the middle of its range (libcamera interpolates between them).

    ccm-from-tuned.py TUNED.bin SENSOR-NAME > sensor.yaml
"""
import struct
import sys

path, name = sys.argv[1], sys.argv[2]
d = open(path, "rb").read()
F = lambda o, n=1: struct.unpack_from(f"<{n}f", d, o)


def is_ccm(o):
    f = F(o, 9)
    if any(x != x or abs(x) > 4 for x in f):
        return False
    if not all(1.0 < f[i] < 3.5 for i in (0, 4, 8)):
        return False
    return all(abs(sum(f[3 * k:3 * k + 3]) - 1) < 0.02 for k in range(3))


runs, o = [], 0
while o + 0x48 * 2 < len(d):
    if not is_ccm(o):
        o += 4
        continue
    run, p = [], o
    while p + 36 <= len(d) and is_ccm(p):
        lo, hi = F(p - 16)[0], F(p - 8)[0]
        run.append((lo, hi, F(p, 9)))
        p += 0x48
    runs.append((o, run))
    o = p


def good(run):
    rs = [(lo, hi) for lo, hi, _ in run]
    return all(1500 <= lo < hi <= 12000 for lo, hi in rs) and \
        all(rs[i][1] <= rs[i + 1][0] for i in range(len(rs) - 1))


cands = []
for o, run in runs:
    # the first entry of a table may carry a trigger, not a CCT range: drop it
    for skip in range(len(run)):
        if len(run) - skip >= 3 and good(run[skip:]):
            cands.append((len(run) - skip, o + 0x48 * skip, run[skip:]))
            break
if not cands:
    sys.exit("no CCT-ordered CCM table found")
# The first table is the sensor's own; later ones repeat the main camera's
# (S5KHM2) table, apparently to match colours across cameras (29/10).
n, off, table = min(cands, key=lambda c: c[1])
print("# SPDX-License-Identifier: CC0-1.0")
print(f"# {name}: softISP tuning with the vendor CCMs (cc13 table at {off:#x} of")
print(f"# {path.rsplit('/', 1)[-1]}, {n} CCT regions, ct = middle of each range).")
print("# Black level 64 @ 10 bits = 4096 @ 16 bits, measured on this phone.")
print("%YAML 1.1\n---\nversion: 1\nalgorithms:")
print("  - BlackLevel:\n      blackLevel: 4096\n  - Awb:\n  - Ccm:\n      ccms:")
for lo, hi, m in table:
    ct = int(round((lo + min(hi, 7500)) / 2 / 100) * 100)
    rows = ",\n                 ".join(", ".join(f"{x:7.4f}" for x in m[3 * k:3 * k + 3]) for k in range(3))
    print(f"        - ct: {ct}   # {lo:.0f}-{hi:.0f} K\n          ccm: [ {rows} ]")
print("  - Adjust:\n  - Agc:\n...")
