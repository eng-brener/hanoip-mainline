# U-Boot + Kernel Mainline para Motorola Moto G60 (hanoip / SM7150)

Port do U-Boot mainline (fork sm7150-mainline/u-boot) e kernel Linux mainline
(fork sm7150-mainline/linux) para o Moto G60 (codename `hanoip`,
SoC Qualcomm Snapdragon 730G / `sm7150` / `sdmmagpie`).

## 📚 DOCUMENTAÇÃO COMPLETA EM `docs/`

**LEIA `docs/README.md` PRIMEIRO** — documenta tudo: estado atual do U-Boot
e kernel, como compilar, como flashar, como bootar, hardware, e segurança.

```
docs/
├── README.md          ← comece por aqui (índice geral + estado)
├── uboot/
│   ├── estado.md      ← U-Boot funcional + watchdog fix (2026-08-13)
│   ├── build.md       ← como compilar
│   ├── flash.md       ← como flashar/instalar
│   ├── boot.md        ← como bootar/testar
│   └── hardware.md    ← SoC, partições, UFS multi-LUN, RAM
├── kernel/
│   ├── estado.md      ← kernel em andamento + causa raiz do reset
│   ├── build.md       ← como compilar
│   ├── boot.md        ← como bootar e debugar
│   ├── dts.md         ← DTS do hanoip
│   ├── progresso-2026-08-13.md ← LCDB + watchdog + DTB embutido do U-Boot
│   └── pm6150l-lcdb-known-good.md ← mapa de registros do LCDB PM6150L
├── scripts/
│   └── README.md      ← referência de todos os scripts
└── seguranca/
    └── README.md      ← como recuperar, o que NÃO fazer
```

## Status resumido (2026-08-13)

- **U-Boot: ✅ FUNCIONAL** (persistente no slot A, fastboot, UFS multi-LUN)
  + watchdog do boot parado antes do handoff ao kernel (`wdt_stop_all()`)
- **Kernel mainline: 🔧 EM ANDAMENTO** — boota (tela cinza) mas reiniciava
  a cada ~30s (CAUSA RAIZ: watchdog do boot; fix no U-Boot aplicado, validação
  pendente). Driver LCDB PM6150L (skeleton read-only) compilado.
- ⚠️ **DESCOBERTA CRÍTICA**: via `fastboot boot`, o kernel usa o **DTB
  embutido do U-Boot** (`boot_with_embedded_fdt`), não o DTB do boot.img do
  kernel. Editar o DTS do U-Boot para bootargs/ramoops valerem.

## Arquivos

- `uboot-sm7150/` - fork do U-Boot (branch tauchgang) com DTS do hanoip
- `kernel-mainline/` - fork do kernel mainline (branch v7.2) com DTS do hanoip
- `dump/` - dumps das partições do device
- `rom_stock/` - ROM stock Motorola (Android 12, para recuperação)
- `pmaports2/` - pmaports (config do kernel, device packages)
- `docs/` - documentação completa
- `work/` - artefatos (boot.img, dtb, etc)
- `build.sh` - script reproduzível de build do U-Boot

## Status: U-BOOT FUNCIONAL (persistente no slot A)

O U-Boot é o **bootloader ativo do device** (flashado no slot A). Boota de
forma persistente, com fastboot, UFS multi-LUN, display, bootmenu e console
USB serial.

## Funcionalidades validadas

- **Boot persistente**: U-Boot flashado na partição `boot_a`, boota sem
  depender de `fastboot boot`.
- **Fastboot funcional**: `product: motorola-hanoip`, version 0.4.
- **Flash UFS multi-LUN**: `fastboot flash boot_a/vendor_boot_a/dtbo_a`
  funciona (o hanoip divide as partições entre LUNs: LUN1=super/userdata,
  LUN4=partições _a, LUN5=partições _b).
- **Display + bootmenu**: logo do U-Boot, menu com navegação por botões.
- **Console limpo**: avisos de boot corrigidos (UFS reset, ref_clk, GENI).
- **Bootstd**: escaneia os devices UFS (bootflow scan).
- **Watchdog**: parado antes do kernel (`wdt_stop_all` em board_preboot_os
  e fastboot_boot) — 2026-08-13.

## Arquivos

- `uboot-sm7150/` - fork do U-Boot (branch tauchgang) com o DTS do hanoip
- `dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts` - DTS do device (U-Boot)
- `dump/` - dumps das partições do device (boot/vendor_boot/super/GPT/fw)
- `rom_stock/` - ROM stock Motorola (Android 12, para recuperação)
- `kernel-src/` - kernel source (downstream Motorola 4.14) do usuário
- `work/` - artefatos (boot.img, dtb, etc)
- `build.sh` - script reproduzível de build + empacotamento

## Commits do port (no fork)

1. `dts: qcom: sm7150: add Motorola Moto G60 (hanoip) support`
2. `fastboot: support UFS multi-LUN storage (Qualcomm SM7150)`
3. `dts: hanoip: silence boot warnings (UFS reset/ref_clk, GENI)`
4. `qcom: boot kernel with the U-Boot embedded FDT via fastboot`

## Como o boot funciona

O ABL (Android Bootloader stock do Moto) carrega o U-Boot como payload do
`boot.img` (header v3). O U-Boot roda no lugar do kernel e usa o DTB embutido
(CONFIG_OF_EMBED). No slot A, o U-Boot é persistente.

**IMPORTANTE (2026-08-13):** com `boot_with_embedded_fdt=1`, o kernel usa o
DTB embutido do U-Boot. Para bootargs/ramoops do kernel valerem, editar o
DTS do U-Boot (`uboot-sm7150/dts/.../sm7150-motorola-hanoip.dts`).

Para flashar o U-Boot no slot A (via fastboot do U-Boot):
```
fastboot flash boot_a work/u-boot-hanoip-boot.img
```

Para testar sem gravar:
```
fastboot boot work/u-boot-hanoip-boot.img
```

## Lições do port (o que quebrou)

1. **Memória RAM**: o `/memory` NÃO pode ser 4GB cheio. O device tem
   `0x80000000` até `0x17dd00000` (size `0xfdd00000`, ~3.96GB). Os últimos
   ~35MB são reservados para firmware. Declarar 4GB (`0x100000000`) faz o
   U-Boot relocar para memória inexistente e crashar no `dm_init_and_scan`.

2. **OF_EMBED vs OF_SEPARATE**: com `OF_SEPARATE` + header v3, o ABL
   descomprime o gzip do kernel mas o DTB appended (fora do gzip) se perde,
   deixando o internal FDT inválido. O U-Boot então usa o DTB stock do
   vendor_boot (cheio de nós downstream) que crasha no `dm_scan`.
   Com `CONFIG_OF_EMBED` o DTB fica dentro do binário e sempre é usado.

3. **VID/PID USB**: o U-Boot default usa `0x0/0x0` que o Windows não
   reconhece. Definir `USB_GADGET_VENDOR_NUM=0x18D1` / `PRODUCT_NUM=0x4EE0`
   (Google) faz o fastboot funcionar.

4. **UFS multi-LUN**: o fastboot do U-Boot assume um único device MMC. No
   hanoip (UFS), as partições estão espalhadas por LUNs. O `fb_mmc.c` foi
   modificado para iterar todos os devices SCSI até achar a partição.

5. **Watchdog do boot (2026-08-13)**: o U-Boot inicia o WDT (`AUTOSTART`,
   30s). Ao entregar ao kernel, não o alimenta → reset em 30s. Fix:
   `wdt_stop_all()` antes do handoff.

## Próximos passos

- Validar o fix do watchdog (kernel deve ficar estável sem reset de 30s)
- Ler dmesg (ramoops agora configurado) → confirmar o probe do LCDB
- Port completo do driver LCDB PM6150L (voltage + enable + VREG_OK)
- Driver de painel (avdd/avee reais), DSC, WLED, 60/90/120Hz