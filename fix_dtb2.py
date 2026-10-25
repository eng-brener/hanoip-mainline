#!/usr/bin/env python3
from scripts.hanoip_boot import inspect, repair_v2

if __name__ == "__main__":
    output = 'work/kernel-mainline-hanoip-fixed2.img'
    repair_v2('work/kernel-mainline-hanoip-osm.img', output)
    print(inspect(output))
