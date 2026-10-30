# Revalidação dos achados e correções locais

Escopo: `kernel-mainline/drivers/gpu/drm/msm/dsi/dsi_host.c`. Patch
autoritativo e autossuficiente: `dsi-fixes-all.patch` (aplicar com `-p2`).
`dsi-fixes-batch1-lancamento.patch` é o registro do primeiro lote e NÃO deve
ser aplicado depois do patch completo.

## Classificação após conferir APIs e testar

**Defeitos de código confirmados e corrigidos:**

1. Parser de lanes acessava tabela mesmo após detectar índice inválido.
   Agora rejeita toda entrada >3 antes de indexar. Removido teste `<0` em u32.
2. DSC fazia módulo por dimensão de slice sem verificar zero. Agora retorna
   MODE_H_ILLEGAL/MODE_V_ILLEGAL. Defesa contra configuração inválida do
   driver, não prova de falha na configuração atual 540x10.
3. Retorno de runtime resume era ignorado no power_on.
   `pm_runtime_resume_and_get` verifica sucesso e não mantém referência na
   falha, conforme `include/linux/pm_runtime.h`. Nada de programação DSI
   posterior nesse erro.
4. Falha de clock após adquirir PM vazava referência no power_on. Novo label
   libera PM antes de desfazer reguladores. Não chama disable em clock cujo
   enable falhou: callbacks de clock já desfazem seus enables parciais.
5. Erro DSC em `dsi_timing_setup` era perdido porque a função retornava void.
   Agora retorna int; o erro sai antes dos writes de timing e power_on desfaz
   clocks/PM/reguladores, sem reset/enable nem power_on=true.

**Segundo lote, confirmado e corrigido:**

6. `msm_dsi_host_xfer_prepare` ignorava erros de resume, set_rate e enable do
   clock, acessava registradores e retornava zero. A falha de enable também
   levava restore a desabilitar um clock nunca adquirido. Agora os três
   retornos são verificados e o PM é liberado no erro; nenhum MMIO ocorre.
   O manager já esperava esse contrato (`dsi_manager.c:540-561`).
7. `msm_dsi_host_destroy` não liberava o último `msm_host->mode`, alocado com
   `drm_mode_duplicate`/`kzalloc_obj` e portanto fora de devm. Agora libera
   após drenar o workqueue e antes de destruir mutexes. `msm_host->dev` pode
   ser NULL em caminho de erro inicial e `drm_mode_destroy` já trata NULL.
8. `dsi_link_clk_set_rate_6g_v2_9` registrava falha de `clk_set_parent` e
   seguia, retornando sucesso se o set_rate funcionasse. Agora propaga o erro
   e não chama set_rate. **Escopo:** usado por variantes DSI v2.9 (inclui
   SM8650); não demonstrado no SM7150. Correção geral, sem efeito esperado
   neste aparelho.

**Endurecimento, com limite explícito:** criação do modo novo ocorre antes de
liberar o anterior, então -ENOMEM preserva o modo antigo. Isso NÃO torna o
callback void de mode_set atômico nem propaga erro ao compositor; a
recuperação integral da troca em falta de memória continua não resolvida.

**Não corrigidos por não haver defeito ou causa demonstrada:** significado de
`f9`, suposto atraso insuficiente, ausência de retry no touch e piscada
durante modeset completo. Touch, painel, LCDB, backlight e DT não mudaram.
A concorrência de `panel_status_show` e o estado parcial de regulador seguem
documentados e exigem projeto próprio, não patch pontual.
`msm_dsi_host_init` pode deixar mutexes sem init se falhar antes de
`mutex_init`, mas isso hoje é mascarado por `destroy_workqueue(NULL)`
protegido: o caminho de destroy já tolera o estado parcial. Não alterado.

## Preservação

- Nenhum DT, regulador, touch, painel, imagem de kernel ou módulo persistente
  alterado. Nenhum comando no telefone, reboot, instalação ou flash.
- Volumes fonte/objetos da baseline montados somente leitura; port e
  compilação em diretório descartável no container.
- Não houve commit; demais mudanças do usuário preservadas.

## Testes executados

Execução em `dsi-fixes-build-test-results.txt`, aplicando o patch completo
sobre cópia descartável da árvore experimental e rodando as duas suítes
(`--fixed`) mais a compilação ARM64.

- Funções C reais extraídas, com stubs externos e UBSan/bounds:
  lanes inválidas, slices zero, falhas de resume/rate/enable/pinctrl/timing,
  falta de memória, preparação de comando, reparentamento e teardown.
- 13 cenários reais de `msm_dsi_manager_cmd_xfer` (host único e dois hosts):
  falha de preparação em cada host não executa comando nem deixa voto;
  sucesso e erro de comando continuam liberando os dois hosts.
- Regressões touch (8192 coordenadas, pacotes e firmware inválidos) e LCDB
  (fault injection e concorrência) continuam passando.
- Objeto corrigido compilou ARM64 com o comando Kbuild salvo e `-Werror`;
  ELF AArch64 confirmado. Sem ligação completa, módulo instalado ou boot.
- Checkpatch do patch completo: zero erros e zero avisos.
  `git diff --check` limpo.
- Controle: `review-more-candidates-original-results.txt` mostra a árvore
  experimental original ainda reproduzindo os três defeitos do segundo lote.

Os stubs não validam corrente, clocks físicos, concorrência real, runtime PM
real, o driver inteiro no kernel nem boot. Nada disso autoriza instalar a
versão corrigida no aparelho.

## Reproduzir

```sh
docker run --rm -v hanoip-display120-test-20261030:/test:ro \
  -v "$PWD:/repo:ro" hanoip-kernel73-v3 \
  python3 /repo/work/display-120hz-20261030/compile_dsi_fixes.py
```
