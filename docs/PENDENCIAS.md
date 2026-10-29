PENDÊNCIAS DO PROJETO HANOIP — lista única (27/10/2026, 19h10)
==============================================================
Consolidado a partir de: onde paramos.md, docs/kernel/checkpoint-2026-10-27-
bateria-RESUMO.txt (seções 1-27), docs/PLANO-USB-MODOS.md, docs/kernel/
PENDENTE-recarga-e-AICL-20261027.txt, work/PRE-GOLD-20261027-1852/PRE-GOLD.txt
e as notas das frentes anteriores (sensores, câmera, digital, áudio).

ROTEIRO DE TESTE (tudo de USB, passo a passo com comandos e critérios de
aceite): docs/TESTE-USB.md — secções A (modos gadget), B (OTG com periférico),
C (host+carregando), D (persistência), E (virada do serviço), F (regressão),
G (matriz de falhas), H (registro), I (critérios de saída).

Legenda de "precisa de":
  [PC]      cabo no PC (fastboot/SSH por USB)
  [REBUILD] rebuild do U-Boot (DT) ou do kernel/modulo
  [HW]      hardware externo (pendrive, carregador, periférico)
  [USER]    decisão sua
  [—]       só trabalho de código/config, ao vivo


A. BATERIA E CARGA (frente desta sessão) ................ 2 de 6 abertos
--------------------------------------------------------------------------
A1. RECARGA automática após a terminação
    Nunca observada. Só acontece com fonte FRACA onde o sistema consome da
    bateria (porta de PC + tela ligada); plugado em carregador forte a bateria
    fica em 0 mA e a tensão não cai até o limiar (~4,30 V).
    Precisa: [PC] + [HW: porta fraca]   Protocolo pronto em
    docs/kernel/PENDENTE-recarga-e-AICL-20261027.txt
A2. AICL (o chip baixando o limite quando a fonte afunda)
    Mesma condição de A1: com carregador de 100 W o VBUS fica em 5,0 V e não há
    o que limitar. Prova tem de ser por VBUS+corrente (o CURRENT_MAX mostra o
    comandado, não o efetivo).
    Precisa: [PC] + [HW]   Mesmo documento
A3. CARGA LIGAR SOZINHA NO BOOT
    Hoje é opt-in: o bit CHARGING_ENABLE reseta em power cycle e é preciso
    `dd` no debugfs. Virar parâmetro de módulo (ex.: charge_on_boot=1).
    Precisa: [—] + [REBUILD do módulo]   ~1 patch
A4. CURRENT_MAX EFETIVO (AICL)
    O patch 0186 mostra o valor COMANDADO. O efetivo está no campo de STATUS_2,
    cuja codificação no SMB5 é uma TABELA que ainda não decodificamos.
    Precisa: [—] engenharia reversa (opcional)
A5. QUIRK DO DEBUGFS DO CHARGER
    Os arquivos hanoip-charge/hanoip-icl e o dump do charger não nascem no
    boot (o work tenta 8x a cada 5 s e desiste). Hoje: recarregar qcom_smbx.
    Precisa: [—] + [REBUILD do módulo]   ~1 patch pequeno
A6. SUSPEND/RESUME COM CARGA
    Nunca validado (o aparelho também não suspende hoje — ver G3).
    Precisa: [—] frente de gerenciamento de energia


B. USB E MODOS (paridade prática com o Android) ......... 1 de 6 feito
--------------------------------------------------------------------------
B1. OTG COM PERIFÉRICO (o teste que falta)
    Imagem pronta e boot validado (dr_mode=otg, role switch em device, boost de
    VBUS presente e desligado). Falta plugar: pendrive, teclado, hub.
    PROTOCOLO COMPLETO: docs/TESTE-USB.md secção B (B1..B6), com o que medir,
    o que é esperado (UDC vazio, role host, regulador enabled, xHCI, sdX) e
    critérios de ABORTO (T > 42 C, erro de VBUS, papel oscilando).
    Precisa: [HW: pendrive/hub] + [PC] se algo travar
B2. SCRIPT DE RECUPERAÇÃO — FEITO (instalado em 27/10 19:40)
    /usr/local/sbin/hanoip-usb-fix (status|fix). Validado só na leitura.
B3. FASE 0 — IMPLEMENTADA E INSTALADA, FALTA ATIVAR E TESTAR
    hanoip-usb-mode (7 modos) + serviço + /etc/hanoip/usb-mode.conf + app GTK
    + política polkit, tudo instalado no aparelho. O serviço segue DISABLED e o
    hanoip-usbnet segue ativo: nada mudou no comportamento atual.
    Falta: rodar o protocolo de docs/PENDENTE-fase0-teste-usb.md e fazer a
    virada (systemctl disable --now hanoip-usbnet && enable hanoip-usb-mode).
    Precisa: [PC] para validar os modos do lado do host
B4. RELIGAÇÃO AUTOMÁTICA DO GADGET
    Com OTG, o UDC DESAPARECE em modo host e volta depois. O serviço precisa
    religar sozinho (observar uevent) e a ferramenta deve tolerar UDC ausente.
    Precisa: [—]   Faz parte de B3
B5. MTP/PTP
    Interface existe (f_fs compilado); falta servidor em userspace.
    DECISÃO NECESSÁRIA: expor só-leitura? Em qual diretório? (nunca /root nem /)
    Precisa: [USER] + [—]
B6. HOST + CARREGANDO AO MESMO TEMPO
    Teoricamente possível (PR_SWAP com TCPM), nunca testado. Exige hub com
    fonte.   Precisa: [HW]


C. TELA / EXIBIÇÃO ....................................... 3 abertos
--------------------------------------------------------------------------
C1. STARTUP DSI FIFO (intermitente)
    Dois boots limpos tiveram 0 e 6 IRQs de FIFO na inicialização; não é
    universalmente resolvido. Baseline atual é quiesce-late.
    Precisa: [—] investigação
C2. TELA ACENDENDO SOZINHA NO PC
    Hipótese forte: era o TCPM rodando como FONTE (antes da correção do
    power-role). Com o carregador de parede não acendeu nenhuma vez. Falta
    confirmar numa sessão longa plugado no PC.
    Precisa: [PC] + [HW: sessão longa]
C3. BRILHO MÍNIMO/FLICKER, APAGAR TELA POR INATIVIDADE
    Ajustes de Phosh (não é kernel).   Precisa: [—]


D. SENSORES .............................................. pausado
--------------------------------------------------------------------------
D1. ROTAÇÃO/ORIENTAÇÃO
    Você confirmou que não gira. Os quatro canais funcionam (acelerômetro,
    giroscópio, luz, proximidade) via ADSP/FastRPC/libssc, mas a mount matrix
    está zerada (identidade).
    Precisa: [—] matriz de montagem + integração no Phosh (iio-sensor-proxy)
D2. PROXIMIDADE PARA APAGAR TELA EM CHAMADA
    Sensor funciona; falta o caminho de UI.   Precisa: [—]


E. CÂMERA E DIGITAL ......................... câmera: 3 abertos; digital pausada
--------------------------------------------------------------------------
E1. CÂMERA — FUNCIONANDO (29/10, PRE-GOLD-20261029-1534): principal S5KHM2
    (C-PHY), wide S5K4H7 e frontal OV32B no Snapshot, troca entre elas, cores
    com as CCM do vendor, foco fixo por lente. A OV02B1B (profundidade) fica
    fora do app por decisão sua. Detalhes: docs/kernel/checkpoint-2026-10-28-
    camera.txt, itens 7-19. Pendente (anotado a seu pedido em 29/10):
  E1a. AUTOFOCO NO APP. Hoje cada lente fica numa posição fixa (main 450,
       wide 180) e só muda pelo nó de lente (v4l2-ctl focus_absolute). A
       pipeline simple da libcamera 0.7.2 não tem AF: exige implementar um
       algoritmo de foco por contraste na libcamera (IPA simple + controle
       da lente) ou um auxiliar fora dela.   Precisa: [—] trabalho grande
  E1b. CORREÇÃO DE SOMBREAMENTO DAS BORDAS (LSC). As tabelas existem no
       tuning do vendor (mod_lsc34_*), mas o softISP da libcamera não aplica
       LSC: exige suporte na libcamera ou outro ISP.   Precisa: [—]
  E1c. RECUPERAÇÃO AUTOMÁTICA DO SERVIÇO DE CÂMERA após falha de stream: se
       um STREAMON falha, o wireplumber/libcamera fica preso e precisa de
       restart (systemd mata após 90 s). Menos urgente: a causa (timeout do
       CCI) foi corrigida no patch 0193.   Precisa: [—]
E2. DIGITAL — parada a seu pedido. FPC via QSEECOM legado; NENHUM comando TEE
    foi executado. Achados salvos em docs/kernel/checkpoint-...-fpc.txt.


F. ÁUDIO ................................................. não iniciado
--------------------------------------------------------------------------
F1. Caminho de áudio (nodes LPASS já no kernel v2, desabilitados e fora do DT
    do U-Boot). Faltam: earpiece, detecção de fone, perfis/voz, proteção do
    alto-falante (plano de 4 passos), rádio FM.
    Precisa: [REBUILD U-Boot (DT)] + [—]


G. SISTEMA E ENERGIA ................... 5 abertos + levantamento CPU 100%
   LEVANTAMENTO COMPLETO: docs/kernel/LEVANTAMENTO-CPU-100.md
   Resumo: DT e kernel JÁ têm 8 CPUs, schedutil+energy model, cpuidle PSCI,
   tsens/thermal e interconnect. Faltam: (G1) confirmar os 8 núcleos na imagem
   atual e limpar maxcpus=6/cpufreq.off/idle=poll do fonte sm7150-motorola-
   hanoip.dts; (G2) tabelas OPP com 1 ponto só (300 MHz) travam o voto de banda
   DDR/L3 — é o teto real de desempenho e exige rebuild de U-Boot; (G3) colapso
   de cluster ativo, historicamente tela preta; (G4) térmica sob carga longa;
   (G5) suspend s2idle FUNCIONA com hook (falta soak de 3-4 ciclos; deep suspend
   não existe no kernel); (RTC) resolvido por userspace, gravação no PMIC falha
   com ERANGE (correção de kernel pendente); (boot) Plymouth causava 3 min de
   espera — mascarado, confirmar; (G6) GPU fora do escopo.
--------------------------------------------------------------------------
G1. CPUS 6/7 OFFLINE (0-5 de 0-7 online).   Precisa: [—]
G2. CPUIDLE: hoje só estados locais; o colapso de cluster foi o suspeito do
    black screen. Cluster ainda desligado.   Precisa: [—]
G3. SUSPEND/RESUME geral (nunca validado).   Precisa: [—] frente de PM
G4. WIFI POWER SAVE → 300 ms de ping local. Funciona, mas dá para ajustar.
    Precisa: [—]
G5. RTC/HORA após reboot (o relógio acerta depois? verificar).


H. PORT KALI / NETHUNTER ................................ 6 abertos
--------------------------------------------------------------------------
H1. NFC: hanoip-nfc.py pronto, app gráfico não instalado.   Precisa: [—]
H2. WAYDROID: falta ANDROID_BINDERFS no kernel.   Precisa: [REBUILD]
H3. QCE/RNG: avaliar.   Precisa: [—]
H4. WI-FI MODO MONITOR/INJEÇÃO: ath10k declara suporte, injeção não testada.
    Precisa: [HW: outro AP] + [—]
H5. SSH root + firewall (nftables já no 7.3).   Precisa: [USER]
H6. MODEM/SIM nos dois slots: modem sobe (state=running); SIM não validado.


H7. APPS DO KALI QUE FALTAM vs RECEITA OFICIAL
    firefox-esr-mobile-config (1 pkg) e mobian-phosh-phone (13 pkgs, apps de
    telefone tipo Calls). Ambos disponiveis no repo.
    Precisa: [USER] decidir
H8. FERRAMENTAS DE PENTEST
    Nao ha NENHUMA (nem nmap). A receita oficial tambem nao traz.
    Opcoes: kali-menu + conjunto escolhido (recomendado), kali-nethunter-nano,
    ou kali-nethunter-full (628 pacotes).
    Precisa: [USER] decidir + espaco no rootfs (3,8 G livres)

I. HIGIENE DO PROJETO ................................... 4 abertos
--------------------------------------------------------------------------
I1. PUSH DO GIT: tudo commitado LOCALMENTE no main; você pediu para não
    insistir no push.   Precisa: [USER]
I2. MASCARAR serial de fastboot, MACs reais e SSID antes de publicar
    (parcialmente feito segundo as notas).
I3. PROMOVER PRÉ-GOLD → GOLD só depois de B1, A1, A2 (e decidir B5).
I4. UPSTREAM (opcional): qcom_qg/qcom_smbx/DT têm correções que interessam ao
    fork sm7150-mainline (div64_s64, retificação, reconciliação do APSD,
    power-role dual).   Precisa: [USER]


ORDEM RECOMENDADA
------------------
1. B2 (instalar hanoip-usb-fix) + B1 (plugar pendrive)   → fecha o OTG
2. B3 (Fase 0: ferramenta + app)                         → o que você pediu
3. A3 + A5 (dois patches pequenos, sem reboot)            → uso diário melhor
4. A1 + A2 num único momento com o cabo no PC             → fecha a bateria
5. D1 (rotação)                                          → maior impacto visível
6. C2 (sessão longa no PC) e C3                           → polimento
7. E/F/G/H conforme prioridade sua

O QUE ESTÁ BLOQUEADO POR HARDWARE/DECISÃO (não por código)
  A1, A2 (porta fraca), B1 (periférico), B6 (hub com fonte), C2 (sessão longa),
  B5 (decisão read-only), H4 (outro AP), I1 (sua ordem).
