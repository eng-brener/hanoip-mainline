#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150/.output

echo "=== gzip u-boot-nodtb.bin ==="
gzip -f -k u-boot-nodtb.bin
ls -la u-boot-nodtb.bin.gz

echo "=== append dtb ==="
cat u-boot-nodtb.bin.gz dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dtb > u-boot-nodtb.bin.gz-dtb
ls -la u-boot-nodtb.bin.gz-dtb

echo "=== mkbootimg header v3 ==="
mkbootimg \
  --kernel u-boot-nodtb.bin.gz-dtb \
  --header_version 3 \
  --os_version 14.0.0 \
  --os_patch_level 2026-07 \
  --output /home/brener/hanoip-uboot/work/u-boot-hanoip-boot.img

echo "=== resultado ==="
ls -la /home/brener/hanoip-uboot/work/u-boot-hanoip-boot.img
file /home/brener/hanoip-uboot/work/u-boot-hanoip-boot.img
