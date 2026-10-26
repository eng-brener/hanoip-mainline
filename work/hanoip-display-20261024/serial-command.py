#!/usr/bin/env python3
import argparse
import glob
import os
from pathlib import Path
import select
import time
import tty
import uuid

p = argparse.ArgumentParser()
p.add_argument('log')
p.add_argument('command')
p.add_argument('--seconds', type=float, default=40)
a = p.parse_args()
ports = glob.glob('/dev/cu.usbmodem*')
assert len(ports) == 1, ports
fd = os.open(ports[0], os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
data = bytearray()
marker = ('HANOIP_END_' + uuid.uuid4().hex[:12]).encode()
try:
    tty.setraw(fd)
    # Drain old console output before sending a short, single-line command.
    end = time.monotonic() + 2
    while time.monotonic() < end:
        if select.select([fd], [], [], .1)[0]:
            chunk = os.read(fd, 65536)
            if chunk:
                data.extend(chunk)
                Path(a.log + '.partial.raw').write_bytes(data)
    command = ('\n' + a.command + "; printf '\\n" + marker.decode() + "\\n'\n").encode()
    while command:
        if select.select([], [fd], [], 1)[1]:
            sent = os.write(fd, command[:128])
            command = command[sent:]
            time.sleep(.03)
    end = time.monotonic() + a.seconds
    while time.monotonic() < end:
        if select.select([fd], [], [], .1)[0]:
            chunk = os.read(fd, 65536)
            if chunk:
                data.extend(chunk)
                Path(a.log + '.partial.raw').write_bytes(data)
            if b'\n' + marker + b'\n' in data or b'\n' + marker + b'\r\n' in data:
                break
    else:
        raise TimeoutError('Serial command did not finish')
finally:
    os.close(fd)
    Path(a.log + '.raw').write_bytes(data)
    Path(a.log).write_text(data.decode(errors='replace'))
    print(data.decode(errors='replace'))
