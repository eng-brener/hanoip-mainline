#!/bin/bash
# Temporary preview from an already configured Y10P 1600x1200 media graph.
# Run in the graphical user's Wayland environment; all cache stays in RAM.
set -euo pipefail
if [[ -z ${XDG_RUNTIME_DIR:-} || -z ${WAYLAND_DISPLAY:-} ]]; then
    echo 'Run inside the logged-in Wayland session (XDG_RUNTIME_DIR and WAYLAND_DISPLAY required).' >&2
    exit 1
fi
converter=${CONVERTER:-/dev/shm/y10p-to-gray8}
video=${VIDEO_DEVICE:-/dev/video2}
frames=${FRAMES:-300}
export GST_REGISTRY="/dev/shm/hanoip-gst-$(id -u).bin"
v4l2-ctl -d "$video" --stream-mmap --stream-count="$frames" --stream-to=- |
    "$converter" |
    gst-launch-1.0 -q fdsrc blocksize=1920000 ! \
        rawvideoparse format=gray8 width=1600 height=1200 framerate=30/1 ! \
        videoconvert ! waylandsink sync=false
