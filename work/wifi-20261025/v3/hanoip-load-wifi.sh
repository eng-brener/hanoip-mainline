#!/bin/sh
# Volatile Wi-Fi bring-up: modem firmware and WLAN board data are read from
# the modem_a partition mounted read-only (kernel RO block device + noload).
# The modem EFS is served by rmtfs from RAM copies in read-only mode
# (-o /run/efs -r): nothing is ever written to UFS.
BB=/bin/busybox
LOG=/run/hanoip-wifi.log
FW=/lib/firmware/qcom/sm7150/motorola/hanoip
MNT=/mnt/ro/modem_a
up() { $BB cut -d' ' -f1 /proc/uptime; }
fail() { echo "HANOIP wifi: $*" >&2; exit 1; }
[ ! -e /run/hanoip-wifi-started ] || fail "already started"

part() { # PARTNAME -> /dev node
    for b in /sys/class/block/sd*; do
        [ "$($BB grep PARTNAME= $b/uevent 2>/dev/null)" = "PARTNAME=$1" ] && { echo /dev/${b##*/}; return 0; }
    done
    return 1
}

[ -b "$(part modem_a 2>/dev/null)" ] || /sbin/load-ufs || fail "UFS not available"
for b in /sys/class/block/sd*; do
    [ "$($BB cat $b/ro)" = 1 ] || fail "${b##*/} is not read-only"
done
$BB touch /run/hanoip-wifi-started
exec > "$LOG" 2>&1
echo "start $(up)"

# Firmware: modem_a read-only, verified unchanged by hash before and after.
M=$(part modem_a) || fail "modem_a missing"
PRE=$($BB sha256sum $M | $BB cut -c1-64); echo "modem_a $M pre $PRE"
$BB mkdir -p $MNT $FW /lib/firmware/ath10k/WCN3990/hw1.0
$BB mount -t ext4 -o ro,noload,nodev,nosuid,noexec $M $MNT || fail "mount modem_a"
for f in $MNT/image/*; do $BB ln -sf "$f" "$FW/${f##*/}"; done
$BB ln -sf $MNT/image/bdwlan_hanoip_ipa.bin /lib/firmware/ath10k/WCN3990/hw1.0/board.bin
echo "firmware links: $($BB ls $FW | $BB wc -l)"

# EFS copies in RAM, named as rmtfs expects in file mode; rmtfs -r never
# writes them back.
$BB mkdir -p /run/efs
for p in modemst1:modem_fs1 modemst2:modem_fs2 fsg:modem_fsg fsc:modem_fsc; do
    n=${p%%:*}; f=${p#*:}
    d=$(part $n) || d=$(part ${n}_a) || fail "$n missing"
    $BB dd if=$d of=/run/efs/$f bs=1048576 2>/dev/null
    echo "efs $f from $n $d $($BB sha256sum /run/efs/$f | $BB cut -c1-16)"
done

W=/lib/hanoip-wifi
for m in rfkill cfg80211 libarc4 mac80211 qcom_glink_smem qcom_pil_info qcom_sysmon \
         qcom_q6v5 qcom_common qcom_q6v5_pas qrtr-smd ipa ath ath10k_core ath10k_snoc; do
    $BB grep -q "^$(echo $m | $BB tr - _) " /proc/modules || $BB insmod $W/$m.ko || echo "insmod $m failed"
done
echo "modules loaded $(up)"

# The stock Motorola modem reads mmi_unit_info (SMEM item 134) and aborts
# ~1.5 s after boot without it. Identifiers come from a runtime file
# (/run/mmi-unit-info.conf, KEY=value lines), never from the image.
if [ -f /run/mmi-unit-info.conf ]; then
    . /run/mmi-unit-info.conf
    $BB insmod $W/hanoip_mmi_unit_info.ko device="${DEVICE:-hanoip}" \
        barcode="$BARCODE" carrier="$CARRIER" radio_str="$RADIO_STR" \
        radio="${RADIO:-0}" system_rev="${SYSTEM_REV:-0}" \
        serial_low="${SERIAL_LOW:-0}" serial_high="${SERIAL_HIGH:-0}" \
        powerup_reason="${POWERUP_REASON:-0}" || echo "mmi_unit_info failed"
else
    echo "WARNING: /run/mmi-unit-info.conf missing; the modem is expected to crash"
fi
# IPA (self-loaded GSI firmware) must be up before the modem starts.
i=0
while ! $BB dmesg | $BB grep -q "IPA driver setup completed" && [ $i -lt 20 ]; do $BB sleep 1; i=$((i+1)); done
$BB dmesg | $BB grep -iE " ipa |ipa:|1e40000" | $BB tail -5

/sbin/pd-mapper > /run/pd-mapper.log 2>&1 &
/sbin/tqftpserv > /run/tqftpserv.log 2>&1 &
/sbin/rmtfs -o /run/efs -r -v > /run/rmtfs.log 2>&1 &
$BB sleep 1

R=''
for r in /sys/class/remoteproc/remoteproc*; do
    case "$($BB readlink -f $r)" in *4080000.remoteproc*) R=$r ;; esac
done
[ -n "$R" ] || fail "mpss remoteproc missing"
# No automatic recovery: a crashing modem stops instead of looping.
echo disabled > $R/recovery
echo "mpss $R firmware=$($BB cat $R/firmware) state=$($BB cat $R/state) recovery=$($BB cat $R/recovery)"
echo start > $R/state
i=0
while [ ! -e /sys/class/net/wlan0 ] && [ $i -lt 60 ] && [ "$($BB cat $R/state)" = running ]; do
    $BB sleep 1; i=$((i+1))
done
echo "mpss state=$($BB cat $R/state) wlan0=$([ -e /sys/class/net/wlan0 ] && echo yes || echo no) after ${i}s at $(up)"
POST=$($BB sha256sum $M | $BB cut -c1-64)
[ "$PRE" = "$POST" ] && echo "modem_a unchanged" || echo "modem_a HASH CHANGED $POST"
