import struct

# corrige o boot.img do kernel mainline
# - page_size para 4096 (o mkbootimg gravou 256 por bug)
# - dtb_size para o tamanho real do DTB
src = open('work/kernel-mainline-hanoip-osm.img','rb').read()

# encontra o DTB real e o tamanho
idx = src.find(b'\xd0\x0d\xfe\xed')
totalsize = struct.unpack('>I', src[idx+4:idx+8])[0]
print('DTB real em 0x%x, totalsize %d' % (idx, totalsize))

out = bytearray(src)
# page_size em offset 32
struct.pack_into('<I', out, 32, 4096)
# v2: dtb_addr em 1632, dtb_size em 1636
struct.pack_into('<I', out, 1632, 0x1f00000)
struct.pack_into('<I', out, 1636, totalsize)
open('work/kernel-mainline-hanoip-fixed2.img','wb').write(out)

# verifica
d = open('work/kernel-mainline-hanoip-fixed2.img','rb').read()
print('page_size:', struct.unpack('<I', d[32:36])[0])
print('dtb_size:', struct.unpack('<I', d[1636:1640])[0])
print('dtb_addr: 0x%x' % struct.unpack('<I', d[1632:1636])[0])
print('total file:', len(d))
