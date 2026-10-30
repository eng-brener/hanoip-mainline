#!/bin/sh
# snapshot-kali.sh — roda no pmOS: monta o rootfs do Kali (sdb24) SOMENTE
# LEITURA e escreve um tar.zst na saída padrão. Nada é escrito no aparelho.
set -eu

D=/dev/sdb24
MNT=/mnt/kali-ro

grep -q '^PARTNAME=userdata$' /sys/class/block/sdb24/uevent || { echo "ABORT: partlabel" >&2; exit 1; }
[ "$(cat /sys/class/block/sdb23/ro)" = 1 ] || { echo "ABORT: super gravavel" >&2; exit 1; }

mountpoint -q "$MNT" || {
    mkdir -p "$MNT"
    blockdev --setro "$D"
    mount -t ext4 -o ro,noload,nodev,nosuid,noexec "$D" "$MNT"
}

echo "montado RO; iniciando tar" >&2
nice -n 19 tar -C "$MNT" -c --numeric-owner \
    --exclude=./proc --exclude=./sys --exclude=./dev --exclude=./run \
    --exclude=./tmp --exclude=./mnt/ro --exclude='./var/log/journal/*' \
    --exclude='./var/cache/apt/archives/*' . 2>/dev/null \
  | nice -n 19 zstd -1 -T2 -q -c

echo "tar concluido" >&2
