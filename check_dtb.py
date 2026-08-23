import struct
d = open('work/kernel-mainline-hanoip-osm.img','rb').read()
page_size = struct.unpack('<I', d[32:36])[0]
header_version = struct.unpack('<I', d[40:44])[0]
kernel_size = struct.unpack('<I', d[8:12])[0]
ramdisk_size = struct.unpack('<I', d[16:20])[0]
second_size = struct.unpack('<I', d[24:28])[0]
recovery_dtbo_size = struct.unpack('<I', d[1624:1628])[0]
dtb_addr = struct.unpack('<I', d[1632:1636])[0]
dtb_size = struct.unpack('<I', d[1636:1640])[0]
print('page_size:', page_size)
print('header_version:', header_version)
print('kernel_size:', kernel_size)
print('ramdisk_size:', ramdisk_size)
print('second_size:', second_size)
print('recovery_dtbo_size:', recovery_dtbo_size)
print('dtb_addr:', hex(dtb_addr), 'dtb_size:', dtb_size)

def align(x, a):
    return (x + a - 1) & ~(a - 1)

end = page_size
kernel_ptr = end
end += kernel_size
end = align(end, page_size)
ramdisk_ptr = end
end += ramdisk_size
end = align(end, page_size)
second_ptr = end
end += second_size
end = align(end, page_size)
if header_version >= 1:
    rec_dtbo_ptr = end
    end += recovery_dtbo_size
    end = align(end, page_size)
if header_version >= 2:
    dtb_ptr = end
    print('dtb_ptr calculado: 0x%x' % dtb_ptr)
    print('magic no dtb_ptr:', d[dtb_ptr:dtb_ptr+4].hex())

idx = d.find(b'\xd0\x0d\xfe\xed')
print('DTB real magic em: 0x%x' % idx)
