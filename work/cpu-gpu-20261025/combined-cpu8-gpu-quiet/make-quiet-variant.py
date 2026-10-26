#!/usr/bin/env python3
"""Build combined CPU8/GPU-Zap images without kernel printk on tty1.

Only the console=tty1 token is blanked, preserving FDT size and layout.
Serial, USB gadget, and ramoops kernel consoles remain enabled.
"""
from pathlib import Path
import struct
import subprocess
import sys

HERE = Path(__file__).resolve().parent
REPO = HERE.parents[2]
SRC = REPO / "work/cpu-gpu-20261025/gpu-zap-early"
TOKEN = b"console=tty1"
BLANK = b" " * len(TOKEN)


def patch_dtb(data: bytes, label: str) -> bytes:
    count = data.count(TOKEN)
    if count != 1:
        raise SystemExit(f"{label}: expected one {TOKEN!r}, found {count}")
    out = data.replace(TOKEN, BLANK, 1)
    if len(out) != len(data) or out.count(TOKEN):
        raise SystemExit(f"{label}: patch validation failed")
    return out


# The bootloader DT and the kernel boot-image DT both carry bootargs.
uboot_dtb = patch_dtb((SRC / "uboot.dtb").read_bytes(), "U-Boot DTB")
kernel_dtb = patch_dtb((SRC / "kernel.dtb").read_bytes(), "kernel DTB")
(HERE / "uboot.dtb").write_bytes(uboot_dtb)
(HERE / "kernel.dtb").write_bytes(kernel_dtb)

# Keep the embedded U-Boot FDT byte-for-byte synchronized with uboot.dtb.
u_boot = bytearray((SRC / "u-boot.bin").read_bytes())
off = 1016176
if u_boot[off:off + 4] != b"\xd0\x0d\xfe\xed":
    raise SystemExit("U-Boot embedded FDT magic mismatch")
size = struct.unpack_from(">I", u_boot, off + 4)[0]
if bytes(u_boot[off:off + size]) != (SRC / "uboot.dtb").read_bytes():
    raise SystemExit("U-Boot embedded FDT differs from source uboot.dtb")
u_boot[off:off + size] = uboot_dtb
(HERE / "u-boot.bin").write_bytes(u_boot)
if bytes(u_boot[off:off + size]) != uboot_dtb:
    raise SystemExit("U-Boot embedded FDT synchronization failed")

subprocess.run([
    sys.executable, str(REPO / "scripts/hanoip_boot.py"), "uboot",
    str(SRC / "u-boot-hanoip-gpu-zap-early.img"),
    str(HERE / "u-boot.bin"), str(HERE / "u-boot-hanoip-combined-cpu8-gpu-quiet.img"),
], check=True)
subprocess.run([
    sys.executable, str(REPO / "scripts/hanoip_boot.py"), "repack",
    str(SRC / "kernel-hanoip-gpu-zap-early.img"),
    str(SRC / "ramdisk.cpio.gz"),
    str(HERE / "kernel-hanoip-combined-cpu8-gpu-quiet.img"),
    "--dtb", str(HERE / "kernel.dtb"),
], check=True)

print("Quiet variant built: kernel console remains on serial/USB/ramoops; tty1 removed.")
