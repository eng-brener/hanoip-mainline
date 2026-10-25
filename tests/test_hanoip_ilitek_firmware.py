import struct
import unittest

from scripts.hanoip_ilitek_firmware import BLOCK, HEADER, MAGIC, convert, crc32_mpeg, parse_hex


def record(kind, data=b'', address=0):
    value = bytes([len(data)]) + address.to_bytes(2, 'big') + bytes([kind]) + data
    return ':' + (value + bytes([-sum(value) & 0xff])).hex().upper()


class IlitekFirmwareTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.ranges = {1: (0, 0x14000), 2: (0x1d000, 0x2000),
                      3: (0x1f000, 0x200), 5: (0x14000, 0x9000)}
        memory = bytearray(b'\xff' * 0x20000)
        info = 0x13fff - 0x4f
        memory[info] = 0
        struct.pack_into('<2H', memory, info + 16, 1080, 2460)
        memory[info + 48:info + 52] = bytes.fromhex('10000a00')
        memory[info + 68:info + 72] = bytes.fromhex('01040608')
        lines = []
        for kind, (start, size) in cls.ranges.items():
            end = start + size
            memory[end - 4:end] = crc32_mpeg(memory[start:end - 4]).to_bytes(4, 'big')
            lines.append(record(0xaf, start.to_bytes(3, 'big') + (end - 1).to_bytes(3, 'big') + bytes([kind])))
        lines += [record(0xb0, bytes.fromhex('02087002')), record(0xb0, bytes.fromhex('02067003'))]
        base = -1
        for start, size in cls.ranges.values():
            for address in range(start, start + size, 32):
                if address >> 16 != base:
                    base = address >> 16
                    lines.append(record(4, base.to_bytes(2, 'big')))
                lines.append(record(0, memory[address:address + 32], address & 0xffff))
        lines.append(record(1))
        cls.text = '\n'.join(lines)

    def test_crc_matches_mpeg2_reference(self):
        self.assertEqual(crc32_mpeg(b'123456789'), 0x0376e6e7)

    def test_packages_only_runtime_blocks_in_fixed_iram_ranges(self):
        data, report = convert(self.text)
        header = HEADER.unpack_from(data)
        self.assertEqual(header[:3], (MAGIC, 0x7807, 3))
        entries = [BLOCK.unpack_from(data, HEADER.size + i * BLOCK.size) for i in range(3)]
        self.assertEqual([(e[0], e[1], e[2]) for e in entries],
                         [(1, 0, 81920), (2, 0x20870, 8192), (3, 0x20670, 512)])
        self.assertTrue(report['mp_firmware_excluded'])
        self.assertEqual(len(data), 90724)

    def test_rejects_broken_record_checksum(self):
        with self.assertRaisesRegex(ValueError, 'checksum'):
            parse_hex(self.text.replace(self.text.splitlines()[0], self.text.splitlines()[0][:-2] + '00', 1))

    def test_rejects_missing_eof(self):
        with self.assertRaisesRegex(ValueError, 'complete'):
            parse_hex(self.text.rsplit('\n', 1)[0])

    def test_rejects_address_outside_verified_iram(self):
        bad = self.text.replace(record(0xb0, bytes.fromhex('02087002')),
                                record(0xb0, bytes.fromhex('04100002')))
        with self.assertRaisesRegex(ValueError, 'IRAM layout'):
            convert(bad)

    def test_rejects_modified_firmware_even_with_valid_hex_checksum(self):
        lines = self.text.splitlines()
        i = next(i for i, line in enumerate(lines) if bytes.fromhex(line[1:])[3] == 0)
        rec = bytes.fromhex(lines[i][1:])
        payload = bytearray(rec[4:-1])
        payload[0] ^= 1
        lines[i] = record(0, payload, int.from_bytes(rec[1:3], 'big'))
        with self.assertRaisesRegex(ValueError, 'CRC mismatch'):
            convert('\n'.join(lines))


if __name__ == '__main__':
    unittest.main()
