# Referência: klockmt/hanoip-pmos (lido em 26/10/2026)

<https://github.com/klockmt/hanoip-pmos> — outro port do postmarketOS para o
mesmo aparelho (Moto G60, XT2135-1, LATAM/retbr), GPL-2.0-only, 67 commits,
último em 24/10/2026. Objetivo deles: servidor headless.

## Estado deles (24/10)

- **Kernel downstream 4.14** (cool585 "Cybertron" v18, commit b92cb6cd):
  funciona, pmOS edge + OpenRC, SSH por USB, rootfs de 104 GB na `userdata`,
  nftables. **Flasheado** em `boot_b`/`vendor_boot_b`/`userdata` (o
  aparelho deles roda LineageOS 22.1 no slot b; o nosso é Android 11 stock,
  slot a).
- **Wi-Fi: não funciona** no 4.14 (firmware WLAN cai 0,7 s depois de
  conectar ao `icnss`, "EX:kernel:0x0:tmr_slave1:0x1d1").
- **Mainline: nunca bootou.** Testaram 6.6-rc1, 6.13.4 e 7.1_rc3 e o U-Boot
  do fork; tudo resetava. Concluíram que o ABL só executa imagens com
  cabeçalho **v3** (testes v0 eram inválidos) e que o `EFI_ZBOOT` da config
  do pmOS gerava `vmlinuz.efi`, que o ABL não carrega.

Comparação: o nosso port já resolveu o caminho mainline (U-Boot volátil com
cabeçalho v3 via `pack_uboot_v3` + kernel por `fastboot boot` do U-Boot),
com Plasma, display, touch, Wi-Fi, BT, áudio, Venus etc. no 7.3. O que eles
documentam pode ajudar a eles (e a quem for upstreamar) mais do que a nós.

## O que serve para nós

1. **Contador de tentativas A/B** (achado deles, importante): cada boot de
   um slot nunca marcado como "successful" gasta uma tentativa; depois de ~7
   o ABL marca `unbootable=yes` e troca o slot ativo. No nosso caso o slot A
   é marcado pelo Android quando ele sobe; não sabemos se `fastboot boot`
   conta tentativa. **Conferir só lendo** (sem gravar nada), da próxima vez
   que o aparelho estiver no fastboot da Motorola:
   `fastboot getvar slot-retry-count:a`, `slot-successful:a`,
   `slot-unbootable:a`, `current-slot`. (Trocar slot é proibido aqui.)
2. **Reboot direto para o bootloader**: eles usam a syscall
   `reboot(RESTART2, "bootloader")`. O nosso `/sbin/reboot` às vezes cai no
   Android, às vezes no fastboot — isso pode tornar o retorno previsível.
3. **ABL troca todo `console=` por `console=null`** na cmdline (com o
   kernel bootado direto pelo ABL). No nosso caminho o U-Boot monta a
   cmdline, mas vale saber.
4. **Ramdisk direto pelo ABL precisa ser LZ4 legacy** (`lz4 -l`); gzip/zstd
   travam no logo. Não nos afeta (o U-Boot carrega o nosso), só se um dia
   bootarmos o kernel sem U-Boot.
5. **Splash framebuffer**: `cont_splash_region` em `0x9c000000`, 1080x2460,
   32 bpp, stride 4320, bytes BGRA — o mesmo buffer que mapeamos no MSM.
6. **UART**: `ttyMSM0` no GPIO44 (TX)/45 (RX), `qup12`, 1,8 V, 115200 —
   igual ao nosso earlycon `msm_geni_serial,0xa88000`.
7. **board-id** do hanoip `<0x4c 0xb200>` vem de um dos 3 overlays do `dtbo`
   (os outros `0xb100`, `0xa100`); msm-id `0x16d` (soc_id 365).
8. Transferências grandes pela rede USB NCM derrubavam a rede deles no 4.14
   (limitam com `pv -L 1m`); no nosso mainline isso não apareceu.
9. Eles também guardam os dados do aparelho sem identificadores (MAC e
   serial mascarados) — mesma regra que a nossa.

Já temos: `FW_LOADER_USER_HELPER` desligado (eles ganharam minutos de boot
ao desligá-lo), pstore/ramoops, firmware fora do repositório.
