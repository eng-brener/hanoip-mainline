LEVANTAMENTO: O QUE FALTA PARA A CPU CHEGAR A 100%
===================================================
28/10/2026. Base: DT em vigor (work/PRE-GOLD-20261027-1852/uboot/uboot.dtb e
o dtsi em uboot-sm7150/), .config do kernel 7.3 (build 187), checkpoints de
24-25/10 (cpufreq, cpu8, cpuidle) e o fork sm7150-mainline/linux (upstream).

"100%" aqui = 8 núcleos, escalonamento de frequência nos dois clusters,
estados de idle corretos, térmica limitando quando precisa, e memória (DDR/L3)
acompanhando a frequência da CPU.

IMPORTANTE: o aparelho não estava acessível quando isto foi escrito. Os itens
marcados [VERIFICAR] precisam de leitura ao vivo (seção 5).


1. O QUE JÁ ESTÁ PRONTO (evidência)
-----------------------------------
DT (idêntico ao upstream do fork, não é versão mutilada nossa):
  - 8 CPUs PSCI: cpu0..cpu5 (A55, capacity 488) e cpu6/7 (A76, 1024),
    com dynamic-power-coefficient 137 / 480  -> modelo de energia correto
  - qcom,freq-domain: cpufreq_hw 0 (A55) e 1 (A76)
  - interconnects nas 8 CPUs (gem_noc MASTER_AMPSS_M0)
  - idle-states por cluster: little cpu-sleep-0-0/0-1, big cpu-sleep-1-0/1-1
  - domain-idle-states: cluster-sleep-0 e cluster-sleep-1 (colapso de cluster)
  - tsens0/tsens1 + thermal-zones com trips 90/95/110 C e cooling-maps para
    cpu0..cpu5
KERNEL (.config):
  - ARM_QCOM_CPUFREQ_HW=y, CPU_FREQ_GOV_SCHEDUTIL (default), ENERGY_MODEL=y
  - ARM_PSCI_CPUIDLE=y + _DOMAIN=y, CPU_IDLE_GOV_MENU=y
  - INTERCONNECT_QCOM_SM7150=y, OSM_L3=y, BCM_VOTER (bwmon) =y
HISTÓRICO VALIDADO (checkpoints):
  - 25/10 cpu8: TODOS os 8 núcleos sobem (A76 até 2304 MHz, A55 1804,8 MHz);
    idle nos A76 com cpu-sleep-1-0 e 1-1 em uso; carga em 8 núcleos por 45 s
  - 24/10 cpufreq: qcom-cpufreq-hw, 300..1804,8 MHz, governors testados
  - 25/10 cpuidle: estados LOCAIS passam; colapso de cluster = tela preta


2. AS LACUNAS (o que falta, em ordem de impacto)
------------------------------------------------

G1. OS 8 NÚCLEOS — CONFIRMADO EM 28/10 (e fonte limpo)
    Medido ao vivo no pré-GOLD:
      /sys/devices/system/cpu/online ..... 0-7   (possible: 0-7)
      /proc/cmdline ...................... sem maxcpus/cpufreq.off/cpuidle.off/idle
      cpuinfo ............................ 8 processadores, cpu6 part 0x805
      policy0 (A55, cpus 0-5) ............ schedutil, 300..1805 MHz
      policy6 (A76, cpus 6-7) ............ schedutil, 300..2304 MHz
    Ou seja: 8 núcleos e frequência nos DOIS clusters já funcionam nesta par de
    boot. O limite de 6 núcleos do histórico era o maxcpus=6.
    FEITO TAMBÉM: removi "maxcpus=6 cpuidle.off=1 cpufreq.off=1 idle=poll" do
    fonte sm7150-motorola-hanoip.dts e deixei um comentário em maiúsculas
    explicando por que NÃO reintroduzir (com maxcpus=6 o kernel fecha as
    capacidades com os A55 e recusa o CPU6: "Detected conflict for capability
    80 (Spectre-v2)"). Nenhuma mudança de comportamento agora, porque a cadeia
    perif-* já sobrescrevia /chosen — mas elimina o risco em variantes futuras.

G2. TABELAS OPP — **NÃO É LACUNA** (correção de 28/10)
    Eu havia escrito que as tabelas tinham 1 OPP de 300 MHz. ERRADO: eu li o
    dtsi com um awk que parava no primeiro "};" e truncava a tabela. Medido no
    DTB construído e no fonte:
      opp-table-cpu0 (A55): 10 OPPs, 300.000 a 1.804.800.000 Hz
      opp-table-cpu6 (A76): 13 OPPs, 300.000 a 2.304.000.000 Hz
    Cada OPP traz opp-hz E opp-peak-kBps (DDR 4-wide x 2 canais x DDR e
    L3 16-wide x 2 canais), inclusive os pontos altos.
    MEDIÇÃO QUE FECHA O ASSUNTO (28/10, ao vivo):
      com scaling_max_freq = 300 MHz  -> cpu0 e cpu6 votam  9.600.000 kBps
      com o maximo (1804,8 / 2304)    -> cpu0 41.779.200  cpu6 46.694.400
    Ou seja: o voto de banda ACOMPANHA a frequencia. O subsistema de
    interconnect esta funcionando e a memória não fica presa no mínimo.
    (Lição: não concluir nada sobre tabela OPP sem olhar o DTB construído.)

G3. COLAPSO DE CLUSTER — TESTADO EM 28/10: FUNCIONA (display e touch OK)
    SITUAÇÃO QUE ENCONTRAMOS: o colapso estava DESLIGADO. O DT que roda é uma
    PILHA de overlays (ver seção 6) e o cpuidle-local-diagnostic faz
    &cluster_pd { /delete-property/ domain-idle-states; } — por isso o genpd de
    cluster só tinha S0 e o aparelho rodava em idle "local-only".
    COMPROVADO NO DTB: domain-idle-states só existia em /psci/power-domain-
    cpu0..7; /psci/power-domain-cluster não tinha a propriedade.

    TESTE FEITO (28/10, 09:00): variante sm7150-motorola-hanoip-clusteridle-
    test.dts, que inclui o perif-batt e devolve os 3 estados ao &cluster_pd
    (cluster-sleep-0 PC / -1 CX ret / -2 AOSS). fdt_diff contra o pré-GOLD:
    744 nós, +1 propriedade em /psci/power-domain-cluster e +3 phandles; o resto
    é renumeração de phandle. bootargs idênticos.
    Artefatos e log: work/cpu-20261028/ (img 5ff86a75..., dtb 4d1fb2c4...).

    RESULTADO MEDIDO:
      - estados registrados: S0 (lat 5800us), S1 (8200us), S2 (9825us)
      - S1 (CX retention) entrou 4.063 vezes em ~290 s, 163 s acumulados
        (~57% do tempo) — inclusive COM A TELA LIGADA
      - S2 (AOSS) NUNCA entrou (0 usos)
      - tela: dpms Off->On limpa, status connected, ZERO erro DSI novo
        (dsi_err_worker ficou em 6, todos do boot)
      - touch: Ilitek 0x78071c03 religou o IRAM após power-on e respondeu
      - temperatura: pico 41,6 C ao ligar a tela, estabilizou em ~36 C
      - usuário confirmou: "a imagem ta perfeita, touch tb"
    CONCLUSÃO: para ESTA configuração, o colapso de cluster em S1 não quebra o
    display. A hipótese histórica ("cluster = tela preta") NÃO se confirma aqui.
    O caminho S2/AOSS continua não testado (o governador nunca o escolhe).
    SUSPEITA NOVA, para investigar se o bug voltar: a cada power cycle do painel
    o LCDB é desligado e o touch recarrega IRAM ("IRAM reloaded after panel
    power-on"); o cluster pode ser só o gatilho que aumenta a FREQUÊNCIA desses
    ciclos, não a causa.

    PENDENTE PARA FECHAR G3 DE VEZ: soak com vários ciclos de tela (o usuário
    liga/apaga; monitor em /root/cluster-watch.sh grava a cada 2 s) e, se o
    contador de erro DSI ficar em 6, promover esta variante a base.

G4. TÉRMICA SOB CARGA SUSTENTADA — TESTADA EM 28/10 (10 min, 8 núcleos)
    Protocolo: 8 laços de CPU por 600 s, amostragem a cada 10 s, com aborto
    automático acima de 100 C. Script: hanoip-support/teste-termico
    Log: work/cpu-20261028/thermal-test-10min.log (60 amostras).
    RESULTADO:
      pico de temperatura ... cpu0 71,9 C · cpu6 74,8 C · cpu7 76,4 C
      throttling ............ ZERO em 60/60 amostras (cool0=cool6=0)
      trips (90/95/110 C) ... nunca atingidas
      A55 ................... 1805 MHz o tempo todo
      A76 ................... >=2200 MHz em 23 de 60 amostras (o resto é
                              schedutil reagindo à carga irregular do teste)
      depois da carga ....... volta a 43 C em ~1 min
    CONCLUSÃO: com 8 núcleos em carga por 10 min o aparelho estabiliza na
    faixa de 75 C, com ~15 C de folga até a primeira trip passiva (90 C) e
    sem acionar nenhum cooling device. A térmica NÃO limita a CPU hoje.
    RESSALVA HONESTA: a carga usada (laços com `date`) não é 100% estável;
    um teste com carga sintética constante (ex.: stress-ng) mediria o teto
    real. Para "não limita", o resultado já basta.

G5. SUSPEND/RESUME — RESOLVIDO EM 28/10 (s2idle usável, com hook)
    O QUE EXISTE: /sys/power/state = "freeze mem"; mem_sleep = [s2idle] apenas.
    NÃO há deep suspend neste port — só suspend-to-idle (freezer + idle).

    TRÊS TESTES, EM ORDEM, E O QUE CADA UM DESMENTIU:
      1) rtcwake -m mem -s 25 direto em /sys/power/state
         -> entrou e saiu em 1,04 s; ADSP morreu (err_qdi.c:1040,
            EX:sensor_process:0x1:frpc_dsp:0xc7) e nao recuperou; iio caiu para 2.
         Lição: rtcwake escreve direto no /sys/power/state, então o systemd NÃO
         roda os hooks de sleep (o hook existia e não foi chamado).
      2) systemctl suspend (hooks ativos) com hook que só parava o
         hanoip-ssc/hexagonrpcd -> suspend durou os 30 s (pre 09:24:20,
         post 09:24:51), MAS o ADSP morreu igual.
         DESMENTIU A HIPÓTESE: não é a sessão FastRPC que mata o ADSP.
      3) hook desligando o REMOTEPROC (echo stop) antes de suspender e deixando
         o hanoip-ssc religar depois -> SUCESSO:
           pre  09:36:12 desliga adsp; 09:36:13 hexagonrpcd=0
           post 09:36:43 religa hanoip-ssc (31 s de suspend real)
           post 09:36:51 usb0=172.16.42.1/24
           post 09:36:53 adsp=running hexagonrpcd=1 iio=2
           crashes de ADSP: 0
    IMPLEMENTAÇÃO: /usr/lib/systemd/system-sleep/hanoip-adsp
      pre : systemctl stop hanoip-ssc; pkill hexagonrpcd;
            echo stop em /sys/class/remoteproc/*62400000.remoteproc*/state
      post: systemctl start hanoip-ssc (ele faz "echo start" se state=offline);
            reaplica 172.16.42.1/24 no usb0 e o dnsmasq do host
      (o usb0 voltava do resume SEM IPv4 — medido — e isso derrubava o SSH USB)
    Fonte: work/nethunter-pro-20261026/hanoip-support/hanoip-adsp
    PENDENTE: soak de 3-4 ciclos (validado 1 ciclo completo).

G6. RTC 19.066 DIAS ATRASADO — RESOLVIDO EM 28/10 (por userspace)
    MEDIDO: RTC = 1974-08-15, sistema = 2026-10-28 (19.066 dias). No boot:
    "rtc-pm8xxx: setting system clock to 1974-08-15T15:17:35 UTC".
    CAUSA: o driver faz time = contador_cru + offset, e o offset vem de uma
    célula nvmem ("offset") que este DT não declara; sem ela e sem
    qcom,uefi-rtc-info, offset = 0 e o contador cru do PMIC (que conta desde a
    fabricação) vira a hora. Pior: set_time retornava -ENODEV (allow-set-time
    ausente), então "hwclock -w" nunca funcionou.
    TENTATIVA 1 (DT): "allow-set-time;" no &pm6150_rtc -> o ioctl RTC_SET_TIME
    passou a chegar no driver, mas falha com ERANGE (errno 34).
    INVESTIGAÇÃO DO ERANGE (28/10) — o que foi descartado, com evidência:
      - não está no regmap: "grep ERANGE drivers/base/regmap/*.c" = nada
      - não está no SPMI: "grep ERANGE drivers/spmi/*.c" = nada
      - não está no driver: "grep ERANGE drivers/rtc/rtc-pm8xxx.c" = nada
      - em drivers/rtc só existe em class.c:77 (hctosys, só 32 bits) e
        interface.c:78 (rtc_valid_range)
      - o range do RTC está OK: /sys/class/rtc/rtc0/range = [0, 4294967295] e
        agora = 1793191479 (dentro)
      - não há "start-year" em nenhum DTS nem no DTB (verificado por grep)
      - o ioctl é o correto: struct rtc_time = 9 ints = 36 B -> 0x4024700a
      - TODOS os valores testados falham, inclusive 0 e o próprio valor atual:
        0, 1e9, 2e9, 3e9, 4e9, 4294967290
    CAUSA RAIZ ENCONTRADA (28/10) — com kretprobes + dmesg, em duas etapas:
      1) kretprobe mostrou rtc_valid_range retornando -34 (0xffffffde) e, antes
         disso, o problema real: EU passava tm_year como ano cheio (2026). A ABI
         do RTC usa ANOS DESDE 1900 (126). Com 2026 o kernel entendia ano 3926
         -> fora do range -> ERANGE. Bug do meu script (rtc-set), nao do kernel.
      2) Corrigido o tm_year, veio -EPERM e o dmesg explicou tudo:
           spmi spmi-0: disallowed SPMI write to sid=0, addr=0x6046
         Origem (drivers/spmi/spmi-pmic-arb.c):
           case PMIC_ARB_CHANNEL_RW:
             if (bus->apid_data[apid].write_ee != pmic_arb->ee)
                 return -EPERM;   /* ACL por APID */
         Ou seja: o ARBITRO DO PMIC tem ACL por APID e o APID do RTC pertence a
         OUTRO Execution Environment. O Linux (nosso EE) pode LER (canal de
         observacao) mas NAO PODE ESCREVER. Isso e' configuracao de plataforma
         gravada pelo bootloader, nao algo que um driver contorne.
      CONSEQUENCIA: set_time nunca funcionara por driver neste aparelho.
      O caminho "oficial" alternativo seria o offset em nvmem (pm8xxx_rtc_
      update_offset), mas o unico SDAM do PMIC (nvram@b600) e' COMPARTILHADO com
      o QGauge (OCV em 0x4c, capacidade em 0x68) — e nao vamos arriscar os dados
      do medidor de bateria que custaram um dia de calibracao.
      DECISAO: manter o offset em userspace (/etc/hanoip/rtc-offset +
      hanoip-rtc.service), que esta validado. L3 encerrado com causa raiz.
      (A gravacao do ALARME funciona: rtcwake -m no -s 30 programou e acordou.)
    SOLUÇÃO EFETIVA (userspace, sem tocar no PMIC): o contador do RTC ANDA certo
    (medido: +3 s em 3 s), só está deslocado por uma constante.
      /etc/hanoip/rtc-offset  -> RTC_OFFSET=1647376775
      /usr/local/sbin/hanoip-rtc save|apply|show
      hanoip-rtc.service (WantedBy=time-set.target) roda "apply" no boot:
        se o relógio estiver fora por >60 s, faz date -s @(raw + offset);
        se já estiver coerente, não briga com o NTP.
    TESTE: com o relógio forçado a 1974, "apply" acertou para 2026-10-28 na
    hora. Fontes: hanoip-support/hanoip-rtc e hanoip-support/rtc-set (ioctl,
    usado para o diagnóstico).
    EFEITO COLATERAL BOM: com relógio coerente, rtcwake volta a ser utilizável
    para testes automáticos de suspend.

G6b. BOOT DE 3 MINUTOS — PLYMOUTH (achado e corrigido em 28/10)
    systemd-analyze culpava plymouth-start.service (186 s) e
    plymouth-read-write.service (187 s):
      "plymouth-start.service: start-post operation timed out. Terminating."
    O splash não desenha no nosso painel DSI e o systemd espera ~3 min. A tela
    ficava parada no texto do initramfs (foi reportado como "travou").
    NÃO era regressão nossa: acontecia em todos os boots, invisível porque o
    SSH sobe em ~16 s e só o graphical.target esperava.
    CORREÇÃO: mascarar plymouth-start/read-write/quit/quit-wait/switch-root.
    Esperado no próximo boot: ~3min19s -> ~15 s. (confirmar)

G7. GPU (gpuss) ................................................... FORA DO ESCOPO
    Não sobe; o checkpoint de 25/10 registra "gpuss sem cdev até a GPU subir".
    Não limita a CPU, mas limita o SoC e a térmica compartilhada.

G8. idle=poll e cpufreq.off no fonte .............................. LIMPEZA
    idle=poll não existe em arm64 (o kernel ignora), e cpuidle.off=1 desliga
    os estados. Só não estão em vigor porque o /chosen é sobrescrito. Vale
    limpar o fonte para não repetir o tropeço em variantes futuras.

G9. IDLE — VERIFICADO E MELHORADO EM 28/10 (TEO habilitado)
    MEDIDO com o governor 'menu' (janela de 30 s, tela apagada, load 0.03):
      driver psci_idle; A55 92% do tempo em cpu-sleep-0-1 (+971 usos / 27,7 s);
      A76 97% em cpu-sleep-1-1 (rail-PC); cluster S1 78% do tempo.
    LACUNA CORRIGIDA: só existia o governor 'menu'. Adicionado
    CONFIG_CPU_IDLE_GOV_TEO=y ao config-7.3-hanoip (1 linha; exige rebuild do
    kernel, não é DT) e o kernel foi reconstruído e bootado (v3-teo).
      available_governors = "menu teo"   current = teo
    MEDIDO com TEO (20 s, load 0.59):
      cpu0 estado profundo +14,5 s de 20 (73%); cpu6 +18,4 s de 20 (92%);
      cluster S1 +3,2 s de 20 (16%).
    NOTA HONESTA: as duas janelas têm cargas diferentes (0.03 vs 0.59), então
    NÃO dá para afirmar que TEO é melhor que menu aqui — só que funciona e que
    os estados profundos continuam dominando. Comparação honesta exigiria medir
    corrente na bateria (o aparelho estava no carregador).
    Pendências que sobraram: nada bloqueante. S2/AOSS agora disparou 1 vez.



6. ACHADO COLATERAL IMPORTANTE: O DT DE PRODUÇÃO É UMA PILHA DE DIAGNÓSTICOS
--------------------------------------------------------------------------
O "DT do pré-GOLD" não é um arquivo de placa; é o empilhamento de 17 arquivos,
a maioria chamada *-diagnostic.dts. Isso funciona (boota), mas tem duas
consequências práticas:
  - o comportamento de CPU atual (8 núcleos, cpuidle local-only, OTG) é
    resultado de SOBRESCRITAS em cadeia, não de uma decisão num único lugar;
  - quem editar o hanoip.dts achando que manda no bootargs pode se enganar: o
    cpu8-diagnostic define por último e vence.
Antes de promover o pré-GOLD a GOLD, vale consolidar isso num DT de placa
honesto (sem a palavra diagnostic no caminho), com as escolhas escritas uma vez
só. Fica como item de higiene para depois do G3/G2.


=====================================================================
7. REANÁLISE COMPLETA — 2ª PASSADA (28/10, aparelho vivo)
=====================================================================
Refiz o levantamento do zero, procurando o que eu NÃO tinha olhado antes
(scheduler/EAS, governadores, corners de tensão, afinidade de IRQ).

CONFIRMADO BOM (não é lacuna):
  - 8 CPUs online (0-7)
  - cpufreq schedutil nos dois clusters: 300..1805 MHz (A55) e 300..2304 (A76)
  - EAS ATIVO: /proc/sys/kernel/sched_energy_aware = 1
  - energy model populado: /sys/kernel/debug/energy_model/cpu0 = 13 estados,
    cpu6 = 17 estados (EAS tem dados reais para escolher núcleo/frequência)
  - capacity-dmips 488/1024 + dynamic-power-coefficient 137/480
  - OPP completos (10 no A55, 13 no A76) com opp-peak-kBps; voto de banda
    medido escalando: 9.600.000 kB/s a 300 MHz -> 41,8/46,7 GB/s no topo
  - idle psci_idle + menu, estados mais profundos dominando (92-97%)
  - colapso de cluster S1 testado (4.063 entradas), tela e touch OK
  - térmica: 819 zonas, 31 cooling devices, INCLUINDO cpufreq-cpu0 (0/9) e
    cpufreq-cpu6 (0/13) -> o A76 TEM cooling device; trips 90/95/110 C;
    nenhum throttling ocorreu ainda (cur_state=0)
  - suspend s2idle: 31 s reais, ADSP sobrevive com o hook, usb0 restaurado
  - bootargs limpos (sem maxcpus/cpufreq.off/idle=poll); Plymouth mascarado
  - NO_HZ_IDLE, HZ=1000, PREEMPT, SCHED_MC/SCHED_CLUSTER/UCLAMP habilitados
  - IRQ "presa" no CPU0 é apenas pmic_arb/pm8xxx_rtc_alarm (normal, SPMI
    serializado); o resto é distribuído

LACUNAS QUE SOBRARAM (3 reais + 3 de validação):

  L1. TÉRMICA SOB CARGA SUSTENTADA (G4) — única lacuna de comportamento
      Tudo existe (trips e cdevs para os dois clusters) mas NUNCA medimos
      além de 45 s. Falta: onde o throttling entra, quanto corta, e se o
      aparelho sustenta carga longa sem passar de 95 C.

  L2. IDLE: só existe o governor 'menu' — TEO NÃO está compilado
      CONFIG_CPU_IDLE_GOV_MENU=y e nada de CPU_IDLE_GOV_TEO.
      TEO costuma render melhor residência em idle e menos wakeups em ARM
      moderno. Correção = configuração do kernel + rebuild (não é DT).
      Verificado: available_governors = "menu" (só).

  L3. ESCRITA DO RTC NO PMIC (ERANGE) — opcional/kernel
      allow-set-time levou o ioctl até o driver, mas ele falha com ERANGE
      para qualquer valor, e o ERANGE não existe no regmap nem no driver:
      vem do caminho SPMI/arb. Continuamos com o offset em userspace, que
      funciona. Investigar quando valer a pena.

  V1. SOAK do colapso de cluster (1 ciclo validado)
  V2. SOAK do suspend (1 ciclo validado)
  V3. CONFIRMAR o boot rápido (Plymouth mascarado; esperado 3min19s -> ~15 s)

OBSERVAÇÃO (não é lacuna, é limite): S2/AOSS nunca é escolhido pelo
governador de idle, e NÃO existe deep suspend neste kernel — só s2idle.

VEREDITO: em desempenho e em configuração, a CPU está em 100%. O que falta é
(a) validar a térmica sob carga longa, (b) opcionalmente compilar o TEO e
(c) fechar os soaks. Nada mais bloqueia.


=====================================================================
8. FECHAMENTO DA FRENTE CPU 100% (28/10, ~10:00)
=====================================================================
Medido no boot final (kernel v3-teo, U-Boot com cluster idle + RTC):
  boot .................. 2,956 s kernel + 13,151 s userspace = 16,1 s
                          (era 3 min 19 s por causa do Plymouth)
  nucleos ............... 0-7 (8)
  cpufreq ............... schedutil, 300..1805 (A55) / 300..2304 (A76)
  idle .................. psci_idle + TEO (menu tambem disponivel)
  cluster idle .......... S1 com 4.253 entradas / 67,7 s; S2 disparou 1 vez
  erros DSI ............ 0 NESTE BOOT (nos anteriores eram 6 no boot)
  ADSP ................. running; hanoip-ssc active; usb0 com IPv4
  unidades falhando .... 0
  relogio .............. correto (2026-10-28), via RTC + offset
  termica .............. 10 min de 8 nucleos: pico 71,9/74,8/76,4 C, sem throttling
  suspend .............. 3 ciclos de s2idle no soak, ADSP sobreviveu (0 crashes)

LACUNAS ENCERRADAS NESTA FRENTE:
  G1 8 nucleos ............... confirmado
  G2 OPP/banda ............... nao era lacuna (erro meu de leitura)
  G3 cluster idle ............ funciona (display e touch), soak feito
  G4 termica ................. testada 10 min, sem throttling
  G5 suspend ................. s2idle usavel com hook do ADSP (soak 3 ciclos)
  G6 RTC ..................... causa raiz: ACL do arbitro SPMI; resolvido por
                               userspace (offset)
  G6b Plymouth ............... mascarado; boot caiu de 3min19s para 16,1 s
  G9 idle .................... TEO adicionado e ativo

O QUE NAO E LACUNA / NAO DA PARA FECHAR:
  - deep suspend: nao existe neste kernel (so s2idle)
  - escrita do RTC por driver: bloqueada pelo arbitro (ACL por APID), nao e'
    problema de software
  - GPU (gpuss): frente separada
  - S2/AOSS: quase nunca escolhido (1 vez), estado raro mas funcional

VEREDITO: a CPU esta em 100% do que o hardware e este kernel permitem, com
evidencia medida em cada item. O que resta sao frentes vizinhas (GPU, audio,
camera) e nao a CPU.


=====================================================================
9. 3ª VALIDAÇÃO — ITEM POR ITEM (28/10, kernel + hardware)
=====================================================================
Refeita do zero, no nível de features de CPU, PMU, atomics, errata,
topologia e governadores. Resultado, com evidência de cada linha:

CONFIRMADO (kernel + hardware):
  CPUs ................ 8 PSCI; HOTPLUG funciona (offline 7 -> 0-6 -> 0-7)
  capacity por CPU .... A55 382, A76 1024  (382 = 488 x 1804,8/2304: é a
                         escala relativa ao núcleo de maior capacidade, correto)
  cpufreq ............. qcom-cpufreq-hw; 300.000..1.804.800 e ..2.304.000
  frequências ......... 10 no A55 e 13 no A76 (todas as OPP do hardware)
  scheduler ........... schedutil + EAS (sched_energy_aware=1) + energy model
                         (13 estados no cpu0, 17 no cpu6)
  uclamp .............. min=max=1024 -> é o PADRÃO "sem clamp", não trava nada
  idle ................ psci_idle + TEO (adicionado hoje) + cluster S1/S2
  térmica ............. 10 zonas de CPU + 31 cooling devices; trips 90/95/110 C;
                         10 min de carga sem throttling (pico 76,4 C)
  governor térmico .... step_wise; power_allocator (IPA) disponível -> aplicado
                         nas 10 zonas de CPU em 28/10 (reversível, testado)
  PMU ................. registrado: armv8_cortex_a55 e armv8_cortex_a78
  atomics (LSE) ....... hardware tem 'atomics' nos 8 núcleos; o kernel 7.3 usa
                         alternatives em runtime (ARM64_HAS_LSE_ATOMICS)
  errata .............. 14+ workarounds compilados (819472 ... 4311569)
  opções .............. PSI, CPU_FREQ_STAT, CPU_FREQ_THERMAL, HOTPLUG_CPU,
                         PERF_EVENTS, ARM_PMUV3, SCHED_AUTOGROUP: todos =y

NÃO É LACUNA (correções de achados meus nesta passada):
  - PMU diz "a78": o dtsi usa "arm,cortex-a78-pmu" no cluster A76, mas AMBOS
    os compatibles usam PMUV3_INIT_SIMPLE (init idêntico). É só o NOME errado,
    não muda contagem. Cosmético; renomear exigiria rebuild de U-Boot.
  - LSE atomics sem CONFIG: no 7.3 o símbolo ARM64_LSE_ATOMICS foi REMOVIDO do
    arch/arm64 — virou alternativa de runtime. Nada a habilitar.
  - uclamp 1024/1024: valor padrão, significa "sem limite".

OPCIONAIS — TODOS FEITOS EM 28/10:
  1. IDLE TEO + THERMAL IPA PERSISTENTES: /usr/local/sbin/hanoip-cpu-tune +
     hanoip-cpu-tune.service. Sem isso, o kernel volta para 'menu' e
     'step_wise' a cada boot (as escolhas são de runtime, não de config).
     Log: /run/hanoip-cpu-tune.log  ->  "idle governor: teo" e
     "thermal: power_allocator em 12 zonas de CPU".
  2. LINUX-PERF INSTALADO (7.1.5-1kali1) e TESTADO com o PMU:
       perf stat -a -e cycles,instructions -- sleep 1
       -> 93.564.638 cycles e 41.170.705 instructions em 1 s
     kernel.perf_event_paranoid=1 persistente (/etc/sysctl.d/60-hanoip-perf.conf)
     para usuário comum poder medir o próprio processo.
  3. PMU RENOMEADO no dtsi: pmu-a76 agora é "arm,cortex-a76-pmu" (era a78).
     Exige rebuild de U-Boot; feito e bootado no mesmo dia.

VEREDITO FINAL: nada falta para a CPU. Os três itens acima são melhorias de
observabilidade/acabamento, não capacidades ausentes.


=====================================================================
10. VERIFICAÇÃO FINAL DOS "OPCIONAIS" (28/10 ~10:06, boot limpo)
=====================================================================
Boot com o U-Boot renomeado (PMU) + kernel v3-teo:
  PMU .................. armv8_cortex_a55 e armv8_cortex_a76  (era a78)
  perf ................. perf 7.1.5; "perf stat -a -e cycles -- sleep 0.5"
                         -> 1.163.999.110 cycles em 0,503 s
  idle governor ........ teo (aplicado no boot pelo hanoip-cpu-tune)
  thermal governor ..... power_allocator em 12 zonas de CPU
  boot ................. 2,933 s kernel + 11,805 s userspace = 14,7 s
  8 CPUs ............... online 0-7
  systemd .............. 0 unidades falhando
  ADSP ................. running
  fdt_diff ............. 1 propriedade alterada: /pmu-a76 compatible
                         "arm,cortex-a78-pmu" -> "arm,cortex-a76-pmu"

NOVOS ARTEFATOS DESTA ETAPA:
  hanoip-support/hanoip-cpu-tune        (persiste TEO + IPA no boot)
  hanoip-support/hanoip-cpu-tune.service
  /etc/sysctl.d/60-hanoip-perf.conf     (perf_event_paranoid=1)
  work/cpu-20261028/ (u-boot, dtb e SHA256SUMS atualizados com o PMU novo)

FRENTE CPU 100%: ENCERRADA. Nada pendente.
