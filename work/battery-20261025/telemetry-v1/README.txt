Battery/USB passive telemetry diagnostic — 2026-10-25

This volatile pair was booted and remains the current phone state:

  U-Boot: u-boot-hanoip-battery-telemetry-v1.img
  Kernel: kernel-hanoip-battery-telemetry-v1.img

SHA256:
  U-Boot  b8674f8145f0bf62330b7d0742b8f6c1b02ae3d5b492139bef6c6f104fc573dc
  Kernel  b37bf4a689cc332b7166802e9b145669e4956a141220ea4d679b6ac3955b6fcf

The kernel is Linux 7.1.0-sm7150 #10, reused from display-v2. The DT enables
PM6150 ADC5, SDAM and QG plus a Hanoip SMB5 monitor-only match. The ramdisk
loads the modules from /lib/hanoip-battery using /sbin/hanoip-load-battery.sh.
The monitor-only driver does not configure the charger or Type-C hardware and
does not expose write callbacks. SDAM is read-only.

Observed: battery around 3.91 V and 31 C; QG reported 56–57% from its
voltage-based estimate, not calibrated pack SOC. USB was online around 5.07 V,
with a 500 mA reported maximum. Both supplies reported “Not charging”. A short
bounded CPU load confirmed battery current changes from near zero at idle to
about -169…-228 mA while USB current approached 495–498 mA, then returned
near idle. Maximum SoC temperature was 74.5 C. Display stayed active, DSI
error IRQ count was zero, all 84 block devices were read-only, and SDAM
force_ro was 1.

This proves telemetry response only. It does not enable/validate charging,
JEITA, USB-PD, calibrated SOC, suspend/resume or prolonged stability. No phone
partition was written. Continue with `docs/kernel/checkpoint-2026-10-25-battery.txt`
and the first section of `onde paramos.md`. Preserve display-v2 and GOLDs.

Build sources: kernel DTS at
kernel-mainline/arch/arm64/boot/dts/qcom/sm7150-motorola-hanoip-battery-diagnostic.dts;
U-Boot DTS at
uboot-sm7150/dts/upstream/src/arm64/qcom/sm7150-motorola-hanoip-battery-diagnostic.dts;
monitor script at scripts/hanoip-load-battery.sh. Module source snapshots and
build logs are kept in this directory. The host helper check is recorded in
host-test.txt.
