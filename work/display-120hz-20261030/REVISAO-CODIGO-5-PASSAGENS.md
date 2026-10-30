# Revisão de código em cinco passagens — 30/10

Escopo: driver `ilitek-hanoip-spi.c`, driver de painel
`panel-ilitek-ili7807s.c` experimental, diff 120 Hz e interfaces imediatas
DRM/SPI/backlight. A cópia de touch em `kernel-mainline` foi comparada com
`/test/linux` no volume Docker: idêntica byte a byte; painel difere apenas
pelo diff experimental. Citações de painel abaixo usam numeração da cópia
baseline em `kernel-mainline`; o diff desloca linhas na variante. Não é uma
auditoria integral do kernel, firmware, Phoc ou hardware. Revisão estática,
sem injeção de falhas, execução de testes novos ou mudanças no telefone.

## 1. Memória e limites

- Firmware: tamanho mínimo do cabeçalho antes das leituras, tamanhos e offsets
  fixos, limite de cada bloco antes do CRC, tamanho final exato. As cópias de
  SPI ficam dentro de ILI_XFER para os tamanhos usados; os dez slots cabem no
  relatório de 43 bytes. Não foi identificado overflow neste escopo.
- Não significa segurança provada para entradas arbitrárias de todo o kernel.

## 2. Falhas e propagação

- **Confirmado no código — erro de DSI suprimido:** em
  `kernel-mainline/drivers/gpu/drm/panel/panel-ilitek-ili7807s.c:189-206`,
  `ili7807s_off` pode falhar, é registrado no log, mas `ret` é substituído
  pelo retorno de `regulator_bulk_disable`; se este for zero, unprepare
  retorna sucesso. O desligamento deve continuar para segurança; porém a
  falha DCS deixa de ser representada no retorno. Não demonstra que isso
  ocorreu nesta sessão; o DRM usa callback void no topo e é necessário
  projetar tratamento de estado antes de modificar o retorno.
- **Confirmado — sem recuperação autônoma:** no touch, linhas 346-363,
  qualquer falha de `ili_start` deixa IRQ desabilitada e encerra o worker,
  sem nova tentativa até próxima ativação. Isso é limitação de robustez
  observada em logs, não prova de falha percebida pelo usuário. Retry deve
  ser limitado e sincronizado com power-off; não aplicar cegamente.
- **Risco de estado parcial de energia:** se `regulator_bulk_disable` falhar,
  reset já foi afirmado mas unprepare retorna erro; DRM
  `drm_panel.c:218-226` mantém `prepared=true`. Próximo prepare pode ser
  ignorado mesmo com painel em reset. Cenário condicional não reproduzido;
  sem saber garantias do regulador não se presume quais rails ficaram ligados.
- **Variante experimental, baixa probabilidade:** helper de modo preferido
  retorna 0, não negativo, se alocação falha (`drm_probe_helper.c:1158-1169`).
  O diff só testa `< 0`, e pode então anunciar apenas o modo experimental se
  sua alocação seguinte funcionar. Viola intenção de preservar 60 Hz como
  modo preferido; condicionado a falha de memória, não observado.

## 3. Concorrência e sincronização

- **Risco concreto de corrida:** `panel_status_show` em linhas 380-400 lê
  `prepared`, modifica `dsi->mode_flags`, envia leituras e restaura flags sem
  lock comum com unprepare ou backlight (`:222-234`) e com o próprio caminho
  do painel. Leituras simultâneas podem restaurar estado de flags obsoleto ou
  disputar o desligamento; `drm_mipi_dsi.c:456` consulta esse campo para LPM.
  Não há prova de ocorrência ou relação com falhas atuais. A leitura desse
  diagnóstico já é desaconselhada no projeto; não exercitá-la no aparelho.
- IRQ touch é desabilitada/sincronizada antes do worker acessar buffers SPI;
  power-off chama `cancel_work_sync`. Não se demonstrou corrida nesses
  caminhos; isso não prova ausência de todas as corridas do kernel.

## 4. Estados, inicialização e encerramento

- Se sair do modo ICE falha, `ts->ice` só muda após transferência bem-sucedida
  (`:81-95`, `:228-235`); estado software/hardware pode divergir após erro SPI.
  Uma tentativa posterior faz reset e volta a habilitar ICE, mas a correção
  sob falhas nessa sequência não está demonstrada. Risco condicional, sem
  evidência de que explique payload f9 (que passou no ACK não-ICE).
- Recursos devm são registrados em ordem: remoção do follower antes de liberar
  IRQ e limpeza do worker/firmware; DRM remove o follower com lock e chama o
  callback de desligamento quando necessário. Não identificado use-after-free
  nesse caminho por inspeção estática.

## 5. API, aritmética e visibilidade

- Modos calculados: 60 e 119,976 Hz com clock inteiro idêntico, tamanho e DSC
  inalterados; os limites sintáticos dos timings são consistentes. Isso não
  valida especificação elétrica ou imagem.
- `rejected` mistura falhas SPI, checksum, tipo e coordenadas; `restarts` só
  conta sucesso. Não são contadores de falhas percebidas. Amostras sem lock
  não são instantâneo coerente entre campos.
- A ausência de EBUSY ou IRQ DSI não comprova qualidade visual ou que todas as
  operações de painel deram certo. O usuário relatou piscada só durante troca
  e funcionamento normal do touch.

## Prioridade

1. Planejar correção de concorrência do diagnóstico e cobertura por testes
   locais com falhas, sem ler `panel_status` no dispositivo.
2. Projetar recuperação touch limitada e cancelável e testar estados de falha
   antes de qualquer teste físico. Não ativar IRQ antes da confirmação.
3. Definir semântica de falha/rollback do painel com o core DRM e testar com
   falhas simuladas; evitar mudanças de regulador sem revisão de segurança.
4. Corrigir o caso de alocação no patch experimental e testar localmente.

Nenhum dos achados acima prova a causa do f9, da piscada ou do EBUSY.
