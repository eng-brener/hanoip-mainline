#!/bin/sh
# write-userdata.sh — grava a imagem do Kali em /dev/sdb24 (userdata).
# Checklist de seguranca antes de qualquer escrita. Le a imagem da stdin.
#
# Detalhe importante do kernel: uma particao so pode ficar gravavel se o
# DISCO estiver gravavel (BLKROGET/BLKROSET por dispositivo). Entao o disco
# sdb e aberto por um instante e TODAS as outras particoes dele voltam a RO
# antes de qualquer byte ser escrito.
set -eu

D=$(readlink -f /dev/disk/by-partlabel/userdata)
NAME=${D##*/}

[ "$NAME" = "sdb24" ] || { echo "ABORT: alvo e ${NAME}, esperava sdb24"; exit 1; }
grep -q '^PARTNAME=userdata$' /sys/class/block/sdb24/uevent || {
    echo "ABORT: partlabel do sdb24 nao e userdata"; exit 1; }
SIZE=$(cat /sys/class/block/sdb24/size)
[ "$SIZE" -gt 200000000 ] || { echo "ABORT: tamanho inesperado ($SIZE setores)"; exit 1; }
if mount | grep -q "/dev/sdb24"; then echo "ABORT: sdb24 montado"; exit 1; fi
SUPER=$(readlink -f /dev/disk/by-partlabel/super)
[ "$SUPER" != "$D" ] || { echo "ABORT: alvo e o super"; exit 1; }

echo "CONFIRMADO: $D = userdata ($((SIZE/2/1024/1024/1024)) GiB); super/root = $SUPER"

# 1) abrir o disco, 2) fechar de novo todas as particoes menos o userdata.
blockdev --setrw /dev/sdb
for p in /sys/class/block/sdb[0-9]*; do
    n=${p##*/}
    [ "$n" = "sdb24" ] && continue
    blockdev --setro "/dev/$n" 2>/dev/null || true
done
blockdev --setrw /dev/sdb24

# 3) conferir antes de escrever
[ "$(cat /sys/class/block/sdb24/ro)" = 0 ] || { echo "ABORT: sdb24 continua RO"; exit 1; }
[ "$(cat /sys/class/block/sdb23/ro)" = 1 ] || { echo "ABORT: sdb23 (super) ficou gravavel!"; exit 1; }
bad=""
for p in /sys/class/block/sdb[0-9]*; do
    n=${p##*/}
    [ "$n" = "sdb24" ] && continue
    [ "$(cat "$p/ro")" = 1 ] || bad="$bad $n"
done
[ -z "$bad" ] || { echo "ABORT: particoes gravaveis:$bad"; exit 1; }
echo "checagem ok: so sdb24 gravavel; sdb23 e as demais RO"

echo "gravando; isso pode levar alguns minutos..."
dd of=/dev/sdb24 bs=4M conv=fsync status=none || { echo "ABORT: dd falhou"; exit 1; }
sync
echo "escrita concluida"
