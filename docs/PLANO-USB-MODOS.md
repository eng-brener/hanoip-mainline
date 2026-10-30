PLANO: MODOS USB DO HANOIP — REVISÃO 2 (análise de reboot)
==========================================================
Criado 27/10/2026, revisado no mesmo dia depois de verificar as dependências
uma a uma. Estado: PLANEJAMENTO. Nada foi alterado no aparelho para esta
frente. Testes ficam para o fim (seção 10).

MUDANÇA IMPORTANTE DESTA REVISÃO
  A antiga "Fase 2" (implementar o boost de VBUS) DEIXOU DE EXISTIR como
  trabalho separado. Evidência nova: o driver TCPM já liga o VBUS sozinho.
  Ver seção 6.


1. PRINCÍPIO
------------
Trocar o modo da porta pela interface, como o Android faz em "Preferências
USB". Paridade de FUNCIONALIDADE, não de implementação. Sem ADB (SSH
substitui), sem funções proprietárias Qualcomm (diag/QMI) e MTP só se houver
decisão explícita sobre leitura/escrita.


2. INVENTÁRIO VERIFICADO (com evidência, não memória)
-----------------------------------------------------
KERNEL (.config do build 187):
  CONFIG_USB_CONFIGFS=y  com F_ACM, F_ECM, F_ECM_SUBSET, F_EEM, F_NCM,
    F_RNDIS, F_MASS_STORAGE, F_HID, F_SERIAL, F_OBEX, F_FS, F_UVC=m
  CONFIG_USB_ROLE_SWITCH=y  CONFIG_USB_DWC3_DUAL_ROLE=y  CONFIG_USB_OTG=y
  CONFIG_USB_XHCI_HCD=y                  (host compilado)
  CONFIG_TYPEC_QCOM_PMIC=y               (TCPM)
  CONFIG_REGULATOR_QCOM_USB_VBUS=y       (boost de VBUS)

DRIVER DO BOOST (drivers/regulator/qcom_usb_vbus-regulator.c):
  CMD_OTG 0x40 (bit0 OTG_EN) · OTG_CURRENT_LIMIT_CFG 0x52 ·
  OTG_CFG 0x53 (bit1 OTG_EN_SRC_CFG). No probe põe OTG_EN_SRC_CFG = 0.

DT ATUAL (sm7150-motorola-hanoip.dts):
  &pm6150_vbus { regulator-min-microamp = <500000>;
                 regulator-max-microamp = <3000000>; status = "okay"; }
  &pm6150_typec { vdd-vbus-supply = <&pm6150_vbus>; status = "okay"; }
  &usb_1_dwc3  { dr_mode = "peripheral"; maximum-speed = "high-speed"; }
  &usb_1_dwc3_hs { remote-endpoint = <&pm6150_hs_in>; }   <- link já existe
  conector: power-role = "dual" (corrigido hoje), sink-pdos 5 V.

REFERÊNCIA QUE FUNCIONA (sunfish, MESMO sm7150 e MESMO pm6150):
  &usb_1_dwc3 { dr_mode = "otg"; usb-role-switch; };
  &usb_1_dwc3_hs { remote-endpoint = <&pm6150_hs_in>; };
  &pm6150_typec { vdd-vbus-supply = <&pm6150_vbus>; ... }
  Ou seja: a diferença entre o nosso DT e um OTG que funciona são DUAS LINHAS.

ANDROID (dump work/android-dump-20261025/deep/):
  /sys/class/udc/a600000.dwc3: is_otg=1, USB_UDC_DRIVER=g1 (configfs)
  /sys/class/usb_role/* vazio até no Android (lá o papel vem por extcon do SMB5)
  port otg_default: supported_modes=dual, current_mode=ufp, sink/device


3. O QUE PRECISA DE REBOOT — ANÁLISE
------------------------------------
Pergunta central: "só a Fase 1 precisa reiniciar?". Resposta verificada:

FASE 0 (userspace: ferramenta, app, gadget único, serviço)
  Precisa rebuild? NÃO. Precisa reboot? NÃO.
  Por quê: são arquivos (/usr/local/sbin/hanoip-usb-mode, app, unit systemd,
  /etc/hanoip/usb-mode.conf) e escrita em configfs, que é montado em runtime.
  Já provamos nesta sessão que dá para criar/destruir gadget e desvincular o
  UDC ao vivo (foi assim que o USB net voltou depois do replugue).
  Única ação extra: `systemctl daemon-reload` + `enable` do serviço novo.
  Efeito colateral esperado: o UDC desvincula por 1-3 s (SSH por USB pisca).

FASE 1 (DT: dr_mode = "otg" + usb-role-switch)
  Precisa rebuild? SIM — do U-Boot. Precisa reboot? SIM.
  Por quê: o DT desta placa vem EMBUTIDO no U-Boot (CONFIG_OF_EMBED); o dtb do
  boot.img do kernel não é usado. Provado na prática hoje: mudamos
  power-role no DT do U-Boot e, ao bootar a imagem nova, o kernel passou a
  enxergar o valor novo (/proc/device-tree/.../power-role = sink). O kernel
  em si NÃO precisa ser recompilado (dr_mode é só DT; DWC3_DUAL_ROLE já =y).

FASE 2 (energizar o periférico / boost de VBUS)
  Precisa rebuild? NÃO. Precisa reboot? NÃO como trabalho próprio.
  Por quê: ver seção 6 — o TCPM já faz regulator_enable() do VBUS, e o link
  vdd-vbus-supply já está no nosso DT. Essa capacidade simplesmente passa a
  funcionar quando a Fase 1 permite o papel source.

FASE 3 (MTP/PTP sobre FunctionFS)
  Precisa rebuild? NÃO (CONFIG_USB_F_FS=y). Precisa reboot? NÃO.
  É função de configfs + um daemon em userspace.

FASE 4 (persistência do modo, acabamento, UI)
  NÃO / NÃO — arquivos e serviços.

RESUMO: de cinco fases, UMA exige rebuild+reboot. E as fases que não exigem
podem ser feitas e desfeitas ao vivo, sem tocar em boot.


4. ARMADILHA QUE O PLANO ANTERIOR NÃO DESTACAVA: O DT É VOLÁTIL
--------------------------------------------------------------
O DT novo não fica "instalado" no aparelho: ele vive DENTRO da imagem de
U-Boot que bootamos. Consequências práticas:
  - se amanhã alguém bootar o U-Boot antigo (work/bateria-soc-20261027/...),
    voltam o papel Type-C errado (source) e a ausência de OTG;
  - portanto a imagem nova precisa virar a PAR DE BOOT PADRÃO, registrada com
    hash, e o comando de boot documentado deve apontar para ela;
  - e um "snapshot" desta frente tem que guardar a imagem do U-Boot, não só o
    rootfs.
Isso vale também para a correção de hoje (power-role sink), que já está nessa
mesma imagem nova: hoje o baseline de boot JÁ mudou e ainda não está
formalizado em GOLD/snapshot.


5. FASE 0 — DETALHE (continua igual, sem reboot)
-----------------------------------------------
  a) gadget único "hanoip" substituindo hanoip-console + hanoip-net
  b) /usr/local/sbin/hanoip-usb-mode <charge|net|serial|storage|hid|uvc|combo>
       storage: SOMENTE arquivo-imagem (/root/usbstore.img), nunca partição
  c) /etc/hanoip/usb-mode.conf (persistência)
  d) hanoip-usb-mode.service (aplica no boot)
  e) app GTK4/Adw "USB" na grade do Phosh
  f) desativar o serviço hanoip-usbnet antigo (evitar disputa pelo UDC)
  Aceite: trocar modo não deixa UDC órfão; host vê a função certa; reboot
  volta no modo salvo.


6. FASE 1 — AS DUAS LINHAS, E POR QUE A FASE 2 DESAPARECEU
---------------------------------------------------------
diff pretendido (espelhando sunfish):
  &usb_1_dwc3 {
        dr_mode = "otg";          /* era "peripheral" */
        usb-role-switch;
        maximum-speed = "high-speed";
  };

PROVA de que o VBUS é automático (drivers/usb/typec/tcpm/qcom/
qcom_pmic_typec_port.c):
  - pega o regulador: devm_of_regulator_get_optional(dev, CONECTOR, "vbus")
    com fallback devm_regulator_get(dev, "vdd-vbus")  -> casa com o nosso
    vdd-vbus-supply = <&pm6150_vbus>
  - qcom_pmic_typec_set_vbus(on): regulator_enable(vdd_vbus) e espera o
    estado VSafe5V no registrador TYPEC_SM_STATUS.
Ou seja: quando o TCPM decide que a porta é SOURCE, ele liga o boost, com o
limite de corrente que o DT já declara (500 mA..3 A).

Então a cadeia completa é:
  periférico plugado -> CC detecta sink (Rd) -> TCPM: power_role=source,
  data_role=host -> regulator_enable(pm6150_vbus) -> 5 V na porta
  -> DWC3 passa a host -> xHCI enumera.

VERIFICAÇÕES READ-ONLY no primeiro boot com o DT novo:
  - /proc/device-tree/soc@0/usb@a6f8800/usb@a600000/dr_mode == "otg"
  - /proc/device-tree/.../usb@a600000/usb-role-switch existe
  - /sys/class/usb_role/ aparece (antes não existia)
  - /sys/class/regulator/*/name contém o regulador do VBUS (probe OK)
  - dmesg sem erro de regulador/typec
Isso é verificação, não trabalho novo: se o regulador não probeiar, o OTG não
energiza e aí sim vira investigação.


7. FASE 3 — MTP (opcional, userspace, sem reboot)
-------------------------------------------------
f_fs já compilado. Falta servidor MTP. DECISÃO NECESSÁRIA: leitura apenas
(recomendado) e diretório dedicado (ex.: /srv/mtp). Nunca expor / nem /root
inteiro: o Kali vive no userdata.


8. FASE 4 — ACABAMENTO
----------------------
  persistência do modo (já na Fase 0), indicador de estado no app, e opcional
  integração com quick settings (extensão GNOME é frágil: só se valer o custo).


9. RISCOS
---------
  - Elétrico (Fase 1, de graça): com a porta em dual e dr_mode=otg, o aparelho
    PODE energizar 5 V na porta quando detectar um sink. O TCPM só faz isso ao
    ver Rd, mas é a única mudança desta frente que mexe em energia. Testar
    primeiro com pendrive, monitorando temperatura e corrente.
  - mass_storage em partição real: PROIBIDO (host poderia escrever e destruir
    o Kali). Só arquivo-imagem.
  - Host e gadget são excludentes: em host cai o SSH por USB (WiFi permanece).
  - Não alterar float/JEITA/FCC (decisões da frente de bateria).


10. MATRIZ DE TESTE (rodar depois, em bloco)
-------------------------------------------
  modo      | validação no host                | esperado
  ----------+----------------------------------+----------------------------
  charge    | -                                | sem UDC, só carga
  net       | ping 172.16.42.1 / SSH           | usb0 UP e DHCP
  serial    | dmesg no host                    | /dev/ttyACM* aparece
  storage   | lsblk                            | bloco novo, monta, leitura
  hid       | evtest                           | teclado/mouse funcional
  uvc       | ls /dev/video*                   | câmera aparece
  sem reboot| trocar tudo sem reiniciar       | nenhum UDC órfão
  OTG       | pendrive comum                   | bloco novo NO CELULAR,
            |                                  | 5 V na porta, T < 42 C
  retorno   | voltar a 'combo'                 | SSH por USB volta


11. ORDEM DE EXECUÇÃO (revisada)
--------------------------------
  1. Fase 0 agora — sem reboot, sem energia. Testar com o cabo no PC.
  2. UM build de U-Boot com as duas linhas da Fase 1 (+ o que mais for DT).
  3. Um `fastboot boot` e, no mesmo boot, validar: OTG com pendrive (#6) e a
     bateria continuar carregando normalmente pelo PC (não regrediu).
  4. Fase 3 (MTP) só depois de decidir read-only.
  5. Fase 4 e, por fim, formalizar a nova par de boot (U-Boot + kernel) com
     hash, em snapshot/GOLD, porque o DT agora depende dela.


---------------------------------------------------------------------
12. ESTADO EM 27/10/2026, FIM DO DIA (construido, NADA testado)
---------------------------------------------------------------------
Por decisao do usuario ("nao vamos testar nada hoje, so deixar pronto"):

FEITO (offline, sem tocar no aparelho):
  - DT alterado: &usb_1_dwc3 -> dr_mode="otg" + usb-role-switch (2 linhas,
    espelhando sunfish), com comentario explicando o mecanismo.
  - U-Boot reconstruido; imagem e dtb arquivados em work/usb-20261027/otg/
    com SHA256SUMS (img 8d777c9c..., dtb 0503d416...).
  - Imagem que ESTA RODANDO preservada em work/usb-20261027/ANTES-otg/
    (img e07ff366..., dtb 22cbe176...) — e' a unica com a correcao de
    power-role VALIDADA em uso.
  - Prova cirurgica com scripts/fdt_diff.py: 744 nos, 0 nos novos/removidos,
    1 propriedade alterada (dr_mode peripheral->otg) + 1 nova (usb-role-switch).
  - Corrigido defeito do proprio fdt_diff: valor de 4 bytes era impresso como
    inteiro ("otg" -> 1869899520); agora string terminada em NUL e' string.
  - Script de recuperacao escrito em
    work/nethunter-pro-20261026/hanoip-support/hanoip-usb-fix
    (status/fix; tolera UDC ausente quando o papel e' host). NAO instalado.
  - work/usb-20261027/LEIA-ME.txt com comandos de boot, o que conferir e as
    pendencias.

NAO FEITO NAQUELE MOMENTO (e depois concluido — ver secao 13):
  - naquele instante nenhum reboot; as 18:46 a imagem otg/ foi bootada e passou
    a ser a que roda (ANTES-otg/ fica como rollback imediato);
  - script de recuperacao continua NAO instalado;
  - Fase 0 (ferramenta + app) continua nao iniciada.

PROXIMO PASSO, QUANDO FORMOS TESTAR:
  fastboot boot work/usb-20261027/otg/u-boot-hanoip-pmos-perif-batt-OTG.img
  + kernel (inalterado), depois o checklist da secao 6 e o LEIA-ME.
  Se o UDC nao voltar ao remover o periferico: hanoip-usb-fix fix, sem reboot.


---------------------------------------------------------------------
13. TESTE **SÓ DE BOOT** COM A IMAGEM OTG (27/10 18:46-18:50) — PASSOU
---------------------------------------------------------------------
Escopo pedido pelo usuário: "dar boot nesse pra testar apenas o boot, não
vamos testar tudo do USB". Portanto: NENHUM periférico foi plugado, nenhum
teste de host/VBUS.

Sequência executada:
  hanoip-reboot -> fastboot (ZF523QJBSG)
  fastboot boot work/usb-20261027/otg/u-boot-hanoip-pmos-perif-batt-OTG.img
  fastboot boot work/nethunter-pro-20261026/artifacts/kernel-hanoip-kali-phosh-v2.img
  (kernel e módulos inalterados: dr_mode é só DT)

RESULTADOS (up 70 s a ~4 min):
  DT ............... dr_mode = "otg"; usb-role-switch presente; SEM
                     role-switch-default-mode (logo, padrão = peripheral)
  role switch ...... /sys/class/usb_role/a600000.usb-role-switch  role=device
                     <- registrou e ficou no papel seguro, exatamente o previsto
  UDC .............. a600000.usb  state=configured  speed=high-speed
  Type-C ........... power_role = source [sink]   data_role = host [device]
                     vconn_source = no
  gadget/rede ...... usb0 UP 172.16.42.1/24, SSH por USB funcionando,
                     hanoip-usbnet active (nada regrediu)
  boost de VBUS .... regulador "usb_vbus" presente, state=disabled,
                     uA=3000000   <- existe e está desligado, como deve
  carga pelo PC .... APSD=SDP, ICL 500000, enable=1, FSM=0x04,
                     +213 mA na bateria, 31,9 C  (após religar o bit opt-in)
  ADSP/sensores .... hanoip-ssc active
  dmesg ............ nenhum erro de typec/role-switch/regulador/dwc3
                     (só o aviso inofensivo "request was not queued to ep1in")

O QUE **NÃO** FOI TESTADO (de propósito)
  - periférico plugado (pendrive/teclado) e enumeração por xHCI;
  - saída de 5 V pela porta (o boost continua disabled);
  - carregador de parede com esta imagem (papel dual deveria manter DCP/1 A,
    mas não foi reconferido hoje);
  - recuperação com hanoip-usb-fix (script ainda não instalado).

ACHADO A CORRIGIR (não é regressão, é antigo): neste boot o dump de debugfs do
charger NÃO nasceu sozinho. O work de criação tenta 8 vezes a cada 5 s e
desiste; com o debugfs montado tarde, ele perde a janela. Sintoma: arquivos
/sys/kernel/debug/hanoip-* e o dump do charger ausentes até recarregar o
módulo (foi o que fiz). Correção sugerida: aumentar as tentativas (ou disparar
a criação também na primeira leitura), o que elimina o "recarregar módulo
depois de cada boot" que fazemos desde o começo.

CONCLUSÃO: o boot com dr_mode="otg" é seguro e não regrediu nada. A imagem em
work/usb-20261027/otg/ passa a ser a que está rodando; ANTES-otg/ continua
como rollback imediato.


---------------------------------------------------------------------
14. FASE 0 IMPLEMENTADA E INSTALADA (27/10 ~19:40) — NÃO ATIVADA
---------------------------------------------------------------------
Pedido do usuário: "vamos de fase 0 e anote esse plano pra testar por completo
mais tarde".

CRIADO em work/nethunter-pro-20261026/hanoip-support/:
  hanoip-usb-mode        ferramenta: charge|serial|net|combo|storage[ro]|hid|
                         uvc, mais set/save/status/storage-init/apply-saved
  hanoip-usb-mode.service  aplica MODE= do /etc/hanoip/usb-mode.conf no boot
  usb-mode.conf          padrao combo
  hanoip-usb-app.py      app GTK3/4 "Porta USB" (lista de modos + Aplicar)
  hanoip-usb-app.desktop entrada na grade do Phosh
  org.hanoip.usbmode.policy  acao polkit (allow_active=yes) para o app
  hanoip-usb-fix         status|fix (recuperacao; tolera UDC ausente)
  instalar-fase0.sh      instalador idempotente

INSTALADO no aparelho e VALIDADO apenas na leitura:
  sh -n OK, python py_compile OK, `hanoip-usb-mode status` mostrando os dois
  gadgets atuais (hanoip-net bound com acm+ncm; hanoip-console unbound).

NAO ATIVADO de proposito: hanoip-usb-mode.service segue disabled/inactive e
hanoip-usbnet segue enabled/active. A virada é um passo separado e testado:
  systemctl disable --now hanoip-usbnet && systemctl enable --now hanoip-usb-mode

Teste completo planejado em docs/PENDENTE-fase0-teste-usb.md (T1 por modo,
T2 persistencia, T3 volta ao padrao, criterios de aceite e reversao).


---------------------------------------------------------------------
15. ROTEIRO DE TESTE MESTRE (27/10 ~19:20)
---------------------------------------------------------------------
Todo o teste de USB (modos gadget, OTG com periférico, host+carregando,
persistencia, virada do servico, regressao de bateria, matriz de falhas,
template de registro e criterios para promover pre-GOLD -> GOLD) esta em
docs/TESTE-USB.md.

Resumo do que se mede no teste de OTG (o unico que ainda nao rodou):
  antes ....... role=device, UDC presente, regulador usb_vbus disabled
  durante ..... role=host, UDC VAZIO, regulador enabled, xHCI + sdX no dmesg,
                T < 42 C
  depois ...... volta a role=device, UDC presente, regulador disabled
  aborto ...... T > 42 C, erro de VBUS/over-current, papel oscilando
  recuperacao . tirar periferico; hanoip-usb-fix fix; reboot com pre-GOLD
