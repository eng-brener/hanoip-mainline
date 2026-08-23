#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
D=.output
gzip -f -k $D/u-boot-nodtb.bin
cat $D/u-boot-nodtb.bin.gz $D/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dtb > $D/uboot-dtb

# header v3 com ramdisk (o ABL do Moto pode exigir ramdisk_size > 0)
./mkbootimg/mkbootimg \
  --base '0x0' \
  --kernel_offset '0x00008000' \
  --ramdisk /home/brener/hanoip-uboot/work/ramdisk-empty.cpio.gz \
  --pagesize '4096' \
  --header_version '3' \
  --os_version '14.0.0' \
  --os_patch_level '2026-07' \
  --kernel $D/uboot-dtb \
  -o $D/u-boot-hanoip-v3.img

cp $D/u-boot-hanoip-v3.img /home/brener/hanoip-uboot/work/
echo "=== resultado ==="
ls -la $D/u-boot-hanoip-v3.img
