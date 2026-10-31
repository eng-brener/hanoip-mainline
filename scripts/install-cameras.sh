#!/bin/sh
# Instala as câmeras no Kali do hanoip (a partir do repo, idempotente).
#
#   sh scripts/install-cameras.sh            # só mostra o plano (dry-run)
#   sh scripts/install-cameras.sh --apply    # escreve no aparelho
#
# O que instala: os 5 módulos da câmera e os 3 tunings.
#   qcom-camss, i2c-qcom-cci, s5k4h7, hanoip-cam, hanoip-vcm
#   /etc/libcamera/ipa/simple/{s5k4h7,s5khm2,ov32b}.yaml
#
# Fonte dos módulos, em ordem: tarball do build v7 (work/kernel-7.3/v7/out)
# ou o snapshot PRE-GOLD-20261029-1534/modules. Os dois têm os mesmos nomes.
# Antes de escrever, faz backup em /root/backup-cameras-<data>/.
#
# Pré-requisitos: aparelho bootado (U-Boot cam-tres + kernel com os patches
# 0190-0194), SSH root@172.16.42.1, e autorização do usuário para a escrita.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
host=${HANOIP_HOST:-root@172.16.42.1}
KREL=${KREL:-7.3.0-sm7150}
apply=0
[ "${1:-}" = "--apply" ] && apply=1

SSH="ssh -o BatchMode=yes -o ConnectTimeout=8 -o HostKeyAlias=10.0.0.44 $host"
MODULES="qcom-camss i2c-qcom-cci s5k4h7 hanoip-cam hanoip-vcm"
PATHS="
drivers/media/platform/qcom/camss/qcom-camss.ko.zst
drivers/i2c/busses/i2c-qcom-cci.ko.zst
drivers/media/i2c/s5k4h7.ko.zst
drivers/media/i2c/hanoip-cam.ko.zst
drivers/media/i2c/hanoip-vcm.ko.zst"
SNAP="$repo/work/PRE-GOLD-20261029-1534"

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
	# Sem build local: usa o tarball do v7, se existir.
	tar=$repo/work/kernel-7.3/v7/out/modules-$KREL.tar.gz
	[ -f "$tar" ] || { echo "sem módulos: rode work/kernel-7.3/v7/build.sh"; exit 1; }
	tmp=$(mktemp -d); tar -C "$tmp" -xzf "$tar"
	src_dir=$tmp/$KREL/kernel
	cleanup() { rm -rf "$tmp"; }
	trap cleanup EXIT
fi
echo "   $src_dir"

echo "== verificando módulos e tunings =="
for p in $PATHS; do
	[ -f "$src_dir/$p" ] || { echo "faltando: $p"; exit 1; }
done
for y in s5k4h7 s5khm2 ov32b; do
	[ -f "$SNAP/tuning/$y.yaml" ] || { echo "faltando tuning $y"; exit 1; }
done
echo "   5 módulos e 3 tunings presentes"

if [ "$apply" -eq 0 ]; then
	cat <<EOF

== PLANO (nada foi escrito) ==
  backup  : $SSH "mkdir -p /root/backup-cameras-\$(date +%Y%m%d-%H%M)"
  módulos : $KREL/{drivers/media/...,drivers/i2c/...} (5 arquivos .ko.zst)
  tunings : /etc/libcamera/ipa/simple/*.yaml (3 arquivos)
  depois  : depmod + modprobe (ou reboot) e conferir com cam -l / libcamera
Para aplicar: sh scripts/install-cameras.sh --apply
EOF
	exit 0
fi

stamp=$(date +%Y%m%d-%H%M)
echo "== backup em /root/backup-cameras-$stamp =="
$SSH "mkdir -p /root/backup-cameras-$stamp/ipa && \
      for f in $PATHS; do b=/lib/modules/$KREL/kernel/\$f; \
        [ -f \$b ] && cp -a \$b /root/backup-cameras-$stamp/ ; done; \
      cp -a /etc/libcamera/ipa/simple/*.yaml /root/backup-cameras-$stamp/ipa/ 2>/dev/null || true"

echo "== instalando módulos =="
for p in $PATHS; do
	$SSH "mkdir -p /lib/modules/$KREL/kernel/$(dirname "$p")"
	cat "$src_dir/$p" | $SSH "cat > /lib/modules/$KREL/kernel/$p.new && mv /lib/modules/$KREL/kernel/$p.new /lib/modules/$KREL/kernel/$p"
done

echo "== instalando tunings =="
$SSH "mkdir -p /etc/libcamera/ipa/simple"
for y in s5k4h7 s5khm2 ov32b; do
	cat "$SNAP/tuning/$y.yaml" | $SSH "cat > /etc/libcamera/ipa/simple/$y.yaml.new && mv /etc/libcamera/ipa/simple/$y.yaml.new /etc/libcamera/ipa/simple/$y.yaml"
done

echo "== depmod =="
$SSH "depmod -a $KREL && echo depmod-ok"

cat <<EOF
== pronto ==
Recarregar: reiniciar o aparelho (volátil) ou, com as câmeras paradas,
  modprobe -r hanoip-cam s5k4h7 hanoip-vcm i2c-qcom-cci qcom-camss && depmod -a
Conferir: cam -l   (ou libcamera-hello --list-cameras)
Backup:  /root/backup-cameras-$stamp
EOF
