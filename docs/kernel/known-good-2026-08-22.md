# Known Good 2026-08-22 - LCDB full + nomdss + USB COM8 + RPMh fix

## Estado
Moto G60 (hanoip) chega ao userspace com **tela visivel (faixa + HANOIP ALIVE)** e **console USB Serial COM8**.

## Imagens known good (Temp\opencode)
```
u-boot-good-30s.img  SHA256 206491a1e98a0d2dcbce5bdcd3eca4e6ba4074a902b71cb7c1bee9551cab6710
kernel-good-30s.img  SHA256 d07b79403487130b03f2eea195b7c867c0bf1ce2eeca5d487535405fd58c501b
kernel-usb-gadget2c.img SHA256 018aec40aea5a7304eda12846db79efe50ce067f7d61f68d71a3b25f6c120635  (COM8)
u-boot-rpmhfix.img   SHA256 6d382c8401d08e784824165feaa7176e4d5d3839366fdefcf544e6ac64635f8d
u-boot-sd-off.img    SHA256 327226ee100dca731f91f9f0ef93c9a112ef3ccd1b5f98edbe0b42c40f4cba1e  (sdhc_2 disabled, ESTAVEL + COM8) - atual
```

## Boot
fastboot Motorola ZF523QJBSG:
```
fastboot -s ZF523QJBSG boot u-boot-sd-safe.img   # 548K
# Enable fastboot -> ????????????
fastboot boot kernel-usb-gadget2c.img            # 13M
# ~40s depois: Windows COM8 "Dispositivo Serial USB" - PuTTY 115200 -> shell ~ #
```

## Config efetiva
- CONFIG_FB_SIMPLE=y, FRAMEBUFFER_CONSOLE=y, VT=y, SM_DISPCC_7150=y (dts disabled), DRM_MSM=n, SCSI_UFS_QCOM=n
- CONFIG_REGULATOR_QCOM_LCDB=y (full), CONFIG_USB_GADGET/CONFIGFS/SERIAL=y
- bootargs (U-Boot): earlycon=msm_geni_serial,0xa88000 console=ttyMSM0,115200n8 console=ttyGS0 console=ramoops console=tty1 ... consoleblank=0 panic=5 clk_ignore_unused maxcpus=6
- DT: lcdb_lab/ibb 5500, panel avdd/avee->lcdb, gpio55 hog, &mdss/&dispcc disabled, &ice/&ufs disabled, sdhc_2 L6C 1648-2950 + delete iommus

## Evidencias
- IMG_1047/1048: ALIVE 30s sem UFS stuck
- COM8 dmesg: 0.623 Got CD GPIO, 0.660 mmc2 ADMA 64-bit, sem tcs_tx_done WARN (apos RPMh fix), USB GADGET CFG=/config UDC=a600000.usb ttyGS0 ready
