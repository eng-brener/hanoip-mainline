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
| Retorno padrão (GOLD v4) | Linux 7.1 (kernel #10) — `work/GOLD-20261025-1659/` |
| Sistema | postmarketOS v26.06 + Plasma Mobile, rootfs ext4 no fim do `super` |
| Display | DSI 1080×2460 @ 60 Hz com DSC, painel Tianma ILI7807S, brilho (WLED) |
| GPU | Adreno 618 com Freedreno/Mesa, KWin com OpenGL |
| Touch | ILI7807S TDDI por SPI, firmware só na RAM, segue a energia do painel |
| Rede | Wi-Fi WCN3990 (NetworkManager), USB NCM + SSH em 172.16.42.1 |
| Bluetooth | WCN3990 por UART (hci0) |
| Armazenamento | UFS, todos os blocos somente leitura exceto o rootfs |
| CPU | 8 CPUs, CPUfreq (qcom-cpufreq-hw), CPUidle local |
| Bateria | telemetria (PM6150 QG + SMB5); **carga ainda desligada** |
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
- **Fluidez do Plasma.** Os engasgos vinham da GPU subindo de frequência
  tarde; o serviço `hanoip-gpu-tune` fixa um piso de 355 MHz e reavalia a
  cada 16 ms. Ainda dá para dar prioridade de tempo real ao KWin
  (`CAP_SYS_NICE`), que hoje roda com prioridade normal.
- **Touch: refinamento.** Cantos, orientação, calibração e gestos ficaram
  adiados de propósito.
- **Botões.** Power e volume aparecem como `gpio-keys`/`pwrkey`; falta
  conferir o mapeamento no Plasma.

**Áudio**
- **Alto-falante, microfones e fone.** O hanoip usa codec WCD937x pelos
  macros do LPASS, amplificador Awinic aw882xx (I²C 0 = SE `0x888000`,
  endereço 0x34) e chave de áudio do USB-C `fsa4480`. No Android o
  alto-falante sai por `MultiMedia1 → SEC_MI2S_RX → aw882xx` (I²S, não
  SoundWire); o aw882xx (chip ID `0x1852`) é inicializado pelo
  `aw882xx_spk_reg.bin` do vendor. Fone e microfones passam pelo WCD937x. Os nós do LPASS e do SoundWire já estão no kernel 7.3
  v2 (PRs #65/#60 do fork), mas desligados e fora do DT do U-Boot. O pinctrl
  do LPASS está bloqueado no autoload até ser validado.
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
- **Flash da câmera.** PM6150L com 2 canais (flash até 1150 e 600 mA,
  lanterna 500 mA); candidato ao `leds-qcom-flash`. O hanoip não tem LED de
  notificação.

**Sensores e periféricos**
- **Acelerômetro/giroscópio e luz/proximidade.** ICM4x6xx e TMD2755, ligados
  ao ADSP no Android. O TMD2755 não tem driver no mainline e o barramento
  (SE do QUP) ainda não foi achado. Sem eles: sem rotação nem brilho
  automáticos. Não há magnetômetro.
- **Leitor de digital.** Sensor FPC (há variante Chipone). No Android, a
  imagem é lida pelo TrustZone (app seguro `fpctzapp`) e o SPI do sensor
  nem aparece para o Linux; o kernel só cuida dos GPIOs (IRQ 90, reset 4,
  alimentação 30). Viabilidade muito baixa: exigiria falar com o TEE
  (`qcomtee`) e o protocolo fechado do app da FPC.
- **Vibração.** Vibrador LDO do PM6150 (SPMI `0x5300`, com `vmax_mv`);
  candidato ao driver `pm8xxx-vibrator` do mainline só com DT.
- **Sensor SAR.** Semtech SX933x no I²C 1 (SE `0xa84000`, 0x28); nem o
  Android liga um driver nele.
- **NFC.** NXP PN54x no I²C 0, endereço 0x28 (IRQ no GPIO 37, habilitação no
  GPIO 12, modo firmware no GPIO 36). Candidato ao driver `nxp-nci` do
  mainline, quase só DT.
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
- **Upstream.** As correções do hanoip (LCDB, painel, touch, DSI, SMMU,
  bateria) ainda não foram enviadas ao fork nem ao mainline.

## Como bootar (só volátil)

Com o celular no fastboot da Motorola (power + volume para baixo):

```
fastboot boot work/kernel-7.3/v2/u-boot-hanoip-pmos-v1.img   # espere o fastboot do U-Boot
fastboot boot work/kernel-7.3/v2/kernel-hanoip-pmos-7.3-v2.img
```

Para a GOLD v4, use uma **cópia** das imagens de `work/GOLD-20261025-1659/`
(a pasta é somente leitura e o helper grava um log ao lado da imagem). O
Plasma sobe em ~30–40 s. SSH: `ssh root@172.16.42.1` (só por chave).
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
- `work/GOLD-20261025-1659/` — GOLD v4 (7.1), somente leitura, com
  `GOLD.txt` e `SHA256SUMS`. GOLDs anteriores em `work/GOLD-*`.
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

## Histórico

Em agosto de 2026 o U-Boot chegou a ficar gravado no slot A e havia exemplos
de flash nesta página. Depois da perda de dados numa tentativa, a regra
passou a ser **não gravar partições**; aqueles exemplos foram removidos e não
devem ser repetidos. A evolução etapa por etapa (USB, UFS, display, touch,
CPUfreq/idle, Wi-Fi, BT, GPU, bateria, pmOS no `super`, kernel 7.3) está
nos checkpoints em `docs/kernel/` e no `onde paramos.md`.
