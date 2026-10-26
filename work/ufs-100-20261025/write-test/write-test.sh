# UFS write test on the inactive-slot partition logo_b only, with restore.
# Authorized by the user on 2026-10-25. Every other block device stays RO.
P=sdf21; DISK=sdf; ORIG_SHA=bf6fdb9ec8f9bc4282eda697041e7edfdce22c9318414746ba895585d3fb044b
up() { cut -d' ' -f1 /proc/uptime; }
fail() { echo "FAIL: $*"; exit 1; }

[ "$(grep PARTNAME /sys/class/block/$P/uevent)" = PARTNAME=logo_b ] || fail "not logo_b"
[ "$(cat /sys/class/block/$P/size)" = 65536 ] || fail "size"
[ "$(sha256sum /dev/$P | cut -c1-64)" = $ORIG_SHA ] || fail "pre hash differs from backup"
dd if=/dev/$P of=/tmp/logo_b.orig bs=1048576 2>/dev/null
[ "$(sha256sum /tmp/logo_b.orig | cut -c1-64)" = $ORIG_SHA ] || fail "RAM copy"
dd if=/dev/urandom of=/tmp/pattern bs=1048576 count=32 2>/dev/null
PAT_SHA=$(sha256sum /tmp/pattern | cut -c1-64); echo "pattern $PAT_SHA"

GPID=$(cat /run/hanoip-ufs-readonly.pid)
grep -q sh /proc/$GPID/cmdline 2>/dev/null && kill $GPID && echo "guard $GPID stopped"

opened=0
restore() {
    [ $opened = 1 ] || return 0
    echo "RESTORE start $(up)"
    dd if=/tmp/logo_b.orig of=/dev/$P bs=1048576 conv=fsync 2>&1 | tail -1
    blockdev --flushbufs /dev/$P; echo 3 > /proc/sys/vm/drop_caches
    R=$(sha256sum /dev/$P | cut -c1-64)
    [ "$R" = $ORIG_SHA ] && echo "RESTORE_OK $R" || echo "RESTORE_MISMATCH $R"
    blockdev --setro /dev/$P; blockdev --setro /dev/$DISK
    echo "ro after: disk=$(cat /sys/class/block/$DISK/ro) part=$(cat /sys/class/block/$P/ro)"
    opened=0
}
trap restore EXIT

# Partitions only report RO through their disk; pin every other partition of
# the disk read-only by its own flag before the disk itself is made writable.
for b in /sys/class/block/$DISK/$DISK*; do n=${b##*/}; [ $n = $P ] || blockdev --setro /dev/$n; done
blockdev --setrw /dev/$DISK; blockdev --setrw /dev/$P; opened=1
others=0; for b in /sys/class/block/sd*; do n=${b##*/}; [ $n = $P ] || [ $n = $DISK ] || [ "$(cat $b/ro)" = 1 ] || others=$((others+1)); done
echo "writable now: $DISK $P; other non-RO devices: $others"
[ $others = 0 ] || fail "other devices writable"

s=$(date +%s%N)
dd if=/tmp/pattern of=/dev/$P bs=1048576 conv=fsync 2>&1 | tail -1
e=$(date +%s%N); echo "write_ms=$(( (e - s) / 1000000 ))"
blockdev --flushbufs /dev/$P; echo 3 > /proc/sys/vm/drop_caches
s=$(date +%s%N); W=$(sha256sum /dev/$P | cut -c1-64); e=$(date +%s%N)
echo "readback $W read_ms=$(( (e - s) / 1000000 ))"
[ "$W" = "$PAT_SHA" ] && echo WRITE_VERIFY_OK || echo WRITE_VERIFY_MISMATCH

restore
trap - EXIT
rm -f /tmp/pattern /tmp/logo_b.orig
# restart the read-only guard (0.1 s if usleep exists)
( while :; do for d in /dev/sd*; do [ -b "$d" ] || continue; [ "$(blockdev --getro $d)" = 1 ] || blockdev --setro $d; done; usleep 100000 2>/dev/null || sleep 1; done ) > /run/hanoip-ufs-readonly.log 2>&1 &
echo $! > /run/hanoip-ufs-readonly.pid; echo "guard restarted $!"
sleep 1
n=0; rw=0; for b in /sys/class/block/sd*; do n=$((n+1)); [ "$(cat $b/ro)" = 1 ] || rw=$((rw+1)); done
echo "final blocks=$n not_ro=$rw"
dmesg | grep -iE "I/O error|ufshcd.*(timeout|abort|reset)|blk_update" | grep -v "UFS DIAG" | tail -3
echo DONE
