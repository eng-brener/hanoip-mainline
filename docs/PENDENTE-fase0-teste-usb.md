FASE 0 DOS MODOS USB — IMPLEMENTADA E INSTALADA, **NÃO ATIVADA**
=================================================================
27/10/2026, ~19:40. Para testar depois, em bloco. Nada foi ativado: o
hanoip-usbnet segue no comando da porta e o modo atual (combo) não mudou.


1. O QUE FOI CRIADO (em work/nethunter-pro-20261026/hanoip-support/)
--------------------------------------------------------------------
  hanoip-usb-mode          ferramenta (POSIX sh). É o coração da Fase 0.
  hanoip-usb-mode.service  aplica o modo salvo no boot
  usb-mode.conf            /etc/hanoip/usb-mode.conf (MODE=combo)
  hanoip-usb-app.py        app GTK (3/4) "Porta USB" para o Phosh
  hanoip-usb-app.desktop   entrada na grade de aplicativos
  org.hanoip.usbmode.policy  ação polkit org.hanoip.usbmode.set
  hanoip-usb-fix           inspeção/recuperação (status|fix)
  instalar-fase0.sh        instalador idempotente

INSTALADO NO APARELHO (verificado): todos os arquivos acima em
/usr/local/sbin, /usr/local/bin, /usr/share/applications,
/usr/share/polkit-1/actions, /etc/systemd/system, /etc/hanoip.
NÃO ativado: hanoip-usb-mode.service continua `disabled/inactive` e
hanoip-usbnet continua `enabled/active`.

Modos disponíveis na ferramenta:
  charge | serial | net | combo | storage [ro] | hid | uvc
  set <modo>      aplica E salva (é o que o app usa)
  save <modo>     só salva para o próximo boot
  status          leitura (seguro, não muda nada)
  storage-init MB cria a imagem /var/lib/hanoip/usbstore.img


2. ESTADO ATUAL (leitura real, 27/10 19:40)
-------------------------------------------
  modo configurado : combo
  Type-C           : source [sink] / host [device]
  UDC              : a600000.usb state=configured speed=high-speed
  gadget           : hanoip nao criado (modo ainda nao aplicado)
  outro gadget     : hanoip-console (unbound, acm)   <- resto do initramfs
  outro gadget     : hanoip-net     (bound, acm+ncm) <- o que roda hoje
  usb0             : UP (só link-local; o IPv4 some às vezes)
  boost de VBUS    : disabled


3. PROTOCOLO DE TESTE (ordem sugerida, tudo reversível)
-------------------------------------------------------
PRÉ-REQUISITOS
  - cabo no PC (para ver as funções do lado do host) e WiFi funcionando
    (porque trocar de modo derruba o USB por 1-3 s);
  - antes de começar: `hanoip-usb-mode status` e guardar a saída;
  - ter `hanoip-usb-fix status` à mão.

T0. NÃO FAZER AINDA: manter hanoip-usbnet ativo enquanto testa a ferramenta
    com o gadget "hanoip" criado por ela. O conflito é esperado e a própria
    ferramenta desvincula o UDC dos outros gadgets ao aplicar um modo.

T1. Cada modo, um por vez, com o cabo no PC:
      hanoip-usb-mode net        -> usb0 UP + 172.16.42.1/24 + dnsmasq
                                    no host: ping 172.16.42.1, SSH
      hanoip-usb-mode serial     -> host: dmesg mostra /dev/ttyACM*
      hanoip-usb-mode storage    -> host: lsblk mostra um disco novo
                                    (precisa antes: hanoip-usb-mode
                                     storage-init 256)
      hanoip-usb-mode hid        -> host: dmesg mostra teclado HID;
                                    no aparelho existe /dev/hidg0
      hanoip-usb-mode uvc        -> host: ls /dev/video* (precisa de
                                    uvc-gadget rodando; senão só enumera)
      hanoip-usb-mode charge     -> host: nada aparece; UDC continua existindo
                                    mas sem funções
      hanoip-usb-mode combo      -> usb0 + /dev/ttyACM* ao mesmo tempo
    Em cada um: anotar dmesg dos DOIS lados e `hanoip-usb-mode status`.

T2. PERSISTÊNCIA
      hanoip-usb-mode set serial
      systemctl disable --now hanoip-usbnet
      systemctl enable --now hanoip-usb-mode
      -> depois de um reboot, o modo deve ser serial (conf do /etc/hanoip).

T3. VOLTA AO PADRÃO
      hanoip-usb-mode set combo
      systemctl disable --now hanoip-usb-mode
      systemctl enable --now hanoip-usbnet


4. COMO REVERTER TUDO (se algo sair errado)
-------------------------------------------
  systemctl disable --now hanoip-usb-mode
  systemctl enable --now hanoip-usbnet
  rm -f /etc/hanoip/usb-mode.conf          (opcional: volta ao padrao de boot)
  # o gadget "hanoip" pode ficar criado e desvinculado; não atrapalha, mas
  # se quiser limpar:  hanoip-usb-fix fix   (ou desvincular a mao)
  Se o USB sumir de vez: hanoip-usb-fix status; hanoip-usb-fix fix; e, no
  pior caso, reboot volatil com a mesma imagem (nada é gravado em partição).


5. LIMITES CONHECIDOS (não são bugs, são escopo)
------------------------------------------------
  - uvc: monta a função, mas sem um app que alimente o stream o host vê a
    câmera e não recebe imagem. Precisa de uvc-gadget (Fase 3+).
  - hid: monta o teclado e cria /dev/hidg0; injetar teclas exige um
    utilitário (estilo ducky). A função USB em si é o que a Fase 0 entrega.
  - storage: SOMENTE arquivo-imagem. Exportar partição real é proibido
    (o host poderia escrever e destruir o Kali em userdata).
  - o app usa pkexec + política polkit com allow_active=yes. Se o polkit do
    sistema for elogind (é o nosso caso), a ação aparece como
    org.hanoip.usbmode.set. Sem pkexec, o app instrui o comando de terminal.
  - trocar de modo derruba o USB por 1-3 s: com SSH USB cai e volta; por
    WiFi nada acontece.
  - em modo host (UDC ausente), a ferramenta avisa e não tenta religar nada.


6. CRITÉRIOS DE ACEITE DA FASE 0
--------------------------------
  [ ] cada modo aplica sem deixar UDC órfão (status mostra 1 gadget bound)
  [ ] voltar de qualquer modo para combo restaura usb0 + console
  [ ] `set` + reboot volta no modo salvo
  [ ] app abre, mostra o estado e aplica sem terminal
  [ ] nenhum modo toca em charger/VBUS/float/JEITA (conferir dump do charger
      antes/depois: FSM, float 0x50, FCC 0x14, JEITA 0x1b inalterados)


7. DEPOIS DA FASE 0
-------------------
  - Fase 1 (OTG) já está pronta: falta só plugar periférico (pendrive).
  - MTP/PTP (Fase 3) continua dependendo de decisão: só leitura? qual pasta?
