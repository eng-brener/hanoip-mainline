#!/bin/sh
# Monta do zero a digital no Kali do Moto G60 (rodar do Mac, na raiz do repo):
#
#   sh work/fingerprint-20261029/integration/setup-kali-fingerprint.sh [MODULO.ko[.zst]]
#
# Sem argumento usa o módulo da PRE-GOLD-20261030-1430 ou, num clone novo
# (binários não vão para o git), o do build work/kernel-7.3/v7/out.
#
# Pré-requisitos: aparelho bootado com U-Boot cam-tres + kernel v7
# (work/kernel-7.3/v7, ou a PRE-GOLD-20261030), SSH em root@172.16.42.1 e rede
# no aparelho (apt). Idempotente: pode rodar de novo.
#
# Passos:
#   1. módulo qcom_qseecom_fpc em /lib/modules/.../updates + parâmetros
#      (region_phys=0 listener_id=0x2000 rpmb_writes=1) + carga no boot
#   2. pacotes: fprintd, libpam-fprintd (perfil PAM fica desligado) e o
#      necessário para compilar a libfprint
#   3. libfprint v1.94.10 + patch hanoip_fpc, compilada no aparelho e
#      instalada em /opt/hanoip-fprint (a do sistema não muda)
#   4. drop-in do fprintd (env, dispositivos, /var/lib/fpc-gk)
#   5. install-digital.sh: app Digital, guardião, polkit, sudo (desligado)
#
# Não cria a credencial do Gatekeeper: ela nasce no primeiro cadastro, em
# /var/lib/fpc-gk (segredo do aparelho; nunca copiar para fora dele).
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
host=${HANOIP_HOST:-root@172.16.42.1}
ko=${1:-$repo/work/PRE-GOLD-20261030-1430/kernel/qcom_qseecom_fpc.ko}
patch=$here/../libfprint/0001-hanoip_fpc-driver-for-the-Moto-G60-FPC-sensor-via-TEE.patch
opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

if [ ! -f "$ko" ] && [ $# -eq 0 ]; then
	mods=$repo/work/kernel-7.3/v7/out/modules-7.3.0-sm7150.tar.gz
	[ -f "$mods" ] || { echo "sem módulo: rode work/kernel-7.3/v7/build.sh"; exit 1; }
	tar -xzf "$mods" -C "$tmp" \
		7.3.0-sm7150/kernel/drivers/firmware/qcom/qcom_qseecom_fpc.ko.zst
	ko=$tmp/7.3.0-sm7150/kernel/drivers/firmware/qcom/qcom_qseecom_fpc.ko.zst
fi
[ -f "$ko" ] || { echo "módulo não encontrado: $ko"; exit 1; }
case "$ko" in *.zst) ext=ko.zst ;; *) ext=ko ;; esac

echo "== fonte da libfprint (v1.94.10 + hanoip_fpc)"
git clone -q --depth 1 --branch v1.94.10 \
	https://gitlab.freedesktop.org/libfprint/libfprint.git "$tmp/libfprint" 2>/dev/null
git -C "$tmp/libfprint" apply "$patch"
COPYFILE_DISABLE=1 tar -C "$tmp/libfprint" --exclude=.git -czf "$tmp/libfprint.tgz" .

ssh $opts "$host" 'rm -rf /tmp/fp-setup && mkdir /tmp/fp-setup'
scp -q $opts "$ko" "$host:/tmp/fp-setup/qcom_qseecom_fpc.$ext"
scp -q $opts "$tmp/libfprint.tgz" "$host:/tmp/fp-setup/"

ssh $opts "$host" "EXT=$ext sh -s" <<'EOF'
set -e
cd /tmp/fp-setup
grep -q qcom_scm_qseecom_listener_deregister /proc/kallsyms ||
	{ echo "kernel sem o QSEECOM legado: bootar o kernel v7"; exit 1; }

echo "== 1. módulo"
rm -f /lib/modules/$(uname -r)/updates/qcom_qseecom_fpc.ko*
install -D -m0644 qcom_qseecom_fpc.$EXT /lib/modules/$(uname -r)/updates/qcom_qseecom_fpc.$EXT
depmod -a "$(uname -r)"
cat > /etc/modprobe.d/qcom-qseecom-fpc.conf <<'CONF'
# Transporte QSEECOM do leitor FPC (só no kernel v7 = listener7 ou posterior).
# region_phys=0: notificar 0x86d00000 trava o aparelho.
# rpmb_writes=1: autorizado pelo usuário em 2026-10-30 para o Gatekeeper do
# uid 0x4b414c49 (cadastro de digitais); identificar não escreve.
options qcom_qseecom_fpc region_phys=0 listener_id=0x2000 rpmb_writes=1
CONF
echo qcom_qseecom_fpc > /etc/modules-load.d/qcom-qseecom-fpc.conf
modprobe qcom_qseecom_fpc

echo "== 2. pacotes"
[ -d /root/backup-fingerprint-20261030/pam.d ] ||
	{ mkdir -p /root/backup-fingerprint-20261030; cp -a /etc/pam.d /root/backup-fingerprint-20261030/pam.d; }
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -q --no-install-recommends \
	fprintd libpam-fprintd meson ninja-build gcc g++ pkg-config \
	libglib2.0-dev libgusb-dev >/dev/null

echo "== 3. libfprint"
rm -rf /root/build/libfprint && mkdir -p /root/build/libfprint
tar -C /root/build/libfprint -xzf libfprint.tgz 2>/dev/null
cd /root/build/libfprint
meson setup build --prefix=/opt/hanoip-fprint -Ddrivers=hanoip_fpc \
	-Dintrospection=false -Dudev_rules=disabled -Dudev_hwdb=disabled \
	-Dgtk-examples=false -Ddoc=false -Dinstalled-tests=false >/dev/null
ninja -C build >/dev/null
ninja -C build install >/dev/null

echo "== 4. fprintd"
mkdir -p /etc/systemd/system/fprintd.service.d /var/lib/fpc-gk
chmod 0700 /var/lib/fpc-gk
cat > /etc/systemd/system/fprintd.service.d/hanoip-fpc.conf <<'CONF'
# Leitor FPC do Moto G60 via TEE (driver hanoip_fpc na libfprint de
# /opt/hanoip-fprint). Ver work/fingerprint-20261029 no hanoip-mainline.
[Service]
Environment=FP_HANOIP_FPC=/dev/qseecom-fpc
Environment=LD_LIBRARY_PATH=/opt/hanoip-fprint/lib
DeviceAllow=/dev/qseecom-fpc rw
DeviceAllow=char-gpiochip rw
ReadWritePaths=/var/lib/fpc-gk
CONF
systemctl daemon-reload
systemctl try-restart fprintd || true
fprintd-list "$(id -nu 1000 2>/dev/null || echo kali)" | head -2
rm -rf /tmp/fp-setup
EOF

echo "== 5. app, guardião, polkit e sudo"
sh "$here/install-digital.sh"
