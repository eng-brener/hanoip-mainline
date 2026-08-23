# Progresso 2026-08-13 — LCDB, watchdog e diagnóstico de reset

## Objetivo da sessão

Portar o driver LCDB real (PM6150L) para o kernel mainline e fazer o painel
ILI7807S funcionar em cold boot. Durante o caminho descobrimos a CAUSA RAIZ
do reset de ~30s que o kernel vinha sofrendo.

---

## DESCOBERTA CRÍTICA: o kernel usa o DTB embutido do U-Boot

O fix `boot_with_embedded_fdt=1` (commit `bc21cf70709`) faz o **kernel usar o
DTB embutido do U-Boot** (OF_EMBED), NÃO o DTB do boot.img do kernel!

Isso significa que:

- Todas as mudanças no DTS do kernel (`kernel-mainline/.../sm7150-motorola-hanoip.dts`)
  **NÃO são aplicadas** quando se boota via `fastboot boot`!
- O DTS que vale é o do U-Boot:
  `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`
- Bootargs, ramoops, dr_mode, etc. precisam ser alterados **no DTS do U-Boot**

### Consequências

1. `panic_on_oops`, `console=ramoops`, `pstore.backend` adicionados no DTS do
   kernel **nunca foram efetivos**.
2. `dr_mode="peripheral"` no DTS do kernel não fez efeito (o U-Boot DTS tinha `otg`).
3. O ramoops NÃO gravou o log porque o bootargs efetivo (do U-Boot) não tinha
   `console=ramoops`.

### Correção aplicada (U-Boot DTS)

```
bootargs = "earlycon=msm_geni_serial,0xa88000 console=ttyMSM0,115200n8
            console=ttyGS0 console=tty1 console=ramoops
            loglevel=8 ignore_loglevel
            panic_on_oops=1 panic=5 pstore.backend=ramoops";
```

---

## Causa raiz do reset de ~30s

### Sintomas observados

- Kernel boota (tela cinza = simple-framebuffer ativo)
- Reinicia sozinho após ~30s (~1min com config antigo)
- `panic_on_oops=1` NÃO mudou o comportamento (reset continua em 30s)
  → NÃO é panic/oops, é um reset de hardware

### Evidências

| Evidência | Detalhe |
|-----------|---------|
| Timing | ~30s = exatamente `CONFIG_WATCHDOG_TIMEOUT_MSECS=30000` do U-Boot |
| Registro | `md.l 17c10000` mostra `WDT_EN (0x8) = 1` |
| `wdt stop` manual | Zera WDT_EN=0 — comprovado via `md` |
| `panic_on_oops` | Sem efeito → não é panic |

### Mecanismo

O U-Boot inicia o WDT do boot (`CONFIG_WATCHDOG_AUTOSTART=y`, device
`watchdog@17c10000`) e o alimenta via cyclic. Quando entrega o controle ao
kernel, para de alimentar. O kernel (com `CONFIG_WATCHDOG=n` original) não
desliga nem alimenta → o WDT dispara após o timeout → reset.

### Solução aplicada (U-Boot)

Adicionado `wdt_stop_all()` antes do handoff:

1. `arch/arm/mach-snapdragon/board.c`: hook `board_preboot_os()` que chama
   `wdt_stop_all()` (chamado pelo `boot_selected_os`).
2. `drivers/fastboot/fb_common.c`: `wdt_stop_all()` DIRETO no
   `fastboot_boot()`, antes do `do_bootm()` — cobre o path do `fastboot boot`
   garantidamente.

```
/* drivers/fastboot/fb_common.c (antes do do_bootm) */
wdt_stop_all();
printf("QCOM fastboot: stopped watchdogs\n");
```

- `wdt stop` manual via `oem run` funciona: `md.l 17c10000 4` → `0x8 = 0`
- STATUS: aplicado, compilado, FLASHADO no slot A (aguardando validação)

---

## Driver LCDB PM6150L — Gate 1 (skeleton read-only) COMPLETO

### Arquivos criados/modificados

| Arquivo | O que é |
|---------|---------|
| `kernel-mainline/drivers/regulator/qcom-lcdb-regulator.c` | Skeleton read-only (probe + captura de estado, SEM escrita) |
| `kernel-mainline/drivers/regulator/Kconfig` | `REGULATOR_QCOM_LCDB` |
| `kernel-mainline/drivers/regulator/Makefile` | `qcom-lcdb-regulator.o` |
| `kernel-mainline/Documentation/devicetree/bindings/regulator/qcom,pm6150l-lcdb.yaml` | Binding novo |
| `kernel-mainline/arch/arm64/boot/dts/qcom/pm6150l.dtsi` | Node `regulator@ec00` (lcdb) com lab/ibb |
| `kernel-mainline/.../sm7150-motorola-hanoip.dts` | (mudanças feitas, MAS não efetivas via fastboot boot — usar U-Boot DTS) |

### Detalhes do driver

- Compatible: `qcom,pm6150l-lcdb`
- Regmap: `dev_get_regmap(pdev->dev.parent, NULL)` (SPMI do PMIC)
- Base: `0xec00`
- Lê no probe (SEM escrever):
  - `0x46` ENABLE_CTL1 (MODULE_EN, HWEN_RDY)
  - `0x45` MODULE_RDY
  - `0x10` INT_RT_STATUS (VREG_OK, SC_ERROR)
  - `0x71` LDO_OUTPUT_VOLTAGE (LAB)
  - `0x81` NCP_OUTPUT_VOLTAGE (IBB)
  - `0x41` BST_OUTPUT_VOLTAGE
- Loga o estado via `dev_info` (visível no dmesg)

### Registradores validados (downstream qpnp-lcdb-regulator.c)

```
Base 0xec00 (slave SPMI 5 do PM6150L)
0x10  INT_RT_STATUS   BIT0 VREG_OK, BIT1 SC_ERROR
0x41  BST_OUTPUT_VOLTAGE  6-bit, step 25mV, min 4700mV
0x45  MODULE_RDY      BIT7
0x46  ENABLE_CTL1     BIT7 MODULE_EN, BIT6 HWEN_RDY
0x71  LDO_OUTPUT_VOLTAGE (LAB)  GENMASK(4,0)
0x81  NCP_OUTPUT_VOLTAGE (IBB)  GENMASK(4,0)
0xD0  SEC_ACCESS      0xA5 unlock
```

### Voltage mapping (confirmado na branch Motorola)

```
if (mv < 4950)  val = (mv - 4000) / 100     # 100mV step
else            val = (mv - 4950) / 50 + 0xA # 50mV step, offset 0xA
```
- LDO/NCP range: 4000..6000 mV
- BST = max(LAB,IBB) + headroom 150mV (não-PM660L), step 25mV
- Alvos: LAB=5500mV, IBB=5500mV → BST≈5650mV (~5.65V)

### Config do kernel

```
CONFIG_REGULATOR_QCOM_LCDB=y
```

### STATUS

- Compila ✅
- Driver presente no Image (string `qcom,pm6150l-lcdb` no vmlinux) ✅
- TESTE NA PLACA: pendente — precisa do boot que agora para o watchdog

---

## Console USB serial (ttyGS0) — tentativa de ver logs

### O que foi feito

- Initramfs: script `init` que monta configfs, cria gadget `gser.usb0`
  (VID 0x18D1, PID 0x4EE2), liga o UDC, e imprime dmesg filtrado (LCDB/WDT/USB)
- Bootargs com `console=ttyGS0`
- Capturador serial Python (pyserial) rodando no WSL monitorando `/dev/ttyS*`
  (COM ports do Windows mapeadas)

### Resultado

- A COM port do gadget **NÃO apareceu** no Windows
- O capturador não abriu nenhuma porta nova
- Causa provável: dwc3 não entra em modo device no kernel (role switch),
  ou configfs falha, ou UDC não aparece

### Notas

- O U-Boot tem console serial gadget funcional (bootmenu opção 2, usbacm)
- Alternativa futura: ativar usbacm no U-Boot, bootar, e ver se o kernel
  herda o gadget (provável que não, pois reconfigura o dwc3)

---

## Initramfs (busybox)

- `/tmp/rd/` — extraído do boot.img (busybox aarch64 estático)
- Applets: sh, mount, cat, echo, ls, mkdir, touch, mknod, dmesg, poweroff, watchdog
- `init` atual: watchdog ping + configfs serial gadget + dmesg filtrado
- Re-empacotamento: `find . | cpio -o -H newc | gzip`

---

## Regra de segurança (fastboot Motorola)

**SEMPRE que o device estiver no fastboot da Motorola:**
1. `fastboot getvar current-slot` → deve ser `a`
2. `fastboot getvar slot-unbootable:_a` → deve ser `no`
3. Se não: `fastboot set_active a` + `fastboot oem fb_mode_clear`

---

## Próximos passos

1. Flashar o U-Boot corrigido (bootargs + watchdog stop) no slot A
2. Bootar o kernel → verificar que NÃO reseta em 30s
3. Ler o dmesg (via ramoops agora funcional OU serial) → confirmar o LCDB probe
4. Gate 2: implementar voltage programming no driver LCDB
5. Gate 3: enable com refcount + MODULE_EN + VREG_OK
6. Remover placeholders vreg_lab/vreg_ibb, apontar avdd/avee → lab/ibb
7. DSC, enable-gpio, WLED (fases seguintes)

## IMPORTANTE para as próximas sessões

**Ao mexer em DTS/bootargs do kernel mainline, lembrar:**
- Via `fastboot boot`, quem manda é o **DTB embutido do U-Boot**
- Editar `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`
  e recompilar o U-Boot
- O DTS do kernel (`kernel-mainline/.../hanoip.dts`) só vale se o U-Boot for
  mudado para usar o DTB do boot.img (ex: sem `boot_with_embedded_fdt`)
---

## ATUALIZACAO FINAL (mesma sessao, tarde)

### Descoberta definitiva do reset de ~30s

- O reset de ~30s e o **watchdog do boot** (qcom-wdt 30s timeout)
- **SOLUCAO CONFIRMADA**: `CONFIG_WATCHDOG=y` + `CONFIG_QCOM_WDT=y` no kernel
  -> o driver qcom-wdt do kernel alimenta o WDT (WDOG_HW_RUNNING) -> **kernel ESTAVEL**
- SEM qcom-wdt -> reseta (o hook wdt_stop_all do U-Boot nao basta sozinho)
- NAO e o painel, NAO e DRM, NAO e panic (confirmado por bisect: kernel sem
  painel/DRM tambem resetava ate habilitar qcom-wdt)

### Kernel ESTAVEL (config correta)

```
CONFIG_WATCHDOG=y
CONFIG_QCOM_WDT=y
# CONFIG_DRM_MSM is not set
# CONFIG_DRM_PANEL_ILITEK_ILI7807S is not set
CONFIG_REGULATOR_QCOM_LCDB=y
```

### g_serial — testado, enumerou mas crasha

- VID 0x0525 apareceu (COM3/COM4/RNDIS) -> o dwc3 gadget FUNCIONA
- Mas o g_serial legacy crasha o kernel em ~10-30s -> NAO usar
- Configfs serial (ttyGS0) nao enumerou

### LCDB node adicionado ao DTB do U-Boot

O pm6150l_lcdb (regulator@ec00) foi adicionado ao
uboot-sm7150/dts/upstream/src/arm64/qcom/pm6150l.dtsi -> o DTB embutido do
U-Boot agora tem o node -> driver LCDB pode bindar.

### Ver detalhes

docs/kernel/estado-2026-08-13-final.md — estado final completo.