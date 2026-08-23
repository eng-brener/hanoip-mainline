# Sessão 2026-08-13 (continuação) — Kernel ESTÁVEL + descobertas finais

## ESTADO FINAL CONFIRMADO (importante para próximas sessões)

### KERNEL ESTÁVEL (NÃO reseta) — CONFIGURAÇÃO CORRETA:

```ini
CONFIG_WATCHDOG=y
CONFIG_QCOM_WDT=y
CONFIG_WATCHDOG_HANDLE_BOOT_ENABLED=y
# CONFIG_DRM_MSM is not set
# CONFIG_DRM_PANEL_ILITEK_ILI7807S is not set
# CONFIG_USB_G_SERIAL is not set
CONFIG_REGULATOR_QCOM_LCDB=y
```

- Com essa config o kernel fica **ESTÁVEL na tela cinza** (não reinicia)
- O qcom-wdt do kernel alimenta o WDT do boot (via WDOG_HW_RUNNING)
- SEM qcom-wdt no kernel → reseta em ~30s (WDT do U-Boot não é alimentado)
- O hook wdt_stop_all do U-Boot **NÃO é suficiente** sozinho

### O que o g_serial CAUSOU (teste 11:50):

- O gadget USB **FUNCIONOU**: VID 0x0525 (NetChip) apareceu no Windows como
  "USB Composite Device" + COM3 + COM4 + RNDIS + UsbNcm
- MAS o kernel reiniciou em ~10-30s com g_serial — o gadget legacy
  (drivers/usb/gadget/legacy/serial.c) é instável nesse dwc3
- NÃO usar g_serial para o serial console

## DTB do U-Boot — o que vale (CRÍTICO, reafirmado)

O kernel usa o **DTB embutido do U-Boot** (boot_with_embedded_fdt=1).
Mudanças no DTS do kernel mainline NÃO têm efeito via fastboot boot.

### U-Boot atual (work/u-boot-hanoip-boot.img, 10:37) CONTÉM:
- ✅ Node `lcdb@ec00` (pm6150l_lcdb) — ADICIONADO ao pm6150l.dtsi do U-Boot
- ✅ Bootargs: `console=ramoops panic_on_oops=1 panic=5 pstore.backend=ramoops`
- ✅ `dr_mode = "peripheral"` (sem usb-role-switch)
- ✅ Hooks wdt_stop_all (board_preboot_os + fastboot_boot)
- ✅ Painel tianma,ili7807s-hanoip

### ATENÇÃO: O boot.img atual do kernel (11:53) TEM g_serial e RESETA.
Para o kernel estável, recompilar com USB_G_SERIAL desabilitado (config atual
já está correto) — basta recompilar Image.gz e reempacotar.

## USB serial — estado

- g_serial legacy: funciona (enumerou) mas crasha → NÃO usar
- configfs (ttyGS0): não enumerou (dwc3 role/configfs não resolveram)
- O problema do dwc3 gadget no kernel ainda NÃO está resolvido
- Caminho futuro possível: investigar por que o g_serial crasha, ou usar
  configfs com o timing correto, ou investigar o extcon/role do dwc3-qcom

## LCDB — estado

- Driver compilado (CONFIG_REGULATOR_QCOM_LCDB=y)
- Node no DTB do U-Boot ✅ (adicionado)
- Bind: NÃO confirmado ainda (falta ler o dmesg)
- O próximo passo (Gate 1 validar): ler o log do LCDB no dmesg para confirmar
  o probe e ver o estado dos registros

## Pstore/ramoops — estado

- Configurado no bootargs (console=ramoops) mas **não grava**
- O ramoops em 0x9d800000 não mostra o magic do pstore (0xc35d4da5)
- Investigação pendente: por que o pstore/ramoops não bind no kernel

## Regra de segurança (reafirmada)

SEMPRE validar no fastboot Motorola:
1. current-slot = a
2. slot-unbootable:_a = no
3. Se não: set_active a + oem fb_mode_clear

## Próximos passos (sessão futura)

1. Recompilar kernel SEM g_serial (config já correto) → kernel estável
2. Resolver o USB serial (ou outra via de log) para ler o dmesg
3. Confirmar o bind do LCDB (Gate 1) + ler estado dos registros
4. Resolver o pstore/ramoops (para capturar crashes)
5. Gate 2: voltage programming do LCDB