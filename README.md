# postmarketOS + Linux 7.3 mainline no Motorola Moto G60 (hanoip / SM7150)

Port do U-Boot mainline e do kernel Linux mainline (fork
[sm7150-mainline](https://github.com/sm7150-mainline/linux)) para o Moto G60
(codename `hanoip`, Snapdragon 730G / `sm7150` / `sdmmagpie`), com
postmarketOS e Plasma Mobile rodando de verdade.

> **Regra do projeto: nenhum flash.** U-Boot e kernel sobem só por
> `fastboot boot` (em RAM). A única área gravável do celular é a região não
> alocada no fim da partição `super` (espaço do slot B; o slot ativo é o A),
> onde mora o rootfs do pmOS. Metadados LP, partições `_a`, `userdata`,
> `persist` e `metadata` nunca são gravados. Detalhes em [AGENTS.md](AGENTS.md).

## Estado atual (26/10/2026)

| Item | Estado |
|---|---|
| Kernel | **Linux 7.3** (upstream v7.3 + 160 patches) — `work/kernel-7.3/v2/` |
| Retorno padrão (GOLD 26/10) | kernel #6 7.3, boot em ~40 s — `work/GOLD-20261026-1500/` |
| Sistema | postmarketOS v26.06 + Plasma Mobile, rootfs ext4 no fim do `super` |
| Display | DSI 1080×2460 @ 60 Hz com DSC, painel Tianma ILI7807S, brilho (WLED) |
| GPU | Adreno 618 com Freedreno/Mesa, KWin com OpenGL |
| Touch | ILI7807S TDDI por SPI, firmware só na RAM, segue a energia do painel |
| Rede | Wi-Fi WCN3990 (NetworkManager), USB NCM + SSH em 172.16.42.1 |
| Bluetooth | WCN3990 por UART (hci0) |
| Áudio | alto-falante (ADSP → SEC_MI2S → Awinic AW882xx) com PipeWire; **sem proteção do alto-falante ainda** |
| Vibração | vibrador LDO do PM6150 (`pm8xxx-vibrator`, teto de 3,0 V), usado pelo Plasma (feedbackd) |
| Lanterna e flash | PM6150L: flash traseiro (lanterna do Plasma) e flash frontal separados |
| LED de notificação | LED branco no TRILED do PM6150L (`white:status`), ligado ao feedbackd; **acendimento confirmado visualmente** |
| NFC | NXP PN54x (`nxp-nci`): o kernel lê cartões; falta app no Plasma |
| Botões | power e volume (+/−) funcionando no Plasma |
| Armazenamento | UFS, todos os blocos somente leitura exceto o rootfs |
| CPU | 8 CPUs, CPUfreq (qcom-cpufreq-hw), CPUidle local |
| Bateria | telemetria (PM6150 QG + SMB5); **carga ainda desligada** |
| Par de testes atual | U-Boot `work/perif-20261026/v5/` + kernel #6 `work/perif-20261026/v6-qrtr/` (áudio + periféricos + correção do Wi-Fi) |
| Pendente | ver [O que falta](#o-que-falta) |

## O que falta

Ordem sugerida: primeiro o que impede o uso diário, depois o resto.

**Energia (o mais urgente)**
- **Carga da bateria.** O SMB5 roda só em modo monitor: o celular descarrega
  mesmo no cabo (~−160 mA com a tela no máximo). Falta ligar a carga com
  limites conservadores, corte por temperatura (JEITA) e, depois, USB-PD.
  Escreve no carregador do PMIC, então precisa de autorização. Referência
  medida no Android carregando pelo USB do computador: entrada limitada a
  500 mA, corrente de carga até 3,6 A, flutuação 4,45 V, sem step charging
  nem JEITA por software, Type-C sem PD (aceitaria até 9 V).
- **Porcentagem calibrada.** Hoje é estimada pela tensão. O driver já aceita
  tabela OCV, mas falta descrever a bateria (tabela e resistência interna)
  no DT.
- **Suspend/resume.** O celular nunca dorme. Desligar o painel já funciona
  (o touch recarrega o firmware), mas o suspend do sistema nunca foi testado.
  O Android usa `deep`; com cabo e ADB conectados ele também não suspende,
  e as estatísticas de sono do SoC (RPMh) só existem no debugfs, ausente no
  kernel do Android.
- **CPUidle de cluster.** Só os estados locais das CPUs estão ligados; o
  colapso de cluster deixou a tela preta e está desativado.
- **Estabilidade prolongada.** Falta uma sessão de horas medindo
  temperatura, erros do DSI e memória.

**Display e entrada**
- **FIFO do DSI na partida.** Alguns boots ainda mostram erros de FIFO; a
  causa da tela preta ocasional não foi fechada.
- **90/120 Hz.** O painel do Android tem modos de 90 e 120 Hz; hoje só 60 Hz.
- **Fluidez.** Engasgos e travadas ao abrir apps vinham do devfreq da GPU
  e da UFS reagindo devagar; o serviço `hanoip-perf-tune` aplica um piso de
  355 MHz na GPU (reavaliação a cada 16 ms) e fixa a UFS em 200 MHz. Ainda
  dá para melhorar: direct I/O no loop do rootfs, zram e tempo real no KWin.
- **Touch: refinamento.** Cantos, orientação, calibração e gestos ficaram
  adiados de propósito.

**Áudio**
- **Proteção do alto-falante (antes de usar volume alto).** No Android o ADSP
  modela a temperatura da bobina; aqui não há proteção. Hoje o amplificador
  começa com 6 dB de atenuação (`/etc/modprobe.d/hanoip-speaker.conf`). Plano
  combinado, nesta ordem: (1) controle de volume ALSA com teto no driver +
  monitor de bateria/frio do vendor (tabelas do DT stock); (2) retorno de
  tensão/corrente (IV) do amplificador pela SEC_MI2S_TX; (3) `speakersafetyd`
  (pacote do Alpine) com parâmetros do hanoip; (4) passa-alta + limitador no
  PipeWire.
- **Formato de 24 bits.** Com S24_LE o caminho do ADSP toca ~48 dB mais baixo;
  o WirePlumber força S16LE como contorno. A causa no q6asm não foi vista.
- **Microfones e fone.** Passam pelo codec WCD937x (macros do LPASS +
  SoundWire) e pela chave `fsa4480` do USB-C; ainda não começou.
- **Áudio Bluetooth.** Depende da pilha de áudio; não testado.

**Telefonia e rádio**
- **Modem.** O modem sobe (necessário para o Wi-Fi), mas não há RIL: sem
  chamadas, SMS ou dados móveis. Firmware `M7150_25.333.01.85R`, perfil
  `HANOIP_LATAMDSDS_CUST` (dual SIM). Não há chip no aparelho (o Android
  também mostra os dois slots vazios), então telefonia só pode ser testada
  com um SIM inserido.
- **GPS.** Passa pelo modem; não investigado.
- **Hotspot Wi-Fi.** Não testado.

**Câmera e LEDs**
- **Câmeras.** Principal Samsung S5KHM2 (108 MP), ultrawide S5K4H7 (8 MP),
  OmniVision OV02B1B (2 MP) e frontal OV32B (32 MP), em dois barramentos CCI
  e quatro CSIPHYs, com EEPROMs e 2 atuadores de foco. Nenhum desses
  sensores tem driver no mainline; o fork tem o camss do SM7150.
- **Flash da câmera.** Os dois LEDs já acendem (traseiro e frontal), mas o
  modo flash só será usado quando houver câmera.
- **LED de notificação.** O feedbackd já programa o piscar por hardware no
  `white:status`; acendimento confirmado visualmente em 26/10.

**Sensores e periféricos**
- **Acelerômetro/giroscópio e luz/proximidade.** ICM4x6xx e TMD2755, ligados
  ao ADSP no Android. Firmware mapeado: SSC SE0/I3C (ICM) e SSC SE4/I²C
  (TMD). Teste real via ADSP/FastRPC + libssc, com registry em RAM: 382
  amostras do acelerômetro, luz de 0 a 72,5 lux observados e proximidade
  alternando FAR/NEAR. Giroscópio também testado: 665 amostras com resposta nos três eixos;
  orientação/calibração pendentes. Ver
  `docs/kernel/checkpoint-2026-10-26-sensores-teste-ssc.txt`.
  Integração Plasma/iio-sensor-proxy parcial: luz e proximidade chegam,
  mas o proxy não recebe amostras do accel via QMI (enable ok, zero
  mensagens; libssc recebe normal) e a orientação fica `undefined` —
  rotação automática adiada. Inversão de 180° medida quando fluía.
  Sem magnetômetro.
- **Leitor de digital.** Sensor FPC (há variante Chipone). No Android, a
  captura usa o TrustZone (`fpctzapp`); o helper do kernel só controla
  IRQ 90, reset 4 e pinctrl de alimentação 29 (30 é da alternativa Chipone).
  Modelo exato ainda desconhecido: `fpc1020` é o compatible genérico.
  SPI1/0x884000 é candidato forte pelos dados do TA/devcfg, sem teste AP.
  Falta o caminho QSEECOM legado e o protocolo HAL/FPC; carregar `qcomtee`
  moderno não fornece essa pilha. Ver o checkpoint FPC de 26/10.
- **Sensor SAR.** Semtech SX933x no I²C 1 (SE `0xa84000`, 0x28); nem o
  Android liga um driver nele.
- **NFC: aplicativos.** O kernel liga o PN54x e lê cartões (ISO 14443-A
  testado); o Alpine não tem o `neard`, então nenhum app usa o NFC ainda.
- **USB host/OTG.** Hoje a USB é só gadget (NCM + serial). O hardware faz os
  dois papéis (`dual power role`, dwc3 em OTG, regulador de VBUS
  `smb5-vbus`); falta a troca de papel do Type-C e esse regulador no
  mainline.
- **microSD.** Parado: as tentativas pediam 3,3 V num regulador que vai até
  2,95 V. Os patches estão guardados em `work/sd-20261025/saved-patches/`.
- **Vídeo por hardware.** O Venus decodifica H.264, H.265, VP8, VP9 e MPEG-2
  e codifica H.264, H.265 e VP8 no Android; no mainline ainda não foi ligado
  (o fork tem um nó WIP do Venus para o SM7150).

**Sistema**
- **Boot sem computador.** Tudo sobe por `fastboot boot` a partir do Mac;
  sem gravar partições, o celular não inicia o pmOS sozinho.
- **OTA do Android.** Uma atualização do Android usaria o espaço livre do
  `super` e apagaria o pmOS.
- **Firewall.** O kernel não tem nftables; o pmOS roda sem firewall.
- **Térmica sob carga.** As CPUs grandes chegam a ~74 °C; o controle
  térmico existe, mas não foi validado em carga longa.
- **Wi-Fi intermitente: confirmar a correção.** A corrida do QRTR que travava
  o modem em metade dos boots foi corrigida no kernel #6; falta confirmar em
  mais boots (os logs de cada boot ficam em `/var/log/hanoip-boot/`).
- **Upstream.** As correções do hanoip (LCDB, painel, touch, DSI, SMMU,
  bateria, pinos SSC do LPI, vibrador, QRTR) ainda não foram enviadas ao fork
  nem ao mainline. O helper da lanterna do Plasma Mobile 6.6.6 já tem
  correção no master (`ad036102`); o binário corrigido é usado até o Alpine
  atualizar.

## Como bootar (só volátil)

Com o celular no fastboot da Motorola (power + volume para baixo):

```
fastboot boot work/kernel-7.3/v2/u-boot-hanoip-pmos-v1.img   # espere o fastboot do U-Boot
fastboot boot work/kernel-7.3/v2/kernel-hanoip-pmos-7.3-v2.img
```

Par de testes com áudio e periféricos (mesmos passos, U-Boot
`work/perif-20261026/v5/u-boot-hanoip-pmos-perif-v5.img` e kernel
`work/perif-20261026/v6-qrtr/kernel-hanoip-pmos-7.3-qrtr.img`).

Para a GOLD atual, use uma **cópia** das imagens de `work/GOLD-20261026-1500/`
(a pasta é somente leitura e o helper grava um log ao lado da imagem). O
Plasma sobe em ~40 s (sem o hash integral da super no boot). SSH:
`ssh root@172.16.42.1` (só por chave).
O helper `work/hanoip-display-20261024/boot-volatile.py` faz os dois passos.

Como funciona: o ABL carrega o U-Boot como `boot.img`; o U-Boot passa ao
kernel o **DTB embutido nele** (o DT que vale é o de `uboot-sm7150/`). O
initramfs sobe display, USB, UFS (RO), Wi-Fi, BT e bateria, confere os
metadados LP e o ext4 no offset, monta o rootfs por `/dev/loop7` e faz
`switch_root` para o OpenRC.

## Onde está cada coisa

- `onde paramos.md` — handoff detalhado, comece por aqui.
- `AGENTS.md` — regras de segurança do aparelho e estado resumido.
- `work/kernel-7.3/v2/` — kernel 7.3: `patches/` (160 patches sobre v7.3),
  config, imagens, módulos e `README.txt` com a reconstrução.
- `work/GOLD-20261026-1500/` — GOLD atual (kernel #6 7.3, boot rápido),
  somente leitura, com `GOLD.txt` e `SHA256SUMS`. GOLDs anteriores em `work/GOLD-*`.
- `work/sensors-20261026/orient-fix/` — imagens v3/v4 de boot rápido,
  parser do registry e notas do diagnóstico de orientação.
- `work/audio-20261026/` — áudio do alto-falante: patches do driver
  AW882xx e dos pinos SSC do LPI, DTs e fases de bring-up.
- `work/perif-20261026/` — vibrador, flashes, LED, NFC e a correção do QRTR:
  patches, DTs, imagens por versão, helper da lanterna e ferramentas de teste
  (`tools/nfcpoll.py`, `tools/vib.py`).
- `work/pmos-super-20261025/` — `build-rootfs.sh` + `overlay/` recriam o
  rootfs pmOS do zero; `write-super-tail.sh` é o procedimento de gravação.
- `kernel-mainline/` — fonte do kernel 7.1 (#10) da GOLD v4.
- `uboot-sm7150/` — U-Boot (fork sm7150-mainline) com os DTs do hanoip.
- `scripts/` — scripts do initramfs e helpers de boot.
- `docs/kernel/` — checkpoints de cada etapa.

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
