#!/usr/bin/env python3
"""fdt_diff.py — compara duas device trees (.dtb) propriedade por propriedade.

Uso:
    ./fdt_diff.py a.dtb b.dtb            # mostra diferenças
    ./fdt_diff.py a.dtb b.dtb --quiet    # só o resumo

Existe porque neste projeto a DT efetiva vem EMBUTIDA no U-Boot
(CONFIG_OF_EMBED): para provar que uma variante muda só o que se espera
(bateria, painel, ...) é preciso diferir os .dtb construídos, não as fontes.
"""
import struct
import sys

FDT_MAGIC = 0xD00DFEED
BEGIN_NODE, END_NODE, PROP, NOP, END = 1, 2, 3, 4, 9


def parse(path):
    data = open(path, 'rb').read()
    magic, total, off_struct, off_strings, _rsv, _ver, _last, _cpu, size_str, _ = \
        struct.unpack_from('>10I', data, 0)
    if magic != FDT_MAGIC:
        raise SystemExit(f'{path}: não é um FDT (magic={magic:#x})')

    strings = data[off_strings:off_strings + size_str]
    pos = off_struct
    path_stack = []
    props = {}

    while True:
        (tok,) = struct.unpack_from('>I', data, pos)
        pos += 4
        if tok == NOP:
            continue
        if tok == END:
            break
        if tok == BEGIN_NODE:
            end = data.index(b'\0', pos)
            name = data[pos:end].decode(errors='replace')
            pos = (end + 4) & ~3
            path_stack.append(name)
            props.setdefault('/' + '/'.join(p for p in path_stack if p), {})
            continue
        if tok == END_NODE:
            if path_stack:
                path_stack.pop()
            continue
        if tok == PROP:
            length, nameoff = struct.unpack_from('>2I', data, pos)
            pos += 8
            value = data[pos:pos + length]
            pos = (pos + length + 3) & ~3
            end = strings.index(b'\0', nameoff)
            name = strings[nameoff:end].decode(errors='replace')
            node = '/' + '/'.join(p for p in path_stack if p)
            props.setdefault(node, {})[name] = value
            continue
        raise SystemExit(f'{path}: token inesperado {tok} em {pos - 4}')
    return props


def fmt(value):
    # Strings primeiro: "otg" tem exatamente 4 bytes (3 letras + NUL) e era
    # impresso como inteiro (1869899520), o que já causou confusão ao conferir
    # o dr_mode. Um valor terminado em NUL e todo imprimível é string.
    if value.endswith(b'\0') and all(32 <= c < 127 or c == 0 for c in value):
        return f'"{value.rstrip(chr(0).encode()).decode(errors="replace")}"'
    if len(value) % 4 == 0 and len(value) <= 64:
        vals = struct.unpack(f'>{len(value) // 4}I', value)
        return ' '.join(str(v) for v in vals)
    text = ''.join(chr(c) if 32 <= c < 127 else '.' for c in value)
    return f'"{text.strip(chr(0))}"'


def main():
    if len(sys.argv) < 3:
        raise SystemExit(__doc__)
    a, b = parse(sys.argv[1]), parse(sys.argv[2])
    quiet = '--quiet' in sys.argv

    added = [(n, p, b[n][p]) for n in b if n not in a for p in b[n]]
    removed = [(n, p, a[n][p]) for n in a if n not in b for p in a[n]]
    changed = [(n, p, a[n][p], b[n][p])
               for n in a if n in b for p in a[n] if p in b[n] and a[n][p] != b[n][p]]
    only_a = [(n, p) for n in a if n in b for p in a[n] if p not in b[n]]
    only_b = [(n, p) for n in b if n in a for p in b[n] if p not in a[n]]

    print(f'A: {sys.argv[1]}  ({len(a)} nós)')
    print(f'B: {sys.argv[2]}  ({len(b)} nós)')
    print(f'diferenças: nós novos={len(added)} nós removidos={len(removed)} '
          f'props alteradas={len(changed)} props só em A={len(only_a)} só em B={len(only_b)}')
    if quiet:
        return
    for name, prop, val in added:
        print(f'  + nó (só em B): {name} {prop} = {fmt(val)}')
    for name, prop, val in removed:
        print(f'  - nó (só em A): {name} {prop} = {fmt(val)}')
    for name, prop in sorted(only_b):
        print(f'  + {name} {prop} = {fmt(b[name][prop])}')
    for name, prop in sorted(only_a):
        print(f'  - {name} {prop} = {fmt(a[name][prop])}')
    for name, prop, va, vb in sorted(changed):
        print(f'  ~ {name} {prop}: {fmt(va)}  ->  {fmt(vb)}')


if __name__ == '__main__':
    main()
