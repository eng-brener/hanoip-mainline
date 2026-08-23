# Checkpoint 2026-08-23 - UFS link startup

## Base segura

- Known-good: `u-boot-sd-off.img` + `kernel-usb-gadget2c.img`.
- Tela/simplefb, LCDB, `HANOIP ALIVE` e USB ACM COM8 funcionam.
- SDHC2 permanece desabilitado; testes somente com `fastboot boot`.

## Ultimo teste

- U-Boot: `u-boot-ufs-fix6.img` (19:30).
- Kernel: `kernel-ufs-fix5.img` (18:59).
- O DT efetivo passou a ter oito clocks UFS, incluindo `core_clk_ice`, e oito
  pares em `freq-table-hz`.
- O erro `freq-table-hz len mismatch` desapareceu.
- ICE inicializa como v3.1.75 e o PHY `1d87000.phy` esta bindado.
- Providers `qnoc-sm7150` estao bindados.
- O host continua deferred em `ufshcd_pltfrm_init()` e nao existe `/dev/sda`.

## Reset do PHY

Hanoip downstream e Sunfish nao declaram reset no node do PHY. Usam o
`GCC_UFS_PHY_BCR` no host e o pad dedicado `ufs_reset` para o dispositivo.
O reset do PHY foi removido deliberadamente no port. Um teste ligando-o
diretamente ao mesmo BCR do host causou `-EBUSY`. Nao recolocar reset apenas
para satisfazer `dtbs_check`; ele nao explica o defer atual, anterior a
`phy_init()`.

## Proximo passo

Instrumentar `ufs_qcom_init()` para imprimir qual etapa retorna
`-EPROBE_DEFER (-517)`: reset `rst`, PHY, ICC `ufs-ddr`, ICC `cpu-ufs`, voto de
bandwidth, GPIO `reset`, lane clocks ou ICE. Gerar uma unica imagem diagnostica,
bootar com `u-boot-ufs-fix6.img`, ler via COM8 e corrigir somente a dependencia
identificada.

## Resultado posterior - 2026-08-23

O plano acima foi executado com uma imagem diagnostica nova e instrumentacao em
`kernel-mainline/drivers/ufs/host/ufs-qcom.c` e
`kernel-mainline/drivers/ufs/core/ufshcd.c`.

### Correcoes aplicadas

- `drivers/pinctrl/qcom/pinctrl-sm7150.c`: `hanoip_tlmm.ngpios` passou de 119
  para 120, permitindo o GPIO 119 usado pelo reset do dispositivo UFS.
- DT efetivo do U-Boot:
  `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`.
- No node `ufs_mem_phy`, foi adicionado:

  ```dts
  resets = <&ufs_mem_hc 0>;
  reset-names = "ufsphy";
  ```

- O U-Boot foi recompilado como `work/u-boot-hanoip-boot.img`, tamanho
  561152 bytes. O DTB compilado confirma `reset-names = ufsphy` e o reset
  `109 0`.
- O kernel diagnostico foi empacotado como
  `work/kernel-ufs-diag-usb-v5.img`.

### Evidencia da captura

Na captura de 2026-08-23 (`Screenshot 2026-08-23 at 11.04.18 AM.png`), o erro
anterior abaixo nao aparece mais:

```text
qcom-qmp-ufs-phy: failed to get PHY reset: -2
```

O probe agora alcanca:

```text
UFS DIAG: Qualcomm variant init complete (8 lane clocks)
UFS DIAG: variant callback returned 0
UFS DIAG: ufshcd_hba_init passed
UFS DIAG: hba_capabilities passed
scsi host0
```

Isso confirma que o reset PHY no DT do U-Boot resolveu o bloqueio anterior e
que o kernel chegou a registrar o host SCSI. A captura termina antes de
`ufshcd_link_startup()` concluir e antes da enumeracao final do dispositivo
UFS (`/dev/sd*`).

### Onde paramos

- O dispositivo nao enumerou COM9 na ultima verificacao; apenas COM1 estava
  presente no Windows.
- Ainda nao foi confirmado se o link UniPro conclui, retorna erro ou trava
  dentro de `ufshcd_dme_link_startup()`.
- Proximo diagnostico: marcar `host controller enable`, `add SCSI host`,
  `link startup` e o retorno de `ufshcd_dme_link_startup()`, depois repetir o
  boot volatilo com `fastboot boot`.
