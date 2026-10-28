MODEM: CHAMADAS / SMS / DADOS — investigação de 28/10/2026
===========================================================
Sem chip SIM (por decisão do usuário: não testar com chip). Este documento é
investigação: o que o Android de base mostra, o que o Linux já entrega medido,
o que fica bloqueado e o que provavelmente não vai funcionar nem com SIM.

CONCLUSÃO CURTA
  O modem FUNCIONA no Linux. ModemManager enumera o modem, lê firmware, IMEI e
  bandas, e o transporte QMI/QRTR + IPA está de pé. O único bloqueio imediato é
  `sim-missing` (não há chip). O que não existirá nem com chip é VoLTE/IMS.

1. ANDROID DE BASE (o que ele usava)
------------------------------------
  Dump: work/android-dump-20261025/ (deep/getprop.txt, vendor-config.tar)
    qcrild e qcrild2 em execução (vendor QMI RIL), dois processos = DSDS
    persist.radio.multisim.config = dsds
    gsm.version.baseband = M7150_25.333.01.85R
    daemons de IMS no vendor: ims_rtp_daemon.rc, imsqmidaemon.rc,
      imsdatadaemon.rc, imsrcsd.rc; permissão android.hardware.telephony.ims.xml
  Firmware do modem: parte da imagem `modem` (remoteproc), carregada da
  partição vendor/firmware_mnt. Não há stack de RIL aproveitável no Linux
  (HIDL/Binder), mas o protocolo por baixo é QMI — que o Linux fala nativo.

2. LINUX: O QUE JÁ ESTÁ MEDIDO E FUNCIONANDO
--------------------------------------------
  remoteproc1: firmware = qcom/sm7150/motorola/hanoip/modem.mdt, state=running
  ModemManager 1.24.2 (mmcli -m 0):
    manufacturer .... QUALCOMM INCORPORATED
    firmware ........ MPSS.AT.4.4-00333-RENNELL_GEN_PACK-3.475832.24 1
                      [Apr 12 2023]
    h/w revision .... 10000
    equipment id .... <IMEI lido com sucesso>
    modos ........... gsm-umts, lte (2G/3G/4G); bandas: egsm/dcs/pcs/g850,
                      utran 1/2/4/5/6/8, eutran 1/2/3/4/5/7/8/12/13/17/19/28/40/66
    physdev ......... /sys/devices/platform/soc@0/1e40000.ipa
    drivers ......... ipa, qrtr        plugin: qcom-soc
    portas .......... qrtr0 (qmi), rmnet_ipa0 (net)
    estado .......... failed / sim-missing
    voz ............. interface presente, "emergency only: yes"

  Serviços QMI que o modem anuncia no QRTR (qrtr-lookup), node 0:
     1 WDS  Wireless Data (dados)          2 DMS  Device Management
     3 NAS  Network Access (registro)      4 QoS
     5 WMS  Wireless Messaging (SMS)       7 Auth
     8 AT                                  9 Voice v2 (chamadas)
    10 CAT   Card Application Toolkit     11 UIM (SIM)
    12 Phonebook                          16 LOC (GPS, ver doc proprio)
    21 EFS   22 Time   23/24 Thermal      26 WDA   29 CSVT
  Ou seja: chamada, SMS, dados e SIM têm serviço correspondente disponível.
  O ModemManager desta versão tem API completa de voz
  (--voice-create-call, --voice-list-calls, --voice-hangup-all, ...).

3. O QUE ESTÁ BLOQUEADO HOJE E POR QUÊ
--------------------------------------
  a) Sem chip, o MM marca o modem como failed/sim-missing e recusa habilitar:
       mmcli -m 0 --enable -> "WrongState: Wrong state: modem in failed state"
     Isso é política do ModemManager (estado inicial sem SIM), não defeito de
     driver. Com um chip o modem entraria em "registered" normalmente.
  b) rmnet_ipa0 está DOWN: só sobe quando existe bearer (APN + registro).
  c) Sem SIM não há como validar: registro em operadora, SMS, APN/dados,
     chamada. Nada disso foi testado (e não será, sem chip).

4. O QUE NÃO VAI FUNCIONAR NEM COM CHIP — VoLTE / IMS
-----------------------------------------------------
  O Android tem uma pilha IMS inteira (ims_rtp_daemon, imsqmidaemon,
  imsdatadaemon, imsrcsd) que no Linux NÃO existe. Consequências:
    - Chamada por VoLTE (IMS) não é suportada.
    - Chamada só funcionaria por comutação de circuitos (2G/3G), que depende
      de a operadora ainda manter CS e de cobertura 3G/2G no local.
    - Em operadora "VoLTE-only" (caso de várias redes 5G atuais), chamada
      simplesmente não sai.
  SMS por CS/IMS: o WMS está lá; SMS sobre CS costuma funcionar, sobre IMS não.

5. CHECKLIST PARA QUANDO HOUVER UM CHIP (não executar agora)
------------------------------------------------------------
  1. Inserir chip, `mmcli -L` e `mmcli -m 0` (esperado: state=registered,
     sim slot 1 com ICCID/IMSI).
  2. Registro: `mmcli -m 0 --3gpp-register-home`; conferir operadora e sinal.
  3. SMS: `mmcli -m 0 --messaging-create-sms="text=..."` + `--send`.
  4. Dados: `mmcli -m 0 --create-bearer="apn=<apn>"`, `--bearer=<id> --connect`;
     conferir rmnet_ipa0 UP e IP.
  5. Chamada: `mmcli -m 0 --voice-create-call="number=..."` e `--voice-list-calls`.
     Se falhar por falta de IMS, testar forçando 2G/3G: `--set-allowed-modes`.
  6. Guardar log com `ModemManager --debug` para o primeiro registro.
  Critério de aceite: SMS enviado, dados com IP e ping, chamada com áudio nos
  dois sentidos (o áudio ainda depende do microfone/earpiece estarem prontos —
  ver item 1.3 de docs/HARDWARE-PENDENTE.md).

6. RISCOS E INCÓGNITAS
----------------------
  - DSDS: o Android roda dois qcrild (slot 1 e 2). O MM no Linux trata um modem
    com dois slots, mas só o slot com SIM fica utilizável; não foi validado.
    Existe também o serviço UIMRMT no QRTR, que o Android usa para o segundo
    slot — o MM não o utiliza.
  - Firmware do modem é de abril/2023 (MPSS.AT.4.4-00333). É o mesmo do Android
    atual do aparelho; não mexemos nele.
  - Não foi feita nenhuma escrita em partição nesta investigação.
