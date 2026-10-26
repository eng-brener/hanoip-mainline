#!/bin/sh
# Build the pmOS v26.06 (Alpine 3.24) rootfs for the super-tail region and
# pack it as an ext4 image. Runs inside `docker run --platform linux/arm64
# alpine:3.24` with this directory mounted at /work. Host-only: nothing here
# touches the phone.
#   build-rootfs.sh [extra packages...]
set -eu
ROOT=/build/rootfs
IMG=${IMG:-/work/pmos-super-rootfs.img}
SIZE_MIB=5120
PMOS=https://mirror.postmarketos.org/postmarketos/v26.06
ALP=https://dl-cdn.alpinelinux.org/alpine/v3.24

apk add --no-cache e2fsprogs >/dev/null
rm -rf "$ROOT"; mkdir -p "$ROOT/etc/apk/keys"
cp /etc/apk/keys/* "$ROOT/etc/apk/keys/"
cp /work/build.postmarketos.org.rsa.pub "$ROOT/etc/apk/keys/"
printf '%s\n' "$PMOS" "$ALP/main" "$ALP/community" > "$ROOT/etc/apk/repositories"

apk --root "$ROOT" --initdb --update-cache add \
    alpine-base postmarketos-base openrc eudev elogind polkit-elogind \
    bash nano htop iproute2 iw wpa_supplicant openssh-server \
    e2fsprogs util-linux usbutils evtest fastfetch \
    mesa-dri-gallium mesa-egl mesa-gles kmscube \
    postmarketos-ui-plasma-mobile qmlkonsole discover discover-backend-apk \
    alpine-appstream-downloader \
    dolphin ark kalk kclock kweather koko elisa haruna okular calindori \
    plasma-phonebook krecorder spectacle \
    firefox mobile-config-firefox \
    postmarketos-base-ui-audio-backend-pipewire alsa-utils \
    mesa-vulkan-freedreno vulkan-tools \
    v4l-utils ffmpeg gstreamer-tools gst-plugins-base gst-plugins-good \
    gst-plugins-bad i2c-tools strace \
    "$@" > /work/apk-install.log 2>&1 || { tail -30 /work/apk-install.log; exit 1; }

# Board-specific configuration (no device identifiers, no passwords).
cp -a /work/overlay/. "$ROOT/"
chmod 700 "$ROOT/root" "$ROOT/root/.ssh"
chmod 600 "$ROOT/root/.ssh/authorized_keys"
chmod 755 "$ROOT/etc/init.d/hanoip-usbnet" "$ROOT/etc/init.d/hanoip-touch" \
    "$ROOT/etc/init.d/hanoip-firmware" "$ROOT/etc/init.d/hanoip-ro-handoff" \
    "$ROOT/etc/init.d/hanoip-perf-tune" \
    "$ROOT/etc/init.d/hanoip-brightness" \
    "$ROOT/usr/libexec/hanoip-speaker-route" \
    "$ROOT/etc/local.d/"*.start
ln -sf /etc/init.d/hanoip-touch "$ROOT/etc/runlevels/boot/hanoip-touch"
ln -sf /etc/init.d/hanoip-firmware "$ROOT/etc/runlevels/boot/hanoip-firmware"
# udev rule 60-hanoip-blockdev-ro takes over the initramfs RO poll loop.
ln -sf /etc/init.d/hanoip-ro-handoff "$ROOT/etc/runlevels/sysinit/hanoip-ro-handoff"
ln -sf /etc/init.d/hanoip-perf-tune "$ROOT/etc/runlevels/boot/hanoip-perf-tune"
ln -sf /etc/init.d/hanoip-brightness "$ROOT/etc/runlevels/boot/hanoip-brightness"
# NetworkManager (from the Plasma UI) owns wlan0 and D-Bus-activates
# wpa_supplicant; no ifupdown/wpa_supplicant OpenRC services for it.
echo hanoip > "$ROOT/etc/hostname"
sed -i 's|^root:[^:]*:|root:*:|' "$ROOT/etc/shadow"

# Kernel modules, one tree per kernel (depmod output included):
#   7.1.0-sm7150  kernel #10 (GOLD v4): in-tree build + 43 validated in updates/
#   7.3.0-sm7150  kernel 7.3 (work/kernel-7.3): in-tree build + extra/mmi
mkdir -p "$ROOT/lib/modules"
for t in /work/modules-7.1.0-sm7150.tar.gz /work/modules-7.3.0-sm7150.tar.gz; do
    tar -xzf "$t" -C "$ROOT/lib/modules"
done

# Plasma Mobile session for tinydm autologin (AUTOLOGIN_UID=10000). The
# account is created locked: set the PIN on the phone with `passwd user`.
chroot "$ROOT" adduser -D -u 10000 -s /bin/bash -g "pmOS user" user
for g in audio input netdev plugdev video wheel feedbackd; do
    chroot "$ROOT" addgroup user $g
done
chroot "$ROOT" tinydm-set-session -f -s /usr/share/wayland-sessions/plasma-mobile.desktop
# PipeWire as OpenRC user services, up at login before Plasma: started from
# the XDG autostart it races plasma-pa, which then never reaches the server
# (volume keys dead). pipewire-launcher exits when the service is running.
mkdir -p "$ROOT/home/user/.config/rc/runlevels/default"
for s in pipewire pipewire-pulse wireplumber; do
    ln -sf /etc/user/init.d/$s "$ROOT/home/user/.config/rc/runlevels/default/$s"
done
# Panel idle-off would cost an IRAM reload; keep it off by default.
mkdir -p "$ROOT/home/user/.config"
for p in AC Battery LowBattery; do
    printf '[%s][Display]\nDimDisplayWhenIdle=false\nTurnOffDisplayWhenIdle=false\n\n[%s][SuspendAndShutdown]\nAutoSuspendAction=0\n\n' $p $p
done > "$ROOT/home/user/.config/powerdevilrc"
printf '[Daemon]\nAutolock=false\n' > "$ROOT/home/user/.config/kscreenlockerrc"
chroot "$ROOT" chown -R user:user /home/user/.config

for svc in dmesg mdev hwdrivers; do
    rm -f "$ROOT/etc/runlevels/sysinit/$svc"
done
for svc in devfs udev udev-trigger udev-settle; do
    ln -sf /etc/init.d/$svc "$ROOT/etc/runlevels/sysinit/$svc"
done
# No swap file on UFS and no RTC (PMIC) writes at shutdown.
rm -f "$ROOT/etc/runlevels/default/swapfile" "$ROOT/etc/runlevels/boot/hwclock"
ln -sf /etc/init.d/swclock "$ROOT/etc/runlevels/boot/swclock"
for svc in sshd hanoip-usbnet local; do
    ln -sf /etc/init.d/$svc "$ROOT/etc/runlevels/default/$svc"
done
# No plymouth on this image and no nftables in kernel #10.
rm -f "$ROOT/etc/runlevels/default/kill-plymouth" "$ROOT/etc/runlevels/default/nftables"
# NetworkManager D-Bus-activates wpa_supplicant; a second owner of wlan0 breaks it.
rm -f "$ROOT/etc/runlevels/default/wpa_supplicant"

apk --root "$ROOT" info -v | sort > /work/packages.txt
du -sh "$ROOT" | tee /work/rootfs-size.txt

rm -f "$IMG"
truncate -s ${SIZE_MIB}M "$IMG"
mkfs.ext4 -q -F -L hanoip_pmos -U 7a2c1c55-0b1e-4f4b-9c1a-68616e6f6970 \
    -E root_owner=0:0 -d "$ROOT" "$IMG"
e2fsck -fn "$IMG" | tail -2
ls -l "$IMG"
