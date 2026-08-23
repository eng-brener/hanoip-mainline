#!/bin/bash
set -euo pipefail

ROOT=/home/brener/hanoip-uboot
NAME=hanoip-replica-2026-08-23-v5
DEST=/home/brener
OUT="$DEST/$NAME"
ARCHIVE="$DEST/$NAME.tar.gz"

if [ -e "$OUT" ] || [ -e "$ARCHIVE" ]; then
	printf 'Destino ja existe: %s ou %s\n' "$OUT" "$ARCHIVE" >&2
	exit 1
fi

mkdir -p "$OUT"/patches "$OUT"/sources "$OUT"/untracked/kernel-mainline \
	"$OUT"/config "$OUT"/artifacts "$OUT"/scripts

cp -a "$ROOT/docs" "$OUT/docs"
cp -a "$ROOT/README.md" "$OUT/README.md"
find "$ROOT" -maxdepth 1 -type f -name '*.sh' -exec cp -a {} "$OUT/scripts/" \;
find "$ROOT" -maxdepth 1 -type f -name '*.py' -exec cp -a {} "$OUT/scripts/" \;

for repo in kernel-mainline uboot-sm7150; do
	git -C "$ROOT/$repo" rev-parse HEAD > "$OUT/config/$repo.commit"
	git -C "$ROOT/$repo" rev-parse --abbrev-ref HEAD > "$OUT/config/$repo.branch"
	git -C "$ROOT/$repo" remote get-url origin > "$OUT/config/$repo.origin"
	git -C "$ROOT/$repo" diff --binary HEAD > "$OUT/patches/$repo-working.patch"
	git -C "$ROOT/$repo" archive --format=tar --prefix="$repo/" HEAD | \
		gzip -9 > "$OUT/sources/$repo-base.tar.gz"
done

if [ -f "$ROOT/kernel-mainline/.config" ]; then
	cp -a "$ROOT/kernel-mainline/.config" "$OUT/config/kernel-mainline.config"
fi
if [ -f "$ROOT/uboot-sm7150/.output/.config" ]; then
	cp -a "$ROOT/uboot-sm7150/.output/.config" "$OUT/config/uboot-sm7150.config"
fi

while IFS= read -r -d '' path; do
	dir=$(dirname "$path")
	mkdir -p "$OUT/untracked/kernel-mainline/$dir"
	cp -a "$ROOT/kernel-mainline/$path" "$OUT/untracked/kernel-mainline/$path"
done < <(git -C "$ROOT/kernel-mainline" ls-files -z --others --exclude-standard)

for artifact in \
	work/u-boot-hanoip-boot.img \
	work/kernel-ufs-diag-usb-v5.img \
	work/ramdisk-hanoip-usbserial.cpio.gz; do
	cp -a "$ROOT/$artifact" "$OUT/artifacts/"
done

cat > "$OUT/README-REPLICACAO.md" <<'EOF'
# Replica enxuta do Hanoip

Este pacote contem os fontes-base limpos do kernel e do U-Boot em `sources/`,
alem da documentacao, scripts, configuracoes, commits-base e patches locais
necessarios para reconstruir o estado salvo em 2026-08-23.

## Restauracao

Para restaurar automaticamente uma arvore pronta para build:

```bash
bash restore_replica.sh /home/brener/hanoip-uboot
```

O segundo argumento e opcional; o caminho padrao e `/home/brener/hanoip-uboot`
porque os scripts atuais usam esse caminho absoluto.

O script extrai os dois fontes, aplica os patches, restaura configs, arquivos
novos, docs, scripts e imagens.

Restauracao manual:

1. Extraia `sources/kernel-mainline-base.tar.gz` e
   `sources/uboot-sm7150-base.tar.gz`.
2. Aplique o patch correspondente em `patches/*-working.patch`.
3. Copie o conteudo de `untracked/kernel-mainline/` para a raiz do kernel.
4. Copie os arquivos de `config/` para os locais indicados pelos scripts.
5. Consulte `docs/kernel/` para a sequencia de build e boot.

Como alternativa, clone as URLs em `config/*.origin`, faca checkout dos
commits em `config/*.commit` e aplique os mesmos patches.

O pacote inclui imagens prontas em `artifacts/` para teste sem recompilar.
EOF

cat > "$OUT/restore_replica.sh" <<'EOF'
#!/bin/bash
set -euo pipefail

PKG=$(cd "$(dirname "$0")" && pwd)
DEST=${1:-/home/brener/hanoip-uboot}

if [ -e "$DEST/kernel-mainline" ] || [ -e "$DEST/uboot-sm7150" ]; then
	printf 'Destino ja contem fontes: %s\n' "$DEST" >&2
	exit 1
fi

mkdir -p "$DEST"
tar -xzf "$PKG/sources/kernel-mainline-base.tar.gz" -C "$DEST"
tar -xzf "$PKG/sources/uboot-sm7150-base.tar.gz" -C "$DEST"

(cd "$DEST/kernel-mainline" && git apply "$PKG/patches/kernel-mainline-working.patch")
(cd "$DEST/uboot-sm7150" && git apply "$PKG/patches/uboot-sm7150-working.patch")

cp -a "$PKG/untracked/kernel-mainline/." "$DEST/kernel-mainline/"
cp -a "$PKG/config/kernel-mainline.config" "$DEST/kernel-mainline/.config"
mkdir -p "$DEST/uboot-sm7150/.output"
cp -a "$PKG/config/uboot-sm7150.config" "$DEST/uboot-sm7150/.output/.config"
mkdir -p "$DEST/docs" "$DEST/work"
cp -a "$PKG/docs/." "$DEST/docs/"
cp -a "$PKG/scripts/." "$DEST/"
cp -a "$PKG/README.md" "$DEST/"
cp -a "$PKG/artifacts/." "$DEST/work/"

printf 'Replica restaurada em %s\n' "$DEST"
printf 'Build U-Boot:  cd %s && bash build.sh\n' "$DEST"
printf 'Build kernel:  cd %s && bash kernel_build.sh\n' "$DEST"
EOF
chmod +x "$OUT/restore_replica.sh"

find "$OUT" -type f -printf '%P\n' | sort > "$OUT/MANIFEST.txt"
tar -czf "$ARCHIVE" -C "$DEST" "$NAME"
du -sh "$OUT" "$ARCHIVE"
