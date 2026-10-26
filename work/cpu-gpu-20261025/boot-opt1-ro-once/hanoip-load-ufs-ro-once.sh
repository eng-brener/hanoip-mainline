#!/bin/sh
# UFS diagnostic loader with one BLKROSET per newly enumerated disk/partition.
# Keep scanning until the inventory is stable, validate every node RO, then
# stop the guard instead of reissuing blockdev --setro forever.
set -e
BB=/bin/busybox
LOADER=/run/hanoip-ufs-loader.log
ROLOG=/run/hanoip-ufs-readonly.log
SEEN=/run/hanoip-ufs-ro-seen
DONE=/run/hanoip-ufs-ro-complete
FAILED=/run/hanoip-ufs-ro-failed

while read -r source target type rest; do
    case "$target:$rest" in /mnt/ro/*:ro,*) continue ;; esac
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
"$BB" mkdir -p "$SEEN"

# Scan at 10 Hz while UFS enumerates. Each block node is marked only after its
# own blockdev ioctl succeeds. The stability window also catches late LUNs and
# partitions before the caller mounts modem_a.
(
    last=''
    stable=0
    iteration=0
    while [ "$iteration" -lt 900 ]; do
        current=''
        count=0
        pending=0
        for entry in /sys/class/block/sd*; do
            [ -e "$entry/ro" ] || continue
            name=${entry##*/}
            current="$current $name"
            count=$((count+1))
            marker="$SEEN/$name"
            if [ ! -e "$marker" ]; then
                if [ -b "/dev/$name" ] && "$BB" blockdev --setro "/dev/$name" &&
                   [ "$("$BB" cat "$entry/ro")" = 1 ]; then
                    "$BB" touch "$marker"
                else
                    pending=$((pending+1))
                fi
            fi
        done

        if "$BB" grep -q returned "$LOADER" 2>/dev/null &&
           [ "$count" -gt 0 ] && [ "$current" = "$last" ] &&
           [ "$pending" -eq 0 ]; then
            stable=$((stable+1))
        else
            stable=0
        fi

        # Eight seconds with an unchanged inventory after module probe return.
        if [ "$stable" -ge 80 ]; then
            writable=''
            for entry in /sys/class/block/sd*; do
                [ -e "$entry/ro" ] || continue
                name=${entry##*/}
                [ -e "$SEEN/$name" ] || writable="$writable $name(unmarked)"
                [ "$("$BB" cat "$entry/ro")" = 1 ] || writable="$writable $name"
            done
            if [ -z "$writable" ]; then
                echo "RO inventory stable: $count block nodes, all read-only"
                "$BB" touch "$DONE"
                exit 0
            fi
            echo "RO validation pending:$writable"
            stable=0
        fi

        last=$current
        "$BB" usleep 100000
        iteration=$((iteration+1))
    done
    echo 'Timed out waiting for stable RO block inventory'
    "$BB" touch "$FAILED"
) > "$ROLOG" 2>&1 &

"$BB" insmod /lib/hanoip-ufs/ufshcd-core.ko
"$BB" insmod /lib/hanoip-ufs/ufshcd-pltfrm.ko
(
    "$BB" insmod /lib/hanoip-ufs/ufs-qcom.ko
    echo "UFS module loader returned: $?"
) > "$LOADER" 2>&1 &
echo "HANOIP: UFS probe started in background (PID $!); RO guard marks new nodes once"

i=0
while [ ! -e "$DONE" ] && [ ! -e "$FAILED" ] && [ "$i" -lt 900 ]; do
    "$BB" usleep 100000
    i=$((i+1))
done
if [ ! -e "$DONE" ]; then
    "$BB" cat "$ROLOG" >&2
    echo 'HANOIP: UFS not ready; refusing firmware mounts' >&2
    exit 1
fi

"$BB" cat "$LOADER"
"$BB" cat "$ROLOG"
total=0
for entry in /sys/class/block/sd*; do
    [ -e "$entry/ro" ] || continue
    total=$((total+1))
    [ "$("$BB" cat "$entry/ro")" = 1 ] || {
        echo "HANOIP: UFS NOT read-only: ${entry##*/}" >&2; exit 1;
    }
done
echo "HANOIP: UFS ready, $total block devices, all read-only; guard stopped"
