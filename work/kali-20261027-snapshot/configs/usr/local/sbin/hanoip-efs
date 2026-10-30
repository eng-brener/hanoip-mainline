#!/bin/sh
# hanoip-efs: make the modem EFS available to rmtfs from RAM.
# The partitions are only READ; rmtfs runs with -r so it never writes back.
set -eu

log() { printf 'hanoip-efs: %s\n' "$*" > /dev/kmsg 2>/dev/null || true; }

mkdir -p /run/efs

part() {
    for b in /sys/class/block/sd*; do
        [ -e "$b/uevent" ] || continue
        case "$(cat "$b/uevent")" in
            *"PARTNAME=$1"*) echo "/dev/${b##*/}"; return 0 ;;
        esac
    done
    return 1
}

for p in modemst1:modem_fs1 modemst2:modem_fs2 fsg:modem_fsg fsc:modem_fsc; do
    name=${p%%:*}
    file=${p#*:}
    dev=$(part "$name" || part "${name}_a") || { log "$name missing"; continue; }
    dd if="$dev" of="/run/efs/$file" bs=1M 2>/dev/null || log "read $name failed"
    log "$file <- $dev"
done

chmod 600 /run/efs/* 2>/dev/null || true
log "done"
