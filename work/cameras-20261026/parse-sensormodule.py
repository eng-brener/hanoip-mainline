#!/usr/bin/env python3
"""Parse grosseiro dos blobs com.qti.sensormodule.*.bin do hanoip (somente leitura).

Formato observado (camx binary, little-endian):
  - Nós de 72 bytes, stride 0x48:
      +0x00 u32 marker 0xFFFFFFFF
      +0x04 u32 0
      +0x08 u32 V (referência: aponta p/ campo de outro nó; ex.: V=0xdb80
             cai dentro do campo nome de outro registro — NÃO é offset de
             dados brutos neste arquivo; semântica exata pendente do loader
             camx; cada tripleto registerData/delayUs/slaveAddr tem V em
             passos de 8 e C sequencial)
      +0x0C u32 0
      +0x10 u32 A (0x8 nos triplets de operação I2C = 8 bytes/op?)
      +0x14 u32 0
      +0x18 u32 C (índice sequencial)
      +0x1C u32 0
      +0x20 char[32] nome (null-padded)
      +0x40 8 bytes zero (folga)
  - Ordem típica por operação de modo: registerData, delayUs, slaveAddr.
  - Valores úteis já extraídos por strings: nomes de módulo/sensor/eeprom/
    atuador (ex.: mot_hanoip_ov64b_dw9800), e resoluções como u32 LE
    (s5khm2 até 12000x9000; ov64b até 9248x6944).
Uso: python3 parse-sensormodule.py <arquivo.bin>
"""
import struct, sys

def records(d):
    recs, off = [], 0
    while off + 72 <= len(d):
        u = struct.unpack_from('<8I', d, off)
        name = d[off+32:off+64].split(b'\x00')[0]
        if (u[0] == 0xFFFFFFFF and u[1] == 0 and len(name) >= 2
                and all(32 <= c < 127 for c in name)):
            recs.append((off, name.decode(), u[2], u[4], u[6]))
            off += 72
        else:
            off += 1
    return recs

def main(fn):
    d = open(fn, 'rb').read()
    recs = records(d)
    print(f'{fn}: {len(d)} bytes, {len(recs)} registros')
    for off, name, v, a, c in recs:
        if name in ('registerData', 'delayUs', 'slaveAddr', 'powerSetting',
                     'powerOffSequence', 'sensorVersion', 'sensorSlaveAddress',
                     'streamConfiguration', 'sensorName'):
            print(f'  {off:#8x} {name:22s} V={v:#8x} A={a:#6x} C={c:#6x}')

if __name__ == '__main__':
    main(sys.argv[1])
