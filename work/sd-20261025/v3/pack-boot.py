#!/usr/bin/env python3
"""Pack the v3 kernel/DTB with the SD-safe voltage patches and active-low CD."""
from pathlib import Path
import importlib.util, json

here = Path(__file__).resolve().parent
repo = here.parents[2]
base = repo / 'work/display-robustness-20261025/display-v2'
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'kernel-hanoip-sd-v3.img'
m.repack(base / 'kernel-hanoip-display-robust-v2.img',
         repo / 'work/sd-20261025/ramdisk.cpio.gz',
         out,
         kernel=here / 'Image.gz',
         dtb=here / 'kernel.dtb')
info = m.inspect(out)
(here / 'image.json').write_text(json.dumps(info, indent=2) + '\n')
print('packed', out, out.stat().st_size)
