#!/bin/sh
# Make the Adreno Zap firmware available from modem_a before the DRM probe.
# modem_a remains kernel read-only and is mounted ro,noload with safe flags.
set -e
BB=/bin/busybox
MNT=/mnt/ro/modem_a
FW=/lib/firmware/qcom/sm7150/motorola/hanoip
LOG=/run/hanoip-gpu-firmware.log
fail() { echo "HANOIP GPU firmware: $*" >&2; exit 1; }
part() {
    for b in /sys/class/block/sd*; do
        [ -f "$b/uevent" ] || continue
        [ "$("$BB" grep '^PARTNAME=' "$b/uevent" 2>/dev/null)" = "PARTNAME=$1" ] && {
            echo "/dev/${b##*/}"; return 0;
        }
    done
    return 1
}

exec >"$LOG" 2>&1
echo "start uptime=$("$BB" cut -d' ' -f1 /proc/uptime)"
[ -b "$(part modem_a 2>/dev/null)" ] || /sbin/load-ufs || fail "UFS unavailable"
for b in /sys/class/block/sd*; do
    [ -e "$b/ro" ] || continue
    [ "$("$BB" cat "$b/ro")" = 1 ] || fail "${b##*/} is not read-only"
done
M=$(part modem_a) || fail "modem_a missing"
PRE=$("$BB" sha256sum "$M" | "$BB" cut -d' ' -f1)
echo "modem_a=$M ro=$("$BB" cat /sys/class/block/${M##*/}/ro) pre=$PRE"
"$BB" mkdir -p "$MNT" "$FW"
if ! "$BB" grep -q " $MNT " /proc/mounts; then
    "$BB" mount -t ext4 -o ro,noload,nodev,nosuid,noexec "$M" "$MNT" || fail "mount modem_a"
else
    mounted=$("$BB" awk -v m="$MNT" '$2 == m {print $1}' /proc/mounts)
    opts=$("$BB" awk -v m="$MNT" '$2 == m {print $4}' /proc/mounts)
    [ "$mounted" = "$M" ] || fail "unexpected source already mounted at $MNT"
    case ",$opts," in *,ro,*) ;; *) fail "existing mount is not read-only" ;; esac
    case ",$opts," in *,norecovery,*|*,noload,*) ;; *) fail "existing mount lacks noload" ;; esac
fi
for suffix in mdt b00 b01 b02; do
    [ -f "$MNT/image/a615_zap.$suffix" ] || fail "missing a615_zap.$suffix"
    "$BB" ln -sf "$MNT/image/a615_zap.$suffix" "$FW/a615_zap.$suffix"
done
echo "Zap firmware links ready: $FW/a615_zap.mdt and segments"
POST=$("$BB" sha256sum "$M" | "$BB" cut -d' ' -f1)
[ "$PRE" = "$POST" ] || fail "modem_a hash changed: $POST"
echo "modem_a unchanged post=$POST"
