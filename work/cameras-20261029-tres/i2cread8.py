#!/usr/bin/env python3
"""Read-only 8-bit-register I2C read. Usage: i2cread8.py BUS ADDR REG N"""
import ctypes, fcntl, os, sys
I2C_RDWR, I2C_M_RD = 0x0707, 0x0001
class Msg(ctypes.Structure):
    _fields_ = [("addr", ctypes.c_uint16), ("flags", ctypes.c_uint16),
                ("len", ctypes.c_uint16), ("buf", ctypes.POINTER(ctypes.c_uint8))]
class Data(ctypes.Structure):
    _fields_ = [("msgs", ctypes.POINTER(Msg)), ("nmsgs", ctypes.c_uint32)]
bus, addr, reg, n = int(sys.argv[1]), int(sys.argv[2], 0), int(sys.argv[3], 0), int(sys.argv[4])
w = (ctypes.c_uint8 * 1)(reg); r = (ctypes.c_uint8 * n)()
fd = os.open(f"/dev/i2c-{bus}", os.O_RDWR)
fcntl.ioctl(fd, I2C_RDWR, Data((Msg * 2)(Msg(addr, 0, 1, w), Msg(addr, I2C_M_RD, n, r)), 2))
os.close(fd); print(" ".join(f"{b:02x}" for b in r))
