Kernel 7.3 hanoip — variante v2: v1 + PRs #70, #64, #65 e #60 do fork, 26/10/2026
================================================================================

Base: upstream v7.3 (c03c1a14). patches/ = 160 commits, `git am` direto sobre
v7.3 (conferido: aplicado do zero gera exatamente a árvore testada; branch
hanoip-7.3-prs @ ce54777a1093 no container hanoip-kernel73).
  0001-0128  v1 (fork sm7150-mainline "v7.2" + hanoip + fix IIO_CONSUMER).
  0129-0158  PRs abertos no fork, todos baseados em fd78d17954 (ponta do v7.2):
             #70  qcom_smbx: status de sobretensão lia STATUS_7/reg errados.
             #64  só os 8 commits de driver (os 3 de DT do Xiaomi sweet ficaram
                  de fora). SMB5: codificação da tensão de flutuação, USBIN
                  sem escala dupla, decodificação do estado. QG: LSB da
                  corrente pelo subtipo do ADC, capacidade por tabela OCV,
                  suavização (1% a cada 20 s), status pelo carregador.
             #65  áudio do sweet: nós LPASS (tx/rx/va macro, SoundWire) no
                  sm7150.dtsi, aw88261/AW88263S, q6afe/q6routing, SoundWire,
                  wcd937x após reinício do ADSP, LPI pinctrl.
             #60  WCD9375/microfones do davinci e ajustes do LPI pinctrl.
  0159       qcom_qg: resultado líquido do QG do #64 + o que é só nosso
             (-EAGAIN sem batt_info, leituras SDAM alinhadas, IIO_CONSUMER).
  0160       sm7150.dtsi: um único conjunto de nós de áudio (o do #65); os
             valores que o #60 afinou para o davinci foram para o DT dele.

Decisões de integração:
  - #64 0006/0009 (status do QG) pulados: a nossa árvore já tirava o status
    do carregador; o arquivo final vem do 0159.
  - Patches 0024-0026 do PR (macros LPASS "Don't latch runtime PM error")
    pulados: no 7.3 os macros usam pm_clk, e pm_clk_resume não propaga erro
    de clock; o problema que eles resolviam não existe mais.
  - LPI pinctrl GPIO1/GPIO5: #65 e #60 chegavam ao mesmo valor; ficou o
    valor com o comentário explicativo do #60.
  - Entrada hanoip do qcom_smbx ganhou fv 3,6-4,79 V/10 mV (SMB5); no modo
    monitor o probe sai antes de gravar, então nada é escrito no PMIC.
  - Os patches 0151/0153 sozinhos duplicam nós de DT; a série só compila os
    DTs depois do 0160 (o kernel compila em qualquer ponto).

Áudio: o hanoip usa WCD937x via macros LPASS (bolero), amplificador Awinic
aw882xx em I2C 0x34 e fsa4480 no USB-C (dump Android). Os nós de áudio estão
no sm7150.dtsi com status "disabled" e o DT em uso é o do U-Boot (sem esses
nós), então nada de áudio é ativado no aparelho nesta variante. É a base
para a frente de áudio.

Boot (SÓ volátil): u-boot-hanoip-pmos-v1.img (o da GOLD v4) e
kernel-hanoip-pmos-7.3-v2.img. Instalar os módulos no rootfs com
install-rootfs-7.3.sh (em primeiro plano: em `sh`, um comando com & no fim
recebe stdin de /dev/null e o tar falha).

Validado (26/10/2026): pmOS + Plasma, display DSI irqs=0, touch, Wi-Fi, BT,
sem Oops/WARNING, tainted 4096. Drivers novos confirmados carregados
(qcom_qg_get_status, smbx_ov_status em /proc/kallsyms). Bateria: 52%,
3,85 V, corrente ~-160 mA estável com brilho máximo (v1: 53%, 3,87 V),
status Not charging pelo carregador, USB 4,97 V/497 mA, health Good. A
porcentagem continua estimada por tensão (o DT não tem tabela OCV). A carga
continua desligada (modo monitor).
