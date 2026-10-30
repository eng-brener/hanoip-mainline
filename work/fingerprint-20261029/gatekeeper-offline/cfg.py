#!/usr/bin/env python3
"""Percorre o fluxo de controle de uma funcao AArch64 do keymaster_a.img.

Uso: cfg.py IMG STARTVA [STOP_VA]
Decodifica apenas o subconjunto necessario para seguir o fluxo (b, bl, b.cond,
cbz/cbnz, tbz/tbnz, ret, br/blr) e imprime:
  - os alvos de bl alcancados (possiveis chamadas),
  - chamadas indiretas (blr/br) explicitamente marcadas,
  - se a funcao alcanca cada endereco listado em WATCH.
Somente leitura do arquivo local.
"""
import struct
import sys

IMG, START = sys.argv[1], int(sys.argv[2], 0)
BASE = 0x100000
FILE_BIAS = 0x3000
CODE_START, CODE_END = 0x100000, 0x136000

WATCH = {
    0x115cfc: "gk_modify_user_data",
    0x11585c: "sync (gk salvar)",
    0x11b224: "gk_write_platform",
    0x11b87c: "open_storage_platform",
    0x115428: "gk storage init",
    0x115f6c: "FUN_00115f6c",
    0x115ec0: "sfs_rpmb_set",
    0x116268: "cripto bloco",
    0x11b380: "gk_read_platform",
}


def va_to_off(va):
    return va - BASE + FILE_BIAS


def load_window(start, size=0x4000):
    with open(IMG, "rb") as f:
        f.seek(va_to_off(start))
        return f.read(size)


def decode(code, va):
    off = va - CODE_START
    if off < 0 or off + 4 > len(code):
        return None
    w = struct.unpack_from("<I", code, off)[0]
    if w == 0xD65F03C0 or (w & 0xFFFFFC1F) == 0xD65F0000:
        return ("ret", None)
    if w & 0xFFFFFC1F == 0xD61F0000:
        return ("br", None)
    if w & 0xFFFFFC1F == 0xD63F0000:
        return ("blr", None)
    if w >> 26 == 0x25:
        imm = w & 0x03FFFFFF
        if imm & 0x02000000:
            imm -= 0x04000000
        return ("bl", (va + imm * 4) & 0xFFFFFFFFFFFF)
    if w >> 26 == 0x05:
        imm = w & 0x03FFFFFF
        if imm & 0x02000000:
            imm -= 0x04000000
        return ("b", (va + imm * 4) & 0xFFFFFFFFFFFF)
    if (w & 0xFF000010) == 0x54000000:
        imm = (w >> 5) & 0x7FFFF
        if imm & 0x40000:
            imm -= 0x80000
        return ("bcond", (va + imm * 4) & 0xFFFFFFFFFFFF)
    if (w & 0x7E000000) in (0x34000000, 0x36000000):
        imm = (w >> 5) & 0x7FFFF
        if imm & 0x40000:
            imm -= 0x80000
        return ("cb", (va + imm * 4) & 0xFFFFFFFFFFFF)
    return ("other", None)


def main():
    code = load_window(0x100000, CODE_END - CODE_START)
    seen = set()
    work = [START]
    calls = {}
    indirect = []
    while work:
        cur = work.pop()
        if cur in seen or not (CODE_START <= cur < CODE_END):
            continue
        seen.add(cur)
        kind, tgt = decode(code, cur)
        if kind is None:
            continue
        if kind == "ret":
            continue
        if kind == "br":
            indirect.append(("br", cur))
            continue
        if kind == "blr":
            indirect.append(("blr", cur))
            work.append(cur + 4)
            continue
        if kind == "bl":
            calls.setdefault(tgt, []).append(cur)
            work.append(cur + 4)
            continue
        if kind == "b":
            if CODE_START <= tgt < CODE_END:
                work.append(tgt)
            continue
        if kind in ("bcond", "cb"):
            work.append(cur + 4)
            if CODE_START <= tgt < CODE_END:
                work.append(tgt)
            continue
        work.append(cur + 4)

    print("funcao em 0x%06x: %d instrucoes no fluxo" % (START, len(seen)))
    print("\nchamadas (bl) alcancadas:")
    for t in sorted(calls):
        extra = "   <== %s" % WATCH[t] if t in WATCH else ""
        print("  0x%06x  de %s%s" % (t, ", ".join("0x%06x" % s for s in sorted(calls[t])), extra))
    if indirect:
        print("\nchamadas/ramos indiretos (nao resolvidos):")
        for k, a in indirect:
            print("  %s em 0x%06x" % (k, a))
    hit = sorted(set(calls) & set(WATCH))
    print("\nalvos monitorados alcancados: %s" %
          (", ".join("0x%06x(%s)" % (h, WATCH[h]) for h in hit) or "nenhum"))


if __name__ == "__main__":
    main()
