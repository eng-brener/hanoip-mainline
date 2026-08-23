# Progresso 2026-08-19 — dwc3/QCOM backports, usb_shutdown e USB serial

Sessão focada em desbloquear a leitura do dmesg do kernel (o "chicken-and-egg":
sem dmesg não dá pra saber por que UFS/USB/display falham, e sem UFS/USB/display
não dá pra capturar o dmesg).

---

## 1. Análise de base (onde estávamos)

- Repos base **sem atualizações** (confirmado via API GitHub + `git rev-parse`):
  - `sm7150-mainline/u-boot` (tauchgang) = `f8c04469e828` (Dez/2025)
  - `sm7150-mainline/linux` (v7.2) = `fd78d17954a8` (Jun/2026)
  - Nosso clone já está em cima de ambos; nada novo pra puxar.
- Mainline `u-boot/u-boot` (oficial) tem commits úteis de Jan–Jun/2026 que o
  fork NÃO tem. Backportamos 6 deles (ver seção 3).

## 2. Descoberta importante — `fixup_power_domains` NÃO afeta o kernel

`arch/arm/mach-snapdragon/of_fixup.c` tem `fixup_power_domains()` que remove
`power-domains` (referências ao rpmhpd) da **live tree do U-Boot** (via
`of_remove_property`). Isso é necessário porque o U-Boot **não tem driver
rpmhpd** (confirmado: `drivers/power/domain/` sem qcom/rpmhpd, sem
`CONFIG_QCOM_RPMHPD`).

O kernel, com `boot_with_embedded_fdt=1`, recebe `gd->fdt_blob` = **o FDT
embutido ORIGINAL** (flat), que **mantém os power-domains**. Ou seja: o kernel
**já recebe** os GDSCs/power-domains. Isso descarta a hipótese de que
UFS/USB/display falham por falta de power-domains no DT.

> ⚠️ NÃO portar o commit upstream `3fbd82eb67bd` ("Remove RPMH power domain DT
> fixup code") — ele depende do driver rpmhpd no U-Boot, que nosso fork não tem.
> Portar quebraria o boot do U-Boot.

## 3. Backports aplicados no U-Boot (fork uboot-sm7150)

6 commits do mainline `u-boot/u-boot`, aplicados via `git am -3` (patches do
`.patch` do GitHub), em cima do HEAD `bc21cf70709`:

| Commit (novo sha local) | Assunto |
|---|---|
| `fb4a39c22f6` | usb: dwc3: core: Add ip and version_type support from Linux |
| `cf6df23a825` | usb: dwc3: Increase DWC3 controller halt timeout |
| `c5c21fe8044` | usb: dwc3: gadget: Don't send unintended link state change |
| `366c0ae43ec` | usb: dwc3: core: improve reset sequence (DCTL.CSFTRST) |
| `05a43913632` | drivers: usb: dwc3: Add delay after core soft reset |
| `e45a63cb98a` | usb: dwc3: qcom: Add delays in UTMI clock selection (Qscratch) |

- **Pulado** `cc8195b13b12` (fix crash fastboot exit): no-op pra nós, o
  `free(evt)` que ele remove veio de um commit de abril/2026 que não temos.
- Build U-Boot OK (aviso `CONFIG_OF_EMBED` é o esperado do port).

## 4. Implementado: `usb_shutdown_for_kernel()` (U-Boot)

Em `arch/arm/mach-snapdragon/board.c`, nova função chamada no
`board_preboot_os()` (junto de `wdt_stop_all()` e `ufs_shutdown_for_kernel()`):

- Itera `UCLASS_USB_GADGET_GENERIC` (o dwc3 em modo peripheral — `dr_mode=peripheral`).
- `generic_phy_power_off()` + `generic_phy_exit()` no QUSB2 PHY (`usb2-phy`).
  O `qusb2phy_power_off` já faz `reset_assert(GCC_QUSB2PHY_PRIM_BCR)` + disable.
- `reset_assert(GCC_USB30_PRIM_BCR)` no glue (parent `qcom,dwc3`).
- Objetivo: entregar o dwc3/PHY "limpo" ao kernel (o U-Boot deixava o PHY
  calibrado do fastboot, e o kernel não recuperava). Mesmo princípio do
  `ufs_shutdown_for_kernel()`.

**Mudanças NÃO commitadas** no fork (board.c/fb_common.c/dts continuam assim):
- `board.c`: +`usb_shutdown_for_kernel()` (novo) + `ufs_shutdown_for_kernel()` +
  `board_preboot_os()` (wdt_stop_all + ufs + usb shutdown)
- `fb_common.c`: `wdt_stop_all()` antes do `do_bootm`
- `pm6150l.dtsi`: node `lcdb@ec00`
- `sm7150-motorola-hanoip.dts`: bootargs + painel

## 5. Validação na placa (A/B) — U-Boot novo está OK

| Combinação | Resultado |
|---|---|
| U-Boot novo + `fixed2.img` (Aug 15) | ❌ reset |
| U-Boot antigo (slot A) + `stable.img` (Aug 13) | ✅ estável |
| **U-Boot novo** + `stable.img` (Aug 13) | ✅ **estável** |

→ `usb_shutdown_for_kernel()` + commits dwc3 **não regrediram** nada.

## 6. DESCOBERTA: o "reset" do fixed2.img era o `reboot -f` do ramdisk

Desempacotamos os boot.imgs (script `unpack.py`, header v2):
- `stable.img`: kernel 12.7MB + **ramdisk vazio (127 bytes)**.
- `fixed2.img`: kernel 12.7MB + **ramdisk `ramdisk-hanoip-ufs.cpio.gz` (891KB)**.

O init desse ramdisk é um **ufstest**: loop 90s tentando gravar dmesg na UFS
(`/dev/sd?`, que nunca aparece pois UFS não probeia) e depois **`reboot -f`**.

→ O "reset a cada 30s" NÃO era watchdog nem panic: era o script se reiniciando.

## 7. Tentativa de USB serial via configfs (CRASHOU)

Criado `work/kernel-mainline-hanoip-usbserial.img`:
- Kernel: recompilado com `# CONFIG_USB_G_SERIAL is not set` (configfs limpo;
  `CONFIG_USB_CONFIGFS=y`, `CONFIG_USB_F_ACM=y`, `CONFIG_CONFIGFS_FS=y`,
  `CONFIG_QCOM_WDT=y` mantido). `Image` de 22:16 (29.2MB), `Image.gz` 12.1MB.
- Ramdisk: `work/ramdisk-hanoip-usbserial.cpio.gz` — init que monta configfs,
  cria gadget CDC ACM (VID 0x18D1/PID 0x4EE4, função `acm.usb0`), ativa UDC e
  manda `dmesg` pro `/dev/ttyGS0` a cada 10s.

**Resultado na placa: reset em <30s.** Provável **panic** no configfs ativando o
dwc3 gadget (consistente com "USB gadget é instável" dos docs). Não confirmado
(impossível ler o panic sem serial = o próprio chicken-and-egg).

## 8. DESCOBERTA: caminho do DISPLAY já está habilitado no kernel

O `.config` do kernel JÁ TEM:
```
CONFIG_VT=y
CONFIG_VT_CONSOLE=y
CONFIG_FB=y
CONFIG_FB_SIMPLE=y
CONFIG_FRAMEBUFFER_CONSOLE=y
CONFIG_FONT_8x16=y
CONFIG_DUMMY_CONSOLE=y
```
E o bootargs já tem `console=tty1`. O DTS do U-Boot tem o node
`framebuffer@9c000000` (`simple-framebuffer`, 1080x2460, `a8r8g8b8`).

→ O dmesg **deveria** aparecer na tela via fbcon. Caminho mais simples que USB
(que está crashando).

---

## ONDE PARAMOS

1. `usb_shutdown_for_kernel()` + 6 commits dwc3: **prontos e validados** (stable.img
   boota estável no U-Boot novo), mas ainda **não flashados** no slot A (só `fastboot boot`).
2. USB serial via configfs: **crashou** (reset <30s).
3. Display/fbcon: **já habilitado** no kernel, mas a "tela cinza" reportada sugere
   que o fbcon NÃO está mostrando texto — motivo desconhecido.
4. **Pergunta pendente (não respondida)**: na tela cinza do stable.img, tinha
   TEXTO/letras ou era cinza UNIFORME?

## PRÓXIMOS PASSOS (para amanhã)

1. **Responder a pergunta pendente**: a tela cinza tinha texto?
   - SIM → display funciona, ler o dmesg pela tela (ou capturar/fotografar).
   - NÃO (cinza uniforme) → debugar por que simplefb/fbcon não assume a tela
     (candidatos: simplefb não probeia, região cont-splash/reserved-memory,
     `console=tty1` não está pegando).
2. **Caminho display (recomendado)**: fazer o dmesg aparecer na tela. Se o
   simplefb não probeia, investigar o node `framebuffer@9c000000` e o
   reserved-memory `cont_splash_mem` (está SEM `no-map`).
3. **Caminho USB (alternativo)**: se quiser insistir no USB, o próximo passo é
   entender o panic do configfs (ex: testar g_serial legacy — que NÃO crasha
   segundo os docs — em vez de configfs; ou bootar o kernel novo com ramdisk
   VAZIO pra confirmar que o kernel novo em si é estável).
4. **UART física (plano B confiável)**: uart8, gpio44 TX / gpio45 RX, 115200,
   adaptador USB-UART 3.3V.
5. **Depois de ler o dmesg** (qualquer caminho): confirmar probe do LCDB
   (Gate 1), debugar UFS (por que não probeia), e seguir o plano do LCDB/display.

## OPERACIONAL (lições do ambiente — não esquecer)

- **Arquivos são do root**: git/make exigem `wsl.exe -d Ubuntu -u root`. O tool
  `edit` falha em arquivos do root (usar `write` em `/tmp` + script python como
  root, ou bash root direto).
- **PowerShell mangla `$var`** ao passar comandos pra `wsl.exe`. Usar caminhos
  completos, sem variáveis de shell (ex: `/usr/bin/mkbootimg` direto, não `$MKB`).
- **Fluxo de boot no device**: fastboot Motorola → `fastboot boot u-boot-hanoip-boot.img`
  → bootmenu → "Enable fastboot mode" → `fastboot boot kernel.img`.
- **Regra de segurança** (fastboot Motorola): `current-slot` = a e
  `slot-unbootable:_a` = no antes de qualquer coisa.
- **`boot_with_embedded_fdt=1`**: o kernel usa o DTB embutido do U-Boot, NÃO o
  DTB do boot.img do kernel. Mudanças no DTS do kernel NÃO valem via fastboot
  boot — editar o DTS do U-Boot.
- **mkbootimg osm0sis** exige `--dtb` (não aceita vazio) no header v2.

## ARTEFATOS

- `work/u-boot-hanoip-boot.img` — U-Boot novo (6 commits dwc3 + usb_shutdown + ufs_shutdown + wdt).
- `work/kernel-mainline-hanoip-usbserial.img` — kernel configfs ACM (crashou na placa).
- `work/ramdisk-hanoip-usbserial.cpio.gz` — init configfs ACM.
- `work/kernel-mainline-hanoip-stable.img` — kernel estável (ramdisk vazio).
- `work/kernel-mainline-hanoip-fixed2.img` — ufstest (init com `reboot -f`).
- `kernel-mainline/arch/arm64/boot/Image(.gz)` — kernel atual (g_serial OFF).
