#!/bin/sh
# Empacota o boot.img do Kali com o Image.gz/DT deste build (out/), usando o
# ramdisk real do boot.img da PRE-GOLD-20261029-1534 (o mesmo do kernel #29).
# Extrair o ramdisk à mão dá imagem errada (offset 12 é endereço, não
# tamanho); por isso usa scripts/hanoip_boot.py.
#   ./mkimg-kali.sh            -> out/kernel-hanoip-kali-phosh-v7.img
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
python3 -I - "$repo" "$here/out" <<'PY'
import importlib.util, pathlib, sys, tempfile
repo, out = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
spec = importlib.util.spec_from_file_location('hboot', repo/'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
base = repo/'work/PRE-GOLD-20261029-1534/kernel/kernel-hanoip-kali-phosh-v5.img'
if not base.is_file():
    raise SystemExit(
        f"imagem-base ausente: {base}\n"
        "rode antes: sh scripts/fetch-artifacts.sh")
img = out/'kernel-hanoip-kali-phosh-v7.img'
with tempfile.TemporaryDirectory() as t:
    rd = pathlib.Path(t)/'ramdisk.cpio.gz'
    data = base.read_bytes()
    _page, sec = m.read_v2(data)
    off, size = sec['ramdisk']
    rd.write_bytes(data[off:off + size])
    img.unlink(missing_ok=True)
    m.repack(base, rd, img, kernel=out/'Image.gz', dtb=out/'kernel.dtb')
j = m.inspect(img)
print(img.name, j['bytes'], {k: v['size'] for k, v in j['sections'].items()})
PY
