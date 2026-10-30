#!/usr/bin/env python3
"""Pack the volatile test boot image: listener7 kernel + DSI-fixed msm.ko.

The ramdisk is the one from the tested listener7 image; a small extra cpio is
inserted between the module cpio and the main initramfs, overriding only:
  - usr/lib/modules/7.3.0-sm7150/.../msm/msm.ko.zst      (local DSI guards)
  - usr/lib/modules/7.3.0-sm7150/.../panel/panel-ilitek-ili7807s.ko.zst (120 Hz)
Nothing else in the ramdisk, kernel or DT changes, and no partition is written.
"""
import hashlib
import importlib.util
import pathlib
import stat
import sys
import tempfile

repo = pathlib.Path(__file__).resolve().parents[2]
here = pathlib.Path(__file__).resolve().parent
pre_gold = repo / 'work/PRE-GOLD-20261030-1430'
base_img = pre_gold / 'kernel/kernel-hanoip-listener7.img'
kernel = pre_gold / 'kernel/Image.gz.listener7'
dtb = pre_gold / 'kernel/kernel.dtb'
MOD = 'usr/lib/modules/7.3.0-sm7150/kernel/drivers/gpu/drm'
small = here / 'kernel-test/msm-dsifix.ko.zst'
panel = repo / 'work/display-120hz-20261030/panel-ilitek-ili7807s-120-v2.ko.zst'
out = here / 'kernel-listener7-dsifix-120hz.img'

spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
hb = importlib.util.module_from_spec(spec)
spec.loader.exec_module(hb)


def cpio_entries(buf, start):
    """Yield (name, filesize, data_offset) for a newc archive; return end."""
    i = start
    out = []
    while buf[i:i + 6] in (b'070701', b'070702'):
        field = lambda k: int(buf[i + 6 + 8 * k:i + 6 + 8 * (k + 1)], 16)
        namesize, filesize, mode = field(11), field(6), field(1)
        name = buf[i + 110:i + 110 + namesize - 1].decode('utf-8', 'replace')
        i += 110 + namesize
        i += (-i) % 4
        if name == 'TRAILER!!!':
            return out, i
        out.append((name, filesize, i, mode))
        i += filesize
        i += (-i) % 4
    return out, i


def newc(entries):
    archive = bytearray()
    for ino, (path, payload) in enumerate(entries, 1):
        name = path.encode() + b'\0'
        mode = stat.S_IFDIR | 0o755 if path.endswith('/') else stat.S_IFREG | 0o644
        fields = (ino, mode, 0, 0, 1, 0, len(payload), 0, 0, 0, 0, len(name), 0)
        archive += b'070701' + b''.join(f'{v:08x}'.encode() for v in fields)
        archive += name
        archive += b'\0' * (-len(archive) % 4)
        archive += payload
        archive += b'\0' * (-len(archive) % 4)
    name = b'TRAILER!!!\0'
    fields = (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, len(name), 0)
    archive += b'070701' + b''.join(f'{v:08x}'.encode() for v in fields) + name
    archive += b'\0' * (-len(archive) % 4)
    return bytes(archive)


for path in (base_img, kernel, dtb, small, panel):
    if not path.is_file():
        sys.exit(f'missing {path}')

data = base_img.read_bytes()
_page, sec = hb.read_v2(data)
off, size = sec['ramdisk']
ramdisk = data[off:off + size]
print('listener7 ramdisk bytes', size)

# Walk the leading cpio archives to find where the main (zstd) initramfs starts.
pos = 0
while True:
    if ramdisk[pos:pos + 4] == bytes.fromhex('28b52ffd'):
        break
    entries, end = cpio_entries(ramdisk, pos)
    print(f'cpio at {pos}: {len(entries)} entries, ends {end}, trailing '
          f'{ramdisk[end:end + 4].hex()}')
    if end <= pos:
        sys.exit('cannot walk ramdisk')
    pos = end
    if pos >= len(ramdisk):
        sys.exit('no zstd initramfs found')
print('main initramfs (zstd) at', pos)

# Confirm the modules we override really exist in the early archives.
early = []
start = 0
while start < pos:
    got, end = cpio_entries(ramdisk, start)
    early += [n for n, _s, _o, _m in got]
    start = end
for target in (f'{MOD}/msm/msm.ko.zst', f'{MOD}/panel/panel-ilitek-ili7807s.ko.zst'):
    if target not in early:
        sys.exit(f'{target} not present in early cpio')
    print('override target found:', target)

override = newc([(f'{MOD}/msm/msm.ko.zst', small.read_bytes()),
                 (f'{MOD}/panel/panel-ilitek-ili7807s.ko.zst', panel.read_bytes())])
new_ramdisk = ramdisk[:pos] + override + ramdisk[pos:]

with tempfile.TemporaryDirectory() as temp:
    rd = pathlib.Path(temp) / 'ramdisk'
    rd.write_bytes(new_ramdisk)
    out.unlink(missing_ok=True)
    # Keep the kernel and DT exactly as in the validated listener7 image.
    hb.repack(base_img, rd, out)

info = hb.inspect(out)
print(out.name, info['bytes'], {k: v['size'] for k, v in info['sections'].items()})
for path in (out, small, panel, kernel, dtb):
    print(hashlib.sha256(path.read_bytes()).hexdigest(), path.name)
