# Handoff — Moto G60 hanoip mainline

## >>> GOLD ATUAL: work/GOLD-20261025-1047/ (v2, promovida 25/10/2026 10:47 -03)
Retorno padrão; a GOLD-20261025-0126 fica preservada. Ver GOLD.txt na pasta.

## v2 (25/10/2026) — display automático antes da rede

`work/usbnet-20261025/v2/` (SHA256SUMS): kernel/DT/U-Boot = GOLD; ramdisk =
v1 + `/sbin/hanoip-autostart` (load-display, espera fb0=msmdrmfb, depois
start-usbnet; cmdline hanoip.nodisplay/hanoip.nonet pulam etapas) +
`/sbin/enter-pmos` + load-touch/load-display aceitando storage SE todo
`/sys/class/block/*/ro`=1. Init em `scripts/hanoip-v2-shell.init`.
run1: sem interação, fb0 aos 19 s, rede 22,6 s, SSH 28 s após envio;
6 IRQs FIFO na partida, usuário confirmou TEXTO. Depois: pmOS via
enter-pmos embutido OK, touch registrado, UFS enumerou em 1 s, 84 blocos
RO, mounts só RAM, DSI sem IRQ nova, tainted 4096 (O). Checagem do
load-touch: passa com tudo RO, recusa simulação com bloco RW.
fastboot max-download-size = 768 MB (embutir pmOS é viável).
Próximo: repetir boots da v2 (2-3) e promover a nova GOLD; depois UFS 100%
(descritores, gear sob carga, PM) e SD (sdhc_2: L9C/L6C, cd GPIO 69).
Coleta Android completa: `work/android-dump-20261025/` (LEIA-ME, privado).

## (anterior) Rede USB + SSH/SFTP — pausado 25/10/2026 madrugada

Celular ficou no **Android** (ADB ok). Nada gravado em partição.
Retorno padrão: `work/GOLD-20261025-0126/` (não modificar).

Variante em teste: `work/usbnet-20261025/v1/` (SHA256SUMS na pasta).
- Kernel/DTB/U-Boot IDÊNTICOS à GOLD; só o ramdisk muda (base = ramdisk GOLD).
- `/init` novo: `scripts/hanoip-usbnet-shell.init` — gadget configfs único
  1d6b:0104 (IAD 0xEF/2/1) com ACM (serial, `ttyGS0`) + NCM; se NCM falhar
  no bind, cai para só ACM. Monta devpts.
- `scripts/hanoip-start-usbnet.sh` (/sbin/start-usbnet, em background):
  links de applets em /usr/bin (sem mkfs/fdisk/tune2fs/fsck/etc.), usb0
  172.16.42.1/24, udhcpd entrega 172.16.42.2 ao host (sem rota/DNS),
  dropbear `-R -s` (só chave; host key gerada por boot em RAM).
- Dropbear 2026.94 + `sftp-server` do OpenSSH 10.6p1, estáticos com musl
  1.2.6 (compilado em /tmp/usbnet-build no container). Hashes das fontes
  conferidos com SHA256SUM oficial/OpenWrt. glibc estática deu segfault de
  NSS — não usar. authorized_keys = ~/.ssh/id_ed25519.pub do Mac.

Resultado do 1º boot (25/10):
- Mac: serial `cu.usbmodem211401` + interface `en10` com 172.16.42.2 (DHCP).
- ping ok; `ssh root@172.16.42.1` ok; SFTP put/get 64 MiB com hash igual
  (~28 MB/s); `scp -O` e `scp` ~21 MB/s (limite USB high-speed). Serial
  continua funcionando junto. tainted0, mounts só RAM/pseudo.
- **Display: TELA PRETA** com 2 IRQs FIFO DSI (`dsi_err_worker status=4`)
  no init do fb, contador estável em 2; sem Oops/SMMU. Log em
  `v1/dmesg-black.txt`, `v1/display-over-ssh.txt`.
  Diferença vs GOLD: display carregado aos ~72 s (após tráfego scp) em vez
  de ~27 s. Pode ser só o FIFO intermitente conhecido (já deu 0/2/6 IRQs);
  NÃO concluir que a rede causa.

Run2 (25/10, `v1/run2-early/`): mesmo par v1, display carregado pela
SERIAL aos 15 s, sem tráfego de rede iniciado: 5 IRQs FIFO na partida,
mas usuário confirmou TEXTO na tela. Depois ~320 MiB scp/SFTP com hashes
iguais: contador ficou em 5 (nenhuma IRQ nova), tela continuou com texto
(confirmado). Leitura: risco está na inicialização do display, não na rede
depois; número de IRQs na partida não prevê preto (2=preto, 5=texto).
Uma amostra por lado: não é prova. Prática adotada: carregar o display
ANTES de tráfego de rede. Proposta v2: /init carrega display automaticamente
e só depois sobe rede/SSH.

**postmarketOS em RAM (25/10, mesmo boot run2):** `work/pmos-20261025/`.
Rootfs pmOS v26.06 (Alpine 3.24), 156 pacotes (postmarketos-base,
alpine-base, bash, htop, nano, iproute2, iperf3, usbutils, evtest,
fastfetch), montado com apk no container `alpine:3.24` arm64 (precisa
`docker run`; o container de build antigo não tem rede). Chave pmOS de
pmbootstrap main `pmb/data/keys/build.postmarketos.org.rsa.pub` (sha256
b70e6ffc...). Sem pacote de kernel/device; mkinitfs pulou (sem deviceinfo).
Tarball 41,5 MB -> scp 1,9 s -> `scripts/hanoip-enter-pmos.sh` (copiado
como /run/enter-pmos; some no reboot) monta tmpfs 1 GiB em /mnt/pmos,
extrai, bind de proc/sys/dev/dev/pts/run/tmp e faz chroot. NÃO roda
OpenRC/init do pmOS, recusa se houver mount não-RAM. Resultado: fastfetch
"postmarketOS v26.06 / Motorola Moto G60 / DSI-1 1080x2460", bash 5.3.9,
123 MiB usados, tainted0, DSI continuou em 5.
Uso: `scp -O tarball root@172.16.42.1:/tmp/pmos-rootfs.tar.gz`, depois
`ssh -t root@172.16.42.1 /run/enter-pmos`.
Pendente: incluir enter-pmos no ramdisk da v2; internet no celular (NAT
pelo Mac) para `apk add`; mais tarde switch_root com OpenRC. Comandos SSH do Mac (zsh):
`ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 root@172.16.42.1`
Para SFTP: `sftp` com as mesmas opções. Se ADB não aparecer no Android,
entrar no bootloader com Power + Volume-.
Depois da rede: atualizar `load-touch` para aceitar storage só se tudo RO.

Atualizado em 24/10/2026. O usuário pediu este arquivo para outra IA continuar
mais tarde. **Não iniciar novos testes automaticamente por causa deste arquivo.**

Workspace: `/Volumes/SSDExterno/Users/brener/developer/hanoip-mainline`.
Leia também `AGENTS.md`, que preserva a regra de segurança entre sessões.

## Regra absoluta do usuário

**Não dar flash em nada e não gravar nenhuma partição do celular.**
O usuário perdeu dados/drivers de uma partição em uma tentativa anterior.

- Proibidos flash, erase, format, update, troca de slot, gravação em dispositivos
  de bloco, reparos de filesystem e envio de arquivos a filesystems persistentes.
- Não executar os exemplos antigos de flash dos READMEs/documentação de agosto.
- Permitidos: fontes/builds/arquivos no computador, consultas ADB com root em
  somente leitura e testes voláteis com `fastboot boot`, já autorizados.
- O initramfs de teste fica em RAM. Nenhuma partição é montada, inclusive UFS.
- Carregar módulos e firmware na RAM interna do touch é parte do teste volátil.
  O novo driver não implementa programação de flash do controlador.
- Preservar imagens conhecidas e seus hashes; criar outra pasta para cada variante.

## Situação atual — repetibilidade e início da etapa CPUfreq

O usuário aprovou esta ordem: (1) repetir/consolidar boot, (2) energia/CPU,
(3) robustez LCDB/display, (4) rede/GUI. Touch fino fica para depois.

### Baseline mais recente: quiesce-late

Par em RAM:
- Kernel: `work/display-repeat-20261024/quiesce-late/kernel-hanoip-quiesce-late.img`
  SHA256 22fc61f9593fff3fc91ef877407fd7d53783388147728a6d4ebd7e117b37a732.
- U-Boot: `work/hanoip-touch-20261024/handoff-v2/u-boot-hanoip-touch-handoff-v2.img`.
- Mesmo Image Linux #8/DT, reservas, BCR contornado, UFS desabilitada e CPU flags.
  Mudanças recentes estão apenas nos módulos do ramdisk.

Duas execuções desse MESMO par tiveram imagem estável confirmada pelo usuário:
- `quiesce-late/load.txt`: 6 IRQs FIFO iniciais, sem timeout de comandos/video done.
  `steady.txt` confirmou contador ainda em 6 até uptime209,16s; tainted0,
  sem SMMU/Oops, DRM ativo, apenas RAM/pseudo mounts e ram0..ram15.
- `quiesce-late-repeat/load.txt`: ZERO IRQs de erro DSI, sem timeouts/SMMU/Oops.
  Usuário confirmou "sim texto estavel".
Não declarar estabilidade longa/ciclos frios nem todos os boots livres de FIFO.

Correções presentes:
- Brilho Tianma: stock é 51 03 32; helper normal emitia 51 32 03. Agora usa
  bytes explícitos big endian, só na sequência Tianma.
- Em host_power_on, só hanoip/DSC/VIDEO: desliga ENABLE/VID/CMD antes do reset
  DSI local, evitando restaurar VIDEO ativo herdado dentro de dsi_sw_reset.
  Captura provou pre_ctrl=0x1f7/pre_status=0x8 -> post_ctrl=0x1f1/post_status=0.
- Em dsi_manager, só hanoip/Tianma/VIDEO/single DSI: pre_enable prepara link e
  transporte de comandos; inicia vídeo em bridge.enable após panel.prepare.
  Essa mudança isolada falhou; só a combinação acima passou os testes recentes.
- error_snapshot no platform DSI cacheia ACK/FIFO/TIMEOUT/PHY/STATUS0/CLK na IRQ.
  Sua leitura é de software, não envia comandos DSI. Mantém IRQ/avisos originais.
- panel_status no dispositivo MIPI-DSI faz leituras DCS LP. NÃO usar em loop:
  essas consultas geraram DSI status0x16. Não usadas nos testes quiesce-late.

### CPUfreq validado; CPUidle agora em teste

Par CPUfreq validado em `work/cpufreq-20261024/quiesce-late-baseline/`:
`kernel-hanoip-cpufreq.img` + `u-boot-hanoip-cpufreq.img`. Image/ramdisk iguais
à quiesce-late; DT só remove cpufreq.off=1; mantém seis CPUs e idle off.
Driver qcom-cpufreq-hw, policy0 relacionada a CPUs0..5, 300000..1804800 kHz.
Governor powersave -> 300000/300000 solicitado/reportado por hardware;
performance ->1804800/1804800; schedutil ->1248000/1248000 na amostra.
Teste dois segundos por governor, restaurou schedutil, saiu0. Temperaturas
39..42,5 °C, DSI permaneceu com ZERO erros, tainted0, sem Oops/SMMU.
Usuário confirmou "sim estavel". Logs e governor-analysis.json na pasta;
ver docs/kernel/checkpoint-2026-10-24-cpufreq.txt. Sem medição elétrica/stress.

CPUidle completo foi testado no par `work/cpuidle-20261024/` (só removeu
cpuidle.off=1). psci_idle/menu registrados, 18 estados (WFI+2 por CPU).
Contadores em 6s mostram uso de PC/rail-PC em todos os CPUs, mas o usuário
relatou TELA PRETA e demora maior. Não promover esse par como display validado.
No display houve 2IRQs FIFO iniciais, sem novos até uptime255s, tainted0.
`idle-analysis.json` contém os deltas; isso NÃO prova combinação funcional.
Desabilitamos states1/2 em runtime (só sysfs): `disable-idle-runtime.txt`.
CPU0 state2/rejected mostrou2, vários usos bem-sucedidos. Recuperação visual
após desabilitar não foi confirmada antes do teste seguinte.

Próxima variante em boot: `work/cpuidle-20261024/local-only/`, par
kernel-hanoip-cpuidle-local.img + u-boot-hanoip-cpuidle-local.img.
Inclui CPUidle, mas remove domain-idle-states de cluster_pd para testar apenas
PC/rail-PC dos núcleos, sem L3/CX/AOSS collapse. Bootargs iguais ao teste full,
Image/ramdisk iguais ao CPUfreq validado. RAM/22reservas/UFS/proteções conferidos.
**Resultado 25/10/2026: local-only PASSOU em 2 boots** (`local-only/` e
`local-only-repeat/`): DSI irqs=0, connected/enabled, tainted0, sem
Oops/SMMU, CPUs0..5 ~5 s de 5 s em cpu-sleep-0-1 (rail-PC), rejected0,
34,5..37,5 °C. Usuário confirmou imagem nas duas ("sim mostra na tela").
Ver `docs/kernel/checkpoint-2026-10-25-cpuidle.txt`. Colapso de cluster é o
suspeito principal da tela preta, NÃO causa comprovada. Novo par de retorno
com energia: local-only. O par CPUfreq quiesce-late-baseline com
cpuidle.off=1 continua preservado. Coleta serial: `local-only-repeat/collect-sershell.py`
(termios puro; pyserial não está instalado no Mac).
Próximas pendências: bateria/carregador, robustez LCDB/display, CPUs6/7,
estabilidade longa, suspend; colapso de cluster com display fica para depois.

**UFS com tudo ligado, 25/10/2026** (`work/ufs-20261025/ufs-local/`): par
local-only + UFS (DT só habilita ufshc/phy; Image #8 igual; módulos UFS
recompilados contra a árvore #8). Um boot: display DSI irqs=0, UFS 6 discos
/84 blocos todos RO, sdb 64KiB = hash Android, leituras ~510 MB/s, touch
event3 com eventos (insmod manual: load-touch recusa storage exposto),
idle/cpufreq ativos, zero erros. Ver
`docs/kernel/checkpoint-2026-10-25-ufs-tudo-ligado.txt`.

**VERSÃO GOLD (marcada pelo usuário em 25/10/2026 01:26 -03):**
`work/GOLD-20261025-0126/` — cópia somente leitura deste par ufs-local,
com GOLD.txt e SHA256SUMS (kernel c99f8cf5..., U-Boot 33c05711...).
É o retorno padrão daqui em diante. Validada em um boot; repetir antes
de mudanças grandes. Uso apenas com fastboot boot, nunca flash.

### Evidência e variantes anteriores

- `work/boot-repeat-20261024/run1/`: par original handoff-v2 repetido deu preto,
  apesar de DRM ativo/sem falhas SMMU. Unblank, carga do touch e preenchimento
  branco de /dev/fb0 (confirmado por releitura) não recuperaram a imagem.
- `panel-status/` e `panel-status-repeat/`: texto estável duas vezes; segunda
  sem consultas DCS. Leituras do primeiro deram power0x9c (igual ao esperado
  pelo stock), pixel0x07, diagnostic0xc0, prepared/enabled1, resetlogical0.
- `brightness-be/` e `brightness-be-repeat/`: ambos com texto estável, mas o
  segundo teve 7 erros DSI status4 na partida, antes do fbdev pronto.
- `dsi-snapshot/`: raw FIFO primeiro0x88881018/OR0xdddd1019, 7IRQs e timeout
  video done. Bits confirmam underflow de vídeo e das quatro lanes HS, além
  de overflow posterior. Categoria status4 sozinha não mostra esse detalhe.
- `late-video/`: FALHOU; primeiro comando ff780700 deu DMA timeout -110/painel
  não inicializou, preto. Código foi retirado antes do teste seguinte.
- `quiesce-inherited/`: provou limpeza do VIDEO herdado, mas com sequência
  pre_enable original ainda teve 6IRQs FIFO/timeout. Usuário descreveu boot com
  texto, USB/brilho, cinza/preto, mais texto/piscadas e depois linha estável.
  Nem toda transição visual corresponde a reset ou ausência final de imagem.

Pendências: FIFO inicial pode reaparecer; dependência de DISPCC/PLL/estado DPU
herdado e LCDB ainda não resolvida. MDSS core BCR não foi reintroduzido. Não houve
mudança global de IOMMU, reservas, tensão ou partições. Fontes/patches/hashes e
logs estão em cada variante. Referência da sequência DRM:
https://docs.kernel.org/gpu/drm-kms-helpers.html#mipi-dsi-bridge-operation

## Retomada após o handoff — 24/10/2026

O usuário pediu para continuar com o celular conectado. Ele apareceu inicialmente
no fastboot Motorola (`ZF523QJBSG`, product `hanoip`). Nenhum flash foi executado.

- Conferimos os hashes do handoff e o DT efetivo: 22 reservas idênticas, sem
  sobreposição, UFS desabilitada, splash 0x9c000000/0x1700000, sem BCR MDSS.
- Empacotamos e bootamos o par de `handoff-unbooted/` APENAS com fastboot boot.
  **Apesar do nome, essa pasta agora contém um teste já executado e FALHO.**
- `handoff-unbooted/preflight.txt`: o mapa criado no MSM antes do attach retornou
  -ENODEV. A causa foi confirmada nas fontes: `arm_smmu_map_pages` não tem
  pgtbl_ops até `arm_smmu_init_domain_context`, chamado no attach.
- A limpeza da falha chamou `drm_atomic_private_obj_fini` duas vezes e causou
  Oops no `dpu_kms_destroy`. O shell continuou ativo, tainted=128; mounts apenas
  RAM/pseudo e só ram0..ram15, confirmado em `after-failure.txt`.
- Ajustamos o mapa para um hook específico hanoip/MDSS em arm-smmu.c,
  DEPOIS da inicialização das tabelas e ANTES de instalar os S2CRs. Mantém
  somente IOMMU_READ, range exato, booleano por domínio para não remapear.
  MSM só valida/reserva o range no allocator IOVA; não mapeia antes do attach.
- Corrigimos a limpeza dupla com `global_state_initialized` em dpu_kms.c/.h.
- Novo Image e msm.ko compilaram sem erros, modpost estrito:
  `work/hanoip-touch-20261024/handoff-v2/`. Fontes, patch e hashes preservados.
- Novo kernel: `handoff-v2/kernel-hanoip-touch-handoff-v2.img` (SHA256
  14a9df08f290341ff3637529807b6c3a6d4b6f6360300d5e794708fd129ca1c3).
  Usar explicitamente o U-Boot de `handoff-unbooted/u-boot-hanoip-touch-handoff.img`.
  O DT é igual ao primeiro handoff. Esta versão altera o Image builtin também.
- Após `/sbin/reboot`, o aparelho voltou ao Android. O helper detectou o ADB,
  reiniciou para o bootloader e executou os dois fastboot boot. O segundo kernel
  abriu USB serial, build #8. `handoff-v2/display-load.txt` mostrou o mapeamento
  antes da troca dos streams, DRM inicializado, fb0=msmdrmfb, connected/enabled
  e modo 1080x2460. Sem falhas SMMU, timeouts DSI ou Oops nesse teste.
- `handoff-v2/visual-test.txt`: mensagem "HANOIP MAINLINE - TESTE 2" enviada a
  tty1; o usuário confirmou "sim tem mensagem na tela". tainted=0. Touch também
  inicializou com PID/IRAM/FW corretos; contadores iniciais zero.
- Primeira tentativa de captura `input-events.txt` não abriu o leitor porque
  BusyBox antigo requer `timeout -t 45`, NÃO `timeout 45`.
  Captura corrigida em `input-events-45s.txt`. Não interpretar a tentativa
  inválida como um teste físico sem eventos.

### Resultado mais recente desta retomada

**Display confirmado visualmente e touch físico validado, inclusive dois dedos.**
O usuário disse: "sim tem mensagem na tela". Primeira captura:
1949 eventos, 15 contatos/15 solturas. Segunda: 4453 eventos, 42 contatos/42
solturas, máximo observado dois dedos, sem contatos presos. Coordenadas dentro
dos limites declarados. Stats acumuladas: irqs=2347 reports=2347 rejected=0,
tainted=0. Logs/análises em `handoff-v2/input-*.txt` e `input-*-analysis.json`.
A segunda captura representa ~6,73 s de eventos dentro da janela de 30 s.

Par completo preservado em `work/hanoip-touch-20261024/handoff-v2/`:
`u-boot-hanoip-touch-handoff-v2.img` (cópia idêntica do U-Boot do handoff) +
`kernel-hanoip-touch-handoff-v2.img`. DTs e uboot.config também copiados ali.
Não substituir os checkpoints USB/UFS/display anteriores.

Decisão do usuário após este checkpoint: deixar o touch "redondo" mais tarde.
Adiar calibração/orientação, cantos, cobertura, filtros, demais slots e gestos;
não iniciar esses trabalhos automaticamente. O touch básico com dois dedos já
foi validado. O display está confirmado visualmente neste boot; isso ainda não
valida ciclos frios, suspend, GPU ou rootfs.

Prioridade revista após o usuário pedir para "voltar umas casas": rede USB
fica depois de estabilizar a base. Próximo trabalho recomendado é verificar
repetibilidade do boot em RAM e gestão de energia/CPU, antes de userspace/GUI.
Auditoria somente leitura em `work/base-audit-20261024/LEIA-ME.txt` e runtime.txt:
seis de oito CPUs online; CPUfreq/CPUidle desabilitados por cmdline; bateria/carga
não expostas; sensores térmicos funcionam (36,1..38,7 °C nessa amostra).
`idle=poll` foi reportado desconhecido pelo ARM64, não assumir polling efetivo.
Investigar uma mudança por vez; não reativar todos os recursos de uma vez.
LCDB ainda precisa robustez antes de ciclos de alimentação/suspend do painel.
Esta revisão não alterou o hardware nem iniciou outro boot.
O aparelho foi deixado no Linux temporário, display/touch carregados; consultar
`handoff-v2/final-state.txt` e detectar USB de novo ao continuar.
Ver `docs/kernel/checkpoint-2026-10-24-touch.txt` para o checkpoint atualizado.

O restante deste arquivo descreve o histórico anterior. As afirmações abaixo
sobre a correção "ainda não bootada" referem-se ao estado antes desta retomada;
o resultado atualizado acima tem precedência.

## Onde efetivamente paramos

1. **O display funcionou visualmente.** O usuário confirmou que a mensagem
   enviada ao console apareceu na tela no checkpoint anterior.
2. Criamos um driver mínimo para o **touch Ilitek ILI7807 por SPI**. Ele identificou
   o PID, carregou/verificou os três blocos de firmware em IRAM e registrou input.
3. **Toques físicos ainda NÃO foram validados.** Uma captura de 35 segundos
   terminou sem eventos; estatísticas `irqs=0 reports=0 rejected=0`. Não houve
   confirmação explícita de que o usuário realizou os gestos nessa janela.
4. Nesse novo boot, o display teve falhas SMMU durante a passagem do framebuffer
   ABL para o domínio DMA do DRM. O usuário relatou: **“a tela ta preta aqui”**.
5. Preparamos uma correção específica para preservar o mapeamento do framebuffer
   antigo durante essa transição. **Compilou com modpost estrito, mas NÃO foi
   empacotada em novas imagens nem testada no aparelho.**
6. O usuário pediu o handoff antes desse próximo boot. Não continuamos os testes.

### Estado do aparelho no encerramento

- Último estado consultado por shell: Linux temporário, display preto, touch
  inicializado, contadores zero, apenas `ram0` a `ram15`, mounts em RAM/pseudo.
- **Na última checagem do host, não apareceu nenhum aparelho em ADB, fastboot ou
  `/dev/cu.usbmodem*`. A causa não foi determinada.** Pode ter mudado de estado ou
  sido desconectado; não assumir que continua no Linux ou que voltou ao Android.
- Nenhuma nova reinicialização foi solicitada após o pedido deste arquivo.

## Hardware e acesso

- Moto G60, `hanoip`, XT2135-1, Qualcomm SM7150/732G.
- Serial Android/ABL fastboot: `ZF523QJBSG`.
- Android tem root: `adb ... exec-out su -c 'COMANDO_SOMENTE_LEITURA'`.
- Kernel Android: `4.14.206—CosmicFresh-R6-Final`.
- Slot observado: `_a`. Não alterá-lo.
- Linux de diagnóstico: `7.1.0-sm7150`; última imagem do touch mostrou build `#7`.
- USB ACM Linux costuma ser `/dev/cu.usbmodem211401`, mas descobrir novamente.
- U-Boot volátil pode anunciar serial `????????????`. Não usar essa string em
  `fastboot -s`: já causou espera. Confirmar um único aparelho e consultar
  `fastboot getvar product`, esperando `motorola-hanoip`, antes do boot do kernel.
- Cada `fastboot boot` do U-Boot demora cerca de 10,4 s. Linux abre USB em ~7–20 s.
- O DT efetivo entregue ao Linux é o **DT embutido no U-Boot**, não apenas o DTB
  empacotado em `boot.img`. Alterações de DT precisam chegar às duas árvores.

## Checkpoints preservados

### USB e UFS em leitura

- `work/hanoip-build-20261024/v2/`: par sem UFS com shell USB validado.
- `work/hanoip-ufs-modules-20261024/iommu/`: par UFS validado em leitura.
  Seis discos, 78 partições, todos os 84 block devices marcados somente leitura.
  Três leituras de 64 KiB de `/dev/sdb` deram o mesmo SHA e conferiram com Android.
- Manter `iommus = <&apps_smmu 0x300 0x0>` na UFS: sem isso, houve NOP OUT timeout
  com a configuração SMMU strict. Não remover nem usar passthrough global.
- Documentação: `docs/kernel/checkpoint-2026-10-24-ufs-leitura.txt`.
- Originais preservados em `work/baseline-before-qup-2026-10-24/`.

### Display confirmado pelo usuário

Par em `work/hanoip-display-20261024/no-reset/`:

- `u-boot-hanoip-display-noreset.img`
- `kernel-hanoip-display-noreset.img`

O usuário disse **“apreceu a mensagem na tela pode seguir”**. Logs comprovaram:
`card0-DSI-1` connected/enabled, CRTC ativo 1080×2460 a 60 Hz, pixel clock
343458 kHz, dois DSC, `fb0=msmdrmfb`, pitch 4352. GPU desabilitada nesse teste.
Isso valida aquele boot, não estabilidade de todos os handoffs.

Fontes/ajustes dessa etapa:

- Painel Tianma ILI7807S: reset elétrico alto 4 ms, baixo 1 ms, alto 12 ms,
  traduzido para GPIO_ACTIVE_LOW; VFP 2565, VBP 12, VPW 2.
- DSC 1.1, slices 540×10, duas por pacote, 8 bpc/8 bpp, block prediction;
  PPS após a sequência vendor. Backport upstream da flag
  `MIPI_DSI_MODE_DSC_ALL_SLICES_IN_PKT`, não do campo experimental da PR69.
- WLED strings 0/1/2 (stock bitmask 7), brilho inicial 512/4095,
  25000 µA por string, boost 1400 mA, OVP 26500 mV.
- `qcom,sm7150-mdss` adicionado a `qcom_smmu_client_of_match` em
  `drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c`. Mantém domínio identity inicial
  como em outros SoCs, necessário antes de o DRM assumir o display.
- DISPCC definia `mdss_gdsc`, mas não o registrava: restauramos `.gdscs` e
  `.num_gdscs` em `drivers/clk/qcom/dispcc-sm7150.c`.
- O reset BCR do core MDSS reiniciou o aparelho. Logs instrumentados em
  `work/hanoip-display-20261024/trace/msm-registration.txt` terminaram em
  `HANOIP MDSS: asserting reset`, sem `reset released`.
  Só os DTs de diagnóstico omitem `&mdss` `resets`. O reset GPIO do painel
  continua presente. Não reintroduzir esse BCR sem investigar.
- Fontes mantêm a configuração PLL/clocks herdada do ABL. Ainda não restauramos
  todo o init de PLL/gating do DISPCC upstream.
- `docs/kernel/checkpoint-2026-10-24-display.txt` contém detalhes e limites.

## Touch: o que foi feito e o que falta

### Referência e firmware original

Fontes públicos de referência:
`Dark-Matter7232/CosmicFresh-Hanoip`, commit
`9eecac9f6efd66fd2915fd80dd822d690ecbc207`, diretório
`drivers/input/touchscreen/ilitek_v3_mmi/`.
Cópias/proveniência estão em `work/hanoip-touch-20261024/vendor/` e
`provenance.json`. Não importamos integralmente o driver Android com seus
notificadores antigos, interfaces de fábrica, dumps e possíveis efeitos.

Coleta SOMENTE LEITURA do Android:

- `/proc/ilitek/ver_info`: chip `7807`, FW `16.0.10.0`, core `1.4.6.8`,
  protocolo `5.6.0`, driver `3.0.4.0.200731`.
- `getevent -lp`: 10 slots, X 0..1079, Y 0..2459, INPUT_PROP_DIRECT.
- `/vendor/firmware/FW_ILITEK_TDDI_TM.bin` copiado apenas para o computador.
  358761 bytes, SHA256
  `2be3ce9836bfe1ff90a32ad7b081389c0126cac47a0b058c8ecf3446248335e7`.
  Apesar da extensão, é Intel HEX, com checksums válidos.

`scripts/hanoip_ilitek_firmware.py` valida HEX, cobertura, CRC dos blocos e
identidade/layout específicos do hanoip. Gera um container local com AP,
DATA e TUNING; exclui MP/fábrica. Não faz operações no aparelho.

`work/hanoip-touch-20261024/hanoip-7807-iram.bin`: 90724 bytes, SHA256
`ef3e38c1e9dda6700ec29d09e7ec7f7c957b269ad6a56027c4ffb527051c314f`.

| Bloco | Destino IRAM | Bytes | CRC |
|---|---:|---:|---|
| AP | 0x00000 | 81920 | 0xfea9bcbd |
| DATA | 0x20870 | 8192 | 0xca3e7527 |
| TUNING | 0x20670 | 512 | 0x94d9c4dd |

### Driver novo

`kernel-mainline/drivers/input/touchscreen/ilitek-hanoip-spi.c`

- Kconfig `CONFIG_TOUCHSCREEN_HANOIP_ILITEK_SPI=m`;
  `configs/hanoip-touch.fragment`. O driver Ilitek I²C antigo não serve.
- SPI6 em 0xa80000, modo 0, até 10 MHz conforme driver stock;
  reset TLMM8, IRQ TLMM9 falling edge. O DT stock dizia level-low, mas o
  driver Android forçava falling; a variante de DT nova representa isso.
- Valida o container antes do reset. Só aceita os endereços/tamanhos coletados.
- SPI ICE → PID → carga IRAM → releitura de todos os bytes → code reset →
  verificação da versão rodando → formato demo → input com 10 slots.
- Sem comandos de apagar/programar flash do touch, sem gravações de arquivos,
  sem interfaces de fábrica, sem recovery automático ou suspend/gestures.
- Pacotes demo 0x5a/43 bytes, checksum, limites e escala 2048→1080/2460.
- Estatística somente leitura: `/sys/bus/spi/devices/spi6.0/stats`.
- `scripts/hanoip-load-touch.sh`: guard RAM-only/sem discos, carrega evdev e
  touch manualmente; `/sbin/load-touch` no initramfs.

### Evidência no hardware

Primeiro par do touch em `work/hanoip-touch-20261024/`:
`u-boot-hanoip-touch.img` + `kernel-hanoip-touch.img`.
**Não promovê-lo a display validado: teve tela preta neste boot.**

`touch-load.txt` comprovou:

```text
Ilitek PID 0x78071c03
IRAM block 1: 81920 bytes verified at 0x0
IRAM block 2: 8192 bytes verified at 0x20870
IRAM block 3: 512 bytes verified at 0x20670
FW response 21 10 00 0a 00 10 00 02 00
input: Hanoip Ilitek ILI7807 SPI ... input3
ILI7807 ready: 1080x2460, 10 slots, IRAM only
```

Registrou `/dev/input/event3`. IRQ 160, TLMM9, Edge, `spi6.0`.
`input-events.txt` capturou 35 s sem eventos. `before-handoff-retest.txt`
confirmou `irqs=0 reports=0 rejected=0`, apenas RAM e nenhum mount persistente.
Não afirmar que touch está funcional: falta gesto físico confirmado e eventos.
Também é possível que o touch TDDI dependa do painel ativo; estabilizar display
antes de concluir que o IRQ/driver está errado.

## Bug de memória/display em investigação AGORA

O domínio inicial identity resolveu o boot, mas falta preservar o framebuffer
antigo quando o DRM cria/anexa seu domínio paginado próprio.

Neste boot, durante o handoff, apareceram leituras SMMU sem mapeamento em
`0x9c...`, SIDs `0x800`/`0xc40`, depois erros DSI status=4 e
`wait for video done timed out`. O DRM criou `msmdrmfb`, mas a tela ficou preta.
**Esses erros ocorreram em uptime ~753 s; o touch só começou em ~772 s.**
Portanto não atribuir esses erros à carga do touch.

### Correção já escrita/compilada, AINDA NÃO BOOTADA

Fontes alterados:

- `msm_iommu.c`: antes de `iommu_attach_device`, para a combinação específica
  `motorola,hanoip` + `qcom,sm7150-mdss`, lê `memory-region` e mapeia o range
  reservado de splash com identidade e permissão IOMMU_READ.
  Rejeita ranges diferentes de `0x9c000000`, tamanho `0x01700000`.
- `msm_mmu.h`: guarda `firmware_start`, inicializado a zero.
- `msm_kms.c`: limita as alocações virtuais do display à região abaixo desse
  mapeamento para não haver colisão de IOVA. **Isso não diminui a RAM física.**
- DTs de display diagnóstico, nas duas árvores: `memory-region = <&cont_splash_mem>`.
  A reserva física em si não foi ampliada nem mudada.

É uma correção experimental específica do port, não uma solução upstream genérica.
Ainda é necessário verificar no hardware: sucesso do mapeamento antes do attach,
ausência de novas falhas SMMU/DSI, modeset e confirmação visual.
O `msm.ko` antigo dentro das imagens atuais NÃO contém essa correção.

Artefatos compilados preservados em:

`work/hanoip-touch-20261024/handoff-unbooted/`

- `msm.ko`: módulo novo com a correção.
- `kernel.dtb`: DT novo do touch, herdando `memory-region`.
- `u-boot.bin` e `uboot.dtb`: U-Boot/DT novos.
- `kernel-module-build.log`, `uboot-build.log`: builds concluídos sem erro.
- `source-overlay.tar.gz`, `source-manifest.json`, `source-changes.patch`, `SHA256SUMS`.
- Ainda NÃO há um par `.img` novo empacotado nessa pasta.

## Próxima sequência recomendada

1. Ler este arquivo/AGENTS e consultar o estado real de USB/ADB/fastboot.
2. Preservar os checkpoints. Não sobrescrever as imagens existentes.
3. Revisar a correção experimental de handoff e validar o novo DT com o script
   de memória. As proteções LCDB, SMMU inicial e ausência do BCR devem continuar.
4. Empacotar um par novo com os artefatos de `handoff-unbooted/`, substituindo
   também o `msm.ko` do ramdisk. Usar `Image.gz` do primeiro teste do touch:
   as alterações novas são em módulo/DT, não no Image builtin.
5. Bootar apenas em RAM. Confirmar shell/mounts/ausência de discos.
6. Carregar display, aguardar o loader terminar e coletar dmesg completo.
   Não basta esperar 5 s: o probe demora ~10 s pelos logs/earlycon.
7. Confirmar que a imagem voltou e que não existem falhas do framebuffer antigo.
8. Carregar touch, conferir IRAM/FW/input/stats. Capturar gestos com usuário
   avisado e confirmar coordenadas, press/release e eventualmente dois dedos.
9. Somente depois considerar recovery/suspend/gestures ou interface gráfica.
   GPU, rede, rootfs e instalação persistente não foram tratados nesta etapa.

### Empacotamento local sugerido — não executado ainda

Executar da raiz do projeto. Esses comandos só gravam arquivos no computador.
O empacotador recusa sobrescrever uma saída com conteúdo diferente.

```sh
python3 scripts/hanoip_boot.py ramdisk \
  work/hanoip-touch-20261024/ramdisk.cpio.gz \
  scripts/hanoip-usb-shell.init \
  work/hanoip-touch-20261024/handoff-unbooted/ramdisk.cpio.gz \
  --add /lib/hanoip-display/msm.ko=work/hanoip-touch-20261024/handoff-unbooted/msm.ko

python3 scripts/hanoip_boot.py repack \
  work/hanoip-touch-20261024/kernel-hanoip-touch.img \
  work/hanoip-touch-20261024/handoff-unbooted/ramdisk.cpio.gz \
  work/hanoip-touch-20261024/handoff-unbooted/kernel-hanoip-touch-handoff.img \
  --kernel work/hanoip-touch-20261024/Image.gz \
  --dtb work/hanoip-touch-20261024/handoff-unbooted/kernel.dtb

python3 scripts/hanoip_boot.py uboot \
  work/baseline-before-qup-2026-10-24/u-boot-hanoip-boot.img \
  work/hanoip-touch-20261024/handoff-unbooted/u-boot.bin \
  work/hanoip-touch-20261024/handoff-unbooted/u-boot-hanoip-touch-handoff.img
```

O helper `work/hanoip-display-20261024/boot-volatile.py` aceita kernel e
`--uboot CAMINHO`. Seu default é o U-Boot do checkpoint de display, portanto
**passar explicitamente o novo U-Boot** para testar a correção do DT.
`--reset` só serve se existir o shell USB Linux; sem ele, detectar Android/fastboot.
Não usar o helper enquanto o usuário só estiver pedindo para ler este handoff.

## Ferramentas, builds e armadilhas

- Host macOS/zsh, SDK Android em PATH. Builds ARM64 por Docker/GCC 13.3.
- Containers próprios: `hanoip-mainline-build-20261024` e
  `hanoip-uboot-build-20261024`. Fontes e builds em `/tmp/kernel-mainline` e
  `/tmp/uboot-sm7150/.output`. Foram preservados; não apagar containers.
  Os dois containers foram parados ao encerrar o handoff; usar `docker start`
  somente quando for retomar builds. Os artefatos novos já foram copiados ao host.
- Outros containers `agrosync-*` são alheios. Não mexer neles.
- Checkout macOS tem colisões de nomes por maiúsculas/minúsculas em Netfilter
  e litmus. Essas modificações já existiam: não resetar nem incorporá-las.
  Builds usaram fontes extraídos via git archive no filesystem Linux e overlays.
- Não houve commit, push, PR nem publicação nesta sessão.
- Para módulos dependentes do MSM, compilar todos os targets `.ko` necessários
  numa única chamada de make. Não misturar o target DTB nessa mesma chamada:
  o kernel fez builds one-by-one e modpost perdeu símbolos entre os targets.
  Compilar DTB separadamente, depois os módulos juntos.
- Último build correto do handoff: `/tmp/hanoip-touch-handoff-build.log`.
- `python3 -m unittest discover -s tests -v`: **16 testes passaram** (10 de
  boot/CPIO, 6 de firmware). Builds kernel/U-Boot/módulos passaram. `git diff
  --check` passou antes do handoff. Isso não substitui o teste do handoff novo.
- `scripts/hanoip_validate_display.py` compara RAM/reservas/proteções com o
  checkpoint e ignora apenas renumeração de phandles nas reservas.
- RAM termina em `0x17dd00000`, nunca declarar 4 GiB cheios. Manter as 22 reservas
  fixas; não reintroduzir a reserva DFPS duplicada.
- Fix LCDB de corrupção de memória preservado: `regmap_read` recebe
  `unsigned int`, não ponteiro convertido de `u8`. Ainda há outros pontos de
  robustez/refcount do LCDB não tratados.
- Os avisos `sys_fillrect/sys_imageblit: framebuffer is not in virtual address
  space` decorrem da flag FBINFO_VIRTFB ausente no fbdev legado MSM; não foram
  corrigidos nesta etapa. Não confundir com a falha SMMU do framebuffer antigo.
- BusyBox do initramfs é Android 1.29.3. Usar `/bin/busybox APPLET` explicitamente.
  O reboot original chama setprop e não reinicia o Linux. `/sbin/reboot` é nosso
  script com guard de mounts e SysRq; pode voltar ao Android OU ao bootloader.
- Console serial: `work/hanoip-display-20261024/serial-command.py` usa host raw,
  lida com escritas parciais, salva `.raw`/`.partial.raw` e espera marcador.
  Não abrir dois leitores seriais simultâneos. Não enviar heredocs longos;
  se transferir arquivo para /tmp em RAM, conferir SHA antes de executar/carregar.
- Captura de input usada: BusyBox hexdump com `24/1 "%02x" "\n"` sobre
  `/dev/input/event3`, por 35 s. Cada evento ARM64 tem 24 bytes.
  O arquivo está em `work/hanoip-touch-20261024/input-events.txt`.

## Pendências que não devem ser esquecidas

- Correção nova do handoff compilada, ainda sem boot/validação visual.
- Usuário relatou tela preta no último teste do touch.
- Touch inicializa e firmware é verificado, mas nenhum gesto validado.
- Sem validação de suspend/resume, boot/ciclo frio de alimentações, GPU,
  120 Hz ou rootfs. Continua sendo um initramfs de diagnóstico em RAM.
- A regra de nenhuma gravação em partições continua valendo em qualquer etapa.
