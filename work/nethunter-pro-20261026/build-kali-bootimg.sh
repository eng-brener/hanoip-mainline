#!/bin/sh
# build-kali-bootimg.sh — monta o boot.img do Kali a partir de:
#   - Image.gz (kernel)   [$1]
#   - kernel.dtb (DT)     [$2]
#   - initrd (cpio+zstd)  [$3]
# Usa o cabeçalho Android v2 (page 4096) da imagem anterior como molde e
# escreve a cmdline de produção (console=tty0, NUNCA ttyGS0 como último).
# Nada é enviado ao telefone: só gera o arquivo.
#
# Uso:
#   ./build-kali-bootimg.sh Image.gz kernel.dtb initrd.img [-o saida.img]
set -eu

KERNEL=${1:?kernel Image.gz}
DTB=${2:?kernel.dtb}
INITRD=${3:?initrd}
OUT=kernel-hanoip-kali-phosh-v3.img
case "${4:-}" in -o) OUT=${5:?nome de saida} ;; esac

TEMPLATE=work/nethunter-pro-20261026/artifacts/kernel-hanoip-kali-phosh-v2.img
[ -f "$TEMPLATE" ] || { echo "sem molde: $TEMPLATE" >&2; exit 1; }
for f in "$KERNEL" "$DTB" "$INITRD"; do
    [ -f "$f" ] || { echo "faltando: $f" >&2; exit 1; }
done

python3 - "$TEMPLATE" "$KERNEL" "$DTB" "$INITRD" "$OUT" <<'EOF'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location('hboot', 'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)

template, kernel, dtb, initrd, out = map(Path, sys.argv[1:6])
out.unlink(missing_ok=True)
m.repack(template, initrd, out, kernel=kernel, dtb=dtb)

# cmdline de produção: console=tty0 é o ÚLTIMO (PID 1 escreve nele).
# console=ttyGS0 como último trava o systemd em n_tty_write (ver AGENTS.md).
cmd = ("earlycon=msm_geni_serial,0xa88000 console=tty0 loglevel=6 "
       "pstore.backend=ramoops clk_ignore_unused consoleblank=0 "
       "vt.global_cursor_default=0 root=LABEL=kali rw rootwait "
       "mobile.root=/dev/disk/by-partlabel/userdata mobile.qcomsoc=qcom/sm7150 "
       "mobile.vendor=motorola mobile.model=hanoip")
d = bytearray(out.read_bytes())
d[64:64+512] = cmd.encode().ljust(512, b'\0')
out.write_bytes(bytes(d))

info = m.inspect(out)
print(f"gerado: {out}  ({info['bytes']} bytes)")
for name, sec in info['sections'].items():
    print(f"  {name:14} {sec['size']:9} bytes  {sec['sha256'][:16]}")
print(f"  sha256(imagem) {info['sha256']}")
print(f"  cmdline        {d[64:64+512].split(b'\0')[0].decode()}")
EOF
