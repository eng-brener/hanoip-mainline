#!/bin/bash
# Runs inside hanoip-kernel73-v3. Baseline = v6 (patches + config em /v6),
# mais o transporte qseecom-fpc aplicado por /work/apply.py.
#
# Não reescreve a baseline: o hash da árvore NÃO é comparado com o do v6, de
# propósito, porque esta árvore tem o patch extra.
set -euo pipefail
MAKE="make -C /src/linux O=/src/obj ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="
GIT="git -c user.name=hanoip -c user.email=hanoip@localhost"

cd /src/linux
$GIT reset -q --hard base
$GIT am -q /v6/patches/*.patch
echo "árvore base: v6 + $(ls /v6/patches/*.patch | wc -l) patches ($($GIT rev-parse --short HEAD))"

python3 /work/apply.py /src/linux

# ARMADILHA DO PROJETO: árvore suja => scripts/setlocalversion acrescenta '+' =>
# vermagic 7.3.0-sm7150+ e nenhum módulo do rootfs carrega. Commitamos o patch
# local (não é enviado a lugar nenhum) para o release ficar limpo.
$GIT add -A
$GIT commit -q -m "wip: qseecom-fpc (etapa A)" || true
echo "árvore final: $($GIT rev-parse --short HEAD) $($GIT describe --always --dirty)"

mkdir -p /src/obj
cp /v6/config-7.3-hanoip /src/obj/.config
/src/linux/scripts/config --file /src/obj/.config -m QCOM_QSEECOM_FPC
$MAKE olddefconfig >/dev/null
grep -E '^CONFIG_QCOM_QSEECOM(_FPC)?=' /src/obj/.config

$MAKE -j"$(nproc)" Image modules

rel=$(cat /src/obj/include/config/kernel.release)
case "$rel" in
*+) echo "ERRO: kernel release '$rel' tem '+' (árvore suja): módulos não carregariam"; exit 1;;
esac
echo "kernel release: $rel"

mkdir -p /work/out
cp /src/obj/arch/arm64/boot/Image /work/out/Image
gzip -9 -c /src/obj/arch/arm64/boot/Image > /work/out/Image.gz
for f in /src/obj/drivers/firmware/qcom/qcom_qseecom_fpc.ko*; do
	cp "$f" /work/out/ 2>/dev/null || true
done
rm -f /work/out/*.mod.c
echo "== out/"
ls -l /work/out/
modinfo /work/out/qcom_qseecom_fpc.ko | grep -E 'filename|vermagic|depends' || true
echo BUILD_OK
