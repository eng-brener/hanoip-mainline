#!/bin/bash
# Runs inside the v3 container (v7) (see build.sh). Fetches upstream v7.3, applies
# patches/, checks that the result is exactly the tested tree, then builds
# Image, modules, the out-of-tree hanoip_mmi_unit_info module and the DT.
#   /v3   this directory (read-write: out/ is written here)
#   /src  cache volume (tarball, source tree, objects)
set -euo pipefail
# Bump de compilação e data embutidos no banner: fixos para reproduzir a
# Image do listener7 (#64, 16:26:38 UTC de 30/10). Sobrescreva por env.
export KBUILD_BUILD_VERSION="${KBUILD_BUILD_VERSION:-64}"
export KBUILD_BUILD_TIMESTAMP="${KBUILD_BUILD_TIMESTAMP:-Fri Oct 30 16:26:38 UTC 2026}"
V=7.3
URL=https://cdn.kernel.org/pub/linux/kernel/v7.x/linux-$V.tar.xz
BASE_TREE=30fd2ef82912c26cf3a58ad0ba6afc375fa851ac	# git tree of tag v7.3
TREE=276fbce0ae673c83e456cfe359c33ed3c4e3468b		# v7.3 + patches/ (v6 + QSEECOM legado/listener RPMB para a digital FPC)
KREL=7.3.0-sm7150
MAKE="make -C /src/linux O=/src/obj ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION="
GIT="git -c user.name=hanoip -c user.email=hanoip@localhost"

cd /src
if [ ! -d linux/.git ]; then
	# kernel.org tarballs drift to the newest 7.3.x stable; pin the exact
	# v7.3 tag via git so the tree hash matches BASE_TREE.
	rm -rf linux
	git clone -q --depth 1 --branch v7.3 https://github.com/torvalds/linux.git linux
	cd linux
	got=$(git rev-parse HEAD^{tree})
	[ "$got" = $BASE_TREE ] || { echo "tag v7.3 tree $got is not v$V ($BASE_TREE)"; exit 1; }
	$GIT tag base
	cd /src
fi

cd linux
$GIT reset -q --hard base
$GIT am -q /v3/patches/*.patch
got=$(git rev-parse HEAD^{tree})
[ "$got" = $TREE ] || { echo "patched tree $got differs from the tested $TREE"; exit 1; }
echo "source tree OK ($TREE)"
echo "$got" > /src/obj/.tree-v7

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

# NetHunter USB Wi-Fi drivers (out-of-tree, aircrack-ng). Pinned branches;
# best-effort: a failure warns but does not stop the kernel build.
for drv in "rtl8812au v5.13.6 88XXau.ko" "rtl8188eus master 8188eu.ko"; do
	set -- $drv; name=$1; branch=$2; ko=$3
	if [ ! -d /src/$name/.git ]; then
		rm -rf /src/$name
		git clone -q --depth 1 --branch $branch \
			https://github.com/aircrack-ng/$name.git /src/$name || {
			echo "WARNING: could not clone $name, skipping"; continue; }
	fi
	# kbuild >= 6.x dropped EXTRA_CFLAGS; these Makefiles only use it.
	sed -i 's/^EXTRA_CFLAGS += /ccflags-y += /' /src/$name/Makefile
	# I386_PC=n loses -DCONFIG_LITTLE_ENDIAN/-DCONFIG_IOCTL_CFG80211.
	grep -q hanoip-little-endian /src/$name/Makefile || echo 'ccflags-y += -DCONFIG_LITTLE_ENDIAN -DCONFIG_IOCTL_CFG80211 -DRTW_USE_CFG80211_STA_EVENT # hanoip-little-endian' >> /src/$name/Makefile
	# Timer API rework (>= 7.x): from_timer/del_timer_sync/del_timer gone.
	python3 - "$name" <<'PYEOF'
import sys
name = sys.argv[1]
p = f"/src/{name}/include/osdep_service_linux.h"
try:
    s = open(p).read()
except FileNotFoundError:
    sys.exit(0)
if "timer_container_of" not in s and "#include <linux/slab.h>" in s:
    shim = ("#include <linux/slab.h>\n#include <linux/timer.h>\n\n"
            "/* Kernels >= 7.x reworked the timer API. */\n"
            "#ifndef from_timer\n"
            "#define from_timer(var, callback_timer, timer_fieldname) \\\n"
            "\ttimer_container_of(var, callback_timer, timer_fieldname)\n"
            "#endif\n"
            "#ifndef del_timer_sync\n"
            "#define del_timer_sync(t) timer_shutdown_sync(t)\n"
            "#endif\n"
            "#ifndef del_timer\n"
            "#define del_timer(t) timer_delete(t)\n"
            "#endif\n")
    open(p, "w").write(s.replace("#include <linux/slab.h>\n", shim, 1))
    print(f"extra: timer shim applied to {name}")
PYEOF
	( cd /src/$name && make -j"$(nproc)" ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- KSRC=/src/obj CONFIG_PLATFORM_I386_PC=n CONFIG_PLATFORM_ARM64_RPI=y CONFIG_BR_EXT=n modules 2>&1 | tail -3 ) || {
		echo "WARNING: $name failed to build against 7.3, skipping"; continue; }
	find /src/$name -name "$ko" -exec cp -a {} /src/extra/ \;
	echo "extra: $ko OK"
done
ls /src/extra/*.ko 2>/dev/null || true

rm -rf /src/mod
$MAKE INSTALL_MOD_PATH=/src/mod INSTALL_MOD_STRIP=1 DEPMOD=true modules_install >/dev/null
M=/src/mod/lib/modules/$KREL
rm -f "$M/build" "$M/source"
mkdir -p "$M/extra"
for k in /src/extra/*.ko; do
	aarch64-linux-gnu-strip --strip-debug -o "$M/extra/$(basename $k)" "$k"
done
depmod -b /src/mod $KREL

mkdir -p /v3/out
gzip -9n -c /src/obj/arch/arm64/boot/Image > /v3/out/Image.gz
cp /src/obj/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb /v3/out/kernel.dtb
tar -C /src/mod/lib/modules --owner=0 --group=0 --sort=name --mtime=@0 \
	-czf /v3/out/modules-$KREL.tar.gz $KREL
strings /src/obj/arch/arm64/boot/Image | grep "Linux version" | head -n 1 > /v3/out/version.txt || true
echo "built: $(cat /v3/out/version.txt)"
