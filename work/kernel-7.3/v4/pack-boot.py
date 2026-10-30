#!/usr/bin/env python3
"""Pack out/Image.gz + a ramdisk into the pmOS boot image layout (GOLD v4 header).
    pack-boot.py RAMDISK.cpio.gz
"""
from pathlib import Path
import importlib.util
import json
import sys

here = Path(__file__).resolve().parent
repo = here.parents[2]
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'out' / 'kernel-hanoip-pmos-7.3-v3.img'
out.unlink(missing_ok=True)
m.repack(repo / 'work/GOLD-20261025-1659/kernel-hanoip-pmos-super-v1.img',
         Path(sys.argv[1]), out,
         kernel=here / 'out' / 'Image.gz', dtb=here / 'out' / 'kernel.dtb')
(here / 'out' / 'image.json').write_text(json.dumps(m.inspect(out), indent=2) + '\n')
print('packed', out, out.stat().st_size)
