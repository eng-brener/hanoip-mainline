# Write the pmOS rootfs into the unallocated tail of super (sdb23).
# Authorized by the user on 2026-10-25 (see AGENTS.md). Runs on the phone
# from the RAM-only telemetry initramfs:
#   sh write-super-tail.sh test   # 64 MiB pattern at the region start, verify, re-zero
#   sh write-super-tail.sh full   # /tmp/pmos-super-rootfs.img.gz -> region, verify
# Only a loop device starting at OFFSET is ever opened for writing; every
# other block device stays RO by its own flag. LP metadata (head 8 MiB) and
# the _a extents (first 5154 MiB) are hashed before and after.
BB=/bin/busybox
PART=sdb23; DISK=sdb; SIZE=21102592
OFFSET=5410652160                       # 5160 MiB
IMG_MIB=5120
HEAD_SHA=1240833a0a6c72af389c83b8538bc5cac2c066afd65edf5ecdf51ea394fa3886
USED_SHA=ac4806cf5872a6a1bfc3c89c06c239b63560b531c0ecf380eeee6dd64606879b
IMG_SHA=d5fc913aa753e15b98a6b88a05da1a2da6f3b994a1c58d5d4af88f7dede13093
LOOP=/dev/loop7
GUARD=/run/hanoip-ufs-readonly.pid
mode=${1:-}
up() { "$BB" cut -d' ' -f1 /proc/uptime; }
sha() { "$BB" sha256sum | "$BB" cut -c1-64; }
fail() { echo "FAIL: $*"; exit 1; }

case "$mode" in test|full) ;; *) fail "usage: test|full" ;; esac
[ "$("$BB" grep PARTNAME /sys/class/block/$PART/uevent)" = PARTNAME=super ] || fail "not super"
[ "$("$BB" cat /sys/class/block/$PART/size)" = $SIZE ] || fail "size"
[ $mode = test ] || [ -f /tmp/pmos-super-rootfs.img.gz ] || fail "missing image in /tmp"

check_a() {
    h=$("$BB" dd if=/dev/$PART bs=1048576 count=8 2>/dev/null | sha)
    u=$("$BB" dd if=/dev/$PART bs=1048576 count=5154 2>/dev/null | sha)
    echo "$1 head8M=$h used5154M=$u"
    [ "$h" = $HEAD_SHA ] && [ "$u" = $USED_SHA ] || { echo "$1 A_REGION_MISMATCH"; return 1; }
    echo "$1 A_REGION_OK"
}
check_a pre || fail "baseline differs, not writing"

guard() {
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

opened=0
close() {
    [ $opened = 1 ] || return 0
    "$BB" sync
    "$BB" losetup -d $LOOP
    "$BB" blockdev --setro /dev/$PART; "$BB" blockdev --setro /dev/$DISK
    guard ''
    echo "closed: disk ro=$("$BB" cat /sys/class/block/$DISK/ro) part ro=$("$BB" cat /sys/class/block/$PART/ro)"
    opened=0
}
trap close EXIT

guard "$DISK $PART"
for b in /sys/class/block/$DISK/$DISK*; do n=${b##*/}; [ $n = $PART ] || "$BB" blockdev --setro /dev/$n; done
"$BB" blockdev --setrw /dev/$DISK; "$BB" blockdev --setrw /dev/$PART; opened=1
others=0
for b in /sys/class/block/sd*; do
    n=${b##*/}; [ $n = $PART ] || [ $n = $DISK ] || [ "$("$BB" cat $b/ro)" = 1 ] || others=$((others+1))
done
echo "writable: $DISK $PART; others not RO: $others"
[ $others = 0 ] || fail "other devices writable"
"$BB" losetup -o $OFFSET $LOOP /dev/$PART || fail losetup
"$BB" losetup -a

if [ $mode = test ]; then
    "$BB" dd if=/dev/urandom of=/tmp/pattern bs=1048576 count=64 2>/dev/null
    P=$(sha < /tmp/pattern); echo "pattern $P"
    "$BB" dd if=/tmp/pattern of=$LOOP bs=1048576 conv=fsync 2>&1 | "$BB" tail -1
    "$BB" blockdev --flushbufs $LOOP; echo 3 > /proc/sys/vm/drop_caches
    R=$("$BB" dd if=$LOOP bs=1048576 count=64 2>/dev/null | sha)
    [ "$R" = "$P" ] && echo WRITE_VERIFY_OK || echo "WRITE_VERIFY_MISMATCH $R"
    "$BB" dd if=/dev/zero of=$LOOP bs=1048576 count=64 conv=fsync 2>&1 | "$BB" tail -1
    rm -f /tmp/pattern
else
    s=$(up)
    "$BB" gunzip -c /tmp/pmos-super-rootfs.img.gz | "$BB" dd of=$LOOP bs=1048576 conv=fsync 2>&1 | "$BB" tail -1
    echo "write $(up) (start $s)"
    "$BB" blockdev --flushbufs $LOOP; echo 3 > /proc/sys/vm/drop_caches
    R=$("$BB" dd if=$LOOP bs=1048576 count=$IMG_MIB 2>/dev/null | sha)
    [ "$R" = $IMG_SHA ] && echo IMAGE_VERIFY_OK || echo "IMAGE_VERIFY_MISMATCH $R"
fi

close
trap - EXIT
echo 3 > /proc/sys/vm/drop_caches
check_a post
n=0; rw=0; for b in /sys/class/block/sd*; do n=$((n+1)); [ "$("$BB" cat $b/ro)" = 1 ] || rw=$((rw+1)); done
echo "final blocks=$n not_ro=$rw"
"$BB" dmesg | "$BB" grep -iE "I/O error|ufshcd.*(timeout|abort|reset)|blk_update|read-only block" | "$BB" tail -3
echo "DONE $mode $(up)"
