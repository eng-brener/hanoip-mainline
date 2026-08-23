# Known good do bring-up - 2026-08-20

## Resultado confirmado na placa

O Moto G60/G40 Fusion (`hanoip`) iniciou o U-Boot por `fastboot boot` e depois
iniciou o kernel mainline pelo fastboot interno do U-Boot, sem gravar nenhuma
particao.

O kernel:

- passou pelo probe do TLMM sem synchronous external abort;
- chegou ao `/init` do initramfs;
- criou `/dev/fb0`;
- mostrou as mensagens do initramfs;
- ficou com a tela preta porque o `/init` escreveu zeros deliberadamente no
  framebuffer;
- permaneceu no loop do initramfs, sem novo stack trace ou reset observado.

## Imagens known good

U-Boot com DTB stock-validado:

```text
C:\Users\admin\AppData\Local\Temp\opencode\u-boot-hanoip-stock-tz-gpios.img
SHA256 fb6d4aa1da8f7c46f05e8ec830121f498faee36b3f08b05a9c1eb435f617c0a3
```

Kernel que chegou ao initramfs e confirmou `/dev/fb0`:

```text
C:\Users\admin\AppData\Local\Temp\opencode\kernel-mainline-hanoip-stock-tz-gpios-debug.img
SHA256 8b801bcc98d4fb9394c4a9e44c59547dedd5d60e271580c5fa1cf04b4d78b821
```

Copias geradas pelos scripts no workspace, sobrescritas em builds futuros:

```text
work/u-boot-hanoip-boot.img
work/kernel-mainline-hanoip-initrd.img
```

As imagens com nomes em `C:\Users\admin\AppData\Local\Temp\opencode` sao os
artefatos preservados deste checkpoint e nao devem ser sobrescritas.

## Comandos usados

No fastboot Motorola, serial `ZF523QJBSG`:

```text
fastboot -s ZF523QJBSG boot u-boot-hanoip-stock-tz-gpios.img
```

No fastboot interno do U-Boot, serial `????????????`:

```text
fastboot boot kernel-mainline-hanoip-stock-tz-gpios-debug.img
```

## Configuracao TLMM validada

A ROM stock declara somente GPIO0-3 em `tlmm-tz`. A configuracao que passou na
placa e:

```dts
compatible = "motorola,hanoip-tlmm", "qcom,sm7150-tlmm";
gpio-reserved-ranges = <0 4>;
```

Dados do driver:

```text
reserved_gpios = { 0, 1, 2, 3, -1 }
ngpios = 119
```

GPIO59-62 permanecem disponiveis porque o stock os usa no SPI SE6 do
touchscreen Ilitek. GPIO4-7 tambem nao pertencem ao mapa TrustZone stock.

## Bootargs validados

O DTB efetivo vem do U-Boot por `boot_with_embedded_fdt=1`. Bootargs usados no
checkpoint:

```text
earlycon=msm_geni_serial,0xa88000
console=ttyMSM0,115200n8 console=ttyGS0 console=tty1 console=ramoops
loglevel=8 ignore_loglevel
panic_on_oops=0 panic=-1 pause_on_oops=30
pstore.backend=ramoops clk_ignore_unused
maxcpus=6 cpuidle.off=1 cpufreq.off=1 idle=poll
```

## Empacotamento validado

Kernel boot image:

```text
Android boot header v2
page size 4096
kernel load address 0x00008000
ramdisk load address 0x04000000
DTB address 0x01f00000
```

O payload do boot image foi comparado com `Image.gz`, e o DTB extraido foi
comparado com o DTB compilado. Ambos eram identicos.

## Arquivos-fonte relevantes

```text
kernel-mainline/drivers/pinctrl/qcom/pinctrl-sm7150.c
kernel-mainline/drivers/pinctrl/qcom/pinctrl-msm.c
kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts
uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts
uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150.dtsi
pack_kernel_initrd.sh
build.sh
```

O kernel known good ainda contem uma mensagem diagnostica temporaria antes da
leitura de GPIO4 em `pinctrl-msm.c`. Ela nao altera o acesso; apenas imprime
tile, offset e base.

## Initramfs do checkpoint

Arquivo empacotado:

```text
/tmp/initramfs-hanoip.cpio.gz
```

O `/init` monta proc/sys/devtmpfs, confirma `/dev/fb0`, escreve preto no
framebuffer e entra em loop. A tela preta e comportamento intencional desse
script, nao falha de display.

## Referencias

- Auditoria completa da ROM stock:
  `docs/kernel/auditoria-rom-stock-2026-08-20.md`
- Cronologia do bring-up:
  `docs/kernel/progresso-2026-08-20.md`
- Estado resumido:
  `docs/kernel/estado.md`

## Proxima etapa

Criar um novo initramfs diagnostico sem limpar o framebuffer. Ele deve exibir
periodicamente uptime, dispositivos block/UFS, GPIO, input, reguladores e as
ultimas linhas do dmesg. As duas imagens acima permanecem como rollback known
good.

## Imagem diagnostica de storage

A proxima imagem foi criada sem sobrescrever o checkpoint known good:

```text
C:\Users\admin\AppData\Local\Temp\opencode\kernel-mainline-hanoip-storage-diagnostic.img
SHA256 cd6f0017c31083b1028b5444c06944e4bec1ade0903b348c80dc2bab5153a050
```

Fonte persistente do initramfs:

```text
work/diagnostic-root-20260820/
work/diagnostic-root-20260820/init
```

Arquivo CPIO gerado:

```text
/tmp/initramfs-hanoip-diagnostic.cpio.gz
SHA256 e419e7e8237dfd5c68aeb5bfde2c35bfd91a7607d02a66033a2234157cdad554
```

O painel alterna a cada 8 segundos entre:

1. framebuffer, block devices e input;
2. mensagens UFS/SCSI/storage;
3. gpiochips, quantidade de reguladores e erros de probe.

Ele apenas le `/proc`, `/sys`, `/dev` e `dmesg`; nao grava em discos nem limpa
o framebuffer. O kernel e o DTB extraidos do boot image foram comparados com os
artefatos compilados e sao identicos. Header v2, page size 4096, ramdisk em
`0x04000000` e DTB em `0x01f00000` tambem foram confirmados.
