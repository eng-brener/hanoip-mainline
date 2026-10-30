#!/bin/sh
# Instala no Kali do Moto G60 o app "Digital", o guardião do desbloqueio
# pela digital e o sudo pela digital (este último DESLIGADO; liga pelo app).
#
# Rodar do Mac, na raiz do hanoip-mainline:
#   sh work/fingerprint-20261029/integration/install-digital.sh
# Desfazer: uninstall-digital.sh (mesma pasta).
#
# O que muda no aparelho:
#   /usr/local/libexec/hanoip-fp-guard   serviço + porteiro (política Android)
#   /usr/local/libexec/hanoip-fp-admin   liga/desliga (via pkexec, pede senha)
#   /usr/local/bin/hanoip-digital        app; atalho em /usr/local/share/applications
#   /usr/share/polkit-1/actions/org.hanoip.fingerprint.policy
#   /etc/polkit-1/rules.d/50-hanoip-fprint.rules  cadastrar/excluir pede senha
#   /etc/systemd/system/hanoip-fp-guard.service   (habilitado)
#   /etc/hanoip-fp/unlock-enabled        desbloqueio da tela LIGADO
#   /etc/pam.d/sudo                      +2 linhas, inertes sem
#                                        /etc/hanoip-fp/sudo-enabled
set -eu
here=$(cd "$(dirname "$0")" && pwd)
host=${HANOIP_HOST:-root@172.16.42.1}
ssh_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"

ssh $ssh_opts "$host" 'rm -rf /tmp/fp-int && mkdir /tmp/fp-int'
scp -q $ssh_opts "$here/hanoip-fp-guard" "$here/hanoip-fp-guard.service" \
	"$here/hanoip-fp-admin" "$here/hanoip-digital" \
	"$here/org.hanoip.Digital.desktop" "$here/org.hanoip.fingerprint.policy" \
	"$here/50-hanoip-fprint.rules" "$host:/tmp/fp-int/"

ssh $ssh_opts "$host" 'sh -s' <<'EOF'
set -e
cd /tmp/fp-int
[ -d /root/backup-fingerprint-20261030/pam.d ] ||
	{ mkdir -p /root/backup-fingerprint-20261030; cp -a /etc/pam.d /root/backup-fingerprint-20261030/pam.d; }
install -D -m0755 hanoip-fp-guard /usr/local/libexec/hanoip-fp-guard
install -D -m0755 hanoip-fp-admin /usr/local/libexec/hanoip-fp-admin
install -D -m0755 hanoip-digital /usr/local/bin/hanoip-digital
install -D -m0644 org.hanoip.Digital.desktop /usr/local/share/applications/org.hanoip.Digital.desktop
install -D -m0644 org.hanoip.fingerprint.policy /usr/share/polkit-1/actions/org.hanoip.fingerprint.policy
install -D -m0644 50-hanoip-fprint.rules /etc/polkit-1/rules.d/50-hanoip-fprint.rules
install -m0644 hanoip-fp-guard.service /etc/systemd/system/hanoip-fp-guard.service
/usr/local/libexec/hanoip-fp-admin unlock on
/usr/local/libexec/hanoip-fp-admin sudo off
if ! grep -q pam_fprintd /etc/pam.d/sudo; then
	awk '/^@include common-auth/ && !d {
		print "# digital (hanoip): vale só com /etc/hanoip-fp/sudo-enabled e com a política liberando"
		print "auth       [success=ignore default=1] pam_exec.so quiet /usr/local/libexec/hanoip-fp-guard allowed"
		print "auth       sufficient                 pam_fprintd.so max-tries=3 timeout=15"
		d = 1 } { print }' /etc/pam.d/sudo > /etc/pam.d/sudo.new
	chmod 0644 /etc/pam.d/sudo.new
	mv /etc/pam.d/sudo.new /etc/pam.d/sudo
fi
systemctl stop hanoip-fp-guard-test 2>/dev/null || true
systemctl daemon-reload
systemctl enable --now hanoip-fp-guard
sleep 3
echo "guardião: $(systemctl is-active hanoip-fp-guard)"
/usr/local/libexec/hanoip-fp-guard allowed && echo "sudo pela digital: LIGADO" || echo "sudo pela digital: desligado"
cat /run/hanoip-fp/status.json; echo
rm -rf /tmp/fp-int
EOF
echo "Instalado. Abra o app \"Digital\" no menu do Phosh."
