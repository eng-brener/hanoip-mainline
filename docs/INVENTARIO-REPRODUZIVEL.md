# Inventário do que é nosso e como reproduzir

31/10/2026. Objetivo: responder "de onde vem cada peça que fizemos e como
reconstruí-la". Tudo abaixo foi conferido em `git ls-files` (não é suposição).
O que não tem caminho reproduzível está marcado como **LACUNA**.

## 1. Drivers de kernel (patch series `work/kernel-7.3/v7/patches`, 195)

Cada item é um patch versionado; o `build-inside.sh` aplica todos e confere
que a árvore final é `276fbce0`. Reprodução: `sh work/kernel-7.3/v7/build.sh`.

| Área | Patch(es) | O que é |
|---|---|---|
| DT bindings hanoip | `hanoip-dt-bindings` | documentação dos nós novos |
| pinctrl/clk/soc | `hanoip-pinctrl-clk-soc` | base SM7150 no mainline |
| Regulador do painel | `hanoip-lcdb-regulator` | PM6150L LCDB (LAB/IBB/BST, VREG_OK, rollback) |
| Painel | `hanoip-panel-ili7807s` | Tianma ILI7807S 1080x2460 + DSC (modo 120 Hz é o patch do v8) |
| Framebuffer | `hanoip-simplefb` | splash/console |
| UFS | `hanoip-ufs` | controle e leitura read-only |
| IOMMU | `hanoip-iommu-smmu` | identidade/attach |
| Display (MSM) | `hanoip-msm-display` | DPU/DSI: video_deferred, diagnósticos |
| Toque | `hanoip-touch` | Ilitek SPI, IRAM, follower do painel |
| Energia/bateria | `hanoip-power-supply` | QG/SMB telemetria, OCV |
| DT do aparelho | `hanoip-dts` | nós do hanoip |
| Câmeras | `0190`–`0194` | camss rollback, CSIPHY por sensor, C-PHY, CCI resume, sensores/VCM |
| Áudio | `0188`, `0189` + ASoC/soundwire | wcd937x-sdw (mapa de canais), soundwire-qcom |
| Digital (FPC) | `0195` | QSEECOM legado + `qcom_qseecom_fpc` (listener RPMB) |
| Correções DSI | `work/kernel-7.3/v8-dsi/patches/0196` | validação lane/DSC, PM/clock, ciclo de vida do modo |
| Restante (power, arm64, media, pinctrl, drm…) | patches numerados do series | base mainline + ajustes necessários |

Fora do series: nada. Os módulos de teste em `work/cameras-20261028/*/` são
experimentos **superados** pelos patches 0190–0194 (fontes preservadas, sem
papel no build atual).

## 2. U-Boot (DT efetivo do aparelho)

Reprodução: `sh work/uboot-builds-20261026/build-repro.sh` → **byte-idêntico**
ao validado. Base: fork `sm7150-mainline/u-boot` commit `f8c04469`, mais
`patches/hanoip-vs-sm7150-mainline-tauchgang.diff`, mais
`patches/hanoip-dts-cam-tres-delta.diff`, mais `base.config` e
`SOURCE_DATE_EPOCH`. Todos em git.

## 3. Init / ramdisk / empacotamento de boot

| Peça | Onde | Situação |
|---|---|---|
| Extrator/empacotador de boot.img | `scripts/hanoip_boot.py` | em git |
| Init do rootfs Kali (switch_root) | `scripts/hanoip-pmos-root.sh`, `work/GOLD-20261025-1659/pmos-root.sh` | em git |
| Injeção de módulos no initramfs (override cpio) | `work/display-120hz-20261030/make-early-override.py`, `mkimg-dsifix-120hz.py` | em git |
| Hook de init-bottom do painel 120 Hz | `work/display-120hz-20261030/hanoip-panel-120-init-bottom.sh` | em git (protótipo; o método efetivo é o cpio) |
| Empacotar kernel do Kali | `work/kernel-7.3/v7/mkimg-kali.sh` | em git, **depende da imagem-base (LACUNA 1)** |
| Overlay de rootfs (NetworkManager, modprobe, sshd) | `work/GOLD-20261025-1659/overlay/etc/...` | em git |

Observação: o init do ramdisk é o do vendor (Android); não escrevemos init
próprio. Nossa customização é a injeção de módulos, que é script.

## 4. Rootfs (estado instalado)

| Área | Script | Estado |
|---|---|---|
| Áudio (2 módulos + UCM2 + PipeWire) | `scripts/install-audio.sh` | escrito, dry-run ok, **nunca aplicado** |
| Câmeras (5 módulos + 3 tunings) | `scripts/install-cameras.sh` | escrito, dry-run ok, **nunca aplicado** |
| Digital (módulo, libfprint+patch, fprintd, app, guardião) | `work/fingerprint-20261029/integration/setup-kali-fingerprint.sh` | completo e usado em 30/10 |
| NetHunter / USB / CPU / zram / RTC | `work/nethunter-pro-20261026/hanoip-support/*`, `instalar-fase0.sh` | em git |
| Pacotes do Kali | `work/nethunter-pro-20261026/install-kali-pkgs.sh` | em git |

## 5. Apps e serviços nossos

- **Digital** (app Python) + `.desktop` + `install-digital.sh`/`uninstall`:
  `work/fingerprint-20261029/integration/` (em git).
- **hanoip-fp-guard** + unit + teste: idem.
- **hanoip-usb-app.py**, `hanoip-usb-mode`(+unit/policy), `hanoip-mmi.sh`,
  `hanoip-ssc.sh`(+unit), `hanoip-rtc`, `hanoip-reboot`, `hanoip-batt-log`,
  `hanoip-firmware.sh`, `hanoip-cpu-tune`, `hanoip-perf-tune`,
  `teste-termico`: `work/nethunter-pro-20261026/hanoip-support/` (em git).
- Udev/systemd: `99-hanoip-blockdev-ro.rules`, `99-hanoip-zram.conf`,
  `51-hanoip-speaker.conf`, `zram-generator.conf` (em git).

## 6. Artefatos binários

| Artefato | Situação |
|---|---|
| U-Boot `.img`/`u-boot.bin`/`dtb` | reconstruível **byte a byte** |
| Módulos do v8 (`msm`, painel) | `msm` byte-idêntico; painel equivalente |
| DTB do kernel | byte-idêntico |
| `Image.gz` do kernel | equivalente (10.382 bytes de diferença, banner igual) |
| Imagens-base de boot | **LACUNA 1** (abaixo) |
| Segredos do aparelho (`/var/lib/fpc-gk`, cadastro, HAT) | não versionar, por decisão |

### LACUNA 1 — imagens-base de boot

`kernel-hanoip-listener7.img`, `Image.gz.listener7` e
`kernel-hanoip-kali-phosh-v5.img` só existem localmente (33 + 12 + 33 MB).
Sem elas, `mkimg-kali.sh` e `mkimg-dsifix-120hz.py` não montam um boot.img
novo do zero.

Por que não subiram: (a) `work/**/*.img` está fora do git por tamanho;
(b) o push da imagem construída foi bloqueado por falso positivo do scanner
de segredos; (c) **o repositório é público** e essas imagens carregam o
ramdisk do vendor (firmware de terceiros) — publicar precisa de decisão
consciente, não de um commit automático.

Ponto único para resolver isso: `scripts/fetch-artifacts.sh` (com
`artifacts/base-images.sha256` versionado, só hashes). Ele aceita
`--from DIR` (cópia local/backup) ou `BASE_URL=https://...` (release assets),
baixa e **confere o SHA256** antes de aceitar. Testado em 31/10 contra os
arquivos locais: as quatro imagens conferem.

Opções para a origem, em ordem de segurança:
1. tornar o repositório privado e publicar as imagens como *release assets*
   (o `gh` está autenticado; falta só o aval);
2. manter público e publicar as imagens mesmo assim, aceitando o risco de
   redistribuir blobs do vendor;
3. não publicar: quem for reproduzir extrai o ramdisk do próprio aparelho
   (passo documentado, mas não é "do zero").

Enquanto isso não é decidido, "reproduzir do zero" vale para fontes,
drivers, U-Boot, módulos, DTB, scripts de rootfs e apps — não para o pacote
final de boot.

## 7. Comandos

```sh
sh scripts/reproduce-all.sh          # U-Boot + kernel v7 + módulos v8
sh scripts/reproduce-all.sh --verify # confere hashes conhecidos
sh scripts/install-audio.sh          # dry-run; --apply escreve no aparelho
sh scripts/install-cameras.sh        # idem
sh work/fingerprint-20261029/integration/setup-kali-fingerprint.sh
```

Resultado esperado do `--verify` hoje: OK em U-Boot, DTB do U-Boot, DTB do
kernel e `msm`; "EQUIVALENTE" para a `Image.gz`.
