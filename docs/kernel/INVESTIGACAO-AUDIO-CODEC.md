INVESTIGAÇÃO PROFUNDA — CODEC WCD937x (mic / earpiece / jack) — 28/10/2026
===========================================================================
Fontes consultadas:
  A) dumps do Android: work/android-dump-20261025/stock-live.dts,
     vendor-config.tar (mixer_paths.xml, audio_policy_configuration.xml,
     init.qti.fm.sh), inventário docs/hardware/inventario-dt-android.json.
  B) mainline local: kernel 7.3 (build hanoip), bindings em
     Documentation/devicetree/bindings/sound/, drivers pinctrl/qcom,
     arch/arm64/boot/dts/qcom (sm7150 + boards de referência).
  C) internet: fork sm7150-mainline/linux (branch v7.2), LKML/alsa-devel
     (patchset "ASoC: codecs: wcd937x" v5/v6), LWN (WCD9378), wiki pmOS.

1. TOPOLOGIA CONFIRMADA (Android x mainline batem)
---------------------------------------------------
  Android (stock-live.dts):
    bolero-cdc
      ├── rx-macro@62ee0000 -> rx_swr_master -> wcd937x-rx-slave
      ├── tx-macro@62ec0000 -> tx_swr_master -> wcd937x-tx-slave
      ├── wcd937x-codec (status okay)
      ├── va-macro@62f20000
      └── wsa-macro@62f00000 (DISABLED — não há amplificador WSA neste aparelho)
    msm_cdc_pinctrl@24 -> reset do codec em LPI GPIO24 (qcom,lpi-gpios)
    Amplificador do alto-falante: AW882xx no I2C2 (já funcionando no nosso DT).

  Mainline sm7150.dtsi (já existe, só desabilitado):
    txmacro: codec@62ec0000, rxmacro: codec@62ee0000,
    swr_tx: soundwire@62ed0000, swr_rx: soundwire@62ef0000 (ambos completos:
    din/dout, sinterval, offset, lane-control, clock do macro correspondente).
    Observação: nenhum deles tem pinctrl-0 (igual ao sm8250 upstream, cujo swr1
    também não tem) — as linhas SWR são cuidadas pelo macro/LPASS.

2. O QUE O KERNEL JÁ ENTREGA (verificado no .config e no código)
----------------------------------------------------------------
  CONFIG_SND_SOC_WCD937X=m, CONFIG_SND_SOC_WCD937X_SDW=m,
  CONFIG_SND_SOC_WCD_MBHC=m (jack), CONFIG_SOUNDWIRE=m,
  CONFIG_SOUNDWIRE_QCOM=m, CONFIG_SND_SOC_QCOM=m, CONFIG_SND_SOC_AW882XX=m.
  q6afe: port_maps[] contém RX_CODEC_DMA_RX_0 = AFE_PORT_ID 0xB030 e
  TX_CODEC_DMA_TX_3 = 0xB037; o header expõe as portas 113..125.
  => o driver aceita as portas; quem precisa suportar é o firmware do ADSP,
     que é o vendor do Android (que usava exatamente isso).

3. TEMPLATES ENCONTRADOS NO MAINLINE
------------------------------------
  a) sm7150-xiaomi-sweet.dts — MESMO SoC, MESMO codec, modelo antigo (q6afe):
       &swr_rx { status = "okay"; codec@0,4 { compatible = "sdw20217010a00";
                 reg = <0 4>; qcom,rx-port-mapping = <1 2 3 4 5>;
                 qcom,rx-channel-mapping = <1 2 1 1 2 1 1 2>; }; };
       &swr_tx { status = "okay"; codec@0,3 { ... tx-port-mapping = <2 3 4 5>;
                 qcom,tx-channel-mapping = <1 1 2 1 2 3 3 4 1 2 3 4>; }; };
       link "WCD937x Capture": cpu = q6afedai TX_CODEC_DMA_TX_3,
         codec = <&wcd9370 1>, <&swr_tx 0>, <&txmacro 0>; platform = q6routing.
       Limitação: sweet NÃO tem link de playback do WCD (o alto-falante dele é
       no MI2S), então não serve como exemplo de earpiece/headphone.
  b) sm8250-mtp.dts — mesmo modelo (q6afe), tem o link de PLAYBACK do WCD:
       "WCD Playback": cpu = q6afedai RX_CODEC_DMA_RX_0,
         codec = <&wcd938x 0>, <&swr1 0>, <&rxmacro 0>; platform = q6routing.
       "WCD Capture" : cpu = q6afedai TX_CODEC_DMA_TX_3, codec = <&wcd938x 1>,
                       <&swr1 0>, <&txmacro 0>.
     => para o hanoip: playback deve usar <&wcd9370 0>, <&swr_rx 0>, <&rxmacro 0>
        (rx num SoC separado, diferente do swr1 único do sm8250).
  c) qcm6490-idp — usa WCD937x mas no modelo novo (q6apm/q6apmbedai). Não serve
     para o nosso caso, só confirma o codec.

4. VALORES EXATOS DO HANOIP (extraídos e resolvidos do stock DT)
--------------------------------------------------------------
  Codec:
    vdd-ldo-rxtx ....... L10A (vreg_l10a_1p8), 1,8 V, 25 mA
    vddpx-1 ............ L10A, 1,8 V, 10 mA
    vdd-buck ........... L15A (vreg_l15a_1p8), 1,8 V, 650 mA
    vdd-mic-bias ....... BOB (vreg_bob)
    micbias1/2/3 ....... 0xaf0 = 2800 mV
    static supplies .... cdc-vdd-ldo-rxtx, cdc-vddpx-1, cdc-vdd-mic-bias
    on-demand .......... cdc-vdd-buck
    reset .............. LPI GPIO24 (stock: function "func2", drive 16;
                         active output-high, sleep output-low)
  Escravos SoundWire: rx reg 0x1170224 (0,4), tx reg 0x1170223 (0,3).
  Roteamento do Android (mixer_paths.xml): rotas "handset" (earpiece),
    "speaker", "headset", amic1/2/3 -> confirma que o earpiece é do WCD.

5. A INCÓGNITA DO PINCTRL (investigada a fundo)
-----------------------------------------------
  - mainline: pinctrl-sm7150-lpass-lpi.c tem LPI_PINGROUP(0..13) e o dtsi
    gpio-ranges = <&lpass_tlmm 0 0 14>. O driver escreve o ÍNDICE da função no
    campo FUNC (GPIO_FUNC = 0).
  - stock: o controlador LPI declara qcom,num-gpios = <0x20> (32 pinos) e
    qcom,lpi-offset-tbl com 0x0..0x1f000 (um a cada 0x1000) — então o hardware
    tem 32, e o mainline só descreve 14.
  - outros SoCs no mainline expõem mais: sdm660/sdm670 = 31, sm4250 = 26,
    sm8450/8550/8650 = 22, sm6115 = 18. Ou seja, estender é rotina no upstream,
    só não foi feito para o sm7150.
  - o fork sm7150-mainline (branch v7.2) também para no pino 13 e NÃO tem
    hanoip no DTS — não há trabalho pronto para copiar; a extensão é nossa.
  - detalhe do mux: o stock usa function "func2" para o reset, enquanto o
    mainline escreve o índice (gpio = 0). Se o GPIO não togglar com o índice 0,
    o teste seguinte é adicionar uma função "func2" explícita para o pino 24.
    Isso é verificável com leitura do registrador de configuração do pino
    (base do lpass_tlmm 0x62b52000 + pino*0x1000), sem risco.

6. INTERNET — O QUE JÁ SE SABE DO DRIVER WCD937x
------------------------------------------------
  - O driver wcd937x foi mergeado no mainline (patchset "ASoC: codecs:
    wcd937x" v5/v6, autoria Qualcomm/Linaro); cobre WCD9370/9375, SoundWire,
    MBHC. O binding exige apenas compatible e reg; micbias/mbhc são opcionais.
  - Aviso de um caso vizinho (WCD9378, Fairphone 6, LWN): chips mais novos com
    registradores paginados precisam de "SCP address paging" no controlador
    SoundWire; sem isso o codec enumera mas todo acesso paginado lê zero.
    NÃO é o nosso caso (WCD9370 não é paginado), mas é a armadilha clássica de
    "enumera e não funciona".
  - Não há relato de audio no hanoip no wiki pmOS nem no fork sm7150-mainline.

7. DECISÃO DE ENGENHARIA: ETAPA 0 ANTES DO PINCTRL
--------------------------------------------------
  A pergunta caro/não-caro é: o codec já está fora de reset quando o Linux
  boota? Se o bootloader deixou o pino flutuante/alto, ele enumera no barramento
  SEM mexer em pinctrl. Isso é testável com uma variante que só liga txmacro,
  rxmacro, swr_tx, swr_rx e os dois escravos — nenhum reset, nenhuma tensão,
  nenhum risco elétrico.

  Variante criada: sm7150-motorola-hanoip-audio-etapa0.dts
  (base clusteridle-venus + swr/macros okay + escravos 0,3 e 0,4).

  Critério de decisão após o boot:
    ls /sys/bus/soundwire/devices/
      aparecer 0-01170223 / 0-01170224 (ou nomes equivalentes)
        => codec vivo; seguir para o MFD (tensões + micbias) e os dai links
           sem precisar do pinctrl.
      não aparecer nada
        => estender pinctrl (14->32) e dirigir o reset; depois repetir.

8. RISCOS (todos mapeados)
--------------------------
  - micbias errado pode danificar o codec: usar 2,8 V do stock, sem inventar.
  - L10A é compartilhado; o driver só habilita na abertura do stream.
  - mexer no pinctrl LPI afeta SSC/MI2S em uso: acrescentar 14..31, nunca
    alterar 0..13.
  - DT é volátil: cada tentativa é `fastboot boot`; retorno =
    work/PRE-GOLD-20261028-1133/.
  - earpiece: mesmo com o codec de pé, a rota "handset" precisa de UCM do ALSA
    para o app escolher a saída certa.
