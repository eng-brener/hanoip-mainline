#!/bin/sh
# Live chroot test; only the already-mounted RAM root may be changed.
set -eu
BB=/bin/busybox
R=/mnt/plasma
$BB grep -q " $R tmpfs " /proc/mounts || exit 1
for b in /sys/class/block/*; do
 n=${b##*/}; case "$n" in loop*|ram*|zram*) continue ;; esac
 $BB blockdev --setro /dev/$n
 [ "$(cat "$b/ro")" = 1 ] || exit 1
done
$BB mkdir -p /dev/pts
$BB grep -q ' /dev/pts devpts ' /proc/mounts || $BB mount -t devpts -o mode=0620,ptmxmode=0666 devpts /dev/pts
for d in dev proc sys run; do
 $BB mkdir -p "$R/$d"
 $BB grep -q " $R/$d " /proc/mounts || $BB mount -o bind /$d "$R/$d"
done
# /dev/pts is a separate mount; a non-recursive /dev bind does not include it.
$BB grep -q " $R/dev/pts " /proc/mounts || $BB mount -o bind /dev/pts "$R/dev/pts"
$BB mkdir -p "$R/etc/udev/rules.d" "$R/run/openrc" "$R/run/user/10000"
$BB chown -R 10000:10000 "$R/home/user" "$R/run/user/10000"
$BB chmod 700 "$R/run/user/10000"
# Restrict the tag to ADSP; this board has no magnetometer.
cat > "$R/etc/udev/rules.d/99-hanoip-ssc.rules" <<'RULE'
ACTION!="remove", SUBSYSTEM=="misc", KERNEL=="fastrpc-adsp*", ENV{IIO_SENSOR_PROXY_TYPE}="ssc-accel ssc-light ssc-proximity"
RULE
# Start only the live-session services, never the disk-root boot scripts.
$BB touch "$R/run/openrc/softlevel"
$BB chroot "$R" /usr/bin/dbus-uuidgen --ensure
$BB chroot "$R" /etc/init.d/dbus start
$BB chroot "$R" /etc/init.d/udev start
$BB chroot "$R" /sbin/udevadm control --reload-rules
$BB chroot "$R" /sbin/udevadm trigger --action=add --subsystem-match=misc --subsystem-match=drm --subsystem-match=input --subsystem-match=graphics --subsystem-match=backlight --subsystem-match=tty
$BB chroot "$R" /sbin/udevadm settle --timeout=10
$BB chroot "$R" /etc/init.d/elogind start
$BB chroot "$R" /etc/init.d/iio-sensor-proxy start
$BB chroot "$R" /etc/init.d/tinydm start
