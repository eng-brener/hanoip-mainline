#!/bin/sh
# Telemetry only: do not program charger limits, Type-C, or QG/SDAM contents.
BB=/bin/busybox
LOG=/run/hanoip-battery.log
W=/lib/hanoip-battery
exec >> "$LOG" 2>&1
echo "battery monitor start $($BB cut -d' ' -f1 /proc/uptime)"
for m in qcom-spmi-adc5 qcom-spmi-sdam qcom_smbx qcom_qg; do
	N=$($BB echo "$m" | $BB tr - _)
	$BB grep -q "^$N " /proc/modules || $BB insmod "$W/$m.ko" || exit 1
done
i=0
while [ ! -e /sys/class/power_supply/qcom_qg ] ||
      [ ! -e /sys/class/power_supply/hanoip-pm6150-monitor-charger ]; do
	[ "$i" -lt 20 ] || { echo 'battery/charger supply probe timed out'; exit 1; }
	$BB sleep 1
	i=$((i + 1))
done
$BB ls /sys/class/power_supply
echo "battery monitor modules loaded $($BB cut -d' ' -f1 /proc/uptime)"
