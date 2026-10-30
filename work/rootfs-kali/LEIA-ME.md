# Rootfs Kali do hanoip — tornar reproduzível (30/10/2026, EM ANDAMENTO)

Objetivo (pedido do usuário): rootfs reproduzível como já são o U-Boot e o
kernel (work/kernel-7.3/v7), antes de começar o Waydroid.

## O que se descobriu

1. **O script que construiu a imagem base NÃO foi salvo.** Em 26/10 a base foi
   feita no Mac (OrbStack, container arm64, replicando o rootfs.yaml oficial do
   kali-nethunter-pro). Restaram só o resultado
   (work/nethunter-pro-20261026/artifacts/kali-hanoip-userdata.img, 10 GiB, só
   neste SSD) e a cópia da receita oficial (…/docs/build-scripts/). Os passos
   seguintes (pacotes, serviços, áudio, câmeras, digital) foram feitos à mão,
   em scripts espalhados (nethunter-pro-20261026/hanoip-support, install-kali-
   pkgs.sh, instalar-fase0.sh, câmeras, setup-kali-fingerprint.sh).
2. **Inventário exato do rootfs de hoje** (lido do aparelho, só leitura) em
   inventario-20261030/: 1651 pacotes com versão (packages.tsv), 122 manuais,
   67 unidades habilitadas, 23 arquivos de pacote alterados (dpkg-verify.txt),
   12160 arquivos sem dono -> 3612 depois de tirar o que é gerado (cache de
   python/mime/ícones/ssl, .cache, links de alternatives, rc*.d, catálogos XML).
3. Classificação dos 3612:
   - /usr/lib/modules (878): vêm do kernel; o kernel está instalado como
     pacote linux-image-7.3.0-sm7150 (mkdeb.sh), dono de /lib/modules (o dpkg
     não enxerga o caminho /usr/lib por causa do usrmerge). Os 6 módulos e os
     modules.* alterados (dpkg-verify) são as correções instaladas depois
     (áudio, câmeras, carga): a receita usa o .deb do v7, que já os contém.
   - firmware: quase tudo são LINKS que o hanoip-firmware recria a cada boot
     para /mnt/ro/modem_a e /mnt/ro/bluetooth_a (partições do Android, RO).
     Arquivos REAIS: a630_gmu.bin, a630_sqe.fw, ath10k WCN3990 firmware-5.bin
     (60 B) — públicos (linux-firmware); aw882xx_spk_reg.bin e
     ilitek/hanoip-7807-iram.bin — do fabricante.
   - /opt/ssc (83 MB): mini-rootfs do pmOS (musl/busybox/apk) com hexagonrpcd,
     libssc e o registry dos sensores; + /usr/lib/hanoip-sensors/fastrpc.ko.
   - projeto: 84 arquivos em overlay/ (lista em overlay-include.txt).
   - usuário: configurações do kali exportadas em texto (dconf-kali.ini,
     sem senha/token/localização).
4. **Segredos que ficam FORA da receita e do git**: conexão Wi-Fi com senha
   (/etc/NetworkManager/system-connections/*), chaves de host SSH, shadow/
   gshadow, /root/.ssh/authorized_keys (a receita usa a chave pública do Mac na
   hora do build), /var/lib/fpc-gk (credencial da digital). Lixo de teste em
   /root (.wav, .ko, logs) também fica de fora.
5. Arquivo perdido no aparelho: /usr/share/alsa/ucm2/conf.d/sm8250/
   "Motorola\ Moto\ G60.conf" (com barras invertidas no NOME, 460 B, 28/10) é a
   "proposta não testada" de ganhos, criada por um scp antigo; NÃO é usada. A
   real é "Motorola Moto G60.conf" (102 B) e é a que está no overlay.
6. Kali é rolling e não mantém versões antigas: a receita reconstrói o MESMO
   CONJUNTO de pacotes (lock = packages.tsv) com as versões disponíveis no dia;
   a volta EXATA depende de um snapshot do rootfs (ver "Falta").
7. Ambiente de build: Mac arm64 + OrbStack (aarch64 nativo, 10 CPUs, 8 GB),
   imagem kalilinux/kali-rolling arm64 funciona e já traz a chave do Kali;
   chave pública do Mobian copiada em keys/ (mobian-archive-keyring).

## Arquivos desta pasta
- inventario-20261030/  inventário do aparelho (pacotes, unidades, verify,
                        sem dono filtrado, fontes do apt)
- overlay-include.txt   lista de inclusão do overlay; overlay/ o resultado
- dconf-kali.ini        configurações do usuário kali
- keys/                 chaves públicas dos repositórios
- blobs/                firmware do fabricante + /opt/ssc (FORA do git,
                        hanoip-blobs.tar.zst, 30 MB)
- build.sh              (rascunho) build no Mac; build-inside.sh, verify.sh e
                        collect-from-device.sh ainda NÃO escritos

## Mudança no aparelho (30/10)
O ext4 do Kali foi aumentado online de 10 GiB para 107 GiB (autorizado pelo
usuário). A receita continua gerando imagem de 10 GiB por padrão (IMG_SIZE);
num rootfs novo, crescer com resize2fs depois de gravar.

## Falta
1. Escrever build-inside.sh (mmdebstrap arm64 com Kali + Mobian e o lock de
   pacotes; overlay; blobs; .deb do kernel v7; usuários kali/_greetd e grupos;
   unidades; dconf; libfprint do patch; initramfs; mke2fs -d), verify.sh e
   collect-from-device.sh; gerar blobs.SHA256SUMS.
2. Rodar o build e comparar com o inventário.
3. Snapshot exato do rootfs de hoje (tar.zst do sdb24 montado RO a partir do
   pmOS, como em work/kali-20261027-snapshot) — precisa do link USB/fastboot.
