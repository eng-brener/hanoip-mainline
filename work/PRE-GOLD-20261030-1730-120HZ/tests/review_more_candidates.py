#!/usr/bin/env python3
"""Reproduce additional candidates using actual extracted C; host-only."""
import argparse
from pathlib import Path
import subprocess
import tempfile

from review_host_tests import function


PREAMBLE = r'''
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
typedef uint32_t u32;
struct device {int unused;};
struct platform_device {struct device dev;};
struct mipi_dsi_host {int unused;};
struct mipi_dsi_msg {unsigned int flags;};
struct msm_dsi_host;
struct ops {
 int (*link_clk_set_rate)(struct msm_dsi_host *);
 int (*link_clk_enable)(struct msm_dsi_host *);
 void (*link_clk_disable)(struct msm_dsi_host *);
};
struct msm_dsi_cfg_handler {struct ops *ops;};
struct msm_dsi_host {
 struct platform_device *pdev;
 const struct msm_dsi_cfg_handler *cfg_hnd;
 unsigned int dma_cmd_ctrl_restore;
 void *mode,*dev,*workqueue;
 int cmd_mutex,dev_mutex;
 void *byte_src_clk,*pixel_src_clk,*dsi_pll_byte_clk,*dsi_pll_pixel_clk;
};
static struct msm_dsi_host chip;
#define to_msm_dsi_host(h) ((void)(h), &chip)
#define MIPI_DSI_MSG_USE_LPM 1
#define REG_DSI_CTRL 0
#define DSI_CTRL_CMD_MODE_EN 1
#define DSI_CTRL_ENABLE 2
#define DSI_IRQ_MASK_CMD_DMA_DONE 1
#define dev_err(...) ((void)0)
static int pm_error, rate_error, enable_error, pm_count, clocks, writes, calls;
static int pm_runtime_get_sync(struct device *d){pm_count++;return pm_error;}
static int pm_runtime_resume_and_get(struct device *d){if(pm_error<0)return pm_error;pm_count++;return 0;}
static void pm_runtime_put(struct device *d){pm_count--;}
static int rate(struct msm_dsi_host *h){calls++;return rate_error;}
static int enable(struct msm_dsi_host *h){calls++;if(enable_error)return enable_error;clocks++;return 0;}
static void disable(struct msm_dsi_host *h){clocks--;}
static void dsi_set_tx_power_mode(int n,struct msm_dsi_host *h){writes++;}
static unsigned int dsi_read(struct msm_dsi_host *h,int reg){writes++;return 0;}
static void dsi_write(struct msm_dsi_host *h,int reg,u32 val){writes++;}
static void dsi_intr_ctrl(struct msm_dsi_host *h,int mask,int enable){writes++;}
'''


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--fixed', action='store_true')
    args = parser.parse_args()
    host = (args.source / 'drivers/gpu/drm/msm/dsi/dsi_host.c').read_text()
    with tempfile.TemporaryDirectory(prefix='dsi-candidates-') as temp:
        def run(name, body, preamble=PREAMBLE):
            src = Path(temp) / (name + '.c')
            exe = src.with_suffix('')
            src.write_text(preamble + body)
            subprocess.run(['cc', '-std=c11', '-O1', '-fsanitize=undefined,bounds',
                            '-fno-sanitize-recover=all', str(src), '-o', str(exe)], check=True)
            subprocess.run([str(exe)], check=True)

        run('command_prepare', function(host, 'msm_dsi_host_xfer_prepare') +
            function(host, 'msm_dsi_host_xfer_restore') + r'''
int main(void) {
 struct platform_device p;struct ops ops={rate,enable,disable};
 struct msm_dsi_cfg_handler cfg={&ops};struct mipi_dsi_msg msg={0};
 chip.pdev=&p;chip.cfg_hnd=&cfg;
 for(int fail=0;fail<3;fail++) {
  pm_count=clocks=writes=calls=0;pm_error=rate_error=enable_error=0;
  if(fail==0)pm_error=-EIO;
  if(fail==1)rate_error=-EIO;
  if(fail==2)enable_error=-EIO;
''' + (r'''
  assert(msm_dsi_host_xfer_prepare(NULL,&msg)==-EIO);
  assert(writes==0 && clocks==0 && pm_count==0);
  assert(calls==(fail==0?0:fail==1?1:2));
 }
 pm_count=clocks=writes=calls=0;pm_error=rate_error=enable_error=0;
 for(unsigned int flags=0;flags<=1;flags++) {
  msg.flags=flags;
  assert(msm_dsi_host_xfer_prepare(NULL,&msg)==0);
  assert(pm_count==1 && clocks==1 && writes>0);
  msm_dsi_host_xfer_restore(NULL,&msg);
  assert(pm_count==0 && clocks==0);
 }
 puts("PASS: command preparation rejects resume/rate/enable errors without MMIO or leaked votes; HS/LPM success and restore preserved");return 0;}
''' if args.fixed else r'''
  assert(msm_dsi_host_xfer_prepare(NULL,&msg)==0);
  assert(writes>0 && calls==2);
  msm_dsi_host_xfer_restore(NULL,&msg);
  assert(pm_count==0);
  if(fail==2)assert(clocks==-1);
 }
 puts("REPRODUCED: command prepare ignores resume/rate/clock errors and reaches MMIO stubs; clock failure followed by restore disables an unacquired clock vote");
 return 0;
}
'''))

        if args.fixed:
            manager = (args.source / 'drivers/gpu/drm/msm/dsi/dsi_manager.c').read_text()
            dual_preamble = PREAMBLE.replace(
                'struct mipi_dsi_msg {unsigned int flags;};',
                'struct mipi_dsi_msg {unsigned int flags; void *tx_buf,*rx_buf; int tx_len,rx_len;};')
            dual_preamble = dual_preamble.replace(
                'static struct msm_dsi_host chip;',
                'static struct msm_dsi_host chips[2]; static int current;')
            dual_preamble = dual_preamble.replace(
                '#define to_msm_dsi_host(h) ((void)(h), &chip)',
                '#define to_msm_dsi_host(h) (current=(h)->unused, &chips[current])')
            dual_preamble = dual_preamble.replace(
                'static int pm_error, rate_error, enable_error, pm_count, clocks, writes, calls;', r'''
struct mock_state {int ep,er,ec,p,c,w,n;};
static struct mock_state states[2];
#define pm_error states[current].ep
#define rate_error states[current].er
#define enable_error states[current].ec
#define pm_count states[current].p
#define clocks states[current].c
#define writes states[current].w
#define calls states[current].n
''')
            run('manager_failure_cleanup', r'''
#define DSI_0 0
#define pr_err(...) ((void)0)
static bool bonded;
#define IS_SYNC_NEEDED() (bonded)
struct msm_dsi {struct mipi_dsi_host *host;};
static struct msm_dsi devices[2];
static struct msm_dsi *dsi_mgr_get_dsi(int id){return &devices[id];}
static int command_count,command_error;
static int msm_dsi_host_cmd_rx(struct mipi_dsi_host *h,const struct mipi_dsi_msg *m)
{command_count++;return command_error?command_error:m->rx_len;}
static int msm_dsi_host_cmd_tx(struct mipi_dsi_host *h,const struct mipi_dsi_msg *m)
{command_count++;return command_error?command_error:m->tx_len;}
''' + function(host, 'msm_dsi_host_xfer_prepare') +
                function(host, 'msm_dsi_host_xfer_restore') +
                function(manager, 'msm_dsi_manager_cmd_xfer') + r'''
int main(void) {
 struct platform_device p[2];struct mipi_dsi_host h[2]={{0},{1}};
 struct ops ops={rate,enable,disable};struct msm_dsi_cfg_handler cfg={&ops};
 struct mipi_dsi_msg msg={.tx_buf=&cfg,.tx_len=3};
 for(int i=0;i<2;i++){chips[i].pdev=&p[i];chips[i].cfg_hnd=&cfg;devices[i].host=&h[i];}
 int cases=0;
 for(int pair=0;pair<2;pair++) for(int bad=0;bad<(pair?2:1);bad++)
 for(int fail=0;fail<3;fail++) {
  for(int i=0;i<2;i++)states[i]=(struct mock_state){0};
  bonded=pair;command_count=0;
  if(fail==0)states[bad].ep=-EIO;
  if(fail==1)states[bad].er=-EIO;
  if(fail==2)states[bad].ec=-EIO;
  assert(msm_dsi_manager_cmd_xfer(pair?1:0,&msg)==-EIO);
  assert(command_count==0);
  for(int i=0;i<2;i++)assert(states[i].p==0 && states[i].c==0);
  assert(states[bad].w==0);cases++;
 }
 for(int pair=0;pair<2;pair++)for(int err=0;err<2;err++) {
  for(int i=0;i<2;i++)states[i]=(struct mock_state){0};
  bonded=pair;command_count=0;command_error=err?-ETIMEDOUT:0;
  assert(msm_dsi_manager_cmd_xfer(pair?1:0,&msg)==(err?-ETIMEDOUT:3));
  assert(command_count==1);
  for(int i=0;i<2;i++)assert(states[i].p==0 && states[i].c==0);
  cases++;
 }
 printf("PASS: %d manager cases: single/bonded prepare failures, success and command-error cleanup\n",cases);
 return 0;
}
''', dual_preamble)
        run('clock_reparent', r'''
static int parent_calls, parent_fail, rate_calls;
static int clk_set_parent(void *clk,void *parent)
{parent_calls++;return parent_calls==parent_fail ? -EIO:0;}
static int dsi_link_clk_set_rate_6g(struct msm_dsi_host *h){rate_calls++;return 0;}
''' + function(host, 'dsi_link_clk_set_rate_6g_v2_9') + r'''
int main(void) {
 struct platform_device p;chip.pdev=&p;
 for(parent_fail=1;parent_fail<=2;parent_fail++) {
  parent_calls=rate_calls=0;
''' + (r'''
  assert(dsi_link_clk_set_rate_6g_v2_9(&chip)==-EIO);
  assert(parent_calls==parent_fail && rate_calls==0);
 }
 parent_fail=0;parent_calls=rate_calls=0;
 assert(dsi_link_clk_set_rate_6g_v2_9(&chip)==0);
 assert(parent_calls==2 && rate_calls==1);
 puts("PASS: both parent errors propagate and stop rate setting; success preserved");return 0;}
''' if args.fixed else r'''
  assert(dsi_link_clk_set_rate_6g_v2_9(&chip)==0);
  assert(parent_calls==2 && rate_calls==1);
 }
 puts("REPRODUCED: failure of either clk_set_parent is logged but function returns success when set_rate succeeds");
 return 0;
}
'''))

        run('host_destroy_mode', r'''
#define DBG(...) ((void)0)
static int queue_freed,mode_freed,mutex_calls;
static void destroy_workqueue(void *p){queue_freed++;free(p);}
static void drm_mode_destroy(void *dev,void *mode)
{if(mode){assert(queue_freed==1 && mutex_calls==0);mode_freed++;free(mode);}}
static void mutex_destroy(int *p){mutex_calls++;}
static void pm_runtime_disable(struct device *d){}
''' + function(host, 'msm_dsi_host_destroy') + r'''
int main(void) {
 struct platform_device p;chip.pdev=&p;
 chip.mode=malloc(32);chip.workqueue=malloc(32);assert(chip.mode && chip.workqueue);
 msm_dsi_host_destroy(NULL);
 assert(chip.workqueue==NULL && queue_freed==1 && mutex_calls==2);
''' + (r'''
 assert(chip.mode==NULL && mode_freed==1);
 /* Partial initialization: mode and queue were never allocated. */
 queue_freed=mode_freed=mutex_calls=0;
 msm_dsi_host_destroy(NULL);
 assert(queue_freed==0 && mode_freed==0 && mutex_calls==2);
 puts("PASS: teardown frees final owned mode after draining queue, and accepts NULL mode/queue");return 0;}
''' if args.fixed else r'''
 assert(chip.mode!=NULL && mode_freed==0);free(chip.mode);
 puts("REPRODUCED: host destroy leaves final non-devm mode allocated");return 0;}
'''))


if __name__ == '__main__':
    main()
