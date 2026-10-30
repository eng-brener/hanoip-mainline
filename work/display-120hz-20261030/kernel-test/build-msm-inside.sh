#!/bin/bash
# Build ONLY msm.ko from the tested listener7 tree (v7.3 + 195 patches) plus the
# local DSI guards. Runs inside the hanoip-kernel73-v3 container.
#   /v7   work/kernel-7.3/v7 (read-only)
#   /out  work/display-120hz-20261030/kernel-test (writable)
#   /src  cache volume (source tree + objects)
# Nothing here touches the phone. The Image.gz is NOT rebuilt: msm is a module.
set -euo pipefail
KREL=7.3.0-sm7150
MAKE="make -C /src/linux O=/src/obj ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="
GIT="git -c user.name=hanoip -c user.email=hanoip@localhost"
BASE_TREE=30fd2ef82912c26cf3a58ad0ba6afc375fa851ac
TREE=276fbce0ae673c83e456cfe359c33ed3c4e3468b

cd /src/linux
$GIT reset -q --hard base
$GIT am -q /v7/patches/*.patch
got=$(git rev-parse HEAD^{tree})
[ "$got" = $TREE ] || { echo "tree $got != tested $TREE"; exit 1; }
echo "baseline tree OK ($TREE)"

git apply --verbose -p2 /out/dsi-fixes-all.patch
git apply --verbose -p1 /out/0197-marker.patch
$GIT add -A
$GIT commit -q -m "hanoip dsi: guards for resume/clock/dsc/mode plus test marker"
echo "patched tree $(git rev-parse HEAD^{tree}) at $(git rev-parse --short HEAD)"

mkdir -p /src/obj
cp /v7/config-7.3-hanoip /src/obj/.config
$MAKE olddefconfig >/dev/null

# Full modules pass: a single-module build lacks Module.symvers from drm/*.
# Only msm.ko is taken; the kernel Image stays the tested listener7.
$MAKE -j"$(nproc)" modules

ko=/src/obj/drivers/gpu/drm/msm/msm.ko
[ -f "$ko" ] || { echo "msm.ko not built"; exit 1; }
ver=$(modinfo -F vermagic "$ko")
echo "vermagic: $ver"
case "$ver" in
	"$KREL "*) ;;
	*) echo "REFUSING: unexpected vermagic"; exit 1 ;;
esac
case "$ver" in
	*'+'*) echo "REFUSING: dirty-tree '+' in vermagic"; exit 1 ;;
esac
# The marker must be present in the binary so the boot log can prove the load.
# Dump to a file first: `strings | grep -q` under pipefail fails on SIGPIPE.
strings "$ko" > /src/msm.strings
grep -q 'hanoip-dsi-guards' /src/msm.strings || { echo "marker missing"; exit 1; }
grep -q 'DSI: invalid input' /src/msm.strings || { echo "unexpected build"; exit 1; }

aarch64-linux-gnu-strip --strip-debug -o /src/out-msm.ko "$ko"
zstd -q -T0 -19 -f /src/out-msm.ko -o /out/msm-dsifix.ko.zst
ls -l /out/msm-dsifix.ko.zst
sha256sum /out/msm-dsifix.ko.zst
