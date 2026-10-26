#!/usr/bin/env python3
"""Summarize captured ARM64 input_event hex lines on the host only."""
import collections
import json
from pathlib import Path
import re
import struct
import sys

path = Path(sys.argv[1])
events = [struct.unpack('<qqHHi', bytes.fromhex(line.decode()))
          for line in path.read_bytes().splitlines()
          if re.fullmatch(b'[0-9a-f]{48}', line)]
counts = collections.Counter()
ranges = {}
active = {}
slot = maximum = starts = ends = frames = 0
for sec, usec, kind, code, value in events:
    counts[f'{kind}:{code}'] += 1
    if kind == 3:
        if code == 47:
            slot = value
        elif code == 57:
            if value < 0:
                active.pop(slot, None)
                ends += 1
            else:
                active[slot] = value
                starts += 1
        elif code in (53, 54):
            lo, hi = ranges.get(str(code), (value, value))
            ranges[str(code)] = [min(lo, value), max(hi, value)]
    if kind == 0 and code == 0:
        frames += 1
        maximum = max(maximum, len(active))
within_bounds = all(0 <= ranges[key][0] <= ranges[key][1] <= limit
                    for key, limit in [('53', 1079), ('54', 2459)]
                    if key in ranges)
result = dict(source=str(path), event_count=len(events),
              synchronized_frames=frames, contact_starts=starts,
              contact_ends=ends, max_observed_simultaneous_contacts=maximum,
              active_contacts_at_end=len(active), coordinate_ranges=ranges,
              coordinates_within_bounds=within_bounds,
              event_code_counts=dict(counts))
if events:
    result['event_span_seconds'] = round(
        events[-1][0] - events[0][0] +
        (events[-1][1] - events[0][1]) / 1e6, 6)
print(json.dumps(result, indent=2))
