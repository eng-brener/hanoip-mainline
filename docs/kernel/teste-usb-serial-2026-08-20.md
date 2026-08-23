# Teste USB serial isolado - 2026-08-20

## Objetivo

Testar somente a enumeracao gadget serial e obter um shell BusyBox por
`ttyGS0`, sem misturar a alteracao experimental ICE/UFS e sem gravar particoes.

## U-Boot obrigatorio

Usar o checkpoint known good, cujo DTB ja passou pelo TLMM e mantem USB em
peripheral High-Speed com QUSB2:

```text
C:\Users\admin\AppData\Local\Temp\opencode\u-boot-hanoip-stock-tz-gpios.img
SHA256 fb6d4aa1da8f7c46f05e8ec830121f498faee36b3f08b05a9c1eb435f617c0a3
```

Nao usar `u-boot-hanoip-ufs-ice-fixed.img` neste teste. O kernel recebe o DTB
embutido do U-Boot por `boot_with_embedded_fdt=1`; assim a imagem USB isola a
mudanca de configuracao do kernel.

## Kernel USB

```text
C:\Users\admin\AppData\Local\Temp\opencode\kernel-mainline-hanoip-gserial-isolated.img
SHA256 a85ebfbc9879f567532091c80a13ca99cdf9e749ca0965cc300666aacdc5a15e
```

Configuracao extraida do `Image` empacotado:

```text
CONFIG_USB_G_SERIAL=y
CONFIG_U_SERIAL_CONSOLE=y
CONFIG_USB_U_SERIAL=y
CONFIG_USB_F_ACM=y
CONFIG_USB_F_SERIAL=y
CONFIG_USB_LIBCOMPOSITE=y
```

A configuracao anterior foi preservada em:

```text
work/kernel-config-before-gserial-20260820
SHA256 0052ced74abd5a65012901675523fbff251ee02926524a6c325412f4d320b788
```

## Initramfs

Fonte persistente:

```text
work/usb-serial-root-20260820/
work/usb-serial-root-20260820/init
```

CPIO gerado:

```text
/tmp/initramfs-hanoip-usb-serial.cpio.gz
SHA256 e41f3cff3177893acbc20601fb89dc650f5418bd61a87562047393713d7664e4
```

O `/init`:

- monta proc, sysfs e devtmpfs;
- aguarda `/dev/ttyGS0` sem timeout destrutivo;
- registra o progresso em `/dev/kmsg` a cada 10 segundos;
- configura 115200 baud;
- envia um banner;
- abre e reinicia um shell BusyBox em `ttyGS0`.

Nao ha escrita em block devices.

## Validacao do boot image

```text
Android boot header v2
page size 4096
kernel load address 0x00008000
ramdisk load address 0x04000000
DTB address 0x01f00000
```

Kernel e DTB extraidos foram comparados byte a byte com os artefatos
compilados. O initramfs passou em `gzip -t`, o `/init` empacotado foi revisado e
as strings `g_serial` estao presentes no `Image`.

## Procedimento

1. No fastboot Motorola, iniciar o U-Boot known good com `fastboot boot`.
2. Confirmar o fastboot interno como `????????????`.
3. Iniciar `kernel-mainline-hanoip-gserial-isolated.img` com `fastboot boot`.
4. Procurar um novo dispositivo na classe USB/Ports do Windows.
5. Nao esperar ADB; o gadget e CDC ACM/serial.
6. Se uma porta COM surgir, abrir em 115200 baud e pressionar Enter.

## Criterios

Sucesso: porta COM aparece, banner e shell respondem e o aparelho permanece
estavel por pelo menos dois minutos.

Falha controlada: nenhuma enumeracao, mas kernel/tela permanecem ativos.

Falha grave: reset, retorno ao bootloader ou novo stack trace. Nesse caso,
registrar o ultimo driver visivel antes de testar bind por configfs.
