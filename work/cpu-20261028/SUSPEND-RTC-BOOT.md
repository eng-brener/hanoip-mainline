SUSPEND / RTC / BOOT — 28/10/2026 (frente CPU 100%, itens G5/G6/G6b)
======================================================================
Tudo aqui foi medido no aparelho. Artefatos da variante que rodou já estavam
em work/cpu-20261028/ (cluster idle). Este arquivo cobre o que veio depois:
suspend, RTC e o boot de 3 minutos.

1. SUSPEND (s2idle) — TRÊS TESTES
---------------------------------
O kernel só oferece suspend-to-idle:
  /sys/power/state  = "freeze mem"     /sys/power/mem_sleep = [s2idle]
NÃO existe deep suspend neste port.

Teste 1 — rtcwake -m mem -s 25 (direto no /sys/power/state)
  durou 1,04 s; ADSP morreu:
    qcom_q6v5_pas: fatal error received:
      err_qdi.c:1040:EX:sensor_process:0x1:frpc_dsp:0xc7
    remoteproc0: crash detected in adsp: type fatal error
  Não recuperou (state=crashed; iio caiu para 2). O interrupt do crash
  abortou o suspend.
  LIÇÃO: rtcwake escreve direto em /sys/power/state e o systemd NÃO roda os
  hooks de sleep. Foi por isso que o primeiro hook não apareceu no log.

Teste 2 — systemctl suspend, hook parando só o hanoip-ssc/hexagonrpcd
  durou os 30 s pedidos (pre 09:24:20 / post 09:24:51) MAS o ADSP morreu
  igual. Desmentiu a hipótese de que a sessão FastRPC era a causa.

Teste 3 — hook desligando o REMOTEPROC (echo stop) — SUCESSO
  09:36:12 pre  desliga adsp
  09:36:13 pre  hexagonrpcd=0
  09:36:43 post religa hanoip-ssc            (31 s de suspend real)
  09:36:51 post usb0=172.16.42.1/24
  09:36:53 post adsp=running hexagonrpcd=1 iio=2
  crashes de ADSP depois: 0

HOOK: /usr/lib/systemd/system-sleep/hanoip-adsp
  pre : systemctl stop hanoip-ssc; pkill hexagonrpcd; echo stop no remoteproc
  post: systemctl start hanoip-ssc (ele faz "echo start" se state=offline);
        reaplica 172.16.42.1/24 no usb0 + dnsmasq (o usb0 volta SEM IPv4 do
        resume, medido — era o que derrubava o SSH por USB)
  Fonte: work/nethunter-pro-20261026/hanoip-support/hanoip-adsp

PENDENTE: soak de 3-4 ciclos (1 ciclo completo validado).


2. RTC 19.066 DIAS ATRASADO — resolvido por userspace
-----------------------------------------------------
Medido: RTC = 1974-08-15; sistema = 2026-10-28 (19.066 dias).
Boot: "rtc-pm8xxx: setting system clock to 1974-08-15T15:17:35 UTC".

Causa: driver calcula time = contador_cru + offset; o offset vem de uma célula
nvmem ("offset") que o DT não declara, e sem qcom,uefi-rtc-info o offset fica 0.
Além disso set_time retornava -ENODEV (sem allow-set-time).

Tentativa 1 (DT): "allow-set-time;" no &pm6150_rtc. O ioctl passou a chegar no
driver, mas falha com ERANGE (errno 34) para QUALQUER valor — não é faixa:
ERANGE não existe no regmap nem no rtc-pm8xxx; vem do caminho SPMI/arb
(proposta: limite de escrita multi-byte no bloco do RTC). Correção de kernel
fica pendente.

Solução efetiva (userspace): o contador ANDA certo (+3 s em 3 s), só está
deslocado por uma constante.
  /etc/hanoip/rtc-offset   -> RTC_OFFSET=1647376775
  /usr/local/sbin/hanoip-rtc save|apply|show
  hanoip-rtc.service (WantedBy=time-set.target) roda apply no boot; só mexe se
  o desvio passar de 60 s, para não brigar com o NTP.
Teste: relógio forçado a 1974 -> apply acertou para 2026-10-28 na hora.
Bônus: com relógio coerente, rtcwake volta a servir para testes automáticos.


3. BOOT DE 3 MINUTOS — Plymouth
-------------------------------
systemd-analyze: plymouth-start.service 186 s e plymouth-read-write 187 s.
Journal:
  09:31:07 Starting plymouth-start.service - Show Plymouth Boot Screen
  09:34:13 plymouth-start.service: start-post operation timed out. Terminating.
O splash não desenha no painel DSI e o systemd espera ~3 min. A tela fica
parada no texto do initramfs (reportado como "travou").
Não era regressão nossa — acontecia em todos os boots, invisível porque o SSH
sobe em ~16 s e só o graphical.target esperava.
Correção: mascarar plymouth-start/read-write/quit/quit-wait/switch-root.
Esperado: 3min19s -> ~15 s (confirmar no próximo boot).


4. ESTADO DAS CORREÇÕES
-----------------------
  RTC (offset + serviço) ........... OK, persistente
  ADSP sobrevive ao s2idle ......... OK com hook (remoteproc stop)
  usb0 após resume ................. OK (hook reaplica IPv4)
  Plymouth (3 min de boot) ......... mascarado, a confirmar
  deep suspend ..................... não existe no kernel
  soak de suspend .................. pendente (3-4 ciclos)


5. FECHAMENTO (28/10 ~10:00)
---------------------------
  L1 TÉRMICA (10 min, 8 núcleos, work/cpu-20261028/thermal-test-10min.log):
    pico cpu0 71,9 C · cpu6 74,8 C · cpu7 76,4 C
    throttling: 0 de 60 amostras (trips em 90/95/110 C nunca atingidas)
    A55 fixa em 1805 MHz; A76 >=2200 MHz em 23/60 amostras
  L2 TEO: CONFIG_CPU_IDLE_GOV_TEO=y -> available_governors = "menu teo";
    ativado (current=teo). Idle com TEO: cpu0 73% e cpu6 92% nos estados
    profundos; cluster S1 ainda colapsa. (Comparação com menu não é válida:
    janelas com cargas diferentes.)
  V1 cluster idle: S1 com 4.253 entradas / 67,7 s; S2 disparou 1 vez.
  V2 suspend: soak de 3 ciclos — ADSP running antes e depois de cada um,
    0 crashes; usb0 restaurado pelo hook.
  V3 boot: 2,956 s kernel + 13,151 s userspace = 16,1 s (era 3min19s).
  Estado final: 8 CPUs, TEO, 0 unidades falhando, 0 erros DSI no boot,
    relógio correto, usb0 com IPv4.
