GPU Zap firmware early initramfs variant
========================================

Derived from ../gpu/ only. The original gpu/ artifacts are unchanged.
This variant changes initramfs ordering: load-ufs first applies kernel
BLKROSET to enumerated disks and partitions; load-gpu-firmware then checks
every sd* block device has ro=1, hashes modem_a, mounts it with
ro,noload,nodev,nosuid,noexec, links a615_zap.mdt and b00-b02, and verifies
the raw modem_a hash is unchanged. Only after that does autostart call
load-display. load-wifi reuses the same mount after checking source and RO
mount options, avoiding a duplicate mount. No partition is written.

The newc archive is normalized to uid=0/gid=0 after packing so Dropbear's
strict authorized_keys ownership checks pass. The boot image keeps the
original GPU kernel, DTB and boot header fields; only the compressed ramdisk
payload and its size field differ. U-Boot and the GPU DT are copied from
../gpu/. The first package booted and Mesa/KMSCube rendered on FD618. After
that run, initramfs ownership was normalized to root to fix Dropbear
StrictModes; the corrected on-disk package has not yet been rebooted. See
docs/kernel/checkpoint-2026-10-25-gpu.txt for the captured evidence.

`pmos-mesa-kmscube-rootfs.tar.gz` is the Alpine 3.24 diagnostic rootfs used
for rendering. It was transferred only to /tmp and unpacked on a tmpfs.

Volatile boot procedure (when ready to test):
  fastboot boot u-boot-hanoip-gpu-zap-early.img
  fastboot boot kernel-hanoip-gpu-zap-early.img

Never flash these images. Preserve ../gpu/ and all GOLD directories.
