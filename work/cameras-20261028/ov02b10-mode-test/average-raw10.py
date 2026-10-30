#!/usr/bin/env python3
"""Average consecutive static-scene V4L2 packed RAW10 frames into 16-bit LE.

Usage: python3 average-raw10.py input.raw output.raw [frames]
Only appropriate for a stationary camera and scene. Pixel values are not
color-calibrated. Y10P is monochrome; pBAA would require Bayer interpretation.
"""
import array
import pathlib
import sys

WIDTH, HEIGHT = 1600, 1200
FRAME_BYTES = WIDTH * HEIGHT * 5 // 4
BLACK, WHITE = 64, 1023  # Sensor metadata, not a per-channel calibration.

if len(sys.argv) not in (3, 4):
    raise SystemExit(__doc__)
source, destination = map(pathlib.Path, sys.argv[1:3])
count = int(sys.argv[3]) if len(sys.argv) == 4 else 4
if count < 1 or destination.exists():
    raise SystemExit("invalid frame count or output already exists")
data = source.read_bytes()
if len(data) < count * FRAME_BYTES:
    raise SystemExit("input has fewer complete frames than requested")

pixels = array.array("H", [0]) * (WIDTH * HEIGHT)
for i in range(0, FRAME_BYTES, 5):
    base = i // 5 * 4
    sums = [0, 0, 0, 0]
    for frame in range(count):
        off = frame * FRAME_BYTES + i
        low = data[off + 4]
        for k in range(4):
            sums[k] += (data[off + k] << 2) | ((low >> (2 * k)) & 3)
    for k in range(4):
        value = max(0, sums[k] // count - BLACK)
        pixels[base + k] = min(65535, value * 65535 // (WHITE - BLACK))
if sys.byteorder != "little":
    pixels.byteswap()
with destination.open("xb") as out:
    pixels.tofile(out)
print(f"{count} frames averaged -> {destination} (16-bit LE, uncalibrated)")
