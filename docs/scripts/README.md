# Scripts do Projeto - Referência

Todos os scripts estão na raiz do projeto (`/home/brener/hanoip-uboot/`).

## Build U-Boot

| Script | Uso |
|--------|-----|
| `build.sh` | **PRINCIPAL** - build reproduzível do U-Boot + boot.img |
| `build_full.sh` | Aplica os 3 configs do fork + ajustes hanoip |
| `pack_embed.sh` | Empacota boot.img header v3 (OF_EMBED) |
| `pack_v3.sh` / `pack_v3_rd.sh` | Empacota boot.img v3 (com/sem ramdisk) |
| `pack_osm0sis.sh` | Empacota com mkbootimg do osm0sis (header v0) |

Scripts de debug (NÃO usar no build final):
- `build_nosmmu.sh`, `build_nosmmu2.sh`, `build_vidpid.sh`, `genconfig.sh`
- `debug-nosmmu.config` — fragment que desabilita SMMU (para debug)

## Build Kernel

| Script | Uso |
|--------|-----|
| `kernel_build.sh` / `kernel_build2.sh` | Compila o kernel mainline |
| `dtb_build.sh` | Compila só o DTB do kernel |
| `pack_kernel.sh` | Empacota boot.img v3 do kernel |
| `pack_kernel_v2.sh` | Empacota boot.img v2 do kernel |
| `pack_kernel_osm.sh` | Empacota boot.img v2 com mkbootimg osm0sis |

## Correção do boot.img do kernel

| Script | Uso |
|--------|-----|
| `fix_dtb2.py` | **CRÍTICO** - corrige page_size + dtb_size no boot.img v2 |
| `check_dtb.py` | Valida se o dtb_ptr bate com o DTB real |

Uso:
```bash
bash pack_kernel_osm.sh        # gera kernel-mainline-hanoip-osm.img
python3 fix_dtb2.py            # gera kernel-mainline-hanoip-fixed2.img
python3 check_dtb.py           # verifica (opcional)
```

## Análise

| Script | Uso |
|--------|-----|
| `unpack_dev.sh` | Desempacota boot/vendor_boot do device |
| `check_dtb.py` | Valida boot.img do kernel |

## Arquivos gerados (work/)

| Arquivo | Descrição |
|---------|-----------|
| `u-boot-hanoip-boot.img` | U-Boot boot.img (final, flashar no boot_a) |
| `u-boot-hanoip-embed.img` | U-Boot com OF_EMBED (build mais recente) |
| `kernel-mainline-hanoip-fixed2.img` | **Kernel mainline boot.img (corrigido, testar)** |
| `ramdisk-empty.cpio.gz` | Ramdisk vazio (127 bytes) |

## Comandos rápidos

```bash
# U-Boot build completo
cd /home/brener/hanoip-uboot && bash build.sh

# Kernel build completo
cd /home/brener/hanoip-uboot/kernel-mainline
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- LLVM=1
make -j$(nproc)

# Kernel DTS+boot.img rápido (após mudar DTS)
cd /home/brener/hanoip-uboot/kernel-mainline
make LLVM=1 ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- dtbs
cd /home/brener/hanoip-uboot
bash pack_kernel_osm.sh && python3 fix_dtb2.py
```

## Notas

- O `build.sh` é o canônico para U-Boot. Os outros são históricos/debug.
- O `pack_kernel_osm.sh` + `fix_dtb2.py` é o fluxo canônico para kernel.
- Os scripts com "nosmmu", "vidpid", "v2", "osm0sis" são variações usadas
  durante o debug — mantidos para referência, não são o fluxo principal.
