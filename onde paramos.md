# Handoff — Moto G60 hanoip mainline

## SESSÃO 27/10/2026 (noite) — CONSOLIDADO DE TUDO — LEIA ISTO PRIMEIRO

### 0. ESTADO DO APARELHO AGORA (27/10 19:15)
    cap 100% / status Full / i_bateria 0 mA / 31,2 C
    entrada: VBUS 5,10 V, 281 mA, ICL 500 mA (SDP = porta de PC)
    FSM 0x45 (terminado), CHARGING_ENABLE=1, float 0x70=0x50 (4,40 V)
    enumeração USB: portátil ligado ao PC; usb0 UP (sem IPv4 no momento)
    Acesso: WiFi 10.0.0.44 (cai por power save às vezes) ou IPv6 link-local
    em en10 (ssh -6 root@fe80::d14e:ed7a:f52e:ff8c%en10).
    Rollback de DT: work/usb-20261027/ANTES-otg/ (img e07ff366...).

### 1. REGRA DE ARQUITETURA (a que mais custou e a que mais engana)
    O DT efetivo vem EMBUTIDO NO U-BOOT (CONFIG_OF_EMBED); o dtb do boot.img
    do kernel NÃO é usado. Mudar DT = rebuild do U-Boot + `fastboot boot`.
    O DT é VOLÁTIL: vive na imagem bootada. Bootar um U-Boot antigo reverte
    silenciosamente (foi assim que o carregador de parede "voltaria a quebrar").
    Registrado também em AGENTS.md, com as consequências práticas.

### 2. BATERIA / SOC — 4 bugs corrigidos hoje, cada um com medição
    a) 0182 — o viés do OCV MUDA DE SINAL conforme a fase: +7 pts em CC a
       440 mA (polarização) e -8 pts em taper a 360 mA (subtração de IR com
       pouca polarização). Regra: carregando = SÓ Coulomb; em repouso = OCV.
    b) 0183 — dois bugs na contagem de Coulomb:
       - RETIFICAÇÃO: contava só amostras positivas de um ADC ruidoso; com a
         corrente real em torno de -44 mA, inventava carga. Agora filtra a
         corrente COM SINAL (EMA 8) e só conta acima de +50 mA.
       - DIVISOR DE 32 BITS: div_s64 tem divisor s32 e o divisor real
         (3600 x capacidade = 1,78e10) era truncado para 6,0e8 -> contava 27x.
         Agora div64_s64. Conferido contra a física: 0,85 vs 0,855 mili-%/s.
    c) 0184 — OCV só em REPOUSO de verdade: |i| < 120 mA por 30 s. Um único
       sample de -660 mA (Wi-Fi acordando) somava +132 mV com os 200 mOhm e
       lia 97% num pack a 92%. E o slew liberava até 1 ponto por leitura, mas
       acumulava degraus (92 -> 97 de uma vez). Agora no máximo 1 por leitura.
    d) Resistência interna do DT: 30 -> 200 mOhm (duas derivações
       independentes: dado do Android a 54%/500 mA e medição em campo).
       Em repouso, 4,3385 V passou de 94% para 91% (curva: 91,3%).
    Curva OCV real extraída do perfil Motorola do Android
    (S88731AA1-mc50-ATL-4V45-6000mah): 4446 mV = 100% ... 3400 mV = 0%.

### 3. CARREGADOR DE PAREDE (100 W) — não funcionava por causa do DT
    Sintoma: plugado, nada (ONLINE=0, APSD_STATUS=0x00). No PC carregava.
    Causa: o conector Type-C do DT dizia power-role = "source" (herdado do
    port de referência do Xiaomi). Existe TCPM real no kernel e ele
    registrava a porta como FONTE PD (Rp + VCONN); carregador USB-C só liga
    o VBUS ao ver um sink (Rd). O carregador estava certo, o aparelho errado.
    Tentativa errada: power-role="sink" -> TCPM falha no probe com -EINVAL
    (sink sem sink-pdos). Correção final (padrão do upstream):
       power-role = "dual"; data-role = "dual";
       op-sink-microwatt = <5000000>;   /* 5 W = 5 V * 1 A, nosso teto */
       sink-pdos = PDO_FIXED(5000, 3000, ...)   /* SÓ 5 V, de propósito */
    Prova por binário (scripts/fdt_diff.py, DT extraído do u-boot antigo que
    estava em gzip dentro do .img): 744 nós, 1 propriedade alterada + 1 nova.
    Resultado: APSD=DCP, typec [sink], vconn=no, carga de 1 A.
    Bônus (hipótese, não prova): com o carregador de parede a tela NÃO acendeu
    sozinha nenhuma vez na sonda, o que é consistente com o TCPM-fonte sendo a
    causa dos acendimentos no PC. Falta uma sessão longa plugado no PC.

### 4. NEGOCIAÇÃO DE ENTRADA (APSD/ICL) — 0185 e 0186
    0185: o driver negociava no instante do plugue, antes de o APSD terminar,
    caía no padrão SDP (500 mA, reg 0x370 = 0x0a) e NUNCA re-negociava —
    o APSD completava como DCP e o limite ficava no valor de SDP (a leitura
    mostrava 550 mA por causa do decode errado corrigido no 0186). Agora o worker de 10 s compara o tipo e re-negocia; e há um
    passe extra 2,5 s após ligar a carga.
    PROVA EM REPLOGUE REAL (dmesg, boot de 18:46):
      [137s] fonte desconhecido -> 500000 uA     <- o bug acontecendo
      [147s] APSD agora diz DCP -> 1000000 uA    <- a correção agindo
      [270s] APSD agora diz SDP -> 500000 uA     <- e descendo quando o cabo
                                                    voltou para o PC
    0186: CURRENT_MAX lia o campo de STATUS_2, que no SMB5 é uma TABELA
    codificada, e multiplicava por 50 mA -> mostrava 600 mA com 1 A real.
    Agora lê USBIN_CURRENT_LIMIT_CFG (o valor comandado): 1000000 = 0x14.

### 5. TERMINAÇÃO OBSERVADA E O QUE "100%" SIGNIFICA
    Primeira vez: status Full, 0 mA na bateria, FSM 0x45, 100% no display.
    MAS a verificação física diz 94,4% — por DOIS métodos independentes:
      curva OCV em 4,381 V de repouso -> 94,4%
      Coulomb: 91,5% (4,342 V) + 145 mAh de 4939 -> 94,4%
    Causa: o ABL deixa float = 4,400 V (reg 0x70 = 0x50) e a curva Motorola
    só dá 100% em 4,4465 V. O Android usa qcom,fv-max-uv = 4,450 V com
    iterm 290 mA (dump do DT do charger).
    DECISÃO (27/10, usuário): MANTER 4,40 V. A célula é velha (4939 mAh
    aprendidos contra 6174 de projeto). O 100% vale como "o charger terminou,
    pode tirar da tomada": trava em 99% enquanto carrega, vira 100% só em
    Full, e volta ao valor real (~94-96%) quando desconecta.
    Gravado no código no patch 0187 para ninguém "consertar" depois.

### 6. USB / OTG — DT pronto, boot validado, periférico pendente
    DT: &usb_1_dwc3 { dr_mode = "otg"; usb-role-switch; } (era "peripheral"),
    espelhando o sunfish (mesmo sm7150, mesmo pm6150). Sem
    role-switch-default-mode -> padrão peripheral (protege o gadget/SSH USB).
    O VBUS de OTG já é automático: qcom_pmic_typec_port.c faz
    regulator_enable(vdd_vbus) quando o papel vira source, e o nosso DT já
    tem vdd-vbus-supply = <&pm6150_vbus> (500 mA..3 A).
    TESTE SÓ DE BOOT (18:46) — PASSOU:
      dr_mode=otg, usb-role-switch presente, /sys/class/usb_role/
      a600000.usb-role-switch role=device, UDC a600000.usb configured,
      typec source[sink] vconn=no, usb0+SSH por USB OK, regulador usb_vbus
      presente e DISABLED (3 A), carga pelo PC SDP/500 mA/+213 mA, sem erro.
    NÃO TESTADO: periférico plugado (xHCI nunca enumerou), 5 V na porta,
    host+carregando ao mesmo tempo, MTP.

### 7. FASE 0 DOS MODOS USB — IMPLEMENTADA E INSTALADA, NÃO ATIVADA
    Em work/nethunter-pro-20261026/hanoip-support/ e instalado no aparelho:
      hanoip-usb-mode (charge|serial|net|combo|storage[ro]|hid|uvc, mais
      set/save/status/storage-init/apply-saved), hanoip-usb-mode.service,
      /etc/hanoip/usb-mode.conf, hanoip-usb-app.py (GTK, app "Porta USB"),
      .desktop, política polkit org.hanoip.usbmode.set, hanoip-usb-fix
      (status|fix) e instalar-fase0.sh.
    Validado só na LEITURA: sh -n, py_compile e `hanoip-usb-mode status`
    (mostra hanoip-net bound com acm+ncm e hanoip-console unbound).
    NÃO ativado: hanoip-usbnet segue enabled/active e hanoip-usb-mode
    disabled/inactive. A virada é um passo separado:
      systemctl disable --now hanoip-usbnet && systemctl enable --now hanoip-usb-mode
    Protocolo de teste completo: docs/PENDENTE-fase0-teste-usb.md.

### 8. ARTEFATOS E HASHES
    pré-GOLD (somente leitura, referência nova):
      work/PRE-GOLD-20261027-1852/  uboot/ kernel/ dt/ patches/ scripts/
        uboot img 8d777c9c...  uboot.dtb 0503d416...  dtb fonte 3504e9cb...
        kernel-hanoip-kali-phosh-v2.img 3b761454...  Image.gz 27248020...
        modules-7.3.0-sm7150.tar.gz 57c79a20...  patches 187 = 5d2bab38...
    rollback: work/usb-20261027/ANTES-otg/ (img e07ff366..., só power-role)
    cópia avulsa dos módulos críticos: work/bateria-soc-20261027/modulos-187/
      (qcom_qg 0e104aaa..., qcom_smbx 29f507fa..., qcom-spmi-adc5); o aparelho
      foi conferido byte a byte contra esses hashes.

### 9. DOCUMENTOS CRIADOS/ATUALIZADOS HOJE
    AGENTS.md .................................. regra "DT vem do U-Boot"
    onde paramos.md ............................ este consolidado + pré-GOLD
    docs/PENDENCIAS.md ......................... lista única de tudo que falta
    docs/PLANO-USB-MODOS.md .................... plano USB (seções 1-14)
    docs/PENDENTE-fase0-teste-usb.md ........... protocolo de teste da Fase 0
    docs/kernel/checkpoint-2026-10-27-bateria-RESUMO.txt .. seções 17-27
    docs/kernel/PENDENTE-recarga-e-AICL-20261027.txt ...... recarga e AICL
    work/kernel-7.3/v4/README.txt .............. índice 0168-0187
    work/usb-20261027/LEIA-ME.txt .............. pacote OTG (boot e checklist)
    work/PRE-GOLD-20261027-1852/PRE-GOLD.txt ... 9 seções, hashes, decisões

### 10. TESTES FEITOS HOJE (todos no aparelho)
    - carga PC (SDP) 500 mA: +440 a +213 mA, 31-34 C, sem erro
    - carga PAREDE (DCP 100 W): 1 A, APSD=DCP, reconciliação automática
    - terminação real: Full, 0 mA, FSM 0x45, 100% no display (2x)
    - verificação do 100%: 94,4% por curva E por Coulomb
    - Coulomb contra a física: erro < 2%
    - boot com DT OTG: role switch em device, UDC ok, reg. VBUS disabled
    - 187 patches compilam (build rc=0); qcom_qg do build 187:
      comprimido 0e104aaa..., descomprimido 65a50ec8...
    - fdt_diff: 1 propriedade alterada (power-role) e depois (dr_mode)

### 11. NÃO TESTADO / BLOQUEADO
    recarga após terminação e AICL (exigem fonte fraca + tela ligada),
    OTG com periférico, host+carregando, MTP, Fase 0 ativada, suspend com
    carga, tela acendendo no PC (sessão longa), rotação de tela.

### 12. QUIRKS APRENDIDOS (não são bugs, mas enganam)
    - debugfs do charger (hanoip-charge/hanoip-icl/dump) NÃO nasce no boot:
      o work tenta 8x a cada 5 s e desiste. Solução atual: recarregar
      qcom_smbx. Correção pendente (A5 em PENDENCIAS.md).
    - `echo 1 > /sys/kernel/debug/hanoip-charge` dá EACCES (O_TRUNC);
      use  printf '1\n' | dd of=... bs=2 count=1
    - hash de .ko muda entre builds sem mudar código (build-id do linker):
      provar com objdump/cmp, não com sha256. (Aconteceu com o 0187.)
    - fdt_diff imprimia valor de 4 bytes como inteiro ("otg" -> 1869899520);
      corrigido para tratar string terminada em NUL.
    - WiFi do WCN3990 cai por power save; usb0 às vezes perde o IPv4.
      Alternativas: IPv6 link-local em en10, ou religar o serviço usbnet.

### 13. PRÓXIMOS PASSOS IMEDIATOS
    ROTEIRO COMPLETO DE TESTE DE USB: docs/TESTE-USB.md (A modos gadget,
    B OTG com periférico, C host+carregando, D persistência, E virada do
    serviço, F regressão de bateria, G falhas, H registro, I critérios de
    saída). Detalhe por modo: docs/PENDENTE-fase0-teste-usb.md.
    1. testar a Fase 0 (seção A do roteiro) e fazer a virada (seção E)
    2. seção B: plugar um pendrive e validar OTG (hanoip-usb-fix já instalado)
    3. A3 (carga ligar no boot) e A5 (debugfs) — dois patches pequenos
    4. A1+A2 (recarga e AICL) num único momento com o cabo no PC
    Lista completa e ordenada: docs/PENDENCIAS.md

### 14. APP "PORTA USB" REDESENHADO (27/10 ~19:25)
    A primeira versão era feia e frágil: janela GTK "crua", sem cara de app de
    celular, e com bug de ciclo de vida (abria e fechava sozinho).
    Corrigido:
      - CAUSA DO "ABRE E FECHA": a janela era criada sem referência e sem ser
        filha do Gtk.Application (`lambda a: Janela().present()`); o app ficava
        sem janelas e encerrava. Agora App(Adw.Application) guarda self.win e a
        janela nasce com application=app.
      - STATUS SEMPRE SAI 0: `hanoip-usb-mode status` retornava 1 (a última
        linha do script falhava quando /run/hanoip-usb-mode.state não existia)
        e o app lia como erro. Corrigido também no hanoip-usb-fix.
      - UI refeita em GTK4 + libadwaita 1.9 (existe no sistema, verificado):
        cartão grande com o modo ATUAL (ícone + nome + resumo + selo), lista de
        modos com ícone e uma linha de explicação, toque único troca, toast com
        DESFAZER, banner avisando da queda de 1-3 s e o estado técnico dentro de
        um ExpanderRow fechado.
      - pkexec roda em thread (não congela a UI); erro abre AlertDialog com
        "Copiar" e tudo vai para ~/.cache/hanoip-usb-app.log.
    Limite: NÃO há ferramenta de captura no aparelho (grim/gnome-screenshot
    ausentes), então a aparência foi validada por processo (roda, não erra, lê
    estado), não por inspeção visual.

### 18. GPU (Adreno 618) — FRENTE FECHADA 28/10
    Varredura completa item por item: docs/kernel/LEVANTAMENTO-GPU.md
    (hardware, DT, kernel, runtime, userspace, energia).
    FUNCIONA E PERFORMA (medido, não suposto):
      revision 618 (0x06010800); gpu-initialized: 1 (ZAP rodou)
      OpenGL 4.6 Core E Compatibility, vendor freedreno, renderer FD618
      OpenGL ES 3.2 (mesa 26.1.6); 1331 extensões
      Vulkan 1.3.354 Turnip "Adreno (TM) 618", driverID MESA_TURNIP
      peglgears: 40.868 FPS (~45 mil em outra amostra = ruído de CPU)
      vkgears na sessão Phosh: 60,0 FPS estáveis (vsync)
      90 s de carga contínua: 800 MHz até o fim, 54,5 C, cooling 0/6
      DVFS 180..800 MHz (simple_ondemand, poll 16 ms); trips 95/110 C
      speed bin 3 -> 800 MHz é o teto real do silício; 825/700/610 filtrados
    ENERGIA — CICLO PROVADO (correção de duas conclusões minhas erradas):
      cx_gdsc e gx_gdsc (gpucc) EXISTEM e DESLIGAM:
        ocioso: cx=off-0 gx=off-0 gpu_cc_cx_gmu_clk enable=0
        sob carga: cx=on gx=on 800 MHz; 4 s após parar volta a off-0
      A medição que dizia "ficam sempre on" foi feita logo depois da carga
      (active_time ~204 s) — artefato de amostragem. A GMU é o consumidor
      dos dois GDSC, por isso o nó da GPU não precisa de power-domains.
    NÃO são defeitos: "supply vdd/vddcx dummy" (caminho legado a3xx-a5xx;
    no a618 a tensão é votada pela GMU), falta de clock "core" no nó da GPU
    (idem), e "sync_state() pending due to 506a000.gmu" (informativo).
    TESTES DE FECHAMENTO (28/10, todos documentados na seção 11):
      suspend/resume: peglgears 46.391 -> 44.926 FPS, FD618 e Turnip
        revalidados, GDSC off, 0 erros, suspend_stats.success=1
      Firefox (WebRender/WebGL) usa a GPU: GL_RENDERER "FD618", 800 MHz
        sustentado, 415 transições de OPP, 55 C; phoc com 5 fds em renderD128
      piso dinâmico: novo hanoip-gpu-idle-floor.service -> 355 MHz com a tela
        ligada, 180 MHz apagada (validado nos dois sentidos + teste de deriva)
      recovery: NÃO exercitado de propósito (exigiria command stream inválido;
        o hangcheck está armado em 250 ms e não acusa com carga normal)
    Menores: o spam "disallowed SPMI write to 0x6046" (RTC, não GPU — remover
    allow-set-time do DT).
### 17. CPU 100% — FRENTE FECHADA (28/10 ~10:00)
    Levantamento completo (docs/kernel/LEVANTAMENTO-CPU-100.md, seções 7-8):
      boot 16,1 s (era 3min19s; Plymouth mascarado)
      8 núcleos · schedutil 300..1805/300..2304 · EAS ativo com energy model
      OPP completos (10/13) e voto de banda escalando 9,6 -> 46,7 GB/s
      idle psci_idle + TEO (adicionado ao kernel nesta sessão) + cluster S1
      térmica: 10 min de 8 núcleos, pico 71,9/74,8/76,4 C, ZERO throttling
      suspend: s2idle com hook do ADSP, soak de 3 ciclos sem crash
      RTC: 19.066 dias atrasado -> corrigido por offset em userspace
      DSI: 0 erros de FIFO neste boot · systemd: 0 falhas
    Causa raiz do RTC (kretprobe + dmesg): o ÁRBITRO SPMI do PMIC nega escrita
    ("disallowed SPMI write to 0x6046", ACL por APID: write_ee != nosso EE).
    Não é software: driver nunca poderá escrever o RTC. Offset em userspace
    (/etc/hanoip/rtc-offset + hanoip-rtc.service) resolve.
    TEO: CONFIG_CPU_IDLE_GOV_TEO=y no config-7.3-hanoip; kernel recompilado e
    bootado como kernel-hanoip-kali-phosh-v3-teo.img (60b54914...).
    Novos artefatos em hanoip-support/: hanoip-adsp (sleep hook), hanoip-rtc,
    rtc-set, teste-termico, hanoip-cpu-tune (+service, persiste idle=teo e
    thermal=power_allocator no boot). Log térmico em work/cpu-20261028/.
    FECHAMENTO FINAL: PMU renomeado para armv8_cortex_a76 (era a78; fdt_diff
    provou 1 propriedade), linux-perf 7.1.5 instalado e testado (1,16 G ciclos
    em 0,5 s), perf_event_paranoid=1, boot em 14,7 s, 0 falhas systemd.

### 16. SUSPEND, RTC E BOOT DE 3 MIN (28/10) — detalhe em
    work/cpu-20261028/SUSPEND-RTC-BOOT.md e docs/kernel/LEVANTAMENTO-CPU-100.md
    (G5, G6, G6b).
    SUSPEND: o kernel só tem s2idle (mem_sleep=[s2idle]; sem deep). Três testes:
      (1) rtcwake direto -> 1,04 s e ADSP morre (não roda hooks do systemd);
      (2) systemctl suspend com hook só de FastRPC -> 30 s, ADSP morre igual
          (hipótese desmentida);
      (3) hook desligando o REMOTEPROC (echo stop) -> 31 s de suspend real,
          ADSP volta running, 0 crashes, usb0 com IPv4 restaurado.
      Hook: /usr/lib/systemd/system-sleep/hanoip-adsp (fonte em
      hanoip-support/). Falta soak de 3-4 ciclos.
    RTC: estava 19.066 dias atrasado (1974). Causa: offset nvmem ausente no DT;
    e set_time dava -ENODEV. Com "allow-set-time" no DT o ioctl passou a chegar
    mas falha com ERANGE (vem do SPMI, não do regmap) — correção de kernel
    pendente. Solução efetiva por userspace: /etc/hanoip/rtc-offset
    (1647376775 s) + hanoip-rtc.service aplicando raw+offset no boot; testado
    (relógio forçado a 1974 -> acertou para 2026).
    BOOT DE 3 MIN: era o Plymouth (plymouth-start 186 s, "start-post operation
    timed out"). O splash não desenha no DSI e o systemd espera ~3 min; a tela
    fica no texto do initramfs (parecia travamento). Mascarado; esperado ~15 s.

### 15. KALI NETHUNTER PRO: PESQUISA DOS APPS PADRÃO (27/10 ~19:40)
    Fonte autoritativa: gitlab.com/kalilinux/nethunter/build-scripts/
    kali-nethunter-pro (a página kali.org/docs/nethunter-pro/ só ensina a
    instalar). Receita em 3 camadas: include/packages-base.yaml,
    include/packages-phosh.yaml e devices/qcom/packages-{base,phosh}.yaml.

    PRESENTES aqui: kali-linux-core, kali-themes-mobile, mobian-base,
    openssh-server, vim, firefox-esr, gnome-sound-recorder, loupe,
    mobian-phosh, powersupply-gtk, squeekboard,
    webext-ublock-origin-firefox, gnome-snapshot.

    FALTAM (instaláveis): firefox-esr-mobile-config (1 pkg),
    mobian-phosh-phone (13 pkgs, é o metapacote dos apps de telefone),
    gstreamer1.0-plugins-base-apps, yq, systemd-repart (inútil aqui: a camada
    qcom apaga /etc/repart.d).

    NOMES MORTOS: "nethunter" não existe mais. Sobrou kali-nethunter-core
    (INSTALADO), nethunter-utils (INSTALADO), kali-nethunter-nano/-full (628
    pacotes o full) e kali-linux-nethunter (transicional). São "rootfs
    packages" do modelo CHROOT do NetHunter clássico; no Pro não existe Android
    nem chroot, logo NÃO há app NetHunter separado — as ferramentas são CLI.
    "hijacker" e "kalitorify" também saíram do Kali (kali.org/tools -> 404,
    pkg.kali.org -> not found).

    INSTALADOS nesta sessão, a pedido: gstreamer1.0-plugins-base-apps 1.28.8-1
    (traz gstreamer1.0-tools) e yq 3.4.3-3 (traz python3-yaml/xmltodict).
    Verificado: gst-inspect-1.0 lista 1414 elementos, gst-launch-1.0 presente,
    yq devolve 42 no teste. Rootfs segue com 3,8 G livres.

    ACHADO IMPORTANTE: não há NENHUMA ferramenta de pentest instalada (nem
    nmap; só netcat-traditional e tcpdump). A receita oficial também não traz
    tools — instala só kali-linux-core. NetHunter Pro é "Kali puro".
    Para menu de ferramentas na grade do Phosh existe kali-menu (candidato
    2026.3.4); sem tools instaladas não há o que listar.

    EM ABERTO: instalar firefox-esr-mobile-config e mobian-phosh-phone?
    Instalar kali-menu + conjunto escolhido de ferramentas? Ou
    kali-nethunter-nano/full?

## LISTA ÚNICA DE PENDÊNCIAS: docs/PENDENCIAS.md (27/10 19:10)

Consolidado de todas as frentes, com o que cada item precisa (PC, rebuild,
hardware externo, decisão do usuário) e ordem recomendada. Resumo: bateria
tem 2 itens bloqueados por hardware (recarga e AICL, precisam de porta fraca)
e 4 acionáveis; USB tem o OTG pronto mas não testado com periférico, e a
ferramenta/app de troca de modo (Fase 0) ainda não existe; sensores aguardam
mount matrix; câmera/digital/áudio seguem pausados/parados.

## PRÉ-GOLD 27/10/2026 18:52 — NOVA REFERÊNCIA (kernel + DT + U-Boot)

work/PRE-GOLD-20261027-1852/ (somente leitura, PRE-GOLD.txt + SHA256SUMS).
É o primeiro estado em que bateria corrigida, carregador de PAREDE funcionando,
terminação observada e OTG habilitado coexistem. Par de boot:
  fastboot boot uboot/u-boot-hanoip-pmos-perif-batt-OTG.img   (8d777c9c...)
  fastboot boot kernel/kernel-hanoip-kali-phosh-v2.img        (3b761454...)
  módulos:  kernel/modules-7.3.0-sm7150.tar.gz                (57c79a20...)
  DT fonte: dt/sm7150-motorola-hanoip.dts                     (3504e9cb...)
  patches:  patches/ = 187, conjunto 5d2bab38...
  módulos:  os 859 .ko estão DENTRO do tarball acima; cópia avulsa dos três
            críticos em work/bateria-soc-20261027/modulos-187/
            (qcom_qg 0e104aaa..., qcom_smbx 29f507fa..., qcom-spmi-adc5)
            e o aparelho foi conferido byte a byte contra esses hashes.

Contém: curva OCV real + IR 200 mOhm; Coulomb com filtro e div64_s64; OCV só
em repouso e 1 ponto por leitura; trava em 99% e 100% = "pode tirar da tomada"
(float 4,40 V mantido, decisão registrada); Type-C dual/sink-pdos 5 V; DCP com
1 A reconciliado sozinho; dr_mode=otg + usb-role-switch com padrão peripheral.

NÃO validado (não tratar como pronto): OTG com periférico (xHCI nunca
enumerou, 5 V nunca saíram), recarga automática, AICL, MTP, ferramenta/app de
modos USB (Fase 0), suspend com carga. Rollback: work/usb-20261027/ANTES-otg/
(só power-role sink, e07ff366...). Plano e pendências:
docs/PLANO-USB-MODOS.md, docs/kernel/PENDENTE-recarga-e-AICL-20261027.txt.

## [HISTÓRICO — manhã/tarde de 27/10] BATERIA — SOC corrigido, CARGA FUNCIONANDO

> Esta seção é HISTÓRICA. O estado atual está no CONSOLIDADO acima.
> Aqui o aparelho estava em ~86%, com a carga desligada e sem o
> carregador de parede funcionando. Leia o topo do arquivo primeiro.

LEIA PRIMEIRO: docs/kernel/checkpoint-2026-10-27-bateria-RESUMO.txt (tudo o
que descobrimos, em um documento) e work/bateria-soc-20261027/ (artefatos).

ESTADO NA PAUSA (27/10/2026, fim do dia — retomamos depois):
  - carga DESLIGADA a pedido do usuário (enable=0x00, FSM DISABLE_CHARGE,
    i_batt=0, dmesg "charging disabled"). Modo manual até observarmos a
    terminação.
  - aparelho DESPLUGADO pelo usuário no fim da sessão: sem USB, logo sem a
    rede USB 172.16.42.1. Para retomar, precisa replugar o cabo (ou usar
    wlan0 10.0.0.44, se estiver na mesma rede).
  - última leitura conhecida: ~86% (ver explicação do salto abaixo),
    ~33 C, descarregando devagar.
  - nada pendente de escrita: nenhum experimento ficou pela metade.

POR QUE A PORCENTAGEM SAIU DE 79% PARA 86% (não é regressão):
  Eu recarreguei o módulo do qcom_qg para instalar o patch 0170. Ao carregar,
  o driver INICIALIZA o valor suavizado a partir da estimativa bruta daquele
  instante — e naquele momento a bateria tinha acabado de sair de 15 min de
  carga, com a tensão de terminal ainda elevada por "carga de superfície"
  (v_avg = 4,3028 V). A curva Motorola diz ~88% para 4,3028 V, então o valor
  inicial veio 86%. Sem carga há horas isso não aconteceria.
  Ou seja: o salto veio do RELOAD (reinicialização do estado), não do filtro,
  e reflete um viés conhecido de estimador só-OCV logo após carregar.
  Com o aparelho desplugado a tensão relaxa/cai e o número converge para
  baixo (deriva de 1% a cada 2 min; e se o desvio passar de 10 pontos, adota
  na hora, por causa do patch 0170).
  Regra prática para o futuro: NÃO recarregar o módulo logo depois de
  carregar a bateria — ou aceitar que o primeiro valor virá alto.

  ligar:    echo 1 > /sys/kernel/debug/hanoip-charge   (limite 1 A)
  desligar: echo 0 > /sys/kernel/debug/hanoip-charge
  registros: cat /sys/kernel/debug/c440000.spmi:pmic@0:charger@1000
  log:      /usr/local/sbin/hanoip-batt-log 900 2000 /root/batt.csv
  boot:     work/bateria-soc-20261027/u-boot-...-perif-batt.img
            + kernel-hanoip-kali-phosh-v2.img + módulos do kernel v4

1) PORCENTAGEM (resolvido). Oscilava porque o DT não tinha tabela OCV (mapa
linear de 12,5 mV por 1%) e a suavização era um caminhante de 1%/20 s que
perseguia o ruído. Correção: curva REAL da Motorola extraída do perfil que o
Android usa neste aparelho (4.447 V no topo) + histerese de 2% + deriva de
1% a cada 2 min + adoção imediata quando o desvio passa de 10 pontos; direção
pelo STATUS do charger (current_now é errático na transição). Validado:
amplitude de 1 ponto em 15 min ocioso, zero saltos, e sob carga de 79 mV de
queda a capacidade ficou cravada.

2) DESCOBERTA DE ARQUITETURA: a device tree efetiva vem EMBUTIDA NO U-BOOT
(CONFIG_OF_EMBED) — o dtb do boot.img do kernel NÃO é usado. Mudança de DT =
reconstruir U-Boot (variante sm7150-motorola-hanoip-pmos-perif-batt.dts).
scripts/fdt_diff.py compara DTs compiladas (usar sempre).

3) POR QUE NÃO CARREGAVA (laudo B0, somente leitura): faltava UM bit,
CHARGING_ENABLE_CMD (0x42) bit0; entrada/APSD(SDP)/float 4.400 V/JEITA/
terminação/recharga já estavam corretos. O watchdog do charger estava armado
com "bite desliga a carga" e o fast-charge vinha em 2,0 A.

4) CARGA (funciona, validada): 3 escritas (desarma watchdog, 1,0 A, habilita).
Sessão de 15 min em porta USB de PC: entrada 497 mA, bateria +440 mA,
79% -> 81%, 32,6-33,7 C (sem aquecimento). Desligar testado e limpo.

5) ÍCONE vs APP: com entrada de 500 mA e TELA LIGADA o aparelho consome mais
do que recebe, a corrente fica negativa e o UPower mostra "descarregando"
enquanto o sysfs mostra "Charging". Não é bug; resolve com B4 (APSD/ICL).
Com a tela apagada carrega normal (+440 mA).

6) COMPARAÇÃO COM O ANDROID: float 4,45 V, FCC 3,6 A, iterm 290 mA, ICL 3 A
em carregador de parede, 15-45 C, capacidade aprendida 4.939.000 uAh (igual à
nossa). O que a ABL deixou é um subconjunto conservador.

7) B4 FEITO (27/10, mais tarde): o driver agora detecta o tipo de fonte por
APSD ao ligar a carga e programa o limite de entrada (SDP 500 mA, CDP 1,5 A,
DCP 1,0 A, teto 1,5 A; ajustável por módulo). Validado em porta de PC: detecta
SDP e mantém 500 mA, tela apagada carrega +432 mA com ícone de carregando e
2,0 h para cheio; tela ligada fica negativo (conta física). FALTA validar DCP
num carregador de parede. Extra: /sys/kernel/debug/hanoip-icl força o limite
(último recurso; AICL protege se a fonte não aguentar).

8) SESSÃO DE CARGA LONGA (27/10, 14:22-15:30): a bateria subiu de 85% a 95%
e entrou na fase final (FSM TAPER, tensão no float de 4.400 V, corrente caindo
de 445 para ~230 mA, 30 C estável). A TERMINAÇÃO (status Full) ainda NÃO foi
observada — o limite de terminação deixado pela ABL é mais baixo que os 290 mA
do Android (registrador ainda não dumpado). Nessa sessão apareceram e foram
corrigidos 3 bugs do driver: teto de tempo ainda limitando (0174), wind-up de
5% liberando salto de 2 pontos (0175) e USO DE MEMÓRIA LIBERADA no debugfs
após reload — o dump mostrava msoc=0 enquanto o sysfs dizia 95% (0176).
Kernel v4 agora com 178 patches (0174..0178: teto do orçamento, FULL imediato,
cleanup de debugfs no unload, recusa de tensão impossível no boot e criação
tardia dos arquivos de debugfs). Achados do primeiro boot limpo: (1) o ADC
devolve 6,38 V nas primeiras amostras e isso jogava o SOC para 100% — agora é
descartado; (2) o driver sonda antes de /sys/kernel/debug existir, então os
arquivos de debugfs só apareciam após reload — agora são criados com retry.
O reboot desliga a carga (opt-in confirmado).

9) ESTADO NO FIM DO DIA (27/10, ~16h): kernel v4 com **180 patches**
(0167..0180). A porcentagem está estável e reportando (92%), a carga funciona e
está LIGADA por enquanto, e o dump de estado existe:
  cat /sys/kernel/debug/qcom_qg            (cheia SDAM, msoc, orçamento, corrente usada)
  cat /sys/kernel/debug/c440000.spmi:pmic@0:charger@1000
  echo 1|0 > /sys/kernel/debug/hanoip-charge ; echo <uA> > /sys/kernel/debug/hanoip-icl
MAPEAMENTO IMPORTANTE (medido): só os registradores de ÚLTIMO ADC da QGauge são
confiáveis (voltage_now 0xc0, current_now 0xc2). voltage_avg/current_avg
congelam ou devolvem 0, voltage_ocv está congelado, e o algoritmo periódico da
QGauge (que no Android faz a contagem de Coulomb) não roda aqui. Toda vez que o
driver usou um registrador "avançado" a taxa errou ~3x.
BOOT: o reboot desliga a carga (opt-in, confirmado) e a criação dos arquivos de
debugfs é tardia (8 s + retries), porque o driver sonda antes de
/sys/kernel/debug existir.

10) AUDITORIA E CORREÇÕES FINAIS (27/10, fim do dia): kernel v4 com 182
patches. Foram corrigidos, depois de auditoria de código + matemática: o
fallback de tensão que era código morto (podia zerar o SOC), o abs() na
contagem de Coulomb (subia o SOC com a bateria descarregando), o snap sem
limite, a corrente média inflada e, por fim, o viés de OCV que MUDA DE SINAL
entre CC e TAPER (agora: carregando = só Coulomb; em repouso = OCV).
Resistência interna do DT: 30 -> 200 mOhm (derivada de duas fontes: dado do
Android a 54%/500 mA e a nossa medição em campo).
Comparação com outros ports (seção 17 do RESUMO): o port do MESMO SoC
(fork sm7150-qg) usa SOC LINEAR e reporta status UNKNOWN; o sm7125 upstream
nem tem node de bateria. O nosso é o mais completo em reporte.

PRÓXIMOS PASSOS: (a) validar a subida com carga líquida positiva (tela apagada
ou carregador de parede) — com a tela ligada em porta de PC o consumo (631 mA)
supera a entrada (496 mA) e o display corretamente não sobe; (b) observar a
TERMINAÇÃO; (c) validar DCP; (d) decidir se a carga liga no boot; (e) opcional
1,5 A no DCP com térmica.

11) CONTAGEM DE COULOMB CORRIGIDA (patch 0183, 183 patches): dois bugs reais
achados ao ver 95% -> 100% em minutos com a tela apagada. (a) retificação do
ruído: contava só as amostras positivas de um ADC ruidoso, inventando carga
com a bateria entregando corrente; agora filtra a corrente COM SINAL (EMA 8)
e só conta acima de +50 mA. (b) div_s64 tem divisor de 32 bits e o divisor
real (3600 * capacidade em uAh = 1,78e10) era truncado para 6,0e8, contando
27x a carga real; agora div64_s64. Medido depois: 62 mili-% em 60 s a 192 mA
(teoria 71). Teto do orçamento 2000 -> 1000 mili-% (1% por passo) e o valor
PARA EM 99% enquanto carrega; 100% só quando o charger reportar FULL.
Prova de que o 100% era falso: ao recarregar o módulo o valor caiu para 92%.

12) CARREGADOR DE PAREDE (PD) DESTRAVADO — ERA O DT (27/10 tarde, 185
patches): um carregador USB-C de 100 W nao entregava nada. Causa: o DT em
sm7150-motorola-hanoip.dts declarava o conector Type-C como
power-role="source" (herdado do port de referencia do Xiaomi), e existe um
TCPM real no kernel; com "source" ele registrava a porta como FONTE PD
(Rp + VCONN) e o carregador, corretamente, nunca ligava o VBUS. Agora:
power-role="dual" + data-role="dual" + sink-pdos SO 5 V + op-sink 5 W.
"sink" sozinho NAO funciona (TCPM falha no probe com -EINVAL). Prova por
binario com scripts/fdt_diff.py (DT extraido do u-boot antigo, que estava em
gzip dentro do .img): 744 nos, 1 propriedade alterada. Resultado: APSD=DCP,
typec [sink], +186..250 mA na bateria, 32-33 C, e a tela NAO acendeu sozinha
ao plugar (os acordares eram provavelmente o TCPM tentando ser fonte).
Patch 0185: o driver negociava antes do APSD terminar, ficava no padrao SDP
e nunca re-negociava (medido: DCP preso em 550 mA); agora o worker de 10 s
reconcilia o tipo e ha um passe extra 2,5 s apos ligar a carga.

13) TERMINACAO OBSERVADA e o que "100%" significa (27/10 ~18:05, 187 patches):
status Full, 0 mA na bateria, FSM 0x45, 100% no display — primeira vez. Mas a
verificacao fisica diz 94,4%, por DOIS metodos independentes (curva OCV em
4,381 V de repouso; Coulomb: 91,5% + 145 mAh/4939 mAh). Causa: o ABL deixa o
float em 4,400 V (reg 0x70=0x50) e a curva Motorola só dá 100% em 4,4465 V;
o Android usa qcom,fv-max-uv = 4,450 V (dump do DT). DECISAO: manter 4,40 V
(célula velha, 4939 mAh aprendidos de 6174 de projeto) e usar o 100% apenas
como "charger terminou, pode tirar da tomada" — trava em 99% antes e volta ao
valor real quando desconecta. Gravado em comentário no driver (patch 0187).

FRENTE USB / MODOS (27/10 ~18:20, PLANEJADA, nada alterado ainda): o usuário
quer trocar o modo da porta pela interface como o Android faz. Viabilidade
verificada por evidência: o kernel JÁ tem CONFIG_USB_CONFIGFS (+ ACM, ECM, EEM,
NCM, RNDIS, MASS_STORAGE, HID, SERIAL, OBFS/F_FS, UVC=m), USB_ROLE_SWITCH,
DWC3_DUAL_ROLE, USB_OTG, XHCI (host), TYPEC_QCOM_PMIC e — importante —
REGULATOR_QCOM_USB_VBUS (o boost de OTG tem driver mainline próprio, já
habilitado no nosso DT com 500 mA..3 A). Lacunas reais: (L1) falta ferramenta/UI
de troca de modo e temos dois gadgets separados; (L2) DT com dr_mode =
"peripheral" e sem usb-role-switch; (L3) ninguém habilita o boost quando o
papel vira source; (L4) MTP precisa de servidor em userspace sobre f_fs;
(L5) sem persistência do modo; (L6) Phosh não tem UI de USB. Plano completo,
com fases, comandos, critérios e proibições (nunca exportar partição por
mass_storage; nunca habilitar VBUS com papel sink) em docs/PLANO-USB-MODOS.md.
Do dump do Android: gadget configfs "g1", is_otg=1, e o papel de host vem do
SMB5 por extcon (lá /sys/class/usb_role nem existe).

REVISÃO 2 do plano USB (27/10 ~18:30) — análise de reboot, verificada:
SÓ A FASE 1 PRECISA REBUILD+REBOOT (dr_mode="otg" + usb-role-switch; o DT vive
dentro do U-Boot). Fase 0 (ferramenta/app/gadget único/serviço), Fase 3 (MTP
sobre F_FS, já =y) e Fase 4 (persistência) são AO VIVO. E a antiga Fase 2
(energizar o periférico) DEIXOU de existir: qcom_pmic_typec_port.c já chama
regulator_enable(vdd_vbus) quando o papel vira source, e o nosso DT já tem
vdd-vbus-supply = <&pm6150_vbus> com 500 mA..3 A. O sunfish (mesmo sm7150 e
mesmo pm6150) faz OTG com exatamente DUAS linhas de DT, e o nosso link
usb_1_dwc3_hs <-> pm6150_hs_in já é igual ao dele.
CONSTRUÍDO E NÃO TESTADO (27/10 fim do dia): o U-Boot com OTG está pronto em
work/usb-20261027/otg/ (img 8d777c9c..., dtb 0503d416...) e a imagem que está
RODANDO foi preservada em work/usb-20261027/ANTES-otg/ (img e07ff366...).
fdt_diff prova 744 nós, 1 propriedade alterada (dr_mode peripheral->otg) e 1
nova (usb-role-switch). Nenhum reboot foi feito. Script de recuperação
(hanoip-usb-fix status|fix, tolera UDC ausente em modo host) escrito em
work/nethunter-pro-20261026/hanoip-support/ mas NÃO instalado. Instruções de
boot, checklist e pendências em work/usb-20261027/LEIA-ME.txt.

TESTE SÓ DE BOOT — PASSOU (27/10 18:46). O aparelho está rodando a imagem OTG
agora. Verificado: dr_mode="otg", usb-role-switch presente e SEM
role-switch-default-mode (padrão peripheral), role switch registrado
(/sys/class/usb_role/a600000.usb-role-switch role=device), UDC configured,
Type-C segue sink/device sem VCONN, usb0+SSH por USB OK, regulador usb_vbus
presente e DESLIGADO (3 A máx), carga pelo PC segue SDP/500 mA/+213 mA, sem
erros no dmesg. NÃO testado de propósito: periférico, saída de 5 V, carregador
de parede com esta imagem. Achado antigo a corrigir: o dump de debugfs do
charger não nasce no boot (o work desiste após 8 tentativas) — hoje exige
recarregar o módulo.

ARMADILHA REGISTRADA: o DT é VOLÁTIL — vive na imagem de U-Boot que bootamos.
Se alguém bootar o U-Boot antigo, voltam o power-role errado e a ausência de
OTG. A imagem nova precisa virar par de boot padrão, com hash, e o snapshot
desta frente tem de guardar a imagem do U-Boot, não só o rootfs.

PENDENTE ANOTADO (27/10 ~18:10): recarga após terminação (item 1) e AICL
(item 3) NÃO podem ser observados no carregador de parede — com o cabo
plugado a bateria fica em 0 mA (não descarrega, então nunca cruza o limiar de
recharge) e uma fonte de 100 W não afunda o VBUS (não há o que o AICL limitar).
Protocolo completo, comandos, o que esperar e os limites de segurança estão em
docs/kernel/PENDENTE-recarga-e-AICL-20261027.txt. Precisa de porta de PC +
tela ligada. Loggers já rodando no aparelho: charge-watch
(/root/charge-watch.log, 10 s) e dpms-watch (/root/dpms-watch.log).

## KALI NETHUNTER PRO (Phosh) — FUNCIONAL e com SNAPSHOT (27/10/2026)

O Kali roda no hanoip com quase tudo do pmOS e mais: Phosh, Wi-Fi 5 GHz com
internet, SSH root por chave, rede USB (Mac 172.16.42.2), sensores SSC
(accel com orientação, luz, proximidade), vibração, LED, flash, áudio no
alto-falante (UCM+rota+S16LE+mono, 6 dB), tuning de desempenho (GPU 355 MHz /
poll 16 ms, UFS 200 MHz, CPU schedutil), relógio com fake-hwclock+NTP e fuso
America/Sao_Paulo. NFC lê cartão ISO14443-A (kernel + neard).

SNAPSHOT: work/kali-20261027-snapshot/ (rootfs.tar.zst 2,1 GB + configs +
packages + README com restauração + SHA256SUMS). Tirado do pmOS com o rootfs
montado RO — fazer dentro do Kali travou a interface.

Boot (SÓ volátil; NUNCA reiniciar para o Android):
  fastboot boot work/GOLD-20261026-1712/u-boot-hanoip-pmos-perif-v2026.10.img
  fastboot boot work/nethunter-pro-20261026/artifacts/kernel-hanoip-kali-phosh-v2.img
  (cmdline: NÃO usar console=ttyGS0, que trava o PID 1 do systemd)

CORRIGIDO em 27/10 — "Failed to mount /dev/disk/by-partlabel/userdata":
  causa era a NOSSA regra udev /etc/udev/rules.d/99-hanoip-blockdev-ro.rules
  usando KERNEL=="sd*", que travava o DISCO inteiro (/dev/sdb ro=1); com o
  disco RO o `mount -w` do initramfs falha com EPERM. Agora é KERNEL=="sd*[0-9]"
  (só partições). A regra foi corrigida no rootfs E no initrd, e o initrd foi
  reconstruído dentro do Kali. Evidência completa em
  work/nethunter-pro-20261027-fix-mount/LEIA-ME.txt.
  Também foi reparado um ext4 com inodes órfãos/bitmaps (e2fsck -fy, 27/10).
  Reboot seguro: /usr/local/sbin/hanoip-reboot (sync + remount RO + b);
  NUNCA `echo b > /proc/sysrq-trigger` sozinho — foi isso que corrompeu o ext4.
  AUDITORIA COMPLETA de logs (dmesg inteiro + journal inteiro) em
  work/nethunter-pro-20261027-fix-mount/AUDITORIA-LOGS-KERNEL.txt:
  kernel sem Oops/WARNING/hung/OOM; corrigido /etc com uid 502 (2320 arquivos,
  systemd-tmpfiles recusava operações) e regulatory.db (apontava para o
  assinado pela Debian, kernel só confia no upstream → domínio US).
  Pendências: (A) bateria "Not charging" com corrente 0 (continua aberta),
  (B) zram RESOLVIDO em 27/10 (systemd-zram-generator + zstd 1,7 GiB +
  swappiness 100; 11:1 de compressão no teste de pressão), (C) atomic commit
  do DSI-1 medido: 917 IRQs/15 s = 61 Hz e ZERO falhas com a tela em uso; as
  falhas restantes são só do modeset inicial e da abertura de janelas
  (EBUSY transitório do wlroots) — não justifica mexer no kernel.
  Também corrigido no mesmo dia: hanoip-ssc (sensores) falhava no boot a frio
  porque o hexagonrpcd era iniciado uma única vez, antes do ADSP ficar
  "running" — agora espera o remoteproc e tenta até 6 vezes (validado em boot
  a frio: try 1, Result=success). E bootmac-bluetooth.service foi mascarado
  (script do Mobian/SDM845 que dá timeout; o hci0 já sobe com MAC estável
  D8:CF:BF:3C:EE:74). Estado final: is-system-running = running, ZERO units
  falhando.

Descobertas que custaram tempo (não repetir):
 - console=ttyGS0 na cmdline => PID 1 bloqueado em n_tty_write => tela preta,
   systemctl/SSH travados e "user@0 Connection timed out". Usar console=tty0.
 - greetd: phrog NÃO aceita -s; usar `command = "phrog"` e o symlink
   display-manager.service; _greetd nos grupos video/render.
 - Relógio errado (1974/Sep 22) fazia o PAM recusar a conta; hoje há
   fake-hwclock + NTP.
 - Wi-Fi: o modem Motorola precisa do SMEM mmi_unit_info (identidade do ABL);
   sem hanoip_mmi_unit_info.ko o firmware do WLAN crasha
   ("firmware crashed!"). Ordem: firmware -> mmi -> modem -> ath10k.
 - iio-sensor-proxy precisa ser reiniciado depois que o hanoip-ssc publica.
 - Áudio: 3 peças (UCM, regra udev da rota, WirePlumber S16LE) + 6 dB.

PENDENTE no Kali: app gráfico de NFC (hanoip-nfc.py pronto, não instalado),
câmera, digital, microfone/fone, suspend.

## >>> ÍNDICE — COMECE POR AQUI (26/10/2026 ~19h30)

COLETA FINAL DO ANDROID (26/10 ~20h50): `work/android-dump-20261026-final/`
(privada, fora do git; ler LEIA-ME.txt). EFS (modemst1/2, fsg_a, fsc) + 40
partições, /vendor+/odm completos (mixer_paths, ACDB, sensores, câmera, GPS,
NFC, Wi-Fi, init.rc), /data/vendor selecionado (sem Wi-Fi/digitais/radio) e
34 seções de estado em execução (mascaradas). O Android é uma ROM Android 16
custom (kernel 4.14.206 CosmicFresh), NÃO Android 11. Falta só: estado com
microfone gravando / fone conectado / earpiece (precisa de ação do usuário).
Decisão: captura ao vivo do áudio DISPENSÁVEL (mixer_paths.xml tem 526
rotas: amic1-3, dmic-endfire, handset/earpiece, headphones, speaker; mais
audio_platform_info e 9 ACDB). Antes de apagar o Android, ainda valem:
(1) copiar as partições pequenas não lidas (~200 MB): utags/utagsBackup
(config Motorola), uefivarstore, sp, spunvm, ssd, prov_a/b, multiimgoem/qti,
vendor_boot_a/b (DTB+ramdisk stock), vbmeta*, xbl*_b, tz_b, storsec_b,
uefisecapp_b, qupfw_b — rede de segurança para restaurar; (2) arquivos
pessoais da memória interna (fotos etc.) — decisão do usuário; (3) baixar
no Mac o firmware stock XT2135-1 RETBR e o zip da ROM atual, para restaurar.
Nada destrutivo autorizado ainda (AGENTS.md: nenhum flash).

ABL DIRETO (26/10 ~20h20): mainline v2 direto pelo ABL = logo "M" ~1 s e
volta ao fastboot (ABL recusa). v0 não executa (klockmt), v3 usaria o DT do
vendor_boot gravado. Sem gravar partição o caminho é o U-Boot volátil. Slot A:
successful=yes, retry-count=6 (fastboot boot não consome). Ver
work/abl-direct-20261026/LEIA-ME.txt. Celular está no fastboot da Motorola.

REFERÊNCIA EXTERNA: `docs/referencias/klockmt-hanoip-pmos.md` (outro port pmOS
do G60, downstream 4.14 flasheado; mainline nunca bootou para eles). A
conferir só lendo no próximo fastboot da Motorola: `fastboot getvar
slot-retry-count:a`, `slot-successful:a`, `slot-unbootable:a` (o ABL marca
o slot unbootable após ~7 boots sem "successful"). Ideia: reboot direto ao
bootloader com reboot(RESTART2, "bootloader").

REPRODUZIR TUDO: kernel `work/kernel-7.3/v3/build.sh`; U-Boot
`work/uboot-builds-20261026/build.sh <DT>`; rootfs
`work/pmos-super-20261025/build-rootfs.sh` (pacotes de hoje incluídos:
Turnip, vídeo, i2c-tools, strace); índice dos pares em
`work/PARES-DE-BOOT-20261026.md`. Os três scripts de build ainda não foram
rodados do zero. Imagens e blobs ficam só no disco (fora do git).

ESTADO DO CELULAR: rodando o par de teste `work/video-20261026/venus-v1/`
(U-Boot venus-v1 + cópia do kernel da GOLD-20261026-1500). Esse boot monta o
rootfs RO com overlay em RAM: tudo o que foi instalado nele (Turnip,
gst/ffmpeg/v4l-utils, venus-core.ko novo) some no reboot. RETORNO PADRÃO =
GOLD-20261026-1500 (bootar sempre de uma CÓPIA das imagens). Nada commitado;
git só quando o usuário pedir.

Feito hoje (detalhes nas seções abaixo): alto-falante + PipeWire; botões de
volume; vibrador (2 patches); lanterna traseira/frontal + helper do Plasma;
LED de notificação; NFC lendo cartão; correção do Wi-Fi (QRTR); câmeras
passo 1 (4 sensores identificados); Venus (decode H.264 bit-exato) e Vulkan
(Turnip); kernel 7.3 v3 reproduzível (build.sh, não testado do zero).

PAUSADO no meio (retomar pela seção correspondente):
- Carga da bateria — autorizada (500 mA, 4,35 V), patch não escrito.
- Câmeras passo 2 (1ª imagem no OV02B1B) — decode-regs.py não rodado.
- Push do git — FALTA SÓ O PUSH: tudo commitado LOCALMENTE no main em
  "Audio, peripherals, Wi-Fi fix, Venus..." (serial/MACs/SSID mascarados, blobs e imagens fora). `git push
  origin main` quando o usuário pedir.
- Proteção do alto-falante — plano de 4 passos.
- Kali NetHunter Pro — só levantamento.

RAM (diagnóstico 26/10, não mexido): aparelho XT2135-1 com 4 GB; Linux vê
MemTotal 3.635.716 kB (3,47 GiB) contra 3.739.480 kB no Android (~100 MB a
menos: splash 0x9c000000-0x9d6fffff ~23 MB, ramoops 4 MB, CMA 32 MB e outras
reservas). Sem swap: `postmarketos-zram-swap` está no runlevel default mas
fica "stopped" sem log (deviceinfo existe, zram0 e zstd existem) — rodar
`zramstart` à mão para ver o erro. Ganho fácil: zram ~150% da RAM com zstd.

Lista do que falta: README "O que falta" + itens extras levantados na
conversa de 26/10: pacote device-motorola-hanoip/kernel do pmOS; apk upgrade
seguro (sobrescreve correções manuais); série de patches consolidada (feito
no v3); espaço (rootfs 5 GB, userdata proibida); desligar/reiniciar pelo
Plasma; RTC/hora após reboot; carga com o aparelho desligado; bug do WLED
(wled5_setup usa o registrador do WLED4); apagar tela/bloquear por
inatividade; brilho mínimo/flicker; toque duplo/palma; earpiece; detecção do
fone; perfis de som/voz; rádio FM; Wi-Fi 5 GHz/economia; SIM nos 2 slots;
Waydroid (falta ANDROID_BINDERFS); Vulkan (feito); QCE/RNG; SSH root e
firewall (o 7.3 TEM nftables, NF_TABLES=m — o item "sem nftables" do README
vale só para o 7.1). Modo monitor do Wi-Fi: o ath10k declara suporte
(iw list); injeção não testada; OTG funciona no Android, no Linux falta
ligar role-switch + smb5-vbus.

## Projeto novo: Kali NetHunter Pro (26/10 ~19h20) — só levantamento

Pasta `work/nethunter-pro-20261026/` (LEIA-ME.md + docs/). O build oficial
(debos, fork do Mobian) JÁ tem a família `sm7150` (sunfish, davinci, surya,
sweet, toco, tucana): o hanoip entra como mais um [[device]]. Kernel do
Mobian é 6.18 sem hanoip -> empacotar o nosso 7.3 v3 como .deb. Instalação
oficial = flash de userdata/boot (PROIBIDO) -> usar a cauda do super + boot
volátil como no pmOS. Revisar make-dynpart-mappings e droid-juicer (montam/
mapeiam partições do Android) e levar as regras udev de RO. debos precisa de
KVM (não tem no Mac). Nada construído nem gravado.

## Kernel 7.3 v3 reproduzível (26/10 ~19h10)

`work/kernel-7.3/v3/`: patches/ (166 = v2 + 0161 AW882xx, 0162 pinos SSC do
LPI, 0163/0164 vibrador, 0165 QRTR, 0166 Venus), config (v2 +
SND_SOC_AW882XX=m), extra/ (fonte do hanoip_mmi_unit_info, antes só no
container), Dockerfile (Ubuntu 24.04, gcc 13.3), build.sh + build-inside.sh
(baixa o tarball 7.3, confere árvore base 30fd2ef8 e final 19b139f7, compila
Image/módulos/DT/extra, empacota com ramdisk opcional) e README.txt.
NÃO TESTADO do zero (usuário dispensou); conferir no 1º uso.

## Vídeo por hardware (Venus) e Vulkan — SUCESSO (26/10 ~18h55)

- VULKAN OK: `mesa-vulkan-freedreno` (Turnip) -> vulkaninfo "Turnip Adreno
  (TM) 618", Vulkan 1.3, Mesa 26.1.6; vkcube --wsi wayland rodou 6 s sem
  fault da GPU (usuário não confirmou visualmente o cubo).
- VENUS OK: patch `work/video-20261026/patches/0001-media-venus-add-SM7150-
  resources-experimental.patch` (container: bd7ea6f00d54) = entrada
  qcom,sm7150-venus baseada no SC7180 (HFI 4XX, 1 codec; vcodec1 é o CVP),
  freq. dos OPPs do DT (240-533 MHz). DT `sm7150-motorola-hanoip-pmos-venus.dts`
  = perif + &venus okay + firmware-name qcom/sm7150/motorola/hanoip/venus.mdt
  (firmware VIDEO.IR.1.2 do modem_a; região 0x93400000/5 MB e SID 0x1080/0x60
  batem com o Android). Par `work/video-20261026/venus-v1/` (U-Boot venus-v1 +
  kernel da GOLD-20261026-1500) + `venus-core.ko` novo carregado à mão.
  Resultado: /dev/video1 decoder H.264/HEVC/VP8/VP9/MPEG-2, /dev/video0
  encoder (NV12); 300 quadros 1080p H.264 decodificados em 2,4 s (~125 fps)
  pelo GStreamer v4l2h264dec, quadros IDÊNTICOS (md5) ao decoder por
  software. "error reading F/W version" é só o formato da string do Iris.
  Encoder: não testado (usuário encerrou o teste e deu como sucesso).
- ATENÇÃO: a GOLD-20261026-1500 monta o rootfs RO com overlay em RAM
  (/run/pmos-overlay/upper): tudo instalado nesses boots SOME no reboot
  (Turnip, gst/ffmpeg/v4l-utils, venus-core.ko, blacklist). Para tornar
  permanente: bootar um kernel rw (perif/v6-qrtr) ou gravar no rootfs com o
  procedimento do super e pôr os pacotes em build-rootfs.sh. O venus-core.ko
  gravado no rootfs ainda é o original (sem sm7150) -> nada carrega sozinho.
- O boot-volatile.py novo (serial detectado, sem serial fixo) foi usado neste
  boot e FUNCIONOU.

## Carga da bateria — PAUSADA pelo usuário (26/10 ~15h50), nada gravado

AUTORIZAÇÃO DADA (26/10): escrever no carregador do PMIC com o plano abaixo,
começando com 500 mA. Ainda NÃO foi feita nenhuma escrita; o patch não foi
escrito (só lido o driver). Ao retomar, confirmar com o usuário de novo.
Diagnóstico (leitura RO via /sys/kernel/debug/regmap/0-00, base 0x1000):
- Não carrega porque CHARGING_ENABLE_CMD 0x1042 = 0x00 (status 0x1006 = 7,
  DISABLE). CHGR_CFG2 0x1051 = 0x2c (enable por comando, auto-recharge, iterm).
- FCC 0x1061 = 0x28 (2000 mA, valor do bootloader); pré-carga 0x1060 = 4
  (200 mA); FV 0x1070 = 0x50 (4,40 V; SMB5 = 3,6 V + n x 10 mV).
- Entrada: SDP 500 mA (0x1366 = 0x02, ICL 0x1370 = 0x1e), AICL 0x1380 = 0xd4.
- JEITA por hardware ativo (0x1090 = 0x1b, limites 0x1094-0x109f do
  bootloader), status 7 0x100d = 0; safety timer 0x10a0 = 0x03.
- Bateria 3,91 V, 34,3 °C, ~76% (estimado); PM6150 41 °C.
Driver: qcom_smbx (módulo) com match "motorola,hanoip-smb5-monitor"
(monitor_only = true, não grava nada). Sem monitor_only o mainline aplicaria
o init_seq SMB5 (Type-C, AICL, watchdog, SDP...) e NÃO programa a FCC.
Plano aprovado: parâmetro charge_current_ua (0 = desligado, teto 1 A) que
grava FCC + FV 4,35 V (0x4b) + CHARGING_ENABLE_CMD; vigia a cada 10 s corta
em JEITA hard hot/cold (0x100d bits 3/2) ou BAT_OV (0x1007 bit 1); rmmod e
.shutdown desligam a carga. 1º teste: 500 mA por ~10 min no cabo do Mac,
parar se a bateria passar de 40 °C.

## GIT — (histórico; RESOLVIDO às ~19h40: commit local no main, só falta o push)

- O commit local 57b68c527 da outra sessão (2,4 GB, nunca enviado) foi
  DESFEITO só localmente (`git reset --soft` + `git reset`); branch atual =
  `main` = origin/main = b9334203e; `kernel-7.3` local também em b9334203e.
  Nenhum arquivo foi apagado do disco; tudo está como mudança não commitada.
- Usuário escolheu publicar "código + GOLD nova", mas a imagem do kernel e o
  ramdisk da GOLD-20261026-1500 EMBUTEM o sensor-bundle e o firmware do touch
  (proprietários) -> só GOLD.txt, SHA256SUMS e o U-Boot vão.
- `.gitignore` já ganhou as regras (imagens/ramdisks/tarballs/.ko/.dtb/.bin
  de work/, blobs do vendor, android-live-readonly, registry, scans de Wi-Fi).
  `git add -A -- . ':!kernel-mainline'` dá ~877 arquivos / ~22 MB.
- FALTA antes do commit: mascarar o serial do fastboot, os MACs reais
  XX:XX:XX:XX:XX:XX-76 e o SSID da casa nos ~50 arquivos de log/notas
  (lista: grep -l nos arquivos do stage). O serial já está em 5 arquivos do
  main publicado (só reescrevendo histórico para tirar).
- `work/hanoip-display-20261024/boot-volatile.py` foi alterado para NÃO ter o
  serial fixo (usa HANOIP_SERIAL ou detecta o fastboot da Motorola por
  `getvar product` = "hanoip"). Compila, AINDA NÃO TESTADO num boot real.
- kernel-mainline/…/xt_*.h modificados = artefato de maiúsculas do macOS: não
  commitar.

## Câmeras — passo 1 (identificação) VALIDADO (26/10 ~15h05)

Par volátil `work/cameras-20261026/step1-camid/`: U-Boot
`u-boot-hanoip-pmos-camid-v1.img` (DT `sm7150-motorola-hanoip-pmos-camid.dts`
= perif + CCI0/CCI1 a 400 kHz + 6 reguladores fixos por GPIO + MCLK + nós
hanoip,camid) + cópia do kernel da GOLD-20261026-1500. Módulo
`work/cameras-20261026/camid/hanoip-camid.ko` (sem alias, insmod à mão): liga
VIO→VANA→VDIG→MCLK 24 MHz→solta reset, lê o ID, desliga tudo.
Resultado (1ª tentativa, todos OK, rails voltam a 0):
  S5KHM2 principal  CCI0 m0 0x56 ID 0x1AD2 (MCLK0 gpio13, reset 23, AVDD gpio72, VDIG L6A 1,104 V)
  OV02B1B profund.  CCI0 m1 0x3D ID 0x2B   (MCLK3 gpio16, reset 26, AVDD gpio46)
  S5K4H7 ultrawide  CCI0 m1 0x2D ID 0x487B (MCLK1 gpio14, reset 24, AVDD gpio46, DVDD gpio33)
  OV32B frontal     CCI1 m0 0x10 ID 0x3242 (MCLK2 gpio15, reset 25, AVDD gpio65, DVDD gpio93)
  VIO = L13A 1,8 V em todas; VCM 2,8 V = gpio64 (não usado ainda).
IDs/endereços vieram do bloco slaveInfo dos sensormodule.bin (slave 8-bit,
regAddrType, dataType, idReg, id, mask, i2cFreqMode). Foco: S5KHM2 = DW9800,
S5K4H7 = DW9714 (mainline). OV64B/OV16A1Q são segundas fontes (não nesta unidade).
Próximo: passo 2 = primeira imagem num sensor simples (OV02B1B ou S5K4H7):
driver V4L2 com tabela de registradores do .bin + CSIPHY/camss.

**Câmeras PAUSADAS pelo usuário (26/10 ~15h20) no início do passo 2.**
Decisão: 1ª imagem no OV02B1B (2 MP, 1 lane, sem foco; 8 bits de endereço
e página no reg 0xfd, mesma família do ov02a10 mainline = base do driver).
Usuário perguntou sobre usar os drivers do Android: inviável (cam_* embutido
no kernel 4.14 + HAL CamX/CHI fechado sobre bionic/binder); só os DADOS dos
blobs são reaproveitados.
Formato do sensormodule.bin entendido em parte: tabela de tipos (nós de
72 B) termina no último nó; depois vem um fluxo de palavras de 8 bytes.
Cada escrita de registrador = 3 grupos com tags consecutivas:
[t, regAddr, regData] [t+1, addrType, dataType, op, x] [t+2, delayUs].
Resolução 1600x1200 em 0x91b8/0x9b40 do bin do OV02B1B; 19 escritas de 0xfd.
Decodificador escrito MAS NÃO RODADO: `work/cameras-20261026/decode-regs.py
FILE [MIN_RUN]` (imprime as listas de regSetting: power, init, modos,
stream on/off). Próximo ao retomar: rodar no bin do OV02B1B, separar
init/modo/stream, conferir lanes (laneAssign) e taxa MIPI, escrever o driver
V4L2 e ligar camss + CSIPHY3 no DT (slot 2).
ESTADO DO TELEFONE: está no par de teste `step1-camid` (U-Boot camid-v1 +
kernel da GOLD-20261026-1500); reguladores de câmera desligados; o módulo
hanoip-camid foi carregado uma vez (fica em /tmp, some no reboot). Para uso
normal, voltar à GOLD-20261026-1500 (copiar as imagens antes de bootar).

## Rotação manual OK, automática adiada (26/10 ~18h)

- Ponte manual FUNCIONA: `kscreen-doctor output.DSI-1.rotation.{inverted,none}`
  (via `su user`, WAYLAND_DISPLAY=wayland-0, XDG_RUNTIME_DIR=/run/user/10000).
  Testado com o telefone de ponta-cabeça e de volta ao normal.
- Automática ADIADA pelo usuário. O proxy nunca decide sozinho: `ssccli`
  recebe accel sempre (retrato Y≈+9,8, invertido Y≈-9,8, deitado Z≈+9,9),
  mas o proxy recebe ZERO amostras via QMI (log com debug prova; luz/prox
  fluem). Sem amostra, orientação fica `undefined`. No 1º boot Plasma ele
  DECIDIU (retrato→`bottom-up`: inversão de 180° real e medida); nos boots
  seguintes, silêncio — causa raiz aberta (ADSP/QMI).
- Driver ssc do proxy IGNORA `ACCEL_MOUNT_MATRIX` do udev (testado). Registry
  (RAM) está no vendor (-x,-y); testado +x,+y sem efeito (sem stream).
- NÃO dar `rc-service hanoip-ssc restart`: travou o USB (precisou reboot no
  botão). Só o restart do `iio-sensor-proxy` é seguro.
- Boots rápidos em `work/sensors-20261026/orient-fix/` (v3-fast com +x,+y,
  v4-base vendor; ambos sem o hash de 235 s no `pmos-root`; SSH em ~40 s).
  v4 VALIDADA (~43 s): serviços ok, wlan0 com IP, DSI irqs=0, sdb23 RO,
  tainted 4096 (pré-existente), ssccli accel+luz ok, KWin rodando.
  Telefone agora na v4. Detalhes em `orient-fix/NOTAS-diagnostico.txt`.
- Kernel v3 (166 patches) VALIDADO em boot volátil 26/10 ~21h: SSH, DSI
  irqs=0, wlan0 com IP, AW882xx probe OK (0x1852), módulos no overlay RAM.
  Pronto para empacotar como .deb do Kali.
- Próximo da rotação (quando pedirem): ponte libssc→kscreen-doctor ou
  retomar o stream QMI com essas evidências.
- LED white:status VALIDADO visualmente pelo usuário (brilho 511 acende;
  trigger de volta em pattern, feedbackd no controle).
- NOVA GOLD 26/10 ~17h12: `work/GOLD-20261026-1712/` (GOLD.txt + SHA256SUMS,
  somente leitura) — U-Boot v2026.10 + kernel #6, retorno padrão daqui em
  diante. U-Boot refeito sobre o oficial (delta reaplicado, DWC3 descartado);
  validado volátil (DSI irqs=0, wlan0, SSH ~40 s). GOLD-20261026-1500 preservada.
- Push PENDENTE (usuário irritou-se, não insistir): commit local `57b68c527`
  "Sensores via ADSP, GOLD rapida, LED, cameras" criado no branch
  `kernel-7.3` (ahead 1 do remoto); push à `main` subiu só até `b9334203e`
  (commit da outra IA); push do `kernel-7.3` interrompido. Nada se perdeu.
  Antes de retomar: conferir `git status` (outra IA mexe nos mesmos
  arquivos), segredos e binários >95 MB.

## ESTADO ATUAL — Plasma completo + sensores SSC, 26/10/2026 (continuação)

**Comece por este estado.** O celular está no kernel Linux 7.3.0-sm7150 #6
com o U-Boot perif-v5, iniciado por `fastboot boot` em RAM. O usuário pediu
usar a versão completa do Plasma previamente funcional e confirmou que a
orientação automática **não gira**. Não reiniciar enquanto a tela/sessão está
estável sem necessidade. Nenhuma partição foi escrita.

A imagem de teste é
`work/sensors-20261026/plasma-full/kernel-hanoip-pmos-full-sensors-ro-v1.img`
(SHA256 `6400c2e15a387ed054fcb18ec3e414c5dd25e1d0be99c78b272ac6fed48891ff`).
Ela preserva o kernel, DTB, U-Boot e rootfs instalado da variante anterior que
carregava os periféricos, e acrescenta um initramfs para montar o rootfs
existente somente leitura e uma camada OverlayFS inteiramente em RAM. Não
confundir com a tentativa intermediária `work/sensors-20261026/plasma-ram/`:
essa extraiu outro rootfs, criou sessão Plasma nova e foi abandonada. Não usar
essa instalação.

**Segurança/estado do armazenamento:** o usuário autorizou a montagem
somente-leitura do rootfs para esta retomada. Na inicialização, todos os
`/dev/sd*` são marcados RO; `/dev/sdb23` (super), o loop7 e o ext4 aparecem RO.
O rootfs foi montado `ro,noload,nodev,nosuid,noexec`; `/` é OverlayFS e as
alterações ficam em `/run/pmos-overlay` (RAM). SHA256 completo de `/dev/sdb23`
antes/depois coincidiu; log `SUPER_HASH_MATCH_RO_RAM_OVERLAY` e
`PMOS_FULL_RO_RAM_READY` em `/run/hanoip-pmos-root.log`. Não montar qualquer
outra partição. O hash integral da super foi calculado duas vezes no caminho
de boot e tornou esta partida muito lenta (~235 s até o status consultado).
O usuário não pediu essa verificação no boot; ela foi adicionada por minha
decisão para satisfazer uma regra de segurança. Não repetir leitura/hash
integral no caminho de inicialização; deixar hash como auditoria separada,
sem mudar a garantia RO/noload da montagem. O usuário reclamou explicitamente
do atraso.

**Sensores no Plasma:** `hanoip-ssc` e `iio-sensor-proxy` estão started.
`hexagonrpcd` e `pd-mapper` estão ativos. O D-Bus de SensorProxy reportou
HasAccelerometer=true, HasAmbientLight=true, HasProximity=true e luz ~74,7
lux; proximidade FAR. `monitor-sensor` viu mudança de luz (76,1→74,7 lux).
A leitura do acelerômetro em baixo nível dentro deste boot deu valores perto
de X=0, Y=0, Z=9,9–10,1 m/s². O aplicativo do usuário confirma que a tela
**não gira** ao mudar orientação. SensorProxy mantém
AccelerometerOrientation=undefined e AccelerometerTilt=undefined; logo, a
rota do Accelerometer para a política do KWin não está produzindo orientação
útil. O detalhe anterior do firmware permanece: mount matrix zerada, libssc
usa identidade. Proximidade foi validada no diagnóstico anterior, não foi
confirmado evento NEAR no Plasma nesta sessão. Auto brilho não foi validado:
`kwinoutputconfig.json` na base tem `automaticBrightness:false`, curva zero; o
valor do proxy variou, mas a retroiluminação não foi demonstrada reagindo.
Giroscópio produziu 665 amostras no teste SSC anterior, porém o `iio-sensor-
proxy` empacotado só publica accel, luz, proximidade e bússola; não expõe
este gyroscope. Não afirmar que o giroscópio está integrado ao Plasma.

**Próximo passo exato:** diagnosticar AccelerometerOrientation `undefined` e
porque KWin não gira. Use monitor-sensor com o telefone em posições físicas
conhecidas (vertical, horizontal, tela para cima/baixo), registre leituras
SSC XYZ e sinais do proxy. Em seguida validar a política KWin: a configuração
salva define `autoRotation: InTabletMode`, mas o celular não tem sensor de
modo tablet/capa; verificar temporariamente `automatic`/sempre habilitado pela
API KScreen e observar se KWin recebe orientação. Não escrever a base: ajuste
de teste somente em OverlayFS/RAM. Depois confira luz/proximidade e ajuste
curva de brilho só após comprovar leitura. Retomar sessão de SSH pela rede NCM
172.16.42.1 se disponível, ou USB serial. A chave de host SSH mudou com o
switch_root; arquivos de sessão/host local estão em
`work/sensors-20261026/plasma-full/known_hosts-plasma` e a saída volátil em
`handoff/runtime.txt`. Se SSH host key não conferir, confira fingerprint via
console; não apague chaves globais. Uptime observado no snapshot: 491,83 s,
kernel tainted=4096 (existia na captura; causa ainda não determinada), DSI
`error_snapshot` com irqs=0. Wi-Fi/Bluetooth subiram no autostart dessa
variante antes da entrada no Plasma.

**Artefatos desta variante:**
- `work/sensors-20261026/plasma-full/pmos-root`: montagem RO + OverlayFS RAM;
- `hanoip-ssc`: OpenRC que liga FastRPC/ADSP a `/opt/ssc` e inicia hexagonrpcd;
- `sensor-bundle-fixed.tar.gz`: userspace/registry/config/firmware SSC servidos
  a partir de cópias em RAM;
- `ramdisk.cpio.gz`, `baseline-ramdisk.cpio.gz`, `overlay.ko`,
  `kernel-hanoip-pmos-full-sensors-ro-v1.img`, `SHA256SUMS`;
- `handoff/runtime.txt`: estado coletado sem guardar dados de identidade;
  `handoff/runtime-files.tar.gz`: cópia volátil dos serviços/regras/configs;
- `monitor-plasma.txt`: leitura D-Bus (luz variou; acelerômetro sem orientação).
A tentativa `plasma-ram/` e comandos `kscreen-doctor` presos estão obsoletos;
não repetir. Os serviços do Plasma completo já estão ativos neste boot.

Não criar/promover GOLD, não gravar partições, não fazer commit/push. Câmeras
e digital continuam pausadas. O foco é fazer funcionar aceleração/orientação,
brilho e proximidade na sessão Plasma existente.


## ATUALIZAÇÃO — giroscópio também passou, 26/10

Teste de 30 s no mesmo boot RAM: **665 amostras**, resposta ao movimento
nos três eixos, com ambos os sinais. Tainted=0; sem partições montadas.
`ssccli --sensor=gyroscope` funciona apesar da ajuda incompleta.
Orientação/calibração ainda pendentes (mount matrix zerada → identidade).
Checkpoint e evidências no mesmo local do teste SSC abaixo. Os quatro
canais foram testados: acelerômetro, giroscópio, luz e proximidade.
Próximo: integração ao pmOS/Plasma em RAM. Sem reboot nem nova imagem.


## ATUAL — sensores testados no celular, 26/10

Acelerômetro: **382 amostras**, cerca de X=-0,07/Y=0,08/Z=9,95 m/s².
Luz: **0 a 72,5 lux observados**. Proximidade: **FAR/NEAR alternando**,
13 eventos/12 transições. ADSP + FastRPC + hexagonrpcd + libssc funcionaram
no diagnóstico inteiramente em RAM, kernel #6/DT e U-Boot perif-v5.
Tainted=0; nenhuma partição montada ou escrita. Telefone agora no diagnóstico
USB serial, sem Plasma por intenção. Giroscópio e integração ao Plasma ainda
não testados. Câmera/digital pausadas; seções antigas abaixo são históricas.

Checkpoint: `docs/kernel/checkpoint-2026-10-26-sensores-teste-ssc.txt`.
Kit/evidências: `work/sensors-20261026/ssc-ram-test/run1/`.
A imagem v1 precisou corrigir ordem de módulos manualmente no mesmo boot;
script local corrigido, imagem v1 ainda conserva ordem inicial. Próximo:
levar serviços ao pmOS em RAM e validar rotação/brilho automáticos.
Nenhuma nova GOLD e nenhum commit.


## Câmeras — levantamento RO em andamento (26/10 ~13h30, não mexer na seção de sensores)

Frente atual, só leitura, sem boot/probe/captura/escrita. Checkpoint:
`docs/kernel/checkpoint-2026-10-26-cameras.txt`; blobs e parser em
`work/cameras-20261026/` (vendor-blobs/ com SHA256SUMS, parse-sensormodule.py).
DT Android: 4 slots (cell 0 traseira principal AF+flash csiphy0; cells 2/3
auxiliares; cell 1 frontal), CCI0/1, MCLK 24 MHz, GPIOs 13/23, 16/26, 14/24,
15/25; VIO L13 1,8 V, VANAs 2,8 V por câmera, VDIG L6/1,2 V/1,1 V, VCM 2,8 V.
Blobs puxados RO conferem com o inventário; `rear.main.type`=`old` nesta
unidade. Principal = S5KHM2 (12000x9000) ou OV64B (9248x6944, segunda fonte);
frontal = OV32B ou S5K4H7; auxiliares = OV16A1Q + OV02B1B. VCM = DW9800
(mainline só tem dw9807 — checar). `qcom,sm7150-camss` existe no sm7150.dtsi;
nenhum dos sensores tem driver mainline. Formato dos sensormodule.bin
parcialmente mapeado (nós de 72 B, triplets por modo), slave addrs em claro
pendentes. Sysfs ao vivo: 4 sensores + 3 flashes + 4 EEPROMs com probe.
Próximo: fechar slot→modelo e slave addrs via blobs/driver 4.14; sem probe
ativo. (Seção de sensores abaixo está com outra IA — não editar.)

## Pedido mais recente — digital parada, investigar câmeras (26/10)

ATUALIZAÇÃO: usuário depois deixou câmeras de lado e pediu TESTAR SENSORES.
Levantamento parcial de câmera salvo em
docs/kernel/checkpoint-2026-10-26-cameras-parcial.txt. FPC segue encerrada.
Kit de teste ADSP/FastRPC em work/sensors-20261026/ssc-ram-test/: mesmo
kernel #6/DT e U-Boot perif-v5, registry/firmware e ferramentas em RAM.
Boot volátil iniciado; resultado ainda precisa ser coletado em run1/.

Usuário encerrou a investigação FPC. Última análise de protocolo, comandos,
ION/QSEECOM e limites foi registrada no início de
`docs/kernel/checkpoint-2026-10-26-fingerprint-fpc.txt`, com artefatos em
`work/fingerprint-20261026/hal-protocol/`. Nenhum comando ao leitor/TEE,
reset de GPIO ou escrita em partição foi executado. Não retomar digital
sem novo pedido. Frente atual: investigação de câmeras somente leitura,
começando pelo DT/logs/drivers e metadados Android; não iniciar captura.

## >>> ESTADO ATUAL — 26/10/2026 ~14h20 (comece por aqui)

Último par pmOS validado (volátil): U-Boot
`work/perif-20261026/v5/u-boot-hanoip-pmos-perif-v5.img` (DT
`sm7150-motorola-hanoip-pmos-perif.dts` = áudio + vibrador + flashes + LED +
NFC) + kernel #6 `work/perif-20261026/v6-qrtr/kernel-hanoip-pmos-7.3-qrtr.img`
(7.3 v2 + áudio + vibrador + correção do QRTR). GOLD v4 segue sendo o retorno
padrão; nada promovido, NADA COMMITADO (git só quando o usuário pedir).

**Retomada sensores, 26/10:** o usuário entrou no Android com root para
coleta. O ADB deixou de enumerar durante a análise seguinte, depois voltou
para a coleta FPC, sem reboot ou mudança no telefone. O firmware salvo permitiu
mapear SSC SE0/0x62680000 para ICM (pinos SSC0/1, I3C) e SSC SE4/0x62690000
para TMD2755 (SSC6/7, função4, I2C). Votos de alimentação: L7C=3312 mV,
L8C=1800 mV. `/dev/qup_ssc/11` é um conjunto DAL com seis engines; não prova
SE11 AP. Não repetir a variante/overlay AP a94000.

Extrator reproduzível e mapa em `work/sensors-20261026/ssc-mapping/`;
detalhes e limites em `docs/kernel/checkpoint-2026-10-26-sensores-ssc.txt`.
Próximo caminho a investigar: sensors PD pelo ADSP/FastRPC + libssc, com
filesystem/registry em RAM. O kernel já descreve FastRPC/ADSP e a lista de
pacotes pmOS tem libssc/iio-sensor-proxy; hexagonrpcd ainda falta nessa lista.
Isso pode reutilizar o driver TMD do DSP. Não é um teste já executado; não
instalar ou escrever em partições. Acesso AP direto ainda carece dos clocks
SCC, master I3C e resolução do stall anterior.

**Digital FPC investigada offline, 26/10:** dump Android confirma helper
FPC, IRQs e fpctzapp ativo. IRQ GPIO90, reset GPIO4, enable FPC GPIO29
(GPIO30 é a alternativa Chipone). Compatible fpc1020 não identifica o chip.
TA ARM32 importa qsee_spi_* e abre device lógico 1; devcfg torna SPI1/0x884000
o candidato forte, sem confirmação de enumeração QSEE/estado ao vivo. O
helper GPIO não captura imagens. Bloqueio principal: QSEECOM legado +
protocolo HAL/TA, não resolvido por carregar qcomtee moderno. Checkpoint em
`docs/kernel/checkpoint-2026-10-26-fingerprint-fpc.txt`; evidências e extrator
em `work/fingerprint-20261026/`. ADB voltou: HAL ARM64 e libs QSEE coletados;
vendor=fpc, modalias=fpc1020, irq=0, irq_cnt=60. HAL importa QSEECom_* e
contém string fpc1540, mas propriedade vendor.hw.fingerprint.hwid vazia;
modelo segue sem confirmação. Próximo passo local: interpretar o HAL.
Sem bases biométricas, comandos TEE ou alterações de GPIO. Debugfs de pinos,
clocks e reguladores indisponível; não montado. Android com root mantido.

Feito e validado nesta sessão:
- Alto-falante: pinos SSC do LPI (patch pinctrl), driver AW882xx, PipeWire
  (PulseAudio removido), UCM, rota por udev, WirePlumber S16LE, atenuação
  padrão 6 dB. Usuário ouviu. SEM proteção do alto-falante (plano abaixo).
- Botões de volume: PipeWire como serviço de usuário do OpenRC (antes perdia
  a corrida com o plasma-pa).
- Vibrador: 2 patches (teto qcom,vib-max-microvolt 3,0 V + byte alto da
  tensão); feedbackd vibra no perfil full.
- Lanterna: flash traseiro white:flash (canal 1) e frontal white:flash-1
  (canal 2) separados; botão do Plasma funciona com o flashlighthelper
  corrigido (bug do plasma-mobile 6.6.6).
- LED de notificação: existe, branco, no TRILED canal 1 (white:status);
  feedbackd detecta e programa hw_pattern com o tema motorola,hanoip.json.
  FALTA o usuário confirmar o piscar visualmente.
- NFC: nxp-nci lê cartão (ISO14443-A); falta app (sem neard).
- Wi-Fi intermitente: corrida do QRTR (upstream 544d85de4dc2) corrigida no
  kernel #6 (patch ns.c, retry em -EAGAIN); 1 boot bom; confirmar em mais.
  Logs de cada boot em /var/log/hanoip-boot/ (coletor local.d).

Próximos passos sugeridos: (1) confirmar LED e Wi-Fi em mais boots;
(2) carga da bateria — PRECISA de autorização explícita (escreve no PMIC);
(3) proteção do alto-falante (driver com teto + monitor vendor, IV,
speakersafetyd, filtro PipeWire); (4) suspend, 90/120 Hz, sensores.
README "O que falta" atualizado em 26/10 ~14h20.

**Sensores — tentativa interrompida após travamento (26/10):**
O U-Boot sensor-v1, com SE11 habilitado no DT, parou no “M” e não reenumerou
USB. Não usar esse U-Boot. Com U-Boot v5 conhecido, o initramfs RAM-only
iniciou; sua tela preta era intencional e o DT efetivo manteve SE11 disabled.
Uma segunda tentativa aplicou um overlay de runtime para habilitar somente
SE11. `geni_i2c` começou o probe a 100 kHz, mas o `insmod` não retornou e o
kernel entrou em RCU stall; CPU4 não respondeu ao NMI. Nenhuma leitura dos IDs
0x68/0x75 ou 0x39/0x93 foi feita. Não repetir o overlay nem habilitar outros
SEs/rails até analisar o log e mapear o controlador/rails no Android.

**Atualização Android root (26/10):** coleta somente leitura confirmou
SensorService operacional: ICM4x6xx acelerômetro/giroscópio e TMD2755
ALS/proximidade estão disponíveis; há eventos recentes do acelerômetro e
proximidade. O sysfs Android expõe AP I2C0 (`888000`), I2C1 (`a84000`) e I2C2
(`a8c000`), não `a94000`; `/dev/i2c-0..2` existem e `/dev/qup_ssc` não. Os
GENI QUPs `8c0000` e `ac0000` estão registrados, mas não há prova de que
`bus_instance=1/5` do registry do SSC mapeie para algum deles ou para SE11.
Logo, `/dev/qup_ssc/11` no firmware ADSP não justifica habilitar AP `a94000`.
Registry confirma ICM 0x68/IRQ86/`sensor_vddio` e TMD 0x39/IRQ89/
`sensor_vdd`+`sensor_vddio`. Dumps e configs em
`work/sensors-20261026/android-live-readonly/`; resumo em
`docs/kernel/checkpoint-2026-10-26-sensores-preparado.txt`. Próxima etapa é
mapear offline a ligação SSC↔QUP/GPIO; não fazer scan ou escrita de registrador.

Recuperação feita pelo usuário ao bootloader; restaurado o par conhecido
U-Boot `work/perif-20261026/v5/` + kernel #6
`work/perif-20261026/v6-qrtr/`. SSH, DSI conectado 1080x2460 e wlan0 up
confirmados após retorno. Evidências em
`docs/kernel/checkpoint-2026-10-26-sensores-preparado.txt` e
`work/sensors-20261026/se11-runtime-overlay-v2/screenlog.0`.

## >>> RETOMAR AQUI — áudio do alto-falante, fases 1-3 (26/10/2026, madrugada)

**CAUSA DO WI-FI INTERMITENTE ACHADA E CORRIGIDA (26/10 ~14h05):** no boot ruim,
13 ms após "modem is now up", o kernel loga "failed to announce new service"
(net/qrtr/ns.c). Upstream 544d85de4dc2 "net: qrtr: Send HELLO message on
endpoint register" (no 7.3) manda o nosso HELLO por delayed work e recusa
pacotes não-HELLO com -EAGAIN até ele sair; se o HELLO do modem chega antes,
announce_servers() desiste no -EAGAIN e (o NS não responde mais HELLO)
ninguém reanuncia rmtfs/tqftpserv/pd-mapper -> modem espera até o DOG.
Revert não aplica limpo (6a5719cc3ef2 MHI resume depende). Correção:
6371514d320e "net: qrtr: ns: wait for the HELLO before announcing servers"
(retry em -EAGAIN, 20 ms x 50). Kernel #6 em work/perif-20261026/v6-qrtr/
(kernel-hanoip-pmos-7.3-qrtr.img + u-boot-hanoip-pmos-perif-v5.img) = PAR
ATUAL. 1 boot validado (wlan0 em 4 s, 0 "failed to announce"); validar mais
boots. Patches (qrtr + 2 do vibrador) em work/perif-20261026/patches/.
LED de notificação: white:status (LPG canal 1, TRILED sink 1), feedbackd
reconhece (FEEDBACKD_TYPE=led, trigger pattern), tema
overlay/usr/share/feedbackd/themes/motorola,hanoip.json (eventos de LED em
branco) instalado, mas o fbcli ainda NÃO acendeu o LED — investigar.

**Wi-Fi/modem intermitente (26/10 ~13h45):** em 2 boots (perif v3 e v3-nonfc)
o modem travou com "dog_hal_common.c:173: DOG detects stalled
initialization" ~40 s após subir; wlan0 não aparece. No boot ruim o modem
NUNCA falou com rmtfs/tqftpserv/pd-mapper (rmtfs.log só "registering
services"); no boot bom (v3, mesmo par) abre modem_fs1/2/fsg e o ath10k faz
QMI 1 s depois. Não é o NFC (falhou sem ele). Religar o modem depois do crash
também falha (não conclusivo). Coletor /etc/local.d/hanoip-bootlogs.start
(overlay) guarda os logs dos últimos 10 boots em /var/log/hanoip-boot/ 90 s
após o boot; snapshot do boot bom: *-bom. Analisar o próximo boot ruim por lá.
Perif v3 = flash traseiro white:flash (canal 1, 150 mA, lanterna do Plasma) +
frontal white:flash-1 (canal 2, 100 mA, flash 500 mA); vibrador com fix do
byte alto (0x5341 ficava 0: `level << 8` -> `>> 8`) e teto 3,0 V
(qcom,vib-max-microvolt); FF máximo = 2636 mV. Lanterna do Plasma: helper KAuth
do plasma-mobile 6.6.6 tinha use-after-free (segfault); binário corrigido
(fonte do commit ad036102) em work/perif-20261026/flashlighthelper/ e no
overlay. feedbackd: perfil full toca e vibra.
NFC VALIDADO lendo cartão: DEV_UP + START_POLL pela netlink
(work/perif-20261026/tools/nfcpoll.py) detectou ISO14443-A, SENS_RES 0400,
SEL_RES 0x20, ID de 4 bytes (não gravado), 8 IRQs. Falta userspace (sem neard
no Alpine). tools/vib.py = teste de vibração por FF_RUMBLE.

**Periféricos 26/10 ~13h20 — work/perif-20261026/v1/** (U-Boot DT
`sm7150-motorola-hanoip-pmos-perif.dts` = audio3 + vibrador + flash 2 canais
+ NFC; kernel = fase3b #5, sem mudança). VALIDADO: vibrador (pm8xxx_vib, 3
pulsos sentidos), flash canais 1+2 (300 mA total, usuário viu), NFC PN54x
(nxp-nci-i2c no i2c@888000 0x28; DEV_UP pela netlink ok, 4 IRQs no GPIO37;
deixado DOWN). Botões: kernel entrega KEY_VOLUMEUP/DOWN; o Plasma não mudava
o volume porque o PipeWire do autostart subia depois do plasma-pa ("Failed to
connect context"). Correção: pipewire, pipewire-pulse e wireplumber como
serviços de usuário do OpenRC (~/.config/rc/runlevels/default; build-rootfs
atualizado). /etc/user/init.d/wireplumber do Alpine tem `depends()` (typo),
o supervise-daemon compensa. Pendente: vibrador vai até 3,544 V no driver
mainline (Android 3,0 V sem overdrive) — limitar depois; NFC sem userspace
(sem neard no Alpine).

**Atualização 26/10 tarde — fase 3b (work/audio-20261026/fase3b/, kernel #5):**
causa do NOCLKS achada. Os pinos da SEC_MI2S são os gpio8-11 do VENDOR, em
0x62b48000 (faixa SSC); o `lpass_tlmm` mainline começa em 0x62b52000 =
gpio18 do vendor (mainline gpioN = vendor gpioN+18). O patch 0001 antigo
pôs as funções nos pinos errados (DMIC/reset WCD934x) — REMOVIDO. Novo
commit no container: variante "qcom,sm7150-lpass-lpi-ssc-pinctrl" que mapeia
só os 4 blocos (0x62b48000, 0x4000), pinos ssc_gpio8-11; nó novo no
...-pmos-audio2.dts. Resultado: SYSST 0x0311 (clock+PLL, igual ao Android),
tom tocado 3x. ATENÇÃO: ler a faixa SSC inteira via /dev/mem TRAVOU o SoC
(usuário forçou o bootloader) — nunca acessar MMIO por /dev/mem.
Decisão do usuário: usar PipeWire (tirar o PulseAudio).
USUÁRIO OUVIU o tom no alto-falante (aplay hw:0,0, atenuação 6 dB).
PipeWire: `apk add postmarketos-base-ui-audio-backend-pipewire` (purga
pulseaudio, entra pipewire-pulse/pipewire-alsa); matar o pulseaudio velho
pelo PID antes de relançar. UCM mínimo no overlay
(usr/share/alsa/ucm2/conf.d/sm8250/"Motorola Moto G60.conf" +
Motorola/hanoip/HiFi.conf, verbo HiFi, dispositivo Speaker, hw:G60,0) =>
sink alsa_output.platform-sound.HiFi__Speaker__sink padrão. Regra udev
99-hanoip-speaker-route + /usr/libexec/hanoip-speaker-route liga a rota
(precisa rodar depois do alsactl restore; RUN do eudev não aceita aspas).
build-rootfs.sh ganhou o backend pipewire + alsa-utils. i2c-tools foi
instalado no telefone só para diagnóstico. SYSST 0x4011 (UVLS) na partida é
transitório; o driver do vendor usa a mesma checagem CLKS+PLLS.
VOLUME BAIXO RESOLVIDO: o PipeWire abria o PCM em s24-32le e o caminho q6asm
toca ~48 dB mais baixo nesse formato (sensores ISNDAT/VSNDAT do amp: ±0x2c
contra ±0x2a00). Regra WirePlumber no overlay
usr/share/wireplumber/wireplumber.conf.d/51-hanoip-speaker.conf força S16LE;
usuário confirmou "mega alto". Causa no q6asm/ADSP com S24_LE ainda não
investigada (bug a anotar/corrigir no kernel).
ESTADO PARA O PRÓXIMO BOOT (26/10 ~13h): par com som = fase3b
(u-boot-hanoip-pmos-audio-f3b.img + kernel-hanoip-pmos-7.3-audio-f3b.img,
kernel #5); com o par v2 não há placa de som (sem ADSP no DT), o resto do
rootfs funciona igual. Rootfs já tem: PipeWire (pulseaudio purgado), UCM,
regra udev da rota, WirePlumber S16LE, /lib/firmware/aw882xx_spk_reg.bin
(vendor, NÃO está no build-rootfs: copiar à mão num rootfs novo), e
/etc/modprobe.d/hanoip-speaker.conf com attenuation_db=6 (padrão do driver
continua 18). Os módulos 7.3 no rootfs são do build #4; aw882xx.ko não mudou
no #5 (só o pinctrl built-in). Usuário pausou o som: retomar quando pedir.

PLANO DE PROTEÇÃO DO ALTO-FALANTE (combinado com o usuário, fazer nesta ordem):
1. Driver: controle ALSA "Speaker Volume" com teto + port do monitor do
   vendor (DT stock: low-vol-table-down 3200/3400/3600 mV -> -4.5/-3/-1.5 dB,
   up 3700/3500/3300; low-temp-table por temperatura do chip, frio; período
   3000 ms; VBAT = reg0x12*6025/1023 mV; ipeak normal 9). Evita brownout
   com bateria baixa (carga ainda desligada).
2. IV sense: ligar a saída IV do amp (linha data1, SEC_MI2S_TX/AFE 0x1003),
   capturar pelo ADSP, descobrir formato, validar R ≈ 6,8 Ω (Re padrão 27852;
   calibrado 27149 está no persist — montar só com autorização).
3. speakersafetyd (pacote Alpine existe, v2.0.0): config hanoip com
   parâmetros térmicos conservadores, adaptar controles (vsense/isense/
   amp_gain) no driver; depois medir tau/tr do alto-falante e refinar.
4. PipeWire filter-chain: passa-alta ~250-300 Hz + limitador (lsp-plugins-lv2
   disponível; conferir plugins builtin do filter-graph).
Pendentes: controle de volume ALSA no driver (hoje só o parâmetro
attenuation_db, padrão 18 dB), proteção/calibração, fase 4 (WCD937x).

Usuário deixou o celular DESCONECTADO para voltar amanhã. Nada commitado
(git só quando o usuário pedir). Tudo em `work/audio-20261026/`.

Cadeia: app -> MultiMedia1 (q6asm) -> SEC_MI2S_RX (q6afe, LPI GPIO8-11) ->
amplificador Awinic AW882xx (I2C2 = SE 0x888000, 0x34, reset GPIO43,
chip ID 0x1852) -> alto-falante. Android: 48 kHz S16_LE mono, dados na
linha 0, retorno IV na linha 1; mixer "SEC_MI2S_RX Audio Mixer
MultiMedia1" = On (mesmo nome no mainline).

- Fase 1 VALIDADA: DT `sm7150-motorola-hanoip-pmos-audio.dts` = pmos +
  &remoteproc_adsp (firmware qcom/sm7150/motorola/hanoip/adsp.mdt, de
  modem_a). ADSP running, PDR audio_pd up, APR q6core/q6afe/q6asm/q6adm,
  LPASS LPI pinctrl saiu do probe adiado. fase1/.
- Fase 2 VALIDADA: kernel com patch 0001 (LPI pinctrl: funções
  sec_mi2s_sclk/ws/data0/data1 nos GPIO8-11, slots do vendor; qdss_cti
  removido) + DT `...-pmos-audio2.dts` (placa sm8250 "Motorola Moto G60",
  dai@0 MultiMedia1, dai@18 SECONDARY_MI2S_RX sd-lines 0, pinos LPI
  16 mA). Codec placeholder `linux,spdif-dit`: qcom_snd_parse_of só faz
  backend com platform+codec. Rota ligada + `aplay -D hw:0,0 -f S16_LE
  -r 48000 -c 2 /dev/zero` OK, q6afe_i2s_port_prepare sd_line_mask=0x1.
  fase2/ (kernel-hanoip-pmos-7.3-audio-f2.img + u-boot...-f2.img).
- Fase 3 PRONTA, NÃO TESTADA: patch 0002 = driver mínimo
  `sound/soc/codecs/aw882xx.c` (snd-soc-aw882xx, compat
  "awinic,aw882xx"): carrega `aw882xx_spk_reg.bin` (pares LE reg/val, igual
  aos registradores lidos no Android tocando) forçando PWDN=1/HMUTE=1 e
  atenuação attenuation_db=18; ao tocar: I2SCTRL/PLLCTRL1 conforme
  hw_params, PWDN=0, exige SYSST CLKS+PLLS, então HMUTE=0; ao parar mute +
  PWDN. Sem a proteção de alto-falante do ADSP. DT `...-pmos-audio3.dts`.
  fase3/ tem: u-boot-hanoip-pmos-audio-f3.img, kernel-...-audio-f3.img
  (mesmo Image da fase 2), modules-7.3.0-sm7150.tar.gz (com aw882xx),
  aw882xx_spk_reg.bin (do vendor; NÃO commitar).
- Próximo, ao religar: bootar v2 (ou fase 3), instalar o tarball de
  módulos da fase3 com install-rootfs-7.3.sh (EM PRIMEIRO PLANO, sem &),
  copiar aw882xx_spk_reg.bin para /lib/firmware/ do rootfs, reiniciar na
  fase 3, conferir probe do aw882xx (ID 0x1852), ligar a rota e tocar um
  tom BAIXO; subir a atenuação devagar. Depois: PipeWire/WirePlumber e
  PulseAudio rodam juntos (escolher um), mixer padrão/UCM, fase 4 (WCD937x
  fone/microfone + fsa4480).
- Fontes: patches/ (sobre a série v2) e o branch hanoip-7.3-audio no
  container hanoip-kernel73; referência GPL em aw882xx-ref/ (LineageOS
  motorola sm7250). Armadilha: label sec_mi2s_active já existe no TLMM
  principal (gpio57); o nosso é hanoip_sec_mi2s_active.

## Retomada atual — 7.3 v2 com os PRs #70/#64/#65/#60 do fork (26/10/2026)

O telefone roda `work/kernel-7.3/v2/` (ler README.txt): v1 + 4 PRs abertos do
sm7150-mainline (160 patches sobre v7.3, reprodutível). Bateria: drivers
novos de QG/SMB5 carregados e coerentes (52%, ~-160 mA com brilho máximo,
status pelo carregador); carga segue desligada. Áudio: nós LPASS/SoundWire
no sm7150.dtsi (base para o WCD937x + aw882xx do hanoip), desligados e fora
do DT do U-Boot. Fork sem commits novos; branches next*/audio-wip são
rascunhos antigos. PRs #66/#69 já estavam cobertos; #58/#52 superados.
Armadilha: em `sh`, `cmd ... &` recebe stdin de /dev/null (o tar falhou e o
/lib/modules/7.3.0 foi apagado antes; reinstalado). Nunca apagar antes de
extrair.

Estado no fechamento de 26/10/2026: telefone ligado na v2 (7.3), pmOS +
Plasma, Wi-Fi e BT ativos; rootfs com /lib/modules 7.1.0 (GOLD v4) e 7.3.0
(v2). README.md reescrito com o estado atual (sem os exemplos de flash).
Tudo no `main` do GitHub. Container `hanoip-kernel73` mantém a árvore 7.3
(branch hanoip-7.3-prs = v2). Próximos passos sugeridos: ligar a carga da
bateria (precisa de autorização: escreve no carregador do PMIC) ou começar o
áudio (WCD937x + aw882xx no DT do U-Boot). GOLD v5 só se o usuário promover.
Coleta Android de 25-26/10 em `work/android-dump-20261026/` (LEIA-ME.txt):
mapa I2C/SPI (NFC NXP NQ e aw882xx no I2C0/SE 0x888000, SAR no I2C1/SE
0xa84000), carga ao vivo (500 mA SDP, FCC 3,6 A, FV 4,45 V, sem PD), rota do
alto-falante (SEC_MI2S -> aw882xx, regs tocando), vibrador PM6150 0x5300,
config do kernel Android. Microfone não coletado. O hanoip TEM NFC.
Commit pendente: um lote está no stage desde 26/10 (init/overlay pmOS,
U-Boot pmOS, touch .ko, logs do rootfs, patches do SD). O push foi barrado
pelo classificador (dados vindos do telefone, repo público); o usuário
decide se sobe tudo, só código ou nada.
Engasgos no Plasma (26/10): causa = devfreq da GPU (simple_ondemand, piso
180 MHz, poll 50 ms) oscilando entre mínimo e máximo (124 trocas em 20 s).
Fixar 800 MHz sumiu com eles; piso 355 MHz + poll 16 ms deu o mesmo
resultado (usuário confirmou). Serviço OpenRC `hanoip-gpu-tune` (boot) no
rootfs e no overlay. Medições em work/jank-20261026/. Pendente opcional:
KWin roda sem tempo real (SCHED_OTHER; falta CAP_SYS_NICE no binário ou
rtkit) — `setcap cap_sys_nice+ep` reaplicado a cada upgrade do kwin.
Fluidez (26/10, validado pelo usuário): serviço OpenRC `hanoip-perf-tune`
(boot, rootfs + overlay; não commitado ainda — git só quando o usuário
pedir). Engasgos no Plasma = devfreq da GPU (simple_ondemand, piso 180 MHz,
poll 50 ms, 124 trocas em 20 s): piso 355 MHz + poll 16 ms = igual a 800 MHz
fixo. Travadas ao abrir apps = I/O (UFS em 50 MHz ~70% do tempo, ~184 ms de
PSI io, angelfish em estado D, 32% iowait): UFS fixa em 200 MHz. Medições em
work/jank-20261026/. Pendente opcional: loop7 com direct I/O e read-ahead
maior (hoje dio=0, 128 KB), zram (não sobe), KWin sem tempo real
(SCHED_OTHER; falta CAP_SYS_NICE/rtkit).
Brilho e calor (26/10): faixa quente perto do USB = backlight em 100% (622 mA
total a 100%, 382 a 50%, 262 a 25%, sistema ocioso). Hardware igual ao
Android: 3 fileiras ativas (sink 0xd946=0x70), 25 mA/fileira, sem falhas
(0xd808=0); o 100% do Android também é 450 nits; o padrão dele é ~26%.
Serviço `hanoip-brightness` (boot) volta o brilho salvo do KWin para 0,6.
BUG ANOTADO (mainline 7.3, qcom-wled.c, wled5_setup): grava a corrente das
fileiras com WLED4_SINK_REG_STR_FULL_SCALE_CURR (0x52+n*0x10) em vez de
WLED5_..._FULL_SCALE_CURR (0x72+n*0x10). No hanoip não afeta hoje (fileiras
0/1 recebem 25 mA por coincidência, a 2 vem do ABL). Afetaria quem mudar
qcom,current-limit-microamp, ligar só 3 fileiras, ou bootar sem o ABL.
Correção de uma linha; o usuário pediu só para anotar.
Discover "sem internet" (26/10): faltava o catálogo AppStream
(/var/lib/swcatalog vazio). Instalado `alpine-appstream-downloader` e
baixado o catálogo main+community; também no build-rootfs.sh.
Apps básicos (26/10): Dolphin, Ark, Kalk, KClock, KWeather, Koko, Elisa,
Haruna, Okular, Calindori, Plasma Phonebook, KRecorder, Spectacle, Firefox +
mobile-config-firefox (também no build-rootfs.sh; rootfs com 1,5 GB livres). SEGURANÇA: o Plasma Mobile traz udisks2, que listava as
109 entradas da UFS/loop para montagem pela interface; regra
`/etc/udev/rules.d/61-hanoip-udisks-ignore.rules` (overlay também) põe
UDISKS_IGNORE/UDISKS_AUTO=0 em sd* e loop*: 0 visíveis, RO intacto.
Lista completa e agrupada do que falta: seção "O que falta" do README.md
(inclui hardware visto no DT do Android: FPC1020, SX933x, vibrador do PMIC,
flash/tri-LED, 4 câmeras, fsa4480; painel com modos de 90/120 Hz).

## Kernel migrado para o Linux 7.3 mainline (25/10/2026, noite) — v1

Variante validada em dois boots: `work/kernel-7.3/v1/` (ler README.txt).
Base upstream v7.3 (c03c1a14) + 128 patches em `work/kernel-7.3/v1/patches/`
(117 do fork sm7150-mainline "v7.2", 11 do hanoip, 1 fix do qcom_qg para o
namespace IIO_CONSUMER). Boot só volátil:
  fastboot boot work/kernel-7.3/v1/u-boot-hanoip-pmos-v1.img
  fastboot boot work/kernel-7.3/v1/kernel-hanoip-pmos-7.3-v1.img
Mesmo U-Boot/DT e mesmo rootfs da GOLD v4; o rootfs tem /lib/modules 7.1.0 e
7.3.0 lado a lado (hanoip-touch agora usa modprobe), então a GOLD v4 continua
bootando igual. Tudo funcionou no 7.3: display (DSI irqs=0), KWin OpenGL,
touch follower, Wi-Fi, BT, UFS RO, CPUfreq 0-7, sem Oops/WARNING; LP/lado A
do super conferidos idênticos. GOLD v4 segue como retorno padrão até o
usuário promover outra. `kernel-mainline/` continua sendo a fonte do 7.1
(GOLD v4); a fonte do 7.3 é a série de patches.

Ambiente: container `hanoip-kernel73` (imagem hanoip-kernel-builder, COM
rede) tem /tmp/linux-7.3 (branches hanoip-7.1 e hanoip-7.3, config em
/tmp/config-7.3-hanoip). No container o GitHub trava no git (kernel.org ok):
o fork entrou por bundle. Repositórios de análise no Mac:
work/kernel-7.3/linux.git (parcial; NÃO usar para format-patch, os
lazy-fetch falham) e fork-full.git (completo, 118 commits). O helper
boot-volatile.py grava um .json ao lado da imagem: bootar GOLD a partir de
uma cópia (work/kernel-7.3/gold-v4-boot/), nunca da pasta GOLD.

## >>> GOLD ATUAL v4: work/GOLD-20261025-1659/ — pmOS + Plasma Mobile no `super` (25/10/2026 ~16:59 -03)

Promovida pelo usuário. Substitui a GOLD v3 (`work/GOLD-20261025-1203/`) como
retorno padrão; v3, v2 (1047) e a primeira (0126) ficam preservadas. Ler
`GOLD.txt` e `SHA256SUMS` da pasta (somente leitura; nunca modificar).

Boot (SÓ volátil, nunca flash):
  fastboot boot work/GOLD-20261025-1659/u-boot-hanoip-pmos-v1.img
  fastboot boot work/GOLD-20261025-1659/kernel-hanoip-pmos-super-v1.img
Plasma Mobile em ~37-40 s; usuário `user` (uid 10000, PIN definido pelo
usuário no telefone; não registrar aqui). SSH root@172.16.42.1 por chave.

Regra nova (ver AGENTS.md): rootfs gravável SÓ na região não alocada do fim
do `super` (sdb23), espaço do grupo do slot B (slot ativo = A):
offset 5160 MiB (byte 5410652160), 5120 MiB, ext4 `hanoip_pmos`; último
extent LP (vendor_a) termina em 5153,88 MiB. Metadados LP e volumes `_a`
nunca são gravados (hashes antes/depois em baseline-super.txt e
write-*-run.txt). Durante o pmOS só sdb/sdb23 ficam graváveis; os outros 82
blocos ficam RO por flag próprio + guard. OTA do Android apagaria o pmOS.

Como funciona:
- Kernel #10 (Image fa6d0e1c…), mesmo kernel/DTB da telemetry-v1. Ramdisk =
  telemetry-v1 + `/etc/hanoip/boot-pmos` + `/sbin/pmos-root`
  (`scripts/hanoip-pmos-root.sh`): estágio 1 sobe display/USB/UFS RO/Wi-Fi/BT/
  bateria, confere hash LP e ext4 no offset, monta `/dev/loop7` rw, move
  /dev /proc /sys /run e /mnt/ro/* e faz `switch_root` para o OpenRC.
  rmtfs/tqftpserv/pd-mapper/udhcpd e o guard RO do estágio 1 continuam vivos.
- U-Boot: .config da telemetry-v1; DT `sm7150-motorola-hanoip-pmos.dts` =
  battery-diagnostic + `panel = <&panel>` no touch (única diferença).
- Touch `ilitek-hanoip-spi`: o TDDI perde a IRAM quando o painel desliga;
  driver é panel follower (recarrega IRAM em panel_enabled via work, desliga
  IRQ em panel_disabling; `stats` tem `restarts`). Validado com botão power.
- /lib/modules: 828 módulos da árvore #10 (Image idêntico; vmlinux
  inalterado; sem zstd) + 43 validados em `updates/`. Blacklist de autoload
  (`/etc/modprobe.d/hanoip-blacklist.conf`): icc_bwmon (sync_state do
  interconnect pode tirar banda do MDSS), pinctrl_sm7150_lpass_lpi, qcomtee,
  simple_pm_bus. Autoload validado: joydev, qcom_rng, qcom_spmi_temp_alarm,
  qcom_stats, rpmsg_ctrl.
- polkit tem que ser `polkit-elogind` (o `polkit-noelogind-libs` não vê a
  sessão: brilho, Discover e NetworkManager falhavam).
- Wi-Fi: NetworkManager dono do wlan0, wpa_supplicant ativado por D-Bus (sem
  serviço OpenRC nem ifupdown), sem MAC aleatório, usb0 unmanaged. AP
  WPA2/WPA3: NM sempre oferece SAE, que exige a senha em si (PSK hex não
  basta); a senha fica só no .nmconnection 600 do telefone.
- Bluetooth: serviço `hanoip-firmware` (boot) recria os links /lib/firmware
  para /mnt/ro/{modem_a,bluetooth_a}; rfkill block/unblock refaz o setup QCA.
  NUNCA dar unbind em hci_uart_qca (Oops em qca_power_off).
- Seat: no primeiro boot após instalar elogind, as tags udev só aparecem com
  novo trigger; imagens novas já nascem com as regras.
- Instalados: Plasma Mobile, QMLKonsole, Discover (backend apk).

Reprodução: `work/pmos-super-20261025/build-rootfs.sh` (+ overlay/ e
modules-7.1.0-sm7150.tar.gz) recria o rootfs completo do zero (rebuild
verificado em pmos-super-rootfs-v2.img, não gravado). O user sai bloqueado:
`passwd user` no telefone; rede Wi-Fi pelo Plasma. A GOLD também tem
`rootfs-snapshot.tar.gz` do rootfs vivo SEM segredos (senha do Wi-Fi conferida
ausente) e `shadow.sanitized`.

Observado: SoC até ~74 °C sob carga (gzip), 62-70 °C em uso; bateria
descarrega mesmo no cabo (3,84 V, -109 mA, estimativa 56%->44% na sessão).

Pós-GOLD v4 (aplicado no rootfs do telefone e no build, não na pasta GOLD):
guard RO passou do poll de 0,1 s para udev. Regra
`/etc/udev/rules.d/60-hanoip-blockdev-ro.rules` faz `blockdev --setro` em todo
sd* em add/change, exceto o disco sdb e a partição PARTNAME=super; serviço
`hanoip-ro-handoff` (sysinit, após udev) reafirma RO, confere e só então mata
o loop do estágio 1 (/run/hanoip-ufs-readonly.pid). `udevadm test` e trigger
change conferidos; 84 blocos, graváveis só sdb/sdb23. CPU em repouso 13,4% ->
0,2%; pico térmico 62-70 -> 42 °C. Kernel/ramdisk da GOLD inalterados (o loop
ainda roda até o switch_root).

Pendências, em ordem sugerida: carregamento da bateria (hoje desabilitado de
propósito); FIFO DSI intermitente na partida; suspend/resume; nftables no kernel;
áudio, modem/telefonia, câmera, sensores. Touch polish segue adiado.
No zsh, não guardar opções do ssh numa variável ($O não faz word-split).
Nada commitado.

## Histórico — telemetria de bateria/carregador (25/10/2026)

Telefone ligado na variante volátil `work/battery-20261025/telemetry-v1/`.
Ela deriva do kernel #10 e da base `display-v2`, com o display, rede USB,
Wi-Fi/BT, CPU0-7 e UFS somente leitura preservados. O novo DT ativa o gauge
PM6150 e um driver SMB monitor-only: lê USB/bateria sem configurar o carregador,
alterar limites, habilitar carga ou registrar callbacks de escrita. SDAM está
read-only (`force_ro=1`); 84 dispositivos de bloco continuam RO.

Leituras observadas: bateria ~3,91 V, ~31 °C e 56–57% estimados pelo driver a
partir da tensão (não é SOC calibrado); carregador USB presente, ~5,07 V,
`online=1`, status `Not charging`, limite reportado 500 mA. Corrente da bateria
em repouso ficou perto de zero e respondeu a uma carga diagnóstica curta:
−169 a −228 mA na bateria e ~495–498 mA na USB, retornando a zero após a carga.
Temperatura máxima do SoC foi 74,5 °C; display permaneceu ativo, DSI irqs=0,
tainted=4096 apenas por módulos externos, todos os blocos RO. Isso valida
telemetria e resposta do sensor, não carregamento. Ativar/regular carga,
JEITA/USB-PD e validar SOC seguem pendentes, porém adiados por decisão do
usuário (abaixo).

Checkpoint: `docs/kernel/checkpoint-2026-10-25-battery.txt`; detalhes, logs,
fontes de módulos e hashes em `work/battery-20261025/telemetry-v1/`.
GOLDs e a variante display-v2 permanecem preservadas; nada foi gravado no
telefone.

### Decisão de 25/10/2026 e próximo passo

Controle de carga fica adiado por decisão do usuário: não habilitar
carregamento, política JEITA, USB-PD nem SOC calibrado por enquanto. A
variante `telemetry-v1` continua só como instrumentação passiva e referência.

Próximo passo: estabilidade prolongada do par atual, sem mudar
kernel/DT/ramdisk. Usar a `telemetry-v1` (mesmo kernel do display-v2) e
amostrar periodicamente DSI FIFO (contadores e snapshot de registradores),
tainted, diff de dmesg, temperaturas, CPUfreq/idle, memória, supplies de
bateria/USB, estado RO dos 84 blocos e resposta de serial/SSH. Aprovar se não
houver Oops/WARNING/SMMU/DSI fault, a tela continuar correta (checagem visual,
sem LP DCS), os contadores DSI ficarem estáveis após o boot, nenhum bloco RO
mudar e a temperatura ficar abaixo de 80 °C. Abortar diante de tela preta,
taint novo, erro de I/O ou perda de serial/SSH. Isso fecha a base antes de
retomar o FIFO intermitente de partida e, só depois, suspend/resume (segue
adiado). Sem flash, sem escrita em partição, sem montar UFS e sem carga
controlada.

Frente offline paralela (25/10): levantamento de sensores — ver a seção
"Sensores" abaixo.

## Histórico — sensores: levantamento offline (25/10/2026)

Trabalho somente de análise, sem teste no aparelho. Identificados o
acelerômetro/giroscópio TDK InvenSense `icm4x6xx` em 0x68 e o ALS/proximidade
ams `tmd2755` em 0x39; não há magnetômetro ativo (bússola indisponível). No
Android os dois rodam no ADSP (lpass, `62400000.qcom,lpass`), via adsprpc; não
existe nó deles no DT da AP. O registry do SSC guarda só bus_instance 1 e 5,
IRQ DRI 86 e 89 e os rails `sensor_vdd`/`sensor_vddio` (clientes do PMIC vistos
pelo ADSP). O firmware do ADSP contém `sns_icm4x6xx`, `sns_tmd2755` e a única
referência física encontrada, `/dev/qup_ssc/11`.

No mainline, `inv_icm42600` cobre ICM42600/42602/42605/42622/42631/42686/42688
(falta saber qual é a variante do aparelho), mas o **TMD2755 não tem driver** —
será preciso escrever um driver IIO de ALS/proximidade. O bloqueio principal é
descobrir o SE/QUP físico, os GPIOs do barramento e o GPIO de IRQ. Próximo
passo, quando houver teste: habilitar um SE por vez (começando por SE11
`a94000`, GPIO101/102, citado no firmware) e fazer scan somente leitura de
0x68/0x39 + WHO_AM_I. Não tocar SE3 `88c000` (console) nem SE2/SE7 (NFC/SAR).
O BusyBox do ramdisk não tem i2cget; será preciso utilitário próprio ou U-Boot.

Ver `docs/kernel/checkpoint-2026-10-25-sensores.txt` e
`work/sensors-20261025/` (configs do registry, configs do vendor, overlays GPL
da Motorola e SHA256SUMS). Nada foi executado e nenhuma partição foi tocada.

## Histórico — SD: tentativa de 25/10 parada por segurança

Habilitado `sdhc_2` no kernel #1 (`CONFIG_MMC_SDHCI_MSM=y`) e no DT embutido do
U-Boot (o kernel usa o DTB do U-Boot via `boot_with_embedded_fdt`), com pinctrl
`sdc2`, `vmmc` L9C, `vqmmc` L6C e CD no GPIO69. Sem cartão o controlador sobe
limpo: `sdhci_msm 8804000.mmc: Got CD GPIO`, `mmc2 ... ADMA 64-bit`, IRQ de CD
registrada, display normal. Logs em `work/sd-20261025/run1/`.

O dump Android foi coletado **sem cartão** (`LEIA-ME.txt`: "sem cartão
inserido no momento da coleta"; `mmc_cards.txt` vazio), então não existe
identidade de cartão extraída para comparar. A única referência extraída é o DT
stock: L9C 2,95 V, L6C 1,8/2,95 V, CD GPIO69.

A configuração atual repete a condição de 2026-08-22 documentada como
arriscada: o mainline pede 3,3 V para `vqmmc` (L6C máximo 2,95 V) e deixa
`vmmc` em 3,3 V; as tentativas com cartão travaram o boot e queimaram um cartão.
**Não inserir cartão nesta variante.** Antes disso é preciso portar
`qcom,vdd-io-voltage-level` (1,8/2,95 V, nunca 3,3 V) ou fixar vmmc/vqmmc em
2,95 V e validar sem cartão. O par de retorno seguro continua sendo
`work/GOLD-20261025-1203/` ou a `telemetry-v1` (SD desabilitado).

Atualização 25/10 (tarde): `v2/` (LDO9 fixo em 2,95 V, fallback de vqmmc
em `drivers/mmc/core/regulator.c`, caps 2,7–2,95 V em `sdhci-msm.c` e
`cd-gpios` trocado para ACTIVE_HIGH) deu tela preta sem USB/serial/fastboot,
SEM cartão. Suspeita: com ACTIVE_HIGH o GPIO69 alto (vazio, visto no v1) vira
"cartão presente". `v3/` = v2 com só o `cd-gpios` de volta a ACTIVE_LOW
(DTBs alterados em 1 byte; DTS fonte corrigidos) também falhou segundo o
usuário, sem log. **SD descartado por ora por decisão do usuário**. Os patches
MMC, a linha do Makefile e os dois sd-diagnostic.dts saíram do working tree
em 25/10 e estão salvos em `work/sd-20261025/saved-patches/` (LEIA-ME.txt).

O driver downstream foi analisado em
`docs/kernel/checkpoint-2026-10-25-sd-downstream.txt` e
`work/sd-20261025/downstream/`: ele lê `qcom,vdd-voltage-level` e
`qcom,vdd-io-voltage-level`, liga vdd/vdd-io em 2,95 V, alterna 1,8 V no power
IRQ e **nunca escreve 3,3 V**. O `cd-gpios` stock tem flag 0 (active high) e o
downstream liga `MMC_CAP2_CD_ACTIVE_HIGH`; a variante atual usa active low, o
que também precisa ser corrigido. O porte para o mainline é o próximo passo
antes de qualquer cartão.

## Histórico — robustez LCDB/display (25/10/2026)

Telefone rodando em RAM a variante `work/display-robustness-20261025/display-v2/`,
kernel #10, derivada da `combined-cpu8-gpu-quiet/` que fica preservada.
A contagem compartilhada do LCDB foi substituída por estados individuais
LAB/IBB sob mutex; falhas não confirmam mudanças de estado. Leituras e
VREG_OK/SC propagam erros, enable com falha tenta rollback, captura/adopção
do ABL acontece antes do registro e as restrições DT lab/ibb agora são
interpretadas pelo core. Seleção de tensão respeita min/max e headroom do
boost. O painel passa a reportar falhas ao desfazer/desligar reguladores.

Validação: testes de falhas simuladas e concorrência com os helpers reais do
LCDB passaram; kernel e módulo compilados. Seis ciclos reais off/on no v1 e
mais três na variante final v2 passaram, ambas as saídas desligando e
religando com VREG_OK, contagens equilibradas e DSI irqs=0. Usuário confirmou
imagem normal após o primeiro ciclo e após a sequência final. CPU0-7, SSH,
UFS RO continuam disponíveis. Mantido silêncio do kernel no framebuffer;
mensagem de status em tty1 identifica `display robust v2`.

Ver `docs/kernel/checkpoint-2026-10-25-display-robustness.txt`,
`lcdb-v1/cycles-2-to-6.txt` e `display-v2/runtime-v2.txt`. Nenhum flash ou
escrita em partição; hashes de modem_a/bluetooth_a inalterados antes dos resets.
GOLDs intactas. Isso resolve esta etapa de robustez de estados/erros LCDB;
suspend/resume, repetibilidade a frio e FIFO intermitente da partida seguem
pendentes. Não reintroduzir MDSS core BCR nem usar LP DCS para checagem.

### Ponto de parada solicitado pelo usuário

- Estado ao concluir aquela etapa: telefone ligado na `display-v2`, imagem
  normal confirmada pelo usuário depois dos três ciclos finais; nove ciclos no total.
- Par exato na pasta `work/display-robustness-20261025/display-v2/`:
  `u-boot-hanoip-display-robust-v2.img` (SHA256
  `6aae8559d47495b6c2a31e62762bd3a608869b30b8c3537c68f046f3c876f2b1`)
  e `kernel-hanoip-display-robust-v2.img` (SHA256
  `9085a811949520d0940e133b41688944e704045d794eec9eec850ea2a3f45813`).
- Alterações LCDB/painel, teste host e checkpoint estão no disco, ainda sem
  commit/push. A variante não foi promovida a GOLD; GOLD v3 permanece intacta.
- Naquele ponto, suspend/resume, bateria/carregador, estabilidade prolongada
  e FIFO de partida seguiam pendentes. Bateria/carregador foi investigada no
  checkpoint atual acima; suspend/resume continua adiado. Otimização de boot e
  refinamento do touch continuam adiados.
- Antes de reiniciar: verificar novamente todos os blocos RO, conferir os
  hashes brutos de modem_a/bluetooth_a, desmontar `/mnt/ro/*` e usar o
  `/sbin/reboot` com guarda RAM. Detectar o estado USB depois. Somente
  `fastboot boot`, nunca flash ou escrita em partição.

## Histórico — GPU/Freedreno (25/10/2026)

O telefone está na variante volátil `work/cpu-gpu-20261025/gpu-zap-early/`.
Ela carrega UFS com todos os blocos `ro=1`, monta `modem_a` com
`ro,noload,nodev,nosuid,noexec` e disponibiliza `a615_zap.mdt` + b00-b02
antes de carregar o display. Hash bruto de modem_a antes/depois idêntico:
`6a1fc4b5c25704d476a57e1c0a59983b75c9af27ca8a75412037614c6c6f45dc`.

GPU/Mesa validado: pmOS/Alpine 3.24 em tmpfs, Mesa 26.1.6 e kmscube. O teste
de 120 frames em `/dev/dri/card0` terminou com código 0 e reportou
`vendor=freedreno`, `renderer=FD618`, OpenGL ES 3.2. `renderD128` existe,
GPU devfreq/controle térmico registrados; DSI `irqs=0`; sem erro de carga do
Zap ou `gpu hw init failed`. Não há printk explícito de sucesso do Zap. Ver
`docs/kernel/checkpoint-2026-10-25-gpu.txt` e logs em `run1/`.

O initramfs foi repacotado depois para corrigir uid/gid dos arquivos (Dropbear
StrictModes): a imagem atual tem hashes em `gpu-zap-early/SHA256SUMS`, mas a
imagem repacotada ainda não foi reiniciada. O boot testado e a imagem atual
usam o mesmo kernel/DT e ordem GPU; só a propriedade dos arquivos do initramfs
difere. O GOLD v3 continua preservado como retorno; nada foi flashado.

## GOLD v3 anterior: work/GOLD-20261025-1203/ (v3 completa, 25/10/2026 12:03 -03)
Display + rede USB/SSH + UFS RO + modem/Wi-Fi + Bluetooth sobem sozinhos.
Identidade (MAC, BD_ADDR, dados do modem) vem do ABL via U-Boot a cada boot.
Ver GOLD.txt na pasta. GOLDs anteriores (1047, 0126) preservadas.

## >>> Bluetooth FUNCIONANDO (25/10/2026) — hci0, busca BR/EDR + LE
Ver docs/kernel/checkpoint-2026-10-25-bluetooth.txt e scripts/hanoip-load-bt.sh.
Precisa BT_ADDR (privado) aplicado com btmgmt public-addr.

## >>> Wi-Fi FUNCIONANDO (25/10/2026) — work/wifi-20261025/v3/
wlan0 conecta (<ssid> WPA2, DHCP, ping, apk update OK). Ver docs/kernel/checkpoint-2026-10-25-wifi.txt.
Precisa de /run/mmi-unit-info.conf (privado, work/wifi-20261025/private/)
antes de /sbin/load-wifi. Próximo: conectar com wpa_supplicant (pmOS).

## GOLD v2 anterior: work/GOLD-20261025-1047/ (promovida 25/10/2026 10:47 -03)
Foi o retorno padrão até a GOLD-20261025-1203. Ver GOLD.txt na pasta.

## v2 (25/10/2026) — display automático antes da rede

`work/usbnet-20261025/v2/` (SHA256SUMS): kernel/DT/U-Boot = GOLD; ramdisk =
v1 + `/sbin/hanoip-autostart` (load-display, espera fb0=msmdrmfb, depois
start-usbnet; cmdline hanoip.nodisplay/hanoip.nonet pulam etapas) +
`/sbin/enter-pmos` + load-touch/load-display aceitando storage SE todo
`/sys/class/block/*/ro`=1. Init em `scripts/hanoip-v2-shell.init`.
run1: sem interação, fb0 aos 19 s, rede 22,6 s, SSH 28 s após envio;
6 IRQs FIFO na partida, usuário confirmou TEXTO. Depois: pmOS via
enter-pmos embutido OK, touch registrado, UFS enumerou em 1 s, 84 blocos
RO, mounts só RAM, DSI sem IRQ nova, tainted 4096 (O). Checagem do
load-touch: passa com tudo RO, recusa simulação com bloco RW.
fastboot max-download-size = 768 MB (embutir pmOS é viável).
Próximo: repetir boots da v2 (2-3) e promover a nova GOLD; depois UFS 100%
(descritores, gear sob carga, PM) e SD (sdhc_2: L9C/L6C, cd GPIO 69).
Coleta Android completa: `work/android-dump-20261025/` (LEIA-ME, privado).

## (anterior) Rede USB + SSH/SFTP — pausado 25/10/2026 madrugada

Celular ficou no **Android** (ADB ok). Nada gravado em partição.
Retorno padrão: `work/GOLD-20261025-0126/` (não modificar).

Variante em teste: `work/usbnet-20261025/v1/` (SHA256SUMS na pasta).
- Kernel/DTB/U-Boot IDÊNTICOS à GOLD; só o ramdisk muda (base = ramdisk GOLD).
- `/init` novo: `scripts/hanoip-usbnet-shell.init` — gadget configfs único
  1d6b:0104 (IAD 0xEF/2/1) com ACM (serial, `ttyGS0`) + NCM; se NCM falhar
  no bind, cai para só ACM. Monta devpts.
- `scripts/hanoip-start-usbnet.sh` (/sbin/start-usbnet, em background):
  links de applets em /usr/bin (sem mkfs/fdisk/tune2fs/fsck/etc.), usb0
  172.16.42.1/24, udhcpd entrega 172.16.42.2 ao host (sem rota/DNS),
  dropbear `-R -s` (só chave; host key gerada por boot em RAM).
- Dropbear 2026.94 + `sftp-server` do OpenSSH 10.6p1, estáticos com musl
  1.2.6 (compilado em /tmp/usbnet-build no container). Hashes das fontes
  conferidos com SHA256SUM oficial/OpenWrt. glibc estática deu segfault de
  NSS — não usar. authorized_keys = ~/.ssh/id_ed25519.pub do Mac.

Resultado do 1º boot (25/10):
- Mac: serial `cu.usbmodem211401` + interface `en10` com 172.16.42.2 (DHCP).
- ping ok; `ssh root@172.16.42.1` ok; SFTP put/get 64 MiB com hash igual
  (~28 MB/s); `scp -O` e `scp` ~21 MB/s (limite USB high-speed). Serial
  continua funcionando junto. tainted0, mounts só RAM/pseudo.
- **Display: TELA PRETA** com 2 IRQs FIFO DSI (`dsi_err_worker status=4`)
  no init do fb, contador estável em 2; sem Oops/SMMU. Log em
  `v1/dmesg-black.txt`, `v1/display-over-ssh.txt`.
  Diferença vs GOLD: display carregado aos ~72 s (após tráfego scp) em vez
  de ~27 s. Pode ser só o FIFO intermitente conhecido (já deu 0/2/6 IRQs);
  NÃO concluir que a rede causa.

Run2 (25/10, `v1/run2-early/`): mesmo par v1, display carregado pela
SERIAL aos 15 s, sem tráfego de rede iniciado: 5 IRQs FIFO na partida,
mas usuário confirmou TEXTO na tela. Depois ~320 MiB scp/SFTP com hashes
iguais: contador ficou em 5 (nenhuma IRQ nova), tela continuou com texto
(confirmado). Leitura: risco está na inicialização do display, não na rede
depois; número de IRQs na partida não prevê preto (2=preto, 5=texto).
Uma amostra por lado: não é prova. Prática adotada: carregar o display
ANTES de tráfego de rede. Proposta v2: /init carrega display automaticamente
e só depois sobe rede/SSH.

**postmarketOS em RAM (25/10, mesmo boot run2):** `work/pmos-20261025/`.
Rootfs pmOS v26.06 (Alpine 3.24), 156 pacotes (postmarketos-base,
alpine-base, bash, htop, nano, iproute2, iperf3, usbutils, evtest,
fastfetch), montado com apk no container `alpine:3.24` arm64 (precisa
`docker run`; o container de build antigo não tem rede). Chave pmOS de
pmbootstrap main `pmb/data/keys/build.postmarketos.org.rsa.pub` (sha256
b70e6ffc...). Sem pacote de kernel/device; mkinitfs pulou (sem deviceinfo).
Tarball 41,5 MB -> scp 1,9 s -> `scripts/hanoip-enter-pmos.sh` (copiado
como /run/enter-pmos; some no reboot) monta tmpfs 1 GiB em /mnt/pmos,
extrai, bind de proc/sys/dev/dev/pts/run/tmp e faz chroot. NÃO roda
OpenRC/init do pmOS, recusa se houver mount não-RAM. Resultado: fastfetch
"postmarketOS v26.06 / Motorola Moto G60 / DSI-1 1080x2460", bash 5.3.9,
123 MiB usados, tainted0, DSI continuou em 5.
Uso: `scp -O tarball root@172.16.42.1:/tmp/pmos-rootfs.tar.gz`, depois
`ssh -t root@172.16.42.1 /run/enter-pmos`.
Pendente: incluir enter-pmos no ramdisk da v2; internet no celular (NAT
pelo Mac) para `apk add`; mais tarde switch_root com OpenRC. Comandos SSH do Mac (zsh):
`ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/id_ed25519 root@172.16.42.1`
Para SFTP: `sftp` com as mesmas opções. Se ADB não aparecer no Android,
entrar no bootloader com Power + Volume-.
Depois da rede: atualizar `load-touch` para aceitar storage só se tudo RO.

Atualizado em 24/10/2026. O usuário pediu este arquivo para outra IA continuar
mais tarde. **Não iniciar novos testes automaticamente por causa deste arquivo.**

Workspace: `/Volumes/SSDExterno/Users/brener/developer/hanoip-mainline`.
Leia também `AGENTS.md`, que preserva a regra de segurança entre sessões.

## Regra absoluta do usuário

**Não dar flash em nada e não gravar nenhuma partição do celular.**
O usuário perdeu dados/drivers de uma partição em uma tentativa anterior.

- Proibidos flash, erase, format, update, troca de slot, gravação em dispositivos
  de bloco, reparos de filesystem e envio de arquivos a filesystems persistentes.
- Não executar os exemplos antigos de flash dos READMEs/documentação de agosto.
- Permitidos: fontes/builds/arquivos no computador, consultas ADB com root em
  somente leitura e testes voláteis com `fastboot boot`, já autorizados.
- O initramfs de teste fica em RAM. Nenhuma partição é montada, inclusive UFS.
- Carregar módulos e firmware na RAM interna do touch é parte do teste volátil.
  O novo driver não implementa programação de flash do controlador.
- Preservar imagens conhecidas e seus hashes; criar outra pasta para cada variante.

## Situação atual — repetibilidade e início da etapa CPUfreq

O usuário aprovou esta ordem: (1) repetir/consolidar boot, (2) energia/CPU,
(3) robustez LCDB/display, (4) rede/GUI. Touch fino fica para depois.

### Baseline mais recente: quiesce-late

Par em RAM:
- Kernel: `work/display-repeat-20261024/quiesce-late/kernel-hanoip-quiesce-late.img`
  SHA256 22fc61f9593fff3fc91ef877407fd7d53783388147728a6d4ebd7e117b37a732.
- U-Boot: `work/hanoip-touch-20261024/handoff-v2/u-boot-hanoip-touch-handoff-v2.img`.
- Mesmo Image Linux #8/DT, reservas, BCR contornado, UFS desabilitada e CPU flags.
  Mudanças recentes estão apenas nos módulos do ramdisk.

Duas execuções desse MESMO par tiveram imagem estável confirmada pelo usuário:
- `quiesce-late/load.txt`: 6 IRQs FIFO iniciais, sem timeout de comandos/video done.
  `steady.txt` confirmou contador ainda em 6 até uptime209,16s; tainted0,
  sem SMMU/Oops, DRM ativo, apenas RAM/pseudo mounts e ram0..ram15.
- `quiesce-late-repeat/load.txt`: ZERO IRQs de erro DSI, sem timeouts/SMMU/Oops.
  Usuário confirmou "sim texto estavel".
Não declarar estabilidade longa/ciclos frios nem todos os boots livres de FIFO.

Correções presentes:
- Brilho Tianma: stock é 51 03 32; helper normal emitia 51 32 03. Agora usa
  bytes explícitos big endian, só na sequência Tianma.
- Em host_power_on, só hanoip/DSC/VIDEO: desliga ENABLE/VID/CMD antes do reset
  DSI local, evitando restaurar VIDEO ativo herdado dentro de dsi_sw_reset.
  Captura provou pre_ctrl=0x1f7/pre_status=0x8 -> post_ctrl=0x1f1/post_status=0.
- Em dsi_manager, só hanoip/Tianma/VIDEO/single DSI: pre_enable prepara link e
  transporte de comandos; inicia vídeo em bridge.enable após panel.prepare.
  Essa mudança isolada falhou; só a combinação acima passou os testes recentes.
- error_snapshot no platform DSI cacheia ACK/FIFO/TIMEOUT/PHY/STATUS0/CLK na IRQ.
  Sua leitura é de software, não envia comandos DSI. Mantém IRQ/avisos originais.
- panel_status no dispositivo MIPI-DSI faz leituras DCS LP. NÃO usar em loop:
  essas consultas geraram DSI status0x16. Não usadas nos testes quiesce-late.

### CPUfreq validado; CPUidle agora em teste

Par CPUfreq validado em `work/cpufreq-20261024/quiesce-late-baseline/`:
`kernel-hanoip-cpufreq.img` + `u-boot-hanoip-cpufreq.img`. Image/ramdisk iguais
à quiesce-late; DT só remove cpufreq.off=1; mantém seis CPUs e idle off.
Driver qcom-cpufreq-hw, policy0 relacionada a CPUs0..5, 300000..1804800 kHz.
Governor powersave -> 300000/300000 solicitado/reportado por hardware;
performance ->1804800/1804800; schedutil ->1248000/1248000 na amostra.
Teste dois segundos por governor, restaurou schedutil, saiu0. Temperaturas
39..42,5 °C, DSI permaneceu com ZERO erros, tainted0, sem Oops/SMMU.
Usuário confirmou "sim estavel". Logs e governor-analysis.json na pasta;
ver docs/kernel/checkpoint-2026-10-24-cpufreq.txt. Sem medição elétrica/stress.

CPUidle completo foi testado no par `work/cpuidle-20261024/` (só removeu
cpuidle.off=1). psci_idle/menu registrados, 18 estados (WFI+2 por CPU).
Contadores em 6s mostram uso de PC/rail-PC em todos os CPUs, mas o usuário
relatou TELA PRETA e demora maior. Não promover esse par como display validado.
No display houve 2IRQs FIFO iniciais, sem novos até uptime255s, tainted0.
`idle-analysis.json` contém os deltas; isso NÃO prova combinação funcional.
Desabilitamos states1/2 em runtime (só sysfs): `disable-idle-runtime.txt`.
CPU0 state2/rejected mostrou2, vários usos bem-sucedidos. Recuperação visual
após desabilitar não foi confirmada antes do teste seguinte.

Próxima variante em boot: `work/cpuidle-20261024/local-only/`, par
kernel-hanoip-cpuidle-local.img + u-boot-hanoip-cpuidle-local.img.
Inclui CPUidle, mas remove domain-idle-states de cluster_pd para testar apenas
PC/rail-PC dos núcleos, sem L3/CX/AOSS collapse. Bootargs iguais ao teste full,
Image/ramdisk iguais ao CPUfreq validado. RAM/22reservas/UFS/proteções conferidos.
**Resultado 25/10/2026: local-only PASSOU em 2 boots** (`local-only/` e
`local-only-repeat/`): DSI irqs=0, connected/enabled, tainted0, sem
Oops/SMMU, CPUs0..5 ~5 s de 5 s em cpu-sleep-0-1 (rail-PC), rejected0,
34,5..37,5 °C. Usuário confirmou imagem nas duas ("sim mostra na tela").
Ver `docs/kernel/checkpoint-2026-10-25-cpuidle.txt`. Colapso de cluster é o
suspeito principal da tela preta, NÃO causa comprovada. Novo par de retorno
com energia: local-only. O par CPUfreq quiesce-late-baseline com
cpuidle.off=1 continua preservado. Coleta serial: `local-only-repeat/collect-sershell.py`
(termios puro; pyserial não está instalado no Mac).
Próximas pendências: bateria/carregador, robustez LCDB/display, CPUs6/7,
estabilidade longa, suspend; colapso de cluster com display fica para depois.

**UFS com tudo ligado, 25/10/2026** (`work/ufs-20261025/ufs-local/`): par
local-only + UFS (DT só habilita ufshc/phy; Image #8 igual; módulos UFS
recompilados contra a árvore #8). Um boot: display DSI irqs=0, UFS 6 discos
/84 blocos todos RO, sdb 64KiB = hash Android, leituras ~510 MB/s, touch
event3 com eventos (insmod manual: load-touch recusa storage exposto),
idle/cpufreq ativos, zero erros. Ver
`docs/kernel/checkpoint-2026-10-25-ufs-tudo-ligado.txt`.

**VERSÃO GOLD (marcada pelo usuário em 25/10/2026 01:26 -03):**
`work/GOLD-20261025-0126/` — cópia somente leitura deste par ufs-local,
com GOLD.txt e SHA256SUMS (kernel c99f8cf5..., U-Boot 33c05711...).
É o retorno padrão daqui em diante. Validada em um boot; repetir antes
de mudanças grandes. Uso apenas com fastboot boot, nunca flash.

### Evidência e variantes anteriores

- `work/boot-repeat-20261024/run1/`: par original handoff-v2 repetido deu preto,
  apesar de DRM ativo/sem falhas SMMU. Unblank, carga do touch e preenchimento
  branco de /dev/fb0 (confirmado por releitura) não recuperaram a imagem.
- `panel-status/` e `panel-status-repeat/`: texto estável duas vezes; segunda
  sem consultas DCS. Leituras do primeiro deram power0x9c (igual ao esperado
  pelo stock), pixel0x07, diagnostic0xc0, prepared/enabled1, resetlogical0.
- `brightness-be/` e `brightness-be-repeat/`: ambos com texto estável, mas o
  segundo teve 7 erros DSI status4 na partida, antes do fbdev pronto.
- `dsi-snapshot/`: raw FIFO primeiro0x88881018/OR0xdddd1019, 7IRQs e timeout
  video done. Bits confirmam underflow de vídeo e das quatro lanes HS, além
  de overflow posterior. Categoria status4 sozinha não mostra esse detalhe.
- `late-video/`: FALHOU; primeiro comando ff780700 deu DMA timeout -110/painel
  não inicializou, preto. Código foi retirado antes do teste seguinte.
- `quiesce-inherited/`: provou limpeza do VIDEO herdado, mas com sequência
  pre_enable original ainda teve 6IRQs FIFO/timeout. Usuário descreveu boot com
  texto, USB/brilho, cinza/preto, mais texto/piscadas e depois linha estável.
  Nem toda transição visual corresponde a reset ou ausência final de imagem.

Pendências: FIFO inicial pode reaparecer; dependência de DISPCC/PLL/estado DPU
herdado e LCDB ainda não resolvida. MDSS core BCR não foi reintroduzido. Não houve
mudança global de IOMMU, reservas, tensão ou partições. Fontes/patches/hashes e
logs estão em cada variante. Referência da sequência DRM:
https://docs.kernel.org/gpu/drm-kms-helpers.html#mipi-dsi-bridge-operation

## Retomada após o handoff — 24/10/2026

O usuário pediu para continuar com o celular conectado. Ele apareceu inicialmente
no fastboot Motorola (`<serial>`, product `hanoip`). Nenhum flash foi executado.

- Conferimos os hashes do handoff e o DT efetivo: 22 reservas idênticas, sem
  sobreposição, UFS desabilitada, splash 0x9c000000/0x1700000, sem BCR MDSS.
- Empacotamos e bootamos o par de `handoff-unbooted/` APENAS com fastboot boot.
  **Apesar do nome, essa pasta agora contém um teste já executado e FALHO.**
- `handoff-unbooted/preflight.txt`: o mapa criado no MSM antes do attach retornou
  -ENODEV. A causa foi confirmada nas fontes: `arm_smmu_map_pages` não tem
  pgtbl_ops até `arm_smmu_init_domain_context`, chamado no attach.
- A limpeza da falha chamou `drm_atomic_private_obj_fini` duas vezes e causou
  Oops no `dpu_kms_destroy`. O shell continuou ativo, tainted=128; mounts apenas
  RAM/pseudo e só ram0..ram15, confirmado em `after-failure.txt`.
- Ajustamos o mapa para um hook específico hanoip/MDSS em arm-smmu.c,
  DEPOIS da inicialização das tabelas e ANTES de instalar os S2CRs. Mantém
  somente IOMMU_READ, range exato, booleano por domínio para não remapear.
  MSM só valida/reserva o range no allocator IOVA; não mapeia antes do attach.
- Corrigimos a limpeza dupla com `global_state_initialized` em dpu_kms.c/.h.
- Novo Image e msm.ko compilaram sem erros, modpost estrito:
  `work/hanoip-touch-20261024/handoff-v2/`. Fontes, patch e hashes preservados.
- Novo kernel: `handoff-v2/kernel-hanoip-touch-handoff-v2.img` (SHA256
  14a9df08f290341ff3637529807b6c3a6d4b6f6360300d5e794708fd129ca1c3).
  Usar explicitamente o U-Boot de `handoff-unbooted/u-boot-hanoip-touch-handoff.img`.
  O DT é igual ao primeiro handoff. Esta versão altera o Image builtin também.
- Após `/sbin/reboot`, o aparelho voltou ao Android. O helper detectou o ADB,
  reiniciou para o bootloader e executou os dois fastboot boot. O segundo kernel
  abriu USB serial, build #8. `handoff-v2/display-load.txt` mostrou o mapeamento
  antes da troca dos streams, DRM inicializado, fb0=msmdrmfb, connected/enabled
  e modo 1080x2460. Sem falhas SMMU, timeouts DSI ou Oops nesse teste.
- `handoff-v2/visual-test.txt`: mensagem "HANOIP MAINLINE - TESTE 2" enviada a
  tty1; o usuário confirmou "sim tem mensagem na tela". tainted=0. Touch também
  inicializou com PID/IRAM/FW corretos; contadores iniciais zero.
- Primeira tentativa de captura `input-events.txt` não abriu o leitor porque
  BusyBox antigo requer `timeout -t 45`, NÃO `timeout 45`.
  Captura corrigida em `input-events-45s.txt`. Não interpretar a tentativa
  inválida como um teste físico sem eventos.

### Resultado mais recente desta retomada

**Display confirmado visualmente e touch físico validado, inclusive dois dedos.**
O usuário disse: "sim tem mensagem na tela". Primeira captura:
1949 eventos, 15 contatos/15 solturas. Segunda: 4453 eventos, 42 contatos/42
solturas, máximo observado dois dedos, sem contatos presos. Coordenadas dentro
dos limites declarados. Stats acumuladas: irqs=2347 reports=2347 rejected=0,
tainted=0. Logs/análises em `handoff-v2/input-*.txt` e `input-*-analysis.json`.
A segunda captura representa ~6,73 s de eventos dentro da janela de 30 s.

Par completo preservado em `work/hanoip-touch-20261024/handoff-v2/`:
`u-boot-hanoip-touch-handoff-v2.img` (cópia idêntica do U-Boot do handoff) +
`kernel-hanoip-touch-handoff-v2.img`. DTs e uboot.config também copiados ali.
Não substituir os checkpoints USB/UFS/display anteriores.

Decisão do usuário após este checkpoint: deixar o touch "redondo" mais tarde.
Adiar calibração/orientação, cantos, cobertura, filtros, demais slots e gestos;
não iniciar esses trabalhos automaticamente. O touch básico com dois dedos já
foi validado. O display está confirmado visualmente neste boot; isso ainda não
valida ciclos frios, suspend, GPU ou rootfs.

Prioridade revista após o usuário pedir para "voltar umas casas": rede USB
fica depois de estabilizar a base. Próximo trabalho recomendado é verificar
repetibilidade do boot em RAM e gestão de energia/CPU, antes de userspace/GUI.
Auditoria somente leitura em `work/base-audit-20261024/LEIA-ME.txt` e runtime.txt:
seis de oito CPUs online; CPUfreq/CPUidle desabilitados por cmdline; bateria/carga
não expostas; sensores térmicos funcionam (36,1..38,7 °C nessa amostra).
`idle=poll` foi reportado desconhecido pelo ARM64, não assumir polling efetivo.
Investigar uma mudança por vez; não reativar todos os recursos de uma vez.
LCDB ainda precisa robustez antes de ciclos de alimentação/suspend do painel.
Esta revisão não alterou o hardware nem iniciou outro boot.
O aparelho foi deixado no Linux temporário, display/touch carregados; consultar
`handoff-v2/final-state.txt` e detectar USB de novo ao continuar.
Ver `docs/kernel/checkpoint-2026-10-24-touch.txt` para o checkpoint atualizado.

O restante deste arquivo descreve o histórico anterior. As afirmações abaixo
sobre a correção "ainda não bootada" referem-se ao estado antes desta retomada;
o resultado atualizado acima tem precedência.

## Onde efetivamente paramos

1. **O display funcionou visualmente.** O usuário confirmou que a mensagem
   enviada ao console apareceu na tela no checkpoint anterior.
2. Criamos um driver mínimo para o **touch Ilitek ILI7807 por SPI**. Ele identificou
   o PID, carregou/verificou os três blocos de firmware em IRAM e registrou input.
3. **Toques físicos ainda NÃO foram validados.** Uma captura de 35 segundos
   terminou sem eventos; estatísticas `irqs=0 reports=0 rejected=0`. Não houve
   confirmação explícita de que o usuário realizou os gestos nessa janela.
4. Nesse novo boot, o display teve falhas SMMU durante a passagem do framebuffer
   ABL para o domínio DMA do DRM. O usuário relatou: **“a tela ta preta aqui”**.
5. Preparamos uma correção específica para preservar o mapeamento do framebuffer
   antigo durante essa transição. **Compilou com modpost estrito, mas NÃO foi
   empacotada em novas imagens nem testada no aparelho.**
6. O usuário pediu o handoff antes desse próximo boot. Não continuamos os testes.

### Estado do aparelho no encerramento

- Último estado consultado por shell: Linux temporário, display preto, touch
  inicializado, contadores zero, apenas `ram0` a `ram15`, mounts em RAM/pseudo.
- **Na última checagem do host, não apareceu nenhum aparelho em ADB, fastboot ou
  `/dev/cu.usbmodem*`. A causa não foi determinada.** Pode ter mudado de estado ou
  sido desconectado; não assumir que continua no Linux ou que voltou ao Android.
- Nenhuma nova reinicialização foi solicitada após o pedido deste arquivo.

## Hardware e acesso

- Moto G60, `hanoip`, XT2135-1, Qualcomm SM7150/732G.
- Serial Android/ABL fastboot: `<serial>`.
- Android tem root: `adb ... exec-out su -c 'COMANDO_SOMENTE_LEITURA'`.
- Kernel Android: `4.14.206—CosmicFresh-R6-Final`.
- Slot observado: `_a`. Não alterá-lo.
- Linux de diagnóstico: `7.1.0-sm7150`; última imagem do touch mostrou build `#7`.
- USB ACM Linux costuma ser `/dev/cu.usbmodem211401`, mas descobrir novamente.
- U-Boot volátil pode anunciar serial `????????????`. Não usar essa string em
  `fastboot -s`: já causou espera. Confirmar um único aparelho e consultar
  `fastboot getvar product`, esperando `motorola-hanoip`, antes do boot do kernel.
- Cada `fastboot boot` do U-Boot demora cerca de 10,4 s. Linux abre USB em ~7–20 s.
- O DT efetivo entregue ao Linux é o **DT embutido no U-Boot**, não apenas o DTB
  empacotado em `boot.img`. Alterações de DT precisam chegar às duas árvores.

## Checkpoints preservados

### USB e UFS em leitura

- `work/hanoip-build-20261024/v2/`: par sem UFS com shell USB validado.
- `work/hanoip-ufs-modules-20261024/iommu/`: par UFS validado em leitura.
  Seis discos, 78 partições, todos os 84 block devices marcados somente leitura.
  Três leituras de 64 KiB de `/dev/sdb` deram o mesmo SHA e conferiram com Android.
- Manter `iommus = <&apps_smmu 0x300 0x0>` na UFS: sem isso, houve NOP OUT timeout
  com a configuração SMMU strict. Não remover nem usar passthrough global.
- Documentação: `docs/kernel/checkpoint-2026-10-24-ufs-leitura.txt`.
- Originais preservados em `work/baseline-before-qup-2026-10-24/`.

### Display confirmado pelo usuário

Par em `work/hanoip-display-20261024/no-reset/`:

- `u-boot-hanoip-display-noreset.img`
- `kernel-hanoip-display-noreset.img`

O usuário disse **“apreceu a mensagem na tela pode seguir”**. Logs comprovaram:
`card0-DSI-1` connected/enabled, CRTC ativo 1080×2460 a 60 Hz, pixel clock
343458 kHz, dois DSC, `fb0=msmdrmfb`, pitch 4352. GPU desabilitada nesse teste.
Isso valida aquele boot, não estabilidade de todos os handoffs.

Fontes/ajustes dessa etapa:

- Painel Tianma ILI7807S: reset elétrico alto 4 ms, baixo 1 ms, alto 12 ms,
  traduzido para GPIO_ACTIVE_LOW; VFP 2565, VBP 12, VPW 2.
- DSC 1.1, slices 540×10, duas por pacote, 8 bpc/8 bpp, block prediction;
  PPS após a sequência vendor. Backport upstream da flag
  `MIPI_DSI_MODE_DSC_ALL_SLICES_IN_PKT`, não do campo experimental da PR69.
- WLED strings 0/1/2 (stock bitmask 7), brilho inicial 512/4095,
  25000 µA por string, boost 1400 mA, OVP 26500 mV.
- `qcom,sm7150-mdss` adicionado a `qcom_smmu_client_of_match` em
  `drivers/iommu/arm/arm-smmu/arm-smmu-qcom.c`. Mantém domínio identity inicial
  como em outros SoCs, necessário antes de o DRM assumir o display.
- DISPCC definia `mdss_gdsc`, mas não o registrava: restauramos `.gdscs` e
  `.num_gdscs` em `drivers/clk/qcom/dispcc-sm7150.c`.
- O reset BCR do core MDSS reiniciou o aparelho. Logs instrumentados em
  `work/hanoip-display-20261024/trace/msm-registration.txt` terminaram em
  `HANOIP MDSS: asserting reset`, sem `reset released`.
  Só os DTs de diagnóstico omitem `&mdss` `resets`. O reset GPIO do painel
  continua presente. Não reintroduzir esse BCR sem investigar.
- Fontes mantêm a configuração PLL/clocks herdada do ABL. Ainda não restauramos
  todo o init de PLL/gating do DISPCC upstream.
- `docs/kernel/checkpoint-2026-10-24-display.txt` contém detalhes e limites.

## Touch: o que foi feito e o que falta

### Referência e firmware original

Fontes públicos de referência:
`Dark-Matter7232/CosmicFresh-Hanoip`, commit
`9eecac9f6efd66fd2915fd80dd822d690ecbc207`, diretório
`drivers/input/touchscreen/ilitek_v3_mmi/`.
Cópias/proveniência estão em `work/hanoip-touch-20261024/vendor/` e
`provenance.json`. Não importamos integralmente o driver Android com seus
notificadores antigos, interfaces de fábrica, dumps e possíveis efeitos.

Coleta SOMENTE LEITURA do Android:

- `/proc/ilitek/ver_info`: chip `7807`, FW `16.0.10.0`, core `1.4.6.8`,
  protocolo `5.6.0`, driver `3.0.4.0.200731`.
- `getevent -lp`: 10 slots, X 0..1079, Y 0..2459, INPUT_PROP_DIRECT.
- `/vendor/firmware/FW_ILITEK_TDDI_TM.bin` copiado apenas para o computador.
  358761 bytes, SHA256
  `2be3ce9836bfe1ff90a32ad7b081389c0126cac47a0b058c8ecf3446248335e7`.
  Apesar da extensão, é Intel HEX, com checksums válidos.

`scripts/hanoip_ilitek_firmware.py` valida HEX, cobertura, CRC dos blocos e
identidade/layout específicos do hanoip. Gera um container local com AP,
DATA e TUNING; exclui MP/fábrica. Não faz operações no aparelho.

`work/hanoip-touch-20261024/hanoip-7807-iram.bin`: 90724 bytes, SHA256
`ef3e38c1e9dda6700ec29d09e7ec7f7c957b269ad6a56027c4ffb527051c314f`.

| Bloco | Destino IRAM | Bytes | CRC |
|---|---:|---:|---|
| AP | 0x00000 | 81920 | 0xfea9bcbd |
| DATA | 0x20870 | 8192 | 0xca3e7527 |
| TUNING | 0x20670 | 512 | 0x94d9c4dd |

### Driver novo

`kernel-mainline/drivers/input/touchscreen/ilitek-hanoip-spi.c`

- Kconfig `CONFIG_TOUCHSCREEN_HANOIP_ILITEK_SPI=m`;
  `configs/hanoip-touch.fragment`. O driver Ilitek I²C antigo não serve.
- SPI6 em 0xa80000, modo 0, até 10 MHz conforme driver stock;
  reset TLMM8, IRQ TLMM9 falling edge. O DT stock dizia level-low, mas o
  driver Android forçava falling; a variante de DT nova representa isso.
- Valida o container antes do reset. Só aceita os endereços/tamanhos coletados.
- SPI ICE → PID → carga IRAM → releitura de todos os bytes → code reset →
  verificação da versão rodando → formato demo → input com 10 slots.
- Sem comandos de apagar/programar flash do touch, sem gravações de arquivos,
  sem interfaces de fábrica, sem recovery automático ou suspend/gestures.
- Pacotes demo 0x5a/43 bytes, checksum, limites e escala 2048→1080/2460.
- Estatística somente leitura: `/sys/bus/spi/devices/spi6.0/stats`.
- `scripts/hanoip-load-touch.sh`: guard RAM-only/sem discos, carrega evdev e
  touch manualmente; `/sbin/load-touch` no initramfs.

### Evidência no hardware

Primeiro par do touch em `work/hanoip-touch-20261024/`:
`u-boot-hanoip-touch.img` + `kernel-hanoip-touch.img`.
**Não promovê-lo a display validado: teve tela preta neste boot.**

`touch-load.txt` comprovou:

```text
Ilitek PID 0x78071c03
IRAM block 1: 81920 bytes verified at 0x0
IRAM block 2: 8192 bytes verified at 0x20870
IRAM block 3: 512 bytes verified at 0x20670
FW response 21 10 00 0a 00 10 00 02 00
input: Hanoip Ilitek ILI7807 SPI ... input3
ILI7807 ready: 1080x2460, 10 slots, IRAM only
```

Registrou `/dev/input/event3`. IRQ 160, TLMM9, Edge, `spi6.0`.
`input-events.txt` capturou 35 s sem eventos. `before-handoff-retest.txt`
confirmou `irqs=0 reports=0 rejected=0`, apenas RAM e nenhum mount persistente.
Não afirmar que touch está funcional: falta gesto físico confirmado e eventos.
Também é possível que o touch TDDI dependa do painel ativo; estabilizar display
antes de concluir que o IRQ/driver está errado.

## Bug de memória/display em investigação AGORA

O domínio inicial identity resolveu o boot, mas falta preservar o framebuffer
antigo quando o DRM cria/anexa seu domínio paginado próprio.

Neste boot, durante o handoff, apareceram leituras SMMU sem mapeamento em
`0x9c...`, SIDs `0x800`/`0xc40`, depois erros DSI status=4 e
`wait for video done timed out`. O DRM criou `msmdrmfb`, mas a tela ficou preta.
**Esses erros ocorreram em uptime ~753 s; o touch só começou em ~772 s.**
Portanto não atribuir esses erros à carga do touch.

### Correção já escrita/compilada, AINDA NÃO BOOTADA

Fontes alterados:

- `msm_iommu.c`: antes de `iommu_attach_device`, para a combinação específica
  `motorola,hanoip` + `qcom,sm7150-mdss`, lê `memory-region` e mapeia o range
  reservado de splash com identidade e permissão IOMMU_READ.
  Rejeita ranges diferentes de `0x9c000000`, tamanho `0x01700000`.
- `msm_mmu.h`: guarda `firmware_start`, inicializado a zero.
- `msm_kms.c`: limita as alocações virtuais do display à região abaixo desse
  mapeamento para não haver colisão de IOVA. **Isso não diminui a RAM física.**
- DTs de display diagnóstico, nas duas árvores: `memory-region = <&cont_splash_mem>`.
  A reserva física em si não foi ampliada nem mudada.

É uma correção experimental específica do port, não uma solução upstream genérica.
Ainda é necessário verificar no hardware: sucesso do mapeamento antes do attach,
ausência de novas falhas SMMU/DSI, modeset e confirmação visual.
O `msm.ko` antigo dentro das imagens atuais NÃO contém essa correção.

Artefatos compilados preservados em:

`work/hanoip-touch-20261024/handoff-unbooted/`

- `msm.ko`: módulo novo com a correção.
- `kernel.dtb`: DT novo do touch, herdando `memory-region`.
- `u-boot.bin` e `uboot.dtb`: U-Boot/DT novos.
- `kernel-module-build.log`, `uboot-build.log`: builds concluídos sem erro.
- `source-overlay.tar.gz`, `source-manifest.json`, `source-changes.patch`, `SHA256SUMS`.
- Ainda NÃO há um par `.img` novo empacotado nessa pasta.

## Próxima sequência recomendada

1. Ler este arquivo/AGENTS e consultar o estado real de USB/ADB/fastboot.
2. Preservar os checkpoints. Não sobrescrever as imagens existentes.
3. Revisar a correção experimental de handoff e validar o novo DT com o script
   de memória. As proteções LCDB, SMMU inicial e ausência do BCR devem continuar.
4. Empacotar um par novo com os artefatos de `handoff-unbooted/`, substituindo
   também o `msm.ko` do ramdisk. Usar `Image.gz` do primeiro teste do touch:
   as alterações novas são em módulo/DT, não no Image builtin.
5. Bootar apenas em RAM. Confirmar shell/mounts/ausência de discos.
6. Carregar display, aguardar o loader terminar e coletar dmesg completo.
   Não basta esperar 5 s: o probe demora ~10 s pelos logs/earlycon.
7. Confirmar que a imagem voltou e que não existem falhas do framebuffer antigo.
8. Carregar touch, conferir IRAM/FW/input/stats. Capturar gestos com usuário
   avisado e confirmar coordenadas, press/release e eventualmente dois dedos.
9. Somente depois considerar recovery/suspend/gestures ou interface gráfica.
   GPU, rede, rootfs e instalação persistente não foram tratados nesta etapa.

### Empacotamento local sugerido — não executado ainda

Executar da raiz do projeto. Esses comandos só gravam arquivos no computador.
O empacotador recusa sobrescrever uma saída com conteúdo diferente.

```sh
python3 scripts/hanoip_boot.py ramdisk \
  work/hanoip-touch-20261024/ramdisk.cpio.gz \
  scripts/hanoip-usb-shell.init \
  work/hanoip-touch-20261024/handoff-unbooted/ramdisk.cpio.gz \
  --add /lib/hanoip-display/msm.ko=work/hanoip-touch-20261024/handoff-unbooted/msm.ko

python3 scripts/hanoip_boot.py repack \
  work/hanoip-touch-20261024/kernel-hanoip-touch.img \
  work/hanoip-touch-20261024/handoff-unbooted/ramdisk.cpio.gz \
  work/hanoip-touch-20261024/handoff-unbooted/kernel-hanoip-touch-handoff.img \
  --kernel work/hanoip-touch-20261024/Image.gz \
  --dtb work/hanoip-touch-20261024/handoff-unbooted/kernel.dtb

python3 scripts/hanoip_boot.py uboot \
  work/baseline-before-qup-2026-10-24/u-boot-hanoip-boot.img \
  work/hanoip-touch-20261024/handoff-unbooted/u-boot.bin \
  work/hanoip-touch-20261024/handoff-unbooted/u-boot-hanoip-touch-handoff.img
```

O helper `work/hanoip-display-20261024/boot-volatile.py` aceita kernel e
`--uboot CAMINHO`. Seu default é o U-Boot do checkpoint de display, portanto
**passar explicitamente o novo U-Boot** para testar a correção do DT.
`--reset` só serve se existir o shell USB Linux; sem ele, detectar Android/fastboot.
Não usar o helper enquanto o usuário só estiver pedindo para ler este handoff.

## Ferramentas, builds e armadilhas

- Host macOS/zsh, SDK Android em PATH. Builds ARM64 por Docker/GCC 13.3.
- Containers próprios: `hanoip-mainline-build-20261024` e
  `hanoip-uboot-build-20261024`. Fontes e builds em `/tmp/kernel-mainline` e
  `/tmp/uboot-sm7150/.output`. Foram preservados; não apagar containers.
  Os dois containers foram parados ao encerrar o handoff; usar `docker start`
  somente quando for retomar builds. Os artefatos novos já foram copiados ao host.
- Outros containers `agrosync-*` são alheios. Não mexer neles.
- Checkout macOS tem colisões de nomes por maiúsculas/minúsculas em Netfilter
  e litmus. Essas modificações já existiam: não resetar nem incorporá-las.
  Builds usaram fontes extraídos via git archive no filesystem Linux e overlays.
- Não houve commit, push, PR nem publicação nesta sessão.
- Para módulos dependentes do MSM, compilar todos os targets `.ko` necessários
  numa única chamada de make. Não misturar o target DTB nessa mesma chamada:
  o kernel fez builds one-by-one e modpost perdeu símbolos entre os targets.
  Compilar DTB separadamente, depois os módulos juntos.
- Último build correto do handoff: `/tmp/hanoip-touch-handoff-build.log`.
- `python3 -m unittest discover -s tests -v`: **16 testes passaram** (10 de
  boot/CPIO, 6 de firmware). Builds kernel/U-Boot/módulos passaram. `git diff
  --check` passou antes do handoff. Isso não substitui o teste do handoff novo.
- `scripts/hanoip_validate_display.py` compara RAM/reservas/proteções com o
  checkpoint e ignora apenas renumeração de phandles nas reservas.
- RAM termina em `0x17dd00000`, nunca declarar 4 GiB cheios. Manter as 22 reservas
  fixas; não reintroduzir a reserva DFPS duplicada.
- Fix LCDB de corrupção de memória preservado: `regmap_read` recebe
  `unsigned int`, não ponteiro convertido de `u8`. Ainda há outros pontos de
  robustez/refcount do LCDB não tratados.
- Os avisos `sys_fillrect/sys_imageblit: framebuffer is not in virtual address
  space` decorrem da flag FBINFO_VIRTFB ausente no fbdev legado MSM; não foram
  corrigidos nesta etapa. Não confundir com a falha SMMU do framebuffer antigo.
- BusyBox do initramfs é Android 1.29.3. Usar `/bin/busybox APPLET` explicitamente.
  O reboot original chama setprop e não reinicia o Linux. `/sbin/reboot` é nosso
  script com guard de mounts e SysRq; pode voltar ao Android OU ao bootloader.
- Console serial: `work/hanoip-display-20261024/serial-command.py` usa host raw,
  lida com escritas parciais, salva `.raw`/`.partial.raw` e espera marcador.
  Não abrir dois leitores seriais simultâneos. Não enviar heredocs longos;
  se transferir arquivo para /tmp em RAM, conferir SHA antes de executar/carregar.
- Captura de input usada: BusyBox hexdump com `24/1 "%02x" "\n"` sobre
  `/dev/input/event3`, por 35 s. Cada evento ARM64 tem 24 bytes.
  O arquivo está em `work/hanoip-touch-20261024/input-events.txt`.

## Pendências que não devem ser esquecidas

- Correção nova do handoff compilada, ainda sem boot/validação visual.
- Usuário relatou tela preta no último teste do touch.
- Touch inicializa e firmware é verificado, mas nenhum gesto validado.
- Sem validação de suspend/resume, boot/ciclo frio de alimentações, GPU,
  120 Hz ou rootfs. Continua sendo um initramfs de diagnóstico em RAM.
- A regra de nenhuma gravação em partições continua valendo em qualquer etapa.

## Variante consolidada com tela sem printk do kernel (25/10/2026)

Nova variante pronta em `work/cpu-gpu-20261025/combined-cpu8-gpu-quiet/`.
Consolida a base GPU-Zap-early (CPU8, GPU/Freedreno, firmware Zap antes do
DRM, display, touch, USB ACM/NCM + SSH/SFTP, UFS com guarda RO, Wi-Fi e BT).
A remoção de `console=tty1` foi aplicada nos DTBs do U-Boot (externo e
embutido) e do boot image do kernel. Logs seguem disponíveis em ttyMSM0,
ttyGS0 e ramoops; mensagens de status do initramfs ainda podem aparecer na
tela e a saída própria do U-Boot não foi alterada.

A imagem tem estrutura e hashes verificados, mas a combinação com console
silencioso ainda não foi bootada. Não foi feita escrita em partição. Para o
próximo teste, usar somente `fastboot boot` com o par nomeado
`u-boot-hanoip-combined-cpu8-gpu-quiet.img` e
`kernel-hanoip-combined-cpu8-gpu-quiet.img`. Ver
`docs/kernel/checkpoint-2026-10-25-combined-quiet.txt`.

Resultado do teste volátil da variante consolidada (25/10/2026): CPU0-7
online; display conectado; `renderD128` presente; KMSCube 120 frames, exit 0,
Mesa GLES 3.2, Freedreno FD618; DSI `irqs=0`. `/proc/cmdline` confirma sem
`console=tty1`; serial/USB/ramoops mantidos. UFS 84/84 blocos RO, modem_a e
bluetooth_a sem alteração de hash. Wi-Fi/modem/ath10k inicializaram e `wlan0`
apareceu, mas sem associação (sem supplicant/credenciais nessa imagem).
Bluetooth `hci0` e firmware QCA subiram, endereço veio do DT e rfkill estava
liberado; descoberta/pareamento não testados por falta de ferramentas no
initramfs. Logs em `combined-cpu8-gpu-quiet/run2/` e checkpoint combinado.
