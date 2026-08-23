#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
./scripts/config --file .output/.config \
  -e OF_EMBED \
  -d OF_SEPARATE \
  --set-str USB_GADGET_MANUFACTURER "Motorola" \
  --set-val USB_GADGET_VENDOR_NUM 0x18D1 \
  --set-val USB_GADGET_PRODUCT_NUM 0x4EE0
make CROSS_COMPILE=aarch64-linux-gnu- O=.output olddefconfig 2>&1 | tail -1
grep -E 'USB_GADGET_VENDOR_NUM|USB_GADGET_PRODUCT_NUM|USB_GADGET_MANUFACTURER|OF_EMBED|OF_SEPARATE|DEFAULT_DEVICE_TREE' .output/.config
echo "=== build ==="
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j8 2>&1 | tail -3
