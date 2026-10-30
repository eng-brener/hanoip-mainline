#!/usr/bin/env python3
"""Lista alvos de bl/b dentro de um intervalo de VA do keymaster_a.img.

Uso: range_calls.py IMG STARTVA ENDVA
Somente leitura local; decodifica palavras de 4 bytes (sem seguir fluxo).
"""
import struct
import sys

IMG, S, E = sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0)
BASE = 0x100000
FILE_BIAS = 0x3000


def va_to_off(va):
    return va - BASE + FILE_BIAS


with open(IMG, "rb") as f:
    f.seek(va_to_off(S))
    code = f.read(E - S)

calls = {}
for i in range(0, len(code) - 3, 4):
    w = struct.unpack_from("<I", code, i)[0]
    va = S + i
    mn = None
    if w >> 26 == 0x25:
        mn = "bl"
    elif w >> 26 == 0x05:
        mn = "b"
    if mn:
        imm = w & 0x03FFFFFF
        if imm & 0x02000000:
            imm -= 0x04000000
        tgt = (va + imm * 4) & 0xFFFFFFFFFFFF
        calls.setdefault((mn, tgt), []).append(va)

for (mn, tgt), sites in sorted(calls.items(), key=lambda kv: (kv[0][0], kv[0][1])):
    print("%-2s 0x%06x  %s" % (mn, tgt, ", ".join("0x%06x" % s for s in sites)))
