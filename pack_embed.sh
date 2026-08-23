#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
D=.output

# OF_EMBED: o u-boot.bin já contém o DTB embutido.
# gzip do binário inteiro (DTB vai junto).
gzip -f -k $D/u-boot.bin
cp $D/u-boot.bin.gz $D/uboot-embed.gz
ls -la $D/uboot-embed.gz

# header v3 com ramdisk
MKB=$(command -v mkbootimg || echo /usr/bin/mkbootimg)
$MKB \
  --base '0x0' \
  --kernel_offset '0x00008000' \
  --ramdisk /home/brener/hanoip-uboot/work/ramdisk-empty.cpio.gz \
  --pagesize '4096' \
  --header_version '3' \
  --os_version '14.0.0' \
  --os_patch_level '2026-07' \
  --kernel $D/uboot-embed.gz \
  -o $D/u-boot-hanoip-embed.img

cp $D/u-boot-hanoip-embed.img /home/brener/hanoip-uboot/work/
echo "=== resultado ==="
ls -la $D/u-boot-hanoip-embed.img
