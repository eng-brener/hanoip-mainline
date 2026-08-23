# Progresso 2026-08-13 (tarde) — pstore/ramoops: tática nova

## Objetivo

Resolver o item 4 (pstore/ramoops) para capturar o dmesg do kernel sem serial.

## Causa raiz do "não grava" (2 erros de leitura)

O setup do ramoops no DTB do U-Boot SEMPRE esteve correto (node `ramoops@9d800000`
+ bootargs `console=ramoops`), confirmado com `dtc` no
`sm7150-motorola-hanoip.dtb`. O teste antigo falhou por DOIS erros:

1. **Magic errado**: procurava `0xc35d4da5`, o real é `0x43474244` ("DBGC") =
   `PERSISTENT_RAM_SIG` (fs/pstore/ram_core.c).
2. **Endereço errado**: lia `0x9d800000` (zona **dmesg**, só escrita em panic).
   O log vivo vai para a zona **console** em `0x9d900000` (`console=ramoops`
   escreve continuamente durante o boot; `pstore_console` registrado com nome
   "ramoops" em fs/pstore/platform.c).

Layout (record 0x80000 x2 + console 0x100000 + pmsg 0x200000):
- `0x9d800000` dmesg[0..1] · `0x9d900000` **console** · `0x9da00000` pmsg

## Nova tática

Bootar o kernel estável -> deixar rodar -> warm reboot pro U-Boot ->
ler a zona console com o comando `pstore` do U-Boot (que JÁ existia no fork,
só precisava ser habilitado).

## Mudanças

- U-Boot: `build.sh` habilita `CONFIG_CMD_PSTORE` com os valores do hanoip:
  MEM_ADDR=0x9d800000, MEM_SIZE=0x400000, RECORD_SIZE=0x80000,
  CONSOLE_SIZE=0x100000, PMSG_SIZE=0x200000, FTRACE_SIZE=0, ECC_SIZE=0.
- `pack_kernel_osm.sh`: corrigido o path do mkbootimg (apontava para
  `uboot-sm7150/mkbootimg/mkbootimg` que não existia; agora `command -v mkbootimg`).
- Kernel: recompilado SEM g_serial (Image limpo; `gserial_driver` ausente no
  vmlinux — o antigo Image ainda tinha o legacy g_serial por objeto velho).

## Uso no device

```
fastboot boot work/kernel-mainline-hanoip-fixed2.img   # kernel estavel
# ... deixar ~30-60s rodar (grava o dmesg na zona console) ...
# warm reboot -> U-Boot -> enable fastboot
fastboot oem run:"pstore display console"   # imprime o dmesg do kernel
fastboot oem run:"pstore display"           # todos os records
fastboot oem run:"pstore display dump"      # so panics/oops
```

## Pendências

- [ ] Testar na placa: `pstore display console` deve mostrar o dmesg.
- [ ] Validar que a DRAM sobrevive ao warm reboot (se vazio, testar
      persistência escrevendo padrão no U-Boot e relendo).
- [ ] Com o dmesg em mãos: confirmar probe do LCDB (`qcom,pm6150l-lcdb`) = Gate 1.

## Artefatos

- `work/u-boot-hanoip-boot.img` (12:54) — U-Boot com comando `pstore`.
- `work/kernel-mainline-hanoip-fixed2.img` (13:00) — kernel estável (sem g_serial).

## RESULTADO DEFINITIVO (testes na placa, tarde)

O ramoops-através-de-reset **NÃO funciona neste device**. Testado empiricamente:

1. **Reset PSCI** (`fastboot oem run:"reset"`): DRAM apagada.
   - Padrão `0xDEADBEEF` em `0xa0000000` e `0x9dc00000` -> `0xFFFFFFFF` após reset.
2. **Watchdog bark** (kernel sem qcom-wdt + U-Boot sem `wdt_stop_all`): DRAM
   também apagada. `0x9d900000` ficou com dados estruturados aleatórios
   (`6f47c644...`), não o `DBGC` do ramoops.

Conclusão: o XBL re-inicializa a DDR em TODO boot (não há "warm reset" que
preserve DRAM). O `pstore` do U-Boot funciona (decode ok), mas é inútil para
log do kernel porque a DRAM não sobrevive ao reset.

## USB serial (g_serial) — também não resolveu

- `CONFIG_USB_G_SERIAL=y` + `console=ttyGS0` no bootargs do U-Boot.
- O gadget ENUMERA (VID 0x0525, COM3/COM4 aparecem), mas:
  - `usbser.sys` falha a instalação (ConfigFlags=32 FAILEDINSTALL), COM não abre.
  - Após re-plug, o gadget nem enumera mais ("Device Descriptor Request Failed",
    VID_0000). Confirma instabilidade do dwc3 gadget no kernel.
- IMPORTANTE: com `qcom-wdt=y` o g_serial NÃO crasha o kernel (estável) —
  o "crash em 10-30s" dos docs ERA o watchdog.

## Próximo caminho: gravar dmesg em armazenamento persistente (UFS)

Sem DRAM persistente e sem serial confiável, o caminho é o initramfs gravar o
`dmesg` num partição UFS (persistente) e o U-Boot ler depois via `load`/`ext4load`.

Estado dos artefatos:
- `work/u-boot-hanoip-boot.img` (14:20) — U-Boot com `pstore` + `wdt_stop_all` restaurado.
- `work/kernel-mainline-hanoip-fixed2.img` — kernel estável (qcom-wdt, SEM g_serial).
- `work/kernel-mainline-hanoip-stable.img` — backup do estável.
- `work/kernel-mainline-hanoip-wdtest.img` — kernel sem qcom-wdt (teste bark).

## SEGUNDA RODADA (final do dia): initramfs + UFS

### Confirmações importantes

- O **initramfs RODA** (o `init` do busybox executa; o `reboot -f` no final do
  script disparou o reboot sozinho). Isso confirma que o ramdisk do boot.img
  (header v2) é carregado e passado ao kernel corretamente pelo U-Boot.
- `boot_with_embedded_fdt` só afeta o DTB, NÃO o ramdisk.

### BLOQUEIO: a UFS NÃO probeia no kernel

- O init escreve marcadores em `/dev/sd?` (raw no offset do `misc`), mas NENHUM
  marcador caiu em nenhum LUN (checado via `scsi read` no U-Boot em LUN1/LUN4/LUN5).
- Ou seja: sem `/dev/sd*` no kernel => o driver UFS não probeiou.
- Dependências TODAS presentes no config:
  `SCSI_UFSHCD`, `SCSI_UFS_QCOM`, `BLK_DEV_SD`, `PHY_QCOM_QMP_UFS`,
  `SM_GCC_7150`, `QCOM_RPMH`, `QCOM_RPMHPD`, `QCOM_COMMAND_DB`(=y),
  `INTERCONNECT_QCOM_SM7150`, `SPMI`, `SMEM`, `SMD_RPM`, `QFPROM`.
- Node `ufshc@1d84000` no DTB do U-Boot está COMPLETO (7 clocks, resets,
  power-domains, interconnects, iommus, phys=qmp-ufs, ice, vcc/vccq2).

### Causa raiz do bloqueio (chicken-and-egg)

Sem dmesg não dá para saber POR QUE a UFS não probeia (clock? regulador? phy?
reset-gpio?). E sem UFS (ou serial USB) não há como capturar o dmesg.

### Caminhos possíveis (a decidir)

1. **Serial USB (configfs)**: o initramfs roda e o dwc3 funciona (o g_serial
   legacy chegou a enumerar VID 0x0525). Montar configfs no init e mandar o
   dmesg por ttyGS0. Antes "não enumerou", mas agora sabemos que o init roda.
2. **UART física (earlycon)**: bootargs tem `earlycon=msm_geni_serial,0xa88000`.
   Se houver ponto de teste UART, um adaptador resolve tudo.
3. **Debugar a UFS às cegas**: habilitar `CONFIG_UFSHCD` debug / `dyndbg` e
   bisectar o probe (lento, sem feedback).

### Artefatos

- `work/u-boot-hanoip-boot.img` — U-Boot com `pstore` + `wdt_stop_all` restaurado.
- `work/kernel-mainline-hanoip-ufstest.img` — kernel estável + initramfs que
  grava marcadores/dmesg na UFS (quando a UFS probeiar).
- `work/kernel-mainline-hanoip-stable.img` / `-wdtest.img` — backups.
- `work/ramdisk-hanoip-ufs.cpio.gz` — initramfs busybox (init em /tmp/rd/init).

## TERCEIRA RODADA: SSH/rede + confirmacao UFS

### Descoberta: o busybox so tinha symlinks parciais
- `dd`, `sync`, `grep`, `wc`, `reboot`, `ifconfig`, `httpd`, `telnetd` etc.
  NAO estavam symlinkados -> os testes anteriores de escrita na UFS usavam
  `dd` que falhava silenciosamente ("not found"). O "reboot" observado era
  na verdade o kernel panicando apos o init sair. Agora todos estao symlinkados.

### UFS: CONFIRMADO que nao probeia
- Teste com loop de 90s + `dd` funcional + `reboot -f` real: NENHUM marcador
  caiu em nenhum LUN. O init roda, mas `/dev/sd*` nao existe => o driver UFS
  nao probeia no kernel (deps todas presentes no config e node completo no DTB).

### USB: dwc3 gadget e FLAKY
- g_serial (legacy): ENUMEROU uma vez (VID 0x0525), mas usbser.sys falhou
  (ConfigFlags=32 FAILEDINSTALL) e o re-plug quebra a enumeracao.
- configfs NCM: nao enumerou (o dwc3 nem assumiu o USB, ficou no estado do U-Boot).
- g_ether RNDIS (legacy): o kernel crashou.

### Conclusao (chicken-and-egg confirmado)
Todos os caminhos de log (UFS, USB serial, USB rede) esbarram em driver do
kernel que precisa de dmesg para depurar. Sem dmesg, sem saida por software.

### Unica saida confiavel: UART fisica (earlycon)
O bootargs ja tem `earlycon=msm_geni_serial,0xa88000` e
`console=ttyMSM0,115200n8` (uart8). Um adaptador USB-UART 3.3V nos pontos de
teste da uart8 da acesso ao dmesg do kernel desde o early boot.

## QUARTA RODADA: debug da UFS (exaustivo, sem dmesg)

### O que foi verificado e esta OK
- Config UFS COMPLETA (SCSI_UFS_QCOM, PHY_QMP_UFS, SM_GCC_7150, RPMH/RPMHPD,
  COMMAND_DB, CLK_RPMH, GDSC, ICC_SM7150, SMMU, DMA, SCSI/SD, reguladores
  rpmh/spmi). Tudo compilado no vmlinux.
- DTS UFS = sunfish (reverti o override `resets=<&gcc...>` no PHY, que causava
  -EBUSY: o ufshcd usa get_optional("rst") no mesmo GCC reset e o PHY usa
  get_exclusive("ufsphy") -> conflito). Revertido no DTS do U-Boot E do kernel.
- cmd-db populado (magic 0x0c0330db em 0x85f20000), SMEM ok ($PRT em 0x86001000),
  reserved-memory completo (todas as regioes de firmware no-map).
- rpmhpd suporta sm7150; drivers gcc/clk-rpmh/rpmh-rsc compilados.

### O que NAO resolveu
- UFS continua sem probear (sem /dev/sd* -> marcadores nao caem no misc).
- dwc3 gadget flaky (g_serial enumera 1x, depois crasha/nao enumera).

### RAM nao sobrevive a NENHUM reset
- PSCI reset: DRAM -> 0xFF.
- Watchdog bark: DRAM -> 0xFF (o "6f47c644" de antes era o DEADBEEF parcial,
  nao o ramoops).
- Conclusao: ramoops/pstore-através-de-reset IMPOSSIVEL neste device.

### Referencia: fork sm7150-mainline
- PRs/issues nao tem nada de UFS (funciona em sunfish/davinci/surya).
- O port do hanoip (via U-Boot) e o unico com esse problema => algo no fluxo
  de boot (U-Boot vs ABL) OU uma peca do port antigo (deletado) que falta.

### BLOQUEIO: precisa de dmesg (chicken-and-egg)
Sem UART fisico, sem ramoops, sem USB confiavel -> nao da para ver o erro do
probe da UFS. Unico desbloqueio real:
1. UART fisico (gpio44 TX, gpio45 RX, 115200) -> adaptador USB-UART ~R$30.
2. OU trazer o display (DRM/MSM + painel + LCDB + WLED) para ver o log na tela
   (fbcon) - caminho da Fase 3 do plano.

### Estado restaurado
- U-Boot: wdt_stop_all restaurado. Kernel: qcom-wdt reabilitado.
