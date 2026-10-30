#!/bin/sh
set -eu

log() { printf 'hanoip-ssc: %s\n' "$*" > /dev/kmsg 2>/dev/null || true; }

[ -d /opt/ssc/usr/share/qcom/sensors ] || { log "no /opt/ssc bundle"; exit 1; }

modprobe fastrpc 2>/dev/null || true
[ -e /sys/module/fastrpc ] || { log "fastrpc module missing"; exit 1; }

for d in dev proc sys; do
    mkdir -p "/opt/ssc/$d"
    mountpoint -q "/opt/ssc/$d" || mount --bind "/$d" "/opt/ssc/$d" || exit 1
done

# ADSP: no automatic recovery loops (a crashing DSP would spin).
for p in /sys/class/remoteproc/remoteproc*; do
    case "$(readlink -f "$p")" in
        *62400000.remoteproc*)
            echo disabled > "$p/recovery" 2>/dev/null || true
            if [ "$(cat "$p/state")" = "offline" ]; then
                echo start > "$p/state" || true
            fi
            ;;
    esac
done

# A previous run may still have a hexagonrpcd alive (manual restart): kill it,
# otherwise the new instance fails to open /dev/fastrpc-adsp.
if [ -s /run/hanoip-hexagonrpcd.pid ]; then
    old=$(cat /run/hanoip-hexagonrpcd.pid)
    if kill -0 "$old" 2>/dev/null; then
        case "$(cat "/proc/$old/comm" 2>/dev/null || echo)" in
            hexagonrpcd*) log "killing previous hexagonrpcd ($old)"; kill "$old" 2>/dev/null || true; sleep 2 ;;
        esac
    fi
fi

i=0
while [ ! -e /dev/fastrpc-adsp ] && [ "$i" -lt 30 ]; do i=$((i+1)); sleep 1; done
[ -e /dev/fastrpc-adsp ] || { log "/dev/fastrpc-adsp never appeared"; exit 1; }

# On a cold boot the ADSP services are still coming up, so hexagonrpcd can die
# within its first seconds. Retry a few times instead of failing the unit and
# leaving the sensors dead until someone notices (bug seen on 2026-10-27).
try=1
max=6
while [ "$try" -le "$max" ]; do
    # Wait for the ADSP remoteproc to report running before each attempt.
    j=0
    while [ "$j" -lt 20 ]; do
        st=""
        for p in /sys/class/remoteproc/remoteproc*; do
            case "$(readlink -f "$p")" in
                *62400000.remoteproc*) st=$(cat "$p/state" 2>/dev/null || echo "") ;;
            esac
        done
        if [ "$st" = "running" ]; then break; fi
        j=$((j+1)); sleep 1
    done

    [ -e /dev/fastrpc-adsp ] || { log "/dev/fastrpc-adsp vanished (try $try)"; sleep 2; try=$((try+1)); continue; }

    chroot /opt/ssc /usr/bin/hexagonrpcd -d adsp -f /dev/fastrpc-adsp \
        -R /usr/share/qcom -s > /run/hanoip-hexagonrpcd.log 2>&1 &
    pid=$!
    echo "$pid" > /run/hanoip-hexagonrpcd.pid

    sleep 5
    if kill -0 "$pid" 2>/dev/null; then
        break
    fi

    log "hexagonrpcd died on try $try/$max (adsp state ${st:-?})"
    tail -5 /run/hanoip-hexagonrpcd.log > /dev/kmsg 2>/dev/null || true
    if [ "$try" -lt "$max" ]; then sleep 4; fi
    try=$((try+1))
done

if [ "$try" -gt "$max" ]; then
    log "hexagonrpcd failed after $max attempts"
    exit 1
fi

udevadm trigger --action=change --subsystem-match=misc 2>/dev/null || true

# The proxy grabs the sensor list once at start; if it came up before the DSP
# services were published it stays empty. Restart it now that we are ready.
sleep 2
systemctl restart --no-block iio-sensor-proxy.service 2>/dev/null || true
log "hexagonrpcd up (pid $(cat /run/hanoip-hexagonrpcd.pid), try $try)"
