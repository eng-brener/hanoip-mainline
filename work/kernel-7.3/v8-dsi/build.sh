#!/bin/sh
# Build reproduzível dos módulos do experimento de 120 Hz (host side).
#   ./build.sh
# Requer docker e o volume hanoip-kernel73-v3-src (mesmo do v7).
# Saída: msm-dsi-guards.ko.zst e panel-ili7807s-120hz.ko.zst neste diretório.
# Somente volátil: as imagens de teste usam estes módulos no initramfs.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
v7=$(cd "$here/../v7" && pwd)
docker run --rm -v "$v7":/v7:ro -v "$here":/v8 \
	-v hanoip-kernel73-v3-src:/src hanoip-kernel73-v3 \
	bash /v8/build-inside.sh
