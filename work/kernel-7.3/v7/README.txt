Kernel 7.3 hanoip — v7: v6 + digital FPC (QSEECOM legado) (30/10/2026)
=====================================================================

Base: upstream v7.3 (árvore 30fd2ef8). patches/ = 195 commits, `git am`
direto sobre v7.3. Árvore resultante 276fbce0 (conferida pelo
build-inside.sh e gravada em /src/obj/.tree-v7). É exatamente a árvore do
kernel listener7 (#64) bootado e validado em 30/10.

  0001-0194  idênticos ao v6 (árvore f4dccdc7, PRE-GOLD-20261029-1534).
  0195  firmware: qcom: add a legacy QSEECOM transport for HLOS-loaded TAs
        (hanoip FPC). qcom_scm: app_start/shutdown, send por endereço
        físico com e sem whitelist, notificação de região, listener
        (register smcinvoke, resposta com whitelist, deregister) e uma
        variante da chamada sem o WARN_ON de INCOMPLETE. Novo
        qcom_qseecom_fpc (=m): /dev/qseecom-fpc, listener só durante cada
        envio, serviço RPMB no kernel pelo W-LUN do UFS (layout do librpmb),
        escrita só com rpmb_writes=1, PROGRAM_KEY sempre recusado,
        region_phys=0 por padrão. Antes, foram 6 commits "wip" na árvore
        de build; o 0195 é o mesmo diff condensado (mesma árvore).

config-7.3-hanoip = v6 + CONFIG_QCOM_QSEECOM_FPC=m (posição do
olddefconfig). O resto do Image é o código do v6.

Construir:
  ./build.sh            Image.gz, kernel.dtb, módulos (docker, volume do v3..v6)
  ./mkimg-kali.sh       out/kernel-hanoip-kali-phosh-v7.img com o ramdisk real
                        do boot.img da PRE-GOLD-20261029-1534
Bootar (volátil, nunca flash): U-Boot cam-tres da PRE-GOLD e depois o .img.

Rootfs (módulo, fprintd, libfprint com o driver, app Digital, guardião):
  work/fingerprint-20261029/integration/setup-kali-fingerprint.sh

Validado no aparelho (30/10, listener7 = mesma árvore): TA da digital,
Gatekeeper/HAT, listener RPMB com escrita autorizada, cadastro e
identificação pelo fprintd, desbloqueio do Phosh. Detalhes:
work/fingerprint-20261029/HANDOFF-20261030.md e
work/PRE-GOLD-20261030-1430/PRE-GOLD.txt.

REPRODUZIBILIDADE (30/10/2026)
==============================
`build.sh` agora fixa KBUILD_BUILD_VERSION=64 e
KBUILD_BUILD_TIMESTAMP="Fri Oct 30 16:26:38 UTC 2026", que são o contador e
a data embutidos na Image do listener7 realmente bootada (a que está dentro
de PRE-GOLD-20261030-1430/kernel/kernel-hanoip-listener7.img). Ambos podem
ser sobrescritos por variável de ambiente.

O que já se reproduz:
  - árvore-fonte: `git am` dos 195 patches resulta em 276fbce0 (o script
    aborta se divergir), com a tag base v7.3 em 30fd2ef8;
  - configuração: config-7.3-hanoip + olddefconfig sem diferenças (o script
    compara ignorando apenas as linhas de versão do toolchain);
  - DTB: byte-idêntico ao da PRE-GOLD (900e11eb...), conferido em 30/10.

O que NÃO se reproduz ainda:
  - a Image.gz. Com os mesmos fontes e config e com banner já idêntico
    ("#64 ... Sat/Fri Oct 30 16:26:38 UTC 2026"), o build de 30/10 gerou
    2d5439e2... enquanto a referência é 9769296c..., com o MESMO tamanho
    (34.632.192 bytes) e 10.382 bytes diferentes. RANDSTRUCT está desligado
    (CONFIG_RANDSTRUCT_NONE=y), então não é randomização de layout.
    Causa ainda não identificada; o próximo passo é compilar duas vezes com
    entradas idênticas para saber se o build em si é determinístico.

Portanto: reproduzível em fonte, configuração e DT; a imagem binária do
kernel ainda não é byte-idêntica. U-Boot, por outro lado, é byte-idêntico
(ver work/uboot-builds-20261026/README.txt).
