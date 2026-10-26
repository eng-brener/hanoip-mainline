#!/usr/bin/env python3
"""Extract known SSC data tables from this phone's saved ADSP firmware.

Reads local files only. Fixed locations describe this captured firmware;
structural checks fail instead of silently accepting a different layout.
No firmware code is executed, and no phone connection is opened.
"""

import hashlib
import json
from pathlib import Path
import struct


ROOT = Path(__file__).resolve().parent
FW = ROOT / "firmware"
mdt = (FW / "adsp.mdt").read_bytes()
assert mdt[:6] == b"\x7fELF\x01\x01"
assert struct.unpack_from("<H", mdt, 18)[0] == 164  # Hexagon
phoff = struct.unpack_from("<I", mdt, 28)[0]
phsize, phnum = struct.unpack_from("<HH", mdt, 42)
segments = []
for index in range(phnum):
    header = struct.unpack_from("<8I", mdt, phoff + index * phsize)
    path = FW / f"adsp.b{index:02d}"
    if header[0] == 1 and path.exists():
        data = path.read_bytes()
        assert len(data) == header[4]
        segments.append((path.name, header[2], data))


def locate(address, size=4):
    for name, base, data in segments:
        offset = address - base
        if 0 <= offset and offset + size <= len(data):
            return name, offset, data
    raise ValueError(f"Unmapped address {address:#x} (+{size})")


def words(address, count):
    _, offset, data = locate(address, 4 * count)
    return struct.unpack_from(f"<{count}I", data, offset)


def cstring(address):
    _, offset, data = locate(address, 1)
    end = data.index(b"\0", offset)
    return data[offset:end].decode("ascii")


def origin(address):
    name, offset, _ = locate(address)
    return {"file": name, "offset": hex(offset), "virtual_address": hex(address)}


def hx(number):
    return f"0x{number:08x}"


code_va = 0xF012C000
dal_va = code_va + 0x1824F8
dal_total, names_offset = words(dal_va, 2)
assert dal_total == 0x30F4 and names_offset == 0x80
assert cstring(dal_va + names_offset) == "ABT_Propdata"
struct_table_va = code_va + 0x181C48
device_table_va = code_va + 0x185B40
devices = {}
for index in range(82):
    name, name_hash, offset, _, _, _ = words(device_table_va + index * 24, 6)
    devices[cstring(name)] = offset


def properties(device):
    address = dal_va + devices[device]
    result = {}
    while words(address, 1)[0] != 0xFF00FF00:
        attr, value = words(address, 2)
        assert attr >> 24 in (2, 0x12), (device, hex(address), hex(attr))
        name = cstring(dal_va + names_offset + (attr & 0x3FFFFF))
        result[name] = {"type": attr >> 24, "value": value, "origin": origin(address)}
        address += 8
    return result


def struct_property(prop):
    assert prop["type"] == 0x12
    size, pointer = words(struct_table_va + prop["value"] * 8, 2)
    return pointer, size


profiles = {}
for device in ("/dev/qup_ssc", "/dev/qup_ssc/11"):
    props = properties(device)
    pointer, _ = struct_property(props["qup_cfg"])
    base, common_offset, load = words(pointer, 3)
    engines = []
    for se in range(6):
        pointer, _ = struct_property(props[f"se{se}_cfg"])
        offset, protocol, mode_flags = words(pointer, 3)
        engines.append({"se_index": se, "offset": hx(offset),
                        "protocol": {1: "SPI", 2: "UART", 3: "I2C", 4: "I3C"}[protocol],
                        "mode_flags_raw": hx(mode_flags), "origin": origin(pointer)})
    profiles[device] = {"qup_virtual_base": hx(base), "wrapper_offset": hx(common_offset),
                        "load_firmware": load, "engines": engines}

bus_records = []
bus_va = 0xF0006540 + 0x297C0
for index in range(3):
    address = bus_va + index * 0x5C
    w = words(address, 23)
    assert w[0] == 0xEE600000
    packed = w[3]
    instance, core, se = packed & 255, (packed >> 8) & 255, (packed >> 16) & 255
    assert instance == 99 and core == se + 1
    clock = cstring(words(w[16], 1)[0])
    assert clock == f"scc_qupv3_se{se}_clk"
    bus_records.append({
        "core_index_one_based": core, "ssc_se_index": se,
        "core_offset": hx(w[2]), "physical_address_from_lpass_map": hx(0x62600000 + w[2]),
        "dsp_controller_irq": w[4], "clock": clock,
        "scl": {"ssc_gpio": (w[7] >> 4) & 0x3FF, "function": w[7] & 15, "encoding": hx(w[7])},
        "sda": {"ssc_gpio": (w[8] >> 4) & 0x3FF, "function": w[8] & 15, "encoding": hx(w[8])},
        "origin": origin(address),
    })

board_irq_aliases = {}
for device in ("/tlmm/idp7150[1]", "/tlmm/qrp7150[2]"):
    entries = {}
    for name, prop in properties(device).items():
        if name.startswith("ssc_irq_"):
            pointer, size = struct_property(prop)
            assert size == 8
            gpio, function = words(pointer, 2)
            entries[name] = {"gpio": gpio, "function": function, "origin": origin(pointer)}
    board_irq_aliases[device] = entries

rails = []
for offset in (0x16CB80, 0x16CBA4):
    address = code_va + offset
    desc = words(address, 9)
    name = cstring(desc[0])
    assert name.startswith("/pmic/client/sensor_vdd")
    votes_pointer = words(desc[3], 1)[0]
    votes = []
    for state in range(desc[2]):
        mode, millivolts, enabled = words(votes_pointer + state * 12, 3)
        votes.append({"state": state, "pmic_mode_raw": mode, "millivolts": millivolts,
                      "enable_vote": enabled})
    resources = [cstring(words(desc[7] + i * 12, 1)[0]) for i in range(desc[8])]
    rails.append({"name": name, "resource_names": sorted(set(resources)),
                  "configured_votes": votes, "origin": origin(address)})

legend = "sns_icm4x6xx_sensor_instance.c:[INVN]bus type(%d, 0:I2C/1:SPI/3:I3C), MAX bus speed: %d KHz"
sensor_data = (FW / "adsp.b15").read_bytes()
legend_offset = sensor_data.index(legend.encode() + b"\0")
hashes = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(FW.iterdir()) if p.is_file()}
report = {
    "method": "Offline ELF, DAL, HWIO and driver-data extraction with Python; not REA evidence or execution tracing.",
    "firmware_sha256": hashes,
    "bus_type_legend": {"text": legend, "file": "adsp.b15", "offset": hex(legend_offset)},
    "dal_profiles": profiles,
    "ssc_bus_records": bus_records,
    "board_irq_aliases": board_irq_aliases,
    "sensor_rails": rails,
    "limits": ["The bus_instance to core_index match is derived from registry and static driver configuration, not an AP transaction.",
               "Pin function and voltage values are configured values, not live measurements.",
               "The /11 profile contains six engines; the meaning of its suffix is not established here.",
               "No AP access, clock ownership, security permissions or sensor identity register was tested."]
}
(ROOT / "ssc-map.json").write_text(json.dumps(report, indent=2) + "\n")
for bus in bus_records:
    print(f"bus {bus['core_index_one_based']}: SSC SE{bus['ssc_se_index']} "
          f"{bus['physical_address_from_lpass_map']} "
          f"SCL gpio{bus['scl']['ssc_gpio']}/func{bus['scl']['function']} "
          f"SDA gpio{bus['sda']['ssc_gpio']}/func{bus['sda']['function']}")
for rail in rails:
    print(rail["name"], rail["resource_names"], rail["configured_votes"])
