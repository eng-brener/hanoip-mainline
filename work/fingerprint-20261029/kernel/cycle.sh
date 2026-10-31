#!/bin/sh
# Ciclo completo: scp do módulo, reboot para o bootloader, sobe U-Boot e o
# kernel indicado, espera o SSH e carrega o módulo com o listener.
# Uso: ./cycle.sh IMG [params-do-modulo]
# Os parâmetros vão inteiros para o insmod; nada é fixado aqui. O padrão do
# módulo já é region_phys=0 (notificar 0x86d00000 trava este aparelho).
set -eu
repo=$(cd "$(dirname "$0")/../../.." && pwd)
img=$1
params=${2:-region_phys=0 listener_id=0x2000}
SSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -i $HOME/.ssh/id_ed25519"
SCP="scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $HOME/.ssh/id_ed25519"

# O scp só é possível com o Linux de pé; senão o módulo vai depois do boot.
echo "== scp do módulo"
$SCP "$repo/work/fingerprint-20261029/kernel/listener-boot/qcom_qseecom_fpc.ko" \
	root@172.16.42.1:/root/qcom_qseecom_fpc-listen.ko >/dev/null

echo "== reboot para bootloader"
if ! fastboot devices | grep -q fastboot; then
	$SSH root@172.16.42.1 'sync; reboot bootloader' >/dev/null 2>&1 || true
fi

i=0
while :; do
	i=$((i+1)); [ $i -gt 40 ] && { echo "sem fastboot"; exit 1; }
	if fastboot devices | grep -q fastboot; then break; fi
	sleep 3
done
echo "== bootloader ok; subindo U-Boot"
fastboot boot "$repo/work/PRE-GOLD-20261029-1534/uboot/u-boot-sm7150-motorola-hanoip-cam-tres.img" >/dev/null
sleep 12
i=0
while :; do
	i=$((i+1)); [ $i -gt 20 ] && { echo "U-Boot nao apareceu"; exit 1; }
	if fastboot devices | grep -q '????????????'; then break; fi
	sleep 2
done
echo "== U-Boot ok; subindo kernel"
fastboot boot "$img" >/dev/null

echo "== esperando SSH"
i=0
while :; do
	i=$((i+1)); [ $i -gt 30 ] && { echo "SSH nao subiu"; exit 1; }
	if $SSH root@172.16.42.1 'uname -r' >/dev/null 2>&1; then break; fi
	sleep 5
done

echo "== insmod ($params)"
$SSH root@172.16.42.1 "dmesg | grep -m1 'Linux version'; insmod /root/qcom_qseecom_fpc-listen.ko $params; echo insmod=\$?; sleep 1; dmesg | tail -8"
