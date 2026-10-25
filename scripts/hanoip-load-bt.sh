#!/bin/sh
# Volatile WCN3990 Bluetooth bring-up over uart3 (hci_uart/QCA). Firmware
# (qca/crbtfw21.tlv, qca/crnv21.bin) is read from bluetooth_a mounted
# read-only and verified unchanged by hash. U-Boot sets local-bd-address
# from ABL's androidboot.btmacaddr; without it the controller stays
# "unconfigured" until btmgmt public-addr is run. Never stored in the image.
BB=/bin/busybox
LOG=/run/hanoip-bt.log
MNT=/mnt/ro/bluetooth_a
W=/lib/hanoip-bt
up() { $BB cut -d' ' -f1 /proc/uptime; }
fail() { echo "HANOIP bt: $*" >&2; exit 1; }
[ ! -e /run/hanoip-bt-started ] || fail "already started"

part() {
    for b in /sys/class/block/sd*; do
        [ "$($BB grep PARTNAME= $b/uevent 2>/dev/null)" = "PARTNAME=$1" ] && { echo /dev/${b##*/}; return 0; }
    done
    return 1
}

[ -b "$(part bluetooth_a 2>/dev/null)" ] || /sbin/load-ufs || fail "UFS not available"
for b in /sys/class/block/sd*; do
    [ "$($BB cat $b/ro)" = 1 ] || fail "${b##*/} is not read-only"
done
$BB touch /run/hanoip-bt-started
exec > "$LOG" 2>&1
echo "start $(up)"

D=$(part bluetooth_a) || fail "bluetooth_a missing"
PRE=$($BB sha256sum $D | $BB cut -c1-64); echo "bluetooth_a $D pre $PRE"
$BB mkdir -p $MNT /lib/firmware/qca
$BB mount -t ext4 -o ro,noload,nodev,nosuid,noexec $D $MNT || fail "mount bluetooth_a"
for f in $MNT/image/*; do $BB ln -sf "$f" "/lib/firmware/qca/${f##*/}"; done

for m in rfkill ecc ecdh_generic bluetooth btqca btbcm hci_uart rfcomm; do
    $BB grep -q "^$m " /proc/modules || $BB insmod $W/$m.ko 2>/dev/null ||
        $BB insmod /lib/hanoip-wifi/$m.ko 2>/dev/null || echo "insmod $m failed"
done
i=0
while ! $BB dmesg | $BB grep -q "QCA setup on UART is completed" && [ $i -lt 20 ]; do
    $BB sleep 1; i=$((i+1))
done
$BB dmesg | $BB grep -E "hci0: QCA (SOC|ROM) Version|QCA Downloading|QCA setup"
echo "hci: $($BB ls /sys/class/bluetooth 2>/dev/null) after ${i}s at $(up)"
B=$($BB find /proc/device-tree/soc@0 -name local-bd-address 2>/dev/null | $BB head -1)
[ -n "$B" ] && echo "local-bd-address present in DT" || echo "no local-bd-address: controller stays unconfigured"
POST=$($BB sha256sum $D | $BB cut -c1-64)
[ "$PRE" = "$POST" ] && echo "bluetooth_a unchanged" || echo "bluetooth_a HASH CHANGED $POST"
