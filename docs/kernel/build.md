# Kernel Mainline - Como compilar

## Repo

- Fork: https://github.com/sm7150-mainline/linux (branch `v7.2`)
- Local: `/home/brener/hanoip-uboot/kernel-mainline`

## Pré-requisitos

```bash
apt install -y clang lld llvm gcc-aarch64-linux-gnu bison flex \
  python3-dev libssl-dev make zstd cpio device-tree-compiler
```

> O kernel mainline usa **LLVM/clang** (`LLVM=1`), não gcc puro.

## Passo a passo

### 1. Config (o mais delicado)

O config do postmarketOS SM7150 está em:
```
pmaports2/device/community/linux-postmarketos-qcom-sm7150/config-postmarketos-qcom-sm7150.aarch64
```

```bash
cd /home/brener/hanoip-uboot/kernel-mainline

# Copia o config do pmaports
cp /home/brener/hanoip-uboot/pmaports2/device/community/linux-postmarketos-qcom-sm7150/config-postmarketos-qcom-sm7150.aarch64 .config

# Ajustes do hanoip (DEPOIS de copiar o config)
./scripts/config -e FB_SIMPLE -e TOUCHSCREEN_ILITEK

# olddefconfig (o ARCH_QCOM JÁ deve estar no .config antes disso!)
make LLVM=1 ARCH=arm64 olddefconfig
```

> ⚠️ **PEGADINHA**: se o `.config` não tiver `CONFIG_ARCH_QCOM=y` antes do
> `olddefconfig`, ele remove tudo do QCOM (GENI serial, pinctrl, etc).
> Sempre verificar: `grep ARCH_QCOM .config` → deve ser `y`.

### 2. Compilar

```bash
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1
make -j$(nproc)
```

Resultado:
- `arch/arm64/boot/Image` (~31MB)
- `arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb` (~89KB)

### 3. Recompilar só o DTB (rápido)

```bash
make LLVM=1 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- dtbs
```

### 4. Empacotar boot.img (com a CORREÇÃO do DTB)

O mkbootimg (Ubuntu e osm0sis) tem um bug: grava `page_size` errado no
header v2, então o U-Boot não extrai o DTB ("Invalid FDT header").

Use o script `pack_kernel_osm.sh` para gerar o boot.img e depois
**`fix_dtb2.py`** para corrigir o header:

```bash
# 1. Gera o boot.img (kernel gzip + dtb, header v2)
bash /home/brener/hanoip-uboot/pack_kernel_osm.sh

# 2. Corrige page_size + dtb_size no header
cd /home/brener/hanoip-uboot
python3 fix_dtb2.py
# → gera work/kernel-mainline-hanoip-fixed2.img (o que deve ser bootado)
```

> O `fix_dtb2.py` corrige:
> - `page_size` → 4096 (o mkbootimg grava 256 por bug)
> - `dtb_size` → tamanho real do DTB (o mkbootimg deixa 0)
> - `dtb_addr` → 0x1f00000

## Verificar o boot.img

```bash
python3 - <<'PYEOF'
import struct
d = open('work/kernel-mainline-hanoip-fixed2.img','rb').read()
print('page_size:', struct.unpack('<I', d[32:36])[0])       # deve ser 4096
print('header_version:', struct.unpack('<I', d[40:44])[0])  # deve ser 2
print('dtb_size:', struct.unpack('<I', d[1636:1640])[0])    # deve ser ~89562
idx = d.find(b'\xd0\x0d\xfe\xed')                          # DTB magic
print('DTB magic em:', hex(idx))
PYEOF
```

O dtb_ptr calculado pelo U-Boot deve bater com a posição do DTB:
`check_dtb.py` verifica isso.

## DTS do kernel

- `arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts`
- Adicionado ao Makefile (já está): `sm7150-motorola-hanoip.dtb`
- Baseado no `sm7150-google-sunfish.dts` (mesmo SoC/PMIC/UFS)
- Difere do sunfish: memory fixada, touch Ilitek SPI6, panel Tianma,
  reserved-memory do hanoip

## Dicas

- Compilar o kernel inteiro leva ~5-10 min
- Para testar rápido: mudar o DTS e só `make dtbs` + `pack_kernel_osm.sh` + `fix_dtb2.py`
