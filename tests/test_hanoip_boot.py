import gzip
from pathlib import Path
import struct
import tempfile
import unittest

from scripts.hanoip_boot import (
    inspect, pack_uboot_v3, read_v2, repair_v2, repack, replace_init, write_new,
)


class BootImageTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        # Independent fixture: distinct contents, two pages of kernel and
        # a 64-bit DTB load address to catch cross-field/width mistakes.
        self.kernel = b'K' * 5000
        self.ramdisk = b'original ramdisk'
        self.dtb = struct.pack('>II', 0xd00dfeed, 40) + bytes(32)
        header = bytearray(4096)
        header[:8] = b'ANDROID!'
        struct.pack_into('<I', header, 8, len(self.kernel))
        struct.pack_into('<I', header, 16, len(self.ramdisk))
        struct.pack_into('<III', header, 32, 0x12345678, 4096, 2)
        struct.pack_into('<I', header, 1644, 1660)
        struct.pack_into('<I', header, 1648, len(self.dtb))
        struct.pack_into('<Q', header, 1652, 0x101f00000)
        self.image = bytes(header) + self.kernel + bytes(3192)
        self.image += self.ramdisk + bytes(4096 - len(self.ramdisk))
        self.image += self.dtb + bytes(4096 - len(self.dtb))
        self.source = self.root / 'source.img'
        self.source.write_bytes(self.image)

    def test_reads_real_offsets_and_full_address(self):
        info = inspect(self.source)
        self.assertEqual(info['page_size'], 4096)
        self.assertEqual(info['dtb_addr'], '0x101f00000')
        self.assertEqual(info['sections']['dtb']['offset'], 16384)

    def test_repack_preserves_kernel_dtb_and_addresses(self):
        replacement = self.root / 'ramdisk.gz'
        replacement.write_bytes(gzip.compress(b'replacement' * 1000))
        output = self.root / 'new.img'
        repack(self.source, replacement, output)
        data = output.read_bytes()
        _, sections = read_v2(data)
        for name, expected in [('kernel', self.kernel), ('dtb', self.dtb),
                               ('ramdisk', replacement.read_bytes())]:
            offset, size = sections[name]
            self.assertEqual(data[offset:offset + size], expected)
        self.assertEqual(struct.unpack_from('<I', data, 32)[0], 0x12345678)
        self.assertEqual(struct.unpack_from('<Q', data, 1652)[0], 0x101f00000)

    def test_repair_does_not_overwrite_tags_or_recovery_fields(self):
        broken = bytearray(self.image)
        struct.pack_into('<I', broken, 36, 256)
        struct.pack_into('<I', broken, 1648, 0)
        self.source.write_bytes(broken)
        output = self.root / 'fixed.img'
        repair_v2(self.source, output)
        fixed = output.read_bytes()
        self.assertEqual(fixed[32:36], self.image[32:36])
        self.assertEqual(fixed[1632:1648], self.image[1632:1648])
        self.assertEqual(inspect(output)['sections']['dtb']['size'], 40)

    def test_rejects_truncated_payload(self):
        with self.assertRaises(ValueError):
            read_v2(self.image[:16390])

    def test_rejects_corrupt_dtb_size(self):
        broken = bytearray(self.image)
        struct.pack_into('<I', broken, 1648, 41)
        with self.assertRaises(ValueError):
            read_v2(broken)

    def test_refuses_to_overwrite_a_different_output(self):
        with self.assertRaises(ValueError):
            write_new(self.source, b'different')
        self.assertEqual(self.source.read_bytes(), self.image)

    def test_uboot_v3_pack_preserves_ramdisk(self):
        header = bytearray(4096)
        header[:8] = b'ANDROID!'
        struct.pack_into('<II', header, 8, 5000, 3)
        struct.pack_into('<I', header, 40, 3)
        source = bytes(header) + b'K' * 5000 + bytes(3192) + b'RAM'
        self.source.write_bytes(source)
        binary = self.root / 'u-boot.bin'
        binary.write_bytes(b'new U-Boot' * 1000)
        output = self.root / 'uboot.img'
        pack_uboot_v3(self.source, binary, output)
        data = output.read_bytes()
        size = struct.unpack_from('<I', data, 8)[0]
        self.assertEqual(gzip.decompress(data[4096:4096 + size]), binary.read_bytes())
        start = 4096 + ((size + 4095) // 4096) * 4096
        self.assertEqual(data[start:start + 3], b'RAM')
        self.assertEqual(self.source.read_bytes(), source)

    def test_uboot_pack_rejects_v2_template(self):
        with self.assertRaises(ValueError):
            pack_uboot_v3(self.source, self.source, self.root / 'wrong.img')


class RamdiskTests(unittest.TestCase):
    @staticmethod
    def members(path):
        data = gzip.decompress(Path(path).read_bytes())
        result, offset = {}, 0
        while True:
            fields = [int(data[offset + 6 + i * 8:offset + 14 + i * 8], 16)
                      for i in range(13)]
            start = offset + 110
            end = start + fields[11]
            name = data[start:end - 1].decode().removeprefix('./')
            start = ((end + 3) // 4) * 4
            end = start + fields[6]
            offset = ((end + 3) // 4) * 4
            if name == 'TRAILER!!!':
                return result
            result[name] = (fields[1], data[start:end])

    def test_adds_modules_with_parents_and_replaces_reboot_symlink(self):
        root = Path(__file__).resolve().parents[1]
        source = root / 'work/ramdisk-hanoip-usbserial.cpio.gz'
        with tempfile.TemporaryDirectory() as directory:
            init = Path(directory) / 'init'
            init.write_bytes(b'#!/bin/sh\necho ready\n')
            output = Path(directory) / 'new.cpio.gz'
            additions = {'lib/hanoip-ufs/test.ko': (b'ELF fixture', 0o644),
                         'sbin/reboot': (b'#!/bin/sh\necho reboot\n', 0o755)}
            replace_init(source, init, output, additions)
            old, new = self.members(source), self.members(output)
            self.assertEqual(new['bin/busybox'], old['bin/busybox'])
            self.assertEqual(new['init'][1], init.read_bytes())
            self.assertEqual(new['lib/hanoip-ufs'][0] & 0o170000, 0o040000)
            self.assertEqual(new['lib/hanoip-ufs/test.ko'], (0o100644, b'ELF fixture'))
            self.assertEqual(new['sbin/reboot'][0], 0o100755)

    def test_rejects_parent_traversal_in_added_paths(self):
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as directory:
            with self.assertRaises(ValueError):
                replace_init(root / 'work/ramdisk-hanoip-usbserial.cpio.gz',
                             root / 'scripts/hanoip-usb-shell.init',
                             Path(directory) / 'new.gz', {'../escape': (b'x', 0o644)})


if __name__ == '__main__':
    unittest.main()
