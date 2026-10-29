// SPDX-License-Identifier: GPL-2.0
/*
 * Table-driven driver for the hanoip OV32B (front) and S5KHM2 (rear main)
 * sensors, built on what the S5K4H7 bring-up taught (29/10):
 *   - the tables come from the vendor sensormodule.bin through
 *     decode-regs-v3/gen-sensor-tables, which label every list by section
 *     (init, mode, stream on/off) and keep per-entry width and delay;
 *   - one fixed mode per sensor, the 30 fps binned one;
 *   - timing is reported so that (width + hblank) / pixel_rate equals the
 *     real line time (1 / (fps * frame_length)), which is what libcamera
 *     uses for exposure;
 *   - rotation/orientation come from DT (v4l2_fwnode), crop/native size are
 *     the output size.
 * Bayer order: OV32B BGGR, S5KHM2 GBRG (both confirmed 29/10). The writable
 * "bayer" parameter (0 BGGR, 1 GBRG, 2 GRBG, 3 RGGB) overrides BOTH sensors
 * and is only meant for bring-up.
 * Gain scales are not confirmed either; codes are passed through.
 */

#include <linux/clk.h>
#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/i2c.h>
#include <linux/module.h>
#include <linux/pm_runtime.h>
#include <linux/regulator/consumer.h>
#include <linux/units.h>
#include <media/v4l2-ctrls.h>
#include <media/v4l2-device.h>
#include <media/v4l2-fwnode.h>

struct hcam_reg {
	u16 addr;
	u16 val;
	u8 bits;
	u32 delay_us;
};

/* gen-sensor-tables.py emits "struct <prefix>_reg"; both map to hcam_reg. */
#define ov32b_reg hcam_reg
#define s5khm2_reg hcam_reg
#define s5khm2c_reg hcam_reg
#define s5khm2v_reg hcam_reg
#include "ov32b-regs.h"
#include "s5khm2-regs.h"
#include "s5khm2c-regs.h"
#include "s5khm2v-regs.h"

#define HCAM_TABLE(t) { t, ARRAY_SIZE(t) }

struct hcam_table {
	const struct hcam_reg *regs;
	unsigned int n;
};

struct hcam_sensor {
	const char *name;
	u16 id_reg;
	u16 id_val;
	u32 vdig_uv;		/* 0: leave the regulator voltage alone */
	u16 soft_reset_reg;	/* sleep after this write (0: none) */
	struct hcam_table init, mode, stream_on, stream_off;
	u32 width, height;
	u32 lanes;
	s64 link_freq;
	u64 pixel_rate;
	u32 line_length;	/* in pixel_rate units */
	u32 frame_length;
	u32 exposure_margin;
	u16 exposure_reg;
	u8 exposure_bytes;
	u16 frame_length_reg;
	u16 gain_reg;
	u32 gain_min, gain_max, gain_def;
	u32 bayer_def;
};

/*
 * OV32B, list 2 of qtech_mot_hanoip_ov32b: 3264x2448 RAW10, 30.034 fps,
 * VTS 2664 (0x380e), 4 lanes at 414 MHz (outClk 331.2 MHz). Line time
 * 1 / (30.034 * 2664) = 12.498 us = 5000 / 400 MHz. Exposure in lines at
 * 0x3500..0x3502 (mode default 0x0a48 = VTS - 32). Gain 0x3508/0x3509,
 * assumed 0x0100 = 1x (to be measured).
 */
static const struct hcam_sensor ov32b_sensor = {
	.name = "ov32b",
	.id_reg = 0x300b, .id_val = 0x3242,
	.soft_reset_reg = 0x0103,
	.init = HCAM_TABLE(ov32b_init),
	.mode = HCAM_TABLE(ov32b_mode_3264x2448),
	.stream_on = HCAM_TABLE(ov32b_stream_on),
	.stream_off = HCAM_TABLE(ov32b_stream_off),
	.width = 3264, .height = 2448, .lanes = 4,
	.link_freq = 414000000,
	.pixel_rate = 400000000, .line_length = 5000, .frame_length = 2664,
	.exposure_margin = 32,
	.exposure_reg = 0x3500, .exposure_bytes = 3,
	.frame_length_reg = 0x380e,
	.gain_reg = 0x3508, .gain_min = 0x100, .gain_max = 0xf80, .gain_def = 0x100,
	/* BGGR confirmed on a raw frame (RGGB turns skin blue), 29/10. */
	.bayer_def = 0,
};

/*
 * S5KHM2, list 2 of ofilm_mot_hanoip_s5khm2: 4000x3000 RAW10 (3x3 binning,
 * 0x0900 = 0x1233), 30.062 fps, FLL 3200 (0x0340), LLP 16632 (0x0342),
 * D-PHY (0x0111 = 2) 3 lanes at 1012.32 MHz (outClk 607.392 MHz).
 * 16632 * 3200 * 30.062 = 1600 MHz. CCS exposure 0x0202, gain 0x0204
 * (Samsung: 32 = 1x). Stream on also writes 0x0101 = 3 (H+V flip).
 * VDIG is L6A at 1.104 V as on Android.
 */
static const struct hcam_sensor s5khm2_sensor = {
	.name = "s5khm2",
	.id_reg = 0x0000, .id_val = 0x1ad2,
	.vdig_uv = 1104000,
	.init = HCAM_TABLE(s5khm2_init),
	.mode = HCAM_TABLE(s5khm2_mode_4000x3000),
	.stream_on = HCAM_TABLE(s5khm2_stream_on),
	.stream_off = HCAM_TABLE(s5khm2_stream_off),
	.width = 4000, .height = 3000, .lanes = 3,
	.link_freq = 1012320000,
	.pixel_rate = 1600000000ULL, .line_length = 16632, .frame_length = 3200,
	.exposure_margin = 16,
	.exposure_reg = 0x0202, .exposure_bytes = 2,
	.frame_length_reg = 0x0340,
	.gain_reg = 0x0204, .gain_min = 32, .gain_max = 512, .gain_def = 32,
	/* G at 00/11; GBRG confirmed in the app (blue stays blue), 29/10. */
	.bayer_def = 1,
};

/*
 * The vendor ships three S5KHM2 module bins with different init (TnP) and
 * mode tables: s5khm2 (init 659), s5khm2_compatible (2614) and s5khm2_v2
 * (293). Which one this unit needs is not decoded yet; hm2_variant picks
 * the tables at every stream start (0, 1, 2 in that order).
 */
static int hm2_variant;
module_param(hm2_variant, int, 0644);
MODULE_PARM_DESC(hm2_variant, "S5KHM2 tables: 0 s5khm2, 1 s5khm2_compatible, 2 s5khm2_v2");

static const struct hcam_table hm2_variants[3][4] = {
	{ HCAM_TABLE(s5khm2_init), HCAM_TABLE(s5khm2_mode_4000x3000),
	  HCAM_TABLE(s5khm2_stream_on), HCAM_TABLE(s5khm2_stream_off) },
	{ HCAM_TABLE(s5khm2c_init), HCAM_TABLE(s5khm2c_mode_4000x3000),
	  HCAM_TABLE(s5khm2c_stream_on), HCAM_TABLE(s5khm2c_stream_off) },
	{ HCAM_TABLE(s5khm2v_init), HCAM_TABLE(s5khm2v_mode_4000x3000),
	  HCAM_TABLE(s5khm2v_stream_on), HCAM_TABLE(s5khm2v_stream_off) },
};

static int bayer = -1;
module_param(bayer, int, 0644);
MODULE_PARM_DESC(bayer, "Bayer order override: 0 BGGR, 1 GBRG, 2 GRBG, 3 RGGB (-1 sensor default)");

static const u32 hcam_codes[] = {
	MEDIA_BUS_FMT_SBGGR10_1X10, MEDIA_BUS_FMT_SGBRG10_1X10,
	MEDIA_BUS_FMT_SGRBG10_1X10, MEDIA_BUS_FMT_SRGGB10_1X10,
};

struct hcam {
	struct device *dev;
	const struct hcam_sensor *s;
	struct clk *eclk;
	struct gpio_desc *rst_gpio;
	struct regulator_bulk_data supplies[3];
	struct v4l2_subdev subdev;
	struct media_pad pad;
	struct v4l2_ctrl_handler ctrl_handler;
	struct mutex mutex;
	struct v4l2_ctrl *exposure;
	s64 link_freq_menu[1];
	bool streaming;
};

static inline struct hcam *to_hcam(struct v4l2_subdev *sd)
{
	return container_of(sd, struct hcam, subdev);
}

static u32 hcam_code(struct hcam *h)
{
	int b = bayer >= 0 && bayer < 4 ? bayer : h->s->bayer_def;

	return hcam_codes[b];
}

static int hcam_write(struct hcam *h, u16 addr, u32 val, unsigned int bytes)
{
	struct i2c_client *client = v4l2_get_subdevdata(&h->subdev);
	u8 buf[6] = { addr >> 8, addr & 0xff };
	struct i2c_msg msg = { .addr = client->addr, .len = 2 + bytes, .buf = buf };
	unsigned int i;

	for (i = 0; i < bytes; i++)
		buf[2 + i] = val >> (8 * (bytes - 1 - i));
	return i2c_transfer(client->adapter, &msg, 1) == 1 ? 0 : -EIO;
}

static int hcam_read16(struct hcam *h, u16 addr, u16 *val)
{
	struct i2c_client *client = v4l2_get_subdevdata(&h->subdev);
	u8 wbuf[2] = { addr >> 8, addr & 0xff }, rbuf[2] = { 0 };
	struct i2c_msg msgs[2] = {
		{ .addr = client->addr, .len = 2, .buf = wbuf },
		{ .addr = client->addr, .flags = I2C_M_RD, .len = 2, .buf = rbuf },
	};

	if (i2c_transfer(client->adapter, msgs, 2) != 2)
		return -EIO;
	*val = (rbuf[0] << 8) | rbuf[1];
	return 0;
}

static int hcam_write_table(struct hcam *h, const struct hcam_table *t)
{
	unsigned int i;
	int ret;

	for (i = 0; i < t->n; i++) {
		const struct hcam_reg *r = &t->regs[i];

		ret = hcam_write(h, r->addr, r->val, r->bits / 8);
		if (ret) {
			dev_err(h->dev, "write %u/%u (0x%04x) failed\n",
				i, t->n, r->addr);
			return ret;
		}
		if (h->s->soft_reset_reg && r->addr == h->s->soft_reset_reg)
			usleep_range(5000, 6000);
		else if (r->delay_us)
			usleep_range(r->delay_us, r->delay_us + r->delay_us / 10 + 10);
	}
	return 0;
}

static int hcam_power_on(struct device *dev)
{
	struct v4l2_subdev *sd = i2c_get_clientdata(to_i2c_client(dev));
	struct hcam *h = to_hcam(sd);
	int ret;

	gpiod_set_value_cansleep(h->rst_gpio, 1);
	ret = regulator_bulk_enable(ARRAY_SIZE(h->supplies), h->supplies);
	if (ret)
		return ret;
	ret = clk_prepare_enable(h->eclk);
	if (ret) {
		regulator_bulk_disable(ARRAY_SIZE(h->supplies), h->supplies);
		return ret;
	}
	usleep_range(1000, 2000);
	gpiod_set_value_cansleep(h->rst_gpio, 0);
	msleep(25);
	return 0;
}

static int hcam_power_off(struct device *dev)
{
	struct v4l2_subdev *sd = i2c_get_clientdata(to_i2c_client(dev));
	struct hcam *h = to_hcam(sd);

	gpiod_set_value_cansleep(h->rst_gpio, 1);
	clk_disable_unprepare(h->eclk);
	regulator_bulk_disable(ARRAY_SIZE(h->supplies), h->supplies);
	return 0;
}

static const struct hcam_table *hcam_tables(struct hcam *h, int which)
{
	const struct hcam_table *t[4] = {
		&h->s->init, &h->s->mode, &h->s->stream_on, &h->s->stream_off,
	};

	if (h->s == &s5khm2_sensor && hm2_variant > 0 && hm2_variant < 3)
		return &hm2_variants[hm2_variant][which];
	return t[which];
}

static int hcam_start_stream(struct hcam *h)
{
	int ret;

	if (h->s == &s5khm2_sensor)
		dev_info(h->dev, "s5khm2 tables: variant %d, init %u writes\n",
			 hm2_variant, hcam_tables(h, 0)->n);
	ret = hcam_write_table(h, hcam_tables(h, 0));
	if (ret)
		return ret;
	ret = hcam_write_table(h, hcam_tables(h, 1));
	if (ret)
		return ret;
	ret = __v4l2_ctrl_handler_setup(h->subdev.ctrl_handler);
	if (ret)
		return ret;
	ret = hcam_write_table(h, hcam_tables(h, 2));
	if (ret)
		return ret;
	usleep_range(30000, 35000);
	return 0;
}

static int hcam_s_stream(struct v4l2_subdev *sd, int on)
{
	struct hcam *h = to_hcam(sd);
	int ret = 0;

	mutex_lock(&h->mutex);
	if (h->streaming == on)
		goto unlock;

	if (on) {
		ret = pm_runtime_resume_and_get(h->dev);
		if (ret < 0)
			goto unlock;
		ret = hcam_start_stream(h);
		if (ret) {
			hcam_write_table(h, hcam_tables(h, 3));
			pm_runtime_put(h->dev);
			goto unlock;
		}
	} else {
		hcam_write_table(h, hcam_tables(h, 3));
		pm_runtime_put(h->dev);
	}
	h->streaming = on;
unlock:
	mutex_unlock(&h->mutex);
	return ret;
}

static int hcam_set_ctrl(struct v4l2_ctrl *ctrl)
{
	struct hcam *h = container_of(ctrl->handler, struct hcam, ctrl_handler);
	const struct hcam_sensor *s = h->s;
	int ret;

	if (ctrl->id == V4L2_CID_VBLANK) {
		s64 max = s->height + ctrl->val - s->exposure_margin;

		__v4l2_ctrl_modify_range(h->exposure, h->exposure->minimum, max,
					 h->exposure->step,
					 min_t(s64, h->exposure->default_value, max));
	}

	if (pm_runtime_get_if_in_use(h->dev) <= 0)
		return 0;

	switch (ctrl->id) {
	case V4L2_CID_EXPOSURE:
		ret = hcam_write(h, s->exposure_reg, ctrl->val, s->exposure_bytes);
		break;
	case V4L2_CID_ANALOGUE_GAIN:
		ret = hcam_write(h, s->gain_reg, ctrl->val, 2);
		break;
	case V4L2_CID_VBLANK:
		ret = hcam_write(h, s->frame_length_reg, s->height + ctrl->val, 2);
		break;
	default:
		ret = -EINVAL;
		break;
	}

	pm_runtime_put(h->dev);
	return ret;
}

static const struct v4l2_ctrl_ops hcam_ctrl_ops = {
	.s_ctrl = hcam_set_ctrl,
};

static void hcam_fill_fmt(struct hcam *h, struct v4l2_mbus_framefmt *f)
{
	f->width = h->s->width;
	f->height = h->s->height;
	f->code = hcam_code(h);
	f->field = V4L2_FIELD_NONE;
	f->colorspace = V4L2_COLORSPACE_RAW;
}

static int hcam_enum_mbus_code(struct v4l2_subdev *sd,
			       struct v4l2_subdev_state *state,
			       struct v4l2_subdev_mbus_code_enum *code)
{
	if (code->index)
		return -EINVAL;
	code->code = hcam_code(to_hcam(sd));
	return 0;
}

static int hcam_enum_frame_size(struct v4l2_subdev *sd,
				struct v4l2_subdev_state *state,
				struct v4l2_subdev_frame_size_enum *fse)
{
	struct hcam *h = to_hcam(sd);

	if (fse->index || fse->code != hcam_code(h))
		return -EINVAL;
	fse->min_width = fse->max_width = h->s->width;
	fse->min_height = fse->max_height = h->s->height;
	return 0;
}

static int hcam_get_fmt(struct v4l2_subdev *sd, struct v4l2_subdev_state *state,
			struct v4l2_subdev_format *fmt)
{
	hcam_fill_fmt(to_hcam(sd), &fmt->format);
	return 0;
}

static int hcam_get_selection(struct v4l2_subdev *sd,
			      struct v4l2_subdev_state *state,
			      struct v4l2_subdev_selection *sel)
{
	struct hcam *h = to_hcam(sd);

	if (sel->pad)
		return -EINVAL;
	switch (sel->target) {
	case V4L2_SEL_TGT_CROP:
	case V4L2_SEL_TGT_CROP_DEFAULT:
	case V4L2_SEL_TGT_CROP_BOUNDS:
	case V4L2_SEL_TGT_NATIVE_SIZE:
		sel->r = (struct v4l2_rect) { 0, 0, h->s->width, h->s->height };
		return 0;
	default:
		return -EINVAL;
	}
}

static const struct v4l2_subdev_video_ops hcam_video_ops = {
	.s_stream = hcam_s_stream,
};

static const struct v4l2_subdev_pad_ops hcam_pad_ops = {
	.enum_mbus_code = hcam_enum_mbus_code,
	.enum_frame_size = hcam_enum_frame_size,
	.get_fmt = hcam_get_fmt,
	.set_fmt = hcam_get_fmt,	/* single fixed mode */
	.get_selection = hcam_get_selection,
};

static const struct v4l2_subdev_ops hcam_subdev_ops = {
	.video = &hcam_video_ops,
	.pad = &hcam_pad_ops,
};

static int hcam_init_controls(struct hcam *h)
{
	const struct hcam_sensor *s = h->s;
	struct v4l2_ctrl_handler *hdl = &h->ctrl_handler;
	struct v4l2_fwnode_device_properties props;
	s64 hblank = s->line_length - s->width;
	s64 vblank = s->frame_length - s->height;
	s64 exp_max = s->frame_length - s->exposure_margin;
	struct v4l2_ctrl *c;
	int ret;

	ret = v4l2_fwnode_device_parse(h->dev, &props);
	if (ret)
		return ret;
	ret = v4l2_ctrl_handler_init(hdl, 8);
	if (ret)
		return ret;
	hdl->lock = &h->mutex;

	h->link_freq_menu[0] = s->link_freq;
	c = v4l2_ctrl_new_int_menu(hdl, NULL, V4L2_CID_LINK_FREQ, 0, 0,
				   h->link_freq_menu);
	if (c)
		c->flags |= V4L2_CTRL_FLAG_READ_ONLY;
	v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_PIXEL_RATE, s->pixel_rate,
			  s->pixel_rate, 1, s->pixel_rate);
	v4l2_ctrl_new_std(hdl, NULL, V4L2_CID_HBLANK, hblank, hblank, 1, hblank);
	v4l2_ctrl_new_std(hdl, &hcam_ctrl_ops, V4L2_CID_VBLANK, vblank, vblank,
			  1, vblank);
	h->exposure = v4l2_ctrl_new_std(hdl, &hcam_ctrl_ops, V4L2_CID_EXPOSURE,
					4, exp_max, 1, exp_max);
	v4l2_ctrl_new_std(hdl, &hcam_ctrl_ops, V4L2_CID_ANALOGUE_GAIN,
			  s->gain_min, s->gain_max, 1, s->gain_def);
	v4l2_ctrl_new_fwnode_properties(hdl, &hcam_ctrl_ops, &props);
	if (hdl->error) {
		ret = hdl->error;
		v4l2_ctrl_handler_free(hdl);
		return ret;
	}
	h->subdev.ctrl_handler = hdl;
	return 0;
}

static int hcam_check_endpoint(struct hcam *h)
{
	/* D-PHY or C-PHY, as the DT says (the S5KHM2 is wired as C-PHY). */
	struct v4l2_fwnode_endpoint ep = { .bus_type = V4L2_MBUS_UNKNOWN };
	struct fwnode_handle *fw;
	int ret;

	fw = fwnode_graph_get_next_endpoint(dev_fwnode(h->dev), NULL);
	if (!fw)
		return -ENXIO;
	ret = v4l2_fwnode_endpoint_alloc_parse(fw, &ep);
	fwnode_handle_put(fw);
	if (ret)
		return ret;
	dev_info(h->dev, "endpoint bus type %d\n", ep.bus_type);
	if (ep.bus.mipi_csi2.num_data_lanes != h->s->lanes)
		dev_warn(h->dev, "endpoint has %u lanes, mode needs %u\n",
			 ep.bus.mipi_csi2.num_data_lanes, h->s->lanes);
	if (ep.nr_of_link_frequencies != 1 ||
	    ep.link_frequencies[0] != h->s->link_freq)
		dev_warn(h->dev, "DT link-frequencies differ from %lld\n",
			 h->s->link_freq);
	v4l2_fwnode_endpoint_free(&ep);
	return 0;
}

static int hcam_probe(struct i2c_client *client)
{
	static const char *const names[] = { "vio", "vana", "vdig" };
	struct device *dev = &client->dev;
	struct hcam *h;
	unsigned int i;
	u16 id = 0;
	int ret;

	h = devm_kzalloc(dev, sizeof(*h), GFP_KERNEL);
	if (!h)
		return -ENOMEM;
	h->dev = dev;
	h->s = of_device_get_match_data(dev);

	v4l2_i2c_subdev_init(&h->subdev, client, &hcam_subdev_ops);
	/* "<sensor> <bus>-<addr>": libcamera takes the model (and the tuning
	 * file name) from the first word of the entity name. */
	v4l2_i2c_subdev_set_name(&h->subdev, client, h->s->name, NULL);
	ret = hcam_check_endpoint(h);
	if (ret)
		return dev_err_probe(dev, ret, "bad endpoint\n");

	h->subdev.flags |= V4L2_SUBDEV_FL_HAS_DEVNODE;
	h->subdev.entity.function = MEDIA_ENT_F_CAM_SENSOR;
	h->pad.flags = MEDIA_PAD_FL_SOURCE;

	h->eclk = devm_clk_get(dev, "eclk");
	if (IS_ERR(h->eclk))
		return dev_err_probe(dev, PTR_ERR(h->eclk), "no eclk\n");
	h->rst_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(h->rst_gpio))
		return dev_err_probe(dev, PTR_ERR(h->rst_gpio), "no reset\n");
	for (i = 0; i < ARRAY_SIZE(names); i++)
		h->supplies[i].supply = names[i];
	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(names), h->supplies);
	if (ret)
		return dev_err_probe(dev, ret, "failed to get regulators\n");
	if (h->s->vdig_uv) {
		ret = regulator_set_voltage(h->supplies[2].consumer,
					    h->s->vdig_uv, h->s->vdig_uv);
		if (ret)
			return dev_err_probe(dev, ret, "vdig %u uV\n", h->s->vdig_uv);
	}

	mutex_init(&h->mutex);
	ret = hcam_init_controls(h);
	if (ret)
		return ret;
	ret = media_entity_pads_init(&h->subdev.entity, 1, &h->pad);
	if (ret)
		goto free_ctrls;

	pm_runtime_enable(dev);
	ret = pm_runtime_resume_and_get(dev);
	if (ret < 0)
		goto disable_pm;
	ret = hcam_read16(h, h->s->id_reg, &id);
	pm_runtime_put(dev);
	if (ret || id != h->s->id_val) {
		dev_err(dev, "%s: chip id 0x%04x (ret %d), expected 0x%04x\n",
			h->s->name, id, ret, h->s->id_val);
		ret = -ENODEV;
		goto disable_pm;
	}
	dev_info(dev, "%s: chip id 0x%04x, %ux%u, %u lanes @ %lld Hz\n",
		 h->s->name, id, h->s->width, h->s->height, h->s->lanes,
		 h->s->link_freq);

	ret = v4l2_async_register_subdev_sensor(&h->subdev);
	if (ret)
		goto disable_pm;
	return 0;

disable_pm:
	pm_runtime_disable(dev);
	media_entity_cleanup(&h->subdev.entity);
free_ctrls:
	v4l2_ctrl_handler_free(&h->ctrl_handler);
	return ret;
}

static void hcam_remove(struct i2c_client *client)
{
	struct v4l2_subdev *sd = i2c_get_clientdata(client);
	struct hcam *h = to_hcam(sd);

	v4l2_async_unregister_subdev(sd);
	media_entity_cleanup(&sd->entity);
	v4l2_ctrl_handler_free(&h->ctrl_handler);
	pm_runtime_disable(h->dev);
	mutex_destroy(&h->mutex);
}

static const struct dev_pm_ops hcam_pm_ops = {
	SET_RUNTIME_PM_OPS(hcam_power_off, hcam_power_on, NULL)
};

static const struct of_device_id hcam_of_match[] = {
	{ .compatible = "ovti,ov32b", .data = &ov32b_sensor },
	{ .compatible = "samsung,s5khm2", .data = &s5khm2_sensor },
	{ }
};
MODULE_DEVICE_TABLE(of, hcam_of_match);

static struct i2c_driver hcam_driver = {
	.driver = {
		.name = "hanoip-cam",
		.pm = &hcam_pm_ops,
		.of_match_table = hcam_of_match,
	},
	.probe = hcam_probe,
	.remove = hcam_remove,
};
module_i2c_driver(hcam_driver);

MODULE_DESCRIPTION("hanoip OV32B / S5KHM2 table-driven sensor driver");
MODULE_LICENSE("GPL v2");
