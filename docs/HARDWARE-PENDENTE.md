HARDWARE QUE FALTA — estado real em 28/10/2026
==============================================
Lista fechada por subsistema. Cada item diz o estado medido, o que bloqueia e o
que precisa (REBUILD de U-Boot/kernel, HW externo, decisão sua, ou só trabalho
ao vivo). Fonte: docs/PENDENCIAS.md, docs/PLANO-DAILY-DRIVER.md, checkpoints e
os levantamentos de CPU/GPU/sensores desta data.

Legenda: [REBUILD] U-Boot (DT) ou kernel/módulo · [HW] peça externa · [USER]
decisão sua · [—] só código/config ao vivo.


1. NÃO FUNCIONA (nada de hardware utilizável hoje)
--------------------------------------------------
1.1 CÂMERA (todas as câmeras: traseira principal, ultrawide, macro, frontal)
    Estado: parada no passo 2 do plano; primeira imagem no OV02B1B nunca saiu,
    decode-regs.py nunca foi rodado.
    Falta: bring-up completo do sensor + CSIPHY/CSI + ISP (CAMSS), firmware
    do ADSP para câmera, e o caminho de userspace (libcamera/pipewire).
    Precisa: [REBUILD] + muito trabalho ao vivo. É a maior frente restante.

1.2 IMPRESSÃO DIGITAL (FPC)
    Estado: pausada a seu pedido. HAL do Android é AArch64 e usa QSEECOM legado
    (não qcomtee); SPI1/0x884000 é o candidato estático, não validado; nenhum
    comando TEE foi executado.
    Falta: driver + protocolo FPC + ponte TEE (ou reimplementação sem TEE, que
    é o ponto difícil). Precisa: [REBUILD] + pesquisa.

1.3 ÁUDIO — só o ALTO-FALANTE funciona
    Funciona: reprodução no alto-falante.
    Falta: MICROFONE, FONE DE OUVIDO (earpiece), DETECÇÃO DE FONE (headset
    jack), perfis de voz (chamada), proteção do alto-falante (plano de 4
    passos) e RÁDIO FM. Nodes LPASS existem no kernel v2 mas estão desabilitados
    e fora do DT do U-Boot.
    Precisa: [REBUILD U-Boot (DT)] + [—].

1.4 GPS / GNSS
    Estado: nunca iniciado. Depende do modem (QMI) + geoclue.
    Precisa: [—] + modem funcional (ver 1.5). Nenhum hardware extra.

1.5 MODEM: CHAMADAS, SMS E DADOS MÓVEIS
    Estado: o modem sobe (state=running) e o firmware carrega, mas chamada,
    SMS, dados e validação de SIM (nos dois slots) nunca foram testados.
    Precisa: [HW: chip SIM com dados] + [—] (QMI/ModemManager, APN).

1.6 DECODE DE VÍDEO (Venus)
    Estado: não habilitado. Reprodução de vídeo cai em software.
    Precisa: [REBUILD] (DT + firmware) e depois validação.

1.7 MICROSD (slot sdhc_2)
    Estado: NÃO usar cartão na variante atual. O DT stock pede 2,95 V no vdd e
    1,8/2,95 V no vdd-io; o mainline pede 3,3 V e o comentário do checkpoint é
    explícito: combinação "conhecida como arriscada" e "não inserir cartão".
    Falta: portar os níveis do stock para o sdhci-msm, corrigir cd-gpios para
    ACTIVE_HIGH (DTS do kernel E do U-Boot) e validar sem cartão antes.
    Precisa: [REBUILD] + [HW: cartão sacrificial].


2. FUNCIONA, MAS FALTA VALIDAR COM HARDWARE
-------------------------------------------
2.1 OTG / USB HOST (pendrive, teclado, hub)
    Estado: DT com dr_mode="otg" + usb-role-switch, boot validado, role switch
    em device e boost de VBUS presente (desligado). NUNCA foi plugado nada.
    Falta: o teste com periférico (protocolo em docs/TESTE-USB.md secção B).
    Precisa: [HW: pendrive/teclado/hub] + [PC] se travar.

2.2 HOST + CARREGANDO AO MESMO TEMPO
    Estado: teoricamente possível (PR_SWAP com TCPM), nunca testado.
    Precisa: [HW: hub com fonte].

2.3 CARGA COM FONTE FRACA (AICL e recarga após terminação)
    Estado: recarga automática após "Full" nunca foi observada e o AICL nunca
    atuou — só acontece com fonte fraca (porta de PC + tela ligada). Com
    carregador forte o VBUS fica em 5,0 V e não há o que limitar.
    Precisa: [HW: porta fraca] + [PC]. Protocolo pronto.

2.4 WI-FI MODO MONITOR / INJEÇÃO
    Estado: o ath10k declara suporte; injeção nunca testada.
    Precisa: [HW: outro AP] para validar.

2.5 NFC
    Estado: LEITURA ISO14443-A funciona. Falta o app gráfico e não há teste de
    escrita nem de emulação de cartão.
    Precisa: [—] para o app; [HW: tag/leitor] para escrita.

2.6 PROXIMIDADE APAGANDO A TELA EM CHAMADA
    Estado: o sensor funciona (near=1 tampado, 0 livre); falta o caminho de UI
    (Phosh não apaga em chamada).
    Precisa: [—] + chamadas funcionando (1.5).


3. FUNCIONA, MAS COM RESSALVA
-----------------------------
3.1 ROTAÇÃO / SENSORES DE ORIENTAÇÃO
    Estado: o acelerômetro estava 180 graus errado por matriz de montagem
    zerada no ADSP; CORRIGIDO e validado. Depois disso o phosh passou a
    reaplicar transform 180 em ciclos de lock/resume, então a rotação foi
    DESLIGADA a seu pedido (orientation-lock=true, transform normal, tela de
    bloqueio ativa). Se quiser religar: gsettings orientation-lock false.
    Bússola: o proxy reporta "No compass" — não há magnetômetro exposto.

3.2 SUSPEND "DEEP"
    Estado: só s2idle existe neste kernel; não há suspend-to-RAM. O s2idle
    funciona com o hook do ADSP.
    Precisa: [REBUILD] se quiser deep (não é requisito de uso diário).

3.3 CARREGAMENTO EM GERAL
    Funciona e termina (FSM 0x45), mas é OPT-IN: o bit CHARGING_ENABLE reseta
    em power cycle e precisa ser religado no debugfs.
    Falta: parâmetro de módulo charge_on_boot=1. Precisa: [REBUILD do módulo].

3.4 VIBRAÇÃO, LED, FLASH
    Funcionam. Nada pendente.

3.5 DISPLAY 1080x2460 + TOUCH
    Funcionam (touch com multitouch validado, dois dedos). Pendências são de
    robustez: FIFO DSI intermitente no boot e brilho mínimo/flicker (Phosh).

3.6 GPU (Adreno 618)
    Fechada: GL 4.6, GLES 3.2, Vulkan 1.3, 800 MHz sustentado, trilhas
    desligando em idle. Nada pendente de hardware.

3.7 BLUETOOTH
    Ativo (funcionou nas imagens GOLD). Não há pendência de hardware conhecida,
    mas também não foi feito teste longo de áudio A2DP/HFP (o HFP depende do
    1.3).

3.8 CPU / TÉRMICA / ENERGIA
    Fechadas: 8 núcleos, schedutil+EAS, OPP completos, cluster idle, TEO,
    thermal IPA, 10 min a 8 núcleos sem throttling.


4. DEPENDE DE DECISÃO SUA (não é falha de hardware)
--------------------------------------------------
  · MTP/PTP (expor arquivos por USB): decidir se só-leitura e qual diretório
    (nunca /root nem /).
  · Alimentar o ADSP/câmera/digital exige mais firmware extraído do Android:
    já existe cópia em /opt/ssc e no rootfs; decidir se ampliamos.
  · Waydroid (apps Android) precisa de ANDROID_BINDERFS no kernel: [REBUILD].


5. RESUMO EM UMA LINHA POR ITEM
-------------------------------
  FALTA (nada funciona):   câmera, digital, microfone, earpiece, detecção de
                           fone, FM, GPS, chamadas/SMS/dados, decode de vídeo,
                           microSD.
  FALTA VALIDAR (tem HW):  OTG com periférico, hub com fonte, AICL com fonte
                           fraca, monitor mode do Wi-Fi, escrita NFC.
  FUNCIONA COM RESSALVA:   rotação (desligada a pedido), carga opt-in,
                           suspend só s2idle, FIFO DSI intermitente.
  FECHADO:                 display, touch, GPU, CPU/térmica, Wi-Fi, BT,
                           vibração, LED, flash, áudio no alto-falante,
                           leitura NFC, sensores accel/luz/prox.
