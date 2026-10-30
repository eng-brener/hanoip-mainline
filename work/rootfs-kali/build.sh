#!/bin/sh
# Constrói do zero o rootfs Kali NetHunter Pro (Phosh) do hanoip, no Mac
# (OrbStack, container arm64 NATIVO, sem emulação). Nada toca o telefone.
#
#   ./build.sh                  -> out/kali-hanoip-rootfs.img (ext4 10 GiB, label kali)
#
# Entradas (todas versionadas, exceto blobs/ e o kernel, que são gerados):
#   inventario-*/packages.tsv   conjunto exato de pacotes do aparelho (lock)
#   inventario-*/manual.txt     quais foram instalados à mão
#   inventario-*/enabled-units.txt
#   overlay/                    arquivos do projeto (serviços, regras, UCM...)
#   dconf-kali.ini              configurações do usuário kali (texto)
#   keys/                       chaves públicas dos repositórios
#   blobs/hanoip-blobs.tar.zst  firmware do fabricante + /opt/ssc (fora do
#                               git; refazer com collect-from-device.sh;
#                               hashes em blobs.SHA256SUMS)
#   ../kernel-7.3/v7/out/*.deb  kernel (rodar build.sh e mkdeb.sh do v7)
#
# Variáveis:
#   KALI_PASSWORD   senha do usuário kali (padrão 1234, a do projeto)
#   ROOT_PUBKEY     chave pública para SSH root (padrão ~/.ssh/id_ed25519.pub)
#   IMG_SIZE        tamanho do ext4 (padrão 10G, o do aparelho)
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
inv=$(ls -d "$here"/inventario-* | tail -1)
kdeb=$(ls "$repo"/work/kernel-7.3/v7/out/linux-image-7.3.0-sm7150_*_arm64.deb 2>/dev/null | head -1)
pub=${ROOT_PUBKEY:-$HOME/.ssh/id_ed25519.pub}

[ -n "$kdeb" ] || { echo "falta o .deb do kernel: work/kernel-7.3/v7/build.sh && mkdeb.sh"; exit 1; }
[ -f "$here/blobs/hanoip-blobs.tar.zst" ] || { echo "falta blobs/: rode collect-from-device.sh"; exit 1; }
(cd "$here" && shasum -a 256 -c blobs.SHA256SUMS >/dev/null) || { echo "blobs/ não confere com blobs.SHA256SUMS"; exit 1; }
[ -f "$pub" ] || { echo "falta a chave pública $pub (ROOT_PUBKEY=...)"; exit 1; }

mkdir -p "$here/out"
cp "$pub" "$here/out/root.pub"
cp "$kdeb" "$here/out/linux-image.deb"

docker run --rm --platform linux/arm64 --privileged \
	-e KALI_PASSWORD="${KALI_PASSWORD:-1234}" -e IMG_SIZE="${IMG_SIZE:-10G}" \
	-e INV="/r/$(basename "$inv")" \
	-v "$here":/r -v "$repo/work/fingerprint-20261029/libfprint":/fp:ro \
	kalilinux/kali-rolling bash /r/build-inside.sh

(cd "$here/out" && shasum -a 256 kali-hanoip-rootfs.img > kali-hanoip-rootfs.img.sha256)
echo "== verificação contra o inventário"
sh "$here/verify.sh" "$here/out/rootfs-manifest" "$inv"
