#!/usr/bin/env python3
"""Validate the stock Ilitek HEX and package only the hanoip IRAM blocks.

Local files only. No device, partition or controller flash operations.
"""
import argparse
import hashlib
import json
from pathlib import Path
import struct

MAGIC = b'HNOIRAM1'
HEADER = struct.Struct('<8s8I')
BLOCK = struct.Struct('<5I')
LAYOUT = {1: (0x00000, 0x14000), 2: (0x20870, 0x2000), 3: (0x20670, 0x200)}


def crc32_mpeg(data):
    crc = 0xffffffff
    for byte in data:
        crc ^= byte << 24
        for _ in range(8):
            crc = ((crc << 1) ^ (0x04c11db7 if crc & 0x80000000 else 0)) & 0xffffffff
    return crc


def parse_hex(text):
    memory = bytearray(b'\xff' * 0x40000)
    written = bytearray(len(memory))
    blocks, base, ended = {}, 0, False
    for number, line in enumerate(text.splitlines(), 1):
        if not line or not line.startswith(':') or ended:
            raise ValueError(f'Invalid HEX line {number}')
        rec = bytes.fromhex(line[1:])
        if len(rec) < 5 or len(rec) != rec[0] + 5 or sum(rec) & 0xff:
            raise ValueError(f'HEX length/checksum error on line {number}')
        address, kind, data = int.from_bytes(rec[1:3], 'big'), rec[3], rec[4:-1]
        if kind == 0:
            start, end = base + address, base + address + len(data)
            if end > len(memory) or any(written[start:end]):
                raise ValueError('HEX data outside buffer or overlapping')
            memory[start:end] = data
            written[start:end] = b'\x01' * len(data)
        elif kind in (2, 4):
            if len(data) != 2 or address:
                raise ValueError('Invalid extended address')
            base = int.from_bytes(data, 'big') << (4 if kind == 2 else 16)
        elif kind == 0xaf:
            if len(data) != 7 or data[6] in blocks:
                raise ValueError('Invalid or duplicate block descriptor')
            start, end = int.from_bytes(data[:3], 'big'), int.from_bytes(data[3:6], 'big') + 1
            if not 0 <= start < end <= len(memory) or end - start < 4:
                raise ValueError('Invalid block extent')
            blocks[data[6]] = {'start': start, 'end': end}
        elif kind == 0xb0:
            if len(data) != 4 or data[3] not in blocks or 'dest' in blocks[data[3]]:
                raise ValueError('Invalid IRAM address override')
            blocks[data[3]]['dest'] = int.from_bytes(data[:3], 'big')
        elif kind == 1:
            if data or address:
                raise ValueError('Invalid EOF')
            ended = True
        elif kind == 3:
            if len(data) != 4:
                raise ValueError('Invalid start address record')
        else:
            raise ValueError(f'Unsupported HEX record {kind:#x}')
    if not ended or set(blocks) != {1, 2, 3, 5}:
        raise ValueError('Expected complete hanoip AP/DATA/TUNING/MP firmware')
    for entry in blocks.values():
        payload = memory[entry['start']:entry['end']]
        if not all(written[entry['start']:entry['end']]):
            raise ValueError('Firmware block contains missing HEX bytes')
        if crc32_mpeg(payload[:-4]) != int.from_bytes(payload[-4:], 'big'):
            raise ValueError('Firmware block CRC mismatch')
    return memory, blocks


def convert(text):
    memory, blocks = parse_hex(text)
    info = memory[blocks[1]['end'] - 1 - 0x4f:blocks[1]['end']]
    width, height = struct.unpack_from('<2H', info, 16)
    version, core = int.from_bytes(info[48:52], 'big'), int.from_bytes(info[68:72], 'big')
    if (width, height, version, core, info[0] & 1) != (1080, 2460, 0x10000a00, 0x01040608, 0):
        raise ValueError('Firmware identity differs from the collected hanoip firmware')
    result = bytearray(HEADER.pack(MAGIC, 0x7807, 3, width, height, 2048, version, core, 0))
    payloads, entries = [], []
    offset = HEADER.size + 3 * BLOCK.size
    for kind, (destination, size) in LAYOUT.items():
        entry = blocks[kind]
        if entry.get('dest', 0 if kind == 1 else -1) != destination or entry['end'] - entry['start'] != size:
            raise ValueError('IRAM layout differs from the collected hanoip firmware')
        data = bytes(memory[entry['start']:entry['end']])
        crc = crc32_mpeg(data[:-4])
        result.extend(BLOCK.pack(kind, destination, size, crc, offset))
        entries.append({'kind': kind, 'destination': hex(destination), 'bytes': size, 'crc32': hex(crc)})
        payloads.append(data)
        offset += size
    for data in payloads:
        result.extend(data)
    return bytes(result), {'chip': 'ILI7807', 'firmware_version': '16.0.10.0',
                           'core_version': '1.4.6.8', 'blocks': entries,
                           'mp_firmware_excluded': True, 'bytes': len(result),
                           'sha256': hashlib.sha256(result).hexdigest()}


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('source')
    parser.add_argument('output')
    args = parser.parse_args()
    data, report = convert(Path(args.source).read_text())
    target = Path(args.output)
    if target.exists() and target.read_bytes() != data:
        raise ValueError('Refusing to replace a different firmware artifact')
    if not target.exists():
        target.write_bytes(data)
    print(json.dumps(report, indent=2))
