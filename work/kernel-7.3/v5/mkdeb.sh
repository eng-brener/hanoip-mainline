#!/bin/sh
# Build hanoip kernel .debs from a v3 build tree (host side, no docker).
#   ./mkdeb.sh
# Reads out/{Image.gz,kernel.dtb,modules-7.3.0-sm7150.tar.gz,version.txt},
# writes out/linux-image-7.3.0-sm7150_7.3.0-sm7150-1_arm64.deb and
# out/linux-headers-7.3.0-sm7150_7.3.0-sm7150-1_arm64.deb.
# Layout follows what kali bootloader.sh expects:
#   /usr/lib/linux-image-<ver>/qcom/sm7150-motorola-hanoip.dtb
set -eu
here=$(cd "$(dirname "$0")" && pwd)
KREL=7.3.0-sm7150
DEBVER=7.3.0-sm7150-1
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

[ -f "$here/out/Image.gz" ] || { echo "run build.sh first"; exit 1; }

# --- linux-image ---
pkg=$work/img
mkdir -p "$pkg/boot" "$pkg/lib/modules" "$pkg/usr/lib/linux-image-$KREL/qcom" "$pkg/DEBIAN"
cp "$here/out/Image.gz" "$pkg/boot/vmlinuz-$KREL"
cp "$here/out/kernel.dtb" "$pkg/usr/lib/linux-image-$KREL/qcom/sm7150-motorola-hanoip.dtb"
tar -xzf "$here/out/modules-7.3.0-sm7150.tar.gz" -C "$pkg/lib/modules"
cat > "$pkg/DEBIAN/control" <<EOF
Package: linux-image-$KREL
Version: $DEBVER
Architecture: arm64
Maintainer: hanoip-mainline
Description: hanoip mainline kernel 7.3 (sm7150, Moto G60)
 Mainline 7.3 + hanoip patches (display, touch, audio, sensors,
 QRTR fix, Venus). Volatile boot via U-Boot; DT comes from U-Boot.
EOF
cat > "$pkg/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
depmod 7.3.0-sm7150 || true
EOF
chmod 755 "$pkg/DEBIAN/postinst"
fakeroot dpkg-deb -b "$pkg" "$here/out/linux-image-$KREL"_"$DEBVER"_arm64.deb >/dev/null \
	|| dpkg-deb -b --root-owner-group "$pkg" "$here/out/linux-image-$KREL"_"$DEBVER"_arm64.deb >/dev/null

# --- linux-headers (for out-of-tree/DKMS builds, e.g. Realtek) ---
# Headers come from the kernel source tree; v3 keeps no source copy on the
# Mac, so this package carries a build manifest instead of full headers.
hpkg=$work/hdr
mkdir -p "$hpkg/DEBIAN" "$hpkg/usr/share/doc/linux-headers-$KREL"
cat > "$hpkg/DEBIAN/control" <<EOF
Package: linux-headers-$KREL
Version: $DEBVER
Architecture: arm64
Maintainer: hanoip-mainline
Description: build manifest for hanoip kernel 7.3 (placeholder)
 Full headers are produced by work/kernel-7.3/v3/build.sh (out/ tree).
 Realtek/DKMS builds should use that tree (KSRC) instead of this package.
EOF
echo "hanoip kernel $KREL headers: use the v3 build tree, not this stub." \
	> "$hpkg/usr/share/doc/linux-headers-$KREL/README"
dpkg-deb -b --root-owner-group "$hpkg" "$here/out/linux-headers-$KREL"_"$DEBVER"_arm64.deb >/dev/null
ls -la "$here"/out/*.deb
