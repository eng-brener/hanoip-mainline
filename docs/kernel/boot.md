# Kernel Mainline - Boot e Debug

## Como bootar o kernel (teste)

```bash
# 1. Ligar device → U-Boot → menu → "Enable fastboot mode"
# 2. Bootar o kernel (temporário):
fastboot boot work/kernel-mainline-hanoip-fixed2.img
```

O U-Boot processa o boot.img, imprime "Booting Android Image" e
"Starting kernel...", então passa o controle ao kernel.

## O problema do boot (o que foi descoberto)

O `fastboot boot` do U-Boot usa `bootm` (Android boot image). Para header v2,
o U-Boot extrai o DTB do boot.img **pela posição calculada**:
- `dtb_ptr = page_size + kernel + ramdisk + second + recovery_dtbo`
- Precisa do `page_size` correto e do `dtb_size` no header

**BUG encontrado**: os mkbootimg (Ubuntu e osm0sis) gravam `page_size=256`
(e `dtb_size=0`) no header v2, mesmo passando `--pagesize 4096`. Isso faz o
U-Boot calcular o `dtb_ptr` errado → "Invalid FDT header for index 0" → o
kernel recebe x0 inválido → crash precoce (tela cinza + reboot).

**Correção**: `fix_dtb2.py` ajusta o boot.img (page_size=4096, dtb_size
correto). Após a correção, o `dtb_ptr` bate com a posição real do DTB.

## Estado do teste (pendente)

- [ ] Testar `work/kernel-mainline-hanoip-fixed2.img` (corrigido)
- [ ] Verificar se o kernel avança além de "Starting kernel..."
- [ ] Se avançar: criar initramfs e ver logs

## Como ver os logs do kernel

### Opção 1: fbcon no display

O bootargs tem `console=tty1`. Se o kernel inicializar o simple-framebuffer,
os logs aparecem no display. Mas se o kernel crasha antes, nada aparece.

### Opção 2: ramoops/pstore

O DTS define ramoops em `0x9d800000`. Depois de um crash, o log do panic
pode estar lá. O U-Boot `oem console` pode ler se o ramoops persistir.
(Verificar: `fastboot oem console` após crash)

### Opção 3: console serial USB (usbacm)

O U-Boot pode ativar o usbacm (menu → "Enable serial console gadget").
O kernel com `console=ttyGS0` mostraria logs via USB serial. Precisa testar.

### Opção 4: earlycon

O bootargs tem `earlycon=msm_geni_serial,0xa88000`. Mas o Moto não tem
UART física acessível (sem pontos de teste). Se existir ponto de teste,
conectar um adaptador UART para ver os primeiros logs.

## O que pode estar errado no kernel (checklist)

1. **DTB não chega ao kernel** → verificar com o build de debug do U-Boot
   (o `do_bootm_linux` imprime "FDT passed to kernel: %p" — ver se é válido)
2. **Panic por falta de rootfs** → criar initramfs
3. **PSCI não funciona** → verificar se o U-Boot setup corretamente
4. **Crash num driver** → desabilitar drivers um a um (método dos quadrados)
5. **Text offset / load addr** → o kernel Image tem text_offset=0x0, o U-Boot
   deve usar o booti corretamente

## Método de debug: quadrados no framebuffer

Se precisar bissecar onde o kernel/U-Boot trava:

```c
// No arch/arm/mach-snapdragon/board.c
static void dbg_square(int x, int y, int w, int h, u8 r, u8 g, u8 b) {
    volatile u8 *fb = (volatile u8 *)0x9c000000;  // cont_splash
    // preenche um retangulo no framebuffer
}
```

Chamar `dbg_square(...)` em vários pontos do boot para ver até onde chega.
O framebuffer do ABL (cont_splash) fica visível no display.

Isso foi usado para achar o crash do `dm_init_and_scan` no U-Boot (memória
errada). Para o kernel, seria semelhante (mas o kernel é mais difícil de
instrumentar — usar earlycon/printk).

## Arquivos de referência

- `check_dtb.py` — valida se o dtb_ptr bate com o DTB real no boot.img
- `fix_dtb2.py` — corrige page_size + dtb_size no boot.img
- `work/kernel-mainline-hanoip-fixed2.img` — boot.img corrigido (testar)
