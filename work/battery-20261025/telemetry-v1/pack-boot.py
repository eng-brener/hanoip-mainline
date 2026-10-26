#!/usr/bin/env python3
"""Package the prepared telemetry ramdisk/DTs using the preserved v2 headers."""
from pathlib import Path
import importlib.util,json,re
here=Path(__file__).resolve().parent
repo=here.parents[2]
base=repo/'work/display-robustness-20261025/display-v2'
spec=importlib.util.spec_from_file_location('hboot',repo/'scripts/hanoip_boot.py')
m=importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
dtb=(here/'uboot.dtb').read_bytes()
assert (here/'u-boot.bin').read_bytes().count(dtb)==1
for n in ('uboot.dtb','kernel.dtb'):
 assert b'console=tty1' not in (here/n).read_bytes()
cfg=(here/'uboot.config').read_text()
for symbol in ('FASTBOOT_FLASH','UFS','SCSI','CMD_SCSI'):
 assert not re.search(r'^CONFIG_'+symbol+r'=[ym]$',cfg,re.M),symbol
m.pack_uboot_v3(base/'u-boot-hanoip-display-robust-v2.img',here/'u-boot.bin',here/'u-boot-hanoip-battery-telemetry-v1.img')
m.repack(base/'kernel-hanoip-display-robust-v2.img',here/'ramdisk.cpio.gz',here/'kernel-hanoip-battery-telemetry-v1.img',dtb=here/'kernel.dtb')
info=m.inspect(here/'kernel-hanoip-battery-telemetry-v1.img')
orig=m.inspect(base/'kernel-hanoip-display-robust-v2.img')
assert info['sections']['kernel']==orig['sections']['kernel']
(here/'image.json').write_text(json.dumps(info,indent=2)+'\n')
print('Packaged unchanged kernel #10 with battery DT/modules; U-Boot flash/UFS/SCSI disabled.')
