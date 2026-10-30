Kernel 7.3 v4 — SOC da bateria estável (27/10/2026)
===================================================

Base: v3 (166 patches) + 1 patch novo:

  0167  power: supply: qcom_qg: report a steady state of charge
        - usa as amostras MÉDIAS (QG_S2_NORMAL_AVG_V/I) em vez do "último ADC";
        - banda morta de 2% (QG_SOC_HYSTERESIS): a porcentagem não se mexe
          enquanto a estimativa estiver dentro do ruído;
        - deriva máxima de 1% a cada 2 min (QG_SOC_STEP_MS = 120000), nas
          DUAS direções (o código antigo só andava conforme o status, o que
          travava numa direção e fazia o número varrer sozinho);
        - nunca reporta queda enquanto está carregando;
        - clamp 0..100.

IMPORTANTE — a DT NÃO vem daqui
-------------------------------
O DT que vale no aparelho é o EMBUTIDO no U-Boot (CONFIG_OF_EMBED); ver
work/uboot-builds-20261026/README.txt. Portanto a tabela OCV
(ocv-capacity-table-0) foi adicionada na árvore do U-Boot, na variante:

  uboot-sm7150/dts/upstream/src/arm64/qcom/
      sm7150-motorola-hanoip-pmos-perif-batt.dts   (perif + curva da bateria)

Construir:  work/uboot-builds-20261026/build.sh \
                sm7150-motorola-hanoip-pmos-perif-batt

O qcom_qg é MÓDULO: a correção do driver entra trocando
/lib/modules/7.3.0-sm7150/kernel/drivers/power/supply/qcom_qg.ko.zst no
rootfs — não é necessário trocar a Image. vermagic = "7.3.0-sm7150 SMP
preempt mod_unload aarch64", igual ao kernel #2 em uso, e CONFIG_MODVERSIONS
não está ativo (sem CRCs a conferir).

O que muda em relação ao v3 para efeito de imagem: só o timestamp de build
(Image.gz tem hash diferente, código igual).

Reconstruir
-----------
  ./build.sh            # sem ramdisk: gera só out/Image.gz, kernel.dtb,
                        # modules-7.3.0-sm7150.tar.gz e version.txt
Reaproveita a imagem e o volume docker do v3 (hanoip-kernel73-v3-src) para
build incremental. O hash da árvore é registrado em /src/obj/.tree-v4 em vez
de ser comparado com o do v3 (é diferente de propósito).

Instalação do módulo no aparelho (rootfs do Kali, rw)
-----------------------------------------------------
  tar -xzf modules-7.3.0-sm7150.tar.gz \
      7.3.0-sm7150/kernel/drivers/power/supply/qcom_qg.ko.zst
  install -m 644 7.3.0-sm7150/kernel/drivers/power/supply/qcom_qg.ko.zst \
      /lib/modules/7.3.0-sm7150/kernel/drivers/power/supply/
  depmod -a 7.3.0-sm7150
  modprobe -r qcom_qg; modprobe qcom_qg

Verificação (sem tocar no PMIC)
-------------------------------
  /usr/local/sbin/hanoip-batt-log 900 1000 /root/batt-idle.csv
  # 15 min ocioso: amplitude da capacidade deve ficar <= 1 ponto percentual
  # e nenhum salto > 2 (o script resume isso no final)

Estado: build do kernel OK; U-Boot da variante -batt em construção. O teste
no aparelho exige o celular em fastboot.

RESULTADO DO TESTE NO APARELHO (27/10/2026)
------------------------------------------
Bootado: u-boot ...-pmos-perif-batt + kernel-hanoip-kali-phosh-v2.img (Image
do v3, sem mudanca) + qcom_qg.ko.zst do v4 instalado e recarregado.

1) DT: /proc/device-tree/battery tem ocv-capacity-table-0 (21 pontos),
   ocv-capacity-celsius=25 e factory-internal-resistance-micro-ohms=30000.
   Sistema saudavel: running, 0 units falhando, ssc/iio ativos, wlan0 com IP,
   display connected+enabled, 0 erro de GPU/DSI.

2) SOC com a curva: capacity=84% para OCV 4,2369 V (a tabela diz 85% em
   4,240 V; o mapa linear antigo diria 82%).

3) TESTE DE CARGA (o que antes fazia o numero pular):
   6 busy loops de CPU por 40 s -> corrente -708 mA, tensao media caiu de
   4,234 V para 4,155 V (79 mV; ~6% no mapa antigo).
   Capacidade reportada: 84% durante TODO o teste, sem oscilar.

Antes da correcao, uma queda de 79 mV movia a porcentagem em ~6 pontos.

ARMADILHAS DE PATCH (custaram um build)
---------------------------------------
- Ao gerar C por script Python com string tripla ('''...'''), '\n' dentro do
  literal vira QUEBRA DE LINHA REAL no arquivo .c e a string C quebra
  ("missing terminating \" character"). Use '\\n' ou raw string.
- `no_llseek` não existe mais neste kernel: não declare `.llseek` em fops de
  debugfs (o default serve); `noop_llseek` é outra coisa.
- Sempre compile só o objeto antes do build completo, para ver o erro:
    docker run --rm -v hanoip-kernel73-v3-src:/src hanoip-kernel73-v3 \
      bash -c 'make -C /src/linux O=/src/obj ARCH=arm64 \
               CROSS_COMPILE=aarch64-linux-gnu- LOCALVERSION= \
               drivers/power/supply/qcom_smbx.o'
  (o build.sh manda a saída por tail e esconde o erro real; redirecione para
   um log quando estiver depurando)

---------------------------------------------------------------------
PATCHES 0168..0187 — todos da sessao de 27/10/2026 (bateria, carga e USB)
---------------------------------------------------------------------
O resumo acima parou no 0167. A serie cresceu para 187 patches no mesmo dia,
todos com justificativa MEDIDA no corpo do patch (o que aconteceu no aparelho,
qual numero saiu errado e por que). Ordem:

  168  power: supply: qcom_smbx: add a read-only register dump for
  169  power: supply: qcom_smbx: opt-in charging for the hanoip
  170  power: supply: qcom_qg: never freeze on a bad first sample
  171  power: supply: qcom_smbx: negotiate the input current limit
  172  power: supply: qcom_smbx: allow forcing the input current
  173  power: supply: qcom_qg: cap the charging rise with coulomb
  174  power: supply: qcom_qg: limit the charging rise only by
  175  power: supply: qcom_qg: smoother release and immediate full
  176  power: supply: qcom_qg/qcom_smbx: remove debugfs files on
  177  power: supply: qcom_qg: reject implausible voltage samples at
  178  power: supply: qcom_smbx: create the debugfs files late, with
  179  power: supply: qcom_qg: fall back when a voltage sample is
  180  power: supply: qcom_qg: use the last ADC current for the
  181  power: supply: qcom_qg: fix the voltage choice and the
  182  power: supply: qcom_qg: during charging follow only the
  183  power: supply: qcom_qg: filter the current and fix the charge
  184  power: supply: qcom_qg: only trust OCV at rest, one point per
  185  power: supply: qcom_smbx: reconcile the input limit with APSD
  186  power: supply: qcom_smbx: report the programmed input limit
  187  power: supply: qcom_qg: document what 100% means on this port

Contexto por assunto:
  0168-0172  laudo read-only do PMIC, carga opt-in, negociacao APSD/ICL
  0173-0182  contagem de Coulomb, suavizacao, fallback de tensao, vies do OCV
  0183       dois bugs da contagem: retificacao do ruido e div_s64 (s32)
  0184       OCV so em repouso (|i| < 120 mA por 30 s), 1 ponto por leitura
  0185       reconciliacao do ICL com o APSD (replug real, ver 137s/147s)
  0186       CURRENT_MAX passa a ler o registrador de COMANDO no SMB5
  0187       documenta que 100% significa "charger terminou, pode tirar"

Prova de geracao: cat patches/*.patch | sha256 =
  5d2bab385b7272b14f3ad652e0b6b31e894ab03f64634e164f62c538b297e618
Estado congelado que usa esta serie: work/PRE-GOLD-20261027-1852/.
Detalhes: docs/kernel/checkpoint-2026-10-27-bateria-RESUMO.txt (secoes 17-27).

NOTA (28/10/2026 noite) — arquivos de build reconstruídos
--------------------------------------------------------
Numa sessão de áudio, um `cp -p` sobrescreveu por engano build.sh,
build-inside.sh, Dockerfile, config-7.3-hanoip, pack-boot.py, mkdeb.sh e
extra/ com as versões do v3, e despejou patches extras em patches/.
Restauração verificada:
  - patches/: 187 arquivos; `git am` sobre v7.3 reproduz a árvore
    9619406422a2 (= /src/obj/.tree-v4 = a77b73f17, kernel #24 do PRE-GOLD).
  - config-7.3-hanoip: copiada de /src/obj/.config, IDÊNTICA a
    /proc/config.gz do kernel rodando (inclui CONFIG_CPU_IDLE_GOV_TEO=y).
  - build-inside.sh: TREE ajustado para 9619406422a2 (checado) e gravado em
    /src/obj/.tree-v4, como descrito acima.
  - build.sh/Dockerfile/pack-boot.py/mkdeb.sh/extra: versões do v3 (o v4
    reaproveitava a imagem e o volume do v3). Diferenças finas que a versão
    original do v4 tivesse NÃO puderam ser recuperadas (estava fora do git).
O kernel com as correções de áudio está em ../v5/.
