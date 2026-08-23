#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
# gera config com phone fragment
make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig qcom-phone.config 2>&1 | tail -3
# troca device tree
python3 - <<'EOF'
import re
p = '.output/.config'
s = open(p).read()
s = re.sub(r'CONFIG_DEFAULT_DEVICE_TREE="[^"]*"',
           'CONFIG_DEFAULT_DEVICE_TREE="qcom/sm7150-motorola-hanoip"', s)
open(p, 'w').write(s)
print("DEVICE_TREE setado")
EOF
grep DEFAULT_DEVICE_TREE .output/.config
