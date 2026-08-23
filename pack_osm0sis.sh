#!/bin/bash
set -e
cd /home/brener/hanoip-uboot/uboot-sm7150
D=.output
# gzip do u-boot
gzip -f -k $D/u-boot-nodtb.bin
# append dtb
cat $D/u-boot-nodtb.bin.gz $D/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dtb > $D/uboot-dtb
ls -la $D/uboot-dtb
# mkbootimg do osm0sis (como o CI do fork)
./mkbootimg/mkbootimg --base '0x0' --kernel_offset '0x00008000' --pagesize '4096' --kernel $D/uboot-dtb -o $D/u-boot-hanoip.img
echo "=== resultado ==="
ls -la $D/u-boot-hanoip.img
file $D/u-boot-hanoip.img
cp $D/u-boot-hanoip.img /home/brener/hanoip-uboot/work/
echo DONE
