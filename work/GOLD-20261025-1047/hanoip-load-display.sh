#!/bin/sh
# Manual, volatile display bring-up after connecting the USB console.
set -e
BB=/bin/busybox
while read -r source target type rest; do
    case "$type" in
        rootfs|ramfs|tmpfs|proc|sysfs|devtmpfs|devpts|configfs|debugfs|tracefs) ;;
        *) echo "Refusing display test: $target is mounted as $type" >&2; exit 1 ;;
    esac
done < /proc/mounts
# Storage may be exposed only if every disk/partition is kernel read-only.
for disk in /sys/class/block/sd* /sys/class/block/mmcblk*; do
    [ -e "$disk" ] || continue
    [ "$("$BB" cat "$disk/ro" 2>/dev/null)" = 1 ] ||
        { echo "Refusing test: ${disk##*/} is not read-only" >&2; exit 1; }
done
[ ! -e /run/hanoip-display-started ] || { echo 'Display test already started'; exit 1; }
modules='cec drm_display_helper drm_exec drm_gpuvm gpu-sched drm_client_lib
mdt_loader ubwc_config qcom-wled msm panel-ilitek-ili7807s'
for module in $modules; do
    [ -f "/lib/hanoip-display/$module.ko" ] || { echo "Missing $module.ko" >&2; exit 1; }
done
"$BB" touch /run/hanoip-display-started
(
    for module in $modules; do
        echo "HANOIP: loading $module"
        "$BB" insmod "/lib/hanoip-display/$module.ko"
    done
    echo 'HANOIP: display modules loaded'
) > /run/hanoip-display-loader.log 2>&1 &
echo "HANOIP: display probe started (PID $!); see dmesg and /run/hanoip-display-loader.log"
