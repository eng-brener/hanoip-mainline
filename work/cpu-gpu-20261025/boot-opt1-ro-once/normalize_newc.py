#!/usr/bin/env python3
"""Set every newc initramfs entry owner to root, preserving mode and data."""
from pathlib import Path
import gzip
import sys

src, dst = map(Path, sys.argv[1:3])
data = bytearray(gzip.decompress(src.read_bytes()))
pos = 0
entries = 0
while pos + 110 <= len(data):
    hdr = data[pos:pos + 110]
    if hdr[:6] not in (b"070701", b"070702"):
        raise SystemExit(f"invalid newc header at offset {pos}")
    fields = [int(hdr[6 + i * 8:14 + i * 8], 16) for i in range(13)]
    filesize, namesize = fields[6], fields[11]
    data[pos + 22:pos + 30] = b"00000000"  # uid
    data[pos + 30:pos + 38] = b"00000000"  # gid
    name_start = pos + 110
    name_end = name_start + namesize
    name = bytes(data[name_start:name_end - 1])
    file_start = (name_end + 3) & ~3
    next_pos = (file_start + filesize + 3) & ~3
    if next_pos > len(data):
        raise SystemExit(f"truncated newc entry at offset {pos}")
    pos = next_pos
    entries += 1
    if name == b"TRAILER!!!":
        break
else:
    raise SystemExit("newc trailer missing")

dst.write_bytes(gzip.compress(bytes(data), mtime=0))
print(f"normalized {entries} newc entries to uid=0 gid=0: {dst}")
