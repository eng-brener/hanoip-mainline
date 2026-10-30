#!/usr/bin/env python3
"""Drive the hanoip USB serial console: send a command, print the response.

Usage: serial-cmd.py "COMMAND" [SECONDS]
Opens once, sends the command with CR, reads until timeout or marker.
"""
import os
import select
import sys
import termios
import time

PORT = "/dev/cu.usbmodem211401"
cmd = sys.argv[1]
wait = float(sys.argv[2]) if len(sys.argv) > 2 else 6.0

fd = os.open(PORT, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
attrs = termios.tcgetattr(fd)
attrs[0] = 0
attrs[1] = 0
attrs[3] = 0
attrs[4] = attrs[5] = termios.B115200
termios.tcsetattr(fd, termios.TCSANOW, attrs)


def read(seconds):
    out = b""
    end = time.time() + seconds
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.3)
        if not r:
            continue
        try:
            data = os.read(fd, 65536)
        except OSError:
            break
        if not data:
            break
        out += data
    return out


read(0.5)
os.write(fd, b"\r")
time.sleep(1.0)
read(1.0)
os.write(fd, b"echo MARK_START\r")
read(1.0)
os.write(fd, cmd.encode() + b"\r")
data = read(wait)
os.close(fd)
text = data.decode(errors="replace")
text = "".join(ch for ch in text if ch == "\n" or ch == "\t" or 32 <= ord(ch) < 127)
print(text[-4000:])
