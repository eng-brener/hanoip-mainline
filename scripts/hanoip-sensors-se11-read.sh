#!/bin/sh
# Manual, read-only identity probe for the two sensor addresses on SE11 only.
set -eu
found=
for path in /sys/bus/i2c/devices/i2c-*; do
	[ -e "$path" ] || continue
	real=$(readlink -f "$path" 2>/dev/null || true)
	case "$real" in
		*/a94000.i2c/i2c-*) found=${path##*/}; break ;;
	esac
done
if [ -z "$found" ]; then
	echo "SE11 (a94000) I2C adapter not found" >&2
	exit 1
fi
dev="/dev/$found"
echo "SE11 adapter: $dev -> $(readlink -f "/sys/bus/i2c/devices/$found")"
echo "Reading ICM identity register 0x75 at address 0x68"
/sbin/hanoip-i2c-id-read "$dev" 0x68 0x75 || true
echo "Reading TMD2755 identity register 0x93 at address 0x39"
/sbin/hanoip-i2c-id-read "$dev" 0x39 0x93 || true
