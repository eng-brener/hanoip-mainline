# Build environment for the hanoip 7.3 v3 kernel (see build.sh).
# Same toolchain as the tested build: Ubuntu 24.04, aarch64-linux-gnu-gcc 13.3.
FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu gcc make bc bison \
        flex libssl-dev libelf-dev cpio kmod python3 git ca-certificates \
        curl xz-utils rsync zstd \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
ENV KBUILD_BUILD_USER=Const KBUILD_BUILD_HOST=Coccinelle
