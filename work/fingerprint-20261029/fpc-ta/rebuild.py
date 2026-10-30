#!/usr/bin/env python3
"""Reconstroi a imagem ELF do app TEE fpctzapp a partir de mdt + b01..b07.

Layout derivado dos cabecalhos de programa do mdt (ELF 32-bit ARM).
Escreve fpctzapp.elf ao lado. Somente arquivos locais.
"""
import struct

OUT = "fpctzapp.elf"
LAYOUT = [
    (0x0000, "fpctzapp.mdt", 0x1000),
    (0x1000, "fpctzapp.b01"),
    (0x3000, "fpctzapp.b02"),
    (0x117138, "fpctzapp.b03"),
    (0x117250, "fpctzapp.b04"),
    (0x2CFDF4, "fpctzapp.b05"),
    (0x2D0178, "fpctzapp.b07"),
]


def main():
    total = 0
    blobs = []
    for item in LAYOUT:
        off, name = item[0], item[1]
        limit = item[2] if len(item) > 2 else None
        with open(name, "rb") as f:
            data = f.read() if limit is None else f.read(limit)
        assert off >= total, "sobreposicao em %s" % name
        blobs.append((off, data))
        total = off + len(data)
    with open(OUT, "wb") as f:
        cur = 0
        for off, data in blobs:
            f.write(b"\0" * (off - cur))
            f.write(data)
            cur = off + len(data)
    print("gravado %s (%d bytes, 0x%x)" % (OUT, total, total))


if __name__ == "__main__":
    main()
