Kernel 7.3 (mainline) para o Moto G60 hanoip — variante v1, 25/10/2026
=====================================================================

Base: upstream Linux v7.3 (tag v7.3, commit c03c1a14507dfaf8b856c2608f9ac216021fc222).
Topo:  patches/ = 128 commits, `git am` direto sobre v7.3 (HEAD ccb1a177a232
no container hanoip-kernel73, branch hanoip-7.3):
  0001-0116  sm7150-mainline/linux branch v7.2 (fd78d17954a8), os 117 commits
             do fork menos 1 que ficou vazio (já está no v7.3).
  0117-0127  nosso delta do hanoip (11 áreas: dt-bindings, pinctrl/clk/soc,
             LCDB, painel ILI7807S, simplefb, UFS, arm-smmu, MSM display,
             touch, power-supply, DTs).
  0128       qcom_qg: MODULE_IMPORT_NS("IIO_CONSUMER") (exigido no 7.3).
Antes do rebase, a árvore fork v7.2 + 11 patches hanoip foi conferida arquivo
por arquivo contra o kernel #10 commitado (kernel-mainline @ 8f1e319eb):
idêntica (só Documentation/.renames.txt difere, artefato da importação).
O fork "v7.2" parte de 5a66900afbd6, no meio da janela de merge do 7.2
(Makefile ainda 7.1.0); por isso o salto foi de duas versões.

Conflitos resolvidos no rebase (detalhes nos próprios patches):
  - bindings ICE e TRNG: listas, mantidos sm7150 + shikra do 7.3.
  - binding rpmhcc: o fork commitou marcadores de conflito; refeito sobre o 7.3.
  - ath10k htt_rx: lista persistente do fork + ath10k_core_start_recovery do 7.3.
  - painel ILI7807S agora existe no upstream (só DLC0697): mantido o nosso
    driver validado (DLC0697 + Tianma DSC); Kconfig/Makefile deduplicados;
    binding do upstream + compatível tianma,ili7807s-hanoip.
  - MSM DSI: bridge virou atômica no 7.3; o "VIDEO adiado" foi portado para
    .atomic_enable (struct drm_atomic_commit *).
  - msm_iommu: bloco ARM32 do 7.3 + nossa reserva da região do framebuffer.

Config: config-7.3-hanoip = .config do kernel #10 + olddefconfig + UFS
(SCSI_UFSHCD/_PLATFORM/UFS_QCOM), QCOM_IPA e HW_RANDOM_QCOM como módulo
(no #10 esses eram compilados fora da árvore). Build: aarch64-linux-gnu-gcc
13.3, `make LOCALVERSION= Image modules` (sem LOCALVERSION= o release vira
"7.3.0-sm7150+"). Módulos instalados sem zstd (CONFIG_MODULE_COMPRESS_ZSTD=
na instalação). hanoip_mmi_unit_info (work/wifi-20261025/mmi-unit-info) é
compilado com M= e vai em extra/.

Artefatos:
  kernel-hanoip-pmos-7.3-v1.img  Image 7.3 + ramdisk pmOS com os 43 módulos
                                 do estágio 1 em 7.3 (layout da GOLD v4).
  u-boot-hanoip-pmos-v1.img      o mesmo U-Boot/DT da GOLD v4 (DT do SM7150
                                 não mudou entre 7.1 e 7.3).
  modules-7.3.0-sm7150.tar.gz    /lib/modules/7.3.0-sm7150 (850 módulos).
  install-rootfs-7.3.sh          instala esse tree no rootfs pmOS (só no
                                 rootfs do fim do super) e o hanoip-touch
                                 com modprobe.

Boot (SÓ volátil):
  fastboot boot u-boot-hanoip-pmos-v1.img ; fastboot boot kernel-hanoip-pmos-7.3-v1.img
O rootfs do telefone tem /lib/modules 7.1.0 e 7.3.0 lado a lado: o mesmo
rootfs boota a GOLD v4 (7.1) e esta variante.

Validado em dois boots (25/10/2026): pmOS + Plasma em ~30-37 s, display
msmdrmfb DSI-1 connected, DSI irqs=0, KWin com OpenGL, touch (follower,
autoload por modprobe), Wi-Fi (NetworkManager), Bluetooth, UFS 84 blocos
com só sdb/sdb23 graváveis, CPUs 0-7 com qcom-cpufreq-hw, autoload udev
igual ao 7.1, blacklist respeitada, sem Oops/WARNING, tainted 4096,
42-43 °C. Reboot pelo pmOS volta ao fastboot. Metadados LP e os 5154 MiB do
lado A do super conferidos idênticos após o primeiro boot.
Pendente: confirmação visual do usuário nesta variante; bateria ainda não
carrega (igual ao 7.1); probe adiado do LPASS pinctrl (igual ao 7.1).
