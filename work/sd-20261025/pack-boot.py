#!/usr/bin/env python3
"""Package the SD diagnostic kernel/DTB on top of the known-good v2 image."""
from pathlib import Path
import importlib.util, json

here = Path(__file__).resolve().parent
repo = here.parents[1]
base = repo / 'work/display-robustness-20261025/display-v2'
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'kernel-hanoip-sd-v1.img'
m.repack(base / 'kernel-hanoip-display-robust-v2.img',
         here / 'ramdisk.cpio.gz',
         out,
         kernel=here / 'Image.gz',
         dtb=here / 'kernel.dtb')
info = m.inspect(out)
(info and (here / 'image.json').write_text(json.dumps(info, indent=2) + '\n'))
print('packed', out, out.stat().st_size)
