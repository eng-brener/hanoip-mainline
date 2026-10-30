#!/bin/sh
# Run on the phone after loading the one-shot fault sensor and CAMSS variant.
# All output files go to tmpfs. Requires the dual-blacklist boot.
set -eu
export LC_ALL=C
BASE=/dev/shm/hanoip-camera-run3
mkdir "$BASE"
media-ctl -d /dev/media0 -l '"msm_csiphy3":1->"msm_csid0":0[1],"msm_csid0":1->"msm_vfe0_rdi0":0[1]'
for p in msm_csiphy3:0 msm_csiphy3:1 msm_csid0:0 msm_csid0:1 msm_vfe0_rdi0:0; do
    media-ctl -d /dev/media0 -V "\"${p%:*}\":${p##*:}[fmt:SBGGR10_1X10/1600x1200 field:none]"
done
v4l2-ctl -d /dev/video2 --set-fmt-video=width=1600,height=1200,pixelformat=pBAA

echo 'Test 1: expected injected error before sensor power-on'
timeout 8 v4l2-ctl -d /dev/video2 --stream-mmap --stream-count=2 \
    --stream-to="$BASE/injected.raw" >"$BASE/injected.log" 2>&1 || true
if ! grep -q 'VIDIOC_STREAMON.*Input/output error' "$BASE/injected.log"; then
    echo 'Unexpected injection result; stopping.'
    cat "$BASE/injected.log"
    exit 1
fi
if [ "$(cat /proc/sys/kernel/tainted)" != 4096 ]; then
    echo 'Unexpected kernel taint after injection; stopping.'
    exit 1
fi

echo 'Test 2: capture after injected error'
timeout 8 v4l2-ctl -d /dev/video2 --stream-mmap --stream-count=4 \
    --stream-to="$BASE/recovery.raw" >"$BASE/recovery.log" 2>&1 || true
if [ "$(wc -c < "$BASE/recovery.raw")" -ne 9600000 ] ||
   [ "$(cat /proc/sys/kernel/tainted)" != 4096 ]; then
    echo 'Recovery failed or kernel warning; stopping.'
    cat "$BASE/recovery.log"
    exit 1
fi

echo 'Test 3: repeated start/stop with pauses'
for n in 1 2 3; do
    sleep 2
    timeout 8 v4l2-ctl -d /dev/video2 --stream-mmap --stream-count=4 \
        --stream-to="$BASE/repeat-$n.raw" >"$BASE/repeat-$n.log" 2>&1 || true
    if [ "$(wc -c < "$BASE/repeat-$n.raw")" -ne 9600000 ] ||
       [ "$(cat /proc/sys/kernel/tainted)" != 4096 ]; then
        echo "Cycle $n failed or kernel warning; stopping."
        cat "$BASE/repeat-$n.log"
        exit 1
    fi
    echo "Cycle $n: four frames"
done
echo 'Test 4: controls during one 90-frame stream'
timeout 10 v4l2-ctl -d /dev/video2 --stream-mmap --stream-count=90 \
    --stream-to=/dev/null >"$BASE/controls.log" 2>&1 &
pid=$!
sleep 1
if ! v4l2-ctl -d /dev/v4l-subdev16 --set-ctrl=analogue_gain=64,exposure=1000; then
    kill "$pid" 2>/dev/null || true
    wait "$pid" 2>/dev/null || true
    echo 'Control update failed; stopping.'
    exit 1
fi
if ! wait "$pid"; then
    echo 'Continuous stream failed; stopping.'
    cat "$BASE/controls.log"
    exit 1
fi
frames=$(tr -cd '<' < "$BASE/controls.log" | wc -c)
if [ "$frames" -ne 90 ] || [ "$(cat /proc/sys/kernel/tainted)" != 4096 ]; then
    echo "Continuous stream incomplete ($frames frames) or kernel warning."
    exit 1
fi
echo 'Continuous controls: 90 frames; control ioctl accepted.'
echo 'All staged tests passed.'
