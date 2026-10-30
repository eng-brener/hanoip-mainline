#!/usr/bin/env python3
"""Make a small newc archive for the experimental initramfs (local only)."""
import pathlib
import stat

root = pathlib.Path(__file__).resolve().parent
order = (root / "init-bottom-ORDER.original").read_bytes()
if b"hanoip-panel-120" in order or not order.endswith(b"\n"):
    raise SystemExit("unexpected original init-bottom ORDER")
entries = [
    ("hanoip-experimental", stat.S_IFDIR | 0o755, b""),
    ("hanoip-experimental/panel-ilitek-ili7807s.ko.zst", stat.S_IFREG | 0o644,
     (root / "panel-ilitek-ili7807s.ko.zst").read_bytes()),
    ("scripts/init-bottom/hanoip-panel-120", stat.S_IFREG | 0o755,
     (root / "hanoip-panel-120-init-bottom.sh").read_bytes()),
    ("scripts/init-bottom/ORDER", stat.S_IFREG | 0o644,
     order + b'/scripts/init-bottom/hanoip-panel-120 "$@"\n'),
    ("TRAILER!!!", stat.S_IFREG, b""),
]
data = bytearray()
for ino, (name, mode, content) in enumerate(entries, 1):
    encoded = name.encode() + b"\0"
    fields = (ino, mode, 0, 0, 1, 0, len(content), 0, 0, 0, 0, len(encoded), 0)
    data += b"070701" + b"".join(f"{field:08x}".encode() for field in fields)
    data += encoded
    data += b"\0" * (-len(data) % 4)
    data += content
    data += b"\0" * (-len(data) % 4)
(root / "experimental-overlay.cpio").write_bytes(data)
print(f"archive: {len(data)} bytes")
