PLANO FINAL — ITENS PENDENTES (exceto FM, adiado)
=================================================
Base: 28/10/2026, PRE-GOLD work/PRE-GOLD-20261028-1133 (cluster-idle + venus +
kernel #24 v3-teo). FM fica fora deste plano por decisão do usuário (análise em
docs/kernel/LEVANTAMENTO-AUDIO.md, seção 7).

Legenda de esforço: [P] pequeno (1 sessão) · [M] médio (2-4 sessões) ·
[G] grande (semanas). Precisa: [DT+UBOOT] rebuild de U-Boot · [KERNEL] rebuild
de módulo/kernel · [HW] peça externa · [USER] decisão · [—] só ao vivo.

ORDEM POR DEPENDÊNCIA E VALOR
------------------------------
  Fase 1 (destrava o resto):   1. codec de áudio   2. phoc no login
  Fase 2 (barato e visível):   3. venus VP9/HEVC/enc  4. OTG  5. carga on boot
  Fase 3 (com hardware):       6. GPS fix+ponte  7. modem com SIM  8. microSD
  Fase 4 (grande):             9. câmera         10. digital
  Fase 5 (polimento):          11. display  12. NFC app  13. BT A2DP/HFP
  Fase 6 (decisões):           14. MTP  15. Waydroid  16. tools Kali


1. CODEC DE ÁUDIO — microfone, earpiece e detecção de fone   [M] [DT+UBOOT][KERNEL]
   Por que primeiro: três itens de uma vez e destrava áudio de chamada (item 7).
   Estado: drivers todos compilados (wcd937x, wcd937x_sdw, wcd_mbhc,
   soundwire-qcom, CODEC_DMA no q6afe); dtsi já tem swr_tx/swr_rx completos;
   valores do hanoip já extraídos do stock; template = sm7150-xiaomi-sweet.dts.
   Passos:
     a) pinctrl: estender drivers/pinctrl/qcom/pinctrl-sm7150-lpass-lpi.c de
        14 para 32 pinos (só acrescentar 14..31, nunca tocar 0..13) e ajustar
        gpio-ranges no sm7150.dtsi para 32. O reset do codec é LPI GPIO24.
     b) DTS novo (clusteridle-venus-audio): wcd9370 MFD com reset-gpios =
        <&lpass_tlmm 24 GPIO_ACTIVE_LOW>, supplies L10A (rxtx e vddpx), L15A
        (buck), BOB (mic-bias), micbias 1/2/3 = 2,8 V, mbhc configurado;
        &swr_tx/&swr_rx okay com slaves 0,3 e 0,4 (sdw20217010a00);
        dai-links novos: "Earpiece/Handset" e "Headphones" em
        RX_CODEC_DMA_RX_0, "Mic Capture" em TX_CODEC_DMA_TX_3, mantendo o
        link do AW882xx.
     c) rebuild U-Boot + módulo pinctrl; boot volátil.
     d) teste: arecord (mic), aplay (earpiece/handset), plugar fone (MBHC
        deve alternar os controles "Headphone Jack"/"Mic Jack").
     e) UCM do ALSA para expor as rotas aos apps.
   Aceite: arecord grava voz audível; aplay sai no earpiece; plugar/desplugar
   fone gera evento e troca de rota.
   Risco: micbias errado pode danificar o codec (usar 2,8 V do stock);
   pinctrl mexe em pinos compartilhados com SSC/MI2S (só acrescentar).

2. PHOC TRAVA NO LOGIN (Atomic commit EBUSY)                 [M] [—] (+talvez kernel)
   Sintoma: "Atomic commit failed: Device or resource busy" e, em alguns
   logins, "Timeout (3000ms) expired with N configures pending" — a sessão não
   desenha até reiniciar.
   Já provado: vem de drm_atomic_helper_setup_commit (o commit anterior não
   sinalizou flip_done). fbdev/fbcon descartado por teste; apagar/acender tela
   não reproduz; o segundo suspend/resume não reproduziu.
   Passos:
     a) reproduzir com DRM_UT_ATOMIC ligado (0x10) num login: identifica se
        fica pendente em CONNECTOR ou PLANE e qual commit.
     b) instrumentar o msm/dpu: quem deixa de completar flip_done (provável:
        commit que desabilita CRTC no handover greeter->sessão).
     c) correção no msm (completar o commit órfão) ou workaround no phoc
        (commit bloqueante no primeiro frame após assumir o DRM master).
   Aceite: 5 logins seguidos com 0 falhas e 0 timeout.
   Risco: mexer no caminho de commit do DRM pode afetar display; testar com
   PRE-GOLD como retorno.

3. VENUS: VP8 / VP9 / HEVC / MPEG2 + encoder                 [P] [—]
   Estado: H.264 validado (2,8x menos CPU), /dev/video0 anuncia os cinco e
   /dev/video1 é encoder.
   Passos: gerar 4 clipes curtos (VP9 e HEVC de 1080p, MPEG2 e VP8 de 720p,
   via ffmpeg) e repetir o teste de CPU; testar o encoder com
   gst v4l2h264enc (ou ffmpeg h264_v4l2m2m) e conferir o arquivo gerado.
   Aceite: cada formato decodifica sem erro e com CPU menor que software;
   encoder produz H.264 válido (ffprobe).

4. OTG COM PERIFÉRICO                                        [P] [HW: pendrive]
   Estado: DT pronto (dr_mode="otg", role-switch), boot validado, nunca plugado.
   Passos: seguir docs/TESTE-USB.md seção B (UDC vazio, role=host, boost de
   VBUS, xHCI, sdX, montagem read-only). Abortar se T>42 C ou VBUS oscilar.
   Aceite: pendrive monta em read-only e desmonta limpo.

5. CARGA AUTOMÁTICA NO BOOT                                  [P] [KERNEL]
   Estado: CHARGING_ENABLE reseta em power cycle; hoje é opt-in via debugfs.
   Passos: parâmetro de módulo charge_on_boot=1 (patch em qcom_smbx) + default
   no modprobe.d; validar que não liga antes do watchdog ser armado.
   Aceite: boot sem tocar em nada e corrente de carga presente.

6. GPS: FIX + INTEGRAÇÃO                                      [M] [—] + céu
   Estado: serviço LOC achado no QRTR, --loc-start funciona; falta fix e ponte.
   Passos:
     a) fix: aparelho na janela, --loc-start + --loc-follow-position-report;
        se não vier, testar modos msb/msa e injetar tempo/orbits.
     b) ponte: opção A pseudo-terminal NMEA -> gpsd; opção B daemon que lê o
        position-report e fala GeoClue2 por D-Bus (mais nativo).
     c) serviço systemd com liga/desliga por uso.
   Aceite: Gnome Maps (ou equivalente) mostra posição; CPU/consumo não sobe
   com GPS parado.

7. MODEM COM SIM (chamadas/SMS/dados)                        [M] [HW: chip]
   Estado: modem funciona (MM lê firmware/IMEI/bandas; WDS/NAS/WMS/Voice/UIM).
   Passos: inserir chip; verificar registro; SMS; APN/bearer; chamada. Se a
   chamada falhar por IMS, forçar 2G/3G (VoLTE não existe no Linux).
   O áudio da chamada depende do item 1.
   Aceite: SMS enviado, dados com IP e ping, chamada com áudio nos dois sentidos.

8. MICROSD                                                   [M] [HW] [DT+UBOOT]
   Estado: NÃO inserir cartão hoje (DT pede 3,3 V; stock fixa 2,95 V).
   Passos: portar vdd/vdd-io 2,95/1,8 V do stock para o sdhci-msm; corrigir
   cd-gpios para ACTIVE_HIGH (DTS do kernel E do U-Boot); validar SEM cartão
   (controlador sobe, sem "unsupportable voltage range"); só então inserir
   cartão sacrificial.
   Aceite: cartão monta e lê a 100 MHz sem erro de tensão.

9. CÂMERA (todas)                                            [G] [KERNEL/DT]
   Estado: parada no passo 2; 1ª imagem no OV02B1B nunca saiu.
   Passos: sequência já documentada (docs/kernel/checkpoint-...-cameras-parcial):
   decode-regs.py, bring-up do sensor, CSIPHY/CSI, CAMSS, firmware ADSP de
   câmera, libcamera/pipewire. É a maior frente restante.

10. DIGITAL (FPC)                                            [G] [KERNEL]
   Estado: HAL Android usa QSEECOM legado; nenhum comando TEE executado.
   Passos: decidir caminho (driver TEE moderno vs reimplementar protocolo sem
   TEE), depois SPI1/0x884000 + GPIO29/4/90 + protocolo FPC.

11. DISPLAY: FIFO DSI no boot e flicker no brilho mínimo      [P-M] [—]
   Passos: coletar 10 boots e contar IRQs de FIFO; investigar atraso de
   quiesce; ajustar brilho mínimo (curva) no painel.

12. NFC: app gráfico + teste de escrita                       [P] [HW: tag]
13. BT A2DP/HFP                                               [M] [—]
   A2DP provavelmente já funciona (BT de dados ok); HFP depende do item 1.

14. MTP/PTP ................ [USER] decidir modo e diretório
15. WAYDROID ............... [KERNEL] ANDROID_BINDERFS
16. TOOLS KALI ............. [USER] kali-menu + conjunto (3,8 GB livres)


RESUMO DE PRÉ-REQUISITOS
------------------------
  Precisa de chip SIM .......... 7
  Precisa de hardware externo .. 4 (pendrive), 8 (cartão), 12 (tag), 7 (SIM)
  Precisa de rebuild U-Boot .... 1, 8
  Precisa de rebuild kernel .... 1 (pinctrl), 5, 15
  Só software ao vivo .......... 2, 3, 6, 11, 12, 13
  Grandes (semanas) ............ 9, 10
