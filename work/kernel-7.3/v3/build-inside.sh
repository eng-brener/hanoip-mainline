#!/bin/bash
# Runs inside the v3 container (see build.sh). Fetches upstream v7.3, applies
# patches/, checks that the result is exactly the tested tree, then builds
# Image, modules, the out-of-tree hanoip_mmi_unit_info module and the DT.
#   /v3   this directory (read-write: out/ is written here)
#   /src  cache volume (tarball, source tree, objects)
set -euo pipefail
V=7.3
URL=https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$V.tar.xz
BASE_TREE=30fd2ef82912c26cf3a58ad0ba6afc375fa851ac	# git tree of tag v7.3
TREE=19b139f72e7212496c9ed40d5115a2b015236619		# v7.3 + patches/ (tested)
KREL=7.3.0-sm7150
MAKE="make -C /src/linux O=/src/obj ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="
GIT="git -c user.name=hanoip -c user.email=hanoip@localhost"

cd /src
if [ ! -d linux/.git ]; then
	[ -f linux-$V.tar.xz ] || curl -fL -o linux-$V.tar.xz.part "$URL"
	[ -f linux-$V.tar.xz ] || mv linux-$V.tar.xz.part linux-$V.tar.xz
	rm -rf linux && mkdir linux
	tar -xf linux-$V.tar.xz -C linux --strip-components=1
	cd linux
	$GIT init -q
	$GIT add -A
	$GIT commit -q -m "Linux $V (kernel.org tarball)"
	got=$(git rev-parse HEAD^{tree})
	[ "$got" = $BASE_TREE ] || { echo "tarball tree $got is not v$V ($BASE_TREE)"; exit 1; }
	$GIT tag base
	cd /src
fi

cd linux
$GIT reset -q --hard base
$GIT am -q /v3/patches/*.patch
got=$(git rev-parse HEAD^{tree})
[ "$got" = $TREE ] || { echo "patched tree $got differs from the tested $TREE"; exit 1; }
echo "source tree OK ($TREE)"

mkdir -p /src/obj
cp /v3/config-7.3-hanoip /src/obj/.config
$MAKE olddefconfig >/dev/null
# Toolchain version lines may differ with a newer Ubuntu compiler; anything
# else changing means the config no longer matches the tested one.
TOOL='CONFIG_(CC_VERSION_TEXT|GCC_VERSION|AS_VERSION|LD_VERSION|CLANG_VERSION|LLD_VERSION|PAHOLE_VERSION|RUSTC_VERSION|CC_HAS_|AS_HAS_|LD_CAN_|TOOLS_SUPPORT|GCC_ASM_|CC_IS_|AS_IS_|LD_IS_)'
if ! diff -q <(grep -v -E "$TOOL" /v3/config-7.3-hanoip) <(grep -v -E "$TOOL" /src/obj/.config) >/dev/null; then
	diff <(grep -v -E "$TOOL" /v3/config-7.3-hanoip) <(grep -v -E "$TOOL" /src/obj/.config) | head -20
	echo "config changed by olddefconfig"
	exit 1
fi
$MAKE -j"$(nproc)" Image modules qcom/sm7150-motorola-hanoip.dtb

rm -rf /src/extra && cp -a /v3/extra /src/extra
$MAKE M=/src/extra modules

rm -rf /src/mod
$MAKE INSTALL_MOD_PATH=/src/mod INSTALL_MOD_STRIP=1 DEPMOD=true modules_install >/dev/null
M=/src/mod/lib/modules/$KREL
rm -f "$M/build" "$M/source"
mkdir -p "$M/extra"
aarch64-linux-gnu-strip --strip-debug -o "$M/extra/hanoip_mmi_unit_info.ko" /src/extra/hanoip_mmi_unit_info.ko
depmod -b /src/mod $KREL

mkdir -p /v3/out
gzip -9n -c /src/obj/arch/arm64/boot/Image > /v3/out/Image.gz
cp /src/obj/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb /v3/out/kernel.dtb
tar -C /src/mod/lib/modules --owner=0 --group=0 --sort=name --mtime=@0 \
	-czf /v3/out/modules-$KREL.tar.gz $KREL
strings /src/obj/arch/arm64/boot/Image | grep "Linux version" | head -n 1 > /v3/out/version.txt || true
echo "built: $(cat /v3/out/version.txt)"
