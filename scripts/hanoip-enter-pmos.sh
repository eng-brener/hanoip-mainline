#!/bin/sh
# Unpack a postmarketOS rootfs tarball into a dedicated tmpfs and chroot
# into it. RAM only: refuses if any non-RAM filesystem is mounted, never
# runs the pmOS init/OpenRC, never mounts phone storage.
#   enter-pmos [/tmp/pmos-rootfs.tar.gz] [command...]
BB=/bin/busybox
ROOT=/mnt/pmos
TARBALL=${1:-/tmp/pmos-rootfs.tar.gz}
[ $# -gt 0 ] && shift

while read -r source target type rest; do
    case "$target" in "$ROOT"|"$ROOT"/*) continue ;; esac
    # Read-only firmware mounts made by load-wifi are the only exception.
    case "$target:$rest" in /mnt/ro/*:ro,*) continue ;; esac
    case "$type" in
        rootfs|ramfs|tmpfs|proc|sysfs|devtmpfs|devpts|configfs|debugfs|tracefs) ;;
        *) echo "Refusing: $target is mounted as $type" >&2; exit 1 ;;
    esac
done < /proc/mounts

if ! $BB grep -q " $ROOT tmpfs " /proc/mounts; then
    [ -f "$TARBALL" ] || { echo "Missing $TARBALL" >&2; exit 1; }
    $BB mkdir -p "$ROOT"
    $BB mount -t tmpfs -o size=1024m,mode=0755 pmos-rootfs "$ROOT"
    $BB tar -xzf "$TARBALL" -C "$ROOT" || { $BB umount "$ROOT"; exit 1; }
    $BB rm -f "$TARBALL"
    printf 'hanoip\n' > "$ROOT/etc/hostname"
    echo "HANOIP: pmOS rootfs unpacked into RAM at $ROOT"
fi

for m in proc sys dev dev/pts run tmp; do
    $BB mkdir -p "$ROOT/$m"
    $BB grep -q " $ROOT/$m " /proc/mounts || $BB mount --bind "/$m" "$ROOT/$m"
done

[ $# -gt 0 ] || set -- /bin/bash -l
exec $BB chroot "$ROOT" /usr/bin/env -i HOME=/root TERM="${TERM:-xterm}" \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin "$@"
