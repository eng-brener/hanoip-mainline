#!/bin/sh
# instalar-fase0.sh — instala a Fase 0 (modos USB) SEM trocar o modo atual.
# Rodar como root NO APARELHO, com os arquivos copiados para /tmp/fase0/.
# Nao desativa o hanoip-usbnet: a virada e' um passo separado e testado.
set -eu
S=$(cd "$(dirname "$0")" && pwd)
echo "== instalando arquivos"
install -D -m 0755 "$S/hanoip-usb-mode"        /usr/local/sbin/hanoip-usb-mode
install -D -m 0755 "$S/hanoip-usb-fix"         /usr/local/sbin/hanoip-usb-fix
install -D -m 0755 "$S/hanoip-usb-app.py"      /usr/local/bin/hanoip-usb-app
install -D -m 0644 "$S/hanoip-usb-app.desktop" /usr/share/applications/hanoip-usb.desktop
install -D -m 0644 "$S/hanoip-usb-mode.service" /etc/systemd/system/hanoip-usb-mode.service
install -D -m 0644 "$S/org.hanoip.usbmode.policy" \
    /usr/share/polkit-1/actions/org.hanoip.usbmode.policy
if [ ! -f /etc/hanoip/usb-mode.conf ]; then
    install -D -m 0644 "$S/usb-mode.conf" /etc/hanoip/usb-mode.conf
else
    echo "  /etc/hanoip/usb-mode.conf ja existe (mantido)"
fi
echo "== validando"
sh -n /usr/local/sbin/hanoip-usb-mode && echo "  sh -n OK"
python3 -m py_compile /usr/local/bin/hanoip-usb-app 2>/dev/null && echo "  python OK" || echo "  AVISO: py_compile falhou"
systemctl daemon-reload
echo "== estado (NADA foi ativado ainda)"
echo "  hanoip-usbnet     : $(systemctl is-enabled hanoip-usbnet 2>/dev/null) / $(systemctl is-active hanoip-usbnet 2>/dev/null)"
echo "  hanoip-usb-mode   : $(systemctl is-enabled hanoip-usb-mode 2>/dev/null) / $(systemctl is-active hanoip-usb-mode 2>/dev/null)"
echo
echo "Para ver o estado:  hanoip-usb-mode status"
echo "Para testar:        hanoip-usb-mode net     (derruba o USB por 1-3 s)"
echo "Para virar de vez:  systemctl disable --now hanoip-usbnet && systemctl enable hanoip-usb-mode"
