#!/usr/bin/env python3
from scripts.hanoip_boot import inspect, repair_v2

if __name__ == "__main__":
    output = 'work/kernel-mainline-hanoip-initrd-fixed.img'
    repair_v2('work/kernel-mainline-hanoip-initrd.img', output)
    print(inspect(output))
