#!/usr/bin/env python3
"""Minimal Android sparse image generator (raw ext4 -> sparse).

Zero blocks become DONT_CARE chunks, so fastboot only transfers real data.
Usage: img2simg.py IN.img OUT.simg
"""
import struct
import sys

BLK = 4096
MAGIC = 0xED26FF3A
CHUNK_RAW = 0xCAC1
CHUNK_DONT_CARE = 0xCAC3

def main(src, dst):
    with open(src, 'rb') as f:
        data = f.read()
    total = len(data)
    assert total % BLK == 0, f"size {total} not a multiple of {BLK}"
    nblk = total // BLK

    chunks = []
    i = 0
    zero = b'\0' * BLK
    while i < nblk:
        blk = data[i * BLK:(i + 1) * BLK]
        if blk == zero:
            j = i
            while j < nblk and data[j * BLK:(j + 1) * BLK] == zero:
                j += 1
            chunks.append((CHUNK_DONT_CARE, 0, j - i))
            i = j
        else:
            j = i
            while j < nblk and data[j * BLK:(j + 1) * BLK] != zero:
                j += 1
            chunks.append((CHUNK_RAW, i, j - i))
            i = j

    with open(dst, 'wb') as f:
        f.write(struct.pack('<IHHHHIIII', MAGIC, 1, 0, 28, 12, BLK,
                            nblk, len(chunks), 0))
        for ctype, start, count in chunks:
            body = 0 if ctype == CHUNK_DONT_CARE else count * BLK
            f.write(struct.pack('<HHII', ctype, 0, 12 + body, count))
            if ctype == CHUNK_RAW:
                f.write(data[start * BLK:(start + count) * BLK])
    print(f"{dst}: {nblk} blocks, {len(chunks)} chunks")

if __name__ == '__main__':
    main(sys.argv[1], sys.argv[2])
