ÁUDIO: MICROFONE / EARPIECE / FONE (JACK) / FM — investigação 28/10/2026
=========================================================================
Nada foi alterado no aparelho nesta investigação; é levantamento com base no
Android de base, no stock DT e no fonte do kernel.

RESUMO
  - Alto-falante JÁ funciona (amplificador AW882xx no I2C2 + SEC_MI2S).
  - Microfone, earpiece e detecção de fone dependem do codec WCD937x, que NÃO
    está no DT (o DT atual usa um `audio-codec-dummy`).
  - Todos os drivers existem no kernel; falta DT + um ajuste no pinctrl LPI.
  - FM rádio NÃO é viável: o Android usa `fm-slim-ifd` (vendor) e o kernel
    mainline só tem drivers genéricos de rádio (USB/ISA), nenhum Qualcomm.

1. O QUE JÁ FUNCIONA (estado atual, medido)
-------------------------------------------
  Card: "Motorola Moto G60" (snd_soc_sm8250 machine driver, q6afe/q6asm/q6adm
  carregados, ADSP de pé). Rota do alto-falante montada em
  sm7150-motorola-hanoip-pmos-audio2.dts (MultiMedia1 -> SEC_MI2S_RX) e o
  amplificador em ...-audio3.dts:
      speaker_amp: audio-codec@34 { compatible = "awinic,aw882xx";
                                     reset-gpios = <&tlmm 43 GPIO_ACTIVE_LOW>; }
  A cadeia do U-Boot atual inclui isso: clusteridle-test -> perif-batt ->
  perif -> audio3 -> audio2 -> audio -> pmos.

2. O QUE FALTA: CODEC WCD937x (mic, earpiece, jack)
---------------------------------------------------
  Prova de que não existe hoje: no DT efetivo há `audio-codec-dummy` e o
  `amixer -c0 controls` só mostra rotas do machine driver (HDMI,
  DISPLAY_PORT_RX, LPI_MI2S_RX_*), nenhum controle de codec.

  Android de base (stock-live.dts + inventário do DT):
    bolero-cdc com rx-macro@62ee0000 / tx-macro@62ec0000,
    rx_swr_master + tx_swr_master (qcom,swr-mstr),
    wcd937x-rx-slave e wcd937x-tx-slave (qcom,wcd937x-slave),
    wcd937x-codec (status okay), va-macro@62f20000, wsa-macro DESABILITADO.
    No Linux: qmicli não tem nada a ver — o caminho é ASoC.

  Valores exatos do hanoip (do stock DT, phandles resolvidos):
    reset do codec .... LPI GPIO 24 (func2, drive 16; active output-high,
                         sleep output-low) — node "msm_cdc_pinctrl@24"
    vdd-ldo-rxtx ...... L10A 1,8 V (0x1b7740), 25 mA
    vddpx-1 ........... L10A 1,8 V, 10 mA
    vdd-buck .......... L15A 1,8 V, 650 mA
    vdd-mic-bias ...... BOB (bobc1)
    micbias1/2/3 ...... 0xaf0 = 2800 mV
    slaves SWR ........ rx reg 0x1170224, tx reg 0x1170223
    rx channel map .... 9/10/11/12/13/14/15/16 com lanes conforme stock
    tx channel map .... 18/19/20/21/22/23/24/25/26/27/28/29 conforme stock
  No mainline esses reguladores existem com os mesmos nomes:
    vreg_l10a_1p8, vreg_l15a_1p8, vreg_bob  (bate 1:1 com o stock).

3. O QUE O KERNEL JÁ TEM (verificado no .config e no fonte)
-----------------------------------------------------------
  CONFIG_SND_SOC_WCD937X=m, CONFIG_SND_SOC_WCD937X_SDW=m,
  CONFIG_SND_SOC_WCD_MBHC=m (detecção de fone!), CONFIG_SOUNDWIRE=m,
  CONFIG_SOUNDWIRE_QCOM=m, CONFIG_SND_SOC_QCOM=m, q6afe/q6asm/q6adm completos,
  CONFIG_SND_SOC_AW882XX=m.
  No sm7150.dtsi já existem:
    swr_tx: soundwire@62ed0000 e swr_rx: soundwire@62ef0000, ambos completos
    (din/dout, sinterval, offset, lane-control, clocks <&txmacro>/<&rxmacro>);
    pinctrl states tx_swr_active/rx_swr_active em lpass_tlmm;
    portas CODEC_DMA no header (RX_CODEC_DMA_RX_0 = 113, TX_CODEC_DMA_TX_3 = 120)
    e o driver q6afe referencia CODEC_DMA (71 ocorrências).
  Template pronto: arch/arm64/boot/dts/qcom/sm7150-xiaomi-sweet.dts (MESMO SoC)
    mostra o codec MFD qcom,wcd9370-codec, os dois slaves SDW, e os dai-links
    "Primary Spkr Playback" e "WCD937x Capture" (TX_CODEC_DMA_TX_3).

4. O OBSTÁCULO REAL (o que ninguém esperava)
--------------------------------------------
  O pinctrl mainline do LPASS LPI em sm7150 expõe SOMENTE os pinos 0..13:
    drivers/pinctrl/qcom/pinctrl-sm7150-lpass-lpi.c  (LPI_PINGROUP 0..13)
    sm7150.dtsi: gpio-ranges = <&lpass_tlmm 0 0 14>
  Mas o reset do codec é o LPI GPIO 24. O stock declara o hardware com 32
  pinos:
    qcom,num-gpios = <0x20>;
    qcom,lpi-offset-tbl = <0x0 0x1000 ... 0x1f000>;
  Portanto o bring-up exige, além do DTS, ESTENDER A TABELA DO PINCTRL
  (14 -> 32 pinos) e reconstruir U-Boot + módulo do pinctrl (ou kernel).
  Sem isso o codec não pode ser resetado e não sobe.

5. ESCOPO REAL DE CADA ITEM
---------------------------
  MICROFONE ..... DTS (codec + link TX_CODEC_DMA_TX_3) + pinctrl LPI 24
  EARPIECE ...... mesmo DTS (link de playback RX_CODEC_DMA_RX_0, rota handset)
  JACK/FONE ..... mesmo DTS (WCD_MBHC já compilado; limiares micbias/mbhc)
  -> os três são UM único bring-up. Estimativa: 1 arquivo DTS + 1 patch no
     pinctrl + rebuild de U-Boot e do módulo; depois teste com arecord/aplay
     e UCM do ALSA.
  FM RÁDIO ...... NÃO VIÁVEL no estado atual: o FM do Android usa
     fm-slim-ifd/fm_rx/fm_tx (driver vendor sobre Slimbus) e o kernel mainline
     não tem driver de FM Qualcomm. Exigiria escrever driver + firmware.

6. RISCOS
---------
  - Mexer no pinctrl LPI afeta também os pinos do SSC/MI2S já usados; a
    extensão precisa preservar 0..13 e só acrescentar 14..31.
  - O codec compartilha trilhos com o resto (L10A/L15A/BOB); um valor errado
    de micbias pode danificar o codec. Os valores do stock (2,8 V) devem ser
    seguidos à risca.
  - O DT é volátil: qualquer teste exige rebuild de U-Boot e `fastboot boot`.
    O par de retorno é work/PRE-GOLD-20261028-1133/ (tem venus e CPU).
