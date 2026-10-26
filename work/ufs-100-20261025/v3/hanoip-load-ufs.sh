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
# partitions as they enumerate (polled every 0.1 s). No automounter or
# filesystem service is run.
(
    set +e
    while :; do
        # Set every disk and partition unconditionally: a partition reports
        # read-only through its disk even when its own flag is clear, so a
        # getro check would leave partitions writable if the disk were opened.
        for disk in /dev/sd*; do
            [ -b "$disk" ] && "$BB" blockdev --setro "$disk"
        done
        "$BB" usleep 100000
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

# Report only after the probe finished and every block device is read-only.
i=0
while ! "$BB" grep -q returned /run/hanoip-ufs-loader.log 2>/dev/null && [ $i -lt 900 ]; do
    "$BB" usleep 100000; i=$((i+1))
done
"$BB" sleep 2
total=0; writable=''
for disk in /sys/class/block/sd*; do
    [ -e "$disk" ] || continue
    total=$((total+1))
    [ "$("$BB" cat "$disk/ro")" = 1 ] || writable="$writable ${disk##*/}"
done
"$BB" cat /run/hanoip-ufs-loader.log
if [ -n "$writable" ]; then
    echo "HANOIP: UFS NOT read-only:$writable" >&2
    exit 1
fi
echo "HANOIP: UFS ready, $total block devices, all read-only"
