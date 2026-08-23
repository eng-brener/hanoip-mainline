# U-Boot - Como compilar

## Pré-requisitos (WSL Ubuntu)

```bash
apt install -y gcc-aarch64-linux-gnu clang lld llvm bison flex swig \
  python3-dev libssl-dev make zstd cpio libgnutls28-dev device-tree-compiler \
  mkbootimg busybox-static
```

## Build reproduzível (recomendado)

O script `build.sh` na raiz do projeto faz tudo:

```bash
cd /home/brener/hanoip-uboot
bash build.sh          # build normal
bash build.sh limpo    # build do zero (apaga .output)
```

O `build.sh`:
1. `make qcom_defconfig qcom-phone.config tauchgang.config`
2. Aplica configs do hanoip (DEVICE_TREE, OF_EMBED, VID/PID, multi-LUN, etc.)
3. Compila com `make -j$(nproc)`
4. Gera `work/u-boot-hanoip-boot.img` (header v3)

## Build manual passo a passo

```bash
cd /home/brener/hanoip-uboot/uboot-sm7150

# 1. Config base (os 3 configs do fork)
make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig qcom-phone.config tauchgang.config

# 2. Ajustes do hanoip
./scripts/config --file .output/.config --set-str DEFAULT_DEVICE_TREE qcom/sm7150-motorola-hanoip
./scripts/config --file .output/.config \
  -e OF_EMBED -d OF_SEPARATE \
  -e BOOTMETH_ANDROID -e CMD_ABOOTIMG \
  -e BLKMAP -e CMD_BLKMAP \
  -d EFI_VARIABLE_FILE_STORE -e EFI_VARIABLE_NO_STORE \
  --set-str USB_GADGET_MANUFACTURER "Motorola" \
  --set-val USB_GADGET_VENDOR_NUM 0x18D1 \
  --set-val USB_GADGET_PRODUCT_NUM 0x4EE0 \
  --set-val FASTBOOT_FLASH_MMC_DEV 1

# 3. Re-aplica o config (importante! senão perde ARCH_QCOM etc)
make CROSS_COMPILE=aarch64-linux-gnu- O=.output olddefconfig

# 4. Build
make CROSS_COMPILE=aarch64-linux-gnu- O=.output -j$(nproc)
```

## Empacotar boot.img

O `pack_embed.sh` faz o boot.img (header v3) usando o **mkbootimg do sistema**:

```bash
bash /home/brener/hanoip-uboot/pack_embed.sh
```

> IMPORTANTE: usar `u-boot.bin` (com DTB embutido via OF_EMBED), NÃO
> `u-boot-nodtb.bin` + dtb appended. O OF_EMBED deixa o DTB dentro do binário.

## Build do mkbootimg do osm0sis (se precisar)

```bash
cd /home/brener/hanoip-uboot/uboot-sm7150/mkbootimg
CFLAGS=-Wstringop-overflow=0 make mkbootimg
```

> NOTA: o mkbootimg do osm0sis grava `page_size=256` por bug (ignora
> `--pagesize 4096` para header v2). Para o kernel mainline, ver
> `docs/kernel/build.md` (precisa da correção manual).

## Dicas

- Build limpo do zero: `rm -rf uboot-sm7150/.output && bash build.sh`
- O DTS do hanoip está em:
  `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`
- Depois de mudar o DTS, forçar recompilação:
  `rm -f uboot-sm7150/.output/dts/upstream/src/arm64/qcom/.sm7150-motorola-hanoip.dtb*`
