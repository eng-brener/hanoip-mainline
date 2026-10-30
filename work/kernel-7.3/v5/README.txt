Kernel 7.3 hanoip — v5: v4 (PRE-GOLD 28/10, kernel #24) + áudio (28/10/2026)
============================================================================

Base: upstream v7.3 (árvore 30fd2ef8). patches/ = 189 commits, `git am`
direto sobre v7.3. Árvore resultante 2df2c4d6 (conferida pelo
build-inside.sh e gravada em /src/obj/.tree-v5).

  0001-0187  idênticos ao v4 (= kernel #24 do PRE-GOLD-20261028-1133,
             árvore 96194064).
  0188  ASoC: codecs: wcd937x-sdw: bound the static channel map to the
        channel table. O laço do qcom,tx-channel-mapping (12 entradas)
        estourava wcd937x_sdw_tx_ch_info[11] e gravava BIT(3) em
        rx_ch_info[0].ch_mask (HPH_L): fone esquerdo e earpiece mudos,
        HPHL PDM WDOG. Bug do upstream; candidato a envio.
  0189  soundwire: qcom: allow DT to opt out of clock stop
        (qcom,clock-stop-not-supported). No sm7150 o master RX perde o
        contexto quando o rx-macro desliga o MCLK; sem isso 6/8 resumes
        falhavam. Usado em &swr_rx no U-Boot etapa13/14.

As duas mudanças são MÓDULOS (=m): o Image é o mesmo código do #24, só
muda o timestamp de build. Validado: os .ko deste build têm código e
dados (objdump -d, .rodata/.data) idênticos aos instalados e testados
no aparelho (work/PRE-GOLD-20261028-audio/modules/).

config-7.3-hanoip = /proc/config.gz do kernel #24 (inclui TEO=y).

Construir:  ./build.sh   (mesma imagem docker e volume do v3/v4)
  out/: Image.gz, kernel.dtb, modules-7.3.0-sm7150.tar.gz, version.txt e
  um kernel-hanoip-pmos-7.3-v3.img empacotado com o ramdisk do pmOS (nome
  herdado do v3). Para o Kali vale o boot.img do PRE-GOLD
  (kernel-hanoip-kali-phosh-v3-teo.img), já que o código do Image não muda.
  Os drivers rtl8812au/rtl8188eus (best-effort) não compilam contra 7.3,
  igual ao v4.

NÃO estão aqui, de propósito: os patches de teste da sessão de áudio
anterior (voto dcodec nos macros, widgets AIF no wcd937x, NPA/sweep no
q6afe), o muxsel do rx-macro (descartado: RX a 0,77x) e o debug do MBHC.
Eles ficaram só nos branches audio-pre-sweep, hanoip-audio-muxsel-test e
audio-mbhc-debug do volume hanoip-kernel73-v3-src.
Detalhes: docs/kernel/REAVALIACAO-AUDIO-20261028.md.

BOOT VALIDADO (28/10/2026 ~17:05 -03)
-------------------------------------
out/kernel-hanoip-kali-phosh-v5.img (c0a0c822225c34c99cf70c55ffb380b146a9b2e8da6d32145412fd8f74aa1fb7)
  = boot.img Kali do PRE-GOLD-20261028-1133 com SÓ a seção kernel trocada
    pelo out/Image.gz deste build (ramdisk, DTB e cabeçalho idênticos).
  Image descomprimido x #24: mesmo tamanho, 32 bytes diferentes, todos de
  carimbo de build (#24->#29, data/hora, build-id GNU).
Boot volátil: U-Boot work/PRE-GOLD-20261028-audio/uboot/...etapa14.img + esta
imagem. /proc/version = #29; 121 módulos, display, 8 CPUs, Venus, Wi-Fi,
SoundWire Attached/Attached; dmesg sem mensagens novas em relação ao #24.
Usuário confirmou tela normal e o tom tocado pelo PipeWire no alto-falante.
Fone/earpiece não retestados neste kernel (o código dos módulos é idêntico).
