#!/usr/bin/env python3
"""Pack the v2 U-Boot binary (SD-safe DT) into the known-good v2 header."""
from pathlib import Path
import importlib.util

here = Path(__file__).resolve().parent
repo = here.parents[2]
base = repo / 'work/display-robustness-20261025/display-v2'
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'u-boot-hanoip-sd-v2.img'
m.pack_uboot_v3(base / 'u-boot-hanoip-display-robust-v2.img',
                here / 'u-boot.bin', out)
print('packed', out, out.stat().st_size)
