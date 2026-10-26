#!/usr/bin/env python3
"""Run one command on the hanoip USB serial shell and capture output until a marker."""
import os, sys, termios, time, select, secrets

port, outpath, timeout = sys.argv[1], sys.argv[2], float(sys.argv[3])
cmd = sys.stdin.read().strip()
marker = "HANOIP_END_" + secrets.token_hex(6)
fd = os.open(port, os.O_RDWR | os.O_NOCTTY | os.O_NONBLOCK)
a = termios.tcgetattr(fd)
a[0] = 0; a[1] = 0; a[2] = termios.CS8 | termios.CREAD | termios.CLOCAL; a[3] = 0
a[4] = a[5] = termios.B115200
termios.tcsetattr(fd, termios.TCSANOW, a)
buf = bytearray()
def drain(t):
    end = time.time() + t
    while time.time() < end:
        r, _, _ = select.select([fd], [], [], 0.2)
        if r:
            try: buf.extend(os.read(fd, 65536))
            except BlockingIOError: pass
drain(0.5)
os.write(fd, b"\n")
drain(0.5)
full = cmd + "; printf '\\n%s\\n' " + marker + "\n"
for i in range(0, len(full), 64):
    os.write(fd, full[i:i+64].encode()); time.sleep(0.02)
end = time.time() + timeout
tail = ("\n" + marker).encode()
while time.time() < end and tail not in buf:
    drain(0.5)
open(outpath, "wb").write(bytes(buf))
ok = tail in buf
print("complete" if ok else "TIMEOUT", len(buf), "bytes")
sys.exit(0 if ok else 2)
