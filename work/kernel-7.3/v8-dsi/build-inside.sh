#!/bin/bash
# Build reproduzível dos módulos do experimento de 120 Hz.
#   /v7  work/kernel-7.3/v7 (somente leitura): 195 patches + config do listener7
#   /v8  este diretório (gravável): patches próprios e saída
#   /src cache com a árvore e os objetos
# Nada toca o aparelho. A Image.gz NÃO é reconstruída: msm é módulo e o kernel
# continua sendo o listener7 (276fbce0).
set -euo pipefail
KREL=7.3.0-sm7150
BASE_TREE=30fd2ef82912c26cf3a58ad0ba6afc375fa851ac	# tag v7.3
V7_TREE=276fbce0ae673c83e456cfe359c33ed3c4e3468b	# v7.3 + 195 patches
V8_TREE=e0bc45ad28f73ba4f0858f0a97988e351efa09f5	# + guards DSI + marcador
MAKE="make -C /src/linux O=/src/obj ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="
GIT="git -c user.name=hanoip -c user.email=hanoip@localhost"

cd /src/linux
$GIT reset -q --hard base
$GIT am -q /v7/patches/*.patch
[ "$(git rev-parse HEAD^{tree})" = "$V7_TREE" ] || { echo "arvore v7 diverge"; exit 1; }
echo "arvore do listener7 OK ($V7_TREE)"

git apply -p2 --verbose /v8/patches/0196-dsi-guards.patch
git apply -p1 --verbose /v8/patches/0197-marker.patch
$GIT add -A && $GIT commit -q -m "hanoip dsi: guards + marcador de teste"
tree=$(git rev-parse HEAD^{tree})
[ "$tree" = "$V8_TREE" ] || { echo "arvore $tree != $V8_TREE"; exit 1; }
echo "arvore com as correções DSI OK ($V8_TREE)"

# Modo de 120 Hz no painel: entra depois da conferência acima.
git apply -p1 --verbose /v8/patches/0198-panel-120hz-candidate.patch

cp /v7/config-7.3-hanoip /src/obj/.config
$MAKE olddefconfig >/dev/null
# `make modules` inteiro: um módulo isolado não resolve Module.symvers do drm.
$MAKE -j"$(nproc)" modules >/dev/null

check() { # $1 = .ko
	[ -f "$1" ] || { echo "não construído: $1"; exit 1; }
	ver=$(modinfo -F vermagic "$1")
	case "$ver" in "$KREL "*) ;; *) echo "vermagic inesperado: $ver"; exit 1 ;; esac
	case "$ver" in *'+'*) echo "vermagic sujo (árvore não commitada?)"; exit 1 ;; esac
}

msm=/src/obj/drivers/gpu/drm/msm/msm.ko
panel=/src/obj/drivers/gpu/drm/panel/panel-ilitek-ili7807s.ko
check "$msm"; check "$panel"

# O msm do teste foi stripado; o módulo do painel foi comprimido sem strip.
strings "$msm" > /src/.strings-msm
aarch64-linux-gnu-strip --strip-debug -o /src/.msm.stripped "$msm"
zstd -q -T0 -19 -f /src/.msm.stripped -o /v8/msm-dsi-guards.ko.zst
zstd -q -T0 -19 -f "$panel" -o /v8/panel-ili7807s-120hz.ko.zst
echo "msm-dsi-guards.ko.zst e panel-ili7807s-120hz.ko.zst gerados"

grep -q 'hanoip-dsi-guards' /src/.strings-msm || { echo "marcador ausente no msm"; exit 1; }
strings "$panel" > /src/.strings-panel
grep -q 'experimental 120 Hz candidate' /src/.strings-panel || { echo "marcador ausente no painel"; exit 1; }
sha256sum /v8/*.ko.zst
