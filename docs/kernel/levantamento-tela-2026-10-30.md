# Tela do hanoip — levantamento de capacidades e pendências (30/10/2026)

Escopo: análise dos registros locais de display, auditoria Android e patches
da baseline v7, mais consultas somente leitura no aparelho. Este levantamento
não comprova todos os recursos de fábrica nem autoriza alterações no aparelho.
Documentos antigos descrevem etapas anteriores e não são o estado atual.

## Painel e modos

- Referência Android em `work/device-audit-2026-10-24/LEIA-ME.txt`: painel
  Tianma ILI7807S, 1080x2460, quatro lanes DSI RGB888, DSC 8 bpc/8 bpp,
  fatias 540x10, duas por pacote. A referência é um Android downstream em uso,
  não uma ROM stock intacta.
- DT Android coletado em `work/device-audit-2026-10-24/hardware-selected.json`
  anuncia DFPS **60 e 120 Hz**, com atualização imediata por VFP. Não lista
  90 Hz; menções a 90 Hz no README e documentos antigos não são prova. A lista
  120/90/60 em `stock-live-tree.json` pertence a outro nó, o painel Sharp qsync,
  e não deve ser atribuída ao Tianma ativo.
- Em 30/10 `wlr-randr` anuncia apenas 1080x2460 a 60 Hz; painel apagado por
  inatividade. Patch `work/kernel-7.3/v7/patches/0120-hanoip-panel-ili7807s.patch`
  define um único modo Tianma a 60 Hz e DSC. 120 Hz ainda não foi implementado
  nem validado. Não aplicar timings de outro painel ou dobrar clock às cegas.
- Investigar implementação downstream de DFPS e capacidade DRM/DSI/DSC do
  kernel efetivo, timings/VFP, clocks, banda e mudança entre modos. Preparar
  variante local preservando o par PRE-GOLD; medir modo e transições, integridade
  visual, erros, temperatura e consumo antes de considerar o recurso pronto.
  A título apenas aritmético, mantendo clock e htotal do modo de 60 Hz, a
  metade de vtotal=5039 é 2519,5 linhas: VFP seria aproximadamente 45–46
  linhas com os demais parâmetros iguais. Isto **não** é timing validado nem
  prova de compatibilidade, e não deve ser usado para configurar o aparelho.
  A análise da PR em `work/upstream-review-2026-10-24/open-prs.json` relata
  falhas de troca dinâmica em outro painel: serve de alerta, não de receita.
- Investigação adicional: o fonte Motorola comunitário fixado no commit
  `503bfd1297f7c57662a4dc07f643e2a967d54ed1`, arquivo
  `arch/arm64/boot/dts/qcom/dsi-panel-mot-tianma-ili7807s-678-1080x2460-video.dtsi`,
  declara o próprio Tianma em 120 Hz com VFP=46, VBP=12, VPW=2 e horizontais
  28/24/4, compatível com o cálculo aproximado. Fonte:
  https://github.com/Motorola-SM6150/android_kernel_motorola_sm6150/blob/503bfd1297f7c57662a4dc07f643e2a967d54ed1/arch/arm64/boot/dts/qcom/dsi-panel-mot-tianma-ili7807s-678-1080x2460-video.dtsi
  Porém o mesmo fonte declara `non_burst_sync_event` e reset 10/10/10 ms,
  enquanto o DT efetivamente coletado do aparelho usa burst e 4/1/12 ms.
  Não copiar a configuração completa nem tratar a coincidência do VFP como
  validação do modo na baseline; reconciliar variantes e clocks primeiro.
- Aritmética reproduzível sem acesso ao aparelho: 60 Hz atual usa htotal=1136,
  vtotal=5039 e clock ideal 343458,24 kHz (código arredonda para 343458 kHz).
  VFP 46 dá vtotal=2520 e, com esse mesmo clock, ~119,9761 Hz. Exatamente
  120 Hz exigiria ~343526,4 kHz; são clocks diferentes em ~0,020%. Não supor
  que ajuste de clock nem que troca seamless seja aceitável sem estudar o PLL.
- No downstream `drivers/video/fbdev/msm/mdss_dsi.c`,
  `mdss_dsi_dfps_config()` chama `__mdss_dsi_update_video_mode_total()` para
  mudança por porch: atualiza o registrador de total DSI e, quando configurado,
  usa timing double-buffer. O `dsi_manager.c` local por outro lado contém
  `mode_set` e valida clock/DSC; a presença desses callbacks não demonstra
  suporte a mudança imediata sem desligar o painel. Avaliar modeset completo
  primeiro e transição seamless separadamente, sem extrapolar de outro painel.
- Pesquisa pública adicional: a documentação Qualcomm define explicitamente
  `dfps_immediate_porch_mode_vfp` como mudança imediata pelo front porch
  vertical: https://android.googlesource.com/kernel/msm/+/refs/heads/android-msm-coral-4.14-android12-qpr1/Documentation/devicetree/bindings/drm/msm/mdss-dsi-panel.txt
  A PR pública https://github.com/sm7150-mainline/linux/pull/67 continua aberta
  e trata de outro painel: relata funcionamento de modos isolados, mas também
  falhas na troca repetida. Não aplicar seu patch ou seus timings no Tianma.
- O código upstream fixado em v7.3 usa `drm_connector_helper_get_modes_fixed`
  com um único `ctx->desc->mode`. O patch 0120 da baseline mantém esse desenho;
  por isso o segundo modo exige alterar a enumeração do painel, não apenas o
  DT. Manter 60 Hz como preferido por segurança e evitar selecionar 120 Hz
  automaticamente; a validação de clock/DSC no bridge não prova que o painel
  aceite o modo nem que a troca seja segura.

## Luz, cor e qualidade

- Backlight WLED: escala atual sysfs 0..4095; Android anuncia mínimo 27,
  máximo 4095 e padrão 2047. Não presumir que as curvas ou luminância coincidam.
  Em 30/10 brightness e actual_brightness eram 160, bl_power=4 (apagado).
- Consulta posterior: `/sys/class/backlight/backlight` aponta para o WLED do
  PMIC em `leds@d800`; com tela ligada mostrava 4095/4095 e bl_power=0. O
  driver do painel busca backlight externo primeiro e usa DCS como fallback;
  brilho WLED não é equivalente ao comando DCS 0x51 do painel. A referência
  `work/hanoip-display-20261024/upstream-provenance.txt` decodificou
  `string-cfg=7` como bitmask de strings 0, 1 e 2, corrigindo hipótese antiga
  de quatro strings; não alterar configuração elétrica sem análise e autorização.
- Verificação offline do DTB efetivamente embutido na PRE-GOLD 1430, usando
  `scripts/fdt_diff.py` como parser: `leds@d800` compatible qcom,pm6150l-wled,
  status okay, `qcom,enabled-strings = <0 1 2>`, default-brightness 512 e
  max-brightness 4095; `panel@0` referencia esse backlight e o compatible
  Tianma. Valores são configuração, não medição de corrente ou luminância.
- Ajuste de mínimo, curva, persistência, uniformidade e eventual flicker em
  diferentes níveis ainda requerem validação visual e/ou medição; não alterar
  limites elétricos WLED ou LCDB por tentativa.
- Sensor de luz funciona segundo `onde paramos.md`; brilho automático e sua
  curva no Phosh não foram validados de ponta a ponta.
  Na consulta atual os serviços SSC e iio-sensor-proxy estavam ativos e o
  D-Bus anunciava sensor de luz; `LightLevel=0` nessa amostra não comprova
  leitura física válida sem cliente habilitado e teste controlado. A mesma
  consulta indicou `HasProximity=false`, coerente com a corrida já registrada.
  Consulta posterior de GSettings do usuário kali: `ambient-enabled=true`,
  `idle-delay=300` segundos, `lock-enabled=true` e `orientation-lock=true`.
  São valores configurados, não prova de resposta efetiva do brilho, de que a
  tela bloqueia exatamente nesse intervalo, ou de validação dos sensores.
- Android declara comandos CABC UI/vídeo/off e HBM on/off; patch de painel
  inclui 0x55 0x01 na inicialização, o que não prova comportamento ou controles
  funcionais. HDR e primárias também são declarados no DT Android: isso não
  prova HDR funcional no pipeline Linux nem níveis físicos medidos. Confirmar
  suporte do driver/compositor, calibração e segurança antes de expor controles.
- Validar cores, contraste, gama e brilho ao sol; sem colorímetro não afirmar
  fidelidade ou valores em nits. Recursos como HDR, HBM e CABC são pendentes
  de verificação, não promessas de implementação.

## Confiabilidade e interação

- `docs/kernel/checkpoint-2026-10-25-display-robustness.txt`: nove ciclos de
  alimentação do painel passaram em variante antiga, não uma garantia da
  baseline atual ou suspend/resume prolongado. FIFO DSI de partida ainda
  intermitente; o checkpoint não demonstrou correção universal.
- Consulta passiva atual do `error_snapshot` em `ae94000.dsi`: irqs=0; isso
  cobre somente o boot atual e não prova ausência de falha intermitente em
  outros boots. `wlr-randr` mostrou 60 Hz, escala 3 e transform normal.
- Testar apagamento, bloqueio e retomada na baseline atual, além de tela
  acendendo sozinha durante conexão ao computador; medir sem polling LP DCS de
  panel_status, conhecido como arriscado. Não confundir DPMS Off com defeito.
- `onde paramos.md`: rotação foi deliberadamente desligada pelo usuário devido
  a inversões do Phosh no bloqueio/resume; não religar sem pedido. Toque nas
  bordas, calibração e gestos foram adiados; capacidades downstream não provam
  suporte no driver mainline.
- Patch v7 `0125-hanoip-touch.patch`: driver SPI declara dez slots e faixa
  0..1079 x 0..2459; o comentário exclui gestos e programação flash. Ele
  recarrega firmware em IRAM após desligamento do painel. O checkpoint físico
  comprovou até dois dedos, não dez; toque duplo para acordar, rejeição de
  palma e taxa de amostragem do toque não estão comprovados.
- Um travamento GPU/Waydroid e uma falha do Phosh foram observados; mecanismos
  exatos e mitigação llvmpipe ainda não comprovados. Tratar separadamente de
  defeito físico de painel.

## Ordem proposta

1. Preservar baseline e terminar instalação em andamento; inventariar modo,
   logs e configuração por leitura.
2. Validar com o usuário brilho, flicker, cores, bloqueio e toque; corrigir
   configurações somente com autorização específica para escrita no aparelho.
3. Estudar e preparar suporte 120 Hz offline; não confundir uma configuração
   plausível com teste físico. Se houver mudança de DT, o DT efetivo vem do
   U-Boot embutido: rebuild U-Boot e comparar DTBs com `scripts/fdt_diff.py`.
4. Testar variante por boot volátil, sem flash e preservando os artefatos
   conhecidos, somente após coordenação dos riscos; validar 60/120, troca e
   regressões. Não modificar partições sem autorização específica.

## Matriz de aceitação proposta — ainda não executada

| Frente | Evidência exigida | Limite atual |
|---|---|---|
| 60 Hz | boots repetidos, imagem confirmada, contador DSI antes/depois | zero erros em um boot não garante repetibilidade |
| 120 Hz | modo listado e escolhido, taxa medida no scanout com conteúdo em movimento, imagem íntegra, sem incremento de erros | só existe candidato de timing; não há teste |
| troca 60/120 | alternâncias repetidas, sem travamento, timeout, artefatos ou perda de toque | modeset completo e seamless são problemas distintos |
| luz | valores baixo/médio/alto, visibilidade e flicker com observação/medição | faixas do Android não são curva de luminância |
| cores/HDR | padrões SDR e comparação; colorímetro/HDR pipeline se disponíveis | DT declara HDR, sem prova do resultado físico |
| auto-brilho | cobrir/expor sensor, confirmar lux válido e resposta com usuário | serviço ativo sozinho não prova controle automático |
| repouso | apagar/acender, bloqueio e resume repetidos, imagem e toque | ciclos antigos não comprovam o kernel atual |
| toque | grade, bordas, releases e multitouch com participação física | dois dedos validados; dez apenas declarados |
| segurança | temperaturas, consumo, registros e par de retorno durante experimentos | limites elétricos e comandos de teste não foram autorizados |

## Consulta passiva em aparelho ligado — 30/10 16:13

Baseline Linux 7.3.0-sm7150 #64, uptime ~2792 s. DSI-1 conectado e On;
`wlr-randr` anuncia somente 1080x2460 a 60 Hz, transform normal e escala 3.
`error_snapshot`: irqs=0, sem bits FIFO/PHY/timeout registrados neste boot.
WLED: brightness=actual_brightness=max_brightness=4095, bl_power=0.
Touch Ilitek SPI está enumerado em event3; isso não testa contatos físicos.
SSC e iio-sensor-proxy ativos; proxy informa HasAmbientLight=true,
LightLevel=0 e HasProximity=false; zero não é lux validado. Pico térmico da
amostra 58,7 °C em cpu6; temperatura de bateria 34,7 °C em outra amostra.
Waydroid session RUNNING, container FROZEN; status não prova uso de software
ou ausência de riscos gráficos. Journal do phoc contém mensagens históricas
`Atomic commit failed: Device or resource busy` às 15:42–15:43: não atribuir
causa nem concluir que persistem no momento. Nenhuma configuração foi alterada.

O usuário confirmou que a imagem parece normal e que o toque nos cantos e
laterais parece estar certo. Avaliação visual e qualitativa, sem medição de
coordenadas, teste exaustivo ou validação de gestos/multitouch. Sensor de luz
e brilho automático foram pausados a pedido do usuário.
