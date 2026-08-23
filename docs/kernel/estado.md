# Kernel Mainline - Estado Atual (atualizado 2026-08-22 noite)

## Resumo: HANOIP ALIVE + USB COM8 (LCDB full + nomdss + no-UFS + RPMh fix)

Kernel mainline SM7150 chega ao userspace com tela visivel + console serial USB.

## O que funciona
- **LCDB PM6150L full** (driver qcom-lcdb): LAB/IBB 5500mV, BST 5650, VREG_OK, refcnt, adopted ABL. Panel avdd/avee -> lcdb_lab/ibb. `REGULATOR_QCOM_LCDB=y`.
- **panel-en-hog gpio55** + lcd_en_active + reset 9 + vsync 10.
- **nomdss**: `&mdss/&dispcc/&mdss_dsi0 status disabled` mantem simplefb 9c000000 (fbcon 1080x2460) - sem DPU handoff.
- **no-UFS**: `CONFIG_SCSI_UFS_QCOM=n` + nodes disabled -> boot 30s (vs 60s/180s).
- **USB configfs ACM**: `kernel-usb-gadget2c` cria g1 idVendor 0x18D1 idProduct 0x4EE2 acm.usb0, bind UDC a600000.usb -> **COM8** 115200 ttyGS0 shell. `USB_CONFIGFS_SERIAL=y`.
- **RPMh fix (causa raiz)**: U-Boot `rpmh_rsc.c:409` `writel_relaxed(BIT(tcs_id), tcs_base+RSC_DRV_IRQ_CLEAR)` elimina WARN tcs_tx_done e rpmh_write travado.

## Imagens (Temp\opencode)
- `u-boot-good-30s` 206491a1 + `kernel-good-30s` d07b7940 (base ALIVE 30s)
- `kernel-usb-gadget2c` 018aec40 (COM8) + `u-boot-rpmhfix` 6d382c84 (RPMh) + `u-boot-sd-safe` 9326b5c4 (SD limpo)
- Boot: fastboot boot u-boot-*.img -> Enable fastboot -> fastboot boot kernel-usb-gadget2c.img -> COM8 115200

## Pendentes
- **SD 3.3V**: `&sdhc_2 status disabled` (SD desabilitado). Com cartao: `unsupportable voltage range: 3300000`; com L9C fixo 2950 travou boot (`regulator bdev not released` em massa, perdeu UDC). Requer portar `qcom,vdd-io-voltage-level` custom (downstream 1.8/2.95V nunca 3.3V). **Nao mexer em sdhc_2 voltagem sem portar binding.**
- **DPU/DSC**: DRM sem DSC deu 1s preta (MDP_CLK overflow). Precisa DSC 540x10 + dfps.
- **UFS**: re-tentar com RPMh fix (GDSC POLL completo). `super` indisponivel ate la.
- cpufreq-hw 18323000 ainda falha (interconnect/opp), nao bloqueia ALIVE.
- WLED ovp 26500, touch Ilitek SPI6, 60/90/120Hz.

## Docs
- `checkpoint-2026-08-22-lcdb-nomdss.md` + `known-good-2026-08-22.md` (base LCDB+nomdss)
- `progresso-2026-08-22.md` (dia completo)
