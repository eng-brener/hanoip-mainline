GPS / GNSS NO KALI (hanoip) — levantamento de 28/10/2026
=========================================================
Status: CAMINHO ENCONTRADO E SESSÃO INICIADA. Falta fix (visão de céu) e a
integração com o sistema. Nada aqui exige rebuild de kernel ou U-Boot.

1. O QUE O ANDROID DE BASE MOSTRA (a fonte da verdade)
-----------------------------------------------------
  Dump: work/android-dump-20261025/ (vendor-config.tar, firmware/firmware.tar)

  a) NÃO existe firmware de GNSS separado. O motor de localização está DENTRO
     da imagem `modem` (MPSS). O tar do firmware traz `modem`, `modemr.jsn`,
     `modemuw.jsn` e `chre_drv_loc.so`; não há imagem tipo "gnss.mdt".
     Consequência: no Linux não há o que carregar num remoteproc dedicado —
     é preciso falar com o serviço LOC do modem.

  b) Stack de userspace do Android (HIDL/Binder, não serve no Linux):
       vendor/etc/init/android.hardware.gnss@2.1-service-qti.rc
       vendor/etc/vintf/manifest/vendor.qti.gnss@4.0-service.xml
       vendor/etc/vintf/manifest/android.hardware.gnss@2.1-service-qti.xml
       vendor/etc/izat.conf
       vendor/etc/diag_mdlog/GNSS_LT20_General.cfg (+ _QC_default)
       vendor/etc/seccomp_policy/gnss@2.0-*.policy

  c) Nada de GNSS aparece no inventário do DT do Android
     (docs/hardware/inventario-dt-android.json) — confirma que não é um device
     de plataforma (não há nó "qcom,gnss").

2. CAMINHO NO LINUX: QMI_LOC SOBRE QRTR
---------------------------------------
  Kernel já tem o necessário (work/kernel-7.3/v4/config-7.3-hanoip):
    CONFIG_GNSS=m           CONFIG_QRTR=y         CONFIG_QRTR_SMD=m
    CONFIG_QRTR_TUN=m      CONFIG_QCOM_SMEM=y    CONFIG_QCOM_QMI_HELPERS=y
  Tooling já instalado no Kali: qrtr-ns, qrtr-lookup (qrtr-tools) e
  qmicli 1.38.0 (libqmi-utils), que TEM o serviço LOC e aceita URI qrtr://.

  Estado de runtime no boot atual:
    modem (mpss)      = remoteproc1 state=running
    qrtr-ns           = active
    ModemManager      = active
    qrtr-lookup       = anuncia, entre outros:
        16 (0x10) version 2 node 0 port 127  "Location service (~ PDS v2)"

3. COMANDOS QUE FUNCIONARAM (medidos)
-------------------------------------
  qmicli -d qrtr://0 --loc-get-operation-mode
      -> "Successfully retrieved operation mode: standalone"
  qmicli -d qrtr://0 --loc-start
      -> "Successfully started location tracking (session id 0)"
  qmicli --help-all | grep loc-   mostra: --loc-start, --loc-stop,
      --loc-get-position-report, --loc-follow-position-report,
      --loc-get-gnss-sv-info, --loc-follow-gnss-sv-info, --loc-follow-nmea,
      --loc-set-nmea-types, --loc-get-nmea-types, --loc-get-engine-lock,
      --loc-set-engine-lock, --loc-inject-time/position, --loc-set-operation-mode

  Ou seja: dá para controlar o GNSS do modem com ferramenta padrão de distro,
  sem escrever código e sem firmware novo.

4. O QUE AINDA NÃO FUNCIONOU (e por quê)
----------------------------------------
  a) POSIÇÃO E SATÉLITES — timeout, sem céu:
       qmicli -d qrtr://0 --loc-get-position-report --loc-timeout=45  -> timeout
       qmicli -d qrtr://0 --loc-get-gnss-sv-info --loc-timeout=30     -> timeout
     O transporte responde na hora para "get operation mode", então o timeout
     é ausência de MEDIÇÃO (sem visão de satélite), não falha de canal.
     Coletor deixado em background para teste com o aparelho na janela:
       setsid -f sh -c "timeout 600 qmicli -d qrtr://0 \
                        --loc-follow-position-report > /tmp/loc2.log 2>&1"

  b) NMEA por sentença não configurado:
       --loc-set-nmea-types=gga,rmc,gsv,gsa
         -> "error: unknown NMEA type value given"
     O enum de tipos (QmiLocNmeaType) não está exposto no JSON do serviço nem
     nos headers instalados. NÃO é necessário para obter posição: o
     position-report devolve lat/lon/altitude direto.

  c) --loc-get-engine-lock responde "missing" (TLV opcional ausente) — não é
     erro fatal, o tracking iniciou com o mesmo cliente.

5. ARMADILHAS REGISTRADAS NESTA FRENTE
--------------------------------------
  - `pkill -f "qmicli.*qrtr"` mata a PRÓPRIA sessão SSH, porque o padrão
    aparece na linha de comando do shell remoto. Matar por PID:
      for p in $(ps -eo pid,comm --no-headers | awk '$2=="qmicli"{print $1}');
        do kill $p; done
  - O coletor precisa de setsid + timeout, senão morre junto com o SSH.
  - `--loc-get-position-report` sem `--loc-start` antes pode ficar mudo:
    iniciar a sessão é obrigatório (mensagem Start, id 0x0022, session id 0).
  - qmicli é conversador: sempre limitar com `| head` e `timeout`.

6. PRÓXIMOS PASSOS (em ordem)
-----------------------------
  1. Fix real: aparelho na janela/rua, `--loc-start` e coletar
     `--loc-follow-position-report` por 3-5 min. Critério: linha com
     latitude/longitude e/ou horizontal accuracy.
  2. Se não pegar: testar modos `--loc-set-operation-mode=msb` e `=msa`
     (assistido pela rede) e olhar dados de assistência
     (`--loc-get-predicted-orbits-data-source/validity`,
      `--loc-inject-time`, `--loc-inject-position-*`).
  3. Integração com o sistema (sem apps verem GPS hoje):
       opção A: pseudo-terminal NMEA -> gpsd (precisa habilitar NMEA, ver 4b)
       opção B: daemon que lê position-report e fala com o Geoclue por
                GeoClue2 API/D-Bus (mais trabalho, porém nativo)
     Critério de aceite: app do Phosh (ex.: Gnome Maps) mostrando posição.
  4. Persistir: serviço systemd que roda o coletor e o bridge no boot, e parar
     quando o GPS não estiver em uso (consumo).

7. RELAÇÃO COM O RESTO DO PROJETO
---------------------------------
  Depende do modem (remoteproc1) estar de pé — o mesmo que chamadas/SMS/dados.
  Não depende do ADSP/SSC (sensores), nem do Venus, nem da GPU.
  Nenhuma escrita em partição foi feita nesta frente.
