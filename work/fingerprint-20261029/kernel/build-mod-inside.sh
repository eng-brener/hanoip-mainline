#!/bin/bash
# Build incremental: reaplica só o nosso código e compila apenas os módulos.
set -euo pipefail
MAKE="make -C /src/linux O=/src/obj ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="
GIT="git -c user.name=hanoip -c user.email=hanoip@localhost"

cd /src/linux
if [ ! -f /src/obj/include/config/kernel.release ]; then
	echo "ERRO: /src/obj não está configurado; rode build.sh completo primeiro"
	exit 1
fi

# Os arquivos que o apply.py modifica precisam voltar ao estado base, senão as
# guardas de idempotência pulam a inserção do código novo.
$GIT checkout -q base -- drivers/firmware/qcom/qcom_scm.c \
	include/linux/firmware/qcom/qcom_scm.h

python3 /work/apply.py /src/linux
$GIT add -A
$GIT commit -q -m "wip: qseecom listener (passo 1)" || true

time $MAKE -j"$(nproc)" Image modules

rel=$(cat /src/obj/include/config/kernel.release)
case "$rel" in
*+) echo "ERRO: release '$rel' com '+'"; exit 1;;
esac
echo "kernel release: $rel"

mkdir -p /work/out-mod
cp /src/obj/drivers/firmware/qcom/qcom_qseecom_fpc.ko /work/out-mod/
modinfo /work/out-mod/qcom_qseecom_fpc.ko | grep -E 'vermagic' || true
echo BUILD_OK
