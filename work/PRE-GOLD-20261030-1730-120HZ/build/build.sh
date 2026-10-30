#!/bin/sh
# Build msm.ko with the local DSI guards from the tested listener7 tree.
# Writes kernel-test/msm-dsifix.ko.zst. Nothing touches the phone.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
v7="$here/../../kernel-7.3/v7"
docker run --rm -v "$v7":/v7:ro -v "$here":/out \
	-v hanoip-kernel73-v3-src:/src hanoip-kernel73-v3 \
	bash /out/build-msm-inside.sh
