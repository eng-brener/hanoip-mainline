Kernel 7.3 hanoip — v8: correções DSI + modo de 120 Hz (30/10/2026)
===================================================================

Base: exatamente o listener7 (work/kernel-7.3/v7): upstream v7.3 + os 195
patches, árvore 276fbce0ae673c83e456cfe359c33ed3c4e3468b. A Image.gz NÃO
muda: `msm` é módulo (CONFIG_DRM_MSM=m), então o kernel continua sendo o
listener7 validado e só módulos são reconstruídos.

patches/
  0196-dsi-guards.patch          correções no driver DSI (ver abaixo)
  0197-marker.patch              marcador `hanoip-dsi-guards` no dmesg, para
                                 provar em runtime qual módulo carregou
  0198-panel-120hz-candidate.patch  anuncia 1080x2460 @ 119,976 Hz como modo
                                 extra, mantendo 60 Hz como preferido

Árvore esperada depois de 0196+0197 (conferida pelo build):
  e0bc45ad28f73ba4f0858f0a97988e351efa09f5
O 0198 (painel) é aplicado depois da conferência, porque não altera o msm.

Correções em 0196 (todas com teste de regressão em host):
  1. dsi_host_parse_lane_data rejeita lane > 3 antes de indexar a tabela.
  2. msm_dsi_host_check_dsc rejeita slice_width/slice_height zero.
  3. msm_dsi_host_power_on usa pm_runtime_resume_and_get e trata o erro;
     falha de clock libera o runtime PM; falha de DSC desfaz o caminho.
  4. dsi_timing_setup retorna int e propaga erro.
  5. set_display_mode aloca o novo antes de liberar o antigo; power_on exige
     modo definido.
  6. xfer_prepare verifica resume/rate/enable, sem MMIO após erro e sem
     vazar voto de PM.
  7. destroy libera o último modo (alocado fora do devm).
  8. dsi_link_clk_set_rate_6g_v2_9 propaga falha de clk_set_parent (afeta
     variantes v2.9; não demonstrado no SM7150).

Construir:
  ./build.sh
  -> msm-dsi-guards.ko.zst e panel-ili7807s-120hz.ko.zst (vermagic limpo
     7.3.0-sm7150; o script recusa árvore com "+").
  Usa o mesmo container e volume do v7 (hanoip-kernel73-v3-src).

Empacotar a imagem volátil de teste:
  work/display-120hz-20261030/mkimg-dsifix-120hz.py monta
  kernel-listener7-dsifix-120hz.img a partir da imagem listener7, injetando
  os dois módulos no initramfs antes do switch_root. Nada é gravado em
  partição; o módulo do rootfs não é substituído.

Resultado medido no aparelho (30/10, PRE-GOLD-20261030-1730-120HZ):
  6 trocas 120<->60 com rc=0, 6 ciclos LCDB com VREG_OK, 6 recargas do touch
  sem falhas e sem resposta f9, DSI irqs=0, 119,976 FPS de aplicação, imagem
  e toque confirmados pelo usuário, 41,9-45,4 °C. Prova de carga do módulo:
  Build ID 73daad11ed466f94ad82ea2547e3dbe24806210e (o original é 62e041c5...).

Limites: apagar/acender pelo compositor derruba a sessão (também com o msm
original; A/B pendente); login com 119,976 Hz salvo deu tela preta com
Timeout de 3 s do Phoc; suspend, uso prolongado, térmica sustentada e
medição óptica não validados. Voltar a 60 Hz antes de encerrar a sessão.

REPRODUZIBILIDADE MEDIDA (30/10/2026)
=====================================
`./build.sh` foi rodado do zero: árvore v7 conferida (276fbce0), correções
aplicadas, árvore final conferida (e0bc45ad) e módulos gerados.

  msm-dsi-guards.ko.zst        e45516eec237ef31...  BYTE-IDÊNTICO ao módulo
                               que foi carregado no aparelho no teste de
                               120 Hz (mesmo SHA256 do snapshot).
  panel-ili7807s-120hz.ko.zst  e78b54c03026cbaa...  NÃO é byte-idêntico ao
                               artefato testado (72e3d9f8...): aquele foi
                               compilado à mão na sessão anterior, com
                               86.720 bytes contra 86.888 agora, mesmo
                               vermagic e mesmo marcador de 120 Hz.
                               Para repetir exatamente o boot validado, use
                               o artefato do snapshot; para um build novo,
                               use este e revalide no aparelho.

Para a Image do kernel, ver a seção REPRODUZIBILIDADE do v7: fonte, config e
DT reproduzem; a Image ainda difere em 10.382 bytes com banner idêntico.
