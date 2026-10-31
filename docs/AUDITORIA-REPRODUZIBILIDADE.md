# Auditoria de reprodutibilidade — 31/10/2026

Pergunta: "dá para reconstruir tudo do zero?" Este documento responde com o
que foi conferido, o que foi corrigido nesta auditoria e o que ainda **não**
sustenta a palavra "100%".

Método: leitura de todos os scripts de build/instalação versionados,
extração automática das referências a arquivos e conferência contra
`git ls-files`; checagem de sintaxe (`bash -n`, `py_compile`); conferência de
hashes já provados nos testes de 30/10. **Nenhum build foi executado nesta
auditoria** (pedido do usuário).

## Defeitos encontrados e corrigidos hoje

| # | Problema | Risco | Correção |
|---|---|---|---|
| 1 | `FROM ubuntu:24.04` sem digest nos Dockerfiles do kernel e do U-Boot | gcc/binutils diferentes → config diverge e a Image muda a cada release do Ubuntu | `FROM ubuntu:24.04@sha256:33ceb719…` (digest dos builds validados) |
| 2 | Driver `rtl8188eus` clonado de `master` | build muda sozinho a cada upstream | commit fixo `47b50271…` (e `rtl8812au` em `ee6490b6…`, além da tag `v5.13.6`) |
| 3 | `ann.py` e `scan_frames.py` com caminho absoluto do Xcode | só rodavam no Mac do autor | `LLVM_OBJDUMP`/`shutil.which('llvm-objdump')` |
| 4 | `cycle.sh` com caminho absoluto do repositório | quebra em qualquer clone | derivado de `$(dirname $0)` |
| 5 | Instaladores com `HostKeyAlias` e sem aceitar chave nova | SSH falha em máquina limpa | `StrictHostKeyChecking=accept-new` |
| 6 | `mkimg-kali.sh` e `mkimg-dsifix-120hz.py` falhavam com erro seco se a imagem-base não foi buscada | confusão para quem clona | mensagem aponta `scripts/fetch-artifacts.sh` |

## Cobertura de dependências

Scripts auditados: `fetch-artifacts.sh`, `reproduce-all.sh`,
`install-audio.sh`, `install-cameras.sh`, `v7/build.sh`,
`v7/build-inside.sh`, `v7/mkimg-kali.sh`, `v8-dsi/build.sh`,
`v8-dsi/build-inside.sh`, `uboot/build.sh`, `uboot/build-repro.sh`,
`mkimg-dsifix-120hz.py`, `setup-kali-fingerprint.sh`.

Referências que **não** são arquivos versionados (todas tratadas):

| Referência | Situação |
|---|---|
| `work/GOLD-20261026-1500/ramdisk-v4.cpio.gz` | opcional no `v7/build.sh`; sem ele o empacotamento do boot.img é pulado (o `mkimg-kali.sh` faz depois) |
| `work/PRE-GOLD-20261029-1534/kernel/kernel-hanoip-kali-phosh-v5.img` | vem do release via `fetch-artifacts.sh` (agora com erro claro se faltar) |
| `work/PRE-GOLD-20261030-1430/kernel/qcom_qseecom_fpc.ko` | `setup-kali-fingerprint.sh` cai para `v7/out/` quando ausente |
| `v7/out/*`, `v8-dsi/*.ko.zst`, `.cache/`, `.log` | gerados pelos builds |

Referências verificadas como **presentes no git**: módulos do experimento
(`msm-dsifix`, painel 120 Hz), tunings das câmeras, módulos de câmera do
snapshot, imagem-cabeçalho do U-Boot, Dockerfiles, UCM2, `hanoip_boot.py`.

## Provas de hash já obtidas (não repetidas hoje)

- **U-Boot**: build do zero reproduziu `u-boot.bin`, `uboot.dtb` e o `.img`
  com hashes idênticos (`5cb08127…`).
- **Módulo `msm` do experimento**: `e45516ee…`, idêntico ao carregado.
- **DTB do kernel**: `900e11eb…`, idêntico.
- **`Image.gz`**: mesma fonte, config, banner `#64` e tamanho; **10.382 bytes
  diferentes** — equivalente, não idêntica.
- **Módulo do painel 120 Hz**: mesmo vermagic e marcador; bytes diferentes do
  artefato testado (build manual anterior).
- **Artefatos-base**: release `artefatos-base-20261031`, download verificado
  por SHA256 (7 arquivos).

## O que ainda impede dizer "100%"

1. **`Image.gz` não é byte-idêntica.** Causa desconhecida; `RANDSTRUCT` está
   desligado. Próximo teste: compilar duas vezes com entradas idênticas para
   separar não-determinismo de diferença de entrada.
2. **Módulo do painel** não é byte-idêntico ao testado (equivalente).
3. **Instaladores de áudio e câmeras nunca rodaram com `--apply`.** Foram
   validados só em dry-run; a primeira aplicação real precisa ser observada.
4. **Dependências de rede** (torvalds/linux v7.3, fork do U-Boot, aircrack-ng)
   são estáveis agora — tags e commits fixos — mas o espelho é externo.
5. **Nada do rootfs é versionado** além de scripts e configs: pacotes apt são
   resolvidos na hora (`setup-kali-fingerprint.sh` fixa libfprint v1.94.10,
   mas não fixa o snapshot do repositório Debian).
6. **Segredos do aparelho** ficam fora por decisão (`/var/lib/fpc-gk`,
   cadastro da digital, credencial do HAT) — isso é intencional, não lacuna.
7. **Rootfs**: a customização é 100% scriptada, mas a **imagem base do Kali**
   (10 GB) não é reconstruída do repositório; o toolchain upstream do Kali
   NetHunter está só parcialmente vendorizado e a deriva do `apt` não está
   fixada. Detalhes e opções em [REPRODUZIR-ROOTFS.md](REPRODUZIR-ROOTFS.md).

## Veredito

Reprodutível com confiança: **U-Boot, DTBs, módulo `msm`, fontes dos 195
patches, árvore do kernel, scripts de rootfs, apps e imagens-base**.

Não reprodutível byte a byte hoje: **`Image.gz` do kernel** e o **módulo do
painel**. Os dois são *equivalentes funcionais* e precisam de revalidação no
aparelho antes de serem tratados como o artefato validado.
