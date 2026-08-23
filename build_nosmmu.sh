#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
cp /mnt/c/Users/admin/AppData/Local/Temp/opencode/debug-nosmmu.config /home/brener/hanoip-uboot/debug-nosmmu.config
make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig qcom-phone.config 2>&1 | tail -2
# aplica fragment de debug
./scripts/config --file .output/.config -d QCOM_HYP_SMMU -d PINCTRL -d PINCTRL_QCOM_SM7150 -d PINCTRL_QCOM
make CROSS_COMPILE=aarch64-linux-gnu- O=.output olddefconfig 2>&1 | tail -1
grep -E 'QCOM_HYP_SMMU|PINCTRL' .output/.config | head
echo "=== build ==="
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j8 2>&1 | tail -3
