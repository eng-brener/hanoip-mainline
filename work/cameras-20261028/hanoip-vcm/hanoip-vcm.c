// SPDX-License-Identifier: GPL-2.0
/*
 * VCM (focus motor) driver for the hanoip rear cameras, 29/10.
 *
 * Both motors answer at 0x0c and use the DW9768/DW9800 register map
 * (0x02 control, 0x03/0x04 10-bit position, 0x06/0x07/0x08 timing), but only
 * move with the vendor init lists, not with the mainline dw9768 sequence:
 *   wide (S5K4H7, slot 3): qtech_mot_hanoip_s5k4h7 list 10
 *     0xed=0xab, 0x02=1, 0x02=0 (+1 ms), 0x06=0x84, 0x07=0x01, 0x08=0x78
 *   main (S5KHM2, slot 0): ofilm_mot_hanoip_s5khm2 list 16
 *     0x02=1, 0x02=0 (+1 ms), 0x02=2, 0x06=0x40, 0x07=0x0b, 0x10=0x01
 * Measured (29/10, phone resting, text target): wide 260 focuses ~10-15 cm;
 * main 540 focuses ~20-30 cm (window 520-560, 0-200 is far out of focus,
 * >900 is the end stop). With no AF in the libcamera simple pipeline each
 * lens starts at a fixed mid-distance position (profile default).
 */

#include <linux/delay.h>
#include <linux/i2c.h>
#include <linux/module.h>
#include <linux/pm_runtime.h>
#include <linux/regulator/consumer.h>
#include <media/v4l2-ctrls.h>
#include <media/v4l2-device.h>
#include <media/v4l2-subdev.h>

#define HVCM_POS_REG		0x03
#define HVCM_MAX_POS		1023

struct hvcm_init {
	u8 reg, val;
	u16 delay_us;
};

struct hvcm_profile {
	const char *name;
	const struct hvcm_init *init;
	unsigned int n;
	int default_pos;
};

static const struct hvcm_init wide_init[] = {
	{ 0xed, 0xab, 0 }, { 0x02, 0x01, 0 }, { 0x02, 0x00, 1000 },
	{ 0x06, 0x84, 0 }, { 0x07, 0x01, 0 }, { 0x08, 0x78, 0 },
};

static const struct hvcm_init main_init[] = {
	{ 0x02, 0x01, 0 }, { 0x02, 0x00, 1000 }, { 0x02, 0x02, 0 },
	{ 0x06, 0x40, 0 }, { 0x07, 0x0b, 0 }, { 0x10, 0x01, 0 },
};

static const struct hvcm_profile wide_profile = {
	"wide", wide_init, ARRAY_SIZE(wide_init), 180,
};

static const struct hvcm_profile main_profile = {
	"main", main_init, ARRAY_SIZE(main_init), 450,
};

static int default_pos = -1;
module_param(default_pos, int, 0644);
MODULE_PARM_DESC(default_pos, "initial focus position for both lenses (-1 = per-lens default)");

static const char * const hvcm_supplies[] = { "vin", "vdd" };

struct hvcm {
	const struct hvcm_profile *p;
	struct regulator_bulk_data supplies[ARRAY_SIZE(hvcm_supplies)];
	struct v4l2_ctrl_handler ctrls;
	struct v4l2_ctrl *focus;
	struct v4l2_subdev sd;
};

static inline struct hvcm *sd_to_hvcm(struct v4l2_subdev *sd)
{
	return container_of(sd, struct hvcm, sd);
}

static int hvcm_set_pos(struct hvcm *v, u16 pos)
{
	struct i2c_client *client = v4l2_get_subdevdata(&v->sd);

	return i2c_smbus_write_word_swapped(client, HVCM_POS_REG, pos);
}

static int hvcm_init_hw(struct hvcm *v)
{
	struct i2c_client *client = v4l2_get_subdevdata(&v->sd);
	unsigned int i;
	int ret;

	for (i = 0; i < v->p->n; i++) {
		const struct hvcm_init *w = &v->p->init[i];

		ret = i2c_smbus_write_byte_data(client, w->reg, w->val);
		if (ret < 0) {
			dev_err(&client->dev, "%s init %u (0x%02x) failed: %d\n",
				v->p->name, i, w->reg, ret);
			return ret;
		}
		if (w->delay_us)
			usleep_range(w->delay_us, w->delay_us + 100);
	}
	return hvcm_set_pos(v, v->focus->val);
}

static int hvcm_runtime_suspend(struct device *dev)
{
	struct hvcm *v = sd_to_hvcm(dev_get_drvdata(dev));

	regulator_bulk_disable(ARRAY_SIZE(v->supplies), v->supplies);
	return 0;
}

static int hvcm_runtime_resume(struct device *dev)
{
	struct hvcm *v = sd_to_hvcm(dev_get_drvdata(dev));
	int ret;

	ret = regulator_bulk_enable(ARRAY_SIZE(v->supplies), v->supplies);
	if (ret)
		return ret;
	usleep_range(1000, 1100);	/* t_OPR */
	ret = hvcm_init_hw(v);
	if (ret)
		regulator_bulk_disable(ARRAY_SIZE(v->supplies), v->supplies);
	return ret;
}

static int hvcm_set_ctrl(struct v4l2_ctrl *ctrl)
{
	struct hvcm *v = container_of(ctrl->handler, struct hvcm, ctrls);
	struct device *dev = v->sd.dev;
	int ret;

	if (ctrl->id != V4L2_CID_FOCUS_ABSOLUTE)
		return -EINVAL;
	if (pm_runtime_get_if_in_use(dev) <= 0)
		return 0;	/* applied by hvcm_init_hw at power-on */
	ret = hvcm_set_pos(v, ctrl->val);
	pm_runtime_put_autosuspend(dev);
	return ret;
}

static const struct v4l2_ctrl_ops hvcm_ctrl_ops = {
	.s_ctrl = hvcm_set_ctrl,
};

static int hvcm_open(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
{
	return pm_runtime_resume_and_get(sd->dev);
}

static int hvcm_close(struct v4l2_subdev *sd, struct v4l2_subdev_fh *fh)
{
	pm_runtime_put_autosuspend(sd->dev);
	return 0;
}

static const struct v4l2_subdev_internal_ops hvcm_int_ops = {
	.open = hvcm_open,
	.close = hvcm_close,
};

static const struct v4l2_subdev_ops hvcm_ops = { };

static int hvcm_probe(struct i2c_client *client)
{
	struct device *dev = &client->dev;
	struct hvcm *v;
	unsigned int i;
	int ret;

	v = devm_kzalloc(dev, sizeof(*v), GFP_KERNEL);
	if (!v)
		return -ENOMEM;
	v->p = of_device_get_match_data(dev);

	for (i = 0; i < ARRAY_SIZE(hvcm_supplies); i++)
		v->supplies[i].supply = hvcm_supplies[i];
	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(v->supplies), v->supplies);
	if (ret)
		return dev_err_probe(dev, ret, "failed to get regulators\n");

	v4l2_i2c_subdev_init(&v->sd, client, &hvcm_ops);
	v->sd.flags |= V4L2_SUBDEV_FL_HAS_DEVNODE;
	v->sd.internal_ops = &hvcm_int_ops;
	v->sd.entity.function = MEDIA_ENT_F_LENS;

	v4l2_ctrl_handler_init(&v->ctrls, 1);
	v->focus = v4l2_ctrl_new_std(&v->ctrls, &hvcm_ctrl_ops,
				     V4L2_CID_FOCUS_ABSOLUTE, 0, HVCM_MAX_POS, 1,
				     clamp(default_pos >= 0 ? default_pos : v->p->default_pos,
					   0, HVCM_MAX_POS));
	if (v->ctrls.error) {
		ret = v->ctrls.error;
		goto free_ctrls;
	}
	v->sd.ctrl_handler = &v->ctrls;

	ret = media_entity_pads_init(&v->sd.entity, 0, NULL);
	if (ret)
		goto free_ctrls;

	pm_runtime_enable(dev);
	pm_runtime_set_autosuspend_delay(dev, 1000);
	pm_runtime_use_autosuspend(dev);

	/* Prove the address and the init list once at probe. */
	ret = pm_runtime_resume_and_get(dev);
	if (ret < 0)
		goto disable_pm;
	pm_runtime_put_autosuspend(dev);

	ret = v4l2_async_register_subdev(&v->sd);
	if (ret)
		goto disable_pm;
	dev_info(dev, "%s VCM ready, default position %d\n", v->p->name,
		 v->focus->val);
	return 0;

disable_pm:
	pm_runtime_disable(dev);
	media_entity_cleanup(&v->sd.entity);
free_ctrls:
	v4l2_ctrl_handler_free(&v->ctrls);
	return ret;
}

static void hvcm_remove(struct i2c_client *client)
{
	struct hvcm *v = sd_to_hvcm(i2c_get_clientdata(client));

	v4l2_async_unregister_subdev(&v->sd);
	v4l2_ctrl_handler_free(&v->ctrls);
	media_entity_cleanup(&v->sd.entity);
	pm_runtime_disable(&client->dev);
	if (!pm_runtime_status_suspended(&client->dev))
		hvcm_runtime_suspend(&client->dev);
	pm_runtime_set_suspended(&client->dev);
}

static const struct dev_pm_ops hvcm_pm_ops = {
	SET_RUNTIME_PM_OPS(hvcm_runtime_suspend, hvcm_runtime_resume, NULL)
};

static const struct of_device_id hvcm_of_match[] = {
	{ .compatible = "dongwoon,dw9768", .data = &wide_profile },
	{ .compatible = "dongwoon,dw9800", .data = &main_profile },
	{ }
};
MODULE_DEVICE_TABLE(of, hvcm_of_match);

static struct i2c_driver hvcm_driver = {
	.driver = {
		.name = "hanoip-vcm",
		.pm = &hvcm_pm_ops,
		.of_match_table = hvcm_of_match,
	},
	.probe = hvcm_probe,
	.remove = hvcm_remove,
};
module_i2c_driver(hvcm_driver);

MODULE_DESCRIPTION("hanoip rear camera VCM (vendor init lists)");
MODULE_LICENSE("GPL v2");
