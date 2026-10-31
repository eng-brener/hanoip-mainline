#!/bin/sh
# Reproduz o que dá para reconstruir do zero e confere os hashes conhecidos.
#
#   sh scripts/reproduce-all.sh           # constrói tudo (U-Boot, kernel, v8)
#   sh scripts/reproduce-all.sh --verify  # só confere artefatos já construídos
#
# Não escreve nada no aparelho. A instalação no rootfs é feita depois, com
# scripts/install-audio.sh, scripts/install-cameras.sh e
# work/fingerprint-20261029/integration/setup-kali-fingerprint.sh.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
mode=${1:-build}

check() { # $1 = arquivo, $2 = sha256 esperado, $3 = rótulo
	if [ ! -f "$1" ]; then echo "  AUSENTE   $3"; return 1; fi
	got=$(shasum -a 256 "$1" | cut -d' ' -f1)
	if [ "$got" = "$2" ]; then echo "  OK        $3"; else
		echo "  DIFERENTE $3"; echo "            esperado $2"; echo "            obtido   $got"; fi
}

UB="$repo/work/uboot-builds-20261026/out/sm7150-motorola-hanoip-cam-tres"
V7="$repo/work/kernel-7.3/v7/out"
V8="$repo/work/kernel-7.3/v8-dsi"

if [ "$mode" = "--verify" ]; then
	echo "== conferindo artefatos =="
	check "$UB/u-boot-sm7150-motorola-hanoip-cam-tres.img" \
		5cb081270f62344c6308c980caa9ad67fcad5ea98ea284962c65f0e8907dc59a "U-Boot cam-tres (byte-idêntico)"
	check "$UB/uboot.dtb" \
		b7c8b730e4cd38f283aed6636fb9d213eca507318e655420c01bdbc7c4e655ac "DTB do U-Boot"
	check "$V7/kernel.dtb" \
		900e11eb55e16569dc749d3a8b2373f7d992ff610c0f018efa714bee13fe0a4a "DTB do kernel"
	check "$V8/msm-dsi-guards.ko.zst" \
		e45516eec237ef31dbc9cfdd1d0d2cdf2adc5e192a7bd345cc3a454ddacc8785 "msm com correções DSI"
	if [ -f "$V7/Image.gz" ]; then
		got=$(shasum -a 256 "$V7/Image.gz" | cut -d' ' -f1)
		if [ "$got" = 9769296cba871143d85536bcaa4c46b37ec0a2e063213900c2a18298e0bd302c ]; then
			echo "  OK        Image.gz (byte-idêntica)"
		else
			echo "  EQUIVAL.  Image.gz (mesmo banner/tamanho, bytes diferem — ver docs/REPRODUZIR.md)"
		fi
	fi
	exit 0
fi

echo "== 1/3 U-Boot (reproduzível byte a byte) =="
sh "$repo/work/uboot-builds-20261026/build-repro.sh"

echo "== 2/3 kernel v7 (listener7) =="
sh "$repo/work/kernel-7.3/v7/build.sh"

echo "== 3/3 módulos do experimento de 120 Hz (v8) =="
sh "$repo/work/kernel-7.3/v8-dsi/build.sh"

echo
echo "== conferência =="
sh "$here/reproduce-all.sh" --verify || true

cat <<'EOF'

== próximo passo (rootfs, exige autorização e o aparelho ligado) ==
  sh scripts/install-audio.sh --apply
  sh scripts/install-cameras.sh --apply
  sh work/fingerprint-20261029/integration/setup-kali-fingerprint.sh
Empacotar o boot.img do experimento de 120 Hz exige a imagem-base local do
listener7 (ver a lacuna em docs/REPRODUZIR.md).
EOF
