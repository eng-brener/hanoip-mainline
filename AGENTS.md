# Device safety

The user forbids flashing or writing any phone partition. Preserve this rule
throughout this project, including later sessions.

- Never use fastboot flash/erase/format/update, change the active slot, write
  /dev/block devices, repair phone filesystems, or push files onto partitions.
- Do not execute historical flashing examples in README.md or docs/.
- Read-only ADB collection and local source/build/artifact changes are allowed.
- Volatile tests with `fastboot boot` have been authorized and used in this
  session. Keep diagnostic root filesystems in RAM, without automounting disks.
- Keep known-good images and hashes before preparing another variant.

# Current baseline

The 2026-10-24 USB-shell checkpoint boots Linux 7.1.0-sm7150 through a volatile
U-Boot with fastboot flashing disabled. It includes the QUP interconnect fix
from upstream PR 66. The validated v2 images and serial logs are under
work/hanoip-build-20261024/v2/.

The later UFS read-only checkpoint is under
work/hanoip-ufs-modules-20261024/iommu/. Six disks and 78 partitions were
enumerated, all 84 block devices were marked read-only, and three 64 KiB
reads matched Android. The working effective DT must retain
`iommus = <&apps_smmu 0x300 0x0>` for UFS. Removing it causes NOP OUT timeouts
with the current strict SMMU configuration. See
docs/kernel/checkpoint-2026-10-24-ufs-leitura.txt.

The BusyBox supplied by the old ramdisk is Android-specific: its reboot applet
calls setprop, which is absent in this initramfs. Do not assume that applet
actually restarted the device; verify USB/ADB state after a reset request.
The UFS diagnostic ramdisk includes a separate /sbin/reboot script which
checks for RAM-only mounts and uses SysRq. It returns to the Motorola
bootloader; normal `fastboot reboot` returned to Android in this session.

# Display experiment, 2026-10-24

The newest display pair is under work/hanoip-display-20261024/no-reset/:
u-boot-hanoip-display-noreset.img and kernel-hanoip-display-noreset.img.
Both are volatile only; UFS/SD stay disabled. Manual module loading created
card0-DSI-1 connected/enabled, active 1080x2460 at 60 Hz with two DSC blocks,
and fb0 named msmdrmfb. The user confirmed the test message appeared on the
screen. Touch/GPU have not been validated. Do not replace the known-good
USB/UFS images.

Keep qcom,sm7150-mdss in qcom_smmu_client_of_match: its initial identity
domain prevents framebuffer SMMU faults before DRM handoff. Do not remove
the working UFS iommus property or globally weaken IOMMU settings.

The display clock driver's GDSC must be registered. However, asserting the
MDSS core BCR reset rebooted the board before reset release, as recorded in
trace/msm-registration.txt. Only the display diagnostic DTs omit &mdss resets;
the normal DTS and panel reset-gpios were not changed for that workaround.
Earlier display images with MDSS core reset are failed variants. See
docs/kernel/checkpoint-2026-10-24-display.txt for evidence and limitations.

/sbin/reboot can return directly to Android or to Motorola fastboot. Detect
USB/ADB state after reset; do not assume which one will appear.

# Latest handoff

Read `onde paramos.md`, especially the new "Retomada após o handoff" section.
The initially compiled fix in handoff-unbooted/ has now been booted and FAILED:
MSM attempted iommu_map before SMMU page table initialization (-ENODEV), then a
DRM double cleanup caused an Oops. Do not use that kernel as a working baseline.
The fix is now in the arm-smmu attach path, after table initialization but before
stream switching; MSM only reserves the IOVA range. DPU cleanup is idempotent.
The new Image + msm.ko are in work/hanoip-touch-20261024/handoff-v2/, using the
same handoff-unbooted U-Boot and DTs. The second kernel (#8) opened USB serial and initialized display with the
splash mapped before stream switching, connected/enabled 1080x2460, tainted=0
and no SMMU/DSI errors. The user confirmed "sim tem mensagem na tela". Touch initialized;
physical events are now validated: 15 single-finger contacts and then 42
contacts with up to two simultaneous fingers, balanced releases and zero
rejected reports (2347 accepted packets total, tainted=0). See the touch
checkpoint and handoff-v2/input-*-analysis.json. A copy of the matching U-Boot
is now in handoff-v2/u-boot-hanoip-touch-handoff-v2.img. Display and two-finger
input are validated on this boot; repeatability, corners/orientation and power
management remain unvalidated. BusyBox timeout requires `-t SECONDS`.

# User prioritization after touch checkpoint

The user explicitly deferred polishing the touch. Keep corner/orientation,
calibration, filtering and further multitouch/gesture work for later. The user
then requested stepping back to check more fundamental priorities: USB networking
is deferred behind reproducible volatile boot and power/CPU management. Read
work/base-audit-20261024/LEIA-ME.txt and runtime.txt. CPUfreq/idle are intentionally
disabled, CPUs 0-5 online of 0-7, no battery gauge supply exposed, temperatures
36.1-38.7 C in this sample. idle=poll was reported unknown on ARM64; do not claim
it is effectively polling. Change one workaround at a time, retaining the working
image and RAM-only guards. LCDB error/refcount robustness remains pending before
panel power cycles or suspend tests. No power-management changes have been made.
All device partition-write prohibitions remain in force.

# Latest current experiment: CPUidle after CPUfreq validation

Read the FIRST section of onde paramos.md. Display baseline quiesce-late combines
Tianma brightness byte-order fix, quiescing inherited DSI modes before local
reset, and deferring VIDEO until bridge.enable (this board/panel only). Two exact
boots had user-confirmed stable text; first had 6 startup FIFO IRQs unchanged
through uptime209s, second ZERO. Startup FIFO remains open, not universally fixed.
Cached error_snapshot is safe to read; avoid panel_status LP DCS polling.

CPUfreq validated in work/cpufreq-20261024/quiesce-late-baseline/: qcom-cpufreq-hw,
CPUs0..5, 300..1804.8MHz. powersave/performance/schedutil test passed, hardware
reports matched, temperatures39..42.5C, zero DSI faults, tainted0, user confirmed
stable display. See cpufreq checkpoint. Retain this pair as return baseline.

Full CPUidle pair in work/cpuidle-20261024/ booted, registered psci_idle/menu
and exercised local PC/rail-PC states, but the user reported BLACK display.
Do NOT promote it as working. Two startup DSI FIFO IRQs, unchanged through
uptime255s, tainted0. Runtime disabled all state1/2 via sysfs; visual recovery
was not confirmed. Current experiment in work/cpuidle-20261024/local-only/
removes cluster_pd domain-idle-states (keeps local CPU states) to isolate
L3/CX/AOSS collapse. Local-only PASSED on two boots (local-only/ and
local-only-repeat/): DSI irqs=0, tainted0, all CPUs ~5s/5s in cpu-sleep-0-1,
user confirmed display both times. See docs/kernel/checkpoint-2026-10-25-cpuidle.txt.
Cluster collapse is the prime suspect for the black screen, not proven.
Local-only (CPUfreq + local idle) is now the power return pair; CPUfreq
quiesce-late-baseline with idle off remains preserved.
UFS everything-on variant work/ufs-20261025/ufs-local/ passed ONE boot:
display irqs=0, 84 blocks all RO, sdb hash matches Android, ~510 MB/s reads,
touch events (manual insmod; load-touch refuses exposed storage). See
docs/kernel/checkpoint-2026-10-25-ufs-tudo-ligado.txt. Never mount UFS.

# Paused: USB network + SSH/SFTP (read FIRST section of onde paramos.md)

work/usbnet-20261025/v1/ = GOLD kernel/DT/U-Boot + new ramdisk (ACM+NCM
composite gadget, udhcpd, static musl dropbear + sftp-server). SSH/SFTP to
172.16.42.1 worked with serial alive, but display went BLACK with 2 startup
DSI FIFO IRQs when loaded at ~72 s after scp traffic. Not attributed yet;
next: reboot v1 and load display early before network traffic.

# GOLD v2 (user-designated 2026-10-25 10:47 -03) — DEFAULT RETURN PAIR

work/GOLD-20261025-1047/ (read-only, GOLD.txt + SHA256SUMS): same kernel/DT/
U-Boot as the first GOLD, ramdisk adds autostart (display before network),
ACM+NCM gadget, static dropbear + sftp-server, enter-pmos, and RO-aware
load-touch/load-display. kernel-hanoip-v2.img 4f12de96..., U-Boot 33c05711....
Never modify GOLD folders; build variants elsewhere. Volatile boot only.

# First GOLD version (user-designated 2026-10-25 01:26 -03), preserved

work/GOLD-20261025-0126/ is a read-only copy of the ufs-local pair with
GOLD.txt and SHA256SUMS (kernel c99f8cf5..., U-Boot 33c05711...). It is the
default return pair from now on. Never modify files in that folder; build new
variants elsewhere. Volatile fastboot boot only, never flash. Battery/charger, LCDB/display robustness, CPUs6/7, long-run
stability and suspend remain pending. Touch polish stays deferred. No flash
or phone partition writes under any circumstances.
