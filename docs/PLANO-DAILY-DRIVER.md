PLANO ABSOLUTO — Kali NetHunter Pro (hanoip) como daily driver
================================================================
Criado em 27/10/2026. Projeto de longo prazo, sem pressa, com critérios
mensuráveis de aceitação e volta atrás em cada fase.

REGRA DE OURO: nada aqui autoriza gravar partição do telefone. O padrão do
projeto continua `fastboot boot` (volátil) + rootfs no userdata (autorizado).
Qualquer passo que exija escrita em partição (Fase 1) precisa de autorização
explícita do usuário e atualização do AGENTS.md ANTES de executar.


ESTADO DE PARTIDA (verificado em 27/10/2026)
--------------------------------------------
Funciona: Phosh + teclado virtual, login kali/1234, SSH root por chave, USB
NCM+DHCP, Wi-Fi 5 GHz com internet, sensores SSC (accel/luz/prox), vibração,
LED, flash, áudio no alto-falante, NFC leitura ISO14443-A, GPU (355 MHz,
renderD128), display 1080x2460, touch, zram 1,7 GiB (11:1), Bluetooth ativo.
Não funciona / pendente: carregamento (Not charging, 0 mA), suspend, chamadas/
SMS/dados móveis, microfone/fone, GPS, câmera, digital, app gráfico de NFC,
SOC da bateria impreciso e oscilante, boot dependente de PC.


FASE 0 — CONGELAR BASE E CRIAR REDE DE SEGURANÇA   (curta, ~1 dia)
------------------------------------------------------------------
Objetivo: poder quebrar qualquer coisa e voltar em minutos.

0.1 Imagem crua do rootfs ("pneu de estepe")
    - `dd` do /dev/sdb24 a partir do pmOS (mount RO) + zstd. Restauração =
      um único stream `zstd -dc | dd of=/dev/sdb24` (~6 min, idêntico).
    - Guardar também o snapshot tar (2,1 GB) já existente.
0.2 Registro de imagens boas (equivalente ao GOLD, mas do Kali)
    - pasta `work/kali-gold-<data>/` somente leitura: u-boot, boot.img,
      kernel Image.gz, dtb, initrd, SHA256SUMS, GIT/kernel tree hash.
0.3 Checklist de boot (script) que roda no host após cada boot:
    estado systemd, units falhando, GPU/zap, DSI/atomic, sensores, Wi-Fi,
    áudio, flags RO das partições, escrita no root, taint, temp térmicas.
0.4 Coleta automática de logs + pstore (ramoops) ao primeiro SSH.
Critério de aceite: restaurar do zero em <15 min e o checklist passar 100%.
Volta atrás: é a própria rede de segurança.


FASE 1 — BOOT INDEPENDENTE DE PC   (decisão do usuário, depois execução)
------------------------------------------------------------------------
Por que é a fase mais importante para daily driver: hoje, todo reboot exige
Mac + `fastboot boot`. Sem isso não existe uso diário.

Opções (escolher UMA, com autorização explícita):

  A) Manter volátil (não serve para daily driver). Só para bancada.

  B) Instalar U-Boot + kernel na SLOT B (boot_b/vendor_boot_b) e alternar
     slot: A = Android, B = Kali. Escrita em boot_b (inativa), slot ativo
     continua A até um `fastboot --set-active=b` deliberado. Reversível:
     backup da boot_b original + `--set-active=a` restaura o Android.
     RISCOS: gravação em partição (proibida hoje), troca de slot, ABL/AVB
     podem reclamar; precisa de backup e verificação byte a byte.

  C) kexec a partir do Android com root (sem gravar partição): precisa de
     kernel Android com kexec + ferramenta; em prática costuma ser mais
     frágil e depende do root do Android sobreviver a updates.

  D) U-Boot com "bootmenu" gravado em boot_a (substitui o boot Android):
     NÃO recomendado (perde o Android e mistura com OTA).

Recomendação: B, feita como um projeto próprio, com backup duplo (raw image
das duas slots + hash), teste em bancada e critério de volta atrás pronto
antes do primeiro comando de escrita.
Critério de aceite: 10/10 boots sem PC; Android inicia na slot A quando
selecionada; reverter para A também 10/10.


FASE 2 — ENERGIA: CARREGAR COM SEGURANÇA   (o projeto mais valioso)
-------------------------------------------------------------------
Objetivo: carregar de verdade, com envelope conservador, sem risco.

2.1 Instrumentação antes de ligar carga
    - power meter USB externo (mV/mA na entrada) + telemetria do QG (V/I/T).
    - log contínuo (1 s) num arquivo, com alarme de T > 45 C.
2.2 Envelope inicial (copiando o conservadorismo do upstream qcom_smbx)
    - FLOAT/constant-charge ≤ 4,40 V (design da Motorola 4,44 V).
    - Fast-charge ≤ 1 A no começo (upstream capa em 1 A "fire hazard").
    - Pre-charge 500 mA; terminação por corrente (I_TERM ~ 10% de 1 A).
    - JEITA habilitado (limites de frio/quente) + BAT_OV + pet do watchdog.
    - NUNCA habilitar boost/OTG; nunca alterar VBUS/PD nesta fase.
2.3 Implementação
    - Driver novo `hanoip-smb5` (não reutilizar qcom_smbx: mapa de registros
      do smb5 é outro) expondo: status, corrente/tensão de entrada, limite
      de corrente, e o mínimo de writes necessários.
    - Modo de teste por módulo de parâmetro: `charge_enable=0` por padrão.
2.4 Protocolo de teste (não negociável)
    - bancada, supervisão, PSU limitada a 1 A/5 V, sessões de 15 min,
      incrementando 250 mA por vez; medir T bateria e conector.
    - se qualquer zona > 45 C ou corrente > limite: desligar e investigar.
2.5 Depois que carrega
    - Calibrar a curva OCV: registrar pares (OCV, %real) em carga/descarga
      completas → tabela de verdade no DT (substitui a genérica).
    - Só então o SOC vira preciso além de "estável".
Critério de aceite: carrega de 20% a 100% sem intervenção, T < 43 C, sem
watchdog trip, 5 ciclos seguidos; e desligar/religar o cabo 20x sem travar.
Risco: alto se feito sem supervisão; baixo se seguir 2.2 e 2.4.


FASE 3 — SUSPEND, IDLE E TÉRMICA   (autonomia de verdade)
---------------------------------------------------------
3.1 Medir o baseline: corrente média com tela apagada, Wi-Fi ligado/desligado,
    modem parado/rodando; alvo inicial < 30 mA (a definir após medir).
3.2 Suspend/resume: s2idle e/ou deep; validar wake por power key, touch,
    modem e USB. Suspeitos já mapeados: cluster idle (o black screen do
    pmOS), LCDB, DSI, SMMU, UFS.
3.3 Política de energia: gerenciadores (TLB? power-profiles-daemon),
    autosuspend de USB/PCIe, GPU idle, ADSP/CDSP sleep, runtime PM dos
    periféricos, escalonadores.
3.4 Térmica: trip points ativos ligados à CPU/GPU (governor power_allocator)
    e verificação de que o kernel não passa de 60 C em uso normal.
Critério de aceite: tela apagada 8 h com perda < 8%/8h; 200 ciclos de
suspend/resume sem falha; nenhum wake perdido.


FASE 4 — CONFIABILIDADE E RECUPERAÇÃO
-------------------------------------
4.1 fs: política de fsck (superbloco, `tune2fs -c`, initramfs com reparo
    automático quando preen falha) para nunca mais cair no BusyBox.
4.2 Watchdog de hardware (se disponível) + auto-reboot em hung task, com
    pstore para capturar a causa.
4.3 Teste de longa duração: 7 dias ligado, uso normal, sem reboot; contadores
    de erro (SMMU faults, RCU stalls, OOM, taint) em zero.
4.4 Matriz de boot: 20 boots a frio seguidos, contando falhas de mount/DSI.
4.5 Rotina de reboot seguro (já existe `hanoip-reboot`) + nunca `echo b` puro.
Critério de aceite: 20/20 boots, 7 dias sem reboot espontâneo, 0 fault.


FASE 5 — TELEFONIA (o que separa "PC de bolso" de "celular")
------------------------------------------------------------
5.1 Dados móveis: QMI + ModemManager (APN), validar com chip.
5.2 SMS/voz: stack de chamadas (o Kali já traz callaudiod), roteamento de
    áudio de chamada (UCM), e o caminho de voz do ADSP.
5.3 Áudio restante: microfone, fone/auricular, headset jack, viva-voz.
5.4 GPS/GNSS: node + firmware do modem, geoclue.
Critério de aceite: chamada de voz de 5 min estável nos dois sentidos, SMS
ida/volta, dados 4G estáveis 1 h, GPS fix em < 60 s ao ar livre.


FASE 6 — HARDWARE DIFÍCIL (avaliar risco/benefício, sem pressa)
---------------------------------------------------------------
6.1 Câmera: exigirá fastrpc com DMA reservado (hoje inexistente), pipeline
    CAMSS/CCI, e firmware do sensor. Projeto grande.
6.2 Digital: FPC + QSEECom legado (ABI Android) — risco de TEE. Só com plano
    de segurança e sem tocar em banco de dados de cadastro.
6.3 NFC card-emulation (HCE) — hoje só leitura.
6.4 App gráfico de NFC (já escrito, não instalado) — barato, pode entrar antes.
Critério de aceite: definido por item, com teste de regressão do resto.


FASE 7 — SEGURANÇA E MANUTENÇÃO
-------------------------------
7.1 Login: sair de autologin, exigir senha no greetd; revisar sshd.
7.2 Backups automáticos do rootfs (snapshot + imagem crua) num cron do pmOS.
7.3 Atualizações: política de apt, kernel versionado à parte, sempre com
    imagem anterior guardada.
7.4 Documentação: cada mudança com checkpoint + SHA256SUMS + "como voltar".
7.5 (Opcional, grande) Criptografia do userdata — avaliar no fim, porque
    qualquer OTA/Android que formate o userdata destrói o Kali.
Critério de aceite: senha exigida, backup semanal automático, runbook de
recuperação testado uma vez.


ORDEM RECOMENDADA
-----------------
Fase 0 (imediata) → Fase 4.1/4.5 (barato, evita perder dados) →
Fase 1 (decisão do usuário) → Fase 2 (energia) → Fase 3 (autonomia) →
Fase 5 (telefonia) → Fase 6/7 conforme interesse.

Justificativa: sem boot independente e sem carga não existe daily driver;
sem rede de segurança (Fase 0) qualquer experimento custa horas.


CRITÉRIOS GLOBAIS DE "PRONTO PARA DAILY DRIVER"
-----------------------------------------------
[ ] reinicia sem PC, 10/10
[ ] carrega sozinho, 5 ciclos, T < 43 C
[ ] tela apagada 8 h < 8% de perda
[ ] 7 dias sem reboot espontâneo
[ ] chamada + SMS + dados funcionando
[ ] áudio completo (alto-falante, fone, mic, chamada)
[ ] Wi-Fi/BT/sensores/NFC sem regressão
[ ] backup + restauração testados
[ ] nenhum erro de SMMU/RCU/OOM, taint só do módulo nosso


HIGIENE DE TRABALHO (vale para todas as fases)
----------------------------------------------
- Uma mudança por vez; medir antes/depois; guardar imagem anterior.
- Kernel: build reprodutível (work/kernel-7.3/vN), patches numerados,
  configurado por arquivo, version.txt + SHA256SUMS.
- Telefone: `fastboot boot` apenas; nada de flash sem autorização explícita.
- Rootfs do Kali: sempre montar RO no pmOS para snapshot; escrita só no
  userdata; demais partições com ro=1 verificado.
- Logs: coletar dmesg + journal + pstore depois de cada experimento.
