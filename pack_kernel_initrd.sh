#!/bin/bash
set -e
cd /home/brener/hanoip-uboot
MKB=$(command -v mkbootimg || echo /usr/bin/mkbootimg)

# Always refresh the compressed kernel; reusing a stale Image.gz silently
# packages an older configuration.
gzip -f -k kernel-mainline/arch/arm64/boot/Image

# boot.img v2 com kernel mainline + initramfs busybox + dtb
$MKB \
  --base '0x0' \
  --kernel_offset '0x00008000' \
  --ramdisk /tmp/initramfs-hanoip.cpio.gz \
  --ramdisk_offset '0x04000000' \
  --second_offset '0x00f00000' \
  --dtb_offset '0x01f00000' \
  --header_version '2' \
  --kernel kernel-mainline/arch/arm64/boot/Image.gz \
  --dtb kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb \
  --pagesize '4096' \
  -o work/kernel-mainline-hanoip-initrd.img

echo "=== gerado ==="
ls -la work/kernel-mainline-hanoip-initrd.img
