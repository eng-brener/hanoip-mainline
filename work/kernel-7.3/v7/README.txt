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
