#!/bin/sh
# Load only after the USB shell is connected. Never mount/format any disk.
set -e
BB=/bin/busybox
while read -r source target type rest; do
    case "$type" in
        rootfs|ramfs|tmpfs|proc|sysfs|devtmpfs|devpts|configfs|debugfs|tracefs) ;;
        *) echo "Refusing UFS test: $target is mounted as $type" >&2; exit 1 ;;
    esac
done < /proc/mounts
[ ! -e /run/hanoip-ufs-started ] || { echo 'UFS test already started'; exit 1; }
for module in ufshcd-core ufshcd-pltfrm ufs-qcom; do
    [ -f "/lib/hanoip-ufs/$module.ko" ] || { echo "Missing $module.ko" >&2; exit 1; }
done
"$BB" touch /run/hanoip-ufs-started

# BLKROSET changes kernel state, not storage contents. Cover whole disks and
# partitions as they enumerate. No automounter or filesystem service is run.
(
    set +e
    while :; do
        for disk in /dev/sd*; do
            [ -b "$disk" ] || continue
            [ "$("$BB" blockdev --getro "$disk")" = 1 ] || "$BB" blockdev --setro "$disk"
        done
        "$BB" sleep 1
    done
) > /run/hanoip-ufs-readonly.log 2>&1 &
echo "$!" > /run/hanoip-ufs-readonly.pid

"$BB" insmod /lib/hanoip-ufs/ufshcd-core.ko
"$BB" insmod /lib/hanoip-ufs/ufshcd-pltfrm.ko
(
    "$BB" insmod /lib/hanoip-ufs/ufs-qcom.ko
    echo "UFS module loader returned: $?"
) > /run/hanoip-ufs-loader.log 2>&1 &
echo "HANOIP: UFS probe started in background (PID $!); see dmesg"
