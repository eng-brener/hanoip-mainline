# PM6150L LCDB - Estado Conhecido e Mapa de Registros (Moto G60 / hanoip)

Referencia para o port do driver LCDB do PM6150L (bloco lcdb@ec00, slave SPMI 5).

Fonte: qpnp-lcdb-regulator.c (downstream kernel-hanoip-pixelbuilds) + pm6150l.dtsi.

> REGRAS DE SEGURANCA: nao fazer scan do SPMI, nao ler offsets
> desconhecidos, nao escrever por tentativa. Somente ler/escrever os
> registros abaixo (comprovados pelo downstream).

## Acesso

- Driver node: pm6150l_lcdb: qcom,lcdb@ec00 (dentro de pmic@5, USID 5)
- reg = <0xec00 0x100>
- interrupts = <0x5 0xec 0x1 IRQ_TYPE_EDGE_RISING> ("sc-irq")
- qcom,pmic-revid = <&pm6150l_revid> (downstream)
- qcom,voltage-step-ramp;
- regmap: dev_get_regmap(pdev->dev.parent, NULL) (padrao mainline SPMI)

## Register map (offsets da base 0xec00)

| Offset | Registro | Bits | Nota |
|--------|----------|------|------|
| 0x08 | STS1 | | status |
| 0x0A | STS3 | BIT7 = LDO_VREG_OK | |
| 0x0B | STS4 | BIT7 = NCP_VREG_OK | |
| 0x10 | INT_RT_STATUS | BIT0 = VREG_OK, BIT1 = SC_ERROR | poll de enable |
| 0x41 | BST_OUTPUT_VOLTAGE | GENMASK(5,0), step 25mV, min 4700mV | boost |
| 0x45 | MODULE_RDY | BIT7 | set se nao pronto |
| 0x46 | ENABLE_CTL1 | BIT7 = MODULE_EN, BIT6 = HWEN_RDY | enable compartilhado |
| 0x47 | BST_PD_CTL | | |
| 0x4B | BST_ILIM_CTL | GENMASK(2,0) + BIT7 EN | 200-1600mA |
| 0x50 | PS_CTL | | |
| 0x55 | BST_VREG_OK_CTL | GENMASK(1,0) | |
| 0x5B | BST_SS_CTL | | |
| 0x5F | SOFT_START_CTL (common) | GENMASK(1,0) | |
| 0x66 | PWRUP_PWRDN_CTL | GENMASK(1,0) pwrdn 0-8ms | |
| 0x71 | LDO_OUTPUT_VOLTAGE | GENMASK(4,0) | LAB |
| 0x77 | LDO_PD_CTL | | |
| 0x79 | LDO_FORCE_PD_CTL | BIT0 EN, BIT7 MODE | discharge |
| 0x7B/0x7C | LDO_ILIM_CTL1/2 | GENMASK(2,0) + BIT7 EN | 110-460mA |
| 0x7F | LDO_SOFT_START_CTL | GENMASK(1,0) | |
| 0x81 | NCP_OUTPUT_VOLTAGE | GENMASK(4,0) | IBB |
| 0x87 | NCP_PD_CTL | | |
| 0x8B/0x8C | NCP_ILIM_CTL1/2 | GENMASK(1,0) + BIT7 EN | 260-810mA |
| 0x8F | NCP_SOFT_START_CTL | GENMASK(1,0) | |
| 0xD0 | SEC_ACCESS | 0xA5 unlock | |

## Voltage mapping (confirmado na branch Motorola)

- Range LDO/NCP: **4000 mV .. 6000 mV**
- BST: Vout_Boost = headroom + max(LAB, IBB); headroom 150 mV (nao-PM660L);
  step 25 mV; min 4700 mV; max 6275 mV; mask GENMASK(5,0)
- LAB/LDO (0x71) e IBB/NCP (0x81), SET_OUTPUT_VOLTAGE_MASK = GENMASK(4,0):

```
if (mv < 4950)  val = (mv - 4000) / 100            /* 100 mV step */
else            val = (mv - 4950) / 50 + 0xA       /* 50 mV step, offset 0xA */
```

- Read-back:

```
val < 0xA : mv = 4000 + val*100
val >= 0xA: mv = 4950 + (val-0xA)*50
```

- Alvos do painel: LAB = 5500 mV, IBB = 5500 mV (magnitude; IBB e negativo
  fisicamente, mas o regulator framework usa valor positivo)
  -> BST = 5500 + 150 = 5650 mV (~5.65V, coerente com o medido)

## Enable sequence (modulo)

```
1. [se voltage_step_ramp] set LDO=4500, NCP=4500 (VOLTAGE_START_MV)
2. set BST = max(LAB, IBB) + headroom
3. set LDO voltage (0x71)
4. set NCP voltage (0x81)
5. ENABLE_CTL1 (0x46) = MODULE_EN_BIT
6. poll INT_RT_STATUS (0x10) BIT0 (VREG_OK), timeout ~10
   delay = soma dos soft_start + vreg_ok_debounce (BST/LDO/NCP)
7. [se voltage_step_ramp] subir LDO/NCP em steps de 500mV ate o alvo
```

## Disable sequence (PM6150L - sem FORCE_PD_WA)

```
1. [se FORCE_PD_ENABLE_WA] LDO_FORCE_PD_CTL = EN|MODE   (NAO e o caso PM6150L)
2. ENABLE_CTL1 (0x46) = 0
3. [se FORCE_PD_WA] sleep 10ms; LDO_FORCE_PD_CTL = 0      (NAO e o caso PM6150L)
```

> PM6150L subtype 0x1F NAO esta na lista de workarounds (PMI632, PM8150L
> tem FORCE_PD; PM660L tem NCP_SCP). O disable PM6150L e o caminho simples.

## Bootloader handoff

No probe/hw_init, LER (nao escrever):
- 0x46 (MODULE_EN) -> se setado, lcdb_enabled = true (adotar estado)
- 0x41 (BST), 0x71 (LAB), 0x81 (IBB) -> read-back das voltagens
- 0x45 (MODULE_RDY) -> se !ready, set MODULE_RDY (unica escrita aceita no handoff)

## Referencia downstream

- Driver: kernel-src/kernel-hanoip-pixelbuilds/drivers/regulator/qpnp-lcdb-regulator.c
- DTS: kernel-src/kernel-hanoip-pixelbuilds/arch/arm64/boot/dts/qcom/pm6150l.dtsi
- Status no Moto: &pm6150l_lcdb { status = "ok"; }  (sm6150-moto-common-overlay.dtsi)
- Consumo: lab-supply = <&lcdb_ldo_vreg>; ibb-supply = <&lcdb_ncp_vreg>; no dsi_ili7807s_tm_678_vid_display