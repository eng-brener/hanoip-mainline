Hanoip sensor bus probe — SE11 only — prepared 2026-10-26

STATUS: DO NOT USE the U-Boot image in this folder. It was booted once and
stopped at the Motorola M screen without re-enumerating USB fastboot. The
kernel image was later booted with the known-good perif-v5 U-Boot as a RAM-only
shell; the effective DT kept SE11 disabled, so no sensor reads occurred.

Preserved artifact hashes (not a recommendation to boot this pair):
  U-Boot  8f48dd9ded383bca388cea3e2430806122bd1e4a1b04a5e60dd18025bed05ae4
  Kernel  8c10dbaef333c623701231bb972e35c69a4b158265fc5818de261397b3af851f

U-Boot DT is based on the current peripheral v5 tree. The only new enabled
controller is QUP SE11 I2C at a94000, using existing GPIO101/102 pinctrl. No
sensor client nodes, GPIO IRQs or power rails were added. NFC (SE2), SAR
(SE7), and console (SE3) are unchanged. UFS/SCSI and fastboot flash are disabled
in U-Boot; the kernel initramfs uses only RAM/pseudo filesystems and has no
partition-mount or storage-autoload path.

The kernel is the tested Linux 7.3 QRTR fix (#6) Image. Its RAM-only shell
initramfs is based on the existing 7.3 shell ramdisk and replaces `/init` with
`scripts/hanoip-usb-shell.init`. It brings up the ACM USB shell but does not
start pmOS or mount a phone partition. The static AArch64 helper and manual
script are included in the initramfs.

The helper locates the adapter only by its `a94000.i2c` sysfs path and is
hard-limited to address/register pairs 0x68/0x75 and 0x39/0x93. It sends the
register index followed by an I2C read; it contains no sensor register-write
operation and does not scan other addresses. 0x75 is ICM WHO_AM_I; 0x93 is the
TMD2755 ID register (0x92 is REVID). A no-ACK result is inconclusive: the
sensor rails are controlled by the ADSP on Android, and this diagnostic does
not enable unknown rails. Also, the ICM registry says bus_type=3 and I3C
address 10, so lack of an I2C response would not disprove that the device is
present.

Register references: the TMD2755 datasheet identifies ID at 0x93 and REVID at
0x92 (https://docs.rs-online.com/570f/A700000008290199.pdf); TDK's ICM-42688-P
datasheet identifies WHO_AM_I at 0x75
(https://invensense.tdk.com/wp-content/uploads/2021/06/DS-000347-ICM-42688-P-v1.5.pdf).

The U-Boot image is a failed variant. Do not boot it again. Preserve the
kernel only records the shell test with SE11 disabled; it is not a sensor-test
pair. Preserve the current v5/v6 pair and GOLD v4. Never flash. See
`docs/kernel/checkpoint-2026-10-25-sensores.txt` for the offline inventory.
