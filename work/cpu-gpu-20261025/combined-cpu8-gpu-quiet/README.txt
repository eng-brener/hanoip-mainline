Combined CPU8 + GPU/Freedreno variant, with a quiet kernel display
==================================================================

This directory contains the combined volatile test pair based on the
GPU-Zap-early variant. It includes the all-eight-CPU DT and the initramfs
that exposes the device Zap firmware before display initialization, then
starts display, touch, USB ACM/NCM networking with SSH/SFTP, UFS in guarded
read-only mode, Wi-Fi, and Bluetooth. The rootfs archive and prior Mesa/KMSCube
run evidence are included for the Freedreno validation context.

The only bootargs change is removal of the kernel's tty1 console selection.
Kernel messages remain available through serial (ttyMSM0), USB (ttyGS0), and
ramoops. The initramfs can still print its user-space status to /dev/tty1.
The loglevel remains unchanged, so this suppresses kernel messages on the
phone display without discarding diagnostic logs from the other consoles.

Images:
  u-boot-hanoip-combined-cpu8-gpu-quiet.img
  kernel-hanoip-combined-cpu8-gpu-quiet.img

This combined quiet-console package has not yet been boot-tested. The GPU,
Freedreno/KMSCube, CPU8, display, touch, network, wireless, and read-only UFS
features have evidence in their source test variants; integration regression
and screen-output behavior remain to be confirmed by a volatile boot.

When explicitly ready to test, use only:
  fastboot boot u-boot-hanoip-combined-cpu8-gpu-quiet.img
  fastboot boot kernel-hanoip-combined-cpu8-gpu-quiet.img

Never flash or write any phone partition. Preserve all GOLD directories.
