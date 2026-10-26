## REF: https://hub.docker.com/_/debian
FROM docker.io/debian:stable-slim

RUN /bin/bash -o pipefail -c '\
  ## Update package index
    apt-get update && \
  ## Update OS
    #apt-get -y dist-upgrade && \
  #
  ## Install OS packages
  ##   REF: ./README.md
  #
    env DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends \
      # > /build/build.sh: debos: command not found
        debos \
      # > exec: "mkfs.ext4": executable file not found in $PATH
        e2fsprogs \
      # > open /lib/modules: no such file or directory
        linux-image-amd64 \
      # > Packing | /bin/sh: 1: xz: not found
        xz-utils \
      # > Action `recipe` failed at stage Run, error: exec: "parted": executable file not found in $PATH
        parted \
      # > Action `recipe` failed at stage Run, error: exec: "mkfs.vfat": executable file not found in $PATH
        dosfstools \
      # > Action `recipe` failed at stage Run, error: exec: "sfdisk": executable file not found in $PATH
        fdisk \
      ## Qualcomm-based devices:
      # > /build/build.sh: tomlq: command not found
        yq \
      ## LUKS disk encryption:
      # > setup-luks | /build/scripts/setup-luks.sh: line 38: cryptsetup: command not found
        cryptsetup \
      ## f2fs file system:
      # > Action `recipe` failed at stage Run, error: exec: "mkfs.f2fs": executable file not found in $PATH
        f2fs-tools \
      ## btrfs file system:
      # > Action `recipe` failed at stage Run, error: exec: "mkfs.btrfs": executable file not found in $PATH
        btrfs-progs \
      ## If using a HTTPS mirror
      # > ERROR: The certificate of 'http.kali.org' is not trusted.
      # > ERROR: The certificate of 'http.kali.org' doesn't have a known issuer.
        ca-certificates \
      && \
  #
  ## Clean up
  #
    apt-get --quiet --yes --purge autoremove && \
    apt-get --quiet --yes clean && \
    rm -rfv \
      /usr/share/doc \
      /usr/share/man \
      /var/lib/apt/lists/* \
      /tmp/* \
      /var/tmp/*'
