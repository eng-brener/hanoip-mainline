#!/bin/sh
# hanoip-firmware (systemd): mount the vendor firmware partitions read-only
# and link the files where the kernel looks for them. Replaces droid-juicer
# for this port: nothing is copied, nothing is written, the partitions stay
# mounted ro,noload,nodev,nosuid,noexec.
set -eu

KMSG=/dev/kmsg
log() { printf 'hanoip-firmware: %s\n' "$*" > "$KMSG" 2>/dev/null || echo "$*"; }

mount_ro() {
    label=$1
    target=$2
    dev=$(readlink -f "/dev/disk/by-partlabel/$label" 2>/dev/null || true)
    [ -n "$dev" ] && [ -e "$dev" ] || { log "no partition $label"; return 0; }
    mkdir -p "$target"
    if mountpoint -q "$target"; then return 0; fi
    blockdev --setro "$dev" 2>/dev/null || true
    mount -t ext4 -o ro,noload,nodev,nosuid,noexec "$dev" "$target" || {
        log "cannot mount $label"; return 0; }
    log "$label mounted read-only at $target"
}

link_dir() {
    src=$1 dst=$2
    [ -d "$src" ] || return 0
    mkdir -p "$dst"
    for f in "$src"/*; do
        [ -e "$f" ] && ln -sfn "$f" "$dst/${f##*/}"
    done
}

mount_ro modem_a /mnt/ro/modem_a
mount_ro bluetooth_a /mnt/ro/bluetooth_a

# Qualcomm firmware for ADSP/CDSP/GPU/Wi-Fi/BT lives inside modem_a.
link_dir /mnt/ro/modem_a/image /lib/firmware/qcom/sm7150/motorola/hanoip
link_dir /mnt/ro/bluetooth_a/image /lib/firmware/qca

board=/mnt/ro/modem_a/image/bdwlan_hanoip_ipa.bin
if [ -e "$board" ]; then
    mkdir -p /lib/firmware/ath10k/WCN3990/hw1.0
    ln -sfn "$board" /lib/firmware/ath10k/WCN3990/hw1.0/board.bin
fi

# GPU zap shader used by the Adreno driver.
for n in a630_zap.mdt a630_zap.b00 a630_zap.b01 a630_zap.b02; do
    [ -e "/mnt/ro/modem_a/image/$n" ] && \
        ln -sfn "/mnt/ro/modem_a/image/$n" "/lib/firmware/qcom/$n"
done

log "done"
