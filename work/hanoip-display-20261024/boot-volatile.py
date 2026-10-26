#!/usr/bin/env python3
import argparse
import glob
import json
import os
from pathlib import Path
import subprocess
import time
import tty

p = argparse.ArgumentParser()
p.add_argument('kernel')
p.add_argument('--reset', action='store_true')
p.add_argument('--uboot', default='work/hanoip-display-20261024/no-reset/u-boot-hanoip-display-noreset.img')
a = p.parse_args()
kernel = Path(a.kernel)
events = []
event_path = kernel.parent / 'volatile-boot-events.json'
if event_path.exists():
    event_path = kernel.parent / ('volatile-boot-events-' + str(time.time_ns()) + '.json')


def run(args):
    r = subprocess.run(args, capture_output=True, text=True, timeout=35)
    e = dict(command=args, exit=r.returncode, stdout=r.stdout, stderr=r.stderr)
    events.append(e)
    event_path.write_text(json.dumps(events, indent=2))
    print(e, flush=True)
    assert r.returncode == 0
    return r.stdout + r.stderr


def fastboot_devices():
    return subprocess.run(['fastboot', 'devices'], capture_output=True, text=True, timeout=3).stdout.splitlines()


if a.reset:
    ports = glob.glob('/dev/cu.usbmodem*')
    assert len(ports) == 1
    fd = os.open(ports[0], os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
    tty.setraw(fd)
    command = b'\n/sbin/reboot\n'
    while command:
        try:
            command = command[os.write(fd, command):]
        except BlockingIOError:
            time.sleep(.05)
    time.sleep(1)
    os.close(fd)

end = time.monotonic() + 65
while time.monotonic() < end:
    devices = fastboot_devices()
    if len(devices) == 1 and devices[0].startswith('ZF523QJBSG'):
        break
    adb = subprocess.run(['adb', 'devices'], capture_output=True, text=True, timeout=3).stdout
    if 'ZF523QJBSG\tdevice' in adb:
        run(['adb', '-s', 'ZF523QJBSG', 'reboot', 'bootloader'])
    time.sleep(.5)
else:
    raise RuntimeError('Motorola bootloader unavailable')

run(['fastboot', '-s', 'ZF523QJBSG', 'boot', a.uboot])
end = time.monotonic() + 25
while time.monotonic() < end:
    devices = fastboot_devices()
    if len(devices) == 1 and not devices[0].startswith('ZF523QJBSG'):
        break
    time.sleep(.5)
else:
    raise RuntimeError('Volatile U-Boot unavailable')
assert 'motorola-hanoip' in run(['fastboot', 'getvar', 'product'])
run(['fastboot', 'boot', str(kernel)])
end = time.monotonic() + 40
while time.monotonic() < end:
    ports = glob.glob('/dev/cu.usbmodem*')
    if ports:
        print('USB serial:', ports, flush=True)
        break
    time.sleep(.5)
else:
    print('No USB serial yet', flush=True)
