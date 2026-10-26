#!/usr/bin/env python3
"""Read-only local analysis of saved G60 FPC executable artifacts."""

import hashlib
import json
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parent
ART = ROOT / "android-artifacts"
CAPTURE = ROOT.parent / "android-dump-20261025"


def zstring(data, offset):
    return data[offset:data.index(b"\0", offset)].decode("ascii")


# Reassemble the split ARM32 trusted app without loading or executing it.
mdt = (ART / "fpctzapp.mdt").read_bytes()
assert mdt[:6] == b"\x7fELF\x01\x01"
assert struct.unpack_from("<H", mdt, 18)[0] == 40
phoff = struct.unpack_from("<I", mdt, 28)[0]
phsize, phnum = struct.unpack_from("<HH", mdt, 42)
headers = [struct.unpack_from("<8I", mdt, phoff + i * phsize) for i in range(phnum)]
image_size = max([len(mdt)] + [p[1] + p[4] for p in headers])
assert image_size < 32 * 1024 * 1024
image = bytearray(image_size)
image[:len(mdt)] = mdt
for index, header in enumerate(headers):
    part = (ART / f"fpctzapp.b{index:02d}").read_bytes()
    assert len(part) == header[4]
    image[header[1]:header[1] + len(part)] = part
(ROOT / "fpctzapp-reconstructed.elf").write_bytes(image)


def ta_read(address, length):
    for kind, offset, virtual, _, size, *_ in headers:
        if kind == 1 and virtual <= address and address + length <= virtual + size:
            start = offset + address - virtual
            return bytes(image[start:start + length])
    raise ValueError(f"Unmapped trusted app address {address:#x}")


dynamic = {}
for header in headers:
    if header[0] != 2:
        continue
    for offset in range(header[1], header[1] + header[4], 8):
        tag, value = struct.unpack_from("<II", image, offset)
        if tag == 0:
            break
        dynamic[tag] = value
_, count = struct.unpack("<II", ta_read(dynamic[4], 8))
strings = ta_read(dynamic[5], dynamic[10])
symbols = []
for index in range(count):
    name, value, size, info, other, section = struct.unpack(
        "<IIIBBH", ta_read(dynamic[6] + index * dynamic[11], dynamic[11]))
    if name:
        symbols.append({"index": index, "name": zstring(strings, name), "value": hex(value),
                        "size": size, "info": info, "section_index": section})
(ROOT / "ta-dynamic-symbols.json").write_text(json.dumps(symbols, indent=2) + "\n")
by_name = {s["name"]: s for s in symbols}
spi_init = int(by_name["fpc_spi_init"]["value"], 16) & ~1
assert ta_read(spi_init, 2) == b"\x01\x20"  # Thumb: movs r0, #1
speed_getter = int(by_name["fpc_pal_spi_get_speed_hz"]["value"], 16) & ~1
assert ta_read(speed_getter, 8) == bytes.fromhex("43f60060c0f24900")

# Actual module imports establish the scope of the Android kernel helper.
module = (ART / "fpc1020_mmi.ko").read_bytes()
assert module[:6] == b"\x7fELF\x02\x01"
section_offset = struct.unpack_from("<Q", module, 40)[0]
section_size, section_count, _ = struct.unpack_from("<HHH", module, 58)
sections = [struct.unpack_from("<IIQQQQIIQQ", module, section_offset + i * section_size)
            for i in range(section_count)]
imports = []
for section in sections:
    if section[1] != 2:
        continue
    string_section = sections[section[6]]
    string_data = module[string_section[4]:string_section[4] + string_section[5]]
    for offset in range(section[4], section[4] + section[5], section[9]):
        name, _, _, index, _, _ = struct.unpack_from("<IBBHQQ", module, offset)
        if index == 0 and name:
            imports.append(zstring(string_data, name))
(ROOT / "fpc-module-imports.txt").write_text("\n".join(sorted(imports)) + "\n")

# Decode the known DAL SPI records from the captured secure device config.
devcfg_path = CAPTURE / "partitions-a/devcfg_a.img"
devcfg = devcfg_path.read_bytes()
assert struct.unpack_from("<6I", devcfg, 0x66D8) == (0x1950, 0x20, 0xF50, 0x11A4, 0x11A4, 1)
assert struct.unpack_from("<II", devcfg, 0x7954) == (0x128000A0, 12)
assert struct.unpack_from("<QQ", devcfg, 0x6248 + 12 * 16) == (8, 0x1C1F9500)
controllers = []
for offset in (0x9500, 0x9580, 0x9600):
    base = struct.unpack_from("<Q", devcfg, offset)[0]
    core_offset, packed = struct.unpack_from("<II", devcfg, offset + 8)
    clock = struct.unpack_from("<Q", devcfg, offset + 32)[0]
    controllers.append({"config_index_raw": packed & 255, "packed_index_raw": hex(packed),
                        "mmio": hex(base + core_offset), "clock": zstring(devcfg, clock - 0x1C1F0000),
                        "devcfg_file_offset": hex(offset)})

inputs = [*ART.iterdir(), devcfg_path, CAPTURE / "partitions-a/tz_a.img"]
report = {
    "method": "Local ELF/DAL extraction and LLVM disassembly; no target execution or REA Evidence ID.",
    "input_sha256": {str(p.relative_to(ROOT.parent)): hashlib.sha256(p.read_bytes()).hexdigest()
                     for p in sorted(inputs) if p.is_file()},
    "android_stack": {"driver": "fpc1020_mmi", "trusted_app": "fpctzapp", "exact_sensor_model": None,
                      "irq_gpio": 90, "reset_gpio": 4, "fpc_enable_gpio": 29,
                      "alternative_chipone_enable_gpio": 30},
    "trusted_app": {"architecture": "ELF32 ARM/Thumb", "spi_open_argument": 1,
                    "spi_open_argument_origin_vma": hex(spi_init), "speed_getter_hz": 4800000,
                    "speed_getter_origin_vma": hex(speed_getter),
                    "spi_imports": [s["name"] for s in symbols
                                    if s["section_index"] == 0 and s["name"].startswith("qsee_spi_")]},
    "secure_spi_controller_records": controllers,
    "spi_candidate": {"mmio": "0x884000", "ap_tlmm_pins": [0, 1, 2, 3],
                      "confidence": "Strong static correlation of argument 1 with config record 1; QSEE enum mapping not validated live."},
    "limits": ["Compatible fpc,fpc1020 does not identify exact silicon model.",
               "No fingerprint templates or enrollment databases were read.",
               "No GPIO, SPI, TEE command, enrollment or authentication was initiated.",
               "Runtime evidence includes saved Android boot logs and read-only live driver metadata; no new fingerprint operation was tested.",
               "Legacy QSEECOM transport and FPC HAL protocol remain implementation requirements."]
}
live = ROOT / "android-live-readonly"
if (live / "driver-values.txt").exists():
    text = (live / "driver-values.txt").read_text()
    values = {name: re.search(r"^" + name + r":\n([^\n]*)", text, re.M).group(1)
              for name in ("vendor", "modalias", "irq", "irq_cnt")}
    report["android_live_metadata"] = {
        "driver_values": values,
        "hwid_property": (live / "fingerprint-hardware-property.txt").read_text().strip(),
        "hal_elf": json.loads((live / "hal-elf-metadata.json").read_text()),
        "fpc1540_literal": "Present in HAL, not an observed silicon identity.",
    }
    for path in sorted((live / "programs").iterdir()):
        report["input_sha256"][str(path.relative_to(ROOT.parent))] = hashlib.sha256(path.read_bytes()).hexdigest()
(ROOT / "fpc-findings.json").write_text(json.dumps(report, indent=2) + "\n")
print("FPC artifact analysis complete; GPIO29 enable, GPIO4 reset, GPIO90 IRQ.")
print("TA SPI argument=1; SPI1 is a static candidate, not a live access result.")
