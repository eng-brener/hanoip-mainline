# Reproduzir o rootfs do Kali

31/10/2026. O rootfs é um sistema de arquivos mutável: reproduzir significa
chegar ao **mesmo conteúdo funcional**, não a bytes idênticos (timestamps,
logs e versões de pacotes sempre mudam). Comparado ao kernel, é mais simples
em exigência e mais chato em prática, por causa da base e do `apt`.

## O que já é reproduzível ✅

Toda a customização do aparelho está em scripts versionados e roda no Kali já
instalado (não precisa remontar partição):

| Ordem | Script | O que faz |
|---|---|---|
| 1 | `work/nethunter-pro-20261026/install-kali-pkgs.sh` | pacotes extras do Kali (chroot/rápido, lista no próprio script) |
| 2 | `work/nethunter-pro-20261026/patch-kali.sh` | ajustes pequenos no rootfs |
| 3 | `work/fingerprint-20261029/integration/setup-kali-fingerprint.sh` | módulo QSEECOM, libfprint v1.94.10 + patch, fprintd, app Digital, guardião |
| 4 | `scripts/install-audio.sh --apply` | 2 módulos + UCM2 + PipeWire |
| 5 | `scripts/install-cameras.sh --apply` | 5 módulos + 3 tunings + depmod |
| 6 | `work/nethunter-pro-20261026/hanoip-support/instalar-fase0.sh` | units/udev/utilitários do hanoip (USB, CPU, zram, RTC, MMI, SSC) |

Apoio: `snapshot-kali.sh` (gera `.tar.zst` do rootfs **somente leitura**) e
`write-userdata.sh` (grava a imagem em `/dev/sdb24`, com checklist de
segurança — **escrita em partição, exige autorização explícita**).

Verificação depois de cada etapa:
`cam -l` (câmeras), `pactl list short sinks` (áudio), `fprintd-verify` ou o
`test_hanoip_fp_guard.py` (digital), `systemctl --failed`.

## O que NÃO é reproduzível hoje ⚠️

1. **A imagem base do Kali (10 GB)** não é reconstruída por este repositório.
   Ela foi gerada com o *kali-linux/nethunter build-scripts* (upstream) mais a
   nossa entrada de dispositivo em
   `work/nethunter-pro-20261026/docs/build-scripts/devices/qcom/configs/sm7150.toml`
   (seção `hanoip`). Do upstream temos só uma cópia parcial (23 arquivos,
   160 KB: configs + docs), não o toolchain completo.
2. **Não há commit upstream registrado** dos build-scripts usados. Falta
   anotar o commit (ou tag) para fixar a receita.
3. **Deriva do `apt`.** Nenhum snapshot do repositório Debian/Kali está
   fixado: duas instalações em datas diferentes podem trazer versões
   diferentes. A libfprint é a exceção (v1.94.10 fixo no script).
4. **A imagem de 10 GB não cabe em release asset** (limite de 2 GB por
   arquivo no GitHub). O arquivo `kali-hanoip-userdata.img` (10 GB) e o
   `.simg` (5 GB) continuam apenas locais.

## Caminhos para fechar

**Opção A — rebuild da base (recomendada, é a única "do zero").**
Clonar o *build-scripts* do Kali NetHunter em commit fixo, usar a nossa
`sm7150.toml`, gerar a imagem e escrever em `userdata` com
`write-userdata.sh` (com autorização). Custo: rede + tempo de debootstrap.
Falta: registrar o commit e testar uma geração completa.

**Opção B — publicar o rootfs já customizado.**
Comprimir com `snapshot-kali.sh` (`.tar.zst`) e publicar. O tar tende a ficar
abaixo de 2 GB (o `.simg` de 5 GB é imagem esparsa, não serve), o que
**caberia** como asset único. Ganho: rootfs idêntico ao validado sem rebuild.
Risco: publicar um sistema com configuração pessoal; filtrar antes (chaves,
histórico, `/var/lib/fpc-gk`, cadastro da digital).

**Opção C — não publicar nada e documentar o passo a passo.**
Quem reproduzir instala um Kali ARM64 do site oficial e roda os scripts de
customização. É o que já funciona hoje; a base fica por conta de cada um.

## Recomendação

A opção **A** é a que sustenta "do zero" e casa com o resto do repositório.
Enquanto ela não é feita, o rootfs é reproduzível **em customização** (todos
os scripts acima), não em base. Isso é diferente do kernel: lá o problema é
byte a byte; aqui é a origem da imagem e a deriva do `apt`.
