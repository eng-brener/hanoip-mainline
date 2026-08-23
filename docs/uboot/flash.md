# U-Boot - Flash e Instalação

## Estrutura de partições do hanoip (UFS multi-LUN)

O Moto G60 usa UFS com partições divididas entre **LUNs**:

| LUN | Device | Conteúdo |
|-----|--------|----------|
| LUN0 | sda (16MB) | UFS boot partition |
| LUN1 | sdb (118GB) | `ssd`, `persist`, `misc`, `super`, `userdata` etc. |
| LUN2/LUN3 | sdc/sdd (8MB) | `xbl` (XBL bootloader) |
| LUN4 | sde (512MB) | partições `_a`: `aop_a`, `abl_a`, `boot_a`, `vendor_boot_a`, `dtbo_a`, `modem_a`, `dsp_a`, `logo_a` etc. |
| LUN5 | sdf (512MB) | partições `_b` correspondentes |

> O fastboot do U-Boot foi modificado para iterar todos os devices SCSI
> até achar a partição por nome. Sem isso, `boot_a` (LUN4) não era achado.

## Como o U-Boot é instalado

O U-Boot fica na partição `boot_a` (slot A). Para flashar:

```bash
# 1. Ligar o device e ativar o fastboot do U-Boot (menu → opção 4)
# 2. Flashar
fastboot flash boot_a work/u-boot-hanoip-boot.img
```

## Tornar o U-Boot persistente (slot ativo)

O device usa A/B slots. O slot B tem o Android original. Para o U-Boot
bootar sozinho:

```bash
# No fastboot do Motorola (product: hanoip)
fastboot set_active a
fastboot reboot
```

> O slot A fica `unbootable` se o boot do kernel crashar. Para re-marcar:
> ```
> fastboot set_active a
> fastboot oem fb_mode_clear
> ```

## Teste sem gravar nada

```bash
fastboot boot work/u-boot-hanoip-boot.img   # temporário, não grava
```

## Recuperação do Android (voltar pro slot B)

```bash
# No fastboot do Motorola
fastboot set_active b
fastboot reboot
```

## Dumps das partições originais

Os dumps feitos no início estão em `dump/`:
- `boot_a.img`, `boot_b.img` (64MB cada)
- `vendor_boot_a.img`, `vendor_boot_b.img` (64MB)
- `dtbo_a.img`, `dtbo_b.img` (24MB)
- `super.img` (10GB, extraído de /dev/block/sdb)
- `gpt_primary_4k.bin`, `gpt_backup_4k.bin` (GPT em setores 4K)
- Todos os firmwares (abl, xbl, tz, hyp, modem, dsp)

E a ROM stock completa em `rom_stock/` (Android 12):
- `boot.img`, `vendor_boot.img`, `dtbo.img`, `super.img_sparsechunk.*`
- `bootloader.img`, `gpt.bin`
- `flashfile.xml` (define o layout)

## Como restaurar o boot original do slot A

Se precisar restaurar o Android no slot A:
```bash
fastboot flash boot_a rom_stock/boot.img
fastboot flash vendor_boot_a rom_stock/vendor_boot.img
fastboot flash dtbo_a rom_stock/dtbo.img
```

> CUIDADO: `super.img` da ROM stock é Android 12; o device tem Android 14
> custom no slot B. Não misturar slots de versões diferentes sem pensar.
