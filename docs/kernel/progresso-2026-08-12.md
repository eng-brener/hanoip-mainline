# Kernel Mainline - PROGRESSO (2026-08-12)

## ✅ MARCO: Kernel mainline roda estável no Moto G60

O kernel Linux mainline (fork sm7150-mainline/linux v7.2) agora **boota e roda
de forma estável** no Moto G60 (hanoip).

## O que foi conquistado nesta rodada

1. **Kernel compila** — `Image` (31.9MB) + DTB do hanoip
2. **U-Boot passa o DTB corretamente** — fix do `boot_with_embedded_fdt`
   (o U-Boot usa o DTB embutido em vez do DTB do boot.img Android, que o
   mkbootimg grava com dtb_size=0)
3. **Kernel assume o display** — simple-framebuffer ativo (tela cinza)
4. **Watchdog desabilitado** — antes o kernel reiniciava após ~1 min
   (watchdog do boot não alimentado). Com `CONFIG_WATCHDOG=n`, o kernel
   roda estável.
5. **USB serial console** habilitado no config (ttyGS0)

## A solução chave: DTB embutido do U-Boot

O problema original era "FDT and ATAGS support not compiled in" — o bootm
Android não extraía o DTB do boot.img (o mkbootimg grava `dtb_size=0`).

**Fix aplicado** em `boot/image-fdt.c`:
- Se a env `boot_with_embedded_fdt` estiver setada, o boot_get_fdt usa o
  `gd->fdt_blob` (DTB embutido do U-Boot) em vez do DTB do boot.img Android.

**Fix em `drivers/fastboot/fb_common.c`**:
- O `fastboot_boot` seta `boot_with_embedded_fdt=1` e `set_abootimg_addr`
  antes de chamar o bootm.

## Por que reiniciava (watchdog)

O device tem o watchdog do boot ativo (configurado pelo ABL/U-Boot em
0x17c10000). O kernel mainline bind o driver `qcom-wdt`, mas sem um daemon
que alimente o watchdog, ele reinicia após o timeout (~1 min).

**Fix**: `CONFIG_WATCHDOG=n` no config do kernel.

## O que ainda falta

1. **Ver logs/shell no display** — o fbcon não mostra texto ainda
2. **Interagir com o kernel** — USB ADB/serial do kernel
3. **Driver de painel** (Tianma ILI7807S) para display DRM completo
4. **Rootfs real** (o initramfs busybox atual é mínimo)

## Arquivos-chave

- `kernel-mainline/arch/arm64/boot/Image` — kernel (31.9MB)
- `kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dtb`
- `work/kernel-mainline-hanoip-initrd-fixed.img` — boot.img do kernel
- U-Boot com fix: `uboot-sm7150` (boot/image-fdt.c, drivers/fastboot/fb_common.c)

## Como testar

1. Ligar → U-Boot → menu → "Enable fastboot mode"
2. `fastboot boot work/kernel-mainline-hanoip-initrd-fixed.img`
3. Tela cinza = kernel rodando (estável, sem reiniciar)

## Config do kernel (chaves)

```ini
CONFIG_ARCH_QCOM=y
CONFIG_SERIAL_QCOM_GENI=y
CONFIG_SERIAL_QCOM_GENI_CONSOLE=y
CONFIG_FB_SIMPLE=y
CONFIG_SYSFB_SIMPLEFB=y
CONFIG_FRAMEBUFFER_CONSOLE=y
CONFIG_TOUCHSCREEN_ILITEK=y
# CONFIG_WATCHDOG is not set   # <-- CRÍTICO (senão reinicia)
CONFIG_USB_GADGET=y
CONFIG_USB_CONFIGFS=y
CONFIG_USB_CONFIGFS_SERIAL=y
CONFIG_U_SERIAL_CONSOLE=y
```

## Bootargs atuais

```
earlycon=msm_geni_serial,0xa88000 console=ttyMSM0,115200n8 console=ttyGS0 console=tty1 loglevel=8 ignore_loglevel
```
