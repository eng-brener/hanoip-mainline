Kernel 7.3 hanoip — v3: v2 + áudio, periféricos, QRTR e Venus (26/10/2026)
=========================================================================

Base: upstream v7.3 (c03c1a14, árvore 30fd2ef8). patches/ = 166 commits,
`git am` direto sobre v7.3. Árvore resultante 19b139f7 = branch
hanoip-7.3-audio @ bd7ea6f00d54 do container hanoip-kernel73 (é o kernel #6
da GOLD-20261026-1500 mais o patch do Venus, que só muda o módulo
venus-core).
  0001-0160  idênticos ao v2 (mesmo `git patch-id`), ver ../v2/README.txt.
  0161  ASoC: codecs: AW882xx (0x1852) mínimo (alto-falante).
  0162  pinctrl: sm7150-lpass-lpi: pinos SSC da SEC_MI2S (vendor gpio8-11,
        0x62b48000; o lpass_tlmm começa no vendor gpio18).
  0163  Input: pm8xxx-vibrator: tensão máxima opcional (qcom,vib-max-microvolt).
  0164  Input: pm8xxx-vibrator: corrige o byte alto da tensão (era << 8).
  0165  net: qrtr: ns: espera o HELLO antes de anunciar os serviços (corrige o
        modem travando com "DOG detects stalled initialization" e o Wi-Fi
        sumindo em metade dos boots, regressão do 544d85de4dc2).
  0166  media: venus: recursos do SM7150 (experimental; decodificação H.264
        1080p validada bit a bit).
config-7.3-hanoip = config do v2 + CONFIG_SND_SOC_AW882XX=m.
extra/ = fonte do módulo fora da árvore hanoip_mmi_unit_info (identidade do
aparelho vinda do ABL); vai para /lib/modules/7.3.0-sm7150/extra/.

Reconstruir (só precisa de docker; nada é gravado no telefone):
  ./build.sh [RAMDISK.cpio.gz]
  1. monta a imagem Docker (Dockerfile: Ubuntu 24.04, aarch64-linux-gnu-gcc
     13.3, KBUILD_BUILD_USER/HOST iguais aos do build testado);
  2. build-inside.sh baixa linux-7.3.tar.xz do kernel.org, confere a árvore
     base (30fd2ef8), aplica patches/, confere a árvore final (19b139f7),
     confere a config (ignorando só as linhas de versão do toolchain) e
     compila Image, módulos, o DT sm7150-motorola-hanoip e o extra/;
  3. out/: Image.gz, kernel.dtb, modules-7.3.0-sm7150.tar.gz, version.txt e,
     com um ramdisk, kernel-hanoip-pmos-7.3-v3.img (cabeçalho da GOLD v4,
     via scripts/hanoip_boot.py) + SHA256SUMS.
  O cache (tarball, fonte, objetos) fica no volume docker
  hanoip-kernel73-v3-src; rodar de novo é incremental.
  O ramdisk NÃO está no repositório (o do pmOS leva firmware do vendor):
  sem argumento, o build.sh usa o da GOLD-20261026-1500 ou o do v2 se
  existirem localmente; sem nenhum, gera só Image/módulos.

O DT que vale no aparelho é o embutido no U-Boot (uboot-sm7150/), não o
kernel.dtb do boot.img. Para áudio + periféricos use o U-Boot perif-v5; para
o Venus, o DT sm7150-motorola-hanoip-pmos-venus.dts (work/video-20261026/).

Boot: SÓ volátil (`fastboot boot` do U-Boot e depois do kernel). Instalar os
módulos no rootfs com ../v2/install-rootfs-7.3.sh (em primeiro plano). Num
boot da GOLD-20261026-1500 o rootfs é RO com overlay em RAM: o que for
instalado lá some no reboot.

Estado: arquivos e conferências de árvore/config preparados em 26/10/2026;
o build do zero pelo build.sh AINDA NÃO FOI RODADO até o fim (o usuário
dispensou o teste). As árvores e a config foram conferidas contra o
container; a primeira execução dirá se o tarball do kernel.org bate com a
árvore 30fd2ef8.
