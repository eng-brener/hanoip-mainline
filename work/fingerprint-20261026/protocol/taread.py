#!/usr/bin/env python3
"""Leitor mínimo de ELF32-LE para o TA fpctzapp (somente leitura de arquivo).

Uso típico:
    from taread import Ta
    ta = Ta('../../fpctzapp-reconstructed.elf')
    ta.u32(0x116000)

Mapeia VMA -> offset de arquivo pelos PT_LOAD e formata estruturas da TA.
Não executa o alvo.
"""
import struct
import sys


class Ta:
    def __init__(self, path):
        self.path = path
        self.data = open(path, 'rb').read()
        d = self.data
        if d[:4] != b'\x7fELF':
            raise SystemExit('não é ELF')
        self.is64 = d[4] == 2
        if self.is64:
            raise SystemExit('este leitor é para ELF32 (TA)')
        (self.e_type, self.e_machine, _ver, self.e_entry, self.e_phoff,
         self.e_shoff, _flags, _ehsize, self.e_phentsize, self.e_phnum,
         _shentsize, _shnum, _shstrndx) = struct.unpack_from('<HHIIIIIHHHHHH', d, 16)
        self.loads = []
        for i in range(self.e_phnum):
            off = self.e_phoff + i * self.e_phentsize
            p_type, p_off, p_vaddr, _pa, p_filesz, p_memsz, _fl, _al = \
                struct.unpack_from('<IIIIIIII', d, off)
            if p_type == 1:  # PT_LOAD
                self.loads.append((p_vaddr, p_vaddr + p_memsz, p_off, p_filesz))

    def off(self, vma):
        for start, end, foff, filesz in self.loads:
            if start <= vma < end:
                delta = vma - start
                if delta >= filesz:
                    return None
                return foff + delta
        return None

    def read(self, vma, n):
        o = self.off(vma)
        if o is None:
            raise SystemExit('VMA não mapeada: %#x' % vma)
        return self.data[o:o + n]

    def u32(self, vma):
        return struct.unpack('<I', self.read(vma, 4))[0]

    def u16(self, vma):
        return struct.unpack('<H', self.read(vma, 2))[0]

    def u8(self, vma):
        return self.read(vma, 1)[0]

    def cstr(self, vma, limit=200):
        o = self.off(vma)
        if o is None:
            return None
        end = self.data.find(b'\0', o, o + limit)
        if end < 0:
            return None
        return self.data[o:end].decode('utf-8', 'replace')

    def dump(self, vma, n, label=''):
        b = self.read(vma, n)
        if label:
            print('%s @ %#x (%d bytes)' % (label, vma, n))
        for i in range(0, len(b), 16):
            chunk = b[i:i + 16]
            hx = ' '.join('%02x' % c for c in chunk)
            asc = ''.join(chr(c) if 32 <= c < 127 else '.' for c in chunk)
            print('  %08x  %-47s  %s' % (vma + i, hx, asc))


if __name__ == '__main__':
    ta = Ta(sys.argv[1])
    for a in sys.argv[2:]:
        ta.dump(int(a, 16), 64)


def thumb_bl_scan(ta, target, lo=0x0, hi=0x114138):
    """Varre a faixa de texto Thumb procurando BL/BLX imediato para `target`."""
    hits = []
    for a in range(lo, hi - 4, 2):
        try:
            h1, h2 = struct.unpack_from('<HH', ta.data, ta.off(a) or 0)
        except Exception:
            continue
        o = ta.off(a)
        if o is None:
            continue
        h1, h2 = struct.unpack_from('<HH', ta.data, o)
        if (h1 & 0xF800) == 0xF000 and (h2 & 0xC000) == 0xC000:
            imm = ((h1 & 0x7FF) << 12) | ((h2 & 0x7FF) << 1)
            if imm & (1 << 22):
                imm -= (1 << 23)
            dst = (a + 4 + imm) & 0xFFFFFFFF
            if dst in target:
                kind = 'BLX' if (h2 & 0x1000) == 0 else 'BL'
                hits.append((a, dst, kind))
    return hits
