# Auditoria da ROM stock do hanoip - 2026-08-20

## Fonte analisada

ROM Motorola completa:

```text
C:\ProgramData\RSA\Download\RomFiles\
HANOIP_RETAIL_S2RI32.32_20_9_9_2_subsidy_DEFAULT_regulatory_DEFAULT_CFC.xml
```

O caminho acima e uma pasta, apesar da extensao `.xml`. Ela contem
`boot.img`, `vendor_boot.img`, `dtbo.img`, `bootloader.img`, `radio.img`,
`super.img_sparsechunk.*`, `vbmeta*.img`, `dspso.bin` e `BTFM.bin`.

Todos os MD5 conferidos correspondem ao `flashfile.xml`. Nenhuma imagem stock
foi modificada ou gravada no aparelho. Extracoes temporarias foram feitas em:

```text
C:\Users\admin\AppData\Local\Temp\opencode\hanoip-analysis
C:\Users\admin\AppData\Local\Temp\opencode\hanoip-rom-analysis
```

## Layout de boot stock

O stock segue o contrato Android boot header v3:

- `boot.img`: kernel 4.14 e ramdisk Android;
- `vendor_boot.img`: DTB base, vendor cmdline e first-stage ramdisk;
- `dtbo.img`: overlays Motorola selecionados por board ID.

Metadados principais:

```text
boot.img: header v3, kernel 14816251 bytes, ramdisk 11925793 bytes
vendor_boot.img: header v3, DTB 395541 bytes, DTB addr 0x01f00000
kernel: Linux 4.14.190-perf+, build 2023-07-25
```

O vendor cmdline stock inclui:

```text
console=ttyMSM0,115200n8
lpm_levels.sleep_disabled=1
swiotlb=1
androidboot.usbcontroller=a600000.dwc3
earlycon=msm_geni_serial,0x880000
firmware_class.path=/vendor/firmware_mnt/image
```

Nosso boot via U-Boot e deliberadamente outro contrato: o U-Boot define
`boot_with_embedded_fdt=1` e entrega seu proprio DTB ao kernel. Portanto nao e
necessario reproduzir `vendor_boot` durante o bring-up, mas ele continua sendo
a referencia correta de hardware stock.

## DTB e variantes de placa

O DTB base stock declara:

```text
model = Qualcomm Technologies, Inc. SDMMAGPIE SoC
compatible = qcom,sdmmagpie
qcom,msm-id = <0x16d 0>
```

O `dtbo.img` contem tres overlays hanoip:

| Entrada | Board ID | Variante |
|---|---|---|
| 0 | `<0x4c 0xa100>` | EVT1 |
| 1 | `<0x4c 0xb200>` | DVT2 |
| 2 | `<0x4c 0xb100>` | DVT1 |

Todos incluem `sdmmagpie-hanoip-common-overlay.dtsi`; as diferencas principais
sao revisao de placa/camera. Os overlays downstream nao podem ser aplicados
diretamente ao DT mainline porque usam phandles, bindings e topologia
downstream. Eles devem ser usados como evidencia para portar propriedades uma
a uma.

## GPIOs TrustZone confirmados

O overlay stock do hanoip contem explicitamente:

```dts
qcom,tz_gpio {
	compatible = "qcom,tz_gpio";
	tlmm-tz = <0>, <1>, <2>, <3>;
};
```

O codigo Motorola em `kernel/power/user_sysfs_private.c` le `tlmm-tz` e marca
exatamente esses indices em `tz_configs[]`. Conclusao comprovada:

- GPIO0-3 sao protegidos/administrados pelo TrustZone no hanoip;
- GPIO4-7 nao aparecem no mapa TZ stock;
- a mascara mainline especifica da placa deve conter somente GPIO0-3.

GPIO59-62 nao devem ser reservados. O stock habilita `qupv3_se6_spi` para o
touchscreen Ilitek:

```dts
&qupv3_se6_spi {
	status = "ok";
	ilitek@0 {
		compatible = "tchip,ilitek";
	};
};
```

As linhas SPI sao GPIO59-62; logo elas pertencem ao AP no hanoip. A reserva
`<59 4>` usada por outros aparelhos SM7150 nao se aplica a esta placa.

Implementacao correta atual:

```text
reserved_gpios = { 0, 1, 2, 3, -1 }
gpio-reserved-ranges = <0 4>
```

Se o external abort em GPIO4 reaparecer, ele nao deve ser classificado como
ownership TZ. O proximo diagnostico deve verificar o mapeamento/acesso do tile
NORTH e o endereco fisico calculado pelo driver.

## TLMM

Stock:

```dts
pinctrl@3400000 {
	compatible = "qcom,sdmmagpie-pinctrl";
	reg = <0x03400000 0x00dc2000>, <0x17c000f0 0x60>;
	reg-names = "pinctrl", "spi_cfg";
};
```

Mainline usa tres recursos por tile e `qcom,sm7150-tlmm`. Os enderecos
correspondem aos offsets downstream:

```text
WEST  = 0x03400000 + 0x00100000 = 0x03500000
NORTH = 0x03400000 + 0x00500000 = 0x03900000
SOUTH = 0x03400000 + 0x00900000 = 0x03d00000
```

Isso valida os enderecos base, mas o mainline nao modela o segundo recurso
`spi_cfg`. Ele esta ligado a configuracao de interrupcoes downstream e merece
auditoria se o GPIO4 continuar falhando.

## PSCI e CPUs

Os modos downstream confirmam os parametros OSI ja corrigidos:

```text
cluster/CX off   = 0x41002244
cluster/LLCC off = 0x4100c244
```

Os overrides atuais do hanoip estao alinhados ao stock. O stock tambem usa
`lpm_levels.sleep_disabled=1`; por isso manter `cpuidle.off=1 idle=poll` durante
o bring-up e uma diferenca deliberada e conservadora, nao uma regressao.

## Watchdog

O stock possui o driver downstream `CONFIG_QCOM_WATCHDOG_V2=y`, mesmo com o
framework generico `CONFIG_WATCHDOG=n`. Isso nao significa que
`CONFIG_QCOM_WDT` mainline deva ser reativado.

No aparelho, `CONFIG_QCOM_WDT=y` mainline causou reset em aproximadamente 30
segundos. A configuracao validada e:

```text
# CONFIG_QCOM_WDT is not set
```

O U-Boot para explicitamente os watchdogs antes do handoff. Essa evidencia de
placa prevalece sobre a simples diferenca de configuracao stock/mainline.

## Memoria reservada

O stock possui carveouts fixos para hypervisor/XBL, SMEM, camera, modem, video,
CDSP, ADSP, WLAN, NPU, QSEECom e secure CDSP. Tambem confirma:

```text
splash: 0x9c000000 + 0x01700000
```

Os enderecos do splash/DFPS usados no bring-up estao corretos. Antes de
habilitar remoteproc/modem/ADSP/CDSP, a tabela completa de carveouts deve ser
comparada e preservada para evitar corrupcao por firmware.

O ramoops stock possui atributos Motorola como `no-map` e `no-dump-oops`; a
regiao experimental mainline nao e equivalente e, na pratica, nao persistiu
atraves dos resets observados.

## UFS

O stock usa UFS com SMMU/IOMMU, reset, ICE e uma lane. As alimentacoes
confirmadas sao:

```text
VCC:      PM6150 L19, 2.95-2.96 V, ate 600 mA
VCCQ2:    PM6150 L12, 1.75-1.95 V, ate 600 mA
PHY core: PM6150 L4
PHY PLL:  PM6150L L3
```

O DTS mainline preserva a topologia IOMMU. O DTS usado pelo U-Boot atualmente
remove `iommus`, uma divergencia experimental importante. Ela nao deve virar
solucao permanente sem confirmar o handoff SMMU e o comportamento DMA.

## USB

Stock:

```text
dr_mode = otg
maximum-speed = super-speed
USB2 PHY + QMP USB3 PHY
SMMU presente, com bypass downstream
role/extcon controlado pelo charger/Type-C
```

Bring-up atual:

```text
dr_mode = peripheral
maximum-speed = high-speed
somente USB2 PHY
```

Essa reducao e intencional para tentar gadget, mas o connector `power-role =
"source"` fica inconsistente com peripheral-only. A restauracao correta exige
role switch/extcon, QMP USB3 PHY e politica SMMU; nao basta mudar
`maximum-speed`.

## Display e painel

O stock confirma:

```text
painel: mipi_mot_vid_tm_ili7807s_fhd_678
resolucao: 1080 x 2460
modos: 60 e 120 Hz
DSC: 8 bpc, 8 bpp, slice 540 x 10
reset: PM6150L GPIO9
TE: TLMM GPIO10
enable adicional: TLMM GPIO55
LAB/IBB: PM6150L LCDB, aproximadamente +5.5/-5.5 V
backlight: PM6150L WLED
```

O mainline atual e apenas um esqueleto e depende do painel inicializado pelo
ABL. Os fixed regulators de LAB/IBB sao placeholders; os valores U-Boot de
6.0/6.1 V nao correspondem ao perfil stock e nao devem controlar o hardware
real. O proximo port completo de display deve usar LCDB/WLED, GPIO55, DSC,
timings e comandos stock.

## Firmware e seguranca

`bootloader.img` contem XBL, ABL, TZ, HYP, devcfg, AOP, QUP firmware,
keymaster e storsec. Versoes confirmadas:

```text
BOOT.XF.3.1.c3-00001-SM6150LZB-1.20167.3
TZ.XF.5.0.3-00351
```

TrustZone/devcfg contem descritores para os XPUs TLMM NORTH/SOUTH/WEST,
`tlmm_tiles`, `tlmm_xpu_protection`, UFS ICE, secure display e QUP. Os blobs sao
proprietarios/stripped; strings nao permitem inferir de forma confiavel ACLs
numericas adicionais. O mapa `tlmm-tz` do DTBO e a evidencia confiavel para
GPIO ownership.

O stock usa AVB SHA256_RSA2048, rollback index 17 e flags enforcing. Isso
importa para boot pelo ABL, mas o aparelho desbloqueado e os testes por
`fastboot boot` evitam gravacao persistente.

## Conclusoes aplicaveis agora

1. Reservar somente GPIO0-3 no TLMM especifico do hanoip.
2. Nao reservar GPIO59-62; eles sao usados pelo touchscreen stock.
3. Retestar o probe TLMM. Se GPIO4 falhar, investigar tile NORTH/driver, nao TZ.
4. Manter watchdog mainline desabilitado e watchdogs parados no U-Boot.
5. Manter cpuidle/cpufreq desabilitados durante o bring-up inicial.
6. Nao habilitar remoteprocs antes de validar todos os carveouts stock.
7. Tratar UFS sem IOMMU e USB HS peripheral-only como workarounds temporarios.
8. Nao programar os placeholders de 6.0/6.1 V do display.
9. Portar overlays stock semanticamente; nunca aplica-los diretamente ao DT
   mainline.

## Proximo teste controlado

Compilar U-Boot e kernel com:

```text
compatible = "motorola,hanoip-tlmm", "qcom,sm7150-tlmm"
reserved_gpios = { 0, 1, 2, 3, -1 }
gpio-reserved-ranges = <0 4>
```

Resultado esperado: GPIO0-3 nao serao consultados em
`gpiochip_add_data_with_key`. Se o proximo abort indicar GPIO4, coletar o
endereco virtual/fisico calculado e comparar com NORTH `0x03904000`, sem
mascarar GPIO4 automaticamente.

Imagens compiladas e validadas para esse teste:

```text
C:\Users\admin\AppData\Local\Temp\opencode\u-boot-hanoip-stock-tz-gpios.img
SHA256 fb6d4aa1da8f7c46f05e8ec830121f498faee36b3f08b05a9c1eb435f617c0a3

C:\Users\admin\AppData\Local\Temp\opencode\kernel-mainline-hanoip-stock-tz-gpios-debug.img
SHA256 8b801bcc98d4fb9394c4a9e44c59547dedd5d60e271580c5fa1cf04b4d78b821
```

Validacoes realizadas:

- DTB efetivo contem `motorola,hanoip-tlmm qcom,sm7150-tlmm`;
- `gpio-reserved-ranges` efetivo contem somente `0 4`;
- `hanoip_reserved_gpios` e `hanoip_tlmm` existem no `vmlinux`;
- a mensagem diagnostica de GPIO4 existe no `Image`;
- kernel e DTB extraidos do boot image sao identicos aos artefatos compilados;
- header v2, page size 4096, ramdisk em `0x04000000` e DTB em `0x01f00000`.

## Resultado na placa

O teste com essas duas imagens mostrou varias mensagens de boot e depois a tela
ficou preta, sem stack trace. Esse comportamento e sucesso esperado do
initramfs empacotado. Seu `/init` executa:

```sh
echo "HANOIP-FB-TEST"
if [ -e /dev/fb0 ]; then
	echo "FB0-EXISTE"
	dd if=/dev/zero of=/dev/fb0 bs=4320 count=2460 conv=notrunc
	echo "FB0-LIMPADO-PRETO"
fi
while true; do sleep 10; done
```

Conclusoes confirmadas pelo resultado:

- o probe TLMM passou com somente GPIO0-3 reservados;
- nao houve novo external abort em GPIO4;
- o kernel chegou ao userspace `/init`;
- `/dev/fb0` existia;
- a tela preta foi escrita deliberadamente no framebuffer;
- o processo permanece no loop do initramfs, por isso nenhum USB/ADB aparece.

Isso valida o mapa TrustZone extraido da ROM stock e elimina a necessidade de
reservar GPIO4-7 ou GPIO59-62.

## Resultado posterior: probe ICE/UFS

A captura `IMG_1014.HEIC` confirmou que GPIO4 foi lido com sucesso:

```text
hanoip GPIO4 direction read: tile=0 ctl=0x4000
```

O kernel continuou para os probes seguintes, eliminando GPIO4 e o tile NORTH
como causa do abort anterior. O proximo erro confirmado foi:

```text
gcc_ufs_phy_ice_core_clk status stuck at 'off'
qcom-ice 1d90000.crypto: probe failed with error -16
```

O node ICE SM7150 tinha apenas o clock core, sem nome e sem power domain. O
stock alimenta ICE pelo UFS PHY GDSC e fornece clocks core/AHB. O node SC7180
mainline equivalente tambem usa os dois clocks e `UFS_PHY_GDSC`. A correcao
aplicada ao SM7150 foi:

```dts
clocks = <&gcc GCC_UFS_PHY_ICE_CORE_CLK>,
	 <&gcc GCC_UFS_PHY_AHB_CLK>;
clock-names = "core", "iface";
power-domains = <&gcc UFS_PHY_GDSC>;
```

Imagens compiladas e validadas para testar essa correcao:

```text
C:\Users\admin\AppData\Local\Temp\opencode\u-boot-hanoip-ufs-ice-fixed.img
SHA256 edf52594f7d7832dcf67c89c9dbcdb3864d858c7072c57560218627577d88d60

C:\Users\admin\AppData\Local\Temp\opencode\kernel-mainline-hanoip-ufs-ice-fixed.img
SHA256 0acd02701b83050444427d86da795df46b60c48251f36046c81e84aa9091d944
```

O DTB efetivo foi verificado com clocks `core iface`, dois clock specifiers e
`UFS_PHY_GDSC`. Kernel e DTB extraidos do boot image sao identicos aos
artefatos compilados.
