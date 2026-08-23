# U-Boot - Como bootar e testar

## Fastboot do U-Boot

O U-Boot oferece fastboot. Comandos úteis:

```bash
fastboot devices -l          # listar (aparece como "? fastboot")
fastboot getvar product      # -> motorola-hanoip
fastboot getvar version      # -> 0.4
fastboot getvar current-slot # -> a
fastboot getvar all          # todas as variáveis
```

## Boot do U-Boot (temporário)

```bash
fastboot boot work/u-boot-hanoip-boot.img
```

## Boot do kernel mainline (temporário)

```bash
fastboot boot work/kernel-mainline-hanoip-fixed2.img
```

## `oem run` — executar comandos U-Boot via fastboot

O comando usa **dois-pontos** (`:`), não espaço:

```bash
# CORRETO:
fastboot oem run:"echo teste"
fastboot oem run:"part list scsi 1"
fastboot oem run:"bootflow scan -lb"
fastboot oem run:"scsi scan; part list scsi 4"
fastboot oem run:"bdinfo"
fastboot oem run:"printenv"
fastboot oem run:"help"

# ERRADO (não funciona):
fastboot oem run "echo teste"
```

## `oem console` — ler o log do U-Boot

```bash
fastboot oem console
```

Lê o console record (log do boot). O buffer é pequeno (0x6000), então o log
inicial (UFS scan etc.) é lido primeiro.

## Bootmenu

Ao ligar (sem OS), o U-Boot cai no bootmenu:

```
*** U-Boot Boot Menu ***
1. Boot
2. Enable serial console gadget
3. Enable USB mass storage
4. Enable fastboot mode
5. Drop to shell
6. Reset device
7. Dump clocks
8. Dump environment
9. Board info
a. Dump bootargs
0. Exit
```

- Navegação: botões Volume Up/Down (touch não tem driver)
- Enter/Volume Down: selecionar
- Opção 4: ativa fastboot (a mais usada)
- Opção 2: ativa console serial USB (usbacm) — para debug via porta COM

## Endereços úteis

- DTB embutido do U-Boot: `0x17dbce870` (fdt_blob, muda por build)
- fastboot buffer: `0x1A000000` (CONFIG_FASTBOOT_BUF_ADDR)
- Framebuffer (cont_splash): `0x9c000000`
- RAM: `0x80000000` a `0x17dd00000`

## Boot de Linux (o que sabemos)

- O `fastboot boot` do U-Boot usa `bootm` (Android boot image)
- O kernel mainline arm64 precisa do DTB passado em x0
- O bootm Android lê o DTB do boot.img pela posição calculada com page_size
- **BUG**: os mkbootimg (Ubuntu e osm0sis) gravam page_size errado para
  header v2, então o DTB não é extraído → "Invalid FDT header"
- Correção manual: `fix_dtb2.py` (page_size=4096, dtb_size correto)
- Ver `docs/kernel/boot.md` para o estado atual

## Debug de drivers (estilo quadrados)

Se precisar debugar onde o U-Boot trava, o método usado foi:
- Escrever quadrados coloridos no framebuffer (0x9c000000)
- Chamar `dbg_square(x, y, w, h, r, g, b)` em pontos do board.c
- O framebuffer do ABL (cont_splash) é visível no display

Isso foi removido do código (build final limpo), mas a técnica está
documentada em `docs/kernel/debug.md` se precisar de novo.
