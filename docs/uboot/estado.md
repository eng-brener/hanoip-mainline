# U-Boot - Estado Atual (atualizado 2026-08-13)

## Resumo: ✅ FUNCIONAL (com watchdog fix)

O U-Boot é o **bootloader persistente do device** (flashado no slot A). Boota
sozinho ao ligar, tem fastboot, UFS multi-LUN, display e bootmenu.

## NOVIDADE 2026-08-13: watchdog do boot parado antes do kernel

O U-Boot inicia o WDT (`watchdog@17c10000`, `CONFIG_WATCHDOG_AUTOSTART=y`,
30s timeout) e o alimenta via cyclic. Ao entregar o controle ao kernel, o
kernel não o alimentava → **reset a cada ~30s** (causa raiz dos reboots).

**Fix aplicado**: `wdt_stop_all()` antes do handoff ao kernel.
- `arch/arm/mach-snapdragon/board.c`: hook `board_preboot_os()`
- `drivers/fastboot/fb_common.c`: `wdt_stop_all()` direto no `fastboot_boot()`

**IMPORTANTE — DTB embutido do U-Boot é o que o kernel usa:**
Com `boot_with_embedded_fdt=1`, o kernel usa o **DTB embutido do U-Boot**
(OF_EMBED), não o DTB do boot.img do kernel. Por isso bootargs/nodes
adicionados ao DTS do kernel NÃO valem via `fastboot boot`. Editar:
`uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`

Bootargs atuais (U-Boot DTS):
```
earlycon=msm_geni_serial,0xa88000 console=ttyMSM0,115200n8 console=ttyGS0
console=tty1 console=ramoops loglevel=8 ignore_loglevel
panic_on_oops=1 panic=5 pstore.backend=ramoops
```

## Estado detalhado

| Funcionalidade | Status | Notas |
|----------------|--------|-------|
| Boot persistente (slot A) | ✅ | U-Boot boota sozinho ao ligar |
| Fastboot | ✅ | `product: motorola-hanoip`, version 0.4 |
| Flash UFS multi-LUN | ✅ | `boot_a`, `vendor_boot_a`, `dtbo_a`, `persist` OK |
| Display + logo | ✅ | simple-framebuffer no cont_splash |
| Bootmenu | ✅ | navegação por botões de volume |
| `oem run:<cmd>` | ✅ | executa comando U-Boot via fastboot (usar `:` não espaço) |
| `oem console` | ✅ | lê o console record |
| `wdt` cmd | ✅ | `wdt list/start/stop/reset` (CONFIG_CMD_WDT) |
| Watchdog stop pre-kernel | ✅ | `wdt_stop_all()` em board_preboot_os + fastboot_boot |
| Bootstd | ✅ | escaneia devices UFS (`bootflow scan`) |
| Console limpo | ✅ | sem avisos UFS/GENI/dwc3 |

## Commits do port (fork `uboot-sm7150`, branch `tauchgang`)

```
bc21cf70709 qcom: boot kernel with the U-Boot embedded FDT via fastboot
3cb83dd1ce2 usb: dwc3: gadget: silence "request was not queued" spam
dabdfebf482 dts: hanoip: silence boot warnings (UFS reset/ref_clk, GENI)
0693b36c3d2 fastboot: support UFS multi-LUN storage (Qualcomm SM7150)
2cd7455485f dts: qcom: sm7150: add Motorola Moto G60 (hanoip) support
```

### Mudanças locais NÃO commitadas (2026-08-13)

- `arch/arm/mach-snapdragon/board.c`: +`board_preboot_os()` (wdt_stop_all)
- `drivers/fastboot/fb_common.c`: +`wdt_stop_all()` antes do do_bootm
- `dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`: bootargs com
  ramoops/panic_on_oops + panel `tianma,ili7807s-hanoip` com vddi/avdd/avee

## Configurações atuais (no `.output/.config`)

```ini
CONFIG_DEFAULT_DEVICE_TREE="qcom/sm7150-motorola-hanoip"
CONFIG_OF_EMBED=y            # DTB embutido no binário (CRÍTICO)
CONFIG_WATCHDOG=y            # AUTOSTART do WDT do boot
CONFIG_WATCHDOG_TIMEOUT_MSECS=30000
CONFIG_CMD_WDT=y
CONFIG_FASTBOOT_FLASH_MMC_DEV=1  # device SCSI para flash (multi-LUN)
CONFIG_USB_GADGET_VENDOR_NUM=0x18D1  # Google VID
CONFIG_USB_GADGET_PRODUCT_NUM=0x4EE0 # fastboot PID
CONFIG_BOOTMETH_ANDROID=y
CONFIG_CMD_ABOOTIMG=y
CONFIG_BLKMAP=y CONFIG_CMD_BLKMAP=y
CONFIG_EFI_VARIABLE_NO_STORE=y   # evita erro EFI vars
CONFIG_SERIAL_QCOM_GENI=y (via qcom_defconfig)
```

## Como o boot funciona

1. ABL (bootloader Motorola stock) carrega o U-Boot do `boot_a` (slot A)
2. U-Boot usa o DTB embutido (OF_EMBED) — sempre válido
3. Bootcmd = `bootflow scan -lb; pause; run menucmd`
4. Como não há OS no slot A, cai no bootmenu
5. No menu, "Enable fastboot mode" ativa o fastboot
6. `fastboot boot` → `wdt_stop_all()` → `do_bootm` → kernel (com DTB embutido)

## Comandos úteis (debug)

```
fastboot oem run:"wdt list"          # lista device watchdog
fastboot oem run:"wdt stop"          # para o WDT
fastboot oem run:"md.l 17c10000 4"   # lê WDT_EN (0x8=1 ligado, 0=parado)
fastboot oem run:"md.b 9d800000 48"  # lê ramoops
fastboot oem run:"md.b 9d800000 200" # ramoops maior
fastboot oem console                 # lê console record
```

## Problemas conhecidos (aceitos, cosméticos)

- `bootflow scan` imprime "Loading Boot0000-0005 failed" (não há OS) — normal
- O bootmenu usa os botões de volume (touch Ilitek não tem driver no U-Boot)
- `current-slot` reportado como `a` fixo (A/B não implementado no U-Boot)

## NOVIDADE 2026-08-13 (tarde): comando `pstore` para ler o dmesg do kernel

O U-Boot agora embute o comando `pstore` (CONFIG_CMD_PSTORE=y, valores do
hanoip setados no `build.sh`). Ele decodifica o ramoops deixado pelo kernel e
imprime o log SEM precisar de serial.

```
fastboot oem run:"pstore display console"   # dmesg do kernel (zona console 0x9d900000)
fastboot oem run:"pstore display"           # todos os records (dump/console/pmsg)
fastboot oem run:"pstore display dump"      # panics/oops (zona dmesg 0x9d800000)
```

> Fluxo: bootar o kernel estável -> deixar rodar -> warm reboot -> U-Boot ->
> fastboot -> `pstore display console`. Ver `docs/kernel/progresso-2026-08-13-pstore.md`.
