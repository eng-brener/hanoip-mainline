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
