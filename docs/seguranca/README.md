# Segurança - Recuperação e CUIDADOS

> **LEIA ANTES DE MEXER NO DEVICE**

## O que NÃO fazer

1. **NÃO flashar o `gpt.bin` nem usar o `oem format`** — isso reescreve a
   tabela de partições e pode brickar (perder partições).
2. **NÃO apagar/sobrescrever partições críticas**: `xbl`, `abl`, `tz`,
   `hyp`, `aop`, `uefivarstore`, `persist` — são firmware assinado ou dados
   de calibração. Perdê-los = brick ou problemas graves.
3. **NÃO flashar a ROM stock (Android 12) por cima do Android 14 custom**
   sem saber o que está fazendo — mistura de versões pode não bootar.
4. **NÃO usar `fastboot erase userdata`** sem querer perder todos os dados.
5. **CUIDADO com slots**: flashar `boot` (sem sufixo) vs `boot_a`/`boot_b`.
   O host fastboot adiciona `_a` se o current-slot for a. Ver a nota abaixo.

## Nota sobre slots e nomes de partição

- O host fastboot (Windows) adiciona `_a` ao nome se o device reporta
  `current-slot: a` e a partição tem slot.
- O U-Boot reporta `current-slot: a` fixo (A/B não implementado).
- `fastboot flash boot_a` funciona (flash direto no LUN4).
- `fastboot flash boot` pode virar `boot_a_a` (bug do host) — usar nomes
  com sufixo explícito.

## Como recuperar (do que temos)

### Se o U-Boot não boota (preso no M)

1. Forçar fastboot do Motorola: segurar Volume Down + Power (ou o combo)
2. O slot B tem o Android original — `fastboot set_active b; fastboot reboot`
   deve voltar ao Android (se o slot B estiver intacto)

### Se o slot A está "unbootable" (U-Boot não boota)

```bash
# No fastboot do Motorola
fastboot set_active a
fastboot oem fb_mode_clear
fastboot reboot
```

### Re-flashar o U-Boot no slot A

```bash
# No fastboot do U-Boot
fastboot flash boot_a work/u-boot-hanoip-boot.img
```

### Restaurar boot original do slot A (Android)

```bash
# No fastboot do Motorola (dumps originais)
fastboot flash boot_a dump/boot_a.img
fastboot flash vendor_boot_a dump/vendor_boot_a.img
fastboot flash dtbo_a dump/dtbo_a.img
```

> Os dumps originais estão em `dump/`. A ROM stock em `rom_stock/`.

## Backups que temos

| Dado | Local |
|------|-------|
| GPT (4K sectors) | `dump/gpt_primary_4k.bin`, `gpt_backup_4k.bin` |
| boot_a/b | `dump/boot_a.img`, `dump/boot_b.img` |
| vendor_boot_a/b | `dump/vendor_boot_a.img`, `dump/vendor_boot_b.img` |
| dtbo_a/b | `dump/dtbo_a.img`, `dump/dtbo_b.img` |
| super (10GB) | `dump/super.img` |
| Todos os firmware | `dump/*.img` (abl, xbl, tz, hyp, modem, dsp, devcfg) |
| ROM stock completa | `rom_stock/` (Android 12) |
| GPT do LUN1 | `dump/gpt_primary_4k.bin` |

## Dados do device

- Model: XT2135-1 (Moto G60)
- Serial (adb): ZF523QJBSG
- Android 14 custom (kernel 4.14 Cybertron) no slot B
- U-Boot no slot A

## Endereços de memória importantes

| Endereço | O que é |
|----------|---------|
| `0x80000000` | RAM base |
| `0x17dd00000` | RAM fim (size 0xfdd00000) |
| `0x9c000000` | Framebuffer (cont_splash) |
| `0x1a000000` | fastboot buffer |
| `0xa88000` | UART8 (console GENI) |

## Regras de ouro

1. **Testar sempre com `fastboot boot`** (temporário) antes de `fastboot flash`
2. **Manter o slot B intacto** — é o seguro (Android original)
3. **Fazer backup antes de qualquer flash** (dumps já existem)
4. **Re-marcar slot após crash**: `fastboot set_active a; oem fb_mode_clear`
5. **Não mexer no GPT** (gpt.bin / oem format) — sem necessidade
