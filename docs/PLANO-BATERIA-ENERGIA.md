PLANO ABSOLUTO — SUBSISTEMA DE ENERGIA/BATERIA (hanoip + Kali)
================================================================
27/10/2026. Projeto longo, foco único: bateria, carregamento, SOC, térmica e
proteções. Nada aqui autoriza gravar partição do telefone. Toda escrita em
registrador do PMIC só entra depois de existir um "desligar" testado.


1. ESCOPO
---------
Dentro: SOC/porcentagem, carregamento (enable, corrente, tensão, terminação,
recharge), JEITA/térmica, proteções (BAT_OV, watchdog), calibração da curva,
monitoração de saúde, testes de regressão e documentação.
Fora (explicitamente): OTG/boost, USB-PD, papel de fonte, escrita em
persist/metadata, e qualquer coisa que dependa da TEE.


2. ESTADO ATUAL — FATOS MEDIDOS (27/10/2026)
--------------------------------------------
QGauge (drivers/power/supply/qcom_qg.c, do fork sm7150-mainline, upstream não tem):
  capacity 91–93% e caindo ~1% a cada 13–20 s com corrente 0 — o "sobe e desce";
  voltage_now 4,2316 V | voltage_avg 4,2297 V | voltage_ocv 4,2441 V;
  current_now 0 mA | temp 31,5 °C | charge_full 4.939.000 µAh | design 6.174.000 µAh
  cálculo atual: patch 0134 usa tabela OCV se existir, senão mapa LINEAR
  3,2–4,45 V; como o DT NÃO tem `ocv-capacity-table`, cai no linear (≈12,5 mV/1%);
  suavização (0135/0159): "caminhante" de 1% por 20 s, e só numa direção
  conforme o status → persegue o ruído sem parar.

Charger (motorola,hanoip-smb5-monitor, patch 0126 = qcom_smbx sem escritas):
  online=1 | status "Not charging" | USB 5,13 V | 93 mA | ICL 500 mA;
  tcpm-source-psy online=0; 0 escritas no PMIC (só leitura); SDAM read-only.
  Mapa de registradores já validado em LEITURA: status 0x06/0x07, APSD
  0x307/0x308, IRQ 0x310, ICL 0x607, power-path 0x60B, ICL cfg 0x370.

Térmica: 28 zonas, 31–41 °C em uso leve; zona `qcom_qg` 31,5 °C.

Benchmark do que existe fora daqui:
  - `qcom_smbx` (upstream, pmi8998/smb2) É o driver que escreve o caminho de
    energia: sequência de init, FLOAT de voltage_max_design, habilita carga e
    limita a corrente em 1 A "to minimise potential fire hazard risks".
  - `qcom_qg` NÃO existe no upstream; o próprio arquivo diz "will be rewritten".
  - `qcom_battmgr` (SOC do ADSP) só existe de sm8250 pra cima → não é caminho aqui.
  - Fairphone 4 (sm7225, mesmo PM6150L+smb5) não declara node de bateria.
  Conclusão: não há implementação de referência para copiar; a nossa tem que ser
  construída e medida.


3. POR QUE NÃO CARREGA — HIPÓTESES A CONFIRMAR (todas em leitura)
------------------------------------------------------------------
H1 CHARGING_ENABLE_CMD (0x42 bit0) = 0 → habilitação por software ausente
   (é o caso clássico: smb5-lib do Android seta no probe).
H2 USBIN suspenso (USBIN_CMD_IL 0x340 bit0).
H3 ICL/AICL em 0 ou muito baixo (ICL lê 500 mA, mas AICL pode estar parado).
H4 FLOAT_VOLTAGE (0x70) deixado pela ABL fora da faixa útil.
H5 CHGR_CFG2 (0x51): CHARGER_INHIBIT/BAT_OV/I_TERM/AUTO_RECHG em estado que
   impede a carga.
H6 Watchdog do charger expirado (0x651/0x653) → carga suspensa.
H7 Caminho Type-C não renegociado (tcpm online=0) → entrada não habilitada.
H8 Power-path não selecionou USBIN (0x60B).


4. PRINCÍPIOS DE SEGURANÇA (o "safety case")
--------------------------------------------
P1. A PARADA da carga nunca depende do nosso SOC. JEITA, BAT_OV e terminação
    são de hardware/PMIC. Se o nosso número estiver errado, nada queima.
P2. Nenhuma escrita sem um desligamento testado: parâmetro de módulo
    `enable_charge=0` (padrão), nó em sysfs, e a possibilidade física de
    desligar o cabo. Testar o "off" ANTES do "on".
P3. Limites conservadores e explícitos: FLOAT ≤ 4,40 V (design 4,44 V),
    fast-charge ≤ 1 A no início, pré-carga ≤ 500 mA, terminação ≈10% de 1 A.
    Nada de boost/OTG/PD.
P4. Toda sessão de carga é supervisionada, com medidor USB externo, log de
    1 s (V/I/T das duas pontas) e alarme sonoro/visual em 45 °C de bateria ou
    50 °C no conector. Sessões curtas (15 min) no começo.
P5. Reversibilidade: cada experimento tem imagem de kernel anterior guardada
    com hash e procedimento de volta.
P6. Uma mudança por vez, com a mesma instrumentação antes/depois.
P7. Se em algum momento aparecer `health != Good`, temperatura subindo sem
    carga, ou corrente acima do limite → parar a série e investigar.


5. FASES
--------
B0 — DIAGNÓSTICO SOMENTE-LEITURA (1–2 dias)
   - dump dos registradores do smb5 por debugfs/SPMI (só leitura) ou nó
     temporário read-only no driver; documentar o mapa real desta PMIC.
   - identificar a causa (H1..H8) com evidência.
   - montar instrumentação: medidor USB, script `batt-log` (1 s, CSV),
     script de alarme de temperatura.
   Aceite: relatório com cada bit relevante, causa raiz identificada, e
   instrumentação funcionando.
   Risco: nenhum (só leitura).

B1 — SOC ESTÁVEL, SEM TOCAR EM ENERGIA
   - DT: `ocv-capacity-table-0` (Li-ion, topo 4,44 V) + resistência interna.
   - driver: estimar por tensão MÉDIA − I·R; histerese de 2%; deriva ≤1% a cada
     2–3 min nas duas direções; snap em 100% quando FULL e em 0% no fim.
   - testes: 15 min ocioso (não pode variar), abrir apps (sem pulo), reboot
     (coerência), carga/descarga depois de B4.
   Aceite: variação ≤1% em 15 min ocioso; nenhum salto >2% sob carga.
   Risco: baixo (reporte apenas; não escreve no PMIC).

B2 — CARACTERIZAÇÃO ELÉTRICA E TÉRMICA (sem carga)
   - tabela de consumo por cenário (idle, tela, CPU, Wi-Fi, modem);
   - margem térmica real nas zonas da bateria, conector e chg-skin;
   - definir os limites concretos que B3 vai usar.
   Aceite: tabelas publicadas e limites numéricos aprovados.
   Risco: baixo.

B3 — HABILITAÇÃO MÍNIMA DE CARGA (passo crítico)
   - habilitar enable + FLOAT conservador + ICL 500 mA + pet de watchdog;
     JEITA e BAT_OV verificados como ativos (não apenas assumidos).
   - 15 min supervisionados; medir corrente real e temperatura a cada 1 s.
   Aceite: corrente de carga > 300 mA, T bateria < 43 °C, nenhum erro de PMIC,
   e desligar o cabo devolve o sistema ao estado anterior sem resíduo.
   Risco: alto se sem supervisão; controlado com P2–P4.

B4 — RAMPA, TERMINAÇÃO E RECHARGA
   - subir para 1 A em degraus de 250 mA (cada degrau: 15 min + térmica);
   - habilitar terminação por corrente; validar FULL, retomada automática;
   - validar pré-carga com bateria baixa quando houver oportunidade.
   Aceite: 20%→100% sem intervenção, 5 ciclos seguidos, 20 plug/unplug,
   T < 43 °C, zero watchdog trip.
   Risco: médio (térmica).

B5 — CALIBRAÇÃO DA CURVA (só depois de B4)
   - registrar pares (OCV, %) em 2 ciclos completos; ajustar tabela e R_interna
     no DT; repetir até estabilizar.
   Aceite: erro ≤3% nos pontos de referência; sem oscilação.
   Risco: baixo (mexe só em reporte).

B6 — CASOS DE BORDA
   - SDP/CDP/DCP, cabo ruim, carregador fraco, bateria quase vazia, boot com
     cabo plugado, resume de suspend, temperatura alta/baixa, desligar durante
     a carga.
   Aceite: matriz completa sem travar, sem carga indevida, sem corromper fs.

B7 — SAÚDE DE LONGO PRAZO
   - monitorar capacity/health/deriva, log persistente, alertas;
   - avaliar limite de carga (ex.: parar em 90%) para uso contínuo no cabo.
   Aceite: 2 semanas de uso com dados coerentes e sem regressão.

B8 — REGRESSÃO E DOCUMENTAÇÃO
   - script único `batt-selftest` que roda a matriz inteira e dá veredito;
   - checkpoint com evidências, patches numerados, imagens + SHA256SUMS,
     e procedimento de volta atrás.


6. MATRIZ DE TESTES (resumo)
----------------------------
Teste                        Método                     Limite/passe
---------------------------- ----------------------------------------------
SOC parado                   15 min ocioso             variação ≤ 1%
SOC sob carga                abrir 5 apps, scroll      nenhum salto > 2%
SOC após reboot              reboot + comparar         diferença ≤ 2%
Carga mínima                 cabo + ICL 500 mA         I > 300 mA, T < 43 °C
Rampa                        degraus de 250 mA         T < 43 °C por degrau
Ciclo completo               20%→100%                  automático, sem trip
Terminação/Recharga          cheio, depois 1 h         FULL correto, recharga ok
Plug/unplug                  20×                        sem travar, sem resíduo
Térmica extrema              carga + CPU 100%          JEITA reduz, não passa
Watchdog                     sessão longa              nunca expira sem pet
Bateria baixa                descarregar até <5%       pré-carga entra, sem queda
Boot com cabo                boot com USB              sobe normal, carga correta
Suspend com cabo             suspender/resumir         carga continua
Regressão geral              batt-selftest             100% dos itens


7. RISCOS E MITIGAÇÕES
----------------------
Sobrecarga            → FLOAT ≤4,40 V, BAT_OV verificado, JEITA ativo
Sobretemperatura      → JEITA + alarme 45 °C + supervisão + sessões curtas
Watchdog do charger   → pet implementado e testado; detectar expiração por log
SOC errado            → nunca usado para decisão de segurança (P1)
Travar o PMIC         → enable_charge=0 por padrão; cada escrita com rollback
Perder dados          → imagem crua + snapshot antes de B3
Brick                 → nenhuma escrita em partição (regra do projeto)
TEE/persist           → nada aqui toca persist; sem QSEECom


8. O QUE NÃO FAZER (anti-padrões)
---------------------------------
- Não usar o `qcom_smbx` upstream as-is (mapa do smb2, sem JEITA nosso, e ele
  escreve FLOAT/habilita carga sem o nosso envelope).
- Não habilitar OTG/boost/PD nesta trilha.
- Não confiar no SOC do qg para parar carga.
- Não carregar sem supervisão nem sem medidor externo.
- Não "calibrar" antes de ter carga controlada (B4).
- Não gravar partição, não mexer em persist/metadata.


9. ENTREGÁVEIS
--------------
- kernel v4: SOC com OCV + histerese (B1)
- kernel v5: charger `hanoip-smb5` com enable conservador (B3/B4)
- DT: tabela OCV calibrada + resistência interna (B1/B5)
- `batt-log` (CSV V/I/T), `batt-alarm` (térmico), `batt-selftest` (matriz)
- docs: este plano + um checkpoint por fase com evidências
- imagens de kernel com hash + procedimento de reversão


10. DEFINIÇÃO DE PRONTO (subsistema de energia)
-----------------------------------------------
[ ] carrega de 20% a 100% sozinho, 5 ciclos, T < 43 °C, sem trip
[ ] plug/unplug 20× sem falha; boot com cabo ok; suspend com cabo ok
[ ] SOC estável (≤1% em 15 min ocioso) e erro ≤3% após calibração
[ ] JEITA e BAT_OV comprovadamente ativos (evidência, não suposição)
[ ] zero escrita acidental: enable_charge=0 desliga tudo, comprovado
[ ] `batt-selftest` 100%
[ ] 2 semanas de uso diário sem regressão e sem overheating
