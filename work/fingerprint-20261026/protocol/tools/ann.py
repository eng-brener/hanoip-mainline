#!/usr/bin/env python3
"""Desmonta uma faixa do TA/HAL e anota alvos bl/bx com nomes de simbolos exportados.

Somente leitura de arquivo; nao executa o alvo.

Uso:
  python3 ann.py ta  0x3da4 0x3ff0     # faixa do TA
  python3 ann.py hal 0x1e2e0 0x1e3c0   # faixa do HAL
"""
import json
import os
import re
import struct
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
PROT = os.path.dirname(HERE)
ROOT = os.path.dirname(PROT)
OD = ('/Volumes/SSDExterno/Applications/Xcode.app/Contents/Developer/Toolchains/'
      'XcodeDefault.xctoolchain/usr/bin/llvm-objdump')

TA = os.path.join(ROOT, 'fpctzapp-reconstructed.elf')
HAL = os.path.join(ROOT, 'android-live-readonly', 'programs', 'fingerprint-service-fpc')
TA_SYM = os.path.join(ROOT, 'ta-dynamic-symbols.json')
HAL_SYM = os.path.join(ROOT, 'hal-protocol', 'fingerprint-service-fpc-symbols.json')


def load_syms(path, base=0):
    out = {}
    d = json.load(open(path))
    for s in d:
        v = s['value']
        v = int(v, 16) if isinstance(v, str) else int(v)
        out.setdefault(v, s['name'])
    return out


def sym_at(syms, addr):
    return syms.get(addr)


def dis(target, lo, hi, annotate=True):
    elf = TA if target == 'ta' else HAL
    triple = 'thumbv7' if target == 'ta' else 'aarch64'
    syms = load_syms(TA_SYM if target == 'ta' else HAL_SYM)
    p = subprocess.run([OD, '-d', '--triple=' + triple,
                        '--start-address=%d' % lo, '--stop-address=%d' % hi, elf],
                       capture_output=True, text=True)
    lines = p.stdout.splitlines()
    out = []
    for ln in lines:
        if not annotate:
            out.append(ln)
            continue
        m = re.search(r'\b(bl|blx|b|bx)\s+0x([0-9a-f]+)', ln)
        extra = ''
        if m:
            t = int(m.group(2), 16)
            nm = syms.get(t) or syms.get(t & ~1) or syms.get(t + 1)
            if nm:
                extra = '   <== %s' % nm
        out.append(ln + extra)
    return '\n'.join(out)


if __name__ == '__main__':
    tgt = sys.argv[1]
    lo = int(sys.argv[2], 0)
    hi = int(sys.argv[3], 0)
    print(dis(tgt, lo, hi))
