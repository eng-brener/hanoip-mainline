# Reproduzir do zero — o que fecha e o que não fecha

Atualizado em 31/10/2026. Este arquivo diz, sem otimismo, o que dá para
reconstruir numa máquina limpa a partir **apenas do git**, e o que ainda
depende de arquivos que só existem localmente.

## Pré-requisitos

- Docker, `git`, `python3`, `shasum`/`sha256sum`.
- Rede: o build do kernel clona `torvalds/linux` (tag v7.3) e o U-Boot clona
  o fork `sm7150-mainline/u-boot`; alguns drivers NetHunter vêm de
  `aircrack-ng/*`.
- Espaço: ~10 GB para fontes/objetos do kernel e ~2 GB do U-Boot.
- As imagens Docker são construídas dos Dockerfiles versionados
  (`work/kernel-7.3/v7/Dockerfile`, `work/uboot-builds-20261026/Dockerfile`).
  A versão do toolchain dentro delas é parte da receita.

## U-Boot: reproduzível BYTE A BYTE

```sh
sh work/uboot-builds-20261026/build-repro.sh
```

Sai `u-boot.bin`, `uboot.dtb` e `u-boot-sm7150-motorola-hanoip-cam-tres.img`
com os hashes da PRE-GOLD-20261030-1430 (`5cb08127...`). Verificado em
30/10. Depende apenas de: fork no commit de `patches/BASE.txt`, os dois
patches de `patches/`, `base.config`, `SOURCE_DATE_EPOCH` fixo e a imagem
cabeçalho versionada da GOLD-20261026-1500.
Outros DTs: `./build-repro.sh <DT_NAME>`.

## Kernel (listener7 / v7)

```sh
sh work/kernel-7.3/v7/build.sh        # Image.gz, dtb, módulos
sh work/kernel-7.3/v7/mkimg-kali.sh   # empacota o boot.img
```

- **Árvore-fonte:** reproduz exatamente `276fbce0…` (o script aborta se
  divergir). 195 patches + tag v7.3 `30fd2ef8`.
- **Config:** `config-7.3-hanoip` + olddefconfig, sem diferenças.
- **DTB:** byte-idêntico (`900e11eb…`).
- **Image.gz:** NÃO é byte-idêntica. Com banner já igual (`#64 … 16:26:38
  UTC`, via `KBUILD_BUILD_VERSION`/`KBUILD_BUILD_TIMESTAMP`) e mesmo tamanho,
  restam 10.382 bytes diferentes. Causa desconhecida; `RANDSTRUCT` está
  desligado. Trate como "equivalente, precisa revalidar", não como idêntica.
- **`mkimg-kali.sh` depende de um boot.img local** (ver lacunas abaixo).

## Módulos do experimento de 120 Hz (v8)

```sh
sh work/kernel-7.3/v8-dsi/build.sh
```

- Árvore conferida em `e0bc45ad…` (v7 + guards DSI + marcador).
- `msm-dsi-guards.ko.zst`: **byte-idêntico** ao que rodou no aparelho
  (`e45516ee…`). Verificado em 30/10.
- `panel-ili7807s-120hz.ko.zst`: mesmo vermagic e mesmo marcador, mas **não**
  é byte-idêntico ao artefato testado (86.888 vs 86.720 bytes; aquele foi
  compilado à mão antes). Para repetir o boot validado use o artefato do
  snapshot; para build novo, revalide no aparelho.
- Empacotar a imagem volátil: `work/display-120hz-20261030/mkimg-dsifix-120hz.py`
  — também depende da imagem-base local.

## Lacunas: o que NÃO está no git

1. **Imagens-base de boot** (`kernel-hanoip-listener7.img`,
   `Image.gz.listener7`, `kernel-hanoip-kali-phosh-v5.img`). Sem elas não se
   empacota um boot.img novo do zero, porque o ramdisk/extrator parte delas.
   Motivo: `work/**/*.img` fica fora do git e o push da imagem construída foi
   bloqueado por um falso positivo do scanner de segredos (string tipo Twilio
   em dados comprimidos).
2. **A imagem validada de 120 Hz** (`kernel-listener7-dsifix-120hz.img`):
   só local, hash no `SHA256SUMS` do snapshot.
3. **Rootfs do Kali** e snapshots grandes (`*.img`, `*.tar.zst`): fora por
   tamanho.

Enquanto (1) não for resolvido, "do zero" vale para fontes, U-Boot, módulos e
DTB — não para o pacote final de boot.

## Opções para fechar a lacuna das imagens-base

- Publicar as imagens como *release assets* no GitHub (fora do histórico) e
  documentar URL + SHA256 aqui; é o caminho mais simples e não engorda o
  repositório.
- Ou versionar o ramdisk base com uma exceção explícita no `.gitignore` e
  testar o push (pode cair no mesmo falso positivo do scanner).
- Ou escrever um script que gere o ramdisk a partir do rootfs do Kali — mais
  trabalho, mas independente de binário do aparelho.

Nada disso foi feito ainda. Não tratar esta receita como "reproduz tudo de
qualquer máquina" antes de resolver (1).
