// SPDX-License-Identifier: GPL-2.0-only
/*
 * Motorola hanoip camera bring-up probe.
 *
 * For one sensor described in DT: power it up in the vendor order (VIO,
 * VANA, VDIG, MCLK, reset release), read its chip ID over CCI, then power
 * it down again in reverse. Nothing is streamed and nothing stays on.
 * Built out of tree and loaded by hand; it has no module alias on purpose.
 */
#include <linux/clk.h>
#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/i2c.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/regulator/consumer.h>

#define CAMID_MCLK_HZ		24000000

struct camid {
	struct device *dev;
	struct regulator *vio, *vana, *vdig;
	struct clk *mclk;
	struct gpio_desc *reset;
};

static struct regulator *camid_supply(struct device *dev, const char *id)
{
	struct regulator *r = devm_regulator_get_optional(dev, id);

	return PTR_ERR(r) == -ENODEV ? NULL : r;
}

static int camid_read(struct i2c_client *c, u32 reg, u32 reg_bytes,
		      u32 val_bytes, u32 *val)
{
	u8 addr[2] = { reg >> 8, reg };
	u8 buf[2] = { };
	struct i2c_msg msgs[2] = {
		{ .addr = c->addr, .len = reg_bytes,
		  .buf = reg_bytes == 1 ? &addr[1] : addr },
		{ .addr = c->addr, .flags = I2C_M_RD, .len = val_bytes,
		  .buf = buf },
	};
	int ret = i2c_transfer(c->adapter, msgs, 2);

	if (ret != 2)
		return ret < 0 ? ret : -EIO;
	*val = val_bytes == 1 ? buf[0] : buf[0] << 8 | buf[1];
	return 0;
}

static void camid_power_off(struct camid *cam)
{
	gpiod_set_value_cansleep(cam->reset, 1);
	usleep_range(1000, 2000);
	clk_disable_unprepare(cam->mclk);
	if (cam->vdig)
		regulator_disable(cam->vdig);
	if (cam->vana)
		regulator_disable(cam->vana);
	regulator_disable(cam->vio);
}

static int camid_power_on(struct camid *cam)
{
	int ret;

	ret = regulator_enable(cam->vio);
	if (ret)
		return ret;
	usleep_range(1000, 2000);
	if (cam->vana) {
		ret = regulator_enable(cam->vana);
		if (ret)
			goto err_vio;
	}
	if (cam->vdig) {
		ret = regulator_enable(cam->vdig);
		if (ret)
			goto err_vana;
	}
	usleep_range(1000, 2000);
	ret = clk_prepare_enable(cam->mclk);
	if (ret)
		goto err_vdig;
	usleep_range(1000, 2000);
	gpiod_set_value_cansleep(cam->reset, 0);
	/* Samsung parts want 8192 MCLK cycles, OmniVision ~8 ms; be generous. */
	msleep(20);
	return 0;

err_vdig:
	if (cam->vdig)
		regulator_disable(cam->vdig);
err_vana:
	if (cam->vana)
		regulator_disable(cam->vana);
err_vio:
	regulator_disable(cam->vio);
	return ret;
}

static int camid_probe(struct i2c_client *client)
{
	struct device *dev = &client->dev;
	u32 reg, reg_bytes = 2, val_bytes = 2, want, uv, id = 0;
	const char *label = "sensor";
	struct camid *cam;
	int ret, i;

	cam = devm_kzalloc(dev, sizeof(*cam), GFP_KERNEL);
	if (!cam)
		return -ENOMEM;
	cam->dev = dev;

	of_property_read_string(dev->of_node, "label", &label);
	if (of_property_read_u32(dev->of_node, "hanoip,id-reg", &reg) ||
	    of_property_read_u32(dev->of_node, "hanoip,id-value", &want))
		return dev_err_probe(dev, -EINVAL, "missing hanoip,id-reg/-value\n");
	of_property_read_u32(dev->of_node, "hanoip,id-reg-bytes", &reg_bytes);
	of_property_read_u32(dev->of_node, "hanoip,id-bytes", &val_bytes);

	cam->vio = devm_regulator_get(dev, "vio");
	if (IS_ERR(cam->vio))
		return dev_err_probe(dev, PTR_ERR(cam->vio), "vio\n");
	cam->vana = camid_supply(dev, "vana");
	if (IS_ERR(cam->vana))
		return dev_err_probe(dev, PTR_ERR(cam->vana), "vana\n");
	cam->vdig = camid_supply(dev, "vdig");
	if (IS_ERR(cam->vdig))
		return dev_err_probe(dev, PTR_ERR(cam->vdig), "vdig\n");
	if (cam->vdig && !of_property_read_u32(dev->of_node, "hanoip,vdig-microvolt", &uv)) {
		ret = regulator_set_voltage(cam->vdig, uv, uv);
		if (ret)
			return dev_err_probe(dev, ret, "vdig %u uV\n", uv);
	}

	cam->mclk = devm_clk_get(dev, NULL);
	if (IS_ERR(cam->mclk))
		return dev_err_probe(dev, PTR_ERR(cam->mclk), "mclk\n");
	ret = clk_set_rate(cam->mclk, CAMID_MCLK_HZ);
	if (ret)
		return dev_err_probe(dev, ret, "mclk rate\n");

	/* Held in reset (logical 1 = asserted) until the rails are up. */
	cam->reset = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(cam->reset))
		return dev_err_probe(dev, PTR_ERR(cam->reset), "reset\n");

	ret = camid_power_on(cam);
	if (ret)
		return dev_err_probe(dev, ret, "power on\n");

	for (i = 0; i < 3; i++) {
		ret = camid_read(client, reg, reg_bytes, val_bytes, &id);
		if (!ret)
			break;
		msleep(5);
	}
	camid_power_off(cam);

	if (ret)
		dev_err(dev, "%s @0x%02x: no answer reading 0x%04x (%d), MCLK %lu Hz\n",
			label, client->addr, reg, ret, clk_get_rate(cam->mclk));
	else
		dev_info(dev, "%s @0x%02x: chip ID 0x%04x (expected 0x%04x) %s\n",
			 label, client->addr, id, want, id == want ? "OK" : "MISMATCH");
	return 0;
}

static const struct of_device_id camid_of_match[] = {
	{ .compatible = "hanoip,camid" },
	{ }
};

static struct i2c_driver camid_driver = {
	.driver = {
		.name = "hanoip-camid",
		.of_match_table = camid_of_match,
	},
	.probe = camid_probe,
};
module_i2c_driver(camid_driver);

MODULE_DESCRIPTION("Motorola hanoip camera chip-ID probe (bring-up only)");
MODULE_LICENSE("GPL");
