#!/usr/bin/env python3
"""Pure 1-byte I2C read (no write phase) to test whether ADDR acks.
Usage: i2cprobe.py BUS ADDR..."""
import ctypes, fcntl, os, sys

I2C_RDWR, I2C_M_RD = 0x0707, 0x0001


class Msg(ctypes.Structure):
    _fields_ = [("addr", ctypes.c_uint16), ("flags", ctypes.c_uint16),
                ("len", ctypes.c_uint16), ("buf", ctypes.POINTER(ctypes.c_uint8))]


class Data(ctypes.Structure):
    _fields_ = [("msgs", ctypes.POINTER(Msg)), ("nmsgs", ctypes.c_uint32)]


bus = int(sys.argv[1])
fd = os.open(f"/dev/i2c-{bus}", os.O_RDWR)
for a in sys.argv[2:]:
    addr = int(a, 0)
    r = (ctypes.c_uint8 * 1)()
    msgs = (Msg * 1)(Msg(addr, I2C_M_RD, 1, r))
    try:
        fcntl.ioctl(fd, I2C_RDWR, Data(msgs, 1))
        print(f"0x{addr:02x}: ACK, byte 0x{r[0]:02x}")
    except OSError as e:
        print(f"0x{addr:02x}: sem resposta ({e.strerror})")
os.close(fd)
