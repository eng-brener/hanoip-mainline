#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/kernel-mainline
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export LLVM=1

# gzip do kernel (o ABL espera kernel gzip)
gzip -f -k arch/arm64/boot/Image
ls -la arch/arm64/boot/Image.gz

# ramdisk minimo
RD=/home/brener/hanoip-uboot/work/ramdisk-empty.cpio.gz

MKB=$(command -v mkbootimg || echo /usr/bin/mkbootimg)
# boot.img header v3 com kernel mainline + dtb
$MKB \
  --base '0x0' \
  --kernel_offset '0x00008000' \
  --ramdisk $RD \
  --pagesize '4096' \
  --header_version '3' \
  --os_version '14.0.0' \
  --os_patch_level '2026-07' \
  --kernel arch/arm64/boot/Image.gz \
  --dtb arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb \
  --dtb_offset '0x01f00000' \
  -o /home/brener/hanoip-uboot/work/kernel-mainline-hanoip-boot.img

echo "=== OK ==="
ls -la /home/brener/hanoip-uboot/work/kernel-mainline-hanoip-boot.img
