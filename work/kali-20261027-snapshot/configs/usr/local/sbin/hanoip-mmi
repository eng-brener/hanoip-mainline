#!/bin/sh
# hanoip-mmi: load hanoip_mmi_unit_info with the identity that the ABL passed
# to U-Boot (embedded in /chosen). The stock Motorola modem reads SMEM item
# 134 (mmi_unit_info) and aborts ~1.5 s after starting without it, which is
# what made the WCN3990 WLAN firmware crash.
# Identifiers are passed to the kernel only; nothing is logged or stored.
set -eu

log() { printf 'hanoip-mmi: %s\n' "$*" > /dev/kmsg 2>/dev/null || true; }
C=/proc/device-tree/chosen
W=/lib/modules/$(uname -r)/extra
MOD=$W/hanoip_mmi_unit_info.ko

[ -f "$MOD" ] || { log "module not found at $MOD"; exit 1; }
if [ -d /sys/module/hanoip_mmi_unit_info ]; then
    log "already loaded"
    exit 0
fi

abl_arg() {
    [ -f "$C/u-boot,abl-bootargs" ] || return 1
    tr ' ' '\n' < "$C/u-boot,abl-bootargs" | sed -n "s/^$1=//p" | head -1
}
dt_u32() {
    [ -f "$C/$1" ] || return 1
    printf '0x%s' "$(od -An -tx1 "$C/$1" | tr -d ' \n')"
}

BARCODE=$(abl_arg androidboot.serialno || true)
CARRIER=$(abl_arg androidboot.carrier || true)
RADIO_STR=$(abl_arg androidboot.radio || true)
DEVICE=$(abl_arg androidboot.device || true)
SYSTEM_REV=$(dt_u32 linux,hwrev || true)
SERIAL_LOW=$(dt_u32 linux,seriallow || true)
SERIAL_HIGH=$(dt_u32 linux,serialhigh || true)
POWERUP_REASON=$(dt_u32 mmi,powerup_reason || true)

if [ -z "${BARCODE}${SYSTEM_REV}" ]; then
    log "no ABL identity in /chosen; the modem will probably crash"
    exit 1
fi

insmod "$MOD" \
    device="${DEVICE:-hanoip}" \
    barcode="${BARCODE}" \
    carrier="${CARRIER}" \
    radio_str="${RADIO_STR}" \
    radio="${RADIO:-0}" \
    system_rev="${SYSTEM_REV:-0}" \
    serial_low="${SERIAL_LOW:-0}" \
    serial_high="${SERIAL_HIGH:-0}" \
    powerup_reason="${POWERUP_REASON:-0}" || { log "insmod failed"; exit 1; }

log "loaded (device=${DEVICE:-?} carrier set: $([ -n "$CARRIER" ] && echo yes || echo no))"
