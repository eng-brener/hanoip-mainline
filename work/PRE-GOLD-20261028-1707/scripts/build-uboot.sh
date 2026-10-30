#!/bin/sh
# Build a hanoip U-Boot image (embedded DT) from uboot-sm7150/ (host side).
#   ./build.sh DT_NAME          e.g. ./build.sh sm7150-motorola-hanoip-pmos-perif
# DT_NAME is a .dts in uboot-sm7150/dts/upstream/src/arm64/qcom/. Writes
# out/<DT_NAME>/u-boot.bin, uboot.dtb and u-boot-<DT_NAME>.img (header from
# the GOLD-20261026-1500 U-Boot). Volatile use only: `fastboot boot` it.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
dt=${1:?usage: build.sh DT_NAME}
[ -f "$repo/uboot-sm7150/dts/upstream/src/arm64/qcom/$dt.dts" ] || { echo "no such DT: $dt"; exit 1; }
out="$here/out/$dt"
mkdir -p "$out"

docker build -q -t hanoip-uboot "$here" >/dev/null
# The source tree is mounted read-only; objects go to a cache volume.
docker run --rm -v "$repo/uboot-sm7150":/src:ro -v "$here":/b \
	-v hanoip-uboot-obj:/obj -e DT="$dt" hanoip-uboot sh -euc '
	o=/obj/$DT; mkdir -p $o
	sed "s|^CONFIG_DEFAULT_DEVICE_TREE=.*|CONFIG_DEFAULT_DEVICE_TREE=\"qcom/$DT\"|;
	     s|^CONFIG_OF_LIST=.*|CONFIG_OF_LIST=\"qcom/$DT\"|" /b/base.config > $o/.config
	export CROSS_COMPILE=aarch64-linux-gnu-
	make -C /src O=$o olddefconfig >/dev/null
	make -C /src O=$o -j"$(nproc)" >/dev/null
	cp $o/u-boot.bin /b/out/$DT/
	cp $o/dts/upstream/src/arm64/qcom/$DT.dtb /b/out/$DT/uboot.dtb'

python3 -I - "$repo" "$out" "$dt" <<'PY'
import importlib.util, sys
from pathlib import Path
repo, out, dt = Path(sys.argv[1]), Path(sys.argv[2]), sys.argv[3]
spec = importlib.util.spec_from_file_location('hboot', repo / 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
img = out / f'u-boot-{dt}.img'
img.unlink(missing_ok=True)
m.pack_uboot_v3(repo / 'work/GOLD-20261026-1500/u-boot-hanoip-pmos-perif-v5.img', out / 'u-boot.bin', img)
print('packed', img)
PY
(cd "$out" && shasum -a 256 u-boot.bin uboot.dtb "u-boot-$dt.img" > SHA256SUMS && cat SHA256SUMS)
