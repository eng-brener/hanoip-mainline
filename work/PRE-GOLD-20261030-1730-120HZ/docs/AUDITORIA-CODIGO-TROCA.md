# Auditoria do caminho de troca de modo e touch — 30/10

Escopo: variante experimental do painel e caminho relevante do kernel 7.3
compilado em `hanoip-display120-test-20261030`, comparados ao patch v7 do
touch, aos eventos de runtime e ao diff experimental. Não é auditoria de
todo o kernel, firmware fechado ou código-fonte do Phoc da distribuição.
Nenhum teste adicional, alteração no telefone ou correção foi feito.

## Caminho da troca e piscada

1. O diff `experimental-120hz.patch` apenas anuncia segundo modo Tianma;
   clock permanece 343458 kHz, vtotal muda de 5039 para 2520, VFP de 2565
   para 46, mesmo tamanho, quatro lanes, DSC e sequência de inicialização.
   Nenhum caminho de troca contínua ou comando especial de frequência foi
   implementado no patch.
2. `drivers/gpu/drm/msm/msm_atomic.c:213-249` executa no commit MSM os
   helpers de modeset disables e enables. Os helpers DRM atuam na cadeia de
   bridges quando `drm_atomic_crtc_needs_modeset()` indica modeset; a bridge
   `drivers/gpu/drm/bridge/panel.c:113-186` chama os quatro callbacks do
   painel prepare/enable/disable/unprepare. O log confirma o caminho de
   desligamento e religamento do LCDB em cada uma das três últimas trocas.
3. O driver do painel `panel-ilitek-ili7807s.c:141-207` envia display-off,
   aguarda 50 ms, envia sleep-in e aguarda 150 ms; depois aciona reset e
   desabilita reguladores. Ao preparar, habilita reguladores, espera 20 ms,
   executa reset e inicialização: sleep-out, espera 120 ms, display-on,
   espera 20 ms e envia configuração e PPS DSC. O DSI manager também tem
   rotinas de power off/on e reprogramação do modo. O caminho é de fato uma
   reativação completa, não switch transparente.
4. Isso explica por que se espera uma interrupção visível durante um modeset
   completo e é consistente com o relato de piscada somente na transição;
   não prova duração exata, qualidade da imagem ou que o primeiro apagamento
   tenha a mesma causa. DSI irqs=0 não é medição visual e não valida o switch.

## Touch: protocolo, ACK e recuperação

O patch `work/kernel-7.3/v7/patches/0125-hanoip-touch.patch` inclui o driver
integral. Follower desliga IRQ e libera slots em panel_disabling, com
`cancel_work_sync`; panel_enabled agenda worker que carrega e verifica IRAM,
consulta versão e só depois habilita IRQ. Se houver erro, worker termina sem
retry automático. Os logs mostram uma resposta f9 durante troca 60→120,
seguida de reativação bem-sucedida posterior. O usuário reportou touch normal;
não inferir efeito percebido anterior ou sua duração.

Na leitura não-ICE `ili_transfer` valida `rx[1] == 0xa3` antes de copiar o
payload de `rx+3`. Assim, como `FW response f9` foi efetivamente impresso,
essa transferência passou pela checagem de ACK em software. Isso não garante
ausência de erro elétrico, nem dá significado ao primeiro byte do payload.
Foram verificados todos os bytes dos três blocos *antes* de reset de código
e verificação de versão; isso não prova que o firmware executou corretamente
ou que a resposta recebida corresponde ao comando esperado.

O código espera 20 ms após sair de ICE e mais 20 ms após o comando 0x21,
mas não confirma disponibilidade antes da consulta e não tem retry. Timing,
resposta antiga, estado do controlador e transporte são hipóteses não
comprovadas; não se deve presumir que mais atraso corrija ou que f9 signifique
busy. Os buffers SPI são compartilhados; o worker desabilita e sincroniza a
IRQ antes de operar, e `cancel_work_sync` sincroniza com power-off. Não foram
demonstradas corridas nesses caminhos pelo material disponível.

`rejected` junta erro de transporte, checksum, identificação e coordenadas;
`restarts` só conta inicializações bem-sucedidas. Não localizam nem
classificam impactos físicos. Logs posteriores: IRQs/reports voltaram a
crescer e há reload bem-sucedido às 16:48:47.

## Conclusões e limites

- Piscada de transição: desligamento completo é confirmado pelo código e
  pelo LCDB. Troca sem piscar exigiria novo projeto de modo dinâmico, com
  validação da capacidade do painel, DSC, DSI e sincronização; não basta
  omitir desligamento nem trocar apenas o VFP em runtime.
- Uma verificação interna touch falhou em troca controlada; não é demonstrado
  que 120 Hz seja causa ou que usuário tenha percebido perda de toque.
- EBUSY: saída Phoc não identifica ponto de retorno -EBUSY; casos prévios a
  60 Hz existem. Não confundir com DSI nem atribuir ao touch.
- Candidato 120 não foi validado para uso prolongado, óptico ou condições
  variadas. Não modificar drivers, forçar IRQ, fazer ciclos rápidos ou
  instalar módulo persistente sem um plano próprio e autorização.
