#!/bin/sh
# Reempacota o boot.img com o Image.gz recém-construído, reusando o ramdisk de
# 23 MB da baseline. Uso: ./mkimg.sh [nome-de-saida]
set -eu
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../../.." && pwd)
out=${1:-kernel-hanoip-listener.img}
docker run --rm -v hanoip-kernel73-v3-src:/src -v "$here/listener-boot":/out \
	hanoip-kernel73-v3 bash -c 'gzip -9 -c /src/obj/arch/arm64/boot/Image > /out/Image.gz'
cp "$here/out-mod/qcom_qseecom_fpc.ko" "$here/listener-boot/qcom_qseecom_fpc.ko"
python3 - "$repo" "$out" <<'EOF'
import importlib.util, pathlib, sys
repo = pathlib.Path(sys.argv[1]); out_name = sys.argv[2]
spec = importlib.util.spec_from_file_location('hboot', repo/'scripts/hanoip_boot.py')
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
base = repo/'work/PRE-GOLD-20261029-1534/kernel'
d = repo/'work/fingerprint-20261029/kernel/listener-boot'
rd = d/'ramdisk-real.cpio.gz'
out = d/out_name
out.unlink(missing_ok=True)
m.repack(base/'kernel-hanoip-kali-phosh-v5.img', rd, out,
         kernel=d/'Image.gz', dtb=base/'kernel.dtb')
j = m.inspect(out)
print('img', out.name, j['bytes'], {k: v['size'] for k, v in j['sections'].items()})
EOF
