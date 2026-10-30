#!/usr/bin/env python3
"""Varredura linear AArch64 do keymaster_a.img para mapear chamadas bl.

Somente leitura do arquivo local. Heuristica: decodifica toda a regiao de
codigo como palavras de 4 bytes e registra alvos de bl/b imediatos. Nao prova
execucao; apenas mostra arestas estaticas possiveis.
"""
import struct
import sys
from collections import defaultdict, deque

IMG = sys.argv[1]
BASE = 0x100000
FILE_BIAS = 0x3000
CODE_START = 0x100000          # Ghidra VA
CODE_END = 0x136000

# alvos de interesse (VA)
TARGETS = {
    0x115cfc: "gk_modify_user_data(FUN_00115cfc)",
    0x11585c: "sync/save(FUN_0011585c)",
    0x11b224: "gk_write_platform(FUN_0011b224)",
    0x11b87c: "open_storage_platform(FUN_0011b87c)",
    0x11b138: "bloco/tamanho setor",
    0x116268: "FUN_00116268 (cripto bloco)",
    0x118494: "handler 0x205 GET_AUTH_TOKEN_KEY",
    0x115428: "gk storage init (FUN_00115428)",
    0x115f6c: "FUN_00115f6c",
    0x115ec0: "sfs_rpmb_set(FUN_00115ec0)",
    0x10415c: "GK_NEW_ENROLL",
    0x104bf0: "GK_NEW_VERIFY",
    0x104f5c: "GK_NEW_DELETE_USER",
    0x105008: "GK_NEW_DELETE_ALL",
}


def va_to_off(va):
    return va - BASE + FILE_BIAS


def load():
    with open(IMG, "rb") as f:
        f.seek(va_to_off(CODE_START))
        return f.read(CODE_END - CODE_START)


def scan(code):
    edges = defaultdict(set)      # origem -> {destinos}
    callers = defaultdict(set)    # destino -> {origens}
    for i in range(0, len(code) - 3, 4):
        w = struct.unpack_from("<I", code, i)[0]
        va = CODE_START + i
        op = w >> 26
        if op == 0x25:  # bl
            imm = w & 0x03FFFFFF
            if imm & 0x02000000:
                imm -= 0x04000000
            tgt = (va + imm * 4) & 0xFFFFFFFFFFFF
            if CODE_START <= tgt < CODE_END:
                edges[va].add(tgt)
                callers[tgt].add(va)
    return edges, callers


def main():
    code = load()
    edges, callers = scan(code)
    print("instrucoes de codigo varridas: %d; arestas bl: %d" %
          (len(code) // 4, sum(len(v) for v in edges.values())))

    for t, name in sorted(TARGETS.items()):
        cs = sorted(callers.get(t, ()))
        print("\n%s  0x%06x  chamado de %d sitio(s)" % (name, t, len(cs)))
        for c in cs[:40]:
            print("   origem 0x%06x" % c)
        if len(cs) > 40:
            print("   ... %d sitios omitidos" % (len(cs) - 40))

    # alcancabilidade a partir dos handlers
    starts = [0x10415c, 0x104bf0, 0x104f5c, 0x105008, 0x118494]
    print("\n=== alcancabilidade a partir dos handlers (heuristica bl) ===")
    for s in starts:
        seen = {s}
        q = deque([s])
        found = defaultdict(list)
        while q:
            cur = q.popleft()
            for nxt in edges.get(cur, ()):
                if nxt in TARGETS and nxt not in seen:
                    found[nxt].append(cur)
                if nxt not in seen:
                    seen.add(nxt)
                    q.append(nxt)
        names = ", ".join("0x%06x(%s)" % (k, TARGETS[k]) for k in sorted(found))
        print("0x%06x -> %d funcoes alcancadas; alvos: %s" % (s, len(seen), names or "nenhum"))


if __name__ == "__main__":
    main()
