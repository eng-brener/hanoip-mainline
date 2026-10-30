#!/bin/sh
# patch-kali.sh — pequenos ajustes no rootfs do Kali que está no userdata,
# feito a partir do pmOS. Monta sdb24 rw, mexe e desmonta.
set -eu

D=/dev/sdb24
MNT=/mnt/kali

grep -q '^PARTNAME=userdata$' /sys/class/block/sdb24/uevent || { echo ABORT: partlabel; exit 1; }
mount | grep -q "$D" && { echo "ja montado"; } || {
    blockdev --setrw /dev/sdb
    for p in /sys/class/block/sdb[0-9]*; do
        n=${p##*/}; [ "$n" = sdb24 ] && continue
        blockdev --setro "/dev/$n" 2>/dev/null || true
    done
    blockdev --setrw "$D"
    [ "$(cat /sys/class/block/sdb23/ro)" = 1 ] || { echo ABORT: super gravavel; exit 1; }
    mkdir -p "$MNT"
    mount -t ext4 "$D" "$MNT"
    echo "montado $D em $MNT"
}

echo "conteudo: $(ls "$MNT" | wc -l) entradas"
[ -f "$MNT/etc/os-release" ] && grep -E '^(NAME|PRETTY_NAME)=' "$MNT/etc/os-release"
