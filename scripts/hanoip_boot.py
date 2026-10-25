#!/usr/bin/env python3
"""Inspect/repack local Android v2 images and replace a newc /init.

No ADB, fastboot or block-device operations are provided.
"""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import stat
import struct


def align(value, size):
    return (value + size - 1) // size * size


def write_new(path, data):
    path = Path(path)
    if path.exists():
        if path.read_bytes() != data:
            raise ValueError(f"Refusing to overwrite existing output: {path}")
        return
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("xb") as stream:
        stream.write(data)


def read_v2(data, page_override=None, validate_dtb=True):
    if len(data) < 1660 or data[:8] != b"ANDROID!":
        raise ValueError("Not an Android boot image")
    version = struct.unpack_from("<I", data, 40)[0]
    if version != 2:
        raise ValueError(f"Expected header v2, got v{version}")
    page = page_override or struct.unpack_from("<I", data, 36)[0]
    if page < 2048 or page > 65536 or page & (page - 1):
        raise ValueError(f"Invalid page size: {page}")
    sizes = {
        "kernel": struct.unpack_from("<I", data, 8)[0],
        "ramdisk": struct.unpack_from("<I", data, 16)[0],
        "second": struct.unpack_from("<I", data, 24)[0],
        "recovery_dtbo": struct.unpack_from("<I", data, 1632)[0],
        "dtb": struct.unpack_from("<I", data, 1648)[0],
    }
    if sizes["recovery_dtbo"]:
        raise ValueError("Recovery DTBO images require a separate packing workflow")
    sections = {}
    offset = page
    for name, size in sizes.items():
        if offset + size > len(data):
            raise ValueError(f"{name} extends beyond the image")
        sections[name] = (offset, size)
        offset = align(offset + size, page)
    start, size = sections["dtb"]
    if validate_dtb:
        if size < 40 or data[start:start + 4] != b"\xd0\x0d\xfe\xed":
            raise ValueError("Missing FDT at the calculated DTB offset")
        if struct.unpack_from(">I", data, start + 4)[0] != size:
            raise ValueError("DTB totalsize disagrees with boot header")
    return page, sections


def inspect(path):
    data = Path(path).read_bytes()
    page, sections = read_v2(data)
    return {
        "file": str(path), "bytes": len(data), "header_version": 2,
        "page_size": page,
        "dtb_addr": hex(struct.unpack_from("<Q", data, 1652)[0]),
        "sha256": hashlib.sha256(data).hexdigest(),
        "sections": {
            name: {"offset": offset, "size": size,
                   "sha256": hashlib.sha256(data[offset:offset + size]).hexdigest()}
            for name, (offset, size) in sections.items()
        },
    }


def image_id(parts):
    digest = hashlib.sha1()
    for part in parts.values():
        digest.update(part)
        digest.update(struct.pack("<I", len(part)))
    return digest.digest() + bytes(12)


def repack(template, ramdisk, output, kernel=None, dtb=None):
    data = Path(template).read_bytes()
    if data[-64:-60] == b"AVBf":
        raise ValueError("Repacking an AVB-footer image is not supported")
    page, sections = read_v2(data)
    parts = {name: data[offset:offset + size]
             for name, (offset, size) in sections.items()}
    parts["ramdisk"] = Path(ramdisk).read_bytes()
    if kernel:
        parts["kernel"] = Path(kernel).read_bytes()
    if dtb:
        parts["dtb"] = Path(dtb).read_bytes()
    header = bytearray(data[:page])
    for name, offset in [("kernel", 8), ("ramdisk", 16), ("second", 24),
                         ("recovery_dtbo", 1632), ("dtb", 1648)]:
        struct.pack_into("<I", header, offset, len(parts[name]))
    header[576:608] = image_id(parts)
    result = bytes(header)
    for part in parts.values():
        result += part
        result += bytes(align(len(result), page) - len(result))
    read_v2(result)
    write_new(output, result)


def append_cpio_member(result, magic, fields, name_bytes, payload):
    result.extend(magic + b"".join(f"{value:08x}".encode() for value in fields))
    result.extend(name_bytes)
    result.extend(bytes(align(len(result), 4) - len(result)))
    result.extend(payload)
    result.extend(bytes(align(len(result), 4) - len(result)))


def replace_init(source, init, output, additions=None):
    archive = gzip.decompress(Path(source).read_bytes())
    result = bytearray()
    offset, replaced = 0, 0
    remaining = {}
    seen = set()
    for name, value in (additions or {}).items():
        name = name.lstrip("/")
        if not name or ".." in name.split("/") or "." in name.split("/"):
            raise ValueError(f"Invalid archive destination: {name}")
        if name in ("init", "TRAILER!!!"):
            raise ValueError(f"Reserved archive destination: {name}")
        remaining[name] = value
    while True:
        if offset + 110 > len(archive):
            raise ValueError("Truncated newc header")
        magic = archive[offset:offset + 6]
        if magic not in (b"070701", b"070702"):
            raise ValueError("Unsupported CPIO format")
        fields = [int(archive[offset + 6 + i * 8:offset + 14 + i * 8], 16)
                  for i in range(13)]
        size, namesize = fields[6], fields[11]
        name_start = offset + 110
        name_end = name_start + namesize
        if namesize < 1 or name_end > len(archive) or archive[name_end - 1] != 0:
            raise ValueError("Invalid CPIO filename")
        name_bytes = archive[name_start:name_end]
        name = name_bytes[:-1].decode()
        normalized = name[2:] if name.startswith("./") else name
        start = align(name_end, 4)
        if start + size > len(archive):
            raise ValueError("Truncated CPIO member")
        payload = archive[start:start + size]
        offset = align(start + size, 4)
        if name in ("init", "./init"):
            if not stat.S_ISREG(fields[1]):
                raise ValueError("/init must be a regular file")
            payload = Path(init).read_bytes()
            fields[1] = stat.S_IFREG | 0o755
            fields[6] = len(payload)
            fields[12] = sum(payload) & 0xffffffff if magic == b"070702" else 0
            replaced += 1
        if normalized in remaining:
            payload, mode = remaining.pop(normalized)
            fields[1] = stat.S_IFREG | mode
            fields[4] = 1
            fields[6] = len(payload)
            fields[12] = sum(payload) & 0xffffffff if magic == b"070702" else 0
        if name == "TRAILER!!!":
            directories = set()
            for destination in remaining:
                directories.update(str(parent) for parent in Path(destination).parents
                                   if str(parent) != ".")
            for directory in sorted(directories - seen, key=lambda p: (len(p.split("/")), p)):
                encoded = directory.encode() + b"\0"
                entry = [0] * 13
                entry[1], entry[4], entry[11] = stat.S_IFDIR | 0o755, 2, len(encoded)
                append_cpio_member(result, b"070701", entry, encoded, b"")
            for destination, (content, mode) in sorted(remaining.items()):
                encoded = destination.encode() + b"\0"
                entry = [0] * 13
                entry[1], entry[4] = stat.S_IFREG | mode, 1
                entry[6], entry[11] = len(content), len(encoded)
                append_cpio_member(result, b"070701", entry, encoded, content)
        append_cpio_member(result, magic, fields, name_bytes, payload)
        seen.add(normalized)
        if name == "TRAILER!!!":
            break
    if replaced != 1:
        raise ValueError(f"Expected exactly one /init, found {replaced}")
    result.extend(bytes(align(len(result), 512) - len(result)))
    write_new(output, gzip.compress(bytes(result), mtime=0))


def pack_uboot_v3(template, binary, output):
    """Replace the gzip U-Boot payload; preserve the original empty ramdisk."""
    data = Path(template).read_bytes()
    if len(data) < 4096 or data[:8] != b"ANDROID!":
        raise ValueError("Not an Android boot image")
    if struct.unpack_from("<I", data, 40)[0] != 3:
        raise ValueError("Expected the U-Boot Android header v3 template")
    kernel_size, ramdisk_size = struct.unpack_from("<II", data, 8)
    ramdisk_start = 4096 + align(kernel_size, 4096)
    if ramdisk_start + ramdisk_size > len(data):
        raise ValueError("Truncated U-Boot template")
    payload = gzip.compress(Path(binary).read_bytes(), mtime=0)
    header = bytearray(data[:4096])
    struct.pack_into("<I", header, 8, len(payload))
    result = bytes(header) + payload
    result += bytes(align(len(result), 4096) - len(result))
    result += data[ramdisk_start:ramdisk_start + ramdisk_size]
    result += bytes(align(len(result), 4096) - len(result))
    write_new(output, result)


def repair_v2(source, output):
    data = bytearray(Path(source).read_bytes())
    page, sections = read_v2(data, page_override=4096, validate_dtb=False)
    start, _ = sections["dtb"]
    if data[start:start + 4] != b"\xd0\x0d\xfe\xed":
        raise ValueError("No FDT at the expected 4096-byte-aligned position")
    size = struct.unpack_from(">I", data, start + 4)[0]
    struct.pack_into("<I", data, 36, page)
    struct.pack_into("<I", data, 1648, size)
    struct.pack_into("<Q", data, 1652, 0x01f00000)
    parts = {name: bytes(data[offset:offset + length])
             for name, (offset, length) in read_v2(data)[1].items()}
    data[576:608] = image_id(parts)
    write_new(output, bytes(data))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    subs = parser.add_subparsers(dest="command", required=True)
    check = subs.add_parser("inspect")
    check.add_argument("image")
    ramdisk = subs.add_parser("ramdisk")
    ramdisk.add_argument("source")
    ramdisk.add_argument("init")
    ramdisk.add_argument("output")
    ramdisk.add_argument("--add", action="append", default=[], metavar="DEST=SOURCE")
    ramdisk.add_argument("--add-executable", action="append", default=[], metavar="DEST=SOURCE")
    pack = subs.add_parser("repack")
    pack.add_argument("template")
    pack.add_argument("ramdisk")
    pack.add_argument("output")
    pack.add_argument("--kernel")
    pack.add_argument("--dtb")
    uboot = subs.add_parser("uboot")
    uboot.add_argument("template")
    uboot.add_argument("binary")
    uboot.add_argument("output")
    args = parser.parse_args()
    if args.command == "inspect":
        print(json.dumps(inspect(args.image), indent=2))
    elif args.command == "ramdisk":
        additions = {}
        for specs, mode in [(args.add, 0o644), (args.add_executable, 0o755)]:
            for spec in specs:
                destination, source = spec.split("=", 1)
                if destination in additions:
                    raise ValueError(f"Repeated archive destination: {destination}")
                additions[destination] = (Path(source).read_bytes(), mode)
        replace_init(args.source, args.init, args.output, additions)
    elif args.command == "uboot":
        pack_uboot_v3(args.template, args.binary, args.output)
    else:
        repack(args.template, args.ramdisk, args.output, args.kernel, args.dtb)
        print(json.dumps(inspect(args.output), indent=2))


if __name__ == "__main__":
    main()
