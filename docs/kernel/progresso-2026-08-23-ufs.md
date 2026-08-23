# Progresso 2026-08-23 - UFS PHY reset e link startup

## Estado

O probe UFS do kernel mainline deixou de falhar ao buscar o reset do PHY. A
imagem usada foi `work/kernel-ufs-diag-usb-v5.img`, com o U-Boot
`work/u-boot-hanoip-boot.img`.

## Correcoes

- `kernel-mainline/drivers/pinctrl/qcom/pinctrl-sm7150.c`: Hanoip passou a
  declarar 120 GPIOs, incluindo o GPIO 119 do reset UFS.
- No DT efetivo do U-Boot,
  `uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip.dts`, o
  node `ufs_mem_phy` passou a declarar:

  ```dts
  resets = <&ufs_mem_hc 0>;
  reset-names = "ufsphy";
  ```

- O DTB compilado foi validado com `reset-names = ufsphy` e reset `109 0`.

## Evidencia

A captura `Screenshot 2026-08-23 at 11.04.18 AM.png` mostra:

```text
UFS DIAG: Qualcomm variant init complete (8 lane clocks)
UFS DIAG: variant callback returned 0
UFS DIAG: ufshcd_hba_init passed
UFS DIAG: hba_capabilities passed
scsi host0
```

O erro anterior `qcom-qmp-ufs-phy: failed to get PHY reset: -2` nao aparece.
O host SCSI foi registrado; a captura termina antes de a inicializacao do
link UniPro e a enumeracao final do UFS concluirem.

## Ponto atual

- Nao ha `/dev/sd*` confirmado.
- A ultima verificacao no Windows mostrou somente COM1; COM9 nao enumerou.
- Ainda nao sabemos se `ufshcd_link_startup()` retorna erro ou trava dentro de
  `ufshcd_dme_link_startup()`.

## Proximo passo

Adicionar marcadores em `ufshcd.c` antes e depois de `ufshcd_hba_enable()`,
`ufshcd_add_scsi_host()`, `ufshcd_link_startup()` e
`ufshcd_dme_link_startup()`. Recompilar uma imagem diagnostica e repetir o
boot volatilo com `fastboot boot`.
