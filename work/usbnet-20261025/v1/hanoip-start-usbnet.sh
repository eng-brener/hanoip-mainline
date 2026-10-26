#!/bin/sh
# USB NCM network + SSH/SFTP for the RAM-only diagnostic rootfs.
# Device 172.16.42.1, host gets 172.16.42.2 by DHCP (no route, no DNS).
# Dropbear is key-only; host keys are generated per boot in RAM.
BB=/bin/busybox
LOG=/run/hanoip-usbnet.log
exec >> "$LOG" 2>&1
echo "start $($BB cat /proc/uptime)"

# Convenience applet links, without filesystem/partition writers.
$BB mkdir -p /usr/bin /usr/sbin
for applet in $($BB --list); do
    case "$applet" in
        mkfs*|mke2fs|mkdosfs|mkswap|fdisk|tune2fs|fsck*|blkdiscard|fstrim|\
        hdparm|shred|partprobe|nand*|ubi*|flash*|swapon|losetup|fatattr|\
        setfattr|chattr|resume|raidautorun|freeramdisk) continue ;;
    esac
    [ -e "/bin/$applet" ] || [ -e "/sbin/$applet" ] || [ -e "/usr/bin/$applet" ] ||
        $BB ln -s /bin/busybox "/usr/bin/$applet"
done

$BB hostname hanoip
$BB ifconfig lo 127.0.0.1 up

G=/sys/kernel/config/usb_gadget/g1/functions/ncm.usb0
IF=$($BB cat "$G/ifname" 2>/dev/null)
case "$IF" in ''|*unnamed*) IF=usb0 ;; esac
i=0
while [ ! -e "/sys/class/net/$IF" ] && [ $i -lt 30 ]; do $BB sleep 1; i=$((i+1)); done
$BB ifconfig "$IF" 172.16.42.1 netmask 255.255.255.0 up || { echo "no $IF"; exit 1; }

$BB cat > /run/udhcpd.conf <<EOF
start 172.16.42.2
end 172.16.42.2
interface $IF
lease_file /run/udhcpd.leases
max_leases 1
option subnet 255.255.255.0
option lease 86400
EOF
$BB touch /run/udhcpd.leases
$BB udhcpd /run/udhcpd.conf

$BB mkdir -p /etc/dropbear
$BB chmod 700 /root /root/.ssh
$BB chmod 600 /root/.ssh/authorized_keys
/sbin/dropbear -R -s -p 22 -P /run/dropbear.pid
echo "ready $IF $($BB cat /proc/uptime)"
