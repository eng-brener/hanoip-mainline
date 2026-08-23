// SPDX-License-Identifier: GPL-2.0-only
/*
 * Qualcomm PM6150L LCD Bias regulator - full enable/ramp
 * Based on downstream qpnp-lcdb-regulator.c (hanoip 5500mV)
 */
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/interrupt.h>
#include <linux/mod_devicetable.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/regmap.h>
#include <linux/regulator/driver.h>
#include <linux/regulator/of_regulator.h>
#include <linux/of.h>

#define PM6150L_LCDB_BASE 0xec00
#define INT_RT_STATUS_REG 0x10
#define VREG_OK_RT_STS_BIT BIT(0)
#define SC_ERROR_RT_STS_BIT BIT(1)
#define LCDB_BST_OUTPUT_VOLTAGE_REG 0x41
#define LCDB_BST_MASK GENMASK(5,0)
#define LCDB_MODULE_RDY_REG 0x45
#define MODULE_RDY_BIT BIT(7)
#define LCDB_ENABLE_CTL1_REG 0x46
#define MODULE_EN_BIT BIT(7)
#define HWEN_RDY_BIT BIT(6)
#define LCDB_LDO_OUTPUT_VOLTAGE_REG 0x71
#define LCDB_NCP_OUTPUT_VOLTAGE_REG 0x81
#define SET_OUTPUT_VOLTAGE_MASK GENMASK(4,0)
#define LCDB_SEC_ACCESS_REG 0xD0
#define SEC_UNLOCK 0xA5

struct qcom_lcdb {
	struct device *dev;
	struct regmap *regmap;
	u16 base;
	struct regulator_dev *rdev_lab;
	struct regulator_dev *rdev_ibb;
	int lab_mv;
	int ibb_mv;
	bool enabled;
	int refcnt;
};

static int mv_to_sel(int mv)
{
	if (mv < 4950)
		return (mv - 4000) / 100;
	else
		return (mv - 4950) / 50 + 0xA;
}
static int sel_to_mv(int sel)
{
	sel &= 0x1F;
	if (sel < 0xA)
		return 4000 + sel * 100;
	else
		return 4950 + (sel - 0xA) * 50;
}
static int bst_mv(int lab, int ibb)
{
	int mx = lab > ibb ? lab : ibb;
	int bst = mx + 150;
	if (bst < 4700) bst = 4700;
	if (bst > 6275) bst = 6275;
	return bst;
}
static int qcom_lcdb_sec_write(struct qcom_lcdb *lcdb, u16 reg, u8 val)
{
	int ret;
	ret = regmap_write(lcdb->regmap, lcdb->base + LCDB_SEC_ACCESS_REG, SEC_UNLOCK);
	if (ret) return ret;
	return regmap_write(lcdb->regmap, lcdb->base + reg, val);
}
static int qcom_lcdb_set_lab(struct qcom_lcdb *lcdb, int mv)
{
	int sel = mv_to_sel(mv);
	u8 v = sel & SET_OUTPUT_VOLTAGE_MASK;
	return qcom_lcdb_sec_write(lcdb, LCDB_LDO_OUTPUT_VOLTAGE_REG, v);
}
static int qcom_lcdb_set_ibb(struct qcom_lcdb *lcdb, int mv)
{
	int sel = mv_to_sel(mv);
	u8 v = sel & SET_OUTPUT_VOLTAGE_MASK;
	return qcom_lcdb_sec_write(lcdb, LCDB_NCP_OUTPUT_VOLTAGE_REG, v);
}
static int qcom_lcdb_set_bst(struct qcom_lcdb *lcdb, int mv)
{
	int sel = (mv - 4700) / 25;
	if (sel < 0) sel = 0;
	if (sel > 0x3F) sel = 0x3F;
	return qcom_lcdb_sec_write(lcdb, LCDB_BST_OUTPUT_VOLTAGE_REG, sel & LCDB_BST_MASK);
}
static int qcom_lcdb_enable(struct qcom_lcdb *lcdb)
{
	int ret, timeout;
	u8 val;
	int bst = bst_mv(lcdb->lab_mv, lcdb->ibb_mv);
	if (lcdb->enabled)
		return 0;
	// adopt voltages if not yet set, read current hw
	if (lcdb->lab_mv == 0) lcdb->lab_mv = 5500;
	if (lcdb->ibb_mv == 0) lcdb->ibb_mv = 5500;
	bst = bst_mv(lcdb->lab_mv, lcdb->ibb_mv);
	ret = qcom_lcdb_set_bst(lcdb, bst);
	if (ret) return ret;
	ret = qcom_lcdb_set_lab(lcdb, lcdb->lab_mv);
	if (ret) return ret;
	ret = qcom_lcdb_set_ibb(lcdb, lcdb->ibb_mv);
	if (ret) return ret;
	ret = qcom_lcdb_sec_write(lcdb, LCDB_ENABLE_CTL1_REG, MODULE_EN_BIT);
	if (ret) return ret;
	timeout = 20;
	while (timeout--) {
		ret = regmap_read(lcdb->regmap, lcdb->base + INT_RT_STATUS_REG, (unsigned int*)&val);
		if (ret) break;
		if (val & VREG_OK_RT_STS_BIT) break;
		usleep_range(1000, 1500);
	}
	if (timeout <= 0) {
		dev_err(lcdb->dev, "VREG_OK timeout val=0x%x\n", val);
		return -ETIMEDOUT;
	}
	lcdb->enabled = true;
	dev_info(lcdb->dev, "LCDB enabled LAB %d IBB %d BST %d VREG_OK\n", lcdb->lab_mv, lcdb->ibb_mv, bst);
	return 0;
}
static int qcom_lcdb_disable(struct qcom_lcdb *lcdb)
{
	int ret;
	if (!lcdb->enabled) return 0;
	ret = qcom_lcdb_sec_write(lcdb, LCDB_ENABLE_CTL1_REG, 0);
	if (ret) return ret;
	lcdb->enabled = false;
	dev_info(lcdb->dev, "LCDB disabled\n");
	return 0;
}
static void qcom_lcdb_capture(struct qcom_lcdb *lcdb)
{
	unsigned int v;
	int lab, ibb, bst;
	regmap_read(lcdb->regmap, lcdb->base + LCDB_ENABLE_CTL1_REG, &v);
	dev_info(lcdb->dev, "LCDB capture EN 0x%x RDY 0x%x\n", v & 0xC0, v);
	regmap_read(lcdb->regmap, lcdb->base + INT_RT_STATUS_REG, &v);
	dev_info(lcdb->dev, "LCDB INT_RT 0x%x VREG_OK %d SC %d\n", v, !!(v & VREG_OK_RT_STS_BIT), !!(v & SC_ERROR_RT_STS_BIT));
	regmap_read(lcdb->regmap, lcdb->base + LCDB_LDO_OUTPUT_VOLTAGE_REG, &v);
	lab = sel_to_mv(v); regmap_read(lcdb->regmap, lcdb->base + LCDB_NCP_OUTPUT_VOLTAGE_REG, &v); ibb = sel_to_mv(v);
	regmap_read(lcdb->regmap, lcdb->base + LCDB_BST_OUTPUT_VOLTAGE_REG, &v); bst = 4700 + (v & 0x3F)*25;
	dev_info(lcdb->dev, "LCDB voltages LAB %d IBB %d BST %d\n", lab, ibb, bst);
	if (lab > 4000) lcdb->lab_mv = lab;
	if (ibb > 4000) lcdb->ibb_mv = ibb;
}

/* regulator ops shared */
static int lcdb_lab_enable(struct regulator_dev *rdev) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); lcdb->refcnt++; if (lcdb->refcnt==1) return qcom_lcdb_enable(lcdb); return 0; }
static int lcdb_lab_disable(struct regulator_dev *rdev) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); if (lcdb->refcnt>0) lcdb->refcnt--; if (lcdb->refcnt==0) return qcom_lcdb_disable(lcdb); return 0; }
static int lcdb_lab_is_enabled(struct regulator_dev *rdev) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); unsigned int v; regmap_read(lcdb->regmap, lcdb->base+LCDB_ENABLE_CTL1_REG, &v); return !!(v & MODULE_EN_BIT); }
static int lcdb_lab_get_voltage(struct regulator_dev *rdev) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); return lcdb->lab_mv*1000; }
static int lcdb_lab_set_voltage(struct regulator_dev *rdev, int min_uV, int max_uV, unsigned int *sel) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); int mv=min_uV/1000; lcdb->lab_mv=mv; if (lcdb->enabled) return qcom_lcdb_set_lab(lcdb,mv); return 0; }
static int lcdb_ibb_get_voltage(struct regulator_dev *rdev) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); return lcdb->ibb_mv*1000; }
static int lcdb_ibb_set_voltage(struct regulator_dev *rdev, int min_uV, int max_uV, unsigned int *sel) { struct qcom_lcdb *lcdb = rdev_get_drvdata(rdev); int mv=min_uV/1000; lcdb->ibb_mv=mv; if (lcdb->enabled) return qcom_lcdb_set_ibb(lcdb,mv); return 0; }

static const struct regulator_ops lab_ops = {
	.enable = lcdb_lab_enable,
	.disable = lcdb_lab_disable,
	.is_enabled = lcdb_lab_is_enabled,
	.get_voltage = lcdb_lab_get_voltage,
	.set_voltage = lcdb_lab_set_voltage,
	.list_voltage = regulator_list_voltage_linear_range,
};
static const struct regulator_ops ibb_ops = {
	.enable = lcdb_lab_enable,
	.disable = lcdb_lab_disable,
	.is_enabled = lcdb_lab_is_enabled,
	.get_voltage = lcdb_ibb_get_voltage,
	.set_voltage = lcdb_ibb_set_voltage,
	.list_voltage = regulator_list_voltage_linear_range,
};
static const struct linear_range lab_ranges[] = {
	REGULATOR_LINEAR_RANGE(4000000, 0, 0x9, 100000),
	REGULATOR_LINEAR_RANGE(4950000, 0xA, 0x1F, 50000),
};

static const struct regulator_desc lab_desc = {
	.name = "lcdb_lab",
	.of_match = "lab",
	.regulators_node = "lab",
	.ops = &lab_ops,
	.type = REGULATOR_VOLTAGE,
	.owner = THIS_MODULE,
	.linear_ranges = lab_ranges,
	.n_linear_ranges = ARRAY_SIZE(lab_ranges),
	.n_voltages = 32,
	.min_uV = 4000000,
	.uV_step = 100000,
};
static const struct regulator_desc ibb_desc = {
	.name = "lcdb_ibb",
	.of_match = "ibb",
	.regulators_node = "ibb",
	.ops = &ibb_ops,
	.type = REGULATOR_VOLTAGE,
	.owner = THIS_MODULE,
	.linear_ranges = lab_ranges,
	.n_linear_ranges = ARRAY_SIZE(lab_ranges),
	.n_voltages = 32,
	.min_uV = 4000000,
	.uV_step = 100000,
};

static int qcom_lcdb_probe(struct platform_device *pdev)
{
	struct qcom_lcdb *lcdb;
	struct regulator_config cfg = {};
	struct regmap *regmap;
	regmap = dev_get_regmap(pdev->dev.parent, NULL);
	if (!regmap) return -ENODEV;
	lcdb = devm_kzalloc(&pdev->dev, sizeof(*lcdb), GFP_KERNEL);
	if (!lcdb) return -ENOMEM;
	lcdb->dev = &pdev->dev;
	lcdb->regmap = regmap;
	lcdb->base = PM6150L_LCDB_BASE;
	lcdb->lab_mv = 5500; lcdb->ibb_mv = 5500;
	dev_set_drvdata(&pdev->dev, lcdb);
	qcom_lcdb_capture(lcdb);
	cfg.dev = &pdev->dev;
	cfg.driver_data = lcdb;
	cfg.of_node = of_get_child_by_name(pdev->dev.of_node, "lab");
	if (!cfg.of_node) cfg.of_node = pdev->dev.of_node;
	lcdb->rdev_lab = devm_regulator_register(&pdev->dev, &lab_desc, &cfg);
	if (IS_ERR(lcdb->rdev_lab)) return PTR_ERR(lcdb->rdev_lab);
	of_node_put(cfg.of_node);
	cfg.of_node = of_get_child_by_name(pdev->dev.of_node, "ibb");
	lcdb->rdev_ibb = devm_regulator_register(&pdev->dev, &ibb_desc, &cfg);
	if (IS_ERR(lcdb->rdev_ibb)) return PTR_ERR(lcdb->rdev_ibb);
	of_node_put(cfg.of_node);
	// adopt if already enabled by ABL
	{
		unsigned int v; regmap_read(lcdb->regmap, lcdb->base+LCDB_ENABLE_CTL1_REG, &v);
		if (v & MODULE_EN_BIT) { lcdb->enabled=true; lcdb->refcnt=2; dev_info(lcdb->dev, "LCDB adopted enabled state from ABL\n"); }
	}
	dev_info(lcdb->dev, "PM6150L LCDB probed full\n");
	return 0;
}
static const struct of_device_id qcom_lcdb_of_match[] = { { .compatible = "qcom,pm6150l-lcdb", }, { } };
MODULE_DEVICE_TABLE(of, qcom_lcdb_of_match);
static struct platform_driver qcom_lcdb_regulator_driver = {
	.driver = { .name = "qcom-pm6150l-lcdb", .of_match_table = qcom_lcdb_of_match, .probe_type = PROBE_PREFER_ASYNCHRONOUS, },
	.probe = qcom_lcdb_probe,
};
module_platform_driver(qcom_lcdb_regulator_driver);
MODULE_DESCRIPTION("Qualcomm PM6150L LCD bias regulator full");
MODULE_LICENSE("GPL v2");
