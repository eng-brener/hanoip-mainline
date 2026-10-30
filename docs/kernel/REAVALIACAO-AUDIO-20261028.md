# Reavaliação do áudio do zero — 28/10/2026 (tarde)

Pedido do usuário: rever o áudio ponto por ponto, contra as extrações do
Android, o fonte do vendor, o upstream e as referências da internet.
Resultado: **o codec WCD937x funciona no mainline (playback e captura sem
EIO)**. As conclusões "DSP aborta" e "falta o voto DCODEC" das seções 11-18 do
checkpoint `checkpoint-2026-10-28-audio-codec-tentativa.txt` estavam ERRADAS.
Tudo abaixo foi medido na etapa 10 já bootada, só com `amixer`/`aplay`/`arecord`
(sem rebuild, sem reboot, sem escrita em partição).

## 1. Premissas da sessão anterior, uma por uma

| # | Premissa anterior | Veredito | Prova |
|---|---|---|---|
| 1 | Falta votar o bloco DCODEC (o vendor usa `audio-ref-clk` com `codec-ext-clk-src = 9`) | **Falsa** | No techpack (`audio-ext-clk-up.c`, `dt-bindings/clock/qcom,audio-ext-clk.h`), 9 = `AUDIO_LPASS_CORE_HW_VOTE`, que chama `afe_vote_lpass_core_hw(AFE_LPASS_CORE_HW_MACRO_BLOCK, "LPASS_HW_MACRO")`. É o bloco **MACRO** (3), que o mainline já vota com sucesso. DCODEC seria o 11 (`AUDIO_LPASS_AUDIO_HW_VOTE`), e **nenhum nó do stock usa 11**. O Android desta placa nunca vota DCODEC; o EUNSUPPORTED do ADSP para o bloco 4 é coerente com isso. |
| 2 | O ADSP aborta a porta CODEC_DMA "sem reportar erro" | **Falsa** | Com o mux de entrada do macro configurado, a mesma porta roda (rc=0). |
| 3 | Falta widget AIF no wcd937x | **Falsa** | O upstream liga macro↔codec pelo `audio-routing` do card (`IN1_HPHL ← HPHL_OUT`...). O patch AIF não era necessário. |
| 4 | Mux 2 no pino 24 causa RCU stall por "interação com cluster idle" | Mal atribuída | O pino 24 do vendor é o pino 6 do mainline (seção 8 do checkpoint). O pino 24 do mainline cai em 0x62b6a000, fora do bloco. Escrever ali mexe em outro hardware do LPASS. |
| 5 | Clock do rxmacro com ids de TX | **Verdadeira** (bug real do sm7150.dtsi) | Mantida a correção da etapa 10. |
| 6 | Reset do WCD = `<&lpass_tlmm 6>` | **Verdadeira** | Attached/Attached. |

## 2. A causa real do EIO (medida)

Configuração da etapa 10 em runtime: `RX_MACRO RX0/RX1 MUX = ZERO`,
`TX DEC0 MUX = MSM_DMIC`, `TX SMIC MUX0 = ZERO`, todos os `* Switch` do codec
em off. Ninguém tinha configurado os **muxes do macro**: as tentativas só
mexeram em controles do codec (EAR_RDAC/HPHL/RDAC3).

Teste de isolamento (mesmo boot, só uma variável muda por linha):

| Teste | Resultado |
|---|---|
| playback, caminho `handset` completo | rc=0 |
| playback com `RX_MACRO RX0 MUX = ZERO` | **EIO** |
| playback com `HPHL Switch` (porta SWR) off | rc=0 (roda, mas o codec fica sem dados) |
| captura, `amic1` completo | rc=0 |
| captura com `TX DEC0 MUX = MSM_DMIC` | **EIO** |
| captura com `ADC1 Switch` off | rc=0 |

Mecanismo: sem o mux, o widget `RX AIF1 PB` / `TX_AIF1 CAP` do macro não liga
no DAPM. A interface CODEC_DMA do LPASS não é habilitada, o DSP fica sem
consumo e o ALSA devolve EIO. Durante o play medido: `RX AIF1 PB → RX0 MUX →
INT0 INTERP → DEM MUX → HPHL_OUT` passam de Off para On, e 5 registradores do
rx_macro mudam. No codec, `ANA_EAR` (0x300a) = 0x80 (PA ligado),
`RX_SUPPLIES` = 0xc1. Desligar `EAR_RDAC` zera tudo, e religar restaura.

### Segundo defeito: um FE para os dois sentidos

O card só tem o FE MultiMedia1. O `q6routing` guarda **um** `port_id` por
sessão (`struct session_data`, `session->port_id = be_id` no put do mixer).
Com `RX_CODEC_DMA_RX_0 ← MM1` e `MM1 ← TX_CODEC_DMA_TX_3` ligados ao mesmo
tempo:
- a captura abre o ADM com a porta errada: `cmd 0x10325 (ADM_CMD_DEVICE_OPEN_V5) error 0x2` (EBADPARAM) → EIO;
- full-duplex: `Audio Client already active` + `q6asm_open_write error 9`.

Isso explica por que "play e capture davam EIO" mesmo quando parecia tudo certo.
Upstream (sm8250-mtp, sweet) sempre tem MultiMedia2/3 separados.

## 3. Mapa dos microfones (medido, bate com o stock)

| Caminho | Medição (3 s, ganho 10) |
|---|---|
| `TX SMIC MUX0=ADC0` + `ADC1` (amic1) | sinal vivo, −60 dBFS ambiente |
| `TX SMIC MUX0=ADC2` + `ADC2 MUX=INP3` (amic3) | sinal vivo, −66 dBFS |
| `ADC2 MUX=INP2` (amic2 = mic do fone) | ~0 (sem fone plugado, esperado) |
| `TX SMIC MUX0=ADC1` | canal morto (só transiente DC) |

O stock tem exatamente `TX SWR_ADC0 ← ADC1_OUTPUT` e `TX SWR_ADC2 ← ADC2_OUTPUT`
no `qcom,audio-routing`, e o mixer_paths usa os mesmos ADC0/ADC2.

## 4. Receitas de mixer (Android mixer_paths.xml + switches de porta do mainline)

Earpiece (`handset`):
```
RX_CODEC_DMA_RX_0 Audio Mixer MultiMedia1 = 1
RX_MACRO RX0 MUX = AIF1_PB
RX INT0_1 MIX1 INP0 = RX0
RX INT0 DEM MUX = CLSH_DSM_OUT
RDAC3_MUX = RX1
EAR_RDAC Switch = 1
RX_EAR Mode Switch = 1
HPHL Switch = 1          # porta SWR que carrega RX1 (mainline)
EAR_PA Volume = 8        # 0 = +6 dB ... 16 = -18 dB
```
Fone (`headphones`): `RX_MACRO RX0/RX1 MUX = AIF1_PB`, `RX INT0/INT1_1 MIX1
INP0 = RX0/RX1`, `RX INT0/INT1 DEM MUX = CLSH_DSM_OUT`, `HPHL/HPHR_RDAC Switch
= 1`, `HPHL/HPHR Switch = 1`, `RX HPH Mode = CLS_H_LOHIFI` (UCM upstream).
Mic principal (`amic1`): `MultiMediaN Mixer TX_CODEC_DMA_TX_3 = 1`,
`TX DEC0 MUX = SWR_MIC`, `TX SMIC MUX0 = ADC0`, `TX_AIF1_CAP Mixer DEC0 = 1`,
`ADC1_MIXER Switch = 1`, `ADC1 Switch = 1`, `ADC1 Volume` ~8-10.
Mic 2 (`amic3`): igual, mas com `SMIC MUX0 = ADC2`, `ADC2_MIXER Switch`,
`ADC2 Switch`, `ADC2 MUX = INP3`. Mic do fone: `ADC2 MUX = INP2`.

## 5. Etapa 12 (preparada)

`uboot-sm7150/.../sm7150-motorola-hanoip-audio-etapa12.dts`, sobre a etapa 5:
clock RX corrigido, `audio-routing` do stock/upstream (no lugar das rotas
"WCD AIF Playback" da etapa 9, que deixavam o codec sempre energizado), FE
MultiMedia2 só de captura, MultiMedia1 só de playback, link do alto-falante
de volta. `fdt_diff` contra a etapa 10: só nós de áudio, mais renumeração de
phandle. Imagem: `work/uboot-builds-20261026/out/sm7150-motorola-hanoip-audio-etapa12/`
(img b48e15e4...).

## 6. Etapa 12 bootada: do "sem EIO" ao som de verdade (28/10 noite)

Validado pelo usuário, de ouvido: **fone L+R, earpiece, mic do headset
(voz natural no loop gravação → fone) e mic do aparelho** (loop acústico
alto-falante → mic1: 440 Hz a 55,1 contra 0,15 em silêncio, ~+51 dB).

Mics do aparelho com voz real (gravação → reprodução no alto-falante,
confirmado pelo usuário nas duas): amic3 (`SMIC ADC2` + `ADC2 MUX=INP3`,
o `handset-mic` do Android) rms 104 / pico 1118; amic1 (`SMIC ADC0` + ADC1)
rms 15 / pico 117 com ganho 10, ~17 dB abaixo. Para voz, use o amic3 como
mic principal; o amic1 precisa de mais ganho.

### 6.1 Causa raiz do HPHL/earpiece mudos: bug de memória no upstream

`wcd937x-sdw.c` (série "static channel mapping") faz no probe:

    for (i = 0; i < master_ch_mask_size; i++)
        wcd->ch_info[i].master_ch_mask = WCD937X_SWRM_CH_MASK(map[i]);

`qcom,tx-channel-mapping` tem **12** entradas (binding, qcm6490-idp, sweet),
mas `wcd937x_sdw_tx_ch_info[]` tem **11**. No `.ko` compilado:
`tx_ch_info @0x2c8` (0x84 bytes) e logo depois `rx_ch_info @0x350`. A 12ª
escrita cai em `rx_ch_info[0].ch_mask` (HPH_L) com `BIT(4-1) = 0x8`.

Medido no master SWR RX (`DP1 PORT_CTRL` 0x1124 = ch_mask<<24 | ... ):

| switches | antes do fix | depois |
|---|---|---|
| só HPHR | 0x02000003 | — |
| só HPHL | **0x08000003** | 0x01000003 |
| HPHL+HPHR | **0x0a000003** | 0x03000003 |

Sintomas que isso explica: fone esquerdo mudo, earpiece mudo (o EAR usa
RX1 = dado do HPHL via `RDAC3_MUX=RX1`), `HPHL PDM WDOG INT` disparando e
estalos. Fix: limitar os laços a `ARRAY_SIZE()` de cada tabela.
Patch: `work/audio-20261028/patches/0010-ASoC-codecs-wcd937x-sdw-bound-the-static-channel-map.patch`
(branch `hanoip-audio-wcd937x-fix` no volume `hanoip-kernel73-v3-src`,
sobre o a77b73f17 do PRE-GOLD). Módulo instalado no aparelho
(`snd-soc-wcd937x-sdw.ko.zst` 5de8447b..., original em
`/root/wcd937x-sdw.ko.zst.orig` 318eb14e...). **Candidato a upstream.**

### 6.2 `qcom,rx_mclk_mode_muxsel`: investigado, DESCARTADO

O rx-macro do vendor sm6150 (mesma família) escreve 1 em 0x62c25020 quando o
MCLK liga (`rx_macro_mclk_ctrl`, confirmado no `audio_rx_macro.ko` do stock e
no fonte LineageOS sm6150; o kona só faz ioremap). Testado com patch +
parâmetro de módulo: com MCLK de 19,2 MHz (mainline), o RX passa a rodar a
~0,77× (5 s de áudio levam 7,18 s, voz grave). Sem o muxsel: 5,73 s, igual
ao alto-falante, voz normal. Conclusão: o muxsel combina com o
`rx_core_clk` de 22,5792 MHz do vendor e **não deve ser usado** com o clock
do mainline. Módulo original do rx-macro restaurado. O patch de teste ficou
só no branch `hanoip-audio-muxsel-test`.

### 6.3 Outros achados desta rodada

- **SoundWire RX instável com runtime PM**: depois de alguns ciclos de
  clock-stop, o escravo RX volta "UNATTACHED, status was 1", aparecem
  `read underflow`, `bus clsh` e `DPN_PortCtrl write failed` (play com
  -EIO). Contorno usado em todos os testes: `echo on > power/control` nos
  dois masters (62ed0000/62ef0000), nos sdw-master-2/3 e nos dois escravos.
  Falta fixar isso (regra udev ou desligar clock-stop no DT/driver).
- **MBHC não reporta o jack**: `Headphone Jack`/`Mic Jack` ficam off com o
  fone plugado; só `mbhc sw intr` dispara 1 vez. O mic do headset funciona
  mesmo assim, porque o routing liga `MIC BIAS2`. Investigar a configuração
  de MBHC (hphl/gnd-swh, limiares).
- **aplay de vários WAV concatenados toca só o primeiro** (o cabeçalho manda).
  Os "loops" de 6 s das medições anteriores tocaram 2 s.
- Fluxo de teste sem tocar partição: módulo instalado em `/lib/modules` do
  Kali com backup em `/root`; ciclo de boot = `hanoip-reboot --poweroff` +
  usuário em Power+Vol− + `fastboot boot` U-Boot etapa12 + kernel PRE-GOLD.

## 7. Pendências fechadas na rodada final (etapas 13 e 14)

### 7.1 SoundWire RX com runtime PM
Medido na etapa12, com PM em `auto`: 6 de 8 ciclos "espera 5 s → play 2 s"
falham. No resume pelo caminho de clock-stop sem reinit aparecem
`link status not disconnected`, `link failed to connect`, depois
`read underflow`, `DPN_PortCtrl -5` e escravo RX UNATTACHED. O rx-macro
desliga o MCLK no runtime suspend e o master RX perde o contexto.
Correção: patch `soundwire: qcom: allow DT to opt out of clock stop`
(propriedade `qcom,clock-stop-not-supported`, força o reset + init +
re-enumeração que o driver já usa para escravos clk_stop_mode1) e
`&swr_rx { qcom,clock-stop-not-supported; }` na etapa13.
Resultado: **12/12 OK** com o master suspenso entre cada play.

### 7.2 Detecção do fone (MBHC)
Duas causas independentes:
1. **Limiar de headset**: o mic do headset mede 2080 mV. Com o default do
   mainline (`hs_thr = 1700 mV`), o plug virava HIGH_HPH/LINEOUT, que não
   liga `Headphone Jack`/`Mic Jack`. Os limiares do stock
   (`qcom,mbhc-headset-vthreshold-microvolt = 2700000`,
   `...-headphone-... = 116000`) resolvem (etapa13). O "cross connection"
   do log só aparece no transiente de inserção (HPHL/HPHR de 900 a 3700 mV);
   depois de assentar, as duas linhas medem 0 mV.
2. **Wake IRQ do TX**: o MBHC avisa por interrupção do escravo TX. Com o
   master TX suspenso, plugar dava 0 interrupções. O stock tem
   `swr_wake_irq` = GIC SPI 500. Etapa14:
   `interrupts = <GIC_SPI 296 ...>, <GIC_SPI 500 ...>; interrupt-names = "core", "wakeup";`
   Resultado: `swr_wake_irq` dispara, jack on/off correto com o TX suspenso.

### 7.3 UCM + PipeWire
`work/audio-20261028/ucm2/` (instalado em `/usr/share/alsa/ucm2/`, backup
dos anteriores em `/root/ucm-backup/`). Verbo HiFi com Speaker, Earpiece,
Headphones (JackControl), Mic1 (amic3), Mic2 (amic1) e HeadsetMic
(JackControl). Os dispositivos de playback conflitam entre si (um port_id
por sessão no q6routing), e os mics também (todos usam DEC0). Validado: o
PipeWire troca sozinho ao plugar/tirar o fone, e um tom tocado pelo
PipeWire saiu nos dois lados do fone.

### 7.4 Build reproduzível e pacote candidato
- `work/kernel-7.3/v5/`: v7.3 + 189 patches (= v4/PRE-GOLD #24 + 0188 + 0189),
  árvore `2df2c4d6`, conferida com `git am` numa worktree limpa.
- `work/kernel-7.3/v4/` foi danificado por um `cp` meu (estava fora do git)
  e restaurado; ver a nota no fim de `v4/README.txt`.
- Pacote: `work/PRE-GOLD-20261028-audio/` (U-Boot etapa14 + o mesmo kernel #24
  + os 2 módulos + UCM + patches + DTs + SHA256SUMS). Não é GOLD: o usuário decide.
- Os patches da sessão anterior (voto dcodec, AIF no wcd937x, NPA/sweep no
  q6afe) NÃO estão no v5. Ficaram só nos branches `audio-pre-sweep` e
  `audio-mbhc-debug` do volume. Os patches `0001-0003` de
  `work/audio-20261028/patches/` (pinos 14..31, mux 2) são obsoletos.

## 8. O que ainda falta

- Botões do headset (o MBHC já detecta o plug).
- Suspend do sistema inteiro com áudio.
- Ruído no log: `SWR bus clsh detected` na re-inicialização do RX e
  `clk already disabled` no wcd937x.
- Mandar 0188 (e talvez 0189) para o upstream.
- UCM: volume por hardware (PlaybackMixerElem) e roteamento de voz para chamadas.
- (histórico) UCM do ALSA para o PipeWire (HiFi: Speaker/Earpiece/Headphones/Mic1/Mic2/HeadsetMic).
- MBHC (detecção do fone) com fone plugado.
- Bug menor no upstream: `q6afe_callback` não trata a resposta de erro de
  `AFE_CMD_REMOTE_LPASS_CORE_HW_VOTE_REQUEST` ("Unknown cmd 0x100f4") e
  transforma o erro em timeout. Não afeta este aparelho, que não precisa do voto DCODEC.
- Patches locais da sessão anterior (habilitar voto dcodec nos macros, AIF no
  wcd937x, `if (hw_block_id == 103)` no q6afe) são DESNECESSÁRIOS e não devem
  ir para o kernel definitivo.
