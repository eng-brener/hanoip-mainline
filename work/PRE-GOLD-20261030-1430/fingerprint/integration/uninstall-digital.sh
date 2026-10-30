#!/bin/sh
# Desfaz o install-digital.sh: para o guardião, remove app/ajudante/polkit e
# devolve o /etc/pam.d/sudo do backup. As digitais cadastradas e o fprintd
# continuam (apague com fprintd-delete ou pelo app antes, se quiser).
set -eu
host=${HANOIP_HOST:-root@172.16.42.1}
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR "$host" 'sh -s' <<'EOF'
set -e
systemctl disable --now hanoip-fp-guard 2>/dev/null || true
rm -f /etc/systemd/system/hanoip-fp-guard.service \
	/usr/local/libexec/hanoip-fp-guard /usr/local/libexec/hanoip-fp-admin \
	/usr/local/bin/hanoip-digital \
	/usr/local/share/applications/org.hanoip.Digital.desktop \
	/usr/share/polkit-1/actions/org.hanoip.fingerprint.policy \
	/etc/polkit-1/rules.d/50-hanoip-fprint.rules
rm -rf /etc/hanoip-fp /run/hanoip-fp
cp -a /root/backup-fingerprint-20261030/pam.d/sudo /etc/pam.d/sudo
systemctl daemon-reload
echo "removido; /etc/pam.d/sudo restaurado do backup"
EOF
