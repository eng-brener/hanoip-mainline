#!/bin/sh
# Three-camera test, run on the phone from /dev/shm (RAM only, nothing installed).
# Boot: U-Boot cam-tres + kernel-v5-cam-etapa3.logbuf.img. Modules expected in
# /dev/shm: qcom-camss.ko (camss-cphydiag-test), i2c-qcom-cci.ko
# (cci-resume-reset), hanoip-vcm.ko, s5k4h7.ko, hanoip-cam.ko. Diagnostics (camss-diag-test): /sys/module/qcom_camss/parameters/
# lane_map ("N:a,b,c"), dphy_settle, phy_status (read while streaming).
#   sh test-tres.sh load            load modules, print probes and graph
#   sh test-tres.sh cap s5k4h7|s5khm2|ov32b [exposure] [gain]
set -u
cd /dev/shm
M="media-ctl -d /dev/media0"

subdev() {	# subdev node of sensor $1 (the hanoip-cam ones by I2C address)
	case $1 in
	s5khm2) n="s5khm2 12-0056";; ov32b) n="ov32b 14-0010";; *) n="$1 ";;
	esac
	for s in /sys/class/video4linux/v4l-subdev*; do
		case "$(cat "$s/name")" in "$n"*) basename "$s"; return;; esac
	done
}

load() {
	modprobe v4l2_fwnode; modprobe videodev; modprobe videobuf2_dma_sg
	# CCI with reset on runtime resume (cci-resume-reset), replacing the
	# autoloaded one before any camera driver binds.
	if [ -f i2c-qcom-cci.ko ]; then
		rmmod i2c_qcom_cci && insmod i2c-qcom-cci.ko && sleep 1
	fi
	insmod qcom-camss.ko && sleep 1
	# Sensors register with lens-focus: the VCM driver must be there too.
	insmod hanoip-vcm.ko; insmod s5k4h7.ko; insmod hanoip-cam.ko
	sleep 3
	dmesg | grep -vE "spmi|vfe irq" | grep -iE "s5k4h7|hanoip-cam|hanoip-vcm|s5khm2|ov32b|VCM|cci|chip id" | tail -12
	$M -p | grep -E "^- entity.*(s5k|ov32|lens|vcm|000c)"
	for s in s5k4h7 s5khm2 ov32b; do echo "$s -> $(subdev $s)"; done
	cat /proc/sys/kernel/tainted
}

cap() {
	cam=$1; exp=${2:-}; gain=${3:-}
	case $cam in
	s5k4h7) phy=msm_csiphy1; w=3264; h=2448;;
	s5khm2) phy=msm_csiphy0; w=4000; h=3000;;
	ov32b)  phy=msm_csiphy2; w=3264; h=2448;;
	*) echo "camera?"; return 1;;
	esac
	sd=$(subdev $cam)
	[ -n "$sd" ] || { echo "$cam: no subdev"; return 1; }
	code=$(v4l2-ctl -d /dev/$sd --get-subdev-fmt pad=0 | sed -n 's/.*Mediabus Code *: *0x[0-9a-f]* (\(.*\))/\1/p')
	case $code in
	*SBGGR10*) mf=SBGGR10_1X10; pf=pBAA;;
	*SGBRG10*) mf=SGBRG10_1X10; pf=pGAA;;
	*SGRBG10*) mf=SGRBG10_1X10; pf=pgAA;;
	*SRGGB10*) mf=SRGGB10_1X10; pf=pRAA;;
	*) echo "$cam: code '$code'?"; return 1;;
	esac
	$M -r
	$M -l "\"$phy\":1->\"msm_csid0\":0[1],\"msm_csid0\":1->\"msm_vfe0_rdi0\":0[1]" || return 1
	for p in "$phy:0" "$phy:1" msm_csid0:0 msm_csid0:1 msm_vfe0_rdi0:0; do
		$M -V "\"${p%:*}\":${p#*:}[fmt:$mf/${w}x$h field:none]"
	done
	[ -n "$exp" ] && v4l2-ctl -d /dev/$sd -c exposure=$exp
	[ -n "$gain" ] && v4l2-ctl -d /dev/$sd -c analogue_gain=$gain
	dmesg -C
	out=/dev/shm/$cam-${exp:-def}-${gain:-def}.raw
	timeout -s INT ${CAPT:-15} v4l2-ctl -d /dev/video2 \
		--set-fmt-video=width=$w,height=$h,pixelformat=$pf \
		--stream-mmap --stream-skip=3 --stream-count=${CNT:-1} --stream-to=$out 2>&1 | tail -1
	echo "$cam $mf rc=$? bytes=$(stat -c %s $out 2>/dev/null) -> $out"
	dmesg | grep -vE "spmi|vfe irq|validating|trying" | grep -iE "csiphy|csid|WARNING|timeout|err" | tail -6
}

# S5KHM2 receive diagnosis: try every 3-of-4 lane placement on CSIPHY0 (and
# optionally a settle value), one short capture each, phy_status mid-stream.
hm2diag() {
	P=/sys/module/qcom_camss/parameters
	[ -n "${1:-}" ] && echo "$1" > $P/dphy_settle
	for a in 0 1 2 3; do for b in 0 1 2 3; do for c in 0 1 2 3; do
		[ $a = $b ] || [ $a = $c ] || [ $b = $c ] && continue
		echo "0:$a,$b,$c" > $P/lane_map
		CAPT=5 sh "$0" cap s5khm2 > /dev/shm/hm2-$a$b$c.log 2>&1 &
		sleep 3
		st=$(cat $P/phy_status)
		wait
		echo "lanes $a,$b,$c: $(grep -o 'bytes=[0-9]*' /dev/shm/hm2-$a$b$c.log) $st"
	done; done; done
	echo "" > $P/lane_map
	echo -1 > $P/dphy_settle
}

"$@"
