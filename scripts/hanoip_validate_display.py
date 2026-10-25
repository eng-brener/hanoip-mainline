#!/usr/bin/env python3
"""Read-only local checks of the effective display DT and memory baseline."""
import argparse
import json
from pathlib import Path
import struct


def read_fdt(path):
    blob = Path(path).read_bytes()
    magic, total, off_struct, off_strings = struct.unpack_from('>4I', blob)
    if magic != 0xd00dfeed or total != len(blob):
        raise ValueError('Invalid FDT header')
    cursor, stack, tree = off_struct, [], {}
    while cursor < total:
        token = struct.unpack_from('>I', blob, cursor)[0]
        cursor += 4
        if token == 1:
            end = blob.index(0, cursor)
            stack.append(blob[cursor:end].decode())
            tree['/'.join(stack) or '/'] = {}
            cursor = (end + 4) & ~3
        elif token == 2:
            stack.pop()
        elif token == 3:
            size, nameoff = struct.unpack_from('>2I', blob, cursor)
            cursor += 8
            begin = off_strings + nameoff
            name = blob[begin:blob.index(0, begin)].decode()
            tree['/'.join(stack) or '/'][name] = blob[cursor:cursor + size]
            cursor = (cursor + size + 3) & ~3
        elif token == 4:
            continue
        elif token == 9:
            return tree
        else:
            raise ValueError(f'Unexpected FDT token {token}')
    raise ValueError('FDT has no end token')


def u32s(value):
    return struct.unpack('>' + 'I' * (len(value) // 4), value)


def validate(baseline, candidate, config):
    base, tree = read_fdt(baseline), read_fdt(candidate)
    memory = {p: v['reg'] for p, v in tree.items() if v.get('device_type') == b'memory\0'}
    expected = {p: v['reg'] for p, v in base.items() if v.get('device_type') == b'memory\0'}
    assert memory == expected, 'RAM layout changed from known-good'
    assert len(memory) == 1
    assert u32s(next(iter(memory.values()))) == (0, 0x80000000, 0, 0xfdd00000)
    # Adding a backlight reference can renumber unrelated phandles.
    reserved = lambda t: {p: {k: val for k, val in v.items() if k not in ('phandle', 'linux,phandle')}
                          for p, v in t.items() if p.startswith('/reserved-memory')}
    assert reserved(tree) == reserved(base), 'Reserved-memory differs from known-good'
    ranges = []
    for p, v in reserved(tree).items():
        if 'reg' not in v:
            continue
        cells = u32s(v['reg'])
        for i in range(0, len(cells), 4):
            start = (cells[i] << 32) | cells[i + 1]
            size = (cells[i + 2] << 32) | cells[i + 3]
            assert 0x80000000 <= start < start + size <= 0x17dd00000, f'Reservation outside RAM: {p}'
            ranges.append((start, start + size, p))
    ranges.sort()
    for left, right in zip(ranges, ranges[1:]):
        assert left[1] <= right[0], f'Reserved-memory overlap: {left[2]}, {right[2]}'
    for p, v in tree.items():
        compatible = v.get('compatible', b'')
        if b'ufshc\0' in compatible or b'ufs-phy' in compatible:
            assert v.get('status') == b'disabled\0', f'UFS enabled: {p}'
    panel = next(v for v in tree.values() if v.get('compatible') == b'tianma,ili7807s-hanoip\0')
    assert 'backlight' in panel
    wled = next(v for v in tree.values() if v.get('compatible') == b'qcom,pm6150l-wled\0')
    assert u32s(wled['qcom,enabled-strings']) == (0, 1, 2)
    assert u32s(wled['default-brightness']) == (512,)
    cfg = Path(config).read_text()
    for line in ['CONFIG_ANDROID_BOOT_IMAGE_IGNORE_BLOB_ADDR=y',
                 'CONFIG_OF_EMBED=y', '# CONFIG_FASTBOOT_FLASH is not set',
                 '# CONFIG_SCSI is not set']:
        assert line in cfg, f'Missing U-Boot protection: {line}'
    assert not any(line.startswith('CONFIG_UFS=') for line in cfg.splitlines())
    return {'ram_end': '0x17dd00000', 'memory_matches_known_good': True,
            'reserved_memory_matches_known_good': True, 'reserved_ranges': len(ranges),
            'reserved_ranges_do_not_overlap': True, 'ufs_disabled': True,
            'uboot_ignores_legacy_header_addresses': True,
            'wled_strings': [0, 1, 2], 'initial_brightness': 512}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('baseline')
    parser.add_argument('candidate')
    parser.add_argument('uboot_config')
    args = parser.parse_args()
    print(json.dumps(validate(args.baseline, args.candidate, args.uboot_config), indent=2))
