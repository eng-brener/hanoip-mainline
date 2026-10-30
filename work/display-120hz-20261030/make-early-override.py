#!/usr/bin/env python3
"""Append one module override to the early cpio, before the main initramfs."""
from pathlib import Path
import stat

root = Path(__file__).resolve().parent
name = b"usr/lib/modules/7.3.0-sm7150/kernel/drivers/gpu/drm/panel/panel-ilitek-ili7807s.ko.zst\0"
payload = (root / "panel-ilitek-ili7807s-120-v2.ko.zst").read_bytes()
archive = bytearray()
for ino, path, mode, data in ((1, name, stat.S_IFREG | 0o644, payload),
                              (2, b"TRAILER!!!\0", stat.S_IFREG, b"")):
    fields = (ino, mode, 0, 0, 1, 0, len(data), 0, 0, 0, 0, len(path), 0)
    archive += b"070701" + b"".join(f"{value:08x}".encode() for value in fields)
    archive += path
    archive += b"\0" * (-len(archive) % 4)
    archive += data
    archive += b"\0" * (-len(archive) % 4)
base = (root / "baseline-ramdisk.cpio.gz").read_bytes()
if base[5338856:5338860] != bytes.fromhex("28b52ffd"):
    raise SystemExit("unexpected baseline initramfs layout")
(root / "early-override.cpio").write_bytes(archive)
(root / "early-override-ramdisk").write_bytes(base[:5338856] + archive + base[5338856:])
print(f"early override cpio: {len(archive)} bytes")
