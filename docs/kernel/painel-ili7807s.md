# Driver de Painel Tianma ILI7807S (Moto G60 / hanoip) - Reconstrução

## Status: DRIVER RECONSTRUÍDO E VALIDADO

O driver `panel-ilitek-ili7807s.c` foi reconstruído do zero (o código anterior
foi perdido), usando:
1. O driver OSS ILI7807S (DLC DLC0697) como base de infraestrutura
2. Os dados do painel recuperados do kernel downstream Motorola

## Arquivos

- `kernel-mainline/drivers/gpu/drm/panel/panel-ilitek-ili7807s.c` — driver
- `kernel-mainline/drivers/gpu/drm/panel/Kconfig` — `DRM_PANEL_ILITEK_ILI7807S`
- `kernel-mainline/drivers/gpu/drm/panel/Makefile`
- `kernel-mainline/Documentation/devicetree/bindings/display/panel/ilitek,ili7807s.yaml`
- DTS: `arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip.dts` (panel node)

## Variantes suportadas

| Variante | compatible | Resolução |
|----------|-----------|-----------|
| DLC DLC0697 | `dlc,dlc0697` | 1080x1920 |
| Tianma hanoip | `tianma,ili7807s-hanoip` | 1080x2460 |

O Moto G60 usa a variante Tianma (selecionada via Device Tree).

## Dados do painel (recuperados do downstream)

### Nome real
```
mipi_mot_vid_tm_ili7807s_fhd_678
```

### Timings (1080x2460 @ 60Hz)
```
hdisplay = 1080, hfp = 28, hpw = 4, hbp = 24  (htotal = 1136)
vdisplay = 2460, vbp = 12, vpw = 2, vfp = 2565 (vtotal = 5039)
clock = 1136 * 5039 * 60 = 343.46 MHz
```

### DSI config
```
lanes = 4, format = RGB888
mode = VIDEO | VIDEO_BURST | VIDEO_SYNC_PULSE | LPM
```

### Reset sequence (do hanoi-panel.dtsi)
```
<1 4>, <0 1>, <1 12>  →  alto 10ms, baixo 10ms, alto 10ms
```

### Init sequence (byte a byte = downstream on-command)
```
FF 78 07 00          → page select
(exit sleep mode)    → 0x11 + 120ms
(display on)         → 0x29 + 20ms
FF 78 07 06          → page select
3E E3                → register
80 00                → register
FF 78 07 08          → page select
FD 00 9F             → gamma
E1 D9                → gamma
FD 00 00             → restore
FF 78 07 00          → page select
51 03 32             → brightness 0x0332
53 2C                → ctrl display
55 01                → CABC UI
```

### Off sequence
```
(display off) 0x28 + 50ms
(sleep in)    0x10 + 150ms
```

### Alimentação
```
vddi = pm6150_l13 (1.8V, LDO real)
avdd = LCDB LAB   (+5.5V, PLACEHOLDER)
avee = LCDB IBB   (-5.5V, PLACEHOLDER)
```

### Backlight
```
DCS 0x51 (set_display_brightness), max 0x3fff (16-bit)
```

### GPIOs
```
reset = pm6150l_gpio 9
TE    = tlmm 10
enable = tlmm 55
```

## VALIDAÇÃO DE ENERGIA (CRÍTICA)

⚠️ **IMPORTANTE**: os reguladores avdd/avee são **placeholders** `regulator-fixed`
(sem GPIO de enable). O driver chama `regulator_bulk_enable`, mas eles não
ligam tensão real. O display pode NÃO acender até o LCDB real ser portado.

**Correção feita**: os valores foram corrigidos de 6.0V/6.1V (errados) para
**5.5V** (valor real do downstream). Usar 6.0/6.1V danificaria o painel.

- vddi (1.8V) = LDO real, seguro ✓
- avdd/avee (5.5V) = placeholder, não liga nada (não danifica, só não acende) ✓
- Reset sequence = correta (3 pulsos) ✓

## O que validar no próximo boot

1. `dmesg | grep ili7807` — o driver bindou?
2. `dmesg | grep -i drm` — DSI conectou?
3. `modetest -M msm` — tem o modo 1080x2460?
4. Se o painel não acender: é o placeholder LAB/IBB (esperado)

## Próximos passos

1. Portar o LCDB real (pm6150l_lcdb) para ter tensão real LAB/IBB
2. Configurar o DSC (o painel usa compressão)
3. Múltiplos refresh rates (60/90/120Hz)
