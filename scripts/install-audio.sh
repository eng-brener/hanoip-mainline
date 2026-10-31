#!/bin/sh
# Instala o áudio no Kali do hanoip (a partir do repo, idempotente).
#
#   sh scripts/install-audio.sh            # só mostra o plano (dry-run)
#   sh scripts/install-audio.sh --apply    # escreve no aparelho
#
# O que instala:
#   módulos  snd-soc-wcd937x-sdw e soundwire-qcom (patches 0188 e 0189)
#   UCM2     árvore do hanoip em /usr/share/alsa/ucm2
# Depois recompila o cache do ALSA e reinicia o PipeWire/WirePlumber.
#
# Origem dos módulos: build v7 (work/kernel-7.3/v7/out) ou o snapshot
# PRE-GOLD-20261028-1707/modules. UCM: work/audio-20261028/ucm2.
# Backup em /root/backup-audio-<data>/ antes de escrever.
#
# Pré-requisitos: aparelho bootado com kernel que tenha 0188/0189, SSH
# root@172.16.42.1 e autorização do usuário para a escrita no rootfs.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
host=${HANOIP_HOST:-root@172.16.42.1}
KREL=${KREL:-7.3.0-sm7150}
apply=0
[ "${1:-}" = "--apply" ] && apply=1

SSH="ssh -o BatchMode=yes -o ConnectTimeout=8 -o HostKeyAlias=10.0.0.44 $host"
UCM_SRC="$repo/work/audio-20261028/ucm2"
SNAP="$repo/work/PRE-GOLD-20261028-1707"
PATHS="
sound/soc/codecs/snd-soc-wcd937x-sdw.ko.zst
drivers/soundwire/soundwire-qcom.ko.zst"

echo "== conferindo o aparelho =="
if [ "${HANOIP_SKIP_SSH:-0}" = 1 ]; then
	echo "   (HANOIP_SKIP_SSH=1: sem falar com o aparelho; só checagem local)"
else
	$SSH "uname -r; ls /lib/modules/$KREL >/dev/null && echo raiz-ok" || {
		echo "sem SSH ou kernel inesperado; abortando"; exit 1; }
fi

echo "== origem dos módulos =="
src_dir=""
for cand in "$repo/work/kernel-7.3/v7/out/modules-$KREL/kernel" \
            "$SNAP/modules/kernel"; do
	if [ -d "$cand" ]; then src_dir=$cand; break; fi
done
if [ -z "$src_dir" ]; then
	tar=$repo/work/kernel-7.3/v7/out/modules-$KREL.tar.gz
	[ -f "$tar" ] || { echo "sem módulos: rode work/kernel-7.3/v7/build.sh"; exit 1; }
	tmp=$(mktemp -d); tar -C "$tmp" -xzf "$tar"
	src_dir=$tmp/$KREL/kernel
	cleanup() { rm -rf "$tmp"; }
	trap cleanup EXIT
fi
echo "   $src_dir"

[ -d "$UCM_SRC" ] || { echo "faltando $UCM_SRC"; exit 1; }
for p in $PATHS; do
	[ -f "$src_dir/$p" ] || { echo "faltando módulo: $p"; exit 1; }
done
echo "   2 módulos e a árvore UCM presentes"

if [ "$apply" -eq 0 ]; then
	cat <<EOF

== PLANO (nada foi escrito) ==
  backup : /root/backup-audio-<data>/
  módulos: $KREL/sound/soc/codecs/... e $KREL/drivers/soundwire/...
  UCM    : /usr/share/alsa/ucm2/{Motorola/hanoip,conf.d/sm8250}/...
  depois : alsactl init; systemctl restart wireplumber pipewire
Para aplicar: sh scripts/install-audio.sh --apply
EOF
	exit 0
fi

stamp=$(date +%Y%m%d-%H%M)
echo "== backup em /root/backup-audio-$stamp =="
$SSH "mkdir -p /root/backup-audio-$stamp && \
      for f in $PATHS; do b=/lib/modules/$KREL/kernel/\$f; \
        [ -f \$b ] && cp -a \$b /root/backup-audio-$stamp/ ; done; \
      cp -a /usr/share/alsa/ucm2/Motorola/hanoip /root/backup-audio-$stamp/ 2>/dev/null || true; \
      cp -a '/usr/share/alsa/ucm2/conf.d/sm8250/Motorola Moto G60.conf' /root/backup-audio-$stamp/ 2>/dev/null || true"

echo "== instalando módulos =="
for p in $PATHS; do
	$SSH "mkdir -p /lib/modules/$KREL/kernel/$(dirname "$p")"
	cat "$src_dir/$p" | $SSH "cat > /lib/modules/$KREL/kernel/$p.new && mv /lib/modules/$KREL/kernel/$p.new /lib/modules/$KREL/kernel/$p"
done

echo "== instalando UCM2 =="
$SSH "mkdir -p /usr/share/alsa/ucm2/Motorola/hanoip /usr/share/alsa/ucm2/conf.d/sm8250"
tar -C "$UCM_SRC" -cf - . | $SSH "tar -C /usr/share/alsa/ucm2 -xf -"

echo "== depmod e recarga =="
$SSH "depmod -a $KREL && (alsactl init 2>/dev/null || true) && \
      systemctl restart wireplumber 2>/dev/null || systemctl restart pipewire 2>/dev/null || true; \
      echo recarga-ok"

cat <<EOF
== pronto ==
Conferir: aplay -l | grep -i wcd ; pactl list short sinks
Se o som não voltar: reiniciar o aparelho (volátil).
Backup: /root/backup-audio-$stamp
EOF
