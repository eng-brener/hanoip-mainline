#!/bin/bash
# Build do U-Boot para o Moto G60 (hanoip) - configuração completa
# Uso: bash build.sh [limpo]
set -e
cd "$(dirname "$0")"
U=uboot-sm7150
O=.output

if [ "$1" = "limpo" ] || [ ! -f $U/$O/.config ]; then
  make CROSS_COMPILE=aarch64-linux-gnu- -C $U O=$O qcom_defconfig qcom-phone.config tauchgang.config
fi

./uboot-sm7150/scripts/config --file $U/$O/.config \
  --set-str DEFAULT_DEVICE_TREE qcom/sm7150-motorola-hanoip
./uboot-sm7150/scripts/config --file $U/$O/.config \
  -e OF_EMBED -d OF_SEPARATE \
  -e BOOTMETH_ANDROID \
  -e CMD_ABOOTIMG \
  -e BLKMAP -e CMD_BLKMAP \
  -d EFI_VARIABLE_FILE_STORE -e EFI_VARIABLE_NO_STORE \
  -e CMD_PSTORE \
  --set-val CMD_PSTORE_MEM_ADDR 0x9d800000 \
  --set-val CMD_PSTORE_MEM_SIZE 0x400000 \
  --set-val CMD_PSTORE_RECORD_SIZE 0x80000 \
  --set-val CMD_PSTORE_CONSOLE_SIZE 0x100000 \
  --set-val CMD_PSTORE_FTRACE_SIZE 0x0 \
  --set-val CMD_PSTORE_PMSG_SIZE 0x200000 \
  --set-val CMD_PSTORE_ECC_SIZE 0x0 \
  --set-str USB_GADGET_MANUFACTURER "Motorola" \
  --set-val USB_GADGET_VENDOR_NUM 0x18D1 \
  --set-val USB_GADGET_PRODUCT_NUM 0x4EE0 \
  --set-val FASTBOOT_FLASH_MMC_DEV 1
make CROSS_COMPILE=aarch64-linux-gnu- -C $U O=$O olddefconfig

make CROSS_COMPILE=aarch64-linux-gnu- -C $U O=$O -j$(nproc)

RD=work/ramdisk-empty.cpio.gz
if [ ! -f $RD ]; then
  mkdir -p /tmp/rd && pushd /tmp/rd >/dev/null && mkdir -p dev proc sys
  find . | cpio -o -H newc 2>/dev/null | gzip > /home/brener/hanoip-uboot/$RD
  popd >/dev/null
fi

gzip -f -k $U/$O/u-boot.bin

MKB=$(command -v mkbootimg || echo /usr/bin/mkbootimg)
$MKB \
  --base '0x0' --kernel_offset '0x00008000' \
  --ramdisk $RD --pagesize '4096' \
  --header_version '3' \
  --os_version '14.0.0' --os_patch_level '2026-07' \
  --kernel $U/$O/u-boot.bin.gz \
  -o work/u-boot-hanoip-boot.img

echo "=== OK: work/u-boot-hanoip-boot.img ==="
ls -la work/u-boot-hanoip-boot.img
