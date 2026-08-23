#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
D=.output
gzip -f -k $D/u-boot-nodtb.bin
cat $D/u-boot-nodtb.bin.gz $D/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dtb > $D/uboot-dtb

# header v3 como o boot.img stock do hanoip
./mkbootimg/mkbootimg \
  --base '0x0' \
  --kernel_offset '0x00008000' \
  --pagesize '4096' \
  --header_version '3' \
  --os_version '14.0.0' \
  --os_patch_level '2026-07' \
  --kernel $D/uboot-dtb \
  -o $D/u-boot-hanoip-v3.img

echo "=== resultado ==="
ls -la $D/u-boot-hanoip-v3.img
cp $D/u-boot-hanoip-v3.img /home/brener/hanoip-uboot/work/
python3 - <<'EOF'
import struct
d = open('$D/u-boot-hanoip-v3.img','rb').read()
print('magic:', d[0:8])
print('kernel_size:', struct.unpack('<I', d[8:12])[0])
print('ramdisk_size:', struct.unpack('<I', d[12:16])[0])
print('header_size:', struct.unpack('<I', d[20:24])[0])
print('header_version:', struct.unpack('<I', d[40:44])[0])
EOF
echo DONE
