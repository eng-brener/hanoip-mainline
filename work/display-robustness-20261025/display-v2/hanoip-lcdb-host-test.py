#!/usr/bin/env python3
"""Run the actual LCDB state/IO helpers against a fault-injecting host regmap.

No hardware access. Extracts the driver helpers; supplies kernel API stand-ins.
Kernel compilation separately checks the real framework APIs and descriptors.
"""
from pathlib import Path
import os
import subprocess
import tempfile

repo = Path(__file__).resolve().parents[2]
driver = (repo / 'kernel-mainline/drivers/regulator/qcom-lcdb-regulator.c').read_text()
helpers = driver[driver.index('#define PM6150L_LCDB_BASE'):driver.index('static const struct regulator_ops lab_ops')]
preamble = r'''
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <errno.h>
#include <pthread.h>
#include <string.h>
typedef uint8_t u8;
typedef uint16_t u16;
#define BIT(n) (1U << (n))
#define GENMASK(h,l) (((~0U) >> (31-(h))) & ((~0U) << (l)))
struct device { int unused; };
struct mutex { pthread_mutex_t native; };
#define mutex_init(m) assert(!pthread_mutex_init(&(m)->native, NULL))
#define mutex_lock(m) assert(!pthread_mutex_lock(&(m)->native))
#define mutex_unlock(m) assert(!pthread_mutex_unlock(&(m)->native))
#define dev_info(...) ((void)0)
#define dev_err(...) ((void)0)
#define usleep_range(a,b) ((void)0)
struct regmap {
    unsigned int regs[256];
    int fail_read, fail_write, fail_write_n, reads, writes;
    bool timeout, short_circuit;
    unsigned int write_regs[8192];
};
struct regulator_dev { void *data; int id; };
static void *rdev_get_drvdata(struct regulator_dev *r) { return r->data; }
static int rdev_get_id(struct regulator_dev *r) { return r->id; }
static int regmap_read(struct regmap *m, unsigned int addr, unsigned int *v)
{
    unsigned int reg = addr & 255;
    m->reads++;
    if ((int)reg == m->fail_read) { m->fail_read = -1; return -EIO; }
    *v = m->regs[reg];
    return 0;
}
static int regmap_write(struct regmap *m, unsigned int addr, unsigned int v)
{
    unsigned int reg = addr & 255;
    assert(m->writes < 8192);
    m->write_regs[m->writes++] = reg;
    if ((int)reg == m->fail_write || m->writes == m->fail_write_n) {
        m->fail_write = -1; return -EIO;
    }
    m->regs[reg] = v;
    if (reg == 0x46)
        m->regs[0x10] = !(v & 0x80) ? 0 : m->short_circuit ? 2 : m->timeout ? 0 : 1;
    return 0;
}
/* Stand-in for the kernel's range mapper; the real API is compile-checked. */
static int regulator_map_voltage_linear_range(struct regulator_dev *r, int min, int max)
{
    (void)r;
    for (int sel=0; sel<32; sel++) {
        int uv=(sel < 10 ? 4000 + sel*100 : 4950 + (sel-10)*50)*1000;
        if (uv >= min && uv <= max) return sel;
    }
    return -EINVAL;
}
'''
tests = r'''
static struct regmap map;
static struct qcom_lcdb chip;
static struct regulator_dev rail[2];
static void setup(bool adopted)
{
    memset(&map, 0, sizeof(map));
    memset(&chip, 0, sizeof(chip));
    map.fail_read = map.fail_write = -1;
    map.regs[0x71] = map.regs[0x81] = 21; /* 5500 mV */
    map.regs[0x41] = 38; /* 5650 mV */
    map.regs[0x46] = adopted ? 0x80 : 0;
    map.regs[0x10] = adopted ? 1 : 0;
    chip.regmap = &map; chip.base = 0xec00;
    mutex_init(&chip.lock);
    rail[0] = (struct regulator_dev){ &chip, 0 };
    rail[1] = (struct regulator_dev){ &chip, 1 };
    assert(qcom_lcdb_capture(&chip) == 0);
    assert(!map.writes);
}
static void clean(void) { assert(!pthread_mutex_destroy(&chip.lock.native)); }
static void *stress(void *arg)
{
    struct regulator_dev *r = arg;
    for (int i=0; i<100; i++) {
        assert(lcdb_lab_enable(r) == 0);
        assert(lcdb_lab_is_enabled(r) == 1);
        assert(lcdb_lab_disable(r) == 0);
    }
    return NULL;
}
int main(void)
{
    /* Handoff, both disable orders, and re-enable framework decisions. */
    for (int first=0; first<2; first++) {
        setup(true);
        assert(lcdb_lab_disable(&rail[first]) == 0);
        assert(!map.writes && map.regs[0x46] == 0x80);
        assert(lcdb_lab_is_enabled(&rail[first]) == 0);
        assert(lcdb_lab_disable(&rail[!first]) == 0);
        assert(!map.regs[0x46]);
        assert(lcdb_lab_enable(&rail[first]) == 0);
        assert(lcdb_lab_is_enabled(&rail[!first]) == 0);
        assert(lcdb_lab_enable(&rail[!first]) == 0);
        assert(lcdb_lab_disable(&rail[first]) == 0);
        assert(map.regs[0x46] == 0x80);
        assert(lcdb_lab_disable(&rail[!first]) == 0);
        int writes=map.writes;
        assert(lcdb_lab_disable(&rail[!first]) == 0 && map.writes == writes);
        clean();
    }
    /* Every capture read must propagate error, without touching hardware. */
    int regs[] = {0x46, 0x10, 0x71, 0x81, 0x41};
    for (unsigned int i=0; i<sizeof(regs)/sizeof(regs[0]); i++) {
        setup(true); map.fail_read=regs[i];
        assert(qcom_lcdb_capture(&chip) == -EIO && !map.writes);
        clean();
    }
    /* Failed first-enable writes leave no phantom vote; retry works. */
    setup(true); map.regs[0x10]=3;
    assert(qcom_lcdb_capture(&chip)==-EIO && !map.writes); clean();
    setup(true); map.regs[0x10]=0;
    assert(qcom_lcdb_capture(&chip)==-ETIMEDOUT && !map.writes); clean();
    int writes[] = {0xd0, 0x41, 0x71, 0x81, 0x46};
    for (unsigned int i=0; i<sizeof(writes)/sizeof(writes[0]); i++) {
        setup(false); map.fail_write=writes[i];
        assert(lcdb_lab_enable(&rail[0]) == -EIO);
        assert(!chip.rail_enabled[0] && !map.regs[0x46]);
        assert(lcdb_lab_enable(&rail[0]) == 0);
        clean();
    }
    setup(false); map.timeout=true;
    assert(lcdb_lab_enable(&rail[0]) == -ETIMEDOUT);
    assert(!chip.rail_enabled[0] && !map.regs[0x46]);
    map.timeout=false; assert(lcdb_lab_enable(&rail[0]) == 0); clean();
    setup(false); map.short_circuit=true;
    assert(lcdb_lab_enable(&rail[0]) == -EIO);
    assert(!map.regs[0x46] && !chip.rail_enabled[0]); clean();
    setup(false); map.fail_read=0x10;
    assert(lcdb_lab_enable(&rail[0]) == -EIO && !map.regs[0x46]); clean();
    /* Rollback failure is reported; a retry re-reads the actual hardware. */
    setup(false); map.timeout=true; map.fail_write_n=10;
    assert(lcdb_lab_enable(&rail[0]) == -ETIMEDOUT);
    assert(map.regs[0x46] && !chip.rail_enabled[0]);
    map.timeout=false; map.regs[0x10]=1;
    assert(lcdb_lab_enable(&rail[0]) == 0 && chip.rail_enabled[0]); clean();
    /* A failing second vote must never power down its active sibling. */
    setup(true); assert(lcdb_lab_disable(&rail[1]) == 0);
    map.regs[0x10]=0;
    assert(lcdb_lab_enable(&rail[1]) == -ETIMEDOUT);
    assert(chip.rail_enabled[0] && !chip.rail_enabled[1] && !map.writes); clean();
    setup(true); map.fail_read=0x46;
    assert(lcdb_lab_is_enabled(&rail[0]) == -EIO); clean();
    setup(true);
    assert(lcdb_lab_disable(&rail[0]) == 0); map.fail_write=0x46;
    assert(lcdb_lab_disable(&rail[1]) == -EIO && chip.rail_enabled[1]);
    assert(lcdb_lab_disable(&rail[1]) == 0 && !chip.rail_enabled[1]); clean();
    /* Invalid range does no IO; mapping rounds up; errors preserve cache. */
    unsigned int sel=99;
    setup(true);
    assert(lcdb_lab_set_voltage(&rail[0],5500001,5500001,&sel)==-EINVAL);
    assert(sel==99 && !map.writes);
    assert(lcdb_lab_set_voltage(&rail[0],5500001,5550000,&sel)==0);
    assert(sel==22 && chip.lab_mv==5550 && lcdb_lab_get_voltage(&rail[0])==5550000);
    assert(map.write_regs[1]==0x41 && map.write_regs[3]==0x71);
    map.fail_write=0x71;
    assert(lcdb_lab_set_voltage(&rail[0],5600000,5600000,&sel)==-EIO);
    assert(chip.lab_mv==5550);
    map.fail_read=0x46;
    assert(lcdb_lab_set_voltage(&rail[1],5500000,5500000,&sel)==-EIO); clean();
    /* Two framework locks may call the shared driver concurrently. */
    setup(false); pthread_t a,b;
    assert(!pthread_create(&a,NULL,stress,&rail[0]));
    assert(!pthread_create(&b,NULL,stress,&rail[1]));
    assert(!pthread_join(a,NULL)); assert(!pthread_join(b,NULL));
    assert(!chip.rail_enabled[0] && !chip.rail_enabled[1] && !map.regs[0x46]); clean();
    puts("PASS: handoff, independent rails, error propagation, rollback, voltage bounds/headroom, concurrent callbacks");
}
'''
with tempfile.TemporaryDirectory(prefix='hanoip-lcdb-test-') as tmp:
    src = Path(tmp) / 'lcdb-test.c'
    exe = Path(tmp) / 'lcdb-test'
    src.write_text(preamble + helpers + tests)
    subprocess.run([os.environ.get('CC', 'cc'), '-std=c11', '-Wall', '-Wextra',
                    '-Werror', '-pthread', str(src), '-o', str(exe)], check=True)
    subprocess.run([str(exe)], check=True)
