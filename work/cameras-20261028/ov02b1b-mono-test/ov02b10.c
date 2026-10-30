// SPDX-License-Identifier: GPL-2.0
// Copyright (c) 2020 MediaTek Inc.

#include <linux/clk.h>
#include <linux/delay.h>
#include <linux/device.h>
#include <linux/gpio/consumer.h>
#include <linux/i2c.h>
#include <linux/module.h>
#include <linux/pm_runtime.h>
#include <linux/regulator/consumer.h>
#include <linux/units.h>
#include <media/media-entity.h>
#include <media/v4l2-async.h>
#include <media/v4l2-ctrls.h>
#include <media/v4l2-fwnode.h>
#include <media/v4l2-subdev.h>

#define OV02B10_ID					0x2b
#define OV02B10_ID_MASK					GENMASK(7, 0)

#define OV02B10_REG_CHIP_ID				0x03

/* Bit[1] vertical upside down */
/* Bit[0] horizontal mirror */
#define REG_MIRROR_FLIP_CONTROL				0x3f

/* Orientation */
#define REG_MIRROR_FLIP_ENABLE				0x03

/* Bit[2:0] MIPI transmission speed select */
#define TX_SPEED_AREA_SEL				0xa1
#define OV02B10_MIPI_TX_SPEED_DEFAULT			0x04

#define REG_PAGE_SWITCH					0xfd
#define REG_GLOBAL_EFFECTIVE				0x01
#define REG_ENABLE					BIT(0)

#define REG_SC_CTRL_MODE				0xac
#define SC_CTRL_MODE_STANDBY				0x00
#define SC_CTRL_MODE_STREAMING				0x01

/* Exposure control */
#define OV02B10_EXP_SHIFT				8
#define OV02B10_REG_EXPOSURE_H				0x0e
#define OV02B10_REG_EXPOSURE_L				0x0f
#define	OV02B10_EXPOSURE_MIN				4
#define OV02B10_EXPOSURE_MAX_MARGIN			7
#define	OV02B10_EXPOSURE_STEP				1

/* Vblanking control */
#define OV02B10_VTS_SHIFT				8
#define OV02B10_REG_VTS_H				0x05
#define OV02B10_REG_VTS_L				0x06
#define OV02B10_VTS_MAX					0x209f
#define OV02B10_BASE_LINES				1224

/* Analog gain control */
#define OV02B10_REG_GAIN				0x22
#define OV02B10_GAIN_MIN				0x10
#define OV02B10_GAIN_MAX				0xf8
#define OV02B10_GAIN_STEP				0x01
#define OV02B10_GAIN_DEFAULT				0xf8

/* Test pattern control */
#define OV02B10_REG_TEST_PATTERN			0xb6

#define OV02B10_LINK_FREQ_330MHZ			(330 * HZ_PER_MHZ)
#define OV02B10_ECLK_FREQ				(24 * HZ_PER_MHZ)

/* Number of lanes supported by this driver */
#define OV02B10_DATA_LANES				1

/* Bits per sample of sensor output */
#define OV02B10_BITS_PER_SAMPLE				10

static const char * const ov02b10_supply_names[] = {
	"dovdd",	/* Digital I/O power */
	"avdd",		/* Analog power */
	"dvdd",		/* Digital core power */
};

struct ov02b10_reg {
	u8 addr;
	u8 val;
};

struct ov02b10_reg_list {
	u32 num_of_regs;
	const struct ov02b10_reg *regs;
};

struct ov02b10_mode {
	u32 width;
	u32 height;
	u32 exp_def;
	u32 hts_def;
	u32 vts_def;
	const struct ov02b10_reg_list reg_list;
};

struct ov02b10 {
	struct device *dev;

	/* Indication of MIPI transmission speed select */
	u32 mipi_clock_voltage;

	struct clk *eclk;
	struct gpio_desc *pd_gpio;
	struct gpio_desc *rst_gpio;
	struct regulator_bulk_data supplies[ARRAY_SIZE(ov02b10_supply_names)];

	bool streaming;
	bool upside_down;

	/*
	 * Serialize control access, get/set format, get selection
	 * and start streaming.
	 */
	struct mutex mutex;
	struct v4l2_subdev subdev;
	struct media_pad pad;
	struct v4l2_mbus_framefmt fmt;
	struct v4l2_ctrl_handler ctrl_handler;
	struct v4l2_ctrl *exposure;

	const struct ov02b10_mode *cur_mode;
};

static inline struct ov02b10 *to_ov02b10(struct v4l2_subdev *sd)
{
	return container_of(sd, struct ov02b10, subdev);
}

/*
 * eclk 24Mhz
 * pclk 39Mhz
 * linelength 934(0x3a6)
 * framelength 1390(0x56E)
 * grabwindow_width 1600
 * grabwindow_height 1200
 * max_framerate 30fps
 * mipi_datarate per lane 780Mbps
 */
/*
 * Vendor init sequence (Motorola hanoip CamX sensormodule, list 6), minus the
 * soft reset 0xfc=1 which needs a 5 ms delay and is issued separately.
 * 1600x1200 Raw10, MCLK 24 MHz, 1 lane at 660 Mbps, 30.07 fps.
 */
static const struct ov02b10_reg ov02b10_1600x1200_regs[] = {
	{0xfd, 0x00},
	{0xfd, 0x00},
	{0x24, 0x02},
	{0x25, 0x06},
	{0x29, 0x03},
	{0x2a, 0x34},
	{0x1e, 0x17},
	{0x33, 0x07},
	{0x35, 0x07},
	{0x4a, 0x0c},
	{0x3a, 0x05},
	{0x3b, 0x02},
	{0x3e, 0x00},
	{0x46, 0x01},
	{0x6d, 0x03},
	{0x71, 0x05},
	{0x72, 0x06},
	{0xfd, 0x01},
	{0x0e, 0x02},
	{0x0f, 0x1a},
	{0x18, 0x00},
	{0x22, 0xff},
	{0x23, 0x02},
	{0x17, 0x2c},
	{0x19, 0x20},
	{0x1b, 0x06},
	{0x1c, 0x04},
	{0x20, 0x03},
	{0x30, 0x01},
	{0x33, 0x01},
	{0x31, 0x0a},
	{0x32, 0x09},
	{0x38, 0x01},
	{0x39, 0x01},
	{0x3a, 0x01},
	{0x3b, 0x01},
	{0x4f, 0x04},
	{0x4e, 0x05},
	{0x50, 0x01},
	{0x35, 0x0c},
	{0x45, 0x2a},
	{0x46, 0x2a},
	{0x47, 0x2a},
	{0x48, 0x2a},
	{0x4a, 0x2c},
	{0x4b, 0x2c},
	{0x4c, 0x2c},
	{0x4d, 0x2c},
	{0x56, 0x3a},
	{0x57, 0x0a},
	{0x58, 0x24},
	{0x59, 0x20},
	{0x5a, 0x0a},
	{0x5b, 0xff},
	{0x37, 0x0a},
	{0x42, 0x0e},
	{0x68, 0x90},
	{0x69, 0xcd},
	{0x6a, 0x8f},
	{0x6f, 0x47},
	{0x7c, 0x0a},
	{0x7d, 0x0a},
	{0x7e, 0x0a},
	{0x7f, 0x08},
	{0x83, 0x14},
	{0x84, 0x14},
	{0x86, 0x14},
	{0x87, 0x07},
	{0x88, 0x0f},
	{0x94, 0x02},
	{0x98, 0xd1},
	{0xfe, 0x02},
	{0xfd, 0x03},
	{0x97, 0x6c},
	{0x98, 0x60},
	{0x99, 0x60},
	{0x9a, 0x6c},
	{0xa1, 0x40},
	{0xaf, 0x04},
	{0xb1, 0x40},
	{0xae, 0x0d},
	{0x88, 0x5b},
	{0x89, 0x7c},
	{0xb4, 0x05},
	{0x8c, 0x40},
	{0x8e, 0x40},
	{0x90, 0x40},
	{0x92, 0x40},
	{0x9b, 0x46},
	{0xac, 0x40},
	{0xfd, 0x00},
	{0x5a, 0x15},
	{0x74, 0x01},
	{0xfb, 0x01},
};

/* CamX resolutionData.regSetting for the single 1600x1200 mode. */
static const struct ov02b10_reg ov02b10_mode_regs[] = {
	{0xfd, 0x00}, {0x50, 0x40}, {0x52, 0xb0},
	{0xfd, 0x01}, {0x03, 0x70}, {0x05, 0x10},
	{0x07, 0x20}, {0x09, 0xb0}, {0x12, 0x03}, {0x15, 0x05},
};

static const struct ov02b10_reg_list ov02b10_mode_reg_list = {
	.num_of_regs = ARRAY_SIZE(ov02b10_mode_regs),
	.regs = ov02b10_mode_regs,
};

static const char * const ov02b10_test_pattern_menu[] = {
	"Disabled",
	"Eight Vertical Colour Bars",
};

static const s64 link_freq_menu_items[] = {
	OV02B10_LINK_FREQ_330MHZ,
};

static u64 to_pixel_rate(u32 f_index)
{
	u64 pixel_rate = link_freq_menu_items[f_index] * 2 * OV02B10_DATA_LANES;

	do_div(pixel_rate, OV02B10_BITS_PER_SAMPLE);

	return pixel_rate;
}

static const struct ov02b10_mode supported_modes[] = {
	{
		.width = 1600,
		.height = 1200,
		.exp_def = 0x021a,
		.hts_def = 1792,
		.vts_def = 1225,
		.reg_list = {
			.num_of_regs = ARRAY_SIZE(ov02b10_1600x1200_regs),
			.regs = ov02b10_1600x1200_regs,
		},
	},
};

static int ov02b10_write_array(struct ov02b10 *ov02b10,
			       const struct ov02b10_reg_list *r_list)
{
	struct i2c_client *client = v4l2_get_subdevdata(&ov02b10->subdev);
	unsigned int i;
	int ret;

	for (i = 0; i < r_list->num_of_regs; i++) {
		ret = i2c_smbus_write_byte_data(client, r_list->regs[i].addr,
						r_list->regs[i].val);
		if (ret < 0)
			return ret;
	}

	return 0;
}

static void ov02b10_fill_fmt(const struct ov02b10_mode *mode,
			     struct v4l2_mbus_framefmt *fmt)
{
	fmt->width = mode->width;
	fmt->height = mode->height;
	fmt->field = V4L2_FIELD_NONE;
}

static int ov02b10_set_fmt(struct v4l2_subdev *sd,
			   struct v4l2_subdev_state *sd_state,
			   struct v4l2_subdev_format *fmt)
{
	struct ov02b10 *ov02b10 = to_ov02b10(sd);
	struct v4l2_mbus_framefmt *mbus_fmt = &fmt->format;
	struct v4l2_mbus_framefmt *frame_fmt;
	int ret = 0;

	mutex_lock(&ov02b10->mutex);

	if (ov02b10->streaming && fmt->which == V4L2_SUBDEV_FORMAT_ACTIVE) {
		ret = -EBUSY;
		goto out_unlock;
	}

	/* Only one sensor mode supported */
	mbus_fmt->code = ov02b10->fmt.code;
	ov02b10_fill_fmt(ov02b10->cur_mode, mbus_fmt);

	if (fmt->which == V4L2_SUBDEV_FORMAT_TRY)
		frame_fmt = v4l2_subdev_state_get_format(sd_state, 0);
	else
		frame_fmt = &ov02b10->fmt;

	*frame_fmt = *mbus_fmt;

out_unlock:
	mutex_unlock(&ov02b10->mutex);
	return ret;
}

static int ov02b10_get_fmt(struct v4l2_subdev *sd,
			   struct v4l2_subdev_state *sd_state,
			   struct v4l2_subdev_format *fmt)
{
	struct ov02b10 *ov02b10 = to_ov02b10(sd);
	struct v4l2_mbus_framefmt *mbus_fmt = &fmt->format;

	mutex_lock(&ov02b10->mutex);

	if (fmt->which == V4L2_SUBDEV_FORMAT_TRY) {
		fmt->format = *v4l2_subdev_state_get_format(sd_state,
							    fmt->pad);
	} else {
		fmt->format = ov02b10->fmt;
		mbus_fmt->code = ov02b10->fmt.code;
		ov02b10_fill_fmt(ov02b10->cur_mode, mbus_fmt);
	}

	mutex_unlock(&ov02b10->mutex);

	return 0;
}

static int ov02b10_enum_mbus_code(struct v4l2_subdev *sd,
				  struct v4l2_subdev_state *sd_state,
				  struct v4l2_subdev_mbus_code_enum *code)
{
	struct ov02b10 *ov02b10 = to_ov02b10(sd);

	if (code->index != 0)
		return -EINVAL;

	code->code = ov02b10->fmt.code;

	return 0;
}

static int ov02b10_enum_frame_sizes(struct v4l2_subdev *sd,
				    struct v4l2_subdev_state *sd_state,
				    struct v4l2_subdev_frame_size_enum *fse)
{
	if (fse->index >= ARRAY_SIZE(supported_modes))
		return -EINVAL;

	fse->min_width  = supported_modes[fse->index].width;
	fse->max_width  = supported_modes[fse->index].width;
	fse->max_height = supported_modes[fse->index].height;
	fse->min_height = supported_modes[fse->index].height;

	return 0;
}

static int ov02b10_check_sensor_id(struct ov02b10 *ov02b10)
{
	struct i2c_client *client = v4l2_get_subdevdata(&ov02b10->subdev);
	u16 chip_id;
	int ret;

	/* Validate the chip ID */
	ret = i2c_smbus_write_byte_data(client, REG_PAGE_SWITCH, 0x00);
	if (ret < 0)
		return ret;

	ret = i2c_smbus_read_byte_data(client, OV02B10_REG_CHIP_ID);
	if (ret < 0)
		return ret;

	chip_id = ret;

	if ((chip_id & OV02B10_ID_MASK) != OV02B10_ID) {
		dev_err(ov02b10->dev, "unexpected sensor id(0x%04x)\n", chip_id);
		return -EINVAL;
	}

	return 0;
}

static int ov02b10_power_on(struct device *dev)
{
	struct i2c_client *client = to_i2c_client(dev);
	struct v4l2_subdev *sd = i2c_get_clientdata(client);
	struct ov02b10 *ov02b10 = to_ov02b10(sd);
	int ret;

	gpiod_set_value_cansleep(ov02b10->rst_gpio, 1);
	gpiod_set_value_cansleep(ov02b10->pd_gpio, 1);

	ret = clk_prepare_enable(ov02b10->eclk);
	if (ret < 0) {
		dev_err(dev, "failed to enable eclk\n");
		return ret;
	}

	ret = regulator_bulk_enable(ARRAY_SIZE(ov02b10_supply_names),
				    ov02b10->supplies);
	if (ret < 0) {
		dev_err(dev, "failed to enable regulators\n");
		goto disable_clk;
	}
	usleep_range(5000, 6000);

	gpiod_set_value_cansleep(ov02b10->pd_gpio, 0);
	usleep_range(5000, 6000);

	gpiod_set_value_cansleep(ov02b10->rst_gpio, 0);
	usleep_range(5000, 6000);

	ret = ov02b10_check_sensor_id(ov02b10);
	if (ret)
		goto disable_regulator;

	return 0;

disable_regulator:
	regulator_bulk_disable(ARRAY_SIZE(ov02b10_supply_names),
			       ov02b10->supplies);
disable_clk:
	clk_disable_unprepare(ov02b10->eclk);

	return ret;
}

static int ov02b10_power_off(struct device *dev)
{
	struct i2c_client *client = to_i2c_client(dev);
	struct v4l2_subdev *sd = i2c_get_clientdata(client);
	struct ov02b10 *ov02b10 = to_ov02b10(sd);

	gpiod_set_value_cansleep(ov02b10->rst_gpio, 1);
	clk_disable_unprepare(ov02b10->eclk);
	gpiod_set_value_cansleep(ov02b10->pd_gpio, 1);
	regulator_bulk_disable(ARRAY_SIZE(ov02b10_supply_names),
			       ov02b10->supplies);

	return 0;
}

static int ov02b10_write(struct ov02b10 *ov02b10, u8 page, u8 reg, u8 val)
{
	struct i2c_client *client = v4l2_get_subdevdata(&ov02b10->subdev);
	int ret;

	ret = i2c_smbus_write_byte_data(client, REG_PAGE_SWITCH, page);
	if (ret < 0)
		return ret;

	return i2c_smbus_write_byte_data(client, reg, val);
}

static int __ov02b10_start_stream(struct ov02b10 *ov02b10)
{
	int ret;

	/* Soft reset, then the vendor init sequence */
	ret = ov02b10_write(ov02b10, 0x00, 0xfc, 0x01);
	if (ret)
		return ret;
	usleep_range(5000, 6000);

	ret = ov02b10_write_array(ov02b10, &ov02b10->cur_mode->reg_list);
	if (ret)
		return ret;

	ret = ov02b10_write_array(ov02b10, &ov02b10_mode_reg_list);
	if (ret)
		return ret;

	ret = __v4l2_ctrl_handler_setup(ov02b10->subdev.ctrl_handler);
	if (ret)
		return ret;

	/* Stream on (vendor "streamOn" list) */
	ret = ov02b10_write(ov02b10, 0x01, 0x10, 0x00);
	if (ret)
		return ret;

	return ov02b10_write(ov02b10, 0x03, 0xc2, 0x01);
}

static int __ov02b10_stop_stream(struct ov02b10 *ov02b10)
{
	int ret;

	/* Stream off (vendor "streamOff" list) */
	ret = ov02b10_write(ov02b10, 0x01, 0x10, 0x01);
	if (ret)
		return ret;

	return ov02b10_write(ov02b10, 0x03, 0xc2, 0x00);
}

static int ov02b10_init_state(struct v4l2_subdev *sd,
			      struct v4l2_subdev_state *sd_state)
{
	struct v4l2_subdev_format fmt = {
		.which = V4L2_SUBDEV_FORMAT_TRY,
		.format = {
			.width = 1600,
			.height = 1200,
		}
	};

	ov02b10_set_fmt(sd, sd_state, &fmt);

	return 0;
}

static int ov02b10_s_stream(struct v4l2_subdev *sd, int on)
{
	struct ov02b10 *ov02b10 = to_ov02b10(sd);
	int ret;

	mutex_lock(&ov02b10->mutex);

	if (ov02b10->streaming == on) {
		ret = 0;
		goto unlock_and_return;
	}

	if (on) {
		ret = pm_runtime_resume_and_get(ov02b10->dev);
		if (ret < 0)
			goto unlock_and_return;

		ret = __ov02b10_start_stream(ov02b10);
		if (ret) {
			__ov02b10_stop_stream(ov02b10);
			ov02b10->streaming = !on;
			goto err_rpm_put;
		}
	} else {
		__ov02b10_stop_stream(ov02b10);
		pm_runtime_put(ov02b10->dev);
	}

	ov02b10->streaming = on;
	mutex_unlock(&ov02b10->mutex);

	return 0;

err_rpm_put:
	pm_runtime_put(ov02b10->dev);
unlock_and_return:
	mutex_unlock(&ov02b10->mutex);

	return ret;
}

static const struct dev_pm_ops ov02b10_pm_ops = {
	SET_RUNTIME_PM_OPS(ov02b10_power_off, ov02b10_power_on, NULL)
};

static int ov02b10_set_ctrl(struct v4l2_ctrl *ctrl)
{
	struct ov02b10 *ov02b10 = container_of(ctrl->handler,
						       struct ov02b10, ctrl_handler);
	struct i2c_client *client = v4l2_get_subdevdata(&ov02b10->subdev);
	int ret;

	/* V4L2 controls values will be applied only when power is already up */
	ret = pm_runtime_get_if_in_use(ov02b10->dev);
	if (ret <= 0)
		return ret;

	ret = i2c_smbus_write_byte_data(client, REG_PAGE_SWITCH, 0x01);
	if (ret < 0)
		goto out;

	switch (ctrl->id) {
	case V4L2_CID_EXPOSURE:
		ret = i2c_smbus_write_byte_data(client, OV02B10_REG_EXPOSURE_H,
						ctrl->val >> 8);
		if (ret < 0)
			break;
		ret = i2c_smbus_write_byte_data(client, OV02B10_REG_EXPOSURE_L,
						ctrl->val & 0xff);
		break;
	case V4L2_CID_ANALOGUE_GAIN:
		ret = i2c_smbus_write_byte_data(client, OV02B10_REG_GAIN, ctrl->val);
		break;
	default:
		ret = -EINVAL;
		break;
	}
	if (ret >= 0)
		ret = i2c_smbus_write_byte_data(client, 0xfe, 0x02);
out:
	pm_runtime_put(ov02b10->dev);
	return ret;
}

static const struct v4l2_subdev_video_ops ov02b10_video_ops = {
	.s_stream = ov02b10_s_stream,
};

static const struct v4l2_subdev_pad_ops ov02b10_pad_ops = {
	.enum_mbus_code = ov02b10_enum_mbus_code,
	.enum_frame_size = ov02b10_enum_frame_sizes,
	.get_fmt = ov02b10_get_fmt,
	.set_fmt = ov02b10_set_fmt,
};

static const struct v4l2_subdev_ops ov02b10_subdev_ops = {
	.video	= &ov02b10_video_ops,
	.pad	= &ov02b10_pad_ops,
};

static const struct v4l2_subdev_internal_ops ov02b10_internal_ops = {
	.init_state = ov02b10_init_state,
};

static const struct media_entity_operations ov02b10_subdev_entity_ops = {
	.link_validate = v4l2_subdev_link_validate,
};

static const struct v4l2_ctrl_ops ov02b10_ctrl_ops = {
	.s_ctrl = ov02b10_set_ctrl,
};

static int ov02b10_initialize_controls(struct ov02b10 *ov02b10)
{
	const struct ov02b10_mode *mode;
	struct v4l2_ctrl_handler *handler;
	struct v4l2_ctrl *ctrl;
	s64 exposure_max;
	s64 vblank_def;
	s64 pixel_rate;
	s64 h_blank;
	int ret;

	handler = &ov02b10->ctrl_handler;
	mode = ov02b10->cur_mode;
	ret = v4l2_ctrl_handler_init(handler, 7);
	if (ret)
		return ret;

	handler->lock = &ov02b10->mutex;

	ctrl = v4l2_ctrl_new_int_menu(handler, NULL, V4L2_CID_LINK_FREQ, 0, 0,
				      link_freq_menu_items);
	if (ctrl)
		ctrl->flags |= V4L2_CTRL_FLAG_READ_ONLY;

	pixel_rate = to_pixel_rate(0);
	v4l2_ctrl_new_std(handler, NULL, V4L2_CID_PIXEL_RATE, 0, pixel_rate, 1,
			  pixel_rate);

	h_blank = mode->hts_def - mode->width;
	v4l2_ctrl_new_std(handler, NULL, V4L2_CID_HBLANK, h_blank, h_blank, 1,
			  h_blank);

	vblank_def = mode->vts_def - mode->height;
	ctrl = v4l2_ctrl_new_std(handler, NULL, V4L2_CID_VBLANK, vblank_def,
				 vblank_def, 1, vblank_def);
	if (ctrl)
		ctrl->flags |= V4L2_CTRL_FLAG_READ_ONLY;

	exposure_max = mode->vts_def - OV02B10_EXPOSURE_MAX_MARGIN;
	ov02b10->exposure = v4l2_ctrl_new_std(handler, &ov02b10_ctrl_ops,
			V4L2_CID_EXPOSURE, OV02B10_EXPOSURE_MIN, exposure_max,
			OV02B10_EXPOSURE_STEP, mode->exp_def);
	v4l2_ctrl_new_std(handler, &ov02b10_ctrl_ops, V4L2_CID_ANALOGUE_GAIN,
			OV02B10_GAIN_MIN, OV02B10_GAIN_MAX, OV02B10_GAIN_STEP,
			OV02B10_GAIN_DEFAULT);

	if (handler->error) {
		ret = handler->error;
		dev_err(ov02b10->dev, "failed to init controls(%d)\n", ret);
		goto err_free_handler;
	}

	ov02b10->subdev.ctrl_handler = handler;

	return 0;

err_free_handler:
	v4l2_ctrl_handler_free(handler);

	return ret;
}

static int ov02b10_check_hwcfg(struct device *dev, struct ov02b10 *ov02b10)
{
	struct fwnode_handle *ep;
	struct fwnode_handle *fwnode = dev_fwnode(dev);
	struct v4l2_fwnode_endpoint bus_cfg = {
		.bus_type = V4L2_MBUS_CSI2_DPHY,
	};
	unsigned int i, j;
	u32 clk_volt;
	int ret;

	if (!fwnode)
		return -EINVAL;

	ep = fwnode_graph_get_next_endpoint(fwnode, NULL);
	if (!ep)
		return -ENXIO;

	/* Optional indication of MIPI clock voltage unit */
	if (!fwnode_property_read_u32(ep, "ovti,mipi-clock-voltage",
				      &clk_volt))
		ov02b10->mipi_clock_voltage = clk_volt;

	ret = v4l2_fwnode_endpoint_alloc_parse(ep, &bus_cfg);
	fwnode_handle_put(ep);
	if (ret)
		return ret;

	for (i = 0; i < ARRAY_SIZE(link_freq_menu_items); i++) {
		for (j = 0; j < bus_cfg.nr_of_link_frequencies; j++) {
			if (link_freq_menu_items[i] ==
				bus_cfg.link_frequencies[j])
				break;
		}

		if (j == bus_cfg.nr_of_link_frequencies) {
			dev_err(dev, "no link frequency %lld supported\n",
				link_freq_menu_items[i]);
			ret = -EINVAL;
			break;
		}
	}

	v4l2_fwnode_endpoint_free(&bus_cfg);

	return ret;
}

static int ov02b10_probe(struct i2c_client *client)
{
	struct device *dev = &client->dev;
	struct ov02b10 *ov02b10;
	unsigned int i;
	unsigned int rotation;
	int ret;

	ov02b10 = devm_kzalloc(dev, sizeof(*ov02b10), GFP_KERNEL);
	if (!ov02b10)
		return -ENOMEM;

	ov02b10->dev = dev;

	ret = ov02b10_check_hwcfg(dev, ov02b10);
	if (ret)
		return dev_err_probe(dev, ret,
				     "failed to check HW configuration\n");

	v4l2_i2c_subdev_init(&ov02b10->subdev, client, &ov02b10_subdev_ops);
	ov02b10->subdev.internal_ops = &ov02b10_internal_ops;

	ov02b10->mipi_clock_voltage = OV02B10_MIPI_TX_SPEED_DEFAULT;
	/* OV02B1B is the monochrome variant; no Bayer color filter array. */
	ov02b10->fmt.code = MEDIA_BUS_FMT_Y10_1X10;

	/* Optional indication of physical rotation of sensor */
	rotation = 0;
	device_property_read_u32(dev, "rotation", &rotation);
	if (rotation == 180) {
		ov02b10->upside_down = true;
	}

	ov02b10->eclk = devm_v4l2_sensor_clk_get_legacy(dev, "eclk", false, 0);
	if (IS_ERR(ov02b10->eclk))
		return dev_err_probe(dev, PTR_ERR(ov02b10->eclk),
				     "failed to get eclk\n");

	if (clk_get_rate(ov02b10->eclk) != OV02B10_ECLK_FREQ)
		dev_warn(dev, "eclk mismatched, mode is based on 24MHz\n");

	ov02b10->pd_gpio = devm_gpiod_get_optional(dev, "powerdown", GPIOD_OUT_HIGH);
	if (IS_ERR(ov02b10->pd_gpio))
		return dev_err_probe(dev, PTR_ERR(ov02b10->pd_gpio),
				     "failed to get powerdown-gpios\n");

	ov02b10->rst_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(ov02b10->rst_gpio))
		return dev_err_probe(dev, PTR_ERR(ov02b10->rst_gpio),
				     "failed to get reset-gpios\n");

	for (i = 0; i < ARRAY_SIZE(ov02b10_supply_names); i++)
		ov02b10->supplies[i].supply = ov02b10_supply_names[i];

	ret = devm_regulator_bulk_get(dev, ARRAY_SIZE(ov02b10_supply_names),
				      ov02b10->supplies);
	if (ret)
		return dev_err_probe(dev, ret, "failed to get regulators\n");

	mutex_init(&ov02b10->mutex);

	/* Set default mode */
	ov02b10->cur_mode = &supported_modes[0];

	ret = ov02b10_initialize_controls(ov02b10);
	if (ret) {
		dev_err_probe(dev, ret, "failed to initialize controls\n");
		goto err_destroy_mutex;
	}

	/* Initialize subdev */
	ov02b10->subdev.flags |= V4L2_SUBDEV_FL_HAS_DEVNODE;
	ov02b10->subdev.entity.ops = &ov02b10_subdev_entity_ops;
	ov02b10->subdev.entity.function = MEDIA_ENT_F_CAM_SENSOR;
	ov02b10->pad.flags = MEDIA_PAD_FL_SOURCE;

	ret = media_entity_pads_init(&ov02b10->subdev.entity, 1, &ov02b10->pad);
	if (ret < 0) {
		dev_err_probe(dev, ret, "failed to initialize entity pads\n");
		goto err_free_handler;
	}

	pm_runtime_enable(dev);
	if (!pm_runtime_enabled(dev)) {
		ret = ov02b10_power_on(dev);
		if (ret < 0) {
			dev_err_probe(dev, ret, "failed to power on\n");
			goto err_clean_entity;
		}
	}

	ret = v4l2_async_register_subdev(&ov02b10->subdev);
	if (ret) {
		dev_err_probe(dev, ret, "failed to register V4L2 subdev\n");
		goto err_power_off;
	}

	return 0;

err_power_off:
	if (pm_runtime_enabled(dev))
		pm_runtime_disable(dev);
	else
		ov02b10_power_off(dev);
err_clean_entity:
	media_entity_cleanup(&ov02b10->subdev.entity);
err_free_handler:
	v4l2_ctrl_handler_free(ov02b10->subdev.ctrl_handler);
err_destroy_mutex:
	mutex_destroy(&ov02b10->mutex);

	return ret;
}

static void ov02b10_remove(struct i2c_client *client)
{
	struct v4l2_subdev *sd = i2c_get_clientdata(client);
	struct ov02b10 *ov02b10 = to_ov02b10(sd);

	v4l2_async_unregister_subdev(sd);
	media_entity_cleanup(&sd->entity);
	v4l2_ctrl_handler_free(sd->ctrl_handler);
	pm_runtime_disable(ov02b10->dev);
	if (!pm_runtime_status_suspended(ov02b10->dev))
		ov02b10_power_off(ov02b10->dev);
	pm_runtime_set_suspended(ov02b10->dev);
	mutex_destroy(&ov02b10->mutex);
}

static const struct of_device_id ov02b10_of_match[] = {
	{ .compatible = "ovti,ov02b10" },
	{}
};
MODULE_DEVICE_TABLE(of, ov02b10_of_match);

static struct i2c_driver ov02b10_i2c_driver = {
	.driver = {
		.name = "ov02b10",
		.pm = &ov02b10_pm_ops,
		.of_match_table = ov02b10_of_match,
	},
	.probe		= ov02b10_probe,
	.remove		= ov02b10_remove,
};
module_i2c_driver(ov02b10_i2c_driver);

MODULE_AUTHOR("Dongchun Zhu");
MODULE_DESCRIPTION("OmniVision OV02B10 sensor driver (hanoip, from ov02a10)");
MODULE_LICENSE("GPL v2");
