# Revisão ampliada — passagens 6 a 10

30/10/2026. Escopo ampliado para DSI host/manager, DSC, runtime PM, parser
de lanes, integração backlight/follower, LCDB, parser de pacotes e firmware.
Sem acesso ou escrita no telefone. Não foram corrigidos drivers.

## Fonte e método

Funções C extraídas da árvore experimental no volume Docker montado RO,
`hanoip-display120-test-20261030:/test`, não apenas modelos reescritos.
APIs externas substituídas por stubs para controlar entradas e falhas.
Compilação C11 com UBSan/bounds e parada no primeiro erro; testes isolados
para as duas reproduções de comportamento indefinido esperado. Saída em
`review-host-tests-results.txt`, suíte em `review_host_tests.py`.

DSI host SHA256:
`badf944989869515b4af5c0548272d385c8a1c607f5d704646b7866d22b3bb0a`.
Touch SHA256:
`61f3746a27cafaaf882f74f0ce98d816bbd97c4b5286a12cd433bdf8a36c7bcf`.
LCDB da árvore experimental e de `kernel-mainline` são byte-idênticos;
DSI host/manager diferem (inclusive API de bridges), por isso os testes usam
os arquivos da árvore experimental. Não são KUnit, boot, teste elétrico,
prova formal ou auditoria de todo o kernel.

## Passagem 6 — entrada DT e limites no DSI

**Novo bug reproduzido: acesso fora dos limites.** Em
`drivers/gpu/drm/msm/dsi/dsi_host.c`, `dsi_host_parse_lane_data`, o código
detecta lane >3 mas apenas imprime erro e segue para `swap[lane_map[j]]`.
O índice vem de `u32`, logo o teste `< 0` também não é útil. Configuração
simulada `{4,1,2,3}` reproduziu erro UBSan de acesso sem espaço para int.
O teste percorre os swaps e acaba fora da tabela. Requer DT inválido; não é
entrada livre de usuário nem prova de problema no DT atual. Correção candidata:
rejeitar o valor antes de indexar; não aplicada.

## Passagem 7 — DSC e geometria

**Novo bug defensivo reproduzido: divisão por zero.** Em
`msm_dsi_host_check_dsc`, linhas 2682/2688 da árvore experimental, há módulo
por `slice_width`/`slice_height` sem validar zero. Slice width=0 reproduziu
UBSan. Configuração real do painel define 540/10; esta condição não está
demonstrada no aparelho. Origem é configuração do driver, não modo userspace
arbitrário sozinho. Testes da geometria 1080x2460 válida e dimensões inválidas
1079/2459 retornaram os resultados esperados.

**Risco adicional por inspeção, não reproduzido integralmente:**
`dsi_timing_setup` retorna void; erro de `dsi_populate_dsc_params` provoca
return local, mas `msm_dsi_host_power_on` continua com reset/enable e marca
power_on. Sem propagação da falha de cálculo, configuração parcial pode ser
tratada como sucesso. A suíte não executou a cadeia real de cálculo DSC.

## Passagem 8 — runtime PM, falhas e vida do modo

**Dois novos bugs de tratamento de falha reproduzidos**, em
`msm_dsi_host_power_on` (árvore experimental, região 2545–2620):

1. `pm_runtime_get_sync` não tem retorno verificado. Stub de resume=-EIO,
   com demais chamadas bem-sucedidas, alcançou `dsi_timing_setup` e terminou
   com retorno zero e power_on=true. Não foi executado MMIO real; é a
   continuidade indevida do fluxo que foi reproduzida.
2. Após aquisição de runtime PM, falha em link_clk_set_rate/enable salta
   para `fail_disable_reg`, sem `pm_runtime_put`. Falha simulada de enable
   retornou -EIO, mas deixou contagem PM=1. Pode acumular voto e impedir
   economia de energia. Uma falha em pinctrl segue outro label e tem put;
   isso não torna o caminho de clock correto.

**Falha de alocação reproduzida, impacto parcial:**
`msm_dsi_host_set_display_mode` libera o modo anterior antes de duplicar o
novo; -ENOMEM deixa mode=NULL. `dsi_mgr_bridge_mode_set` ignora esse retorno.
O teste confirmou perda do modo, não crash posterior. Há guarda contra NULL
em `dsi_calc_clk_rate_6g`; portanto não é correto afirmar que a sequência
necessariamente causa null dereference no aparelho. Falta desenho transacional
e tratamento da falha entre as APIs.

## Passagem 9 — pacotes e firmware touch

Executada função `ili_irq` original com 4096 valores de X e 4096 de Y,
checksum recalculado em cada pacote, coordenada acima do limite, checksum
inválido, tipo inesperado e erro SPI. Verificados retorno, contadores,
coordenadas enviadas e ausência de eventos parciais nos pacotes rejeitados.
Passou. Não cobre todas combinações de dez contatos, IRQs reais, firmware
ou simultaneidade com hardware.

Executado `ili_validate_firmware` original com imagem sintética válida
(CRC32 BE implementado no harness), 106 comprimentos truncados/excedentes,
100 mutações dos bytes de metadados e corrupção de cada um dos três blocos.
Todas rejeições ocorreram como esperado e original válido foi aceito.
Não cobre todas mutações possíveis nem prova correção da carga no chip.

## Passagem 10 — LCDB, votos e integração de estados

Reexecutada suíte existente que extrai as funções LCDB reais e fornece regmap
com falhas: handoff ABL, ordens de desligamento, votos independentes, falhas
de leitura/escrita, short circuit, timeout, rollback, tensão/headroom e duas
threads executando 100 ciclos cada sob mutex. Passou. Stubs não reproduzem
temporização elétrica, efeitos de escrita parcial, nem todos os contratos
do regulator core. Não foram inventados novos bugs LCDB para completar cinco
passagens.

Backlight tem locks próprios no core, mas não compartilha lock com
`panel_status_show`; o risco já registrado continua. Ordem de teardown do
follower é coerente com callbacks devm no caminho examinado. Nenhum novo
use-after-free demonstrado; não equivale a prova geral de ausência.

## Resultado e ordem de prioridade

- Reproduzidos quatro novos defeitos gerais: índice de lane sem rejeição,
  slice zero, resume PM ignorado e voto PM não liberado em falha de clock.
- Reproduzida perda do modo em -ENOMEM; impacto completo depende da cadeia.
- Encontrado risco adicional de cálculo DSC sem propagação de erro.
- Touch e LCDB passaram nos casos locais descritos, com limites explícitos.
- Nenhum achado demonstra causa de f9, piscada ou EBUSY. Não há confirmação
  de manifestação desses novos bugs no telefone.

Correções devem ser propostas e testadas separadamente: validações antes
dos acessos, balanceamento PM em cada saída, criação do modo novo antes de
trocar ponteiros e propagação de erro DSC. Não mudar energia, DT ou módulo
persistente como consequência automática desta revisão.

Reprodução:

```sh
docker run --rm -v hanoip-display120-test-20261030:/test:ro \
  -v "$PWD:/repo:ro" hanoip-kernel73-v3 \
  python3 /repo/work/display-120hz-20261030/review_host_tests.py \
  --source /test/linux --repo /repo
```
