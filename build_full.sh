#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
# aplica os tres configs do fork
make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig qcom-phone.config tauchgang.config 2>&1 | tail -2
# nossos ajustes hanoip
./scripts/config --file .output/.config \
  --set-str DEFAULT_DEVICE_TREE qcom/sm7150-motorola-hanoip
./scripts/config --file .output/.config \
  -e OF_EMBED -d OF_SEPARATE \
  --set-str USB_GADGET_MANUFACTURER "Motorola" \
  --set-val USB_GADGET_VENDOR_NUM 0x18D1 \
  --set-val USB_GADGET_PRODUCT_NUM 0x4EE0 \
  --set-val FASTBOOT_FLASH_MMC_DEV 1
make CROSS_COMPILE=aarch64-linux-gnu- O=.output olddefconfig 2>&1 | tail -1
grep -E 'BLKMAP|EFI_CAPSULE|DEFAULT_DEVICE_TREE|OF_EMBED|FASTBOOT_FLASH_MMC_DEV' .output/.config
echo "=== build ==="
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j8 2>&1 | tail -3
