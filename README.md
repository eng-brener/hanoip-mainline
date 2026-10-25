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
| Pendente | carga da bateria, áudio (WCD937x + Awinic aw882xx), suspend/resume, modem, câmera, sensores |

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
