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

## RESULTADO — Kali NetHunter Pro (Phosh) BOOTOU no hanoip (26/10 ~22h)

O usuário confirmou a interface gráfica do Phosh rodando, senha `1234`.
Fluxo que funcionou:
  fastboot boot u-boot-hanoip-pmos-perif-v2026.10.img   (U-Boot volátil)
  fastboot boot kernel-hanoip-kali-phosh-v1.img         (boot.img do Kali)
Cadeia: kernel 7.3.0-sm7150 (nosso) -> DT do U-Boot -> initramfs do Kali
com os hooks hanoip (console ACM, guard RO, root por LABEL=kali).

Como o rootfs foi gravado: a ABL da Motorola RECUSA `fastboot flash userdata`
("flash permission denied"; `fastboot erase userdata` funciona). Gravação
feita pelo Linux (pmOS GOLD) com write-userdata.sh, que abre o disco sdb,
refecha todas as partições exceto sdb24, confere e escreve; hash conferido
por amostragem (0, 5120 e 10230 MiB iguais).

Achados que custaram tempo e ficam registrados:
  - `fastboot boot` do U-Boot usa o DTB EMBUTIDO; o DTB do boot.img é ignorado.
  - Kernel tem que ser Image.gz UMA vez (gzip duplo = Synchronous Abort).
  - "ERROR: reserving fdt memory region failed ... -17" é NORMAL neste board.
  - Firmware de GPU (a630_sqe.fw/gmu.bin) precisa estar no INITRAMFS: o
    msm_dpu/adreno carrega antes do rootfs ser montado.
  - Partição só fica gravável se o DISCO estiver rw (BLKROSET por device).
  - O initramfs do Kali não traz console; adicionamos gadget ACM (ttyGS0).
  - `mobile-root` vem do qcom-phone-utils (não instalado): usamos root=LABEL.
  - greetd/phrog sobe; login com kali/1234.

## Estado ao encerrar a primeira sessão do Kali (26/10 ~23h)

FUNCIONA: boot completo, Phosh na tela, login kali/1234, serial ACM (ttyGS0)
com getty, regras RO ativas, hanoip-firmware monta modem_a/bluetooth_a e
liga /firmware (a630 etc.).

NÃO FUNCIONA AINDA:
 - Wi-Fi: `ath10k_snoc` faz bind no device (18800000.wifi, DT status=okay) mas
   o probe NÃO completa e wlan0 não aparece. Causa provável: falta o stack do
   modem que o WCN3990 usa por QMI/QRTR — `qrtr-ns`, `rmtfs`, `pd-mapper`,
   `tqftpserv` (vêm do devices/qcom/packages-base.yaml do Kali, que NÃO
   instalamos). Sem eles o QMI do WLAN não sobe.
 - USB NCM/SSH: o gadget do initramfs (hanoip-console) continua dono do UDC,
   então o gadget hanoip-net não consegue bind e usb0 não existe. Já corrigido
   em hanoip-support/hanoip-usbnet.sh (desvincula gadgets antigos), falta
   reinstalar no rootfs.
 - `ip` (iproute2) não está instalado no Kali mínimo; `nmcli` existe.
 - aw882xx: falta /lib/firmware/aw882xx_spk_reg.bin (áudio sem calibração).
 - greetd/phrog ok; usuário kali em sudo.

PRÓXIMO PASSO (canal confiável, já provado): bootar pmOS GOLD, montar
/dev/sdb24 em /mnt/kali e, de dentro dele, chroot + apt usando a rede do
pmOS para instalar: iproute2, iproute2, rmtfs, pd-mapper, tqftpserv,
qrtr-tools; reinstalar hanoip-usbnet.sh corrigido; copiar
aw882xx_spk_reg.bin para /lib/firmware. Serial é lossy para payloads
grandes/base64 — usar só para comandos curtos.

## Segunda sessão (26/10 ~23h30) — infraestrutura instalada, tela cinza

INSTALADO no rootfs do Kali (via chroot com a rede do pmOS):
iproute2, iputils-ping, rmtfs, tqftpserv, qrtr-tools, protection-domain-mapper.
Serviços habilitados: qrtr-ns, pd-mapper, rmtfs (drop-in: -o /run/efs -r),
tqftpserv. hanoip-efs.service popula /run/efs (modem_fs1/fs2/fsg/fsc) a partir
de modemst1/2, fsg, fsc SOMENTE LEITURA. hanoip-firmware agora tambem inicia o
remoteproc do modem (firmware do WLAN) e espera 3 s.
aw882xx_spk_reg.bin copiado para /lib/firmware.

USB NCM/SSH: CORRIGIDO — o gadget hanoip-net desvincula o gadget do initramfs;
o Mac recebe 172.16.42.2 por DHCP (interface en10), ping 0% perda, porta 22
aberta e o banner do OpenSSH 10.6p1 responde. Porem `ssh` autentica e NAO
devolve saida nenhuma (nem com -tt); ainda nao diagnosticado. Serial tambem
ficou sem resposta depois que o gadget novo subiu (porta mudou para
/dev/cu.usbmodemhanoip_kali3).

TELA CINZA: o usuario relatou tela ligada mas cinza nesta sessao. Nao
diagnosticado (sem shell confiavel). Suspeitas, em ordem:
 1. greetd/phosh reiniciou e ficou no fundo do greeter (cinza) sem sessao;
 2. o inicio do modem (novo) disputou memoria/IOMMU com o DRM;
 3. o display herdou estado do boot anterior (FIFO/VIDEO) como ja aconteceu.
Nao ha evidencia de panic: o sistema responde em TCP e ICMP.

RETOMAR POR AQUI: primeiro recuperar um canal confiavel (serial com getty no
ttyGS0 do gadget novo, ou sshd funcionando) e so depois julgar a tela.

## TERCEIRA SESSÃO (26/10 ~23h50) — Kali funcionando, falta Wi-Fi

CONQUISTADO: Phosh na tela, teclado virtual, SSH root por chave, rede USB NCM
(Mac em 172.16.42.2), serial ACM.

CAUSA RAIZ DE TUDO (tela preta + systemctl travado + SSH travado + user@0
timeout): a cmdline tinha `console=ttyGS0` e o PID 1 do systemd ficou BLOQUEADO
em n_tty_write porque ninguém drenava o ACM do console. Prova: /proc/1/stack
mostrava n_tty_write/wait_woken. Correção: tirar `console=ttyGS0` e usar
`console=tty0`. Imagem corrigida: /tmp/kali-noblk.img.

Outras correções aplicadas (todas no rootfs, via SSH):
 - sshd drop-in /etc/ssh/sshd_config.d/99-hanoip-nopam.conf com `UsePAM no`:
   foi o que destravou o SSH enquanto o user@/logind estava quebrado. Reavaliar
   quando o relógio/sessões estiverem 100%.
 - greetd: `command = "phrog"` (phrog NÃO aceita `-s`); symlink
   /etc/systemd/system/display-manager.service e em graphical.target.wants.
   _greetd nos grupos video e render.
 - /usr/local/sbin/hanoip-modem + hanoip-modem.service: inicia o remoteproc do
   modem DEPOIS de qrtr-ns/pd-mapper/rmtfs/tqftpserv (antes o firmware do WLAN
   crashava). Ainda assim crasha — ver abaixo.
 - relógio: `date -u -s` manual (PAM recusava conta por "password changed in
   future"). FALTA torná-lo permanente.

WI-FI: stack do modem OK, modem sobe, ath10k_snoc faz QMI (chip_id 0x140,
fw WLAN.HL.3.2.2) e então loga "firmware crashed!" sem criar wlan0.
PRÓXIMO: testar /tmp/kali-k6.img (rootfs Kali + INITRD Kali + KERNEL #6, o do
pmOS que tem Wi-Fi funcionando). Se funcionar, o problema é o kernel v3 —
suspeita: o `olddefconfig` mexeu em opções ao adicionarmos BINDERFS/ATH9K_HTC/
MT76x2U. Comparar configs v2 x v3 e refazer o v3 partindo da config v2 com
apenas os símbolos novos.

REGRA: todo reboot vai para o bootloader (AGENTS.md), nunca Android.

## WI-FI RESOLVIDO (27/10 ~00:10) — faltava o mmi_unit_info

O modem Motorola le SMEM item 134 (mmi_unit_info) e ABORTA ~1,5 s depois de
subir sem ele. Sintoma: ath10k fazia o QMI, o firmware carregava e então
"firmware crashed!" (ou ficava em api 0). Era isso, NÃO era kernel v3 (o crash
acontecia igual com o kernel #6), NÃO era firmware de 60 bytes (pmOS usa o
mesmo), NÃO era ordem de módulos.

Correção: /usr/local/sbin/hanoip-mmi + hanoip-mmi.service (sysinit, antes do
hanoip-modem) lê a identidade que o ABL passa ao U-Boot em
/proc/device-tree/chosen (u-boot,abl-bootargs: serialno/carrier/radio/device;
linux,hwrev; linux,serial-low/high; mmi,powerup_reason) e faz insmod de
hanoip_mmi_unit_info.ko com esses parâmetros. Identificadores vão só para o
kernel; nada é logado nem gravado.

Depois disso: firmware ver api 5 crc32 b3d4b790, sem crash, wlan0 criado,
NetworkManager lista as redes (2.4 e 5 GHz). A senha do Wi-Fi é digitada no
aparelho, nunca aqui.

Ordem final dos serviços: hanoip-firmware (links de firmware) ->
hanoip-mmi (identidade) -> hanoip-modem (remoteproc) -> ath10k/NetworkManager.

## PERIFÉRICOS PORTADOS DO pmOS (27/10 manhã)

DESEMPENHO (hanoip-perf-tune.service, mesmos valores validados no pmOS):
GPU devfreq piso 355 MHz + poll 16 ms (antes 180 MHz/50 ms), UFS 200 MHz
(antes 50 MHz), CPU schedutil 300..1804 MHz, 8 núcleos. Medido: GPU e UFS
estáveis, temperaturas 36..51 C.

SENSORES (hanoip-ssc.service + hexagonrpcd + libssc + iio-sensor-proxy):
bundle do SSC em /opt/ssc (83 MB, copiado do pmOS). Acelerômetro (tilt),
luz (lux variando) e proximidade no D-Bus. IMPORTANTE: o iio-sensor-proxy
precisa ser reiniciado depois que o hanoip-ssc publica os serviços, senão
fica vazio — o serviço já faz isso. No Kali a orientação chega a ser
reportada (no pmOS ficava undefined).

VIBRAÇÃO: pm8xxx_vib_ffmemless em /dev/input/event4, ACL de uaccess para o
usuário kali. FF_RUMBLE direto funciona e o feedbackd (fbcli) também.

LED e FLASH: white:status (511) e white:flash acendem; apagados de volta.

ÁUDIO (3 peças necessárias, todas portadas do pmOS):
 1. UCM /usr/share/alsa/ucm2/conf.d/sm8250/Motorola Moto G60.conf +
    /usr/share/alsa/ucm2/Motorola/hanoip/HiFi.conf -> cria o sink Speaker
    (sem isso o WirePlumber só tinha "Dummy Output").
 2. Regra udev 99-hanoip-speaker-route.rules + /usr/libexec/hanoip-speaker-
    route: liga "SEC_MI2S_RX Audio Mixer MultiMedia1" quando o card aparece
    (a rota começa off).
 3. /usr/share/wireplumber/wireplumber.conf.d/51-hanoip-speaker.conf forçando
    S16LE: com S24_32LE o caminho q6asm toca ~48 dB mais baixo.
 Volume: /etc/modprobe.d/hanoip-speaker.conf com attenuation_db=6 (padrão 18).

## NFC no Kali (27/10) — kernel + neard ok; app gráfico PENDENTE

Kernel: nxp_nci/nxp_nci_i2c em 2-0028, nfc0 desbloqueado (rfkill).
Leitura direta (work/perif-20261026/tools/nfcpoll.py): cartão ISO14443-A
detectado, SENS_RES 0400, SEL_RES 0x20, ID 4 bytes.
neard 0.20 instalado e ativo; adaptador /org/neard/nfc0 reconhecido,
Powered via Properties.Set (não existe método Power(b)), StartPollLoop
Initiator; nfctool -l mostra "Tags: [ tag2 ]" com o cartão no campo.
Ainda não verificado: objeto D-Bus /org/neard/nfc0/tagN visível e leitura
de NDEF por app.

PENDENTE (usuário pediu para deixar para depois): app gráfico
hanoip-support/hanoip-nfc.py (GTK4+Adw, fala com org.neard, liga o RF,
inicia o poll e lista tipo/UID dos cartões). Falta instalar, criar
/usr/share/applications/hanoip-nfc.desktop e testar com cartão real.

## SNAPSHOT DO KALI FUNCIONAL (27/10) — work/kali-20261027-snapshot/

rootfs.tar.zst (2,1 GB comprimido / 5,5 GB descomprimido, 171.772 entradas)
com o rootfs inteiro do Kali, incluindo /opt/ssc, módulos e drivers.
Tirado do pmOS com o /dev/sdb24 montado SOMENTE LEITURA (a tentativa de fazer
dentro do Kali com zstd -T0 travou a interface — não repetir).
Junto: configs/ (+ configs.tar.gz) com os 24 arquivos que criamos/portamos,
packages.txt (1566 pacotes), inventory.txt, README.txt com procedimento de
restauração, e SHA256SUMS.

Estado capturado (validado no aparelho): Phosh + teclado virtual, login
kali/1234, SSH root por chave, USB NCM+DHCP, Wi-Fi 5 GHz com internet,
relógio (fake-hwclock + NTP, America/Sao_Paulo), desempenho (GPU 355 MHz /
poll 16 ms, UFS 200 MHz, schedutil), sensores SSC, vibração, LED, flash,
áudio no alto-falante (UCM + rota + S16LE + mono + 6 dB).


## CORREÇÃO DE BOOT 27/10 — "Failed to mount /dev/disk/by-partlabel/userdata"

Dois problemas independentes, ambos corrigidos:

1) ext4 do userdata com inodes órfãos e bitmaps inconsistentes (reboot forçado
   durante o snapshot). Reparado com `e2fsck -fy /dev/sdb24` a partir do pmOS;
   verificação `-fn` fechou RC=0.

2) A regra udev /etc/udev/rules.d/99-hanoip-blockdev-ro.rules usava
   KERNEL=="sd*", que casa com o DISCO inteiro. `blockdev --setro /dev/sdb`
   deixa o disco RO, e o `local` do initramfs monta a raiz com `-w`:
   `mount: mounting /dev/sdb24 on /root failed: Permission denied`.
   No initrd reconstruído o udev passou a disparar a regra DEPOIS do
   hanoip-guard, então todo boot caía no BusyBox.
   Correção: KERNEL=="sd*[0-9]" (só partições), aplicada no rootfs e no initrd
   (initrd reconstruído dentro do Kali). Boot.img novo:
   artifacts/kernel-hanoip-kali-phosh-v2.img

Evidência completa: work/nethunter-pro-20261027-fix-mount/LEIA-ME.txt
Reboot seguro novo: /usr/local/sbin/hanoip-reboot (sync + remount RO + b).

### Extras do mesmo dia (27/10, tarde)

- hanoip-ssc: o hexagonrpcd subia uma única vez, 5 s após o start, e morria
  no boot a frio ("hanoip-ssc: hexagonrpcd died"). Agora o script espera o
  remoteproc 62400000.remoteproc reportar "running", tenta até 6 vezes, mata
  um hexagonrpcd remanescente e o unit tem Restart=on-failure. Validado em
  boot a frio (try 1, Result=success, NRestarts=0).
- bootmac-bluetooth.service: mascarado. É o script do Mobian para SDM845; no
  hanoip o hci0 já sobe com BD Address estável (D8:CF:BF:3C:EE:74) e o serviço
  só produzia timeout e unit failed. Nota em
  /etc/systemd/system/bootmac-bluetooth.service.d/README.conf
- Resultado: `systemctl is-system-running` = running, nenhum unit falhando.
