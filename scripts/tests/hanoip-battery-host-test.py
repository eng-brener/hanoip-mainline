#!/usr/bin/env python3
"""Check the real gauge conversion and SMB status helpers without hardware."""
from pathlib import Path
import os
import subprocess
import tempfile
repo = Path(__file__).resolve().parents[2]
qg = (repo/'kernel-mainline/drivers/power/supply/qcom_qg.c').read_text()
smb = (repo/'kernel-mainline/drivers/power/supply/qcom_smbx.c').read_text()
def function(source, name):
    start = source.index('static int '+name+'(')
    brace = source.index('{',start)
    depth = 1
    end = brace+1
    while depth:
        depth += (source[end]=='{')-(source[end]=='}')
        end += 1
    return source[start:end]+'\n'
preamble = r'''
#include <assert.h>
#include <stdint.h>
#include <stdbool.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
typedef uint8_t u8;
typedef uint16_t u16;
typedef int16_t s16;
typedef int64_t s64;
typedef uint64_t u64;
typedef uint32_t u32;
#define BIT(n) (1U<<(n))
#define GENMASK(h,l) (((~0U)>>(31-(h))) & ((~0U)<<(l)))
#define div_s64(a,b) ((a)/(b))
#define div_u64(a,b) ((a)/(b))
#define dev_err(...) ((void)0)
struct power_supply_battery_info { int voltage_min_design_uv,voltage_max_design_uv; };
struct regmap { u8 regs[65536]; int fail; };
static int regmap_read(struct regmap *m,unsigned int a,unsigned int *v) {
 if (m->fail) return -EIO;
 *v=m->regs[a]; return 0;
}
static int regmap_bulk_read(struct regmap *m,unsigned int a,void *v,unsigned int n) {
 if (m->fail) return -EIO;
 memcpy(v,m->regs+a,n); return 0;
}
enum smb_generation {SMB2,SMB5};
#define SMB_REG_OFFSET(smb) ((smb)->gen==SMB2?0x600:0x100)
struct smb_chip {struct regmap *regmap; unsigned int base; enum smb_generation gen;};
enum {POWER_SUPPLY_STATUS_UNKNOWN,POWER_SUPPLY_STATUS_CHARGING,
 POWER_SUPPLY_STATUS_DISCHARGING,POWER_SUPPLY_STATUS_NOT_CHARGING,POWER_SUPPLY_STATUS_FULL};
'''
helpers=qg[qg.index('/* BATT offsets */'):qg.index('static enum power_supply_property qcom_qg_props')]
helpers+=smb[smb.index('#define BATTERY_CHARGER_STATUS_1'):smb.index('struct smb_init_register')]
helpers+='\n'.join(function(smb,f) for f in ('smb_get_prop_usb_online','smbx_ov_status','smb_get_prop_status'))
tests=r'''
static void put16(struct regmap *m,unsigned int a,unsigned int v) {
 m->regs[a]=v&255; m->regs[a+1]=v>>8;
}
int main(void) {
 struct regmap m={0};
 struct power_supply_battery_info info={3200000,4450000};
 struct qcom_qg_chip q={.regmap=&m,.base=0x4800,.batt_info=&info};
 int v;
 put16(&m,0x4880,20000);
 assert(qcom_qg_get_voltage(&q,0x80,&v)==0 && v==3892740);
 assert(qcom_qg_get_capacity(&q,&v)==0 && v==55);
 put16(&m,0x4882,(u16)(s16)-100);
 assert(qcom_qg_get_current(&q,0x82,&v)==0 && v==15258);
 put16(&m,0x4882,100);
 assert(qcom_qg_get_current(&q,0x82,&v)==0 && v==-15258);
 put16(&m,0x4880,0);
 assert(qcom_qg_get_capacity(&q,&v)==0 && v==0);
 put16(&m,0x4880,65535);
 assert(qcom_qg_get_capacity(&q,&v)==0 && v==100);
 m.fail=1;
 assert(qcom_qg_get_current(&q,0x82,&v)==-EIO);
 assert(qcom_qg_get_voltage(&q,0x80,&v)==-EIO);
 assert(qcom_qg_get_capacity(&q,&v)==-EIO);
 m.fail=0;
 struct smb_chip s={.regmap=&m,.base=0x1000,.gen=SMB5};
 m.regs[0x110b]=0x11;
 assert(smb_get_prop_usb_online(&s,&v)==0 && v==1);
 assert(smbx_ov_status(&s)==0);
 for(int i=0;i<8;i++) {
  m.regs[0x1006]=i;
  assert(smb_get_prop_status(&s,&v)==0);
  assert(v==(i<5?POWER_SUPPLY_STATUS_CHARGING:i<7?POWER_SUPPLY_STATUS_FULL:POWER_SUPPLY_STATUS_NOT_CHARGING));
 }
 m.regs[0x100d]=BIT(1);
 assert(smbx_ov_status(&s)==1);
 m.regs[0x1006]=FAST_CHARGE;
 assert(smb_get_prop_status(&s,&v)==0 && v==POWER_SUPPLY_STATUS_NOT_CHARGING);
 m.regs[0x100d]=0;
 m.regs[0x110b]=0;
 assert(smb_get_prop_status(&s,&v)==0 && v==POWER_SUPPLY_STATUS_DISCHARGING);
 s.gen=SMB2; m.regs[0x1007]=BIT(5);
 assert(smbx_ov_status(&s)==1);
 m.fail=1;
 assert(smbx_ov_status(&s)==-EIO);
 assert(smb_get_prop_usb_online(&s,&v)==-EIO);
 assert(smb_get_prop_status(&s,&v)==-EIO);
 puts("PASS: gauge units/sign/capacity bounds, SMB charging states, overvoltage value bits, read errors");
}
'''
with tempfile.TemporaryDirectory(prefix='hanoip-battery-test-') as tmp:
    src=Path(tmp)/'test.c'; exe=Path(tmp)/'test'
    src.write_text(preamble+helpers+tests)
    subprocess.run([os.environ.get('CC','cc'),'-std=c11','-Wall','-Wextra','-Werror',str(src),'-o',str(exe)],check=True)
    subprocess.run([str(exe)],check=True)
