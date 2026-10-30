#!/bin/sh
# Instala no rootfs do Kali (montado em /mnt/kali) o que falta, usando a rede
# do pmOS via chroot. Nada aqui grava fora do sdb24.
set -eu

M=/mnt/kali
mountpoint -q "$M" || { echo "rootfs do Kali nao esta montado"; exit 1; }

for d in proc sys dev; do
    mountpoint -q "$M/$d" || mount --bind "/$d" "$M/$d"
done

# DNS publico so para o apt (o /etc/resolv.conf do Kali e restaurado depois).
cp -a "$M/etc/resolv.conf" /tmp/kali-resolv.bak 2>/dev/null || true
printf 'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' > "$M/etc/resolv.conf"

DEBIAN_FRONTEND=noninteractive chroot "$M" apt-get update
DEBIAN_FRONTEND=noninteractive chroot "$M" apt-get install -y --no-install-recommends \
    iproute2 iputils-ping rmtfs pd-mapper tqftpserv qrtr-tools

cp -a /tmp/kali-resolv.bak "$M/etc/resolv.conf" 2>/dev/null || true

for d in dev sys proc; do
    mountpoint -q "$M/$d" && umount "$M/$d"
done

echo "pacotes instalados:"
chroot "$M" dpkg -l iproute2 rmtfs pd-mapper tqftpserv qrtr-tools 2>/dev/null | grep '^ii' | awk '{print "  " $2, $3}'
