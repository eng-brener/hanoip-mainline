U-Boot do hanoip — build reproduzível (26/10/2026)
==================================================

O DT que vale no aparelho é o EMBUTIDO no U-Boot (CONFIG_OF_EMBED), então
cada par de teste tem o seu U-Boot. A fonte é `uboot-sm7150/` do repositório
(conferido em 26/10: idêntica, arquivo a arquivo, à cópia do container
hanoip-uboot-build-20261024 usada para todas as imagens de hoje).

  ./build.sh DT_NAME
  -> out/DT_NAME/{u-boot.bin, uboot.dtb, u-boot-DT_NAME.img, SHA256SUMS}

base.config = .config do .output-pmos do container. As 9 configs usadas
(pmos, pmos-audio, -audio2, -audio3, -camid, -perif-nonfc, -perif,
-sensors, -venus) só diferem dela em CONFIG_DEFAULT_DEVICE_TREE/OF_LIST, que
o build.sh troca. A imagem final reaproveita o cabeçalho v3 do U-Boot da
GOLD-20261026-1500 (pack_uboot_v3 em scripts/hanoip_boot.py troca só o
payload).

DTs do U-Boot (uboot-sm7150/dts/upstream/src/arm64/qcom/):
  sm7150-motorola-hanoip-pmos-perif   GOLD-20261026-1500: áudio + vibrador
                                      + flashes + LED + NFC (= "perif-v5")
  sm7150-motorola-hanoip-pmos-venus   perif + Venus (vídeo por hardware)
  sm7150-motorola-hanoip-pmos-camid   perif + CCI + rails/MCLK das câmeras
                                      (teste de chip ID)
  sm7150-motorola-hanoip-pmos-sensors sensores SSC (outra sessão)
  ...-pmos-audio/-audio2/-audio3      fases do bring-up do áudio
  ...-pmos-perif-nonfc                bisseção (perif sem NFC)

Uso: SÓ volátil (`fastboot boot u-boot-....img`, esperar o fastboot do
U-Boot, `fastboot boot kernel-....img`). Nunca flash.
Estado: scripts escritos em 26/10, ainda não rodados do zero.

BUILD REPRODUZÍVEL A PARTIR DO GIT (30/10/2026)
===============================================
`build-repro.sh` não depende da árvore local uboot-sm7150/ (332 MB, fora do
git). Ele reconstrói tudo do zero a partir de:

  1. fork sm7150-mainline/u-boot, branch `tauchgang`, commit de BASE.txt
     (f8c04469e8284aa2f1691a30aa3b7dc59fa0b8cd);
  2. patches/hanoip-vs-sm7150-mainline-tauchgang.diff (diff original 26/10);
  3. patches/hanoip-dts-cam-tres-delta.diff (delta de 28-29/10: DTS de
     câmeras — cam-etapa1..3, cam-tres —, dtsi e ajustes);
  4. base.config com CONFIG_DEFAULT_DEVICE_TREE/OF_LIST trocados para o DT;
  5. SOURCE_DATE_EPOCH=1793296828 (29/10 18:00:28 UTC), que iguala o
     timestamp embutido no u-boot.bin;
  6. o cabeçalho v3 da imagem validada da GOLD-20261026-1500 (versionada).

A árvore resultante é conferida: git write-tree deve dar
a38f1757adeb8ce1d8d0147de1a851a3b28d3f02.

PROVA (30/10): rodando `./build-repro.sh` (DT padrão cam-tres) saiu

  1b904885627234bb09f4d60f9573bf5580261a69ebfb7cf0e7a04aa2f5d0fa27  u-boot.bin
  b7c8b730e4cd38f283aed6636fb9d213eca507318e655420c01bdbc7c4e655ac  uboot.dtb
  5cb081270f62344c6308c980caa9ad67fcad5ea98ea284962c65f0e8907dc59a  u-boot-sm7150-motorola-hanoip-cam-tres.img

idênticos byte a byte aos da PRE-GOLD-20261030-1430 (o par de retorno).
Sem SOURCE_DATE_EPOCH o binário difere apenas na string de data do build.

O cache do clone e os objetos ficam em .cache/ (ignorado no git); o volume
docker hanoip-uboot-obj guarda a compilação incremental. Outros DTs do
hanoip usam o mesmo comando: `./build-repro.sh <DT_NAME>`.
