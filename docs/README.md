# Documentacao do Port U-Boot + Kernel Mainline - Moto G60 (hanoip)

Documentacao completa do port do **Motorola Moto G60 (hanoip)** para U-Boot e kernel Linux mainline.

**SoC**: Qualcomm Snapdragon 730G (sm7150 / sdmmagpie)
**Device**: Moto G60 / G40 Fusion (hanoip, XT2135-1)
**Storage**: Samsung UFS KM5V8001DM-B622 (128GB, multi-LUN)

## Indice
| Pasta | Conteudo |
|-------|----------|
| `uboot/` | Port do U-Boot |
| `kernel/` | Port do kernel mainline |
| `scripts/` | Scripts do projeto |
| `seguranca/` | Recuperacao e cuidados |

## Estado resumido (2026-08-22 noite)

### U-Boot: funcional (boot volatile via fastboot Motorola)
- `work/u-boot-hanoip-boot.img` (sempre o build atual)
- Fastboot `motorola-hanoip` OF_EMBED, bootargs console=ttyGS0/ramoops/tty1
- **RPMh fix**: `rpmh_rsc.c` limpa `RSC_DRV_IRQ_CLEAR` apos vote (elimina WARN tcs_tx_done no kernel)
- DT: lcdb_lab/ibb 5500, gpio55 hog, &mdss/&dispcc/&ice/&ufs disabled, sdhc_2 L6C 1648-2950

### Kernel mainline: HANOIP ALIVE + USB COM8
- `work/kernel-usb-gadget2c.img` (ou os preservados no Temp)
- LCDB full (5500mV VREG_OK), panel-en-hog 55, nomdss simplefb, no-UFS 30s
- USB configfs ACM: COM8 115200 ttyGS0 shell
- SD: mmc2 limpo sem cartao; com cartao pendente (3.3V)

### Pendentes
- SD 3.3V, DPU/DSC, WLED, UFS GDSC completo, touch Ilitek, cpufreq

## Fluxo diario
1. Fastboot Motorola (Vol Down+Power) -> `fastboot boot u-boot-*.img`
2. Enable fastboot mode -> `fastboot boot kernel-usb-gadget2c.img`
3. ~40s -> Windows COM8 115200 -> shell `~ #` (PuTTY/TeraTerm)
