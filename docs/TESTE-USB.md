ROTEIRO DE TESTE — USB COMPLETO (modos + OTG)
=============================================
Criado 27/10/2026 19:20. Este é o documento MESTRE para testar tudo de USB.
Detalhe por modo: docs/PENDENTE-fase0-teste-usb.md
Plano/arquitetura: docs/PLANO-USB-MODOS.md
Estado do aparelho: onde paramos.md (topo)

Princípio: cada teste começa e termina com uma CAPTURA de estado, para que
"funcionou" seja afirmação com evidência, e cada teste tem um caminho de volta
que NÃO depende de reboot.


0. PRÉ-VOO (uma vez, antes de qualquer coisa)
---------------------------------------------
Canais:
  - WiFi 10.0.0.44  (canal principal; cai por power save, tente 3-5x)
  - IPv6 link-local pelo cabo: ssh -6 root@fe80::d14e:ed7a:f52e:ff8c%en10
    (quando o usb0 perde o IPv4; descobrir com: ndp -an | grep en10)
  - fastboot (só com cabo no PC e aparelho no bootloader)

Captura de linha de base (guardar a saída):
  hanoip-usb-mode status
  hanoip-usb-fix status
  cat /sys/kernel/debug/c440000.spmi:pmic@0:charger@1000 | head -20
  dmesg | tail -30
  uptime -s

Rollback pronto (nenhum é gravação em partição):
  - modo atual: hanoip-usb-mode set combo
  - serviço:    systemctl disable --now hanoip-usb-mode
                systemctl enable --now hanoip-usbnet
  - DT anterior: work/usb-20261027/ANTES-otg/u-boot-hanoip-pmos-perif-batt-OTG.img
                 (ou a par de boot do pré-GOLD)


A. MODOS GADGET (Fase 0) — SEM reboot
-------------------------------------
Ordem sugerida: charge → serial → net → combo → storage → hid → uvc.
Antes de cada um: `hanoip-usb-mode status`. Depois: repetir e comparar.

A1. charge
    aparelho: hanoip-usb-mode charge
    host    : nada novo em `lsusb`/dmesg; o cabo continua carregando
    esperado: UDC existe, gadget sem funções; carga segue
    aceite  : `gadget: hanoip bound=...` e `funcoes:` vazio

A2. serial
    aparelho: hanoip-usb-mode serial
    host    : dmesg mostra "cdc_acm" e aparece /dev/cu.usbmodem* (macOS)
    esperado: console disponível (não abrir sem necessidade)
    aceite  : tty criada; `hanoip-usb-mode status` mostra acm.usb0

A3. net
    aparelho: hanoip-usb-mode net
    host    : ifconfig en10 deve pegar 172.16.42.2 (DHCP do dnsmasq)
              ping 172.16.42.1 ; ssh root@172.16.42.1
    esperado: usb0 UP com 172.16.42.1/24, sem rota default nem DNS
    aceite  : ping e SSH funcionam; `ip route` do host NÃO ganha default

A4. combo
    aparelho: hanoip-usb-mode combo
    host    : tty + rede ao mesmo tempo
    aceite  : as duas funções simultâneas e estáveis por 2 min

A5. storage (só arquivo-imagem)
    uma vez : hanoip-usb-mode storage-init 256   (cria /var/lib/hanoip/usbstore.img)
    aparelho: hanoip-usb-mode storage
    host    : lsblk mostra um disco novo (tamanho ~256M)
              montar SÓ LEITURA e listar arquivos
    opcional: hanoip-usb-mode storage 1  -> host vê o disco como read-only
    aceite  : bloco aparece, monta, lê; NENHUMA partição do aparelho exposta

A6. hid
    aparelho: hanoip-usb-mode hid
    host    : dmesg mostra teclado HID; /dev/hidg0 existe no aparelho
    aceite  : enumera como teclado (injeção de teclas exige utilitário; NÃO
              testar digitação às cegas no host, pode digitar na janela ativa)

A7. uvc (experimental)
    aparelho: hanoip-usb-mode uvc
    host    : ls /dev/video* mostra a câmera
    aceite  : enumera. Imagem só com uvc-gadget rodando (não é escopo da Fase 0)

Em TODOS: ao final, conferir que a bateria/carga não mudou (ver seção F).


B. OTG COM PERIFÉRICO (Fase 1) — o teste de hardware
----------------------------------------------------
ESTADO NECESSÁRIO: rodando a imagem com dr_mode=otg (pré-GOLD ou
work/usb-20261027/otg/). Confirmar antes:
    tr -d '\0' < /proc/device-tree/soc@0/usb@a6f8800/usb@a600000/dr_mode  -> otg

CANAL: WiFi ou IPv6 (em modo host o UDC desaparece; o SSH por USB cai por
projeto). Ter `hanoip-usb-fix` instalado (já está).

B1. Capturar antes:
    cat /sys/class/typec/port0/power_role          -> deve ter [sink]
    cat /sys/class/usb_role/a600000.usb-role-switch/role -> device
    ls /sys/class/udc                              -> a600000.usb
    grep -l vbus /sys/class/regulator/*/name       -> achar o regulador
    cat <dir do regulador>/state                   -> disabled

B2. Plugar um PERIFÉRICO SIMPLES (pendrive USB-C, ou adaptador C->A +
    pendrive). Nada de hub com fonte neste primeiro teste.

B3. Em até ~10 s, conferir no aparelho:
    cat /sys/class/typec/port0/power_role          -> deve virar [source]
    cat /sys/class/usb_role/a600000.usb-role-switch/role -> host
    ls /sys/class/udc                              -> VAZIO (é o esperado!)
    cat <regulador vbus>/state                     -> enabled
    dmesg | tail -30                               -> xhci + "new high-speed
                                                      USB device" + sdX
    lsblk                                          -> bloco novo (sdX)
    cat /sys/class/power_supply/qcom_qg/temp       -> < 42 C (420)
    cat /sys/class/power_supply/qcom_qg/current_now -> ver o que a bateria faz

B4. Ler o pendrive COM SEGURANÇA (não escrever em mídia desconhecida):
    mkdir -p /mnt/usb && mount -o ro /dev/sdX1 /mnt/usb && ls /mnt/usb
    umount /mnt/usb
    (se o pendrive não tiver partição, ler só o começo com dd count=1 e
     hexdump — não montar)

B5. Desplugar o pendrive. Conferir a volta:
    role switch -> device ; UDC -> a600000.usb ; regulador -> disabled
    usb0 deve voltar (o serviço hanoip-usbnet religa; se não, hanoip-usb-fix fix)

B6. ABORTAR IMEDIATAMENTE se:
    - temperatura passar de 42 C
    - dmesg mostrar over-current / over-voltage / VBUS error
    - o aparelho reiniciar ou o papel ficar oscilando (source/sink repetido)
    Procedimento: tirar o periférico, `hanoip-usb-fix status`, e se preciso
    reboot com a imagem do pré-GOLD (nada é gravado).


C. HOST + CARREGANDO AO MESMO TEMPO (só com hub com fonte)
----------------------------------------------------------
Nunca testado. Requer hub USB-C com PD pass-through.
    hub: fonte no hub + hub no aparelho + pendrive no hub
Esperado: o TCPM negocia PR_SWAP e a porta fica DFP (host) com a alimentação
vindo do hub. Observar: power_role, role switch, VBUS, corrente de entrada,
temperatura. Se ficar oscilando (source/sink), INTERROMPER: o `source-pdos`
nosso tem só 5 V e o comportamento nesse cenário não foi validado.


D. PERSISTÊNCIA (sem reboot e com reboot)
-----------------------------------------
D1. sem reboot: hanoip-usb-mode set serial ; conferir modo aplicado
    depois: hanoip-usb-mode set combo (volta)
D2. com reboot (precisa do PC):
    hanoip-usb-mode set net
    systemctl disable --now hanoip-usbnet
    systemctl enable --now hanoip-usb-mode
    hanoip-reboot  -> fastboot -> fastboot boot (imagem do pré-GOLD) x2
    Depois do boot: `hanoip-usb-mode status` deve mostrar modo net aplicado
    e usb0 com 172.16.42.1 (o serviço novo aplica no boot).
D3. voltar ao padrão: set combo; disable hanoip-usb-mode; enable hanoip-usbnet


E. VIRADA DO SERVIÇO (ordem exata)
----------------------------------
    hanoip-usb-mode set combo                    # garante o modo desejado
    systemctl disable --now hanoip-usbnet
    systemctl enable --now hanoip-usb-mode
    hanoip-usb-mode status
Se o USB não voltar: systemctl disable --now hanoip-usb-mode ;
                     systemctl enable --now hanoip-usbnet


F. REGRESSÃO OBRIGATÓRIA (depois de CADA teste)
-----------------------------------------------
Bateria/carga não pode ter mudado:
    Q=/sys/class/power_supply/qcom_qg
    S=/sys/kernel/debug/c440000.spmi:pmic@0:charger@1000
    cat $Q/capacity $Q/status
    cat /sys/kernel/debug/c440000.spmi:pmic@0:charger@1000 | grep -E \
        "FLOAT_VOLTAGE|FAST_CHARGE_CURRENT|JEITA_EN|CHARGING_ENABLE|STATUS_1"
Esperado, sempre: float 0x50 (4,40 V), FCC 0x14 (1 A), JEITA 0x1b,
enable 1, FSM coerente. Qualquer mudança aqui = PARAR o teste de USB.
Também: typec deve voltar a [sink] quando há carregador, e APSD a SDP/DCP.


G. MATRIZ DE FALHAS E RECUPERAÇÃO
---------------------------------
  sintoma                          | causa provável            | o que fazer
  ---------------------------------+---------------------------+-----------------
  UDC vazio, role=device           | controlador não bindou    | hanoip-usb-fix fix
  role oscilando source/sink       | CC mal detectado / hub    | tirar periférico
  usb0 sem IPv4                    | serviço/dnsmasq           | hanoip-usb-fix fix ;
                                   |                           | ip addr add 172.16.42.1/24
  host não vê a função             | função não ligada no c.1  | hanoip-usb-mode status
  storage não aparece              | imagem inexistente        | storage-init 256
  hid sem /dev/hidg0               | função não vinculada      | status + reaplicar
  uvc enumera sem imagem           | falta uvc-gadget          | esperado
  USB morto e nada resolve         | -                         | reboot com pré-GOLD
                                   |                           | (nada é gravado)


H. TEMPLATE DE REGISTRO (preencher por teste)
---------------------------------------------
  data/hora | modo | antes (udc/role/vbus) | durante (dmesg host+aparelho)
  | temperatura | corrente | regressão F (ok?) | observações


I. CRITÉRIOS DE SAÍDA (quando promover pré-GOLD -> GOLD)
--------------------------------------------------------
  [ ] A1..A7 passam; trocar modos não deixa UDC órfão
  [ ] voltar de qualquer modo para combo restaura usb0 + console
  [ ] `set` + reboot volta no modo salvo (D2)
  [ ] B1..B5 passam: pendrive enumera, 5 V saem, volta ao normal ao remover
  [ ] nenhuma regressão de bateria em nenhum teste (F)
  [ ] app abre e aplica sem terminal
  [ ] o que falhou está escrito (falha documentada vale mais que teste omitido)

  NÃO entram no critério (escopo separado): C (hub com fonte), A7 com imagem,
  MTP/PTP (decisão pendente: só leitura? qual pasta?).
