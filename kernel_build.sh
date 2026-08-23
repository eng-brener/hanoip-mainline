#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/kernel-mainline
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export LLVM=1

echo "=== compilando kernel (pode demorar) ==="
make -j$(nproc) 2>&1 | tail -5
echo "=== Image ==="
ls -la arch/arm64/boot/Image 2>&1
echo "=== dtb ==="
ls -la arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb 2>&1
