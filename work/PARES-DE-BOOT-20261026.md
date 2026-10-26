# Pares de boot de 26/10/2026 (todos voláteis: `fastboot boot` U-Boot, depois kernel)

O DT efetivo é o do U-Boot. Kernels: "f2/f3/f3b/qrtr" = builds #3..#6 do
branch hanoip-7.3-audio; a GOLD-20261026-1500 usa o #6 com ramdisk rápido
(rootfs RO + overlay em RAM). Fonte atual reproduzível:
- kernel: `work/kernel-7.3/v3/build.sh` (166 patches; #6 + patch do Venus,
  que só muda o módulo venus-core);
- U-Boot: `work/uboot-builds-20261026/build.sh <DT>`;
- rootfs: `work/pmos-super-20261025/build-rootfs.sh` (+ overlay/).
Cada pasta tem SHA256SUMS. Imagens/ramdisks NÃO vão para o git (vendor).

| Pasta | U-Boot DT | Kernel | Para quê | Resultado |
|---|---|---|---|---|
| audio-20261026/fase1 | pmos-audio | v2 | ADSP | OK |
| audio-20261026/fase2 | pmos-audio2 | #3 (f2) | placa de som + SEC_MI2S | OK (mudo) |
| audio-20261026/fase3 | pmos-audio3 | #4 | AW882xx | sem clock (pinos errados) |
| audio-20261026/fase3b | pmos-audio3 | #5 (f3b) | pinos SSC do LPI | **som OK** |
| perif-20261026/v1 | pmos-perif (v1) | #5 | vibrador, flash 2 canais, NFC | OK |
| perif-20261026/v2 | pmos-perif (v2) | #5 | teto 3,0 V do vibrador | OK |
| perif-20261026/v3 | pmos-perif (v3) | #5 | flash traseiro/frontal separados | OK |
| perif-20261026/v3-nonfc | pmos-perif-nonfc | #5 | bisseção do Wi-Fi | Wi-Fi falhou (não era o NFC) |
| perif-20261026/v4 | pmos-perif (v4) | #5 | LED RGB (teste) | só canal 1 acende |
| perif-20261026/v5 | pmos-perif (v5) | #5 | LED branco white:status | OK |
| perif-20261026/v6-qrtr | pmos-perif (v5) | #6 | correção QRTR (Wi-Fi) | **OK** |
| GOLD-20261026-1500 | pmos-perif (v5) | #6 + ramdisk rápido | retorno padrão | GOLD |
| cameras-20261026/step1-camid | pmos-camid | GOLD | chip ID das 4 câmeras | **4/4 OK** |
| video-20261026/venus-v1 | pmos-venus | GOLD | Venus (decode) | **H.264 bit-exato** |

Os DTs "perif (v1..v5)" são estados sucessivos do mesmo arquivo
`sm7150-motorola-hanoip-pmos-perif.dts`; a cópia de cada versão está na pasta
do par (`*.dts`) e o arquivo atual = v5. Módulos fora do Image usados à mão:
pm8xxx-vibrator.ko (perif v2/v3), hanoip-camid.ko (step1), venus-core.ko
(venus-v1) — todos saem do kernel v3 (camid: work/cameras-20261026/camid/).
