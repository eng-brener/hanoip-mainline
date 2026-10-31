#!/bin/sh
# Obtém as imagens-base de boot e confere os hashes.
#
#   sh scripts/fetch-artifacts.sh                 # baixa do release no GitHub
#   sh scripts/fetch-artifacts.sh --from DIR      # copia de um diretório local
#   sh scripts/fetch-artifacts.sh --force         # rebaixa e reescreve
#   BASE_URL=https://... sh scripts/fetch-artifacts.sh   # outra origem
#
# As imagens-base não estão no git (tamanho + ramdisk do vendor). Este script
# é o ponto único para obtê-las quando existir uma origem publicada (release
# assets ou cópia local). Nada é baixado sem conferir o SHA256 de
# artifacts/base-images.sha256.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/.." && pwd)
manifest="$repo/artifacts/base-images.sha256"
DEFAULT_URL=https://github.com/eng-brener/hanoip-mainline/releases/download/artefatos-base-20261031
BASE_URL=${BASE_URL:-$DEFAULT_URL}
force=0
from=""
while [ $# -gt 0 ]; do
	case "$1" in
		--force) force=1 ;;
		--from) shift; from=${1:?--from precisa de um diretório} ;;
		*) echo "argumento desconhecido: $1"; exit 2 ;;
	esac
	shift
done
[ -n "$from" ] || from=${HANOIP_ARTIFACTS_DIR:-}

[ -f "$manifest" ] || { echo "faltando $manifest"; exit 1; }

fetch_one() { # $1 caminho relativo, $2 sha256
	dest="$repo/$1"
	if [ -f "$dest" ]; then
		got=$(shasum -a 256 "$dest" | cut -d' ' -f1)
		if [ "$got" = "$2" ]; then echo "  já presente  $(basename "$1")"; return 0; fi
		if [ "$force" -eq 0 ]; then
			echo "  DIFERENTE    $(basename "$1") — use --force para rebaixar"
			return 1
		fi
		rm -f "$dest"
	fi
	name=$(basename "$1")
	mkdir -p "$(dirname "$dest")"
	if [ -n "$from" ]; then
		[ -f "$from/$name" ] || { echo "  ausente em $from: $name"; return 1; }
		cp -p "$from/$name" "$dest"
	elif [ -n "${BASE_URL:-}" ]; then
		curl -fsSL --retry 3 -o "$dest.part" "$BASE_URL/$name" || {
			rm -f "$dest.part"; echo "  falha ao baixar $name"; return 1; }
		mv "$dest.part" "$dest"
	else
		echo "  sem origem para $name (use --from DIR ou BASE_URL=...)"
		return 1
	fi
	got=$(shasum -a 256 "$dest" | cut -d' ' -f1)
	if [ "$got" != "$2" ]; then
		echo "  SHA256 não confere em $name"; echo "    esperado $2"; echo "    obtido   $got"
		rm -f "$dest"; return 1
	fi
	echo "  baixado/copiado e verificado: $name"
}

fail=0
while read -r sha path; do
	[ -n "${sha:-}" ] || continue
	fetch_one "$path" "$sha" || fail=1
done < "$manifest"

if [ "$fail" -ne 0 ]; then
	cat <<'EOF'

Algumas imagens-base não estão disponíveis. Ver docs/INVENTARIO-REPRODUZIVEL.md
(LACUNA 1): elas precisam de uma origem publicada (release assets) ou de uma
cópia local do aparelho/backup. Sem elas, só o pacote final de boot fica de
fora; fontes, U-Boot, módulos, DTB e scripts continuam reproduzíveis.
EOF
	exit 1
fi
echo "todas as imagens-base presentes e verificadas"
