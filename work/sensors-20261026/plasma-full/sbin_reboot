#!/bin/sh
# The bundled Android BusyBox reboot applet needs setprop. Use kernel SysRq
# only in the diagnostic RAM rootfs, after checking every mounted filesystem.
while read -r source target type rest; do
    case "$type" in
        rootfs|ramfs|tmpfs|proc|sysfs|devtmpfs|devpts|configfs|debugfs|tracefs) ;;
        *) echo "Refusing emergency reset: $target is mounted as $type" >&2; exit 1 ;;
    esac
done < /proc/mounts
[ -w /proc/sysrq-trigger ] || { echo 'Kernel SysRq unavailable' >&2; exit 1; }
echo 'HANOIP: resetting the RAM-only diagnostic system'
echo b > /proc/sysrq-trigger
