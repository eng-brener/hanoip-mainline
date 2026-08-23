#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
./scripts/config --file .output/.config -e PINCTRL -e PINCTRL_QCOM -e PINCTRL_QCOM_SM7150 -d QCOM_HYP_SMMU
make CROSS_COMPILE=aarch64-linux-gnu- O=.output olddefconfig 2>&1 | tail -1
grep -E 'QCOM_HYP_SMMU|PINCTRL_QCOM_SM7150' .output/.config
echo "=== build ==="
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j8 2>&1 | tail -3
