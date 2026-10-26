#!/usr/bin/env python3
"""Replace only the ramdisk in the known GPU diagnostic Android boot image."""
from pathlib import Path
import struct

base = Path(__file__).parent
src = (base.parent / "gpu" / "kernel-hanoip-gpu.img").read_bytes()
ramdisk = (base / "ramdisk.cpio.gz").read_bytes()
page = struct.unpack_from("<I", src, 36)[0]
if src[:8] != b"ANDROID!" or struct.unpack_from("<I", src, 40)[0] != 2:
    raise SystemExit("unexpected boot image header")
ksize, rsize, ssize = (struct.unpack_from("<I", src, off)[0] for off in (8, 16, 24))

def align(n):
    return (n + page - 1) // page * page

ko = page
ro = ko + align(ksize)
so = ro + align(rsize)
recovery_size = struct.unpack_from("<I", src, 1632)[0]
recovery_offset = struct.unpack_from("<Q", src, 1636)[0]
if ssize or recovery_size or recovery_offset:
    raise SystemExit("unexpected second/recovery component; refusing lossy repack")
dtb_size = struct.unpack_from("<I", src, 1648)[0]
dtb_off = so
if src[dtb_off:dtb_off + 4] != b"\xd0\x0d\xfe\xed":
    raise SystemExit("DTB not at expected offset")
if dtb_size <= 0 or dtb_off + align(dtb_size) != len(src):
    raise SystemExit("unexpected DTB tail layout")

header = bytearray(src[:page])
struct.pack_into("<I", header, 16, len(ramdisk))
new = bytearray(header)
new.extend(src[ko:ko + ksize]); new.extend(b"\0" * (align(ksize) - ksize))
new.extend(ramdisk); new.extend(b"\0" * (align(len(ramdisk)) - len(ramdisk)))
new.extend(src[dtb_off:])
out = base / "kernel-hanoip-gpu-zap-early.img"
out.write_bytes(new)
print(f"wrote {out} ({len(new)} bytes), kernel={ksize}, ramdisk={len(ramdisk)}, dtb={dtb_size}")
