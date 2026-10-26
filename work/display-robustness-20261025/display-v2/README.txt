Display robustness v2 — RAM-only diagnostic pair
===============================================

Derived from combined-cpu8-gpu-quiet. Kernel #10 adds LCDB state/error
handling; initramfs replaces only panel-ilitek-ili7807s.ko to report supply
cleanup failures. DT, U-Boot, all other initramfs payloads, GPU/Zap order,
CPU8 and screen console settings are unchanged.

Images:
  u-boot-hanoip-display-robust-v2.img
  kernel-hanoip-display-robust-v2.img

Use only volatile fastboot boot. Never flash any image or phone partition.
Preserved return pair: work/cpu-gpu-20261025/combined-cpu8-gpu-quiet/.
GOLD folders are untouched.

Sources:
  kernel-mainline/drivers/regulator/qcom-lcdb-regulator.c
  kernel-mainline/drivers/gpu/drm/panel/panel-ilitek-ili7807s.c
Host fault tests: python3 scripts/tests/hanoip-lcdb-host-test.py
Checkpoint: docs/kernel/checkpoint-2026-10-25-display-robustness.txt

Build environment: hanoip-mainline-build-20261024, /tmp/kernel-mainline.
Kernel: make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- -j8 Image
Panel: make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
       M=drivers/gpu/drm/panel CONFIG_DRM_PANEL_EDP= CONFIG_DRM_PANEL_SIMPLE=
       KBUILD_EXTRA_SYMBOLS=/tmp/hanoip-display-extra.symvers -j8 modules
The extra symvers contains the drm_display_helper exports from the existing
kernel Module.symvers. Config overrides exclude unrelated panel module builds.

Boot and cycle test results are recorded in runtime-v2.txt and the checkpoint.
Suspend/resume and the intermittent startup FIFO issue remain unvalidated.
