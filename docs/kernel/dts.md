# Kernel Mainline - DTS do hanoip

## Arquivo

```
kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts
```

Adicionado ao Makefile (`arch/arm64/boot/dts/qcom/Makefile`):
```make
dtb-$(CONFIG_ARCH_QCOM)	+= sm7150-motorola-hanoip.dtb
```

## Origem

Criado a partir do `sm7150-google-sunfish.dts` (Google Pixel 4a), que usa o
mesmo SoC (SM7150), mesmos PMICs (PM6150 + PM6150L), mesma UFS. Os
reguladores RPMh são idênticos.

## Diferenças vs sunfish

| Item | sunfish (Pixel 4a) | hanoip (Moto G60) |
|------|-------------------|-------------------|
| model | Google Pixel 4a | Motorola Moto G60 |
| compatible | google,sunfish | motorola,hanoip |
| RAM | (deixa size=0) | fixada `0x80000000 + 0xfdd00000` |
| Display | Samsung AMS581VF01 | Tianma ILI7807S |
| Touch | (i2c, st ft) | Ilitek SPI6 |
| gpio-keys | vol up | vol up + assist key |
| reserved-memory | layout do Pixel | layout do hanoip |

## Conteúdo principal

### chosen (bootargs)

```dts
chosen {
    stdout-path = "serial0:115200n8";
    bootargs = "earlycon=msm_geni_serial,0xa88000 console=ttyMSM0,115200n8 console=tty1 loglevel=8 ignore_loglevel";
    framebuffer@9c000000 {
        compatible = "simple-framebuffer";
        reg = <0x0 0x9c000000 0x0 (1080 * 2460 * 4)>;
        width = <1080>; height = <2460>; stride = <(1080 * 4)>;
        format = "a8r8g8b8";
    };
};
```

### memory (CRÍTICO)

```dts
&{/memory@80000000} {
    device_type = "memory";
    reg = <0x0 0x80000000 0x0 0xfdd00000>;  // 4GB, NÃO usar 0x100000000
};
```

### Display (panel)

```dts
&mdss_dsi0 {
    panel: panel@0 {
        compatible = "motorola,hanoip-panel", "tianma,ili7807s";
        reg = <0>;
        vddio-supply = <&vreg_l13a_1p8>;
        vsn-supply = <&vreg_ibb>;
        vsp-supply = <&vreg_lab>;
        reset-gpios = <&pm6150l_gpios 9 GPIO_ACTIVE_LOW>;
    };
};
```

> ⚠️ O driver `tianma,ili7807s` **não existe no kernel mainline**. Para
> display DRM funcional, precisa portar/criar o driver. Enquanto isso, o
> `simple-framebuffer` é usado (o U-Boot/ABL deixa o framebuffer pronto).

### Touch (Ilitek SPI6)

```dts
&spi6 {
    status = "okay";
    touchscreen@0 {
        compatible = "tchip,ilitek";
        reg = <0>;
        reset-gpios = <&tlmm 8 GPIO_ACTIVE_LOW>;
        interrupts-extended = <&tlmm 9 IRQ_TYPE_LEVEL_LOW>;
        spi-max-frequency = <12000000>;
    };
};
```

> Driver `CONFIG_TOUCHSCREEN_ILITEK=y` habilitado no config.

### UFS

```dts
&ufs_mem_hc {
    reset-gpios = <&tlmm 119 GPIO_ACTIVE_LOW>;
    vcc-supply = <&vreg_l19a_2p85>;
    vccq2-supply = <&vreg_l12a_1p8>;
    status = "okay";
};
&ufs_mem_phy {
    vdda-phy-supply = <&vdda_ufs_core>;
    vdda-pll-supply = <&vdda_ufs_1p2>;
    resets = <&gcc GCC_UFS_PHY_BCR>;  // reset do GCC (U-Boot não tem no ufs_hc)
    status = "okay";
};
```

### gpio-keys

```dts
gpio_keys: gpio-keys {
    compatible = "gpio-keys";
    key-volume-up {
        gpios = <&pm6150l_gpios 2 GPIO_ACTIVE_LOW>;
        linux,code = <KEY_VOLUMEUP>;
    };
};
```

### reserved-memory

Layout real do hanoip (do DTB downstream):
- hyp@85700000, xbl-aop@85e00000, sec-apps@85fff000, smem@86000000
- removed@86200000, camera@8ab00000, modem@8b000000, pil-video@93400000
- cdsp@93900000, pil-adsp@95700000, wlan-msa@97500000, npu@97680000
- ipa-fw@97700000, ipa-gsi@97710000, gpu@97715000, qseecom@9e400000
- cont-splash@9c000000 (sem no-map), dfps-data@9d700000
- ramoops@9d800000

> O `sm7150.dtsi` do kernel já tem a maioria dos reserved-memory com os
> endereços do hanoip (baseado no downstream).

## DTS do U-Boot vs do kernel

O U-Boot e o kernel têm DTS separados (mesmo nome, caminhos diferentes):
- U-Boot: `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`
- Kernel: `kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts`

São quase iguais (ambos baseados no sunfish). O do kernel tem os bootargs
com earlycon e o panel com compatível de driver do kernel.
