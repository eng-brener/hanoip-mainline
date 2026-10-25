#!/bin/sh
# Boot order that kept the panel lit: display first, network/SSH after the
# DRM framebuffer is up. Started in background by /init; the ACM serial
# shell is available meanwhile. Kernel cmdline hanoip.nodisplay skips the
# display; hanoip.nonet skips network/SSH. Storage is never loaded here.
BB=/bin/busybox
LOG=/run/hanoip-autostart.log
exec >> "$LOG" 2>&1
up() { $BB cut -d' ' -f1 /proc/uptime; }
echo "autostart $(up)"
cmdline=$($BB cat /proc/cmdline)

case " $cmdline " in
*" hanoip.nodisplay "*) echo 'display skipped by cmdline' ;;
*)
    /sbin/load-display
    i=0
    while [ "$($BB cat /sys/class/graphics/fb0/name 2>/dev/null)" != msmdrmfb ] && [ $i -lt 90 ]; do
        $BB sleep 1; i=$((i+1))
    done
    echo "fb0=$($BB cat /sys/class/graphics/fb0/name 2>/dev/null) after ${i}s at $(up)"
    $BB sleep 3
    printf '\033[2J\033[HHANOIP mainline - RAM only\nSSH: root@172.16.42.1\npmOS: enter-pmos\n' > /dev/tty1
    $BB cat /sys/bus/platform/devices/*.dsi/error_snapshot 2>/dev/null | $BB cut -d' ' -f1
    ;;
esac

case " $cmdline " in
*" hanoip.nonet "*) echo 'network skipped by cmdline' ;;
*) /sbin/start-usbnet ;;
esac
echo "autostart done $(up)"
