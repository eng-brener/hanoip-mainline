#!/usr/bin/env python3
"""Le a tabela de despacho do keymaster_a.img e classifica os handlers.

Somente leitura do arquivo local. Nao executa nada no aparelho.

Mapeamento VA->arquivo observado nos cabecalhos ELF (base Ghidra 0x100000):
  LOAD off=0x3000 vaddr=0x000000  -> VA = 0x100000 + vaddr
  logo file_off = VA - 0x100000 + 0x3000
"""
import struct
import sys

IMG = sys.argv[1] if len(sys.argv) > 1 else "keymaster_a.img"
BASE = 0x100000
FILE_BIAS = 0x3000

TABLE_VA = 0x137580
COUNT = 0x43
STRIDE = 0x10


def va_to_off(va):
    return va - BASE + FILE_BIAS


def read(f, va, n):
    f.seek(va_to_off(va))
    return f.read(n)


def main():
    with open(IMG, "rb") as f:
        f.seek(0, 2)
        size = f.tell()
        rows = []
        for i in range(COUNT):
            raw = read(f, TABLE_VA + i * STRIDE, STRIDE)
            if len(raw) < STRIDE:
                break
            cmd, fl1, fl2, _pad = struct.unpack("<IBBH", raw[:8])
            handler = struct.unpack("<Q", raw[8:16])[0]
            rows.append((i, cmd, fl1, fl2, handler))

        print("idx  cmd       f1 f2 handler    primeiras instrucoes")
        for i, cmd, fl1, fl2, h in rows:
            if h == 0:
                desc = "NULL"
            elif h < BASE or va_to_off(h) >= size:
                desc = "fora da imagem"
            else:
                b = read(f, h, 8)
                w0 = struct.unpack("<I", b[0:4])[0]
                w1 = struct.unpack("<I", b[4:8])[0]
                if (w0 & 0xFFE0001F) == 0x12800000 and w1 == 0xD65F03C0:
                    imm16 = (w0 >> 5) & 0xFFFF
                    desc = "STUB movn w0,#0x%x (ret) -> 0x%08x" % (imm16, (~imm16) & 0xFFFFFFFF)
                elif w1 == 0xD65F03C0:
                    desc = "stub curto w0=0x%08x ret" % w0
                else:
                    desc = "codigo: %s" % b.hex()
            print("%3d  0x%05x  %02x %02x 0x%08x %s" % (i, cmd, fl1, fl2, h, desc))


if __name__ == "__main__":
    main()
