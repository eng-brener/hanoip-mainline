# Checkpoint 2026-08-22 - LCDB full + panel hog + nomdss (HANOIP ALIVE)

## Estado
Moto G60 (hanoip SM7150) finalmente **chegou ao userspace visível** após ~60s de deferred_probe.

- U-Boot por `fastboot boot` volátil
- Kernel mainline com `LCDB full` + `panel-en-hog gpio55` + `&mdss/&dispcc/&mdss_dsi0 disabled` (mantém simplefb)
- Tela: `simple-framebuffer 9c000000` 1080x2460 + `fbcon 135x153` funciona ~20s, com LCDB antes ia para preta com backlight. Com `LCDB full` + `hog` + `nomdss` a tela **não vai mais para preta** - fica em loop de `gcc_ufs_phy_ice_core_clk stuck` até ~60s, depois faixa xiada (urandom top 100 linhas) + `HANOIP ALIVE` ciclo 8s (diagnostic-root).
- Backlight aceso, scanout vivo.

Evidências na placa:
- `IMG_1038 14:27` `LCDB capture EN 0x80 VREG_OK 1` `LAB 5500 IBB 5500 BST 5650` `LCDB adopted enabled state from ABL` `PM6150L LCDB probed full` (driver qcom-lcdb full, refcnt 2)
- `IMG_1040 14:50` mesma LCDB full, ainda 20s preta sem nomdss
- `IMG_1041 14:50` + `IMG_1043 41s` com nomdss: loop continua mas não preta, até `1.492s SMMU` e `41s rcu stalls`, depois faixa xiada + HANOIP ALIVE.

## Bloqueio ainda
UFS ICE `gcc_ufs_phy_ice_core_clk status stuck at off` `qcom-ice 1d90000.crypto probe failed -16` ainda em loop (20.38s e 29.45s rpmh_write + sdhci pwr_irq timeout). Causa: `ice: crypto@1d90000 clocks core+iface + power-domains UFS_PHY_GDSC` com GCC 0x77044. Downstream usa 4 clocks + GDSC HW. Mainline deixa `clk stuck`. Desabilitar `&ice` causou panic 1s (qcom,ice ainda no ufshc), então mantido enabled mas atrasa boot 60s. Próximo passo: fix GDSC (manter UFS_PHY_GDSC ON via U-Boot ou remover qcom,ice corretamente com &ufs_mem_hc /delete-property/).

## Artefatos checkpoint (preservados)
```
C:\Users\admin\AppData\Local\Temp\opencode\u-boot-nomdss.img
SHA256 c177ceb6bd625fa8696e7e90292d63dfd041822c37ec3081239867bcbbf5c286
work/u-boot-hanoip-boot.img (mesmo)

C:\Users\admin\AppData\Local\Temp\opencode\kernel-nomdss-newinit.img
SHA256 4499158446d8c9db0649b62dffad5c2d7812c551f9cb31604c217cdc78175214
work/kernel-nomdss-newinit.img (mesmo)
```

## Arquivos-fonte
- `kernel-mainline/drivers/regulator/qcom-lcdb-regulator.c` full enable (SEC unlock, BST = max+150, LAB/IBB 5500, MODULE_EN poll VREG_OK 20ms, refcnt 2, adopted from ABL) `REGULATOR_QCOM_LCDB=y`
- `kernel-mainline/arch/arm64/boot/dts/qcom/pm6150l.dtsi` `lcdb_lab: lab` + `lcdb_ibb: ibb` labelled
- `kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts` `avdd/avee -> lcdb_lab/ibb`, `tlmm panel_en_hog gpio-hog 55 output-high`, `&mdss/&dispcc/&mdss_dsi0/&mdss_dsi0_phy status disabled`
- `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts` idem + `clocks <&gcc GCC_DISP_HF_AXI_CLK>` simplefb, bootargs `console=ttyGS0 console=ramoops console=tty1 consoleblank=0 panic=5 clk_ignore_unused maxcpus=6 cpuidle.off=1 cpufreq.off=1 idle=poll`

## Config
```
CONFIG_SM_DISPCC_7150=y (mas dts desabilita via status, mantém simplefb)
CONFIG_REGULATOR_QCOM_LCDB=y
CONFIG_DRM_MSM not set
CONFIG_FB_SIMPLE=y CONFIG_FRAMEBUFFER_CONSOLE=y CONFIG_VT=y
bootargs do U-Boot efetivo: earlycon=msm_geni_serial,0xa88000 console=ttyMSM0 console=ttyGS0 console=ramoops console=tty1 ... consoleblank=0 vt.global_cursor_default=0
```

## Como reproduzir
fastboot Motorola ZF523QJBSG:
```
fastboot -s ZF523QJBSG boot u-boot-nomdss.img  # 548K
# menu -> Enable fastboot mode (????????????)
fastboot boot kernel-nomdss-newinit.img  # 13M
# aguardar ~60s: logs até 41s stalls, depois faixa + HANOIP ALIVE ciclo 8s
```

## Próximos passos
1. Fix UFS ICE GDSC (sem desabilitar) para boot 20s em vez de 60s
2. Re-habilitar DPU/DSC real (hanoip 1080x2460 DSC 540x10) após simplefb OK
3. WLED ovp/string-cfg para backlight nativo
