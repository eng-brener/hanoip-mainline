Sensor probe v2: failed diagnostic attempt. Do not boot this image or reapply
the overlay until the kernel stall described below is understood. The earlier
U-Boot DT variant also hung at the Motorola M screen; do not boot that custom
v1 U-Boot image again.

The kernel module calls the exported OF overlay API to set only the `status`
of `/soc@0/geniqup@ac0000/i2c@a94000` to `okay`. No other controller or sensor
register is touched by the overlay. The module is manually inserted after
checking the shell and mounts; it can be removed to retract the overlay.

The original procedure was booting known-good U-Boot v5, verifying the RAM-only
mounts, manually inserting the module, then reading the two identity registers.
Execution stopped during module insertion before the helper ran. Do not run
`i2cdetect`, `i2cset`, the helper, or the overlay again until the stall is
understood.

TEST RESULT (2026-10-26): the known-good v5 U-Boot and this RAM-only kernel
booted to the USB shell; black display was expected because no display loader
is in this initramfs. Mounts were only rootfs/proc/sysfs/devtmpfs/tmpfs/configfs.
`insmod` applied the overlay and logged `geni_i2c a94000.i2c: Bus frequency not
specified, default to 100kHz`, but did not return to the shell. RCU stall logs
followed; CPU4 did not answer NMI. No sensor identity reads were attempted.
Power reset recovered the Motorola bootloader, then the tested v5/v6 pmOS pair
was restored (SSH works, DSI connected at 1080x2460, wlan0 up). Do NOT retry
the overlay until the cause of the kernel stall is understood. Never flash.
