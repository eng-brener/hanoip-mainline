#!/usr/bin/env python3
"""Pack the 7.3 Image/ramdisk into the GOLD v4 pmOS boot image layout."""
from pathlib import Path
import importlib.util, json

here = Path(__file__).resolve().parent
repo = here.parents[2]
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'kernel-hanoip-pmos-7.3-v1.img'
m.repack(repo / 'work/GOLD-20261025-1659/kernel-hanoip-pmos-super-v1.img',
         here / 'ramdisk.cpio.gz', out,
         kernel=here / 'Image.gz', dtb=here / 'kernel.dtb')
(here / 'image.json').write_text(json.dumps(m.inspect(out), indent=2) + '\n')
print('packed', out, out.stat().st_size)
