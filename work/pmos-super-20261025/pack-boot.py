#!/usr/bin/env python3
"""Pack telemetry-v1 kernel/DTB with the pmOS super-tail ramdisk."""
from pathlib import Path
import importlib.util, json

here = Path(__file__).resolve().parent
repo = here.parents[1]
base = repo / 'work/battery-20261025/telemetry-v1'
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'kernel-hanoip-pmos-super-v1.img'
m.repack(base / 'kernel-hanoip-battery-telemetry-v1.img', here / 'ramdisk.cpio.gz', out)
info = m.inspect(out)
(here / 'image.json').write_text(json.dumps(info, indent=2) + '\n')
print('packed', out, out.stat().st_size)
