#!/bin/sh
# hanoip-usbnet: USB NCM networking + SSH for Kali on the hanoip.
# Device gets 172.16.42.1, the host 172.16.42.2 via DHCP (no route/DNS).
# Requires CONFIG_USB_CONFIGFS_{NCM,ACM} in the kernel (we build them in).
set -eu

log() { printf 'hanoip-usbnet: %s\n' "$*" > /dev/kmsg 2>/dev/null || true; }

mountpoint -q /sys/kernel/config || mount -t configfs none /sys/kernel/config || true

# The initramfs gadget (hanoip-console) owns the UDC; unbind it first,
# otherwise this gadget cannot be bound and no usb0 appears.
for g in /sys/kernel/config/usb_gadget/*; do
    [ -e "$g/UDC" ] || continue
    [ "$g" = "/sys/kernel/config/usb_gadget/hanoip-net" ] && continue
    echo "" > "$g/UDC" 2>/dev/null || true
    log "unbound ${g##*/}"
done

G=/sys/kernel/config/usb_gadget/hanoip-net
if [ ! -d "$G" ]; then
    mkdir -p "$G/strings/0x409" "$G/configs/c.1/strings/0x409"
    echo 0x1d6b > "$G/idVendor"
    echo 0x0104 > "$G/idProduct"
    echo 0x0100 > "$G/bcdDevice"
    echo 0x0200 > "$G/bcdUSB"
    echo 0xEF > "$G/bDeviceClass"
    echo 0x02 > "$G/bDeviceSubClass"
    echo 0x01 > "$G/bDeviceProtocol"
    echo hanoip-kali > "$G/strings/0x409/serialnumber"
    echo Motorola > "$G/strings/0x409/manufacturer"
    echo "hanoip Kali (USB net + console)" > "$G/strings/0x409/product"
    echo "NCM network + ACM console" > "$G/configs/c.1/strings/0x409/configuration"
    echo 500 > "$G/configs/c.1/MaxPower"

    mkdir -p "$G/functions/ncm.usb0" "$G/functions/acm.usb0"
    echo 02:68:61:6e:6f:01 > "$G/functions/ncm.usb0/dev_addr"
    echo 02:68:61:6e:6f:02 > "$G/functions/ncm.usb0/host_addr"
    [ -e "$G/configs/c.1/ncm.usb0" ] || ln -s "$G/functions/ncm.usb0" "$G/configs/c.1/ncm.usb0"
    [ -e "$G/configs/c.1/acm.usb0" ] || ln -s "$G/functions/acm.usb0" "$G/configs/c.1/acm.usb0"
fi

i=0
while [ -z "$(ls /sys/class/udc 2>/dev/null)" ] && [ "$i" -lt 30 ]; do
    i=$((i+1)); sleep 1
done
for udc in /sys/class/udc/*; do
    [ -e "$udc" ] && { echo "${udc##*/}" > "$G/UDC" 2>/dev/null || true; break; }
done

IF=$(cat "$G/functions/ncm.usb0/ifname" 2>/dev/null || echo usb0)
case "$IF" in ''|*unnamed*) IF=usb0 ;; esac
i=0
while [ ! -e "/sys/class/net/$IF" ] && [ "$i" -lt 30 ]; do
    i=$((i+1)); sleep 1
done

ip addr add 172.16.42.1/24 dev "$IF" 2>/dev/null || true
ip link set "$IF" up 2>/dev/null || true

# Hand the host its address.
if command -v dnsmasq >/dev/null 2>&1; then
    pkill -f "dnsmasq.*$IF" 2>/dev/null || true
    dnsmasq --interface="$IF" --bind-interfaces --except-interface=lo \
            --dhcp-range=172.16.42.2,172.16.42.2,255.255.255.0,12h \
            --pid-file=/run/hanoip-dnsmasq.pid --port=0 || true
    log "dnsmasq on $IF"
else
    log "no dnsmasq; set 172.16.42.2/24 manually on the host"
fi

# Make sure sshd is running (enabled in the image).
systemctl start ssh.service 2>/dev/null || true
log "up: $IF 172.16.42.1/24"
