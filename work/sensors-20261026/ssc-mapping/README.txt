SSC firmware mapping, Moto G60, 2026-10-26

Read docs/kernel/checkpoint-2026-10-26-sensores-ssc.txt first.
Run locally: python3 work/sensors-20261026/ssc-mapping/analyze-firmware.py
Output: ssc-map.json. No phone connection or code execution is performed.

ICM: registry bus1 -> SSC SE0/0x62680000, SSC GPIO0/1 func1, I3C.
TMD: registry bus5 -> SSC SE4/0x62690000, SSC GPIO6/7 func4, I2C.
Rails: sensor_vdd L7C/3312mV; sensor_vddio L8C/1800mV (configured votes).
Values are from static tables, not measured voltage or AP transactions.
The AP a94000 SE11 variants remain failed; do not retry them.

Next software route to investigate: ADSP sensors PD with FastRPC,
hexagonrpcd backed by RAM, libssc and iio-sensor-proxy. Existing pmOS
package list includes libssc/iio-sensor-proxy but not hexagonrpcd.
No new kernel or DT was built or booted during this analysis.
