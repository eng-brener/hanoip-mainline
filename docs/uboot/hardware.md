# U-Boot - Hardware e Partições

## SoC: Qualcomm SM7150 (sdmmagpie)

- Snapdragon 730G (8x Kryo 470, 2x A76 + 6x A55)
- GPU Adreno 618
- UFS 3.1 (Samsung KM5V8001DM-B622)
- PMIC: PM6150 + PM6150L
- WiFi/BT: WCN3990 (ath10k)
- Display: DSI (Tianma ILI7807S, 6.78" FHD+ 1080x2460, 120Hz)
- Touch: Ilitek (SPI6)
- USB: dwc3 @ 0xa600000
- UFS: ufshc @ 0x1d84000, phy @ 0x1d87000

## RAM

- Base: `0x80000000`
- Tamanho: `0xfdd00000` (~3.96GB, NÃO 4GB cheio!)
- Fim físico: `0x17dd00000` (os últimos ~35MB são reservados p/ firmware)
- **CRÍTICO**: declarar 4GB (`0x100000000`) faz o U-Boot crashar no
  `dm_init_and_scan` (reloca para memória inexistente)

## UFS multi-LUN

O storage é UFS com 6 LUNs. O GPT principal está no LUN1 (sdb), mas as
partições de boot estão em LUNs separados.

| LUN | Size | Device | Partições |
|-----|------|--------|-----------|
| 0 | 16MB | sda | UFS boot |
| 1 | 118GB | sdb | ssd, persist, misc, super, userdata, metadata, etc. |
| 2 | 8MB | sdc | xbl_a, xbl_config_a |
| 3 | 8MB | sdd | xbl_b, xbl_config_b |
| 4 | 512MB | sde | aop_a, abl_a, boot_a, dtbo_a, logo_a, modem_a, dsp_a, vendor_boot_a, etc. |
| 5 | 512MB | sdf | partições _b |

> GPT usa setores de **4096 bytes** (não 512). O GPT header está no LBA 1
> de 4K (offset 4096).

## GPT do LUN1 (principais)

```
ssd (256), persist (64), misc (1024), keystore, frp, utags, utagsBackup,
cid, metadata (16MB), kpan, sp, carrier, modemst1, modemst2, fsc, dhob,
devinfo, logfs, apdp, spunvm, uefivarstore,
super (10GB, start 28800 x 4K), userdata (118GB)
```

## Partições de boot (LUN4, slot A)

```
aop_a, hyp_a, tz_a, storsec_a, cmnlib_a, cmnlib64_a, keymaster_a, prov_a,
abl_a (1MB), qupfw_a, uefisecapp_a, multiimgoem_a, multiimgqti_a,
vbmeta_a, vbmeta_system_a, fsg_a, modem_a (140MB), dsp_a (32MB),
logo_a (32MB), dtbo_a (24MB), boot_a (64MB), vendor_boot_a (64MB)
```

## Firmware / boot chain

```
XBL (xbl_a, assinado) → ABL (abl_a, assinado) → U-Boot (boot_a) → kernel
```

O ABL (UEFI Motorola) carrega o U-Boot como payload do boot.img (header v3).
O U-Boot usa o DTB embutido (OF_EMBED). O ABL também passa um DTB externo
(do vendor_boot) em x0, mas o U-Boot prefere o interno se válido.

## DTB do device

- DTS do U-Boot: `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`
- DTS do kernel: `kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts`
- DTB downstream (original): `work/hanoip.dtb` (do vendor_boot do device)
- Compatible: `motorola,hanoip`, `qcom,sm7150`

## Hardware específico do hanoip (do DTS)

| Hardware | Config |
|----------|--------|
| Display | Tianma ILI7807S, reset via pm6150l_gpio9, TE gpio10, EN gpio55 |
| Touch | Ilitek SPI6 (reset gpio8, irq gpio9) |
| gpio-keys | Volume Up = pm6150l_gpio2, assist_key = tlmm58 |
| NFC | nq-nci @ qupv3_se2_i2c (gpio37 irq, gpio12 ven, gpio36 fw) |
| Sensor | Semtech sx933x @ qupv3_se7_i2c (gpio84 irq) |
| RAM | 4GB, base 0x80000000, size 0xfdd00000 |
| UFS | Samsung KM5V8001DM-B622, reset gpio119 |
