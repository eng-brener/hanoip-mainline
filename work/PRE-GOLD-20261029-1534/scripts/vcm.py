#!/usr/bin/env python3
"""Drive a hanoip VCM with its vendor init list. Only VCM registers are written.
  wide: slot 3 (S5K4H7), cci0 m1 = i2c-13, 0x0c; qtech_mot_hanoip_s5k4h7 list 10
  main: slot 0 (S5KHM2), cci0 m0 = i2c-12, 0x0c; ofilm_mot_hanoip_s5khm2 list 16
Usage: vcm.py wide|main init | vcm.py wide|main pos N"""
import ctypes, fcntl, os, sys, time
I2C_RDWR = 0x0707
class Msg(ctypes.Structure):
    _fields_ = [("addr", ctypes.c_uint16), ("flags", ctypes.c_uint16),
                ("len", ctypes.c_uint16), ("buf", ctypes.POINTER(ctypes.c_uint8))]
class Data(ctypes.Structure):
    _fields_ = [("msgs", ctypes.POINTER(Msg)), ("nmsgs", ctypes.c_uint32)]
PROFILES = {
    "wide": (13, ((0xed, 0xab, 0), (0x02, 0x01, 0), (0x02, 0x00, 1000),
                  (0x06, 0x84, 0), (0x07, 0x01, 0), (0x08, 0x78, 0))),
    "main": (12, ((0x02, 0x01, 0), (0x02, 0x00, 1000), (0x02, 0x02, 0),
                  (0x06, 0x40, 0), (0x07, 0x0b, 0), (0x10, 0x01, 0))),
}
ADDR = 0x0c
BUS, INIT = PROFILES[sys.argv.pop(1)]
def w(*b):
    buf = (ctypes.c_uint8 * len(b))(*b)
    fd = os.open(f"/dev/i2c-{BUS}", os.O_RDWR)
    try:
        fcntl.ioctl(fd, I2C_RDWR, Data((Msg * 1)(Msg(ADDR, 0, len(b), buf)), 1))
    finally:
        os.close(fd)
if sys.argv[1] == "init":
    for reg, val, dl in INIT:
        w(reg, val)
        time.sleep(dl / 1e6)
    print("init ok")
else:
    n = max(0, min(1023, int(sys.argv[2])))
    w(0x03, n >> 8, n & 0xff)
    print("pos", n)
