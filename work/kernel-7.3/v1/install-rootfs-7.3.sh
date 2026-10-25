# Run on the phone (pmOS, any kernel): install the 7.3 modules tree next to
# the 7.1 one in the pmOS rootfs (super tail) and switch the touch service
# to modprobe. Nothing outside the pmOS rootfs is written.
#   cat modules-7.3.0-sm7150.tar.gz | ssh root@172.16.42.1 'sh /tmp/install-rootfs-7.3.sh'
set -e
[ "$(sed -n 's/.*\/dev\/loop7 \/ ext4.*/ok/p' /proc/mounts)" = ok ] || { echo "root is not the pmOS loop7"; exit 1; }
tar -xzf - -C /lib/modules
depmod 7.3.0-sm7150
cat /tmp/hanoip-touch > /etc/init.d/hanoip-touch
chmod 755 /etc/init.d/hanoip-touch
sync
echo "modules: $(find /lib/modules/7.3.0-sm7150 -name '*.ko' | wc -l)"
modinfo -k 7.3.0-sm7150 -n ilitek_hanoip_spi msm hanoip_mmi_unit_info
