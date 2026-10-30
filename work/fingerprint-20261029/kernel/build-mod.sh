#!/bin/sh
# Compila SÓ o módulo qcom_qseecom_fpc.ko sobre a árvore já preparada em /src.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
docker run --rm \
	-v "$here":/work \
	-v "$repo/work/kernel-7.3/v6":/v6:ro \
	-v hanoip-kernel73-v3-src:/src \
	hanoip-kernel73-v3 bash /work/build-mod-inside.sh
