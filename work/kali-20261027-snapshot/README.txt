KALI NETHUNTER PRO (Phosh) no Moto G60/hanoip — snapshot do estado funcional
Criado em 27/10/2026, depois de validar o sistema no aparelho.

O QUE É
  rootfs.tar.zst  — rootfs completo do Kali (ext4 do userdata, /dev/sdb24),
                    lido SOMENTE LEITURA a partir do pmOS e comprimido com
                    zstd. Inclui tudo o que foi instalado e configurado:
                    kernel 7.3.0-sm7150 (nosso), drivers/módulos, drivers do
                    projeto (msm/DPU/DSI, panel ilitek, touch, aw882xx, wcn3990,
                    nxp-nci, pm8xxx_vibrator, qcom_wled, leds_lpg, qcom_qg,
                    qcom_smbx, fastrpc, qrtr…), /opt/ssc (bundle de sensores),
                    pacotes, serviços e configs.
  configs/        — cópia dos arquivos que criamos/portamos (serviços systemd,
                    scripts em /usr/local/sbin, regras udev, UCM do alto-falante,
                    regra do WirePlumber, modprobe, sshd, helper da rota).
  packages.txt    — 1566 pacotes instalados com versão.
  inventory.txt   — lista dos serviços/configs do projeto no rootfs.
  SHA256SUMS      — hashes deste pacote.

COMO FOI FEITO (nada foi escrito no aparelho)
  Boot no pmOS (GOLD-20261026-1712), montagem RO do /dev/sdb24
  (ro,noload,nodev,nosuid,noexec) e `tar | zstd -1 -T2` com nice. A primeira
  tentativa foi feita DENTRO do Kali rodando e travou a interface (zstd -T0
  saturou CPU/UFS) — por isso o snapshot agora sai do pmOS.

COMO VOLTAR (três caminhos)
  1) Restaurar por cima de um Kali já instalado, a partir do pmOS:
       - montar /dev/sdb24 rw (só ele; super fica RO)
       - tar -xf rootfs.tar.zst -C /mnt/kali --numeric-owner
       - sync && umount
  2) Recriar a imagem ext4 e gravar no userdata pelo Linux:
       dd if=/dev/zero of=kali.img bs=1M count=10240
       mkfs.ext4 -q -L kali -d <rootfs-extraído> -F kali.img
       (depois gravar com dd em /dev/sdb24 a partir do pmOS)
     ATENÇÃO: a ABL da Motorola RECUSA `fastboot flash userdata`
     ("flash permission denied"); `fastboot erase userdata` funciona.
  3) Boot (sempre volátil):
       fastboot boot u-boot-hanoip-pmos-perif-v2026.10.img
       fastboot boot kernel-hanoip-kali-phosh-v1.img
     A cmdline NÃO pode ter `console=ttyGS0` (trava o PID 1 do systemd).

ESTADO VALIDADO NESTE SNAPSHOT
  Phosh + teclado virtual, login kali/1234; SSH root por chave (UsePAM no);
  rede USB NCM+DHCP (Mac 172.16.42.2); Wi-Fi 5 GHz com internet; relógio com
  fake-hwclock + NTP e fuso America/Sao_Paulo; desempenho (GPU 355 MHz/poll
  16 ms, UFS 200 MHz, CPU schedutil); sensores SSC (accel/luz/prox);
  vibração (driver + feedbackd); LED de notificação e flash; áudio no
  alto-falante (UCM + rota automática + S16LE + mono, 6 dB).

PENDENTE: app gráfico de NFC (hanoip-nfc.py pronto, não instalado), câmera,
digital, microfone/fone (WCD937x), suspend.
