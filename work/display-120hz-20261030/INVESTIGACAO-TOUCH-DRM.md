# Investigação: touch e commits DRM nos 120 Hz (30/10/2026)

## Evidência do boot

- `touch-panel-kernel-events.txt` e `phoc-modeset-events.txt`: recortes de
  journal com relógio monotônico, coletados por leitura. Não são trace de SPI
  nem de chamadas DRM. DSI error_snapshot irqs=0 na coleta.
- Duas respostas `f9 00...` após três blocos IRAM verificados, ~429,418 e
  430,563 s de uptime. O driver rejeitou a versão e deixou IRQ desabilitada;
  reinícios posteriores completaram, o último às 438,785 s. Usuário confirmou
  que o touch voltou a funcionar. Stats posteriores: 3520 IRQs, 3511 reports,
  9 rejected e 10 restarts; totais do boot, não localizar no tempo por si só.
- Correção do usuário: ele não percebeu erros no toque durante o uso. As duas
  mensagens são falhas internas de verificação do driver, não comprovam que o
  toque tenha falhado para ele nem estabelecem duração ou impacto percebido.
- Eventos EBUSY do phoc aparecem tanto no início quanto em 356,036/356,053 s
  e 521,196 s, fora da sequência de reativação do touch em 425–439 s. Não há
  evidência de relação causal entre essas ocorrências e os dois erros do touch.

## Touch: origem e hipóteses

### Nova ocorrência e comparação temporal

No uptime 761,990 s houve uma terceira resposta f9: LCDB disabled em
761,097 s, enabled/VREG_OK em 761,523 s, três blocos verificados e resposta
467 ms após enabled. O desligamento seguinte só foi registrado em 762,921 s;
não há evidência de que esse desligamento posterior tenha causado a resposta.
Recargas em 763,704, 765,060 e 768,880 s terminaram com sucesso. As duas
falhas anteriores tiveram intervalos disabled→enabled de 191 e 224 ms, e a
terceira de 426 ms; também há sucessos com intervalos menores (por exemplo
56 ms nas trocas de modo). São tempos do log LCDB, não medições da alimentação
do chip touch: não estabelecem limiar, causalidade ou uma correção por atraso.
Todas as três falhas ocorreram durante reativações a 119,976 Hz; não houve
controle suficiente em 60 Hz para concluir exclusividade. Não há trace SPI
ou evidência de impacto percebido; usuário informou toque normal.

Detalhe dos contadores: `restarts` incrementa apenas após `ili_start()`
bem-sucedido, não contabiliza falhas. `rejected` inclui falha de leitura SPI,
checksum, tipo de pacote ou coordenadas inválidas; o contador não diferencia
essas causas. Não é número de falhas de toque percebidas. Os totais após os
eventos eram irqs=3764 reports=3749 rejected=15 restarts=15.

As três trocas de modo controladas às 16:46–16:47 geraram recargas válidas;
nenhum EBUSY aparece na janela das trocas e dos ciclos intermediários no
journal consultado. Isso não demonstra que não ocorrerão depois. Na última
consulta DSI irqs=0 e modo 60 Hz habilitado. Consulta apenas de leitura.

Fonte exata da baseline: `work/kernel-7.3/v7/patches/0125-hanoip-touch.patch`.
Após checagem byte a byte dos blocos e reset, `ili_check_running_firmware`
envia F6/21 e 21, aguarda 20 ms e aceita somente versão esperada; `f9 00...`
gera `-EBADMSG`. `ili_restart_work` retorna sem habilitar IRQ em erro; outro
ciclo bem-sucedido torna a habilitá-la. `cancel_work_sync` no panel_disabling
sincroniza o trabalho, mas os eventos não provam a causa da resposta inválida.

Referência downstream do mesmo aparelho, commit fixo:
https://github.com/Motorola-SM6150/android_kernel_motorola_sm6150/tree/503bfd1297f7c57662a4dc07f643e2a967d54ed1/drivers/input/touchscreen/ilitek_v3_mmi

- `ilitek_v3.h` define `SPI_ACK = 0xA3`; no downstream, esse ACK é testado em
  outro byte da transferência, não é equivalente à resposta de versão `f9`.
  Não foi encontrado significado comprovado de `f9` no payload.
- `ilitek_v3_hostdl.c` tenta o upgrade de IRAM até três vezes e, se falhar,
  contém caminho adicional de reset. É referência para pesquisa, NÃO prova de
  que repetir a checagem ou repetir todo o download seja seguro/correto aqui.
- `ilitek_v3_ic.c` tem teste busy específico com comando 0xF3 e resposta 0x41
  em modo AP; isso não interpreta `f9` e não deve ser enviado ao aparelho sem
  desenhar teste e autorização apropriados.
- Trabalhar offline em proposta com tentativas limitadas e canceláveis, distinguir
  resposta transitória de falha persistente, evitar IRQ antes da confirmação,
  sincronizar com power-off e garantir que falha final fique explícita. Não
  programar flash, não reativar IRQ cegamente e não copiar recovery downstream.
- Necessários controle a 60 Hz com espaçamento de ciclos, repetição em 120 Hz,
  telemetria de cada etapa e validação de toque depois de cada falha. Não fazer
  novos ciclos rápidos antes de planejar segurança/retorno com usuário.

## DRM/Phoc: o que é e o que falta

- Kernel 7.3 v7 `drm_atomic_helper_setup_commit` contém retornos -EBUSY para
  commit nonblocking quando `flip_done` anterior ainda não terminou em CRTC,
  conector ou plano. É uma explicação possível; o log do Phoc só reporta
  `Device or resource busy`, não indica qual retorno ocorreu nesta sessão.
- `docs/kernel/LEVANTAMENTO-GPU.md` documenta ocorrências anteriores com
  investigação em 60 Hz; não prova a origem das ocorrências deste boot.
- Documentação Linux sobre commits atômicos e eventos:
  https://docs.kernel.org/gpu/drm-kms.html
- Caso semelhante histórico em outro hardware/wlroots, não prova de mesma causa:
  https://github.com/swaywm/wlroots/issues/2492
- Precisamos de medição controlada e logging/trace limitado com critérios para
  evitar inundação de log, correlação com atividade do compositor e comparação
  60/120; não modificar flags DRM ou forçar `flip_done` sem plano e autorização.

## Limites

Pesquisa web e consultas do dispositivo foram somente leitura. Não há teste
controlado que prove falha exclusiva a 120 Hz ou correção validada. 60 Hz segue
modo preferido; 119,976 Hz foi selecionado na sessão experimental. Não mexer
no sensor de luz, pausado pelo usuário. Não executar novos resets ou writes sem
escopo autorizado; preservar par PRE-GOLD e não iniciar Android.
