import fcntl, glob, os, struct, sys, time
# Play an FF_RUMBLE effect on the pm8xxx vibrator: vib.py MAGNITUDE MS COUNT
mag, ms, count = int(sys.argv[1], 0), int(sys.argv[2]), int(sys.argv[3])
dev = None
for p in glob.glob("/sys/class/input/event*/device/name"):
    if open(p).read().strip() == "pm8xxx_vib_ffmemless":
        dev = "/dev/input/" + p.split("/")[4]
fd = os.open(dev, os.O_RDWR)
FF_RUMBLE, EV_FF = 0x50, 0x15
# struct ff_effect: type u16, id s16, direction u16, trigger{u16,u16}, replay{u16 length,u16 delay}, pad, union
eff = struct.pack("<HhHHHHH2xHH", FF_RUMBLE, -1, 0, 0, 0, ms, 0, mag, 0) + bytes(28)  # union is 32 bytes on arm64
EVIOCSFF = 0x40000000 | (len(eff) << 16) | (ord("E") << 8) | 0x80
buf = bytearray(eff)
fcntl.ioctl(fd, EVIOCSFF, buf)
eid = struct.unpack_from("<h", buf, 2)[0]
for _ in range(count):
    os.write(fd, struct.pack("<qqHHi", 0, 0, EV_FF, eid, 1))
    time.sleep(ms / 1000 + 0.4)
print(dev, "effect", eid, "played", count)
