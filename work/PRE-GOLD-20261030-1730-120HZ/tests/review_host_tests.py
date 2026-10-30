#!/usr/bin/env python3
"""Host-only tests of extracted C functions; no device access.

Usage: python3 review_host_tests.py --source /path/to/linux --repo /path/to/repo
Kernel APIs are stubs, not a substitute for kernel/hardware testing.
"""
import argparse
import hashlib
import os
import re
from pathlib import Path
import subprocess
import tempfile


def function(text, name):
    # These selected definitions have no braces in strings/comments.
    match = re.search(r'(?m)^[\w *]+\b' + re.escape(name) +
                      r'\s*\([^;{}]*\)\s*\{', text)
    if not match:
        raise ValueError(f'Definition not found: {name}')
    start = match.start()
    opening = match.end() - 1
    depth = 1
    end = opening + 1
    while depth:
        depth += (text[end] == '{') - (text[end] == '}')
        end += 1
    return text[start:end] + '\n'


COMMON = r'''
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <errno.h>
typedef uint8_t u8;
typedef uint32_t u32;
#define pr_err(...) ((void)0)
#define DRM_DEV_ERROR(...) ((void)0)
#define DRM_DEV_DEBUG(...) ((void)0)
#define ARRAY_SIZE(a) (sizeof(a)/sizeof((a)[0]))
struct device {int dummy;};
struct platform_device {struct device dev;};
struct mipi_dsi_host {int dummy;};
struct drm_display_mode {int hdisplay, vdisplay, htotal, vtotal, hsync_start, hsync_end, vsync_start, vsync_end;};
struct drm_dsc_config {int slice_width, slice_height, pic_width, pic_height, bits_per_component, slice_chunk_size;};
struct msm_dsi_host {
 struct platform_device *pdev;
 struct drm_dsc_config *dsc;
 struct drm_display_mode *mode;
 void *dev;
 int num_data_lanes, dlane_swap;
 const struct msm_dsi_cfg_handler *cfg_hnd;
 int dev_mutex, byte_intf_clk_div_2, mode_flags;
 unsigned long byte_intf_clk_rate, byte_clk_rate;
 bool power_on, diag_enabled;
 unsigned int diag_pre_ctrl,diag_pre_status,diag_post_ctrl,diag_post_status;
 void *supplies;
 struct mipi_dsi_host base;
 int format, channel, dsc_slice_per_pkt;
};
static struct msm_dsi_host chip;
#define to_msm_dsi_host(h) ((void)(h), &chip)
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--fixed', action='store_true', help='Assert corrected behavior')
    args = parser.parse_args()
    host_path = args.source / 'drivers/gpu/drm/msm/dsi/dsi_host.c'
    host = host_path.read_text()
    touch_path = args.source / 'drivers/input/touchscreen/ilitek-hanoip-spi.c'
    touch = touch_path.read_text()
    for path in (host_path, touch_path):
        print(f'SOURCE {path}: {hashlib.sha256(path.read_bytes()).hexdigest()}', flush=True)
    with tempfile.TemporaryDirectory(prefix='panel-review-') as temp:
        root = Path(temp)

        def run_case(name, code, expected_error=None):
            src, exe = root / (name + '.c'), root / name
            src.write_text(COMMON + code)
            subprocess.run(['cc', '-std=c11', '-g', '-O1',
                            '-fsanitize=undefined,bounds', '-fno-sanitize-recover=all',
                            str(src), '-o', str(exe)], check=True)
            result = subprocess.run([str(exe)], text=True, capture_output=True)
            if expected_error:
                assert result.returncode != 0 and expected_error in result.stderr, result
                print(f'REPRODUCED {name}: {result.stderr.splitlines()[0]}', flush=True)
            else:
                assert result.returncode == 0, result.stderr
                print(f'PASS {name}: {result.stdout.strip()}', flush=True)

        lane_stubs = r'''
struct device_node {int dummy;}; struct property {int dummy;};
static u32 lanes[4] = {4,1,2,3};
static struct property prop;
static struct property *of_find_property(struct device_node *n, const char *s, int *len)
{*len=16; return &prop;}
static int drm_of_get_data_lanes_count(struct device_node *n, int a, int b) {return 4;}
static int of_property_read_u32_array(struct device_node *n, const char *s, u32 *v, int count)
{memcpy(v,lanes,count*sizeof(*v)); return 0;}
'''
        table = host[host.index('static const int supported_data_lane_swaps'):host.index('static int dsi_host_parse_lane_data')]
        run_case('lane_invalid_index', lane_stubs + table + function(host, 'dsi_host_parse_lane_data') + r'''
int main(void) {struct platform_device p; chip.pdev=&p;
''' + (r'''
for(int j=0;j<4;j++) {
 for(int i=0;i<4;i++)lanes[i]=i;
 lanes[j]=4; assert(dsi_host_parse_lane_data(&chip,NULL)==-EINVAL);
 lanes[j]=UINT32_MAX; assert(dsi_host_parse_lane_data(&chip,NULL)==-EINVAL);
}
for(unsigned int k=0;k<ARRAY_SIZE(supported_data_lane_swaps);k++) {
 for(int i=0;i<4;i++)lanes[supported_data_lane_swaps[k][i]]=i;
 assert(dsi_host_parse_lane_data(&chip,NULL)==0);
 assert(chip.dlane_swap==(int)k);
}
puts("8 invalid entries rejected; all 8 supported lane permutations preserved");return 0;}
''' if args.fixed else 'return dsi_host_parse_lane_data(&chip, NULL);}\n'),
                 None if args.fixed else 'insufficient space for an object')

        dsc_defs = '#define MODE_OK 0\n#define MODE_H_ILLEGAL 1\n#define MODE_V_ILLEGAL 2\nenum drm_mode_status { dummy_status };\n'
        dsc_function = function(host, 'msm_dsi_host_check_dsc')
        run_case('dsc_zero_slice', dsc_defs + dsc_function + r'''
int main(void) {struct drm_dsc_config d={0,10};
struct drm_display_mode m={1080,2460}; chip.dsc=&d;
''' + (r'''
assert(msm_dsi_host_check_dsc(NULL,&m)==MODE_H_ILLEGAL);
d.slice_width=540;d.slice_height=0;
assert(msm_dsi_host_check_dsc(NULL,&m)==MODE_V_ILLEGAL);
chip.dsc=NULL;assert(msm_dsi_host_check_dsc(NULL,&m)==MODE_OK);
puts("both zero slice dimensions rejected; non-DSC preserved");return 0;}
''' if args.fixed else 'return msm_dsi_host_check_dsc(NULL,&m);}\n'),
                 None if args.fixed else 'division by zero')
        run_case('dsc_valid_and_invalid_dimensions', dsc_defs + dsc_function + r'''
int main(void) {struct drm_dsc_config d={540,10};
struct drm_display_mode m={1080,2460}; chip.dsc=&d;
assert(msm_dsi_host_check_dsc(NULL,&m)==MODE_OK);
m.hdisplay=1079; assert(msm_dsi_host_check_dsc(NULL,&m)==MODE_H_ILLEGAL);
m.hdisplay=1080; m.vdisplay=2459;
assert(msm_dsi_host_check_dsc(NULL,&m)==MODE_V_ILLEGAL);
puts("3 geometry checks"); return 0;}
''')
        run_case('mode_allocation_failure', r'''
static int alloc_failure=1, destroyed;
static void drm_mode_destroy(void *dev, struct drm_display_mode *m) {destroyed++;free(m);}
static struct drm_display_mode *drm_mode_duplicate(void *d,const struct drm_display_mode *m)
{if(alloc_failure)return NULL;struct drm_display_mode *n=malloc(sizeof(*n));assert(n);*n=*m;return n;}
''' + function(host, 'msm_dsi_host_set_display_mode') + r'''
int main(void) {struct drm_display_mode request={1080,2460};
chip.mode=malloc(sizeof(*chip.mode)); assert(chip.mode);
struct drm_display_mode *old=chip.mode; old->hdisplay=720;
assert(msm_dsi_host_set_display_mode(NULL,&request)==-ENOMEM);
''' + (r'''
assert(chip.mode==old && chip.mode->hdisplay==720 && destroyed==0);
alloc_failure=0;assert(msm_dsi_host_set_display_mode(NULL,&request)==0);
assert(chip.mode!=old && chip.mode->hdisplay==1080 && destroyed==1);
free(chip.mode);puts("old mode preserved on ENOMEM; success replaces and frees old mode");return 0;}
''' if args.fixed else 'assert(chip.mode==NULL); puts("old mode lost on failed allocation"); return 0;}\n'))

        run_case('dsi_runtime_pm_failures', r'''
#define DBG(...) ((void)0)
#define MIPI_DSI_MODE_VIDEO 1
#define REG_DSI_CTRL 0
#define REG_DSI_STATUS0 1
struct msm_dsi_phy {int dummy;};
struct msm_dsi_phy_shared_timings {int byte_intf_clk_div_2;};
struct test_cfg {int num_regulators;};
struct test_ops {int (*link_clk_set_rate)(struct msm_dsi_host *);
int (*link_clk_enable)(struct msm_dsi_host *); void (*link_clk_disable)(struct msm_dsi_host *);};
struct msm_dsi_cfg_handler {struct test_cfg *cfg; struct test_ops *ops;};
static int pm_count, pm_failure, clock_failure, rate_failure, pin_failure, timing_failure;
static int timings, regulators, clocks, clock_calls, resets, sleep_calls;
static void mutex_lock(int *p){} static void mutex_unlock(int *p){}
static void msm_dsi_sfpb_config(struct msm_dsi_host *h,bool on){}
static int regulator_bulk_enable(int n,void *p){regulators++;return 0;}
static int regulator_bulk_disable(int n,void *p){regulators--;return 0;}
static int pm_runtime_get_sync(struct device *d){pm_count++;return pm_failure;}
static int pm_runtime_resume_and_get(struct device *d){if(pm_failure<0)return pm_failure;pm_count++;return 0;}
static void pm_runtime_put(struct device *d){pm_count--;}
static int set_rate(struct msm_dsi_host *h){clock_calls++;return rate_failure;}
static int enable_clock(struct msm_dsi_host *h){if(clock_failure)return clock_failure;clocks++;return 0;}
static void disable_clock(struct msm_dsi_host *h){clocks--;}
static int pinctrl_pm_select_default_state(struct device *d){return pin_failure;}
static int pinctrl_pm_select_sleep_state(struct device *d){sleep_calls++;return 0;}
static unsigned int dsi_read(struct msm_dsi_host *h,int reg){return 0;}
static void dsi_op_mode_config(struct msm_dsi_host *h,bool a,bool b){}
static int dsi_timing_setup(struct msm_dsi_host *h,bool b){timings++;return timing_failure;}
static void dsi_sw_reset(struct msm_dsi_host *h){resets++;}
static void dsi_ctrl_enable(struct msm_dsi_host *h,struct msm_dsi_phy_shared_timings *t,struct msm_dsi_phy *p){}
''' + function(host, 'msm_dsi_host_power_on') + r'''
int main(void) {
struct platform_device p; struct test_cfg cfg={1};
struct test_ops ops={set_rate,enable_clock,disable_clock};
struct msm_dsi_cfg_handler handler={&cfg,&ops};
struct msm_dsi_phy_shared_timings t={0}; chip.pdev=&p;chip.cfg_hnd=&handler;
struct drm_display_mode m={1080,2460};chip.mode=&m;
''' + (r'''
for(int fail=0;fail<5;fail++) {
 pm_failure=rate_failure=clock_failure=pin_failure=timing_failure=0;
 pm_count=regulators=clocks=clock_calls=timings=resets=sleep_calls=0;
 if(fail==0)pm_failure=-EIO;
 if(fail==1)rate_failure=-EIO;
 if(fail==2)clock_failure=-EIO;
 if(fail==3)pin_failure=-EIO;
 if(fail==4)timing_failure=-EIO;
 assert(msm_dsi_host_power_on(NULL,&t,false,NULL)==-EIO);
 assert(!chip.power_on && pm_count==0 && regulators==0 && clocks==0 && resets==0);
 if(fail==0)assert(clock_calls==0 && timings==0);
 if(fail==4)assert(sleep_calls==1);
}
pm_failure=rate_failure=clock_failure=pin_failure=timing_failure=0;
chip.mode=NULL;assert(msm_dsi_host_power_on(NULL,&t,false,NULL)==-EINVAL);
assert(pm_count==0 && regulators==0 && clocks==0);
chip.mode=&m;assert(msm_dsi_host_power_on(NULL,&t,false,NULL)==0);
assert(chip.power_on && pm_count==1 && regulators==1 && clocks==1 && resets==1);
assert(msm_dsi_host_power_on(NULL,&t,false,NULL)==0);
assert(pm_count==1 && regulators==1 && clocks==1 && resets==1);
puts("resume/rate/clock/pinctrl/timing failures unwind; missing mode rejected; successful activation and idempotence preserved");return 0;}
''' if args.fixed else r'''
clock_failure=-EIO;
assert(msm_dsi_host_power_on(NULL,&t,false,NULL)==-EIO);
assert(pm_count==1 && !chip.power_on);
pm_count=0;clock_failure=0;pm_failure=-EIO;
assert(msm_dsi_host_power_on(NULL,&t,false,NULL)==0);
assert(chip.power_on && timings==1);
puts("clock failure leaks PM vote; failed runtime resume still reaches timing/MMIO path and returns success");return 0;}
'''))

        if args.fixed:
            timing_function = function(host, 'dsi_timing_setup')
            timing_macros = ''.join(f'#define {name}(x) ((u32)(x))\n' for name in
                                    sorted(set(re.findall(r'\b(DSI_[A-Z0-9_]+)\(', timing_function))))
            timing_macros += ''.join(f'#define {name} {i}\n' for i, name in
                                     enumerate(sorted(set(re.findall(r'\bREG_DSI_[A-Z0-9_]+', timing_function)))))
            run_case('dsc_timing_error_propagation', timing_macros + r'''
#define DBG(...) ((void)0)
#define MIPI_DSI_MODE_VIDEO 1
#define MIPI_DSI_DCS_LONG_WRITE 0
#define DIV_ROUND_UP(n,d) (((n)+(d)-1)/(d))
static int rc_failure, writes, rc_calls;
static bool msm_dsi_host_is_wide_bus_enabled(struct mipi_dsi_host *h){return false;}
static int dsi_populate_dsc_params(struct msm_dsi_host *h,struct drm_dsc_config *d)
{rc_calls++;return rc_failure;}
static int msm_dsc_get_bytes_per_line(struct drm_dsc_config *d){return 1080;}
static void dsi_update_dsc_timing(struct msm_dsi_host *h,bool cmd){}
static void dsi_write(struct msm_dsi_host *h,int reg,u32 val){writes++;}
static int mipi_dsi_pixel_format_to_bpp(int format){return 24;}
''' + timing_function + r'''
int main(void) {
struct drm_display_mode m={1080,2460,1136,2520,1108,1112,2506,2508};
struct drm_dsc_config d={540,10};chip.mode=&m;chip.dsc=&d;chip.mode_flags=MIPI_DSI_MODE_VIDEO;
rc_failure=-EOPNOTSUPP;
assert(dsi_timing_setup(&chip,false)==-EOPNOTSUPP && writes==0 && rc_calls==1);
rc_failure=0;assert(dsi_timing_setup(&chip,false)==0 && writes>0);
writes=rc_calls=0;d.slice_width=0;
assert(dsi_timing_setup(&chip,false)==-EINVAL && writes==0 && rc_calls==0);
d.slice_width=540;d.slice_height=0;
assert(dsi_timing_setup(&chip,false)==-EINVAL && writes==0 && rc_calls==0);
puts("actual timing function propagates RC error, rejects zero slices before writes, and preserves valid setup");return 0;}
''')

        touch_stubs = r'''
#define ILI_REPORT 43
#define ILI_SLOTS 10
#define IRQ_HANDLED 1
#define MT_TOOL_FINGER 1
#define ABS_MT_POSITION_X 0
#define ABS_MT_POSITION_Y 1
typedef int irqreturn_t;
struct ili_hanoip {unsigned long irqs,reports,rejected; void *input;};
static u8 packet[43]; static int io_error, events;
static int ili_read(struct ili_hanoip *ts, void *out, size_t n)
{if(io_error)return -EIO; memcpy(out,packet,n);return 0;}
static void input_mt_slot(void *p,int i){events++;}
static void input_mt_report_slot_state(void *p,int t,bool active){events++;}
static void input_report_abs(void *p,int code,unsigned int v)
{assert(v <= (code==0 ? 1079U:2459U)); events++;}
static void input_mt_sync_frame(void *p){events++;}
static void input_sync(void *p){events++;}
static void checksum(void) {u8 sum=0; for(int i=0;i<42;i++)sum+=packet[i]; packet[42]=-sum;}
'''
        run_case('touch_packets', touch_stubs + function(touch, 'ili_irq') + r'''
int main(void) {struct ili_hanoip ts={0};
for(unsigned int x=0;x<4096;x++) {
 memset(packet,255,sizeof(packet)); packet[0]=0x5a;
 packet[1]=(x>>8)<<4; packet[2]=x; packet[3]=0; checksum(); events=0;
 unsigned long before=ts.reports; ili_irq(0,&ts);
 assert(ts.reports==before+(x<2048)); if(x>=2048)assert(events==0);
}
for(unsigned int y=0;y<4096;y++) {
 memset(packet,255,sizeof(packet)); packet[0]=0x5a;
 packet[1]=y>>8; packet[2]=0; packet[3]=y; checksum(); events=0;
 unsigned long before=ts.reports; ili_irq(0,&ts);
 assert(ts.reports==before+(y<2048)); if(y>=2048)assert(events==0);
}
memset(packet,255,sizeof(packet)); packet[0]=0x5a; checksum();
packet[42]^=1; events=0; ili_irq(0,&ts); assert(events==0);
checksum(); packet[0]=0x21; checksum(); events=0; ili_irq(0,&ts); assert(events==0);
io_error=1; events=0; ili_irq(0,&ts); assert(events==0);
assert(ts.irqs==ts.reports+ts.rejected);
puts("8192 X/Y-coordinate values, invalid checksum/type and SPI error; no partial input events");
return 0;}
''')

        firmware_stubs = r'''
#define ILI_CHIP 0x7807
#define ILI_HEADER 40
#define ILI_ENTRY 20
#define ILI_BLOCKS 3
struct firmware {size_t size; const u8 *data;};
static u32 get_unaligned_le32(const u8 *p)
{return (u32)p[0]|(u32)p[1]<<8|(u32)p[2]<<16|(u32)p[3]<<24;}
static u32 get_unaligned_be32(const u8 *p)
{return (u32)p[3]|(u32)p[2]<<8|(u32)p[1]<<16|(u32)p[0]<<24;}
static u32 crc32_be(u32 crc,const u8 *p,size_t n)
{while(n--){crc^=(u32)*p++<<24;for(int i=0;i<8;i++)crc=crc&0x80000000 ? (crc<<1)^0x04c11db7 : crc<<1;}return crc;}
static void put_le(u8 *p,u32 v){for(int i=0;i<4;i++)p[i]=v>>(8*i);}
static void put_be(u8 *p,u32 v){for(int i=0;i<4;i++)p[3-i]=v>>(8*i);}
'''
        run_case('touch_firmware_validation', firmware_stubs + function(touch, 'ili_validate_firmware') + r'''
int main(void) {
u32 sizes[]={81920,8192,512}, dest[]={0,0x20870,0x20670};
size_t total=100+81920+8192+512; u8 *bytes=calloc(total+1,1); assert(bytes);
memcpy(bytes,"HNOIRAM1",8); u32 fields[]={0x7807,3,1080,2460,2048,0x10000a00,0x01040608,0};
for(int i=0;i<8;i++)put_le(bytes+8+4*i,fields[i]);
size_t off=100;
for(int i=0;i<3;i++) {u8 *entry=bytes+40+20*i;
 put_le(entry,i+1);put_le(entry+4,dest[i]);put_le(entry+8,sizes[i]);
 u32 crc=crc32_be(~0U,bytes+off,sizes[i]-4);
 put_le(entry+12,crc);put_le(entry+16,off);put_be(bytes+off+sizes[i]-4,crc);off+=sizes[i];}
struct firmware fw={total,bytes}; assert(ili_validate_firmware(&fw)==0);
for(size_t n=0;n<100;n++){fw.size=n;assert(ili_validate_firmware(&fw)<0);}
size_t trunc[]={100,81920+99,81920+100,81920+8192+99,total-1,total+1};
for(unsigned int i=0;i<ARRAY_SIZE(trunc);i++){fw.size=trunc[i];assert(ili_validate_firmware(&fw)<0);}
fw.size=total;
for(size_t i=0;i<100;i++){bytes[i]^=0x80;assert(ili_validate_firmware(&fw)<0);bytes[i]^=0x80;}
off=100;
for(int i=0;i<3;i++){bytes[off]^=1;assert(ili_validate_firmware(&fw)==-EBADMSG);bytes[off]^=1;off+=sizes[i];}
assert(ili_validate_firmware(&fw)==0);free(bytes);
puts("valid image; 106 truncated/oversized lengths, 100 metadata mutations, 3 block corruptions");return 0;}
''')

    # Reuse the existing actual-C LCDB suite with an explicit source path.
    previous = args.repo / 'work/display-robustness-20261025/display-v2/hanoip-lcdb-host-test.py'
    script = previous.read_text()
    script = script.replace("repo = Path(__file__).resolve().parents[2]", f'repo = Path({str(args.source.parent)!r})')
    script = script.replace("repo / 'kernel-mainline/drivers/regulator/qcom-lcdb-regulator.c'",
                            f'Path({str(args.source / "drivers/regulator/qcom-lcdb-regulator.c")!r})')
    exec(compile(script, str(previous), 'exec'), {'__file__': str(previous), '__name__': '__main__'})


if __name__ == '__main__':
    main()
