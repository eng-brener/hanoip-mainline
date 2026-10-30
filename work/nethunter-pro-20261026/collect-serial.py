#!/usr/bin/env python3
"""Collect USB serial output, reopening the port when the device re-enumerates.

Usage: collect-serial.py OUT.txt SECONDS [DEV_GLOB]
Pure termios/select, no pyserial (not installed on this Mac).
"""
import glob
import os
import select
import sys
import time
import termios

out_path = sys.argv[1]
duration = float(sys.argv[2])
pattern = sys.argv[3] if len(sys.argv) > 3 else "/dev/cu.usbmodem*"

end = time.time() + duration
fd = None
log = open(out_path, "wb")
last_state = None

def close(fd):
    for fn in (lambda: termios.tcflush(fd, termios.TCIOFLUSH),
               lambda: os.close(fd)):
        try:
            fn()
        except Exception:
            pass

while time.time() < end:
    if fd is None:
        ports = sorted(glob.glob(pattern))
        if ports:
            try:
                fd = os.open(ports[0], os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
                attrs = termios.tcgetattr(fd)
                attrs[4] = attrs[5] = termios.B115200
                attrs[2] |= termios.CLOCAL | termios.CREAD
                termios.tcsetattr(fd, termios.TCSANOW, attrs)
                log.write(f"\n=== port open {ports[0]} ===\n".encode())
                log.flush()
            except OSError:
                fd = None
    if fd is None:
        time.sleep(0.5)
        continue
    try:
        r, _, _ = select.select([fd], [], [], 1.0)
        if r:
            data = os.read(fd, 65536)
            if data:
                log.write(data)
                log.flush()
    except OSError:
        log.write(f"\n=== port lost ===\n".encode())
        log.flush()
        close(fd)
        fd = None

if fd is not None:
    close(fd)
log.close()
print(f"collected into {out_path}")
