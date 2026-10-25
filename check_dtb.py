#!/usr/bin/env python3
import json
import sys
from scripts.hanoip_boot import inspect

if __name__ == "__main__":
    path = sys.argv[1] if len(sys.argv) > 1 else "work/kernel-mainline-hanoip-osm.img"
    print(json.dumps(inspect(path), indent=2))
