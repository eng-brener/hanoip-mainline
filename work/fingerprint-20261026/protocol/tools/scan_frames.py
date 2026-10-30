#!/usr/bin/env python3
"""Varre o HAL e lista os frames {u32 module_id, u32 cmd_id} usados por funcao.

Detecta o padrao
    adrp x9, 0xe000
    ldr  d0, [x9, #imm]        -> constante de 8 bytes em rodata = {module, cmd}
e o caso
    movi v0.2s, #N             -> {N, N}
Somoente leitura; nao executa o alvo.
"""
import json
import os
import re
import struct
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
HAL = os.path.join(ROOT, 'android-live-readonly', 'programs', 'fingerprint-service-fpc')
SYM = os.path.join(ROOT, 'hal-protocol', 'fingerprint-service-fpc-symbols.json')
OD = ('/Volumes/SSDExterno/Applications/Xcode.app/Contents/Developer/Toolchains/'
      'XcodeDefault.xctoolchain/usr/bin/llvm-objdump')

data = open(HAL, 'rb').read()
syms = json.load(open(SYM))
funcs = []
for s in syms:
    v = int(s['value'], 16) if isinstance(s['value'], str) else s['value']
    funcs.append((v, v + (s['size'] or 0), s['name']))


def fname(addr):
    for lo, hi, n in funcs:
        if lo <= addr < hi:
            return n
    return None


def pair(addr):
    return struct.unpack_from('<II', data, addr)


out = subprocess.run([OD, '-d', '--triple=aarch64', '--start-address=0x12000',
                      '--stop-address=0x26f20', HAL], capture_output=True, text=True)
lines = out.stdout.splitlines()
res = {}
for i, ln in enumerate(lines):
    m = re.search(r'^\s+([0-9a-f]+):\s+[0-9a-f]+\s+adrp\s+x(\d+), 0x([0-9a-f]+)', ln)
    if not m:
        continue
    a = int(m.group(1), 16)
    reg = m.group(2)
    page = int(m.group(3), 16)
    if i + 1 >= len(lines):
        continue
    nxt = lines[i + 1]
    m2 = re.search(r'ldr\s+d0, \[x%s, #(0x[0-9a-f]+)\]' % reg, nxt)
    if m2:
        addr = page + int(m2.group(1), 16)
        if 0xe000 <= addr < 0xe200:
            res.setdefault(fname(a), []).append((a, addr, pair(addr)))
    m3 = re.search(r'movi\s+v0\.2s, #(0x[0-9a-f]+|\d+)', nxt)
    if m3:
        n = int(m3.group(1), 0)
        res.setdefault(fname(a), []).append((a, None, (n, n)))

for fn in sorted(res, key=lambda k: (k is None, k)):
    for a, addr, pr in sorted(res[fn]):
        print('%-46s %#08x const=%s -> module=%d cmd=%d' %
              (fn or '?', a, ('%#x' % addr) if addr else 'movi', pr[0], pr[1]))
