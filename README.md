# Linux 7.3 mainline no Motorola Moto G60 (hanoip / SM7150)

Port do U-Boot mainline e do kernel Linux mainline (fork
[sm7150-mainline](https://github.com/sm7150-mainline/linux)) para o Moto G60
(codename `hanoip`, Snapdragon 730G / `sm7150` / `sdmmagpie`). O aparelho roda
**multi-boot volátil**: postmarketOS + Plasma Mobile (histórico) e, desde
outubro, **Kali + NetHunter Pro com Phosh**, ambos sem gravar partição.

> **Regra do projeto: nenhum flash.** U-Boot e kernel sobem só por
> `fastboot boot` (em RAM). O DT que vale é o **embutido no U-Boot**
> (`CONFIG_OF_EMBED`), não o do `boot.img`. Metadados LP, partições `_a`,
> `userdata`, `persist` e `metadata` nunca são gravados. Detalhes e o histórico
> completo de autorizações em [AGENTS.md](AGENTS.md).

Todo o código, os patches e as receitas de build estão neste repositório e
**reproduzem do zero** — ver [Reproduzir do zero](#reproduzir-do-zero).

## Estado atual (31/10/2026)

| Item | Estado |
|---|---|
| Kernel | **Linux 7.3.0-sm7150** — 195 patches sobre upstream v7.3, árvore `276fbce0` (`work/kernel-7.3/v7/`) |
| Par de retorno | **PRE-GOLD-20261030-1430**: U-Boot cam-tres + kernel listener7 (#64) + Kali com digital |
| Experimento de 120 Hz | **PRE-GOLD-20261030-1730-120HZ** (volátil): `msm` corrigido + painel anunciando 119,976 Hz |
| Sistema | Kali + NetHunter Pro, Phosh; rootfs ext4 em `userdata` |
| Display | DSI 1080×2460 @ 60 Hz com DSC (Tianma ILI7807S); **120 Hz validado em troca de modo** (experimental) |
| Toque | Ilitek TDDI por SPI, firmware só na RAM, recarrega a cada power-on do painel |
| Digital (FPC) | TA no TEE, cadastro autorizado pelo Gatekeeper/HAT, fprintd via libfprint `hanoip_fpc`, app **Digital**, guardião de desbloqueio |
| Áudio | alto-falante, fone, earpiece, 3 microfones, detecção de jack e PipeWire validados |
| Câmeras | três validadas: S5K4H7 (wide), S5KHM2 (principal, C-PHY), OV32B (frontal); réguas e tunings instalados |
| CPU/GPU | 8 CPUs, CPUfreq, CPUidle local, piso de GPU 355 MHz |
| Rede | Wi-Fi WCN3990, USB NCM + SSH em 172.16.42.1, Bluetooth |
| Bateria | telemetria + **carga opt-in** (`/sys/kernel/debug/hanoip-charge`); SOC pela curva OCV do vendor |
| Suspender | **quebrado**: entra em `s2idle` e não retorna (ver pendências) |
| Reprodutibilidade | U-Boot **byte-idêntico**; kernel equivalente; módulos e DTB idênticos; artefatos-base em release |

## O que falta

Ordem sugerida: primeiro o que impede o uso diário, depois o resto.

**Suspender e energia**
- **Suspend (`s2idle`) não retorna.** Depois de 15 min ociosos o ambiente pede
  suspend e o aparelho não volta (o "voltar" após apertar power é reboot
  forçado). Em 28/10 funcionou por 31 s com o ADSP parado pelo hook
  `hanoip-adsp`; falta confirmar o hook e fechar o caminho. Evidências em
  `docs/kernel/checkpoint-2026-10-30-suspend.txt`.
- **Travamento com carga alta.** Em 30/10 o aparelho travou logo após abrir o
  Firefox: load 9,5 em 8 CPUs, SSH oscilando e milhares de escritas SPMI
  bloqueadas. Suspeitos não comprovados: GPU/msm, swap em zram, compositor.
- **Carga com a tela ligada.** A carga opt-in entrega ~497 mA; com a tela
  acesa o consumo passa disso. Próximo passo combinado: APSD/ICL (B4).

**120 Hz (experimental)**
- Medição óptica independente ainda não feita (só FPS de aplicação).
- Login com 119,976 Hz salvo abre com tela preta e `Timeout (3000ms)` do Phoc:
  voltar a 60 Hz antes de encerrar a sessão.
- Apagar/acender pelo compositor derruba a sessão gráfica; falta o A/B com o
  `msm` original.
- Sem teste de suspend, uso prolongado, térmica sustentada e bateria em 120 Hz.

**Câmeras e áudio**
- Câmeras: autofoco, LSC e recuperação do serviço em aberto.
- Áudio: proteção do alto-falante (hoje 6 dB de atenuação fixa), S24_LE ~48 dB
  baixo (WirePlumber força S16LE), microfones/fone pelo WCD937x e áudio BT.

**Sistema e periféricos**
- Sensores (ICM4x6xx/TMD2755) via ADSP/libssc: leitura ok, integração e
  orientação pendentes; sem magnetômetro.
- Modem sobe mas não há RIL (sem chamadas/SMS/dados); GPS e hotspot não testados.
- USB host/OTG (troca de papel do Type-C), microSD (parado por tensão).
- Venus: integrar de forma permanente e ligar nos players.
- Upstream: as correções do hanoip ainda não foram enviadas ao fork nem ao
  mainline.

## Como bootar (só volátil)

Com o celular no fastboot (power + volume para baixo), dois passos:

```
# par de retorno (Kali + digital)
fastboot boot work/PRE-GOLD-20261030-1430/uboot/u-boot-sm7150-motorola-hanoip-cam-tres.img
fastboot boot work/PRE-GOLD-20261030-1430/kernel/kernel-hanoip-listener7.img

# experimento de 120 Hz (mesmo U-Boot)
fastboot boot work/PRE-GOLD-20261030-1730-120HZ/uboot/u-boot-sm7150-motorola-hanoip-cam-tres.img
fastboot boot work/PRE-GOLD-20261030-1730-120HZ/kernel/kernel-listener7-dsifix-120hz.img
```

Espere o fastboot do U-Boot reaparecer entre os dois comandos. As pastas
PRE-GOLD são somente leitura; para logar o boot, use uma **cópia** da imagem.

Boot completo: o ABL carrega o U-Boot como `boot.img`; o U-Boot entrega ao
kernel o DTB embutido nele; o initramfs sobe display, USB, UFS (RO), Wi-Fi,
BT e bateria, monta o rootfs e faz `switch_root`. SSH: `ssh root@172.16.42.1`.

Trocar a taxa no 120 Hz (Voltar a 60 Hz antes de sair da sessão):

```
su kali -c "XDG_RUNTIME_DIR=/run/user/1000 WAYLAND_DISPLAY=wayland-0 \
  wlr-randr --output DSI-1 --custom-mode 1080x2460@119.976Hz"
```

## Reproduzir do zero

Precisa de Docker, git, python3, ~12 GB de disco e rede.

```sh
sh scripts/fetch-artifacts.sh     # imagens-base + U-Boot (release, com SHA256)
sh scripts/reproduce-all.sh       # U-Boot + kernel v7 + módulos do 120 Hz
sh scripts/reproduce-all.sh --verify   # confere os hashes conhecidos
```

Rootfs (aparelho ligado e autorização para escrever):

```sh
sh scripts/install-audio.sh --apply
sh scripts/install-cameras.sh --apply
sh work/fingerprint-20261029/integration/setup-kali-fingerprint.sh
```

Detalhes, limites e o que ainda depende de revalidação:
[docs/REPRODUZIR.md](docs/REPRODUZIR.md) e
[docs/INVENTARIO-REPRODUZIVEL.md](docs/INVENTARIO-REPRODUZIVEL.md).

**O que já é byte-idêntico:** U-Boot (`5cb08127…`), DTB do kernel e o módulo
`msm` do experimento (`e45516ee…`). **Equivalente, não idêntico:** `Image.gz`
do kernel e o módulo do painel.

**Segredos do aparelho nunca entram aqui:** `/var/lib/fpc-gk`, cadastro da
digital e credencial do Gatekeeper/HAT são específicos da máquina.

## Onde está cada coisa

- `AGENTS.md` — regras de segurança do aparelho e estado resumido.
- `onde paramos.md` — handoff detalhado do dia a dia.
- `docs/REPRODUZIR.md`, `docs/INVENTARIO-REPRODUZIVEL.md` — como reconstruir
  tudo e de onde vem cada peça.
- `docs/kernel/` — checkpoints por etapa (bateria, display, CPU, áudio,
  câmeras, digital, suspend).
- `work/kernel-7.3/v7/` — kernel atual (195 patches + config + `build.sh`;
  `README.txt` explica a árvore `276fbce0`).
- `work/kernel-7.3/v8-dsi/` — correções DSI + modo de 120 Hz (módulos).
- `work/PRE-GOLD-20261030-1430/` — par de retorno (U-Boot + kernel + rootfs
  reproduzível + digital).
- `work/PRE-GOLD-20261030-1730-120HZ/` — snapshot do experimento de 120 Hz.
- `work/uboot-builds-20261026/` — build reproduzível do U-Boot
  (`build-repro.sh`, patches e prova de hash).
- `work/fingerprint-20261029/integration/` — `setup-kali-fingerprint.sh`,
  app Digital, guardião e testes.
- `scripts/` — `hanoip_boot.py`, `hanoip-pmos-root.sh`, `install-audio.sh`,
  `install-cameras.sh`, `fetch-artifacts.sh`, `reproduce-all.sh`.
- `kernel-mainline/` — fonte mainline usada como referência e para os patches.
- `uboot-sm7150/` — árvore local do U-Boot (não versionada; o build
  reproduzível parte do fork + patches).
- `artifacts/base-images.sha256` — hashes das imagens-base publicadas no
  release `artefatos-base-20261031`.

## Lições do port

1. **DT do U-Boot**: com `fastboot boot`, o kernel usa o DTB embutido no
   U-Boot, não o do `boot.img`. Mudanças de DT vão no `uboot-sm7150/`.
2. **Memória**: o `/memory` não pode ser 4 GiB cheio. A RAM vai de
   `0x80000000` a `0x17dd00000`; declarar 4 GiB faz o U-Boot relocar para
   memória inexistente.
3. **OF_EMBED**: com `OF_SEPARATE` + header v3, o ABL perde o DTB anexado;
   o U-Boot usa `CONFIG_OF_EMBED`.
4. **UFS multi-LUN**: as partições ficam espalhadas por LUNs (LUN1 =
   super/userdata, LUN4 = `_a`, LUN5 = `_b`).
5. **Watchdog**: o U-Boot precisa parar o WDT (`wdt_stop_all()`) antes de
   entregar ao kernel, senão o aparelho reinicia em 30 s.
6. **Somente leitura**: uma partição só aparece como RO através do disco;
   fixe o RO de cada partição antes de liberar o disco para escrita.
7. **TDDI**: o ILI7807S perde o firmware do touch quando o painel desliga;
   o driver do touch é um *panel follower* e recarrega a IRAM.
8. **polkit**: precisa da variante `polkit-elogind`, senão brilho, loja e
   NetworkManager falham por falta de sessão.
9. **Pinos SSC do LPI**: o `lpass_tlmm` do mainline começa no gpio18 do
   vendor (gpioN mainline = gpioN+18 vendor). Os pinos do I²S do alto-falante
   (vendor gpio8–11, `0x62b48000`) ficam fora; uma segunda instância mapeia
   só esses 4 blocos. Ler a faixa SSC inteira por `/dev/mem` travou o SoC.
10. **QRTR no 7.3**: o commit `544d85de4dc2` cria uma corrida em que o modem
    nunca recebe o anúncio do rmtfs e o watchdog dele dispara ("DOG detects
    stalled initialization"); sintoma: Wi-Fi some em metade dos boots.
11. **PipeWire antes do Plasma**: subindo pelo autostart ele perde a corrida
    com o plasma-pa e as teclas de volume param; precisa ser serviço de
    usuário do OpenRC.
12. **Vibrador SPMI**: o `pm8xxx-vibrator` mainline gravava 0 no byte alto da
    tensão (`<< 8` em vez de `>> 8`), então o motor quase não recebia tensão.

## Histórico

Em agosto de 2026 o U-Boot chegou a ficar gravado no slot A e havia exemplos
de flash nesta página. Depois da perda de dados numa tentativa, a regra
passou a ser **não gravar partições**; aqueles exemplos foram removidos e não
devem ser repetidos. A evolução etapa por etapa (USB, UFS, display, touch,
CPUfreq/idle, Wi-Fi, BT, GPU, bateria, pmOS no `super`, kernel 7.3) está
nos checkpoints em `docs/kernel/` e no `onde paramos.md`.
