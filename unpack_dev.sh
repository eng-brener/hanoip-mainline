#!/bin/bash
set -e
cd /home/brener/hanoip-uboot
mkdir -p extracted
cd extracted

for f in boot_a boot_b vendor_boot_a vendor_boot_b; do
  mkdir -p "$f"
  unpack_bootimg --boot_img ../dump/${f}.img --out "$f" 2>&1 | tail -3
  echo "=== $f ==="
done
