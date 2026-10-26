#!/usr/bin/env python3
"""Pack the pmOS U-Boot (touch follows panel) into the telemetry-v1 header."""
from pathlib import Path
import importlib.util

here = Path(__file__).resolve().parent
repo = here.parents[2]
base = repo / 'work/battery-20261025/telemetry-v1'
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

out = here / 'u-boot-hanoip-pmos-v1.img'
m.pack_uboot_v3(base / 'u-boot-hanoip-battery-telemetry-v1.img', here / 'u-boot.bin', out)
print('packed', out, out.stat().st_size)
