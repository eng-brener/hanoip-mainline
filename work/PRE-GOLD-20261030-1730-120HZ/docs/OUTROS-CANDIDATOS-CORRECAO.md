# Outros pontos para correção — nova análise

## 1. Prioridade alta: preparação de comandos DSI

Fonte: `kernel-mainline/drivers/gpu/drm/msm/dsi/dsi_host.c:2214-2265`,
funções `msm_dsi_host_xfer_prepare` e `msm_dsi_host_xfer_restore`.

Prepare ignora retornos de runtime resume, set_rate e enable do link clock,
acessa registradores e retorna zero mesmo nessas falhas. Não é o mesmo
power_on já corrigido. O manager (`dsi_manager.c:540-561`) está preparado
para receber erro do prepare e só restaurar hosts preparados com sucesso,
incluindo o caminho bonded.

Testes com funções C extraídas confirmaram, separadamente para falha de
resume, rate e enable: retorno zero e chegada aos stubs de MMIO. Na falha
de enable, restore subsequente chamou disable sem voto adquirido. São mocks,
não falha de hardware real. A API de clock real faz rollback dos enables
parciais antes de retornar erro, reforçando que não se deve fazer disable
como se enable tivesse funcionado.

Correção candidata: `pm_runtime_resume_and_get`, verificar cada retorno,
desfazer somente recursos adquiridos e impedir MMIO após falha. Preservar o
contrato do manager: prepare deve limpar suas próprias aquisições em erro;
restore só deve ser chamado após prepare bem-sucedido. Exigir regressões
para host único e ambos os hosts no caso bonded antes da integração.

## 2. Clocks: falha de reparentamento ocultada

Fonte: `dsi_host.c:420-437`, `dsi_link_clk_set_rate_6g_v2_9`.
As duas chamadas clk_set_parent apenas registram erro; a função continua e
retorna o resultado de set_rate. Teste separado de falha em cada parent
confirmou retorno zero quando set_rate tem sucesso.

Correção candidata: interromper ao falhar um parent e propagar erro, com
decisão explícita sobre recuperação de alteração parcial dos parents.
**Escopo:** tabela em `dsi_cfg.c` associa esta operação às variantes v2.9
(inclui SM8650), não demonstra uso no SM7150. É defeito geral de tratamento
de erro, não evidência de causa para o telefone atual. Menor prioridade local.

## 3. Encerramento do host: possível vazamento do último modo

`msm_dsi_host_set_display_mode` aloca com drm_mode_duplicate. A troca libera
modo anterior, mas `msm_dsi_host_destroy` não libera o último mode antes de
liberar o host gerenciado por devm. A busca no diretório DSI encontrou
drm_mode_destroy(msm_host->dev, ...) apenas na substituição de modo.
É candidato forte por inspeção, sem teste completo de unbind/teardown.
Antes de corrigir, confirmar ordenação com desligamento DRM e que nenhum
consumidor ainda usa mode. Não acionar unbind no aparelho.

## 4. Diagnóstico e backlight do painel

O risco de `panel_status_show` concorrer com desligamento/backlight continua:
há modificação temporária e restauração de `mode_flags` sem lock comum.
O lock próprio do backlight não serializa essa leitura sysfs. O callback de
backlight também restaura LPM incondicionalmente, e não o valor anterior;
não considerar isso isoladamente prova de bug funcional, pois LPM faz parte
do estado normalmente esperado no driver.

Correção requer uma estratégia comum de sincronização ou remoção/substituição
do diagnóstico ativo, não simplesmente adicionar um lock a uma função só.
Evitar deadlock: o DRM chama backlight_enable/disable sob follower_lock.
Não executar `panel_status` como teste no telefone, por regra do projeto.

## 5. Touch: sem justificativa nova para retry ou atraso

O caminho foi novamente lido; não apareceu evidência nova que permita
transformar f9 em diagnóstico ou escolher novo delay. IRQ e buffers precisam
continuar protegidos durante recarga. Repetição automática de comandos não
é uma correção demonstrada; manter fora de mudanças especulativas.

## Testes e preservação

`review_more_candidates.py` extrai funções reais e usa stubs e sanitizadores.
Executado contra árvore experimental preservada e fonte local: ambos
reproduziram os dois primeiros pontos. Resultado local em
`review-more-candidates-results.txt`. Não testa corrente, clocks físicos,
concorrência real nem boot. Nenhuma mudança adicional em drivers ou acesso
ao telefone nesta análise; correções DSI anteriores permanecem locais.

## Status das correções (atualizado)

Itens 1, 2 e 3 foram confirmados de novo e **corrigidos localmente**:
preparação de comandos com verificação de erros e liberação de PM,
propagação de falha de reparentamento e liberação do último modo no
encerramento do host. Os testes de regressão passaram, incluindo 13 cenários
do manager com host único e dois hosts. Item 4 (diagnóstico/backlight)
continua sem correção por exigir desenho conjunto de sincronização e risco de
deadlock; o touch segue sem mudança justificada. Ver
`CORRECOES-VALIDADAS.md` e `dsi-fixes-all.patch`.

Ordem recomendada: preparação de comandos; confirmação do teardown; projeto
de sincronização do diagnóstico. Reparentamento v2.9 pode ser tratado em
patch separado sem confundir com a plataforma atual.
