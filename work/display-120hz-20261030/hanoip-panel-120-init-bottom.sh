#!/bin/sh
# init-bottom depois de udev settle/exit; diagnostico em /run (RAM).
# Bind somente sobre o arquivo do modulo; nao modificar arquivo no rootfs.
set -eu
source_file=/hanoip-experimental/panel-ilitek-ili7807s.ko.zst
target="${rootmnt:?}/usr/lib/modules/7.3.0-sm7150/kernel/drivers/gpu/drm/panel/panel-ilitek-ili7807s.ko.zst"
status=/run/hanoip-panel-120.status
log() {
    printf '%s\n' "$*" >> "$status"
    printf 'hanoip-120: %s\n' "$*" > /dev/kmsg 2>/dev/null || true
}

log 'hook iniciado'

if grep -q '^panel_ilitek_ili7807s ' /proc/modules; then
    log 'modulo ja carregado; mantendo baseline'
    exit 0
fi
if [ ! -f "$source_file" ] || [ ! -f "$target" ]; then
    log 'origem ou alvo ausente; mantendo baseline'
    exit 0
fi
if mount --bind "$source_file" "$target" 2>>"$status"; then
    log 'bind volatil aplicado; verificar apos switch_root'
else
    log 'bind falhou; mantendo baseline'
fi
