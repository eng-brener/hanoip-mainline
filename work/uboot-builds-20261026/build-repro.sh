#!/bin/sh
# Build reproduzivel do U-Boot do hanoip a partir do git, sem depender da
# arvore local uboot-sm7150/ (332 MB, fora do repositorio).
#
#   ./build-repro.sh [DT_NAME]      padrao: sm7150-motorola-hanoip-cam-tres
#
# Fonte: fork sm7150-mainline/u-boot, branch tauchgang no commit de BASE.txt,
# mais patches/hanoip-vs-sm7150-mainline-tauchgang.diff, mais base.config com
# CONFIG_DEFAULT_DEVICE_TREE/OF_LIST apontando para o DT escolhido.
# Saida: out/<DT>/u-boot.bin, uboot.dtb, u-boot-<DT>.img e SHA256SUMS.
# Nada toca o aparelho; uso somente volatil (fastboot boot).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
dt=${1:-sm7150-motorola-hanoip-cam-tres}
base=$(awk -F' = ' 'NR==1 {print $2}' "$here/patches/BASE.txt")
[ -n "$base" ] || { echo "BASE.txt sem commit"; exit 1; }
url=https://github.com/sm7150-mainline/u-boot
cache="$here/.cache/u-boot"

mkdir -p "$here/.cache"
if [ ! -d "$cache/.git" ]; then
	rm -rf "$cache"
	git init -q "$cache"
	git -C "$cache" remote add origin "$url"
fi
git -C "$cache" fetch -q --depth 1 origin "$base"
git -C "$cache" -c advice.detachedHead=false checkout -q --force FETCH_HEAD
git -C "$cache" reset -q --hard FETCH_HEAD
git -C "$cache" clean -qfdx

git -C "$cache" apply --whitespace=nowarn \
	"$here/patches/hanoip-vs-sm7150-mainline-tauchgang.diff"
# Delta posterior (28-29/10): DTS de cameras, dtsi e demais ajustes.
git -C "$cache" apply --whitespace=nowarn \
	"$here/patches/hanoip-dts-cam-tres-delta.diff"
tree=$(git -C "$cache" add -A >/dev/null && git -C "$cache" write-tree)
echo "arvore resultante: $tree"
expected_tree=${EXPECTED_TREE:-a38f1757adeb8ce1d8d0147de1a851a3b28d3f02}
if [ "$tree" != "$expected_tree" ]; then
	echo "ERRO: arvore $tree difere da esperada $expected_tree"
	exit 1
fi

[ -f "$cache/dts/upstream/src/arm64/qcom/$dt.dts" ] || {
	echo "DT inexistente no fork: $dt"; exit 1; }

out="$here/out/$dt"
mkdir -p "$out"
docker build -q -t hanoip-uboot "$here" >/dev/null
# SOURCE_DATE_EPOCH do build validado (29/10 18:00:28 UTC): com ele o
# u-boot.bin sai byte-identico. Sobrescreva com SOURCE_DATE_EPOCH=...
epoch=${SOURCE_DATE_EPOCH:-1793296828}
docker run --rm -v "$cache":/src:ro -v "$here":/b -v hanoip-uboot-obj:/obj \
	-e DT="$dt" -e SOURCE_DATE_EPOCH="$epoch" hanoip-uboot sh -euc '
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
# O cabecalho v3 (versao, paginas) vem de uma imagem ja validada e versionada;
# so o payload (u-boot.bin) muda.
m.pack_uboot_v3(repo / 'work/GOLD-20261026-1500/u-boot-hanoip-pmos-perif-v5.img',
                out / 'u-boot.bin', img)
print('packed', img.name)
PY
(cd "$out" && shasum -a 256 u-boot.bin uboot.dtb "u-boot-$dt.img" > SHA256SUMS && cat SHA256SUMS)
