#!/bin/sh
# hanoip performance floors — same values validated on pmOS (2026-10-26):
#  - Adreno 618: simple_ondemand starting at 180 MHz with a 50 ms poll ramped
#    up too late (124 changes in 20 s of scrolling). A 355 MHz floor + 16 ms
#    poll behaves like a fixed 800 MHz without pinning power.
#  - UFS: stayed at 50 MHz ~70% of the time during app launches (~184 ms of
#    I/O stalls). Only two levels exist; keep 200 MHz, the link still
#    hibernates when idle.
#  - CPU: schedutil over the full 300..1804 MHz range, all cores online.
set -eu

log() { printf 'hanoip-perf-tune: %s\n' "$*" > /dev/kmsg 2>/dev/null || true; }

GPU=/sys/class/devfreq/5000000.gpu
UFS=/sys/class/devfreq/1d84000.ufshc

wait_for() {
    i=0
    while [ ! -w "$1" ] && [ "$i" -lt 50 ]; do i=$((i+1)); sleep 0.1; done
    [ -w "$1" ]
}

if wait_for "$GPU/min_freq"; then
    echo 355000000 > "$GPU/min_freq" && log "gpu min=$(cat $GPU/min_freq)"
    echo 16 > "$GPU/polling_interval" && log "gpu poll=$(cat $GPU/polling_interval)"
else
    log "no $GPU"
fi

if wait_for "$UFS/min_freq"; then
    echo 200000000 > "$UFS/min_freq" && log "ufs min=$(cat $UFS/min_freq)"
else
    log "no $UFS"
fi

for p in /sys/devices/system/cpu/cpufreq/policy*; do
    [ -w "$p/scaling_governor" ] || continue
    echo schedutil > "$p/scaling_governor" 2>/dev/null || true
done
log "cpu governors: $(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor 2>/dev/null)"
