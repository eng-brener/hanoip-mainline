# Progresso 2026-08-20 - resultado dos testes de framebuffer

## Resultado na placa

- O U-Boot continua completamente funcional: tela, texto, USB e fastboot.
- Ao entregar para o kernel, a tela fica cinza-claro uniforme.
- `kernel-mainline-hanoip-fbtest.img` nao tornou a tela preta.
- `kernel-mainline-hanoip-fbnoise.img` nao mostrou ruido; a tela permaneceu cinza.
- O dispositivo USB do U-Boot ainda aparece no host depois do salto, mas nao
  responde. Isso e estado/enumeracao residual, nao prova que o DWC3 foi assumido
  pelo kernel.

## Diagnostico

O DTB efetivo e o embutido no U-Boot. Nele, o node `simple-framebuffer` havia
sido movido para a raiz e havia perdido o clock presente no DTS do kernel. O
kernel trata explicitamente o simple-framebuffer filho de `/chosen` em
`drivers/of/platform.c`.

O DTB efetivo foi alinhado ao DTS do kernel:

- `framebuffer@9c000000` novamente dentro de `/chosen`;
- `#address-cells`, `#size-cells` e `ranges` restaurados;
- `GCC_DISP_HF_AXI_CLK` preservado pelo node.

Para USB, `console=ttyGS0` nao cria um gadget. A configuracao atual possui
`CONFIG_USB_G_SERIAL=n`; portanto, sem um initramfs configurando configfs, nao
existe funcao USB serial do kernel para enumerar e responder. A tentativa por
configfs ja causou reset/panic e deve ser tratada separadamente do simplefb.

## Proximo teste

O U-Boot foi recompilado com sucesso e gerou
`work/u-boot-hanoip-boot.img`. O DTB compilado contem
`/chosen/framebuffer@9c000000` e a propriedade `clocks`.

1. Testar o novo U-Boot por `fastboot boot`, sem flash persistente.
2. Bootar novamente as imagens `fbtest` e `fbnoise`.
3. Se a tela continuar cinza, capturar o pstore pelo comando do U-Boot e buscar
   as mensagens `simple-framebuffer`, `simplefb`, `fb0`, `dwc3` e `qusb2`.

## Testes adicionais

O pstore nao pode ser usado como canal neste aparelho: tanto reset normal como
reset quente perdem o conteudo. A regiao `0x9d900000` foi lida no U-Boot apos o
reset e continha apenas `0xffffffff`.

O teste `directfb` tentou escrever diretamente em `0x9c000000` por `/dev/mem`,
mas falhou, coerente com `CONFIG_STRICT_DEVMEM=y`. Portanto ele nao confirmou
nem descartou o endereco de scanout.

Foi compilado um kernel minimo com `CONFIG_USB_G_SERIAL=y`. Ativar o gadget
reinicia o aparelho. Foram testadas todas as combinacoes abaixo:

| Handoff USB | IOMMU do DWC3 | Resultado |
|---|---|---|
| reset/desliga | ativo | reinicia |
| preservado | ativo | reinicia |
| reset/desliga | removido | reinicia |
| preservado | removido | reinicia |

Nenhuma combinacao enumerou um novo dispositivo USB no Windows. Isso descarta
o reset do handoff e a SMMU como causas isoladas. O reset acontece ao ativar o
caminho gadget/DWC3 no kernel e agora exige console UART para localizar o panic.

Imagens preservadas:

- `work/kernel-mainline-hanoip-gserial.img`;
- `work/u-boot-hanoip-usb-handoff.img`;
- `work/u-boot-hanoip-usb-noiommu.img`;
- `work/u-boot-hanoip-usb-preserve-noiommu.img`.

## Causa raiz do travamento no handoff do display

Uma busca binaria pelos 369 `device_initcalls` localizou a falha no bloco:

- `gpu_cc_sc7180_driver_init`;
- `camcc_sm7150_driver_init`;
- `dispcc_sm7150_driver_init`.

Desabilitar somente `CONFIG_SM_DISPCC_7150` fez o kernel chegar ao
`late_initcall`, manter o framebuffer RGB de diagnostico e parar de reiniciar.

Checkpoints dentro de `qcom_cc_really_probe()` mostraram:

- attach ao `RPMHPD_CX`: OK;
- registro do reset controller: OK;
- registro dos clocks: falha.

O registro foi reduzido aos IDs 22-32 e uma sequencia visual identificou
precisamente o ID 27, `DISPCC_MDSS_MDP_CLK_SRC`.

Esse RCG usava `clk_rcg2_shared_ops`. O callback de inicializacao dessa
operacao chama `clk_rcg2_shared_disable()` e estaciona o RCG em uma fonte
segura durante o registro. No hanoip, o MDP ja esta ativo pelo U-Boot; alterar
seu clock durante o continuous splash interrompe o pipeline e trava o handoff.

A operacao foi substituida por:

```c
.ops = &clk_rcg2_shared_no_init_park_ops,
```

Ela captura a configuracao atual para o CCF sem estacionar nem reprogramar o
clock herdado.

Uma segunda causa foi confirmada separadamente. Restaurar o registro do
`MDSS_GDSC`, definido com `HW_CTRL`, voltou a causar reset em cerca de 30
segundos. Preservar o PLL/gating nao mudou esse resultado. A configuracao
estavel validada foi:

- todos os clocks DISPCC registrados;
- MDP RCG com `clk_rcg2_shared_no_init_park_ops`;
- PLL e gating herdados preservados no probe;
- GDSC temporariamente nao registrado;
- kernel estavel por mais de 60 segundos.

Artefato validado:

- `work/kernel-mainline-hanoip-dispcc-handoff-stable.img`.

O GDSC ainda precisa de uma implementacao de handoff correta. O DTS declara
`<&dispcc MDSS_GDSC>`, portanto omitir o provider e apenas uma medida de
bring-up para simplefb; nao e a solucao final para habilitar DRM/DPU.

## Console na tela funcionando

Depois de estabilizar o DISPCC, `/dev/fb0` foi confirmado por um initramfs que
reiniciava deliberadamente somente quando o device existia. O framebuffer era
registrado, mas escritas nao apareciam porque `simplefb` usava `ioremap_wc()`.

No hanoip, o scanout herdado em `0x9c000000` somente refletiu escritas pelo
mapeamento linear (`phys_to_virt`) seguido de limpeza explicita do data cache.
O simplefb foi adaptado apenas para esse endereco:

- operacoes em memoria de sistema;
- `dcache_clean_poc()` depois de write/fill/copy/imageblit;
- comportamento original preservado para outros framebuffers.

O empacotamento dos initramfs tinha dois problemas adicionais:

1. ramdisk em `0x01000000`, sobreposto pelo kernel descompactado de cerca de
   29 MB; corrigido para `0x04000000`;
2. `pack_kernel_initrd.sh` reutilizava `Image.gz` antigo, fazendo os testes
   ainda conterem `CONFIG_QCOM_WDT=y`; agora o script sempre recomprime o
   `Image` atual.

O script legado `fix_initrd.py` nao deve ser usado com o `mkbootimg` atual:
ele grava offsets incorretos e corrompe `tags_addr`/`recovery_dtbo`.

Imagem validada com console/fbcon visivel na tela:

- `work/kernel-mainline-hanoip-simplefb-linear-nowdt.img`.

Configuracao relevante validada dentro do boot image:

```text
# CONFIG_QCOM_WDT is not set
CONFIG_FB_SIMPLE=y
ramdisk load address: 0x04000000
```

## External abort no probe do TLMM

Depois que o console visual ficou funcional, duas capturas consecutivas
(`IMG_1009.HEIC` e `IMG_1011.HEIC`) mostraram o mesmo crash:

```text
Internal error: synchronous external abort: 0000000096000010
pc : msm_gpio_get_direction+0x48/0x88
Call trace:
 msm_gpio_get_direction
 gpiochip_add_data_with_key
 devm_gpiochip_add_data_with_key
 msm_gpio_init
 msm_pinctrl_probe
 sm7150_tlmm_probe
```

No frame de `msm_gpio_get_direction`, `x1 = 4`. Pelo ABI arm64, o segundo
argumento e o offset do GPIO; portanto o acesso que dispara o abort e o
**GPIO4**, e nao o GPIO119. A mudanca anterior de `.ngpios = 120` para 119
continua correta para separar `UFS_RESET`, mas nao resolve este crash.

Foi adicionado temporariamente ao DTS da placa:

```dts
gpio-reserved-ranges = <4 4>, <59 4>;
```

O U-Boot de teste foi compilado em uma arvore limpa e validado em tres niveis:

- `dts/dt.dtb` e o DTB da placa sao identicos;
- a secao `.dtb.init.rodata` do ELF contem o mesmo DTB, mais apenas 8 bytes de
  padding zero;
- o DTB ligado contem `gpio-reserved-ranges = <4 4 59 4>`.

O kernel usa comprovadamente esse DTB. `fastboot_boot()` define
`boot_with_embedded_fdt=1`, e `boot/image-fdt.c` seleciona `gd->fdt_blob` para
imagens Android. Mesmo assim, a segunda captura voltou a mostrar
`msm_gpio_get_direction(..., 4)`. Logo, a propriedade generica nao produziu a
mascara valida esperada antes da enumeracao das direcoes.

### Comparacao upstream e downstream

O problema corresponde a uma classe conhecida de falhas Qualcomm: GPIOs
reservados pelo TrustZone causam violacao XPU/external abort quando seus
registros TLMM sao lidos. Referencias upstream importantes:

- `c1e802f68ca0`: documenta `gpio-reserved-ranges` para pinos Qualcomm
  inacessiveis no mundo nao seguro;
- `6f0ec09afe27`: corrige especificamente violacao XPU causada por
  `get_direction()` durante o registro do gpiochip;
- `9becde08f1bc`: mantem a consulta inicial de direcao, mas exige que ela seja
  limitada por `gpiochip_line_is_valid()`.

O downstream Motorola/Qualcomm 4.14 nao possui lista de GPIOs reservados no
driver SDMMAGPIE. Ele tambem nao consulta `get_direction()` de cada linha ao
registrar o gpiochip, por isso consegue registrar o TLMM sem tocar no GPIO
protegido. Isso nao prova que o GPIO4 seja acessivel; apenas evita o acesso.

Em outras placas SM7150, as reservas variam conforme firmware/produto:

| Placa | Ranges reservados |
|---|---|
| Xiaomi surya | 59-62 |
| Xiaomi sweet | 0-3 e 59-62 |
| Xiaomi davinci | 0-3 e 59-62 |
| Google sunfish | 59-62 |

O sunfish usa GPIO4 normalmente. Portanto a protecao do GPIO4 nao e uma
caracteristica universal do SM7150; e especifica do firmware/ownership do
hanoip e nao deve ser aplicada globalmente ao SoC.

### Decisao e proximo passo

A solucao escolhida e criar dados TLMM especificos para o hanoip usando o
mecanismo `reserved_gpios` ja fornecido por `pinctrl-msm`:

```text
4, 5, 6, 7, 59, 60, 61, 62, -1
```

O DTS usara um compatible especifico antes do fallback generico:

```dts
compatible = "motorola,hanoip-tlmm", "qcom,sm7150-tlmm";
```

O match Motorola selecionara uma copia dos dados SM7150 com
`.reserved_gpios`, enquanto todos os outros aparelhos continuarao usando os
dados genericos. Essa abordagem cria a `valid_mask` pelo callback Qualcomm
antes da consulta de direcao e nao altera o comportamento de outros SM7150.

Nao usar como solucao final:

- remover globalmente `.get_direction`;
- remover a consulta inicial do gpiolib;
- aplicar a reserva a todos os SM7150;
- usar `qcom,gpios-disallowed`, que pertence aos GPIOs PMIC/SPMI downstream;
- tentar recuperar ownership com `qcom_scm_restore_sec_cfg`, para o qual nao ha
  mecanismo TLMM documentado no SDMMAGPIE.

### Implementacao e artefatos

A variante especifica foi implementada em
`drivers/pinctrl/qcom/pinctrl-sm7150.c`. O match generico continua selecionando
`sm7150_tlmm`; somente `motorola,hanoip-tlmm` seleciona `hanoip_tlmm`, cuja
lista `reserved_gpios` contem 4-7 e 59-62.

O kernel e o U-Boot foram recompilados. As validacoes confirmaram:

- DTB efetivo: `motorola,hanoip-tlmm qcom,sm7150-tlmm`;
- ranges no DTB efetivo: `4 4 59 4`;
- simbolos `hanoip_reserved_gpios` e `hanoip_tlmm` presentes no `vmlinux`;
- string `motorola,hanoip-tlmm` presente no `Image`;
- kernel e DTB extraidos do boot image identicos aos artefatos compilados;
- payload U-Boot extraido identico ao `u-boot.bin.gz` e gzip integro.

Imagens para o proximo teste, sem flash persistente:

```text
C:\Users\admin\AppData\Local\Temp\opencode\u-boot-hanoip-tlmm-reserved-gpios.img
SHA256 854d0907b6ab6bc173c73d9d19e797c4ecd7aaeba92285ce6231858b2679fd4b

C:\Users\admin\AppData\Local\Temp\opencode\kernel-mainline-hanoip-tlmm-reserved-gpios.img
SHA256 7495f82ae3a9de029dd03e43af0c4aaf63eee7f0dd920dc60dbebebd6ff8d1fe
```

Ponto atual: iniciar primeiro o novo U-Boot pelo fastboot Motorola e depois o
novo kernel pelo fastboot interno. O resultado esperado e o probe do TLMM
ignorar GPIO4-7 e 59-62 e avancar alem de `gpiochip_add_data_with_key()`.

### Resultado do primeiro teste com `reserved_gpios`

A captura `IMG_1012.HEIC` confirmou que a variante especifica foi selecionada:
o abort deixou de ocorrer com `x1 = 4` e passou a ocorrer com `x1 = 0`, ainda
em `msm_gpio_get_direction`. Portanto GPIO4-7 foram efetivamente retirados da
enumeracao, e o proximo acesso protegido e GPIO0.

GPIO0-3 formam o bloco QUP SE1 e tambem sao reservados nos DTS de `sweet` e
`davinci`. Antes de ampliar a mascara por inferencia, a ROM stock completa foi
localizada em `C:\ProgramData\RSA\Download\RomFiles`. O overlay stock
`sdmmagpie-hanoip-common-overlay.dtsi`, presente no `dtbo.img`, contem:

```dts
qcom,tz_gpio {
	compatible = "qcom,tz_gpio";
	tlmm-tz = <0>, <1>, <2>, <3>;
};
```

O codigo Motorola em `kernel/power/user_sysfs_private.c` le `tlmm-tz` e marca
exatamente esses indices em `tz_configs[]`. Essa e a evidencia especifica do
hanoip: GPIO0-3 pertencem ao conjunto TrustZone; GPIO4-7 nao aparecem nele.

A lista especifica foi portanto corrigida para refletir a ROM stock:

```text
0, 1, 2, 3, -1
```

O range equivalente no DTS e `<0 4>`. GPIO4 nao deve ser mascarado
como TrustZone sem outra evidencia. Se o abort em GPIO4 voltar apos essa
correcao, ele deve ser investigado como problema separado de mapeamento/acesso
ao tile NORTH.

GPIO59-62 tambem foram removidos da reserva. A ROM stock habilita
`qupv3_se6_spi` com `status = "ok"` para o touchscreen Ilitek e usa GPIO59-62
como linhas SPI; portanto esses GPIOs sao propriedade normal do AP no hanoip.

A auditoria completa de `boot.img`, `vendor_boot.img`, `dtbo.img`, firmware,
memoria, PSCI, UFS, USB e display foi consolidada em:
`docs/kernel/auditoria-rom-stock-2026-08-20.md`.

O proximo teste usa as imagens `u-boot-hanoip-stock-tz-gpios.img` e
`kernel-mainline-hanoip-stock-tz-gpios-debug.img` no diretorio temporario do
OpenCode. Elas reservam somente GPIO0-3 e imprimem tile/offset/base antes do
primeiro acesso ao GPIO4.

Teste na placa concluido: o kernel passou pelo TLMM, chegou ao `/init`, encontrou
`/dev/fb0` e a tela ficou preta porque o script escreveu zeros deliberadamente
no framebuffer. Nao houve novo stack trace. O mapa stock GPIO0-3 esta validado
na pratica; GPIO4-7 e GPIO59-62 devem permanecer disponiveis.

Checkpoint reproduzivel, com nomes, hashes, bootargs e arquivos-fonte:
`docs/kernel/known-good-2026-08-20.md`.
