#!/bin/sh
# Bring up only the verified SPI touch in an initramfs, never on phone storage.
set -e
BB=/bin/busybox
while read -r source target type rest; do
    case "$type" in
        rootfs|ramfs|tmpfs|proc|sysfs|devtmpfs|devpts|configfs|debugfs|tracefs) ;;
        *) echo "Refusing touch test: $target is mounted as $type" >&2; exit 1 ;;
    esac
done < /proc/mounts
# Storage may be exposed only if every disk/partition is kernel read-only.
for disk in /sys/class/block/sd* /sys/class/block/mmcblk*; do
    [ -e "$disk" ] || continue
    [ "$("$BB" cat "$disk/ro" 2>/dev/null)" = 1 ] ||
        { echo "Refusing test: ${disk##*/} is not read-only" >&2; exit 1; }
done
[ ! -e /run/hanoip-touch-started ] || { echo 'Touch test already started'; exit 1; }
[ -f /lib/firmware/ilitek/hanoip-7807-iram.bin ]
for module in evdev ilitek-hanoip-spi; do
    [ -f "/lib/hanoip-touch/$module.ko" ]
done
"$BB" touch /run/hanoip-touch-started
(
    "$BB" insmod /lib/hanoip-touch/evdev.ko
    "$BB" insmod /lib/hanoip-touch/ilitek-hanoip-spi.ko
    echo 'HANOIP: touch module loader completed; verify input registration and stats'
) > /run/hanoip-touch-loader.log 2>&1 &
echo "HANOIP: SPI touch probe started (PID $!); firmware targets controller RAM only"
