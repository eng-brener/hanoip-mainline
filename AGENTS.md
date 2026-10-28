# Device safety

The user forbids flashing or writing any phone partition. Preserve this rule
throughout this project, including later sessions.

# THE DEVICE TREE COMES FROM U-BOOT, NEVER FROM THE KERNEL boot.img

This is a safety rule, not a detail. The effective DT of this board is EMBEDDED
in U-Boot (CONFIG_OF_EMBED); the dtb inside the kernel boot.img is NOT used.
Verified in the field: a DT edit only takes effect after rebuilding U-Boot and
booting that image, and /proc/device-tree then shows the new values.

Consequences that must shape every change and every record:

- any DT change (battery OCV table, internal resistance, panel, Type-C role,
  dr_mode, regulators) requires an U-Boot rebuild, and a fresh `fastboot boot`;
- the DT state is VOLATILE and lives inside the booted image. Booting another
  U-Boot, for example an older one, silently reverts the DT even with the same
  rootfs and the same modules. That is how a fixed wall charger can "break"
  again with nothing changed on the phone;
- therefore any snapshot/GOLD of a state with DT changes MUST store the U-Boot
  image together with the kernel and modules (see
  work/PRE-GOLD-20261027-1852/ and work/PRE-GOLD-20261028-1133/, which keep
  uboot/, kernel/, dt/ and patches/);
- CURRENT BASELINE PAIR (user-designated 2026-10-28 11:33):
  work/PRE-GOLD-20261028-1133/ = cluster-idle U-Boot + VENUS enabled
  (status=okay, firmware qcom/sm7150/motorola/hanoip/venus.mdt) + kernel
  7.3.0-sm7150 #24 (v3-teo). Hardware H.264 decode validated there
  (/dev/video0, fw_level 0x18, ~2.8x less CPU than avdec_h264). Boot it with
  `fastboot boot uboot/u-boot-*-clusteridle-venus.img` then
  `fastboot boot kernel/kernel-hanoip-kali-phosh-v3-teo.img`. Read-only.
- prove DT changes surgically with scripts/fdt_diff.py between the built .dtb
  files, never by reading the .dts. Note that 4-byte string values ("otg") used
  to be printed as integers by this tool; it is fixed, but distrust round
  numbers when they appear where a string belongs;
- do not trust a .ko hash to prove "only comments changed": the linker build-id
  differs between builds. Compare objdump output or cmp ignoring those bytes.

DT changes that were actually killed/prepared here: Type-C power-role
"source" -> "dual" with 5 V sink PDOs (this is what unblocked the wall charger),
the Motorola OCV curve plus 200 mOhm internal resistance, and
dr_mode="otg" + usb-role-switch for USB host.

- Never use fastboot flash/erase/format/update, change the active slot, write
  /dev/block devices, repair phone filesystems, or push files onto partitions.
- Do not execute historical flashing examples in README.md or docs/.
- Read-only ADB collection and local source/build/artifact changes are allowed.
- 2026-10-25: the user authorized READ-ONLY mounts of UFS partitions, only
  when the block device is already kernel read-only (BLKROSET guard, sysfs
  ro=1) and with ro,noload (ext4) plus nodev,nosuid,noexec. Prove no writes
  by hashing the raw partition before and after. Writing stays forbidden;
  never mount super/userdata/persist/metadata without asking again.
- 2026-10-25: one-time UFS write test on logo_b (inactive slot B) with backup,
  verify and byte-exact restore was authorized and done (RESTORE_OK). That
  does NOT authorize other writes. Partitions report RO only via their disk:
  pin every partition's own RO flag before ever making a disk writable.
- 2026-10-25: the user authorized a pmOS rootfs on the UNALLOCATED tail of
  `super` (sdb23), the space of the inactive slot B group. Active slot is A.
  Allowed: write only inside that tail (after the last LP extent, vendor_a
  ending at LP sector 10555160, plus margin), through a loop/dm device bounded
  by offset and size. Forbidden: changing LP metadata, touching any _a volume
  or other partition, userdata/persist/metadata. Pin every other sdb
  partition RO by its own flag first, hash super head (LP metadata) and the _a
  extents before/after, and get explicit user go before the first write.
  U-Boot and kernel stay volatile (`fastboot boot`); physical _b partitions
  stay untouched. An Android OTA would overwrite this region.
- Volatile tests with `fastboot boot` have been authorized and used in this
  session. Keep diagnostic root filesystems in RAM, without automounting disks.
- Keep known-good images and hashes before preparing another variant.

# Bateria: SOC corrigido e CARGA funcionando (2026-10-27, Kali)

A porcentagem agora vem de uma tabela OCV REAL, extraída do perfil de bateria
que o Android usa neste aparelho (S88731AA1-mc50-ATL-4V45-6000mah). O DT que
vale no sm7150 vem EMBUTIDO NO U-BOOT (CONFIG_OF_EMBED) — o dtb do boot.img do
kernel não é usado; mudar DT = reconstruir U-Boot. Use scripts/fdt_diff.py
para provar que a variante muda só o esperado.

A carga FUNCIONA e é OPT-IN, desligada por padrão:
  echo 1|0 > /sys/kernel/debug/hanoip-charge      (limite 1 A, watchdog
                                                   desarmado antes de ligar)
  cat /sys/kernel/debug/c440000.spmi:pmic@0:charger@1000     (dump read-only)
Validado 15 min: 497 mA de entrada (SDP), +440 mA na bateria, 32-34 C, sem
erro. Float 4.400 V, JEITA e terminação continuam como a ABL deixou.
Com entrada de 500 mA e TELA LIGADA o aparelho consome mais do que recebe: a
corrente fica negativa, o UPower mostra "descarregando" e o sysfs "Charging".
Próximo passo combinado: B4 (APSD/ICL) para carregar com a tela ligada.
Detalhes: docs/kernel/checkpoint-2026-10-27-bateria-RESUMO.txt e
work/bateria-soc-20261027/. Nada disso autoriza escrever partição.

# Latest runtime: sensors PASSED via ADSP, 2026-10-26

Read `onde paramos.md` latest state and
`docs/kernel/checkpoint-2026-10-26-sensores-plasma.txt` FIRST. Phone is in
the complete Plasma session under kernel 7.3 #6/perif-v5 U-Boot; sensors
ADSP/FastRPC/libssc/iio-sensor-proxy started. Light D-Bus works; user confirmed
rotation does not. Root partition is ro,noload,nodev,nosuid,noexec with RAM
OverlayFS. Never repeat whole-super hashing during boot; it added ~235 s.
Continue diagnosis in RAM overlay, do not overwrite known baseline. Camera and
fingerprint remain paused. Earlier test checkpoints are historical.

# Current work: sensor SE11 probe stalled; baseline restored (2026-10-26)

Update: static extraction of this phone's ADSP firmware now maps registry
bus 1 to SSC SE0 at 0x62680000 (SSC GPIO0/1, I3C) and bus 5 to SSC SE4 at
0x62690000 (SSC GPIO6/7 func4, I2C). sensor_vdd is L7C with a configured
3312 mV vote; sensor_vddio is L8C/1800 mV. `/dev/qup_ssc/11` names a DAL
profile with SIX engine configs, not AP SE11. Read the NEW checkpoint
`docs/kernel/checkpoint-2026-10-26-sensores-ssc.txt` and reproducible parser
in `work/sensors-20261026/ssc-mapping/`. These are static values, not AP
access validation. Prefer investigating ADSP sensors-PD/FastRPC + libssc
with a RAM-backed registry before direct AP controller bring-up. ADSP and
FastRPC nodes/modules already exist; the saved pmOS package list includes
libssc and iio-sensor-proxy but not hexagonrpcd. No phone writes or installs.
ADB disappeared during offline analysis, then returned before finishing FPC
research. The phone remains in Android with root. Read-only debugfs inventory
found no pinctrl/clock/regulator interfaces; no mounts were performed. No boot.

FPC fingerprint was also investigated offline at the user's request. Read
`docs/kernel/checkpoint-2026-10-26-fingerprint-fpc.txt` and
`work/fingerprint-20261026/`. Actual FPC enable is GPIO29 (GPIO30 belongs to
the alternative Chipone node), reset GPIO4, IRQ GPIO90. fpc1020 is a generic
helper compatible, not an identified silicon model. The trusted app uses
legacy QSEECOM and imports qsee_spi_*; SPI1/0x884000 is a strong static
candidate, not verified AP access. Do not enable its AP SPI controller,
toggle GPIOs, start TEE commands or read enrollment databases. HAL program
binaries and RO attributes have now been collected under
work/fingerprint-20261026/android-live-readonly/: vendor=fpc, modalias=fpc1020,
irq=0, irq_cnt=60. HAL is AArch64 and imports the legacy QSEECom_* calls.
Its fpc1540 string is only a clue; vendor.hw.fingerprint.hwid was empty.
Modern qcomtee is not a drop-in replacement for the Android QSEECOM ABI.

The user explicitly STOPPED the FPC investigation and switched to cameras.
All latest FPC protocol findings are saved at the top of
docs/kernel/checkpoint-2026-10-26-fingerprint-fpc.txt and in
work/fingerprint-20261026/hal-protocol/. No TEE command was executed. Do not
continue FPC analysis until requested. Camera investigation was then also
deferred by the user; partial notes are in
docs/kernel/checkpoint-2026-10-26-cameras-parcial.txt. Current task: TEST
sensors via the ADSP/FastRPC path. work/sensors-20261026/ssc-ram-test/
contains a RAM-only userspace/initramfs variant, SAME kernel #6/DT and
known-good perif-v5 U-Boot, with hexagonrpcd and ssccli. Firmware/config/
registry copies are in RAM, no UFS mounts or AP SE11. Volatile boot requested
by user and initiated; inspect run1/ and runtime logs before concluding.

Read the first section of `onde paramos.md` and
`docs/kernel/checkpoint-2026-10-26-sensores-preparado.txt`. The SE11 U-Boot DT
variant hung at the Motorola M screen. With known-good U-Boot v5, a RAM-only
shell kernel booted; a runtime OF overlay then enabled SE11, but `geni_i2c`
probe did not return and the kernel logged RCU stalls with CPU4 unresponsive
to NMI. No sensor ID read occurred. Do NOT reuse the sensor-v1 U-Boot or apply
the SE11 overlay again until this stall is understood. Unknown sensor rails
remain untouched; do not probe other buses. After that incident, perif v5 +
kernel #6 was restored and SSH, DSI 1080x2460 and wlan0 were confirmed. The
user has since switched to Android with root for read-only sensor collection.
SensorService shows active ICM4x6xx and TMD2755 sensors with recent events; AP
I2C adapters are only 0..2 and `a94000` is absent. The firmware string
`/dev/qup_ssc/11` does not prove AP SE11 mapping. Read
`docs/kernel/checkpoint-2026-10-26-sensores-preparado.txt` and
`work/sensors-20261026/android-live-readonly/`. Do not probe or enable other
buses/rails until the SSC-to-QUP mapping is understood. Only volatile
`fastboot boot`; all partition-write prohibitions remain.

# Kernel 7.3 v2 (2026-10-26): v1 + fork PRs #70, #64, #65, #60

work/kernel-7.3/v2/ (README.txt), 160 patches on v7.3. Battery telemetry
drivers from the fork PRs (charging still monitor-only) and the shared LPASS
audio nodes as the base for audio work (disabled; not in the U-Boot DT).
In `sh`, a trailing `&` makes the command read stdin from /dev/null: never
pipe a tarball into a backgrounded list, and never delete a modules tree
before the new one is extracted.

# Kernel 7.3 migration (2026-10-25, validated on two boots, not a GOLD)

work/kernel-7.3/v1/ (README.txt): upstream v7.3 + 128 patches (sm7150-mainline
fork, hanoip delta, qcom_qg IIO_CONSUMER fix). Same U-Boot/DT and rootfs as
GOLD v4; the rootfs carries /lib/modules for 7.1.0 and 7.3.0. Everything
validated on 7.1 also works on 7.3. GOLD v4 stays the default return pair
until the user promotes another. Boot GOLD images from a copy: the volatile
boot helper writes next to the image and GOLD folders are read-only.

# GOLD v4 (user-designated 2026-10-25 ~16:59 -03) — DEFAULT RETURN PAIR

work/GOLD-20261025-1659/ (read-only, GOLD.txt + SHA256SUMS). Real pmOS v26.06
with Plasma Mobile: rootfs on the unallocated super tail (offset 5160 MiB,
5120 MiB, ext4 hanoip_pmos), booted by volatile `fastboot boot` of
u-boot-hanoip-pmos-v1.img then kernel-hanoip-pmos-super-v1.img (kernel #10;
ramdisk switch_roots via /sbin/pmos-root). Read the FIRST section of
`onde paramos.md`. Touch is a panel follower (IRAM reload on panel-on), polkit
must be polkit-elogind, NetworkManager owns wlan0, hanoip-firmware relinks
/mnt/ro firmware, module autoload blacklist in /etc/modprobe.d. Never unbind
hci_uart_qca (Oops). The Wi-Fi password and the user PIN live only on the
phone; never copy them into images, snapshots, docs or commits. Rebuild with
work/pmos-super-20261025/build-rootfs.sh. Writing anything outside the super
tail stays forbidden. GOLD v3/v2/first are preserved; never modify GOLD
folders. Battery charging is still disabled (it discharges on USB).

# Latest confirmed experiment: battery/charger telemetry (2026-10-25)

Read the FIRST section of `onde paramos.md` and
`docs/kernel/checkpoint-2026-10-25-battery.txt`. The phone is running volatile
`work/battery-20261025/telemetry-v1/`, derived from display-v2/kernel #10.
PM6150 QG exposes battery voltage/current/temperature and voltage-derived
capacity estimate; 56–57% observed is NOT calibrated SOC. A monitor-only SMB
driver exposes USB online/status/voltage/current without charger configuration
or writes. Battery current responded to a short bounded load (about -169 to
-228 mA, USB about 495–498 mA), then returned near zero. USB is present but
reports `Not charging`; charging control, JEITA/USB-PD, calibrated SOC, long
run and suspend/resume are still pending. The SoC peaked at 74.5 C in that
short test; DSI irqs=0, all 84 block devices RO, SDAM `force_ro=1`.
No phone partition was written. Keep this passive telemetry pair and the
display-v2 return pair; do not promote to GOLD or commit without user request.

# Previous confirmed experiment: LCDB/display robustness (2026-10-25)

Read the FIRST section of `onde paramos.md`. Phone is now running the volatile
`work/display-robustness-20261025/display-v2/` pair (kernel #10), derived from
`combined-cpu8-gpu-quiet/`. LCDB shared state is mutex-protected per rail;
error/timeout handling, rollback, ABL adoption order and DT constraint parsing
are fixed. The panel reports regulator cleanup/power-down failures. Nine real
panel power cycles passed across v1/v2 (six + three), DSI irqs=0, balanced
regulator counts, user confirmed normal image after the final sequence.
Host fault/concurrency tests also passed. See
`docs/kernel/checkpoint-2026-10-25-display-robustness.txt`.
This supersedes the historical LCDB refcount/error-robustness pending notes
below. It does NOT validate suspend/resume or fix intermittent startup FIFO.
MDSS BCR, SMMU handoff and UFS guards remain unchanged. GOLDs and the previous
combined quiet pair are preserved; no GOLD promotion has been requested.

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

# GOLD v3 complete (user-designated 2026-10-25 12:03 -03), preserved

work/GOLD-20261025-1203/ (read-only, GOLD.txt + SHA256SUMS): Image #8 with the
wifi diagnostic DT, U-Boot with abl_identity.c and a ramdisk that brings up
display, USB network/SSH, UFS (RO), modem + Wi-Fi and Bluetooth on its own.
Device identity comes from ABL through U-Boot at every boot; never put device
identifiers or Wi-Fi passwords in images, scripts or commits. kernel
5260ee61..., U-Boot faf8014b.... Unmount /mnt/ro/* before /sbin/reboot.

# GOLD v2 (user-designated 2026-10-25 10:47 -03), preserved

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

# Reboot rule (2026-10-26, user request)

ALWAYS reboot into the bootloader (Motorola fastboot), never into Android.
Reason: Android would boot with the Kali rootfs in userdata and could try to
format/factory-reset it, destroying the Kali install. From Linux, trigger the
reset and make sure the device lands in fastboot before doing anything else;
if it lands in Android, stop and ask the user to force the bootloader.
