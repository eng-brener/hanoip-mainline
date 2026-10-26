Boot optimization experiment 1 — UFS RO guard

Derived from gpu-zap-early. Only /sbin/load-ufs changed: each newly appearing
sd* disk or partition gets one BLKROSET, then the guard waits for an unchanged
block inventory for 8 seconds, verifies every node reports ro=1, and exits.
The old script reapplied blockdev --setro to all 84 nodes every 100 ms forever.
No loglevel, display, GPU, Wi-Fi or Bluetooth ordering changes are included.

Fastboot-boot only. No partition writes. Preserve gpu-zap-early and GOLD.
