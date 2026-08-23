#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/kernel-mainline
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

# tenta compilar só o DTB com um defconfig minimo
if [ ! -f .config ]; then
  make LLVM=1 defconfig 2>&1 | tail -3
fi
# habilita ARCH_QCOM
./scripts/config -e ARCH_QCOM
make LLVM=1 olddefconfig 2>&1 | tail -2
# compila o DTB alvo
make LLVM=1 arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb 2>&1 | tail -20
