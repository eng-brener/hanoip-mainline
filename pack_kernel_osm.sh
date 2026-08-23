#!/bin/bash
set -e
cd /home/brener/hanoip-uboot
MKB=$(command -v mkbootimg || echo /usr/bin/mkbootimg)

# gzip do novo kernel
gzip -f -k kernel-mainline/arch/arm64/boot/Image
ls -la kernel-mainline/arch/arm64/boot/Image.gz

# boot.img v2 com kernel mainline + dtb (osm0sis mkbootimg - o que o CI do fork usa)
$MKB \
  --base '0x0' \
  --kernel_offset '0x00008000' \
  --ramdisk work/ramdisk-empty.cpio.gz \
  --second_offset '0x00f00000' \
  --dtb_offset '0x01f00000' \
  --header_version '2' \
  --kernel kernel-mainline/arch/arm64/boot/Image.gz \
  --dtb kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb \
  --pagesize '4096' \
  -o work/kernel-mainline-hanoip-osm.img

echo "=== OK ==="
ls -la work/kernel-mainline-hanoip-osm.img
python3 - <<'PYEOF'
import struct
d = open('work/kernel-mainline-hanoip-osm.img','rb').read()
print('magic:', d[0:8])
print('kernel_size:', struct.unpack('<I', d[8:12])[0])
print('ramdisk_size:', struct.unpack('<I', d[16:20])[0])
print('header_version:', struct.unpack('<I', d[40:44])[0])
idx = d.find(b'\xd0\x0d\xfe\xed')
print('DTB magic em:', hex(idx) if idx>=0 else 'NAO ACHOU')
PYEOF
