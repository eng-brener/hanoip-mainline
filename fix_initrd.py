import struct
# corrige o boot.img do initrd: page_size + dtb_size
src = open('work/kernel-mainline-hanoip-initrd.img','rb').read()
idx = src.find(b'\xd0\x0d\xfe\xed')
totalsize = struct.unpack('>I', src[idx+4:idx+8])[0]
out = bytearray(src)
struct.pack_into('<I', out, 32, 4096)          # page_size
struct.pack_into('<I', out, 1632, 0x1f00000)   # dtb_addr
struct.pack_into('<I', out, 1636, totalsize)   # dtb_size
open('work/kernel-mainline-hanoip-initrd-fixed.img','wb').write(out)
d = open('work/kernel-mainline-hanoip-initrd-fixed.img','rb').read()
print('page_size:', struct.unpack('<I', d[32:36])[0])
print('ramdisk_size:', struct.unpack('<I', d[16:20])[0])
print('dtb_size:', struct.unpack('<I', d[1636:1640])[0])
print('kernel_size:', struct.unpack('<I', d[8:12])[0])
print('total:', len(d))
