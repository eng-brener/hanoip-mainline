# Progresso 2026-08-22 - LCDB full + USB COM8 + RPMh fix + SD (completo)

## Resumo do dia
Moto G60 (hanoip) saiu de `20s textos -> preta com backlight` para **HANOIP ALIVE visível + USB Serial COM8 funcional** via kernel mainline.

## Etapa 1 - LCDB PM6150L full (95% causa da tela preta 20s)
Downstream `qpnp-lcdb-regulator.c:758` (lab/ibb 5500mV, BST 5650, MODULE_EN 0x46, VREG_OK 0x10) vs mainline `qcom-lcdb-regulator.c:1` skeleton read-only.
- Portado `qcom-lcdb` full: SEC 0xD0 0xA5, BST (max+150), LAB/IBB 0x71/0x81, poll VREG_OK 20x1ms, refcnt 2, adopted from ABL.
- `pm6150l.dtsi:139` `lcdb_lab/ibb 5500000`; `sm7150-motorola-hanoip.dts` panel `avdd/avee -> lcdb_lab/ibb`.
- Evidência: `IMG_1038` `LCDB probed full LAB 5500 IBB 5500` vs `IMG_1020` `read-only`.

## Etapa 2 - panel-en-hog gpio55
- `tlmm panel_en_hog gpio-hog 55 output-high` + `lcd_en_active` + panel pinctrl `reset 9 + en 55 + vsync 10`.
- Downstream `hanoi-panel.dtsi:100`.

## Etapa 3 - nomdss (simplefb retido além 20s)
- `&mdss/&dispcc/&mdss_dsi0/&mdss_dsi0_phy status disabled` nos dois DTS -> mantém `simplefb 9c000000 GCC_DISP_HF_AXI_CLK`.
- Resultado: `IMG_1041/1043/1044` `HANOIP ALIVE` com faixa xiada + ciclo 8s, UFS ICE loop 60-180s.

## Etapa 4 - UFS 4 clocks (downstream)
- `sm7150.dtsi` `ice 4 clocks AXI/MEM_CLKREF/AHB/ICE_CORE 300M qcom,enable-ice-clk` + `ufshc 8 clocks core_clk_ice`.
- `IMG_1045/1046` encurtou 180s -> 60s mas `gcc_ufs_phy_ice_core_clk stuck` persistiu (UFS_PHY_GDSC sem POLL).

## Etapa 5 - A no-UFS (fast 30s)
- `CONFIG_SCSI_UFS_QCOM=n` + `&ice/&ufs_mem_hc/&ufs_mem_phy status disabled`.
- `IMG_1047/1048` `ALIVE 30s` sem stuck - novo good para iteracao USB/DPU.

## Etapa 6 - USB configfs ACM (COM8)
- `CONFIG_CONFIGFS_FS/USB_GADGET/USB_CONFIGFS_SERIAL/U_SERIAL_CONSOLE=y` (sem g_serial legado que dava 1s preta).
- init cria `g1` idVendor 0x18D1 idProduct **0x4EE2** (0x4EE0 = fastboot, colidia) acm.usb0, bind UDC a600000.usb.
- Resultado: `COM8 Dispositivo Serial USB` `uname 7.1.0-sm7150+` shell `~ #` via ttyGS0 115200 - console completo sem HEIC.

## Etapa 7 - RPMh IRQ_CLEAR fix (causa raiz)
- U-Boot `rpmh_rsc_send_data` votava TCS-0 mas nunca limpava `RSC_DRV_IRQ_CLEAR` -> bit TX-done pendente -> kernel `rpmh-rsc.c:451 tcs_tx_done WARN` + `rpmh_write` travado afetando cpufreq/UFS GDSC/SD pwr_irq.
- Fix: `writel_relaxed(BIT(tcs_id), tcs_base + RSC_DRV_IRQ_CLEAR)` apos cada vote (linha 409) em `uboot-sm7150/drivers/soc/qcom/rpmh-rsc.c`.
- Resultado: WARN `tcs_tx_done` eliminado, SD `0.623 Got CD GPIO` + `0.660 ADMA 64-bit` limpo.

## Etapa 8 - SD mmc2 (cartao)
- `vreg_l6c_3p0` (vqmmc) `1648-2950` + `set-load LPM/HPM` + `&sdhc_2 /delete-property/ iommus` + pinctrl sdc2 active/sleep cd bias-disable.
- Sem cartao: `mmc2 0.66s ADMA` limpo (antes pwr_irq timeout 6-12s).
- COM cartao: `unsupportable voltage range: 3300000` (mainline sdhci pede 3.3V, range 2950 nao cobre); `max 3304` quebrou probe sem cartao. **SD 3.3V PENDENTE** - requer `qcom,vdd-io-voltage-level` custom downstream ou investigacao sdhci_msm.

## Artefatos (Temp\opencode)
- good base 30s: `u-boot-good-30s` 206491a1 + `kernel-good-30s` d07b7940
- no-UFS: `u-boot-noufs` c41389ce + `kernel-noufs-newinit` 9b9ed7c6
- USB COM8: `kernel-usb-gadget2c` 018aec40 (com `u-boot-good-30s`)
- RPMh fix: `u-boot-rpmhfix` 6d382c84 (com `kernel-usb-gadget2c`)
- SD safe: `u-boot-sd-safe` 9326b5c4 (L6C 1648-2950, com `kernel-usb-gadget2c`)

## Proximos
- SD 3.3V (qcom,vdd-io-voltage-level custom), DPU/DSC 540x10, WLED ovp, UFS GDSC POLL completo, touch Ilitek.

## Etapa 9 - SD mmc2 (LICAO: desabilitado, arriscado no mainline)

Tentativas de habilitar cartao SD no `&sdhc_2 mmc@8804000`:
- `vqmmc L6C 1648-2950` + `set-load` + `delete iommus`: sem cartao `0.66s ADMA` limpo, mas com cartao `unsupportable voltage range: 3300000` (mainline pede 3.3V, range 2950 nao cobre).
- `vqmmc max 3304` (cobrir 3.3V): **quebrou probe sem cartao** (`rpmh_write` trava, gadget USB nao sobe).
- `vmmc L9C fixo 2950` (Opcao B analisada: OCR bit17 -> 2.9V): **travou boot com cartao** - erros `regulator bdev not released` em massa, nem chegou ao UDC.
- **DECISAO**: `&sdhc_2 status disabled` nos dois DTS. SD com cartao e PENDENTE/arriscado no mainline - requer portar `qcom,vdd-io-voltage-level` custom (downstream usa 1.8/2.95V nunca 3.3V) ou investigar `regulator bdev not released` no sdhci_msm cleanup.

### Licao importante
- O mainline `sdhci_msm` usa o framework regulator padrao e pede 3.3V para cartao nao-UHS, que estoura o L6C (max 2950).
- O downstream Motorola usa `qcom,vdd-io-voltage-level = <1800000 2950000>` e mapeia 3.3V->2.95V no pwr_irq (nunca escreve 3300000).
- Nao mexer em `&sdhc_2` voltagem sem portar o custom binding - pode travar boot (perde UDC/USB).

### Artefatos SD
- `u-boot-sd-safe 9326b5c4` (L6C 1648-2950, sem timeout sem cartao) - obsoleto
- `u-boot-sd33` (L6C 3304, quebrou) - obsoleto
- `u-boot-sd-vmmc2950` (L9C fixo, travou com cartao) - obsoleto
- **`u-boot-sd-off 18:21` (sdhc_2 disabled, ESTAVEL + COM8)** - atual
