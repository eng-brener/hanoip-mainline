import os, select, socket, struct, sys, time
# Kernel NFC (generic netlink "nfc"): power up nfc0, poll, report targets.
#   nfcpoll.py SECONDS
SOL_NETLINK, NETLINK_ADD_MEMBERSHIP = 270, 1
CMD_DEV_UP, CMD_DEV_DOWN, CMD_START_POLL, CMD_STOP_POLL, CMD_GET_TARGET = 2, 3, 6, 7, 8
EV_TARGETS_FOUND, EV_TARGET_LOST = 9, 12
A_DEV, A_PROTOCOLS, A_TGT_IDX, A_SENS_RES, A_SEL_RES, A_NFCID1 = 1, 3, 4, 5, 6, 7
PROTO = {1: "Jewel", 2: "MIFARE", 3: "FeliCa", 4: "ISO14443-A", 5: "NFC-DEP", 6: "ISO14443-B", 7: "ISO15693"}
s = socket.socket(socket.AF_NETLINK, socket.SOCK_RAW, 16)
s.bind((0, 0))
seq = 0
def attr(t, d):
    a = struct.pack("<HH", 4 + len(d), t) + d
    return a + bytes((4 - len(a) % 4) % 4)
def attrs(buf, off):
    out = {}
    while off + 4 <= len(buf):
        l, t = struct.unpack_from("<HH", buf, off)
        if l < 4: break
        out.setdefault(t & 0x3fff, buf[off + 4:off + l])
        off += (l + 3) & ~3
    return out
def req(fam, cmd, payload, flags=5):
    global seq
    seq += 1
    body = struct.pack("<BBH", cmd, 1, 0) + payload
    s.send(struct.pack("<IHHII", 16 + len(body), fam, flags, seq, 0) + body)
    msgs = []
    while True:
        d = s.recv(65536); off = 0
        while off < len(d):
            ln, t, fl, sq, _ = struct.unpack_from("<IHHII", d, off)
            if sq == seq:
                if t == 2:
                    e = -struct.unpack_from("<i", d, off + 16)[0]
                    return e, msgs
                if t == 3:
                    return 0, msgs
                msgs.append(d[off:off + ln])
            off += (ln + 3) & ~3
_, m = req(0x10, 3, attr(2, b"nfc\0"))
a = attrs(m[0], 20)
fam = struct.unpack("<H", a[1])[0]
for g in attrs(a[7], 0).values():
    ga = attrs(g, 0)
    if ga[1].rstrip(b"\0") == b"events":
        s.setsockopt(SOL_NETLINK, NETLINK_ADD_MEMBERSHIP, struct.unpack("<I", ga[2])[0])
dev = attr(A_DEV, struct.pack("<I", 0))
e, _ = req(fam, CMD_DEV_UP, dev); print("dev_up:", os.strerror(e) if e else "ok")
mask = sum(1 << p for p in (1, 2, 3, 4, 6, 7))
e, _ = req(fam, CMD_START_POLL, dev + attr(A_PROTOCOLS, struct.pack("<I", mask)))
print("start_poll:", os.strerror(e) if e else "ok — encoste o cartão")
end = time.time() + float(sys.argv[1]); found = 0
while time.time() < end and not found:
    r, _, _ = select.select([s], [], [], 0.5)
    if not r: continue
    d = s.recv(65536)
    if d[16] == EV_TARGETS_FOUND:
        print("evento: alvo encontrado")
        e, msgs = req(fam, CMD_GET_TARGET, dev, flags=0x301)
        for msg in msgs:
            t = attrs(msg, 20)
            pr = struct.unpack("<I", t[A_PROTOCOLS])[0] if A_PROTOCOLS in t else 0
            names = [n for b, n in PROTO.items() if pr & (1 << b)]
            uid = t.get(A_NFCID1, b"")
            print("  protocolos:", ", ".join(names) or hex(pr),
                  "| SENS_RES", t[A_SENS_RES].hex() if A_SENS_RES in t else "-",
                  "| SEL_RES", t[A_SEL_RES].hex() if A_SEL_RES in t else "-",
                  "| ID com", len(uid), "bytes (não mostrado)")
        found = 1
if not found: print("nenhum cartão detectado em", sys.argv[1], "s")
req(fam, CMD_STOP_POLL, dev); e, _ = req(fam, CMD_DEV_DOWN, dev); print("dev_down:", "ok" if not e else os.strerror(e))
