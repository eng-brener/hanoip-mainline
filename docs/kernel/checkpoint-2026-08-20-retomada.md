# Checkpoint 2026-08-20 - retomada em 2026-08-21

Este documento registra LITERALMENTE tudo o que foi descoberto, o ponto atual e
onde paramos, para retomar amanha sem perda de contexto.

## Estado geral do bring-up

O Moto G60/G40 Fusion (`hanoip`, SM7150) agora:
- Inicia o U-Boot por `fastboot boot` (sem flash persistente);
- Inicia o kernel mainline pelo fastboot interno do U-Boot;
- **Passa pelo probe do TLMM** sem external abort (fix: reservar GPIO0-3);
- Chega ao `/init` do initramfs;
- Cria `/dev/fb0`;
- Permanece vivo (nao reinicia, nao crasha).

Bloqueios atuais:
1. A tela mostra o log do boot e depois fica **"acesa mas preta"** (scanout do
   MDP para ao final; backlight fica ligado). Este e o canal de debug e o foco
   atual.
2. USB serial nao enumera: **nenhum UDC e registrado** (DWC3 nao sobe).
3. UFS: clock `gcc_ufs_phy_ice_core_clk` fica "stuck at off" e `qcom-ice`
   falha com `-EBUSY`.

## Evidencias na placa (confirmadas)

- `IMG_1014.HEIC`: GPIO4 lido com sucesso (`tile=0`, `ctl=0x4000`); kernel
  segue; WARN `gcc_ufs_phy_ice_core_clk status stuck at off` e
  `qcom-ice ... failed with error -16`.
- Log do boot aparece na tela durante a inicializacao (fbcon funciona), depois
  a tela fica preta.
- Usuario confirmou: "sempre pareceu que a tela tava ligada porem preta".
  Ou seja, backlight LIGADO, sem imagem -> scanout/MDP para, nao e backlight.

## TLMM (RESOLVIDO)

ROM stock (`dtbo.img`) declara:
```dts
qcom,tz_gpio {
	compatible = "qcom,tz_gpio";
	tlmm-tz = <0>, <1>, <2>, <3>;
};
```
So GPIO0-3 sao TrustZone. Configuracao que passou na placa:
```dts
compatible = "motorola,hanoip-tlmm", "qcom,sm7150-tlmm";
gpio-reserved-ranges = <0 4>;
```
Driver (`pinctrl-sm7150.c`): `hanoip_tlmm` com `reserved_gpios = {0,1,2,3,-1}`.
GPIO59-62 NAO sao reservados (stock usa SPI SE6 do touchscreen Ilitek).
GPIO4 nao e TZ (verificado na pratica: leitura OK).

## UFS (BLOQUEADO)

- `IMG_1016.HEIC` mostrou mesmo WARN e `-16` apos adicionar UFS_PHY_GDSC ao ICE.
- O node ICE SM7150 foi corrigido (clocks core/AHB + UFS_PHY_GDSC) mas nao
  resolveu -> padrao de GDSC/handoff problematico nesta placa (igual MDSS).
- HIPOTESE: o framework de GDSC nao faz handoff correto; U-Boot ja deixou os
  clocks/domains ON, e o kernel nao deve power-cycle-los.

## USB (BLOQUEADO - sem UDC)

Testado:
- `g_serial` built-in (`CONFIG_USB_G_SERIAL=y`, `U_SERIAL_CONSOLE=y`);
- initramfs com shell em `ttyGS0`;
- Windows: adb vazio, fastboot vazio, PnP sem novo dispositivo;
- Diagnostico por cor (faixas no fb): NAO funcionou porque a tela fica preta;
- **Diagnostico por sinal de reboot**: se existisse UDC, o aparelho reiniciaria
  em ~30s. Resultado: **continuou preto, nao reiniciou -> NAO existe UDC**.

Conclusao: o DWC3 nao registra UDC. HIPOTESE principal: mesmo problema de
GDSC/handoff do USB30_PRIM_GDSC (igual UFS ICE e MDSS).

### Proximo passo USB planejado (NAO executado ainda)
Espelhar o fix do MDSS: remover `[USB30_PRIM_GDSC] = &usb30_prim_gdsc` do
`gcc_sm7150_gdscs[]` em `drivers/clk/qcom/gcc-sm7150.c` (linha 2946), e remover
`power-domains`/`required-opps` do wrapper USB no DTS, confiando no estado ON do
U-Boot + `clk_ignore_unused`.

## TELA (FOCO ATUAL - BLOQUEADO)

Fatos:
- `CONFIG_VT=y`, `CONFIG_FRAMEBUFFER_CONSOLE=y`, `CONFIG_FB_SIMPLE=y`.
- Backlight (WLED) esta LIGADO; a tela fica "acesa porem preta".
- Log do boot aparece (scanout funciona), depois para -> scanout/MDP para ao
  final do boot.
- Fix que NAO resolveu:
  1. Adicionar `clocks = <&gcc GCC_DISP_HF_AXI_CLK>` ao simplefb efetivo
     (U-Boot dts) - nao mudou (testado em `screen-test`, ainda preto).
  2. Habilitar WLED (`pm6150l_wled` status ok, num-strings=4, enabled 0-3,
     default-brightness=max) - backlight ja estava ligado; nao mudou.
- LCDB driver e somente-leitura (nao desliga nada).

HIPOTESE principal: um clock do DISPCC (ex: `dispcc_mdss_mdp_clk`, que esta em
`dispcc-sm7150.c` linhas 714-731) e desligado ao final do boot, parando o
scanout. `clk_ignore_unused` nao cobre se o dispcc desliga explicitamente.

### Proximo passo tela planejado (NAO executado ainda)
Adicionar o clock MDP do DISPCC (`DISPCC_MDSS_MDP_CLK`) ao simplefb efetivo,
alem do GCC AXI, para o kernel segura-lo. Verificar qual provider/ID o simplefb
pode referenciar (dispcc) e se segura o scanout.

## Como parar/retomar (comandos)

Boot (no fastboot Motorola, serial ZF523QJBSG):
```
fastboot -s ZF523QJBSG boot u-boot-<X>.img
# esperar fastboot interno ????????????
fastboot boot kernel-<Y>.img
```

## Artefatos gerados hoje (diretorio temporario)

`C:\Users\admin\AppData\Local\Temp\opencode\`

U-Boot:
- `u-boot-hanoip-stock-tz-gpios.img` (known good TLMM; usado como base)
  SHA256 fb6d4aa1da8f7c46f05e8ec830121f498faee36b3f08b05a9c1eb435f617c0a3
- `u-boot-hanoip-ufs-ice-fixed.img` (experimental ICE/UFS)
- `u-boot-hanoip-simplefb-clock.img` (simplefb com clock)
- `u-boot-hanoip-wled.img` (WLED habilitado)
  SHA256 07a9233c2550e28d1991b16afa5b2fe01f983566b90234d85b71f3a8495db47f

Kernel (initramfs variado):
- `kernel-mainline-hanoip-stock-tz-gpios-debug.img` (known good, debug GPIO4)
- `kernel-mainline-hanoip-storage-diagnostic*.img`
- `kernel-mainline-hanoip-gserial-isolated.img` (g_serial + shell ttyGS0)
- `kernel-mainline-hanoip-usb-color-diag.img`
- `kernel-mainline-hanoip-usb-reboot-signal.img`
- `kernel-mainline-hanoip-screen-test.img`
- `kernel-mainline-hanoip-screen-test-wled.img`
  SHA256 2a89ab32469bdd163a7f3208182d1597cf5054627083c8eb0e28d8ec296d62b6

IMPORTANTE: os nomes em `Temp\opencode` sao os preservados. Os arquivos em
`work/` (`u-boot-hanoip-boot.img`, `kernel-mainline-hanoip-initrd.img`) sao
sobrescritos a cada build e NAO sao confiaveis como checkpoint.

## Fonte de initramfs (editaveis, em work/)

- `work/diagnostic-root-20260820/init` - painel de 3 paginas (tela preta).
- `work/usb-serial-root-20260820/init` - shell em ttyGS0.
- `work/usb-reboot-signal-root-20260820/init` - reinicia se UDC existir.
- `work/screen-test-root-20260820/init` - preenche tela com ruido + brilho max.
- `work/usb-color-root-20260820/init` - faixas de cor no fb.

## Arquivos-fonte relevantes

- `kernel-mainline/drivers/pinctrl/qcom/pinctrl-sm7150.c` (hanoip_tlmm)
- `kernel-mainline/drivers/pinctrl/qcom/pinctrl-msm.c` (diagnostico GPIO4)
- `kernel-mainline/drivers/clk/qcom/gcc-sm7150.c` (gdscs array, linha 2946)
- `kernel-mainline/drivers/clk/qcom/dispcc-sm7150.c` (MDP clock, linha 714)
- `kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts`
- `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`
- `kernel-mainline/.config` (g_serial habilitado; salvo backup em
  `work/kernel-config-before-gserial-20260820`)

## Configuracoes efetivas do kernel (known good)

```text
CONFIG_QCOM_WDT: desligado (ligar causava reset ~30s)
CONFIG_FB_SIMPLE=y
CONFIG_VT=y CONFIG_FRAMEBUFFER_CONSOLE=y
CONFIG_USB_G_SERIAL=y CONFIG_U_SERIAL_CONSOLE=y
CONFIG_REGULATOR_QCOM_LCDB=y (somente-leitura)
CONFIG_BACKLIGHT_QCOM_WLED=y
bootargs: maxcpus=6 cpuidle.off=1 cpufreq.off=1 idle=poll clk_ignore_unused
```

## ROM stock disponivel (referencia)

`C:\ProgramData\RSA\Download\RomFiles\HANOIP_RETAIL_S2RI32.32_20_9_9_2...xml`
(caminho e uma PASTA com a ROM completa: boot/vendor_boot/dtbo/bootloader/radio/
super/firmware). Extracao em `C:\Users\admin\AppData\Local\Temp\opencode\hanoip-analysis`.

## Documentos de apoio (em docs/kernel/)

- `known-good-2026-08-20.md` - checkpoint reproduzivel TLMM
- `auditoria-rom-stock-2026-08-20.md` - analise completa da ROM
- `progresso-2026-08-20.md` - cronologia
- `teste-usb-serial-2026-08-20.md` - plano USB
- `estado.md` - resumo

## ONDE PARAMOS (retomar daqui)

Na tela (foco atual):
1. Aplicar o fix de segurar o clock MDP do DISPCC no simplefb efetivo.
2. Testar se a tela continua acesa/visivel apos o boot.
3. Se resolver, refazer diagnostico USB por cor (agora com tela visivel).

Se a tela nao resolver, o caminho alternativo de console e o USB serial, que
depende de resolver o UDC (hipotese GDSC do USB30_PRIM_GDSC).
