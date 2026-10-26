# Kali NetHunter Pro no Moto G60 (hanoip) — levantamento (26/10/2026)

Projeto novo: rodar o **Kali NetHunter Pro** (Kali Linux completo para
celulares ARM64, com Phosh ou Plasma Mobile) no hanoip, reaproveitando o
kernel 7.3 v3, o U-Boot e todo o suporte de hardware já feito para o pmOS.
Nada foi construído nem gravado ainda; esta pasta é só documentação.

As regras do projeto continuam valendo (AGENTS.md): **nada de flash**, boot
só volátil (`fastboot boot` do U-Boot e do kernel), a única área gravável é
a cauda não alocada do `super` (hoje ocupada pelo rootfs do pmOS).

## O que é o NetHunter Pro

- Distribuição Kali "pura" para ARM64 (não é a camada sobre Android do
  NetHunter clássico). Doc oficial: <https://www.kali.org/docs/nethunter-pro/>
  (atualizada 2026-06-30). Download: <https://www.kali.org/get-kali/>.
- Aparelhos oficiais: PinePhone, PinePhone Pro, Poco F1, OnePlus 6/6T, Mi
  MIX 2S, SHIFT6mq, Nothing Phone 1 (pré-lançamento). Imagens:
  `kali-nethunterpro-2026.2-pinephone-phosh.img.xz` e `...-sdm845.img.xz`.
- Instalação oficial nos Qualcomm: `fastboot flash userdata` (rootfs) +
  `fastboot flash boot` + apagar `dtbo`. **Isso é proibido aqui** — o
  caminho do hanoip é o mesmo do pmOS (rootfs na cauda do `super`, boot
  volátil).
- Subpáginas lidas:
  - Firmware de partições dinâmicas: <https://www.kali.org/docs/nethunter-pro/extract-firmwares/>
    (`fw-xtractor` no Android + config do droid-juicer → `fw.tgz` em
    `/lib/firmware/updates/`).
  - OTG no SDM845: <https://www.kali.org/docs/nethunter-pro/enable-otg-sdm845/>
    (só troca `dr_mode = "peripheral"` por `"host"` no DTB; o resto da página
    grava a partição boot — no hanoip faríamos isso no DT do U-Boot).
  - Waydroid: <https://www.kali.org/docs/nethunter-pro/waydroid/> (repo
    oficial do Waydroid, `waydroid init`; requisitos de kernel não citados —
    nosso 7.3 tem `ANDROID_BINDER_IPC=y` mas `ANDROID_BINDERFS` desligado).

## Como as imagens são construídas (docs/build-scripts/)

Repositório: <https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-pro>
(fork das receitas do Mobian, <https://salsa.debian.org/Mobian-team/mobian-recipes>).
Cópias locais em `docs/build-scripts/` (README, build.sh, receitas, devices/qcom).

- Ferramenta: **debos** (receitas YAML) dentro de uma VM criada pelo
  `fakemachine` → precisa de **QEMU + KVM**. No Mac não há KVM: rodar em
  Linux com KVM, ou em container privilegiado com fakemachine desligado /
  backend qemu (bem mais lento).
- Comando: `./build.sh -v sm7150 -D plasma-mobile` (ou `-D phosh`);
  `-b kali-rolling|kali-last-snapshot`; dá para gerar o rootfs uma vez
  (`./build.sh -v rootfs -a arm64`) e reaproveitar (`-r output/rootfs-...`).
  `build-in-container.sh` + `Dockerfile` empacotam o ambiente.
- **Família SM7150 já existe**: `devices/qcom/configs/sm7150.toml` com
  `[bootimg]` (base 0x0, kernel 0x8000, ramdisk 0x1000000, tags 0x100,
  pagesize 4096) e `[[device]]` para google sunfish, xiaomi davinci
  (samsung/visionox), surya (huaxing/tianma), sweet, toco, tucana. O hanoip
  seria mais um bloco `vendor = "motorola"`, `model = "hanoip"`.
- `devices/qcom/bootloader.sh`: para cada `[[device]]` gera
  `/bootimg-<model>` com `mkbootimg`, kernel + DTB
  `/usr/lib/linux-image-<ver>/qcom/sm7150-<vendor>-<model>.dtb` e cmdline
  `mobile.root=UUID=... mobile.qcomsoc=qcom/sm7150 mobile.vendor=...
  mobile.model=... init=/sbin/init ro quiet splash`.
- `devices/qcom/initramfs-tools/.../losetup_root_img`: permite rootfs como
  ARQUIVO numa partição (`rootimg=PARTLABEL=userdata/media/0/x.img`). Não
  serve direto para nós (o nosso rootfs é uma faixa crua do `super` por
  offset, sem sistema de arquivos em volta) — precisaria de um script
  parecido com o nosso `pmos-root` (losetup -o 5410652160 + guarda RO).
- `devices/qcom/packages-base.yaml`: instala `sm7150-support`, habilita
  `qrtr-ns rmtfs pd-mapper tqftpserv droid-juicer qcom-modem-setup`.

## Pacotes do Mobian para SM7150 (repo.mobian.org, suíte staging)

- `linux-image-6.18-sm7150` 6.18.51-1 (kernel do fork, **6.18, sem o DT nem
  os patches do hanoip**) → para nós: empacotar o **nosso kernel 7.3 v3**
  (work/kernel-7.3/v3) como `.deb` com o `sm7150-motorola-hanoip.dtb`.
- `sm7150-support` 0.3.5 → depende de `linux-image-6.18-sm7150` e
  `qcom-support-common`.
- `qcom-support-common` 0.3.5 → droid-juicer, firmware-atheros,
  firmware-qcom-soc, libdrm-freedreno1, libqmi-utils,
  **make-dynpart-mappings**, mobian-tweaks-common, mobile-usb-networking,
  protection-domain-mapper, qcom-phone-utils, qrtr-tools, rmtfs,
  systemd-zram-generator, tqftpserv.

## droid-juicer (docs/droid-juicer/)

<https://gitlab.com/mobian1/droid-juicer> — copia firmware das partições do
Android (por `/dev/disk/by-partlabel/`) para `/lib/firmware/updates`, no
primeiro boot; configs por compatible do DT (`configs/<vendor>,<model>.toml`,
chaves `firmware`, `folders`, `partdump`). Não grava nas partições, mas as
MONTA e LÊ. Há configs de SM7150 (google,sunfish; xiaomi,davinci; surya),
não de motorola,hanoip. Como no hanoip o firmware já é ligado de
`/mnt/ro/modem_a` pelo nosso `hanoip-firmware`, o plano é **não usar** o
droid-juicer (ou só com config revisada e montagem `ro,noload` em bloco já RO).

## Pontos de atenção (segurança do aparelho)

1. **Instalação**: nunca o fluxo oficial (`fastboot flash userdata/boot`,
   apagar `dtbo`, `set_active`). Rootfs só na cauda do `super`, boot volátil.
2. **make-dynpart-mappings**: cria mapeamentos device-mapper das partições
   dinâmicas do `super`. Revisar o código antes; no mínimo mapear só leitura,
   ou remover o pacote.
3. **droid-juicer**: monta partições do Android → desligar ou restringir.
4. **Regra udev que deixa sd* somente leitura** (60-hanoip-blockdev-ro) e a
   que esconde discos do udisks2 (61-hanoip-udisks-ignore): obrigatórias no
   rootfs do Kali, que traz udisks/automount e ferramentas forenses.
5. **systemd-repart** é removido pela própria receita qcom (bom); conferir
   que nada tenta redimensionar/criar partições (growpart, resize2fs no
   primeiro boot) fora da cauda do `super`.
6. Espaço: a cauda tem 5 GB e hoje é do pmOS; o Kali completo é grande →
   ou substituir o pmOS (regravar só a cauda, já autorizado) ou testar o Kali
   em RAM primeiro.

## Plano proposto

1. **Kernel**: gerar `.deb` do kernel 7.3 v3 (`linux-image-7.3.0-sm7150`),
   com módulos, `hanoip_mmi_unit_info` e o DTB do hanoip.
2. **Device**: acrescentar `motorola/hanoip` ao `sm7150.toml` (ou um
   `hanoip.toml` próprio) e um pacote `hanoip-support` com o que o pmOS usa
   hoje: serviços (rede USB/SSH, firmware, touch, perf-tune, brilho, rota do
   alto-falante, SSC) como unidades systemd, regras udev de segurança, UCM,
   WirePlumber, tema do feedbackd, flashlighthelper corrigido (se Plasma).
3. **Boot**: initramfs com um `pmos-root` equivalente (loop por offset na
   cauda do `super`, guardas RO, conferência dos metadados LP) no lugar do
   `mobile.root=UUID`, empacotado no layout do nosso boot.img e subido por
   `fastboot boot` depois do U-Boot (DT do U-Boot `perif-v5`/`venus`).
4. **Build**: rootfs Kali arm64 via debos numa máquina Linux com KVM (ou
   container privilegiado), variante `-D plasma-mobile` ou `phosh`.
5. **Teste em RAM** antes de tocar na cauda do `super`; depois decidir com o
   usuário se o Kali substitui o pmOS na cauda.

## Arquivos desta pasta

- `docs/build-scripts/` — cópia do README, TREE.txt, build.sh, receitas
  (image.yaml, rootfs.yaml), Dockerfile, CI e `devices/qcom/*` do
  kali-nethunter-pro (GPL-3.0+).
- `docs/droid-juicer/` — README e lista de configs.

## Como o NetHunter Pro dá boot nos Qualcomm (investigado 26/10 ~20h)

Fontes: `docs/build-scripts/devices/qcom/*` e o pacote Debian
`qcom-phone-utils` (salsa.debian.org/DebianOnMobile-team/qcom-phone-utils,
cópia em `docs/qcom-phone-utils/`).

- **Sem U-Boot, sem lk2nd.** O próprio bootloader do Android (ABL) carrega
  um `boot.img` Android gerado pelo `bootloader.sh`: kernel com o DTB
  anexado (`sm7150-<vendor>-<model>.dtb` do pacote do kernel), initrd do
  initramfs-tools do Debian, cabeçalho v0 (offsets do `sm7150.toml`) e
  cmdline `mobile.root=UUID=<rootfs> mobile.qcomsoc=qcom/sm7150
  mobile.vendor=<v> mobile.model=<m> init=/sbin/init ro quiet splash`.
  Instalação oficial: `fastboot flash boot`, rootfs em `userdata` (imagem
  sparse) e `fastboot erase dtbo` (senão o ABL aplica os overlays do
  vendor no DTB anexado).
- **initramfs**: `mobile-root` (init-premount) troca ROOT pelo
  `mobile.root=`; `losetup_root_img` (do Kali) permite rootfs como ARQUIVO
  numa partição (`rootimg=PARTLABEL=userdata/...`); o hook `qcom-firmware`
  copia `qcom/sm7150/<vendor>/<model>/{adsp,cdsp,ipa_fws}.mbn` para dentro do
  initramfs (mesmo caminho que já usamos: qcom/sm7150/motorola/hanoip/).
- **PERIGO — `zz-qcom-bootimg`** (`/etc/kernel/postinst.d/`, do
  qcom-phone-utils): a CADA instalação/atualização de kernel ele lê
  `/dev/disk/by-partlabel/boot$(qbootctl -x)`, remonta o boot.img com o
  kernel novo e GRAVA de volta com `dd of=...boot_<slot>`. No hanoip isso
  sobrescreveria o boot do Android. Tem que ser REMOVIDO do rootfs Kali (e
  o `qcom-backup-boot` também lê a partição boot). Hoje os discos ficam RO
  por BLKROSET, então o dd falharia — mas não depender disso.
- **No hanoip o ABL não serve direto**: segundo o klockmt/hanoip-pmos, o ABL
  do G60 só executa cabeçalho v3 (ramdisk em vendor_boot, LZ4 legacy) e
  aplica o dtbo; por isso usamos o U-Boot volátil.

### Caminho proposto para o hanoip (sem gravar partição)

1. `fastboot boot` do NOSSO U-Boot (DT embutido, ex. pmos-perif/venus) →
   fastboot do U-Boot → `fastboot boot` de um boot.img do Kali. O U-Boot já
   aceita o nosso boot.img (cabeçalho v2, página 4096); o do Kali (v0 +
   DTB anexado) deve passar também, ou reempacotamos com o nosso
   `pack-boot.py`. O kernel usa o DT do U-Boot (o DTB anexado é ignorado).
2. initramfs do Kali (initramfs-tools) + um script init-premount nosso, no
   lugar do `mobile.root=UUID`: travar todos os sd* RO, conferir os
   metadados LP do super e montar a cauda do super por loop com offset
   (5410652160) — o mesmo trabalho do nosso `pmos-root` — e
   `mobile.root=/dev/loop7`.
3. Rootfs do Kali sem `zz-qcom-bootimg`, sem `qcom-backup-boot`, sem
   droid-juicer ativo, revisando `make-dynpart-mappings`, com as regras udev
   de RO/udisks do hanoip.
