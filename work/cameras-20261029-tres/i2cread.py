#!/usr/bin/env python3
"""Read-only I2C register dump via I2C_RDWR (works while a driver owns the
client). Usage: i2cread.py BUS ADDR REG16 [NBYTES]  (no writes, ever)."""
import ctypes, fcntl, os, sys

I2C_RDWR, I2C_M_RD = 0x0707, 0x0001


class Msg(ctypes.Structure):
    _fields_ = [("addr", ctypes.c_uint16), ("flags", ctypes.c_uint16),
                ("len", ctypes.c_uint16), ("buf", ctypes.POINTER(ctypes.c_uint8))]


class Data(ctypes.Structure):
    _fields_ = [("msgs", ctypes.POINTER(Msg)), ("nmsgs", ctypes.c_uint32)]


bus, addr, reg = int(sys.argv[1]), int(sys.argv[2], 0), int(sys.argv[3], 0)
n = int(sys.argv[4]) if len(sys.argv) > 4 else 1
w = (ctypes.c_uint8 * 2)(reg >> 8, reg & 0xff)
r = (ctypes.c_uint8 * n)()
msgs = (Msg * 2)(Msg(addr, 0, 2, w), Msg(addr, I2C_M_RD, n, r))
fd = os.open(f"/dev/i2c-{bus}", os.O_RDWR)
fcntl.ioctl(fd, I2C_RDWR, Data(msgs, 2))
os.close(fd)
print(" ".join(f"{b:02x}" for b in r))
