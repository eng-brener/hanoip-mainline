#!/bin/sh
# Rebuild the hanoip 7.3 v3 kernel from upstream v7.3 + patches/ (host side).
#   ./build.sh [RAMDISK.cpio.gz]
# Needs docker. Writes out/Image.gz, out/kernel.dtb, out/modules-7.3.0-sm7150.tar.gz
# and, when a ramdisk is given (or a known local one exists), out/kernel-hanoip-
# pmos-7.3-v3.img for a volatile `fastboot boot`. Nothing touches the phone.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)

docker build -q -t hanoip-kernel73-v3 "$here" >/dev/null
docker volume create hanoip-kernel73-v3-src >/dev/null
# Reproducibilidade byte a byte da Image do listener7 bootado (#64).
docker run --rm -v "$here":/v3 -v hanoip-kernel73-v3-src:/src \
	-e KBUILD_BUILD_VERSION="${KBUILD_BUILD_VERSION:-64}" \
	-e KBUILD_BUILD_TIMESTAMP="${KBUILD_BUILD_TIMESTAMP:-Fri Oct 30 16:26:38 UTC 2026}" \
	hanoip-kernel73-v3 bash /v3/build-inside.sh

# The ramdisk is not in the repository (the pmOS one embeds vendor firmware).
ramdisk=${1:-}
for r in "$repo/work/GOLD-20261026-1500/ramdisk-v4.cpio.gz" "$here/../v2/ramdisk.cpio.gz"; do
	[ -n "$ramdisk" ] || { [ -f "$r" ] && ramdisk=$r; }
done
if [ -z "$ramdisk" ]; then
	echo "no ramdisk given: skipping the boot image"
	exit 0
fi
python3 -I "$here/pack-boot.py" "$ramdisk"
(cd "$here/out" && shasum -a 256 Image.gz kernel.dtb modules-7.3.0-sm7150.tar.gz kernel-hanoip-pmos-7.3-v3.img > SHA256SUMS)
cat "$here/out/SHA256SUMS"
