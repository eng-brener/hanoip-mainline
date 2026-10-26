#!/bin/sh
# Mount the pmOS rootfs that lives in the unallocated tail of super (sdb23)
# at /newroot, for the initramfs to switch_root into. Authorized 2026-10-25:
# only the region after the last LP extent may be written. LP metadata and
# the _a volumes are verified, never written; every other block device stays
# read-only by its own flag. On any failure everything is undone.
#   pmos-root [--ro]
BB=/bin/busybox
PART=sdb23; DISK=sdb
SIZE=21102592                      # super, 512-byte sectors
OFFSET=5410652160                  # 5160 MiB; last LP extent ends 5153.88 MiB
HEAD_SHA=1240833a0a6c72af389c83b8538bc5cac2c066afd65edf5ecdf51ea394fa3886
LOOP=/dev/loop7
NEWROOT=/newroot
GUARD=/run/hanoip-ufs-readonly.pid
LOG=/run/hanoip-pmos-root.log
exec >> "$LOG" 2>&1
up() { "$BB" cut -d' ' -f1 /proc/uptime; }
echo "pmos-root start $(up)"

mode=rw
[ "${1:-}" = --ro ] && mode=ro

guard() {
    # $1: names to leave alone (empty restores the full guard).
    [ -f "$GUARD" ] && "$BB" kill "$("$BB" cat "$GUARD")" 2>/dev/null
    (
        while :; do
            for d in /dev/sd*; do
                [ -b "$d" ] || continue
                case " $1 " in *" ${d##*/} "*) continue ;; esac
                "$BB" blockdev --setro "$d"
            done
            "$BB" usleep 100000
        done
    ) > /run/hanoip-ufs-readonly.log 2>&1 &
    echo "$!" > "$GUARD"
}

undo() {
    echo "pmos-root FAILED: $*"
    "$BB" umount "$NEWROOT" 2>/dev/null
    "$BB" losetup -d "$LOOP" 2>/dev/null
    "$BB" blockdev --setro "/dev/$PART"
    "$BB" blockdev --setro "/dev/$DISK"
    guard ''
    exit 1
}

[ -e /run/hanoip-ufs-started ] || /sbin/load-ufs || undo "UFS load"
i=0
while [ ! -b "/dev/$PART" ] && [ $i -lt 50 ]; do "$BB" usleep 100000; i=$((i+1)); done
[ "$("$BB" grep PARTNAME "/sys/class/block/$PART/uevent")" = PARTNAME=super ] ||
    undo "$PART is not super"
[ "$("$BB" cat "/sys/class/block/$PART/size")" = $SIZE ] || undo "super size"
h=$("$BB" dd if="/dev/$PART" bs=1048576 count=8 2>/dev/null | "$BB" sha256sum | "$BB" cut -c1-64)
[ "$h" = $HEAD_SHA ] || undo "LP metadata hash changed: $h"

if [ $mode = rw ]; then
    # A partition reports read-only through its disk; pin every other sdb
    # partition by its own flag before the disk itself is made writable.
    guard "$DISK $PART"
    for b in /sys/class/block/$DISK/$DISK*; do
        n=${b##*/}; [ $n = $PART ] || "$BB" blockdev --setro "/dev/$n"
    done
    "$BB" blockdev --setrw "/dev/$DISK"
    "$BB" blockdev --setrw "/dev/$PART"
    others=''
    for b in /sys/class/block/sd*; do
        n=${b##*/}
        [ $n = $PART ] || [ $n = $DISK ] || [ "$("$BB" cat "$b/ro")" = 1 ] || others="$others $n"
    done
    [ -z "$others" ] || undo "other devices writable:$others"
    "$BB" losetup -o $OFFSET "$LOOP" "/dev/$PART" || undo "losetup"
else
    "$BB" losetup -r -o $OFFSET "$LOOP" "/dev/$PART" || undo "losetup"
fi

# ext4 superblock at +1024: magic 0xef53 at +56, label at +120.
sb=$("$BB" dd if="$LOOP" bs=1024 skip=1 count=1 2>/dev/null | "$BB" od -An -tx1 -j56 -N2 | "$BB" tr -d ' \n')
label=$("$BB" dd if="$LOOP" bs=1024 skip=1 count=1 2>/dev/null | "$BB" dd bs=1 skip=120 count=11 2>/dev/null)
[ "$sb" = 53ef ] && [ "$label" = hanoip_pmos ] || undo "no hanoip_pmos ext4 at offset ($sb/$label)"

"$BB" mkdir -p "$NEWROOT"
"$BB" mount -t ext4 -o $mode,noatime "$LOOP" "$NEWROOT" || undo "mount"
[ -x "$NEWROOT/sbin/init" ] || undo "no /sbin/init"

# Read-only firmware mounts (modem_a, bluetooth_a) follow into the new root.
"$BB" grep ' /mnt/ro/' /proc/mounts | while read -r _ target _; do
    "$BB" mkdir -p "$NEWROOT$target"
    "$BB" mount --move "$target" "$NEWROOT$target"
done
for m in dev proc sys run; do
    "$BB" mkdir -p "$NEWROOT/$m"
    "$BB" mount --move "/$m" "$NEWROOT/$m" || undo "move /$m"
done
echo "pmos-root ready $mode $(up)"
