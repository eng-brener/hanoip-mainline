#!/bin/sh
# Compila o transporte qseecom-fpc por cima da árvore 7.3 v6 (baseline congelada).
#   ./build.sh            -> Image + módulos (inclui qcom_qseecom_fpc.ko)
# Nada é enviado ao aparelho; só escreve em out/ e no volume de cache do docker.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
v6="$repo/work/kernel-7.3/v6"

docker run --rm \
	-v "$here":/work \
	-v "$v6":/v6:ro \
	-v hanoip-kernel73-v3-src:/src \
	hanoip-kernel73-v3 bash /work/build-inside.sh
