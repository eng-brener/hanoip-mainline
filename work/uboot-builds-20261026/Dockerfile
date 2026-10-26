# Build environment for the hanoip U-Boot images (see build.sh).
# Same toolchain as the tested builds: Ubuntu 24.04, aarch64-linux-gnu-gcc 13.3.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu gcc make bc bison \
        flex libssl-dev libgnutls28-dev uuid-dev swig python3 python3-dev \
        python3-setuptools python3-pyelftools python3-libfdt \
        device-tree-compiler xxd pkg-config \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
