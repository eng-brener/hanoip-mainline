FPC fingerprint investigation, Moto G60, 2026-10-26

Read docs/kernel/checkpoint-2026-10-26-fingerprint-fpc.txt.
Run locally: python3 work/fingerprint-20261026/analyze-artifacts.py
Inputs are local captured firmware and .ko program artifacts.
No executable firmware is run; no phone connection is opened.

IRQ GPIO90, reset GPIO4, FPC enable GPIO29 (not Chipone GPIO30).
Exact sensor silicon is unknown; fpc1020 is a generic compatible.
TA uses legacy QSEECOM/qsee_spi, not the modern qcomtee ABI.
SPI1/0x884000 is a strong static candidate; do not enable it for a test.

ADB returned: HAL AArch64 and QSEE libraries collected by read-only ADB.
Live vendor=fpc, modalias=fpc1020, irq=0, irq_cnt=60. HWID property empty.
HAL contains fpc1540, which does not confirm exact sensor silicon.
No enrollment databases were read. Next: interpret the local HAL ABI.
