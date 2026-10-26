#!/bin/sh
# GPU diagnostic order: expose modem_a Zap firmware before probing DRM.
BB=/bin/busybox
LOG=/run/hanoip-autostart.log
exec >>"$LOG" 2>&1
up() { "$BB" cut -d' ' -f1 /proc/uptime; }
echo "autostart gpu-zap-early $(up)"
cmdline=$("$BB" cat /proc/cmdline)

case " $cmdline " in
*" hanoip.nodisplay "*) echo 'display skipped by cmdline' ;;
*)
    /sbin/load-gpu-firmware || echo 'GPU firmware preparation failed; continuing display without Zap'
    /sbin/load-display
    i=0
    while [ "$("$BB" cat /sys/class/graphics/fb0/name 2>/dev/null)" != msmdrmfb ] && [ "$i" -lt 90 ]; do
        "$BB" sleep 1; i=$((i+1))
    done
    echo "fb0=$("$BB" cat /sys/class/graphics/fb0/name 2>/dev/null) after ${i}s at $(up)"
    "$BB" sleep 3
    printf '\033[2J\033[HHANOIP mainline - GPU Zap early - RAM only\nSSH: root@172.16.42.1\npmOS: enter-pmos\n' > /dev/tty1
    "$BB" cat /sys/bus/platform/devices/*.dsi/error_snapshot 2>/dev/null | "$BB" cut -d' ' -f1
    ;;
esac

case " $cmdline " in
*" hanoip.nonet "*) echo 'network skipped by cmdline' ;;
*) /sbin/start-usbnet ;;
esac
want() { case " $cmdline " in *" hanoip.$1 "*) return 0 ;; esac; [ -e "/etc/hanoip/autoload-$1" ]; }
want ufs && /sbin/load-ufs
want wifi && /sbin/load-wifi
want bt && /sbin/load-bt
echo "autostart done $(up)"
