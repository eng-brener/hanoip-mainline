#!/usr/bin/env python3
"""Resolve enderecos do fpctzapp.elf para o simbolo dinamico mais proximo.

Uso: symat.py 0x30cc 0x87aa ...
Le symbols.txt (readelf -W) e imprime simbolo, deslocamento e tamanho.
"""
import sys

sym = []
with open("symbols.txt") as f:
    for line in f:
        p = line.split()
        if len(p) >= 8 and p[0].endswith(":") and p[2].isdigit() is False:
            pass
        if len(p) >= 8 and p[3] in ("FUNC", "OBJECT", "NOTYPE") and p[6].isdigit():
            sym.append((int(p[1], 16), int(p[2]), p[3], p[7]))
sym.sort()

for a in sys.argv[1:]:
    addr = int(a, 16)
    best = None
    for s in sym:
        if s[0] <= addr:
            best = s
        else:
            break
    if best:
        off = addr - best[0]
        inside = off < best[1] if best[1] else None
        print("%s -> %s+0x%x (%s, size %d, dentro=%s)" % (a, best[3], off, best[2], best[1], inside))
    else:
        print("%s -> (nenhum simbolo anterior)" % a)
