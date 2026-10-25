// SPDX-License-Identifier: GPL-2.0-only
/*
 * Copyright (c) Qualcomm Technologies, Inc. and/or its subsidiaries.
 *
 * Panel driver for Ilitek ILI7807S LCD DSI panels.
 *
 * Supports:
 *   - DLC DLC0697 (1080x1920)
 *   - Tianma ILI7807S (Moto G60 / hanoip, 1080x2460)
 */

#include <linux/backlight.h>
#include <linux/delay.h>
#include <linux/gpio/consumer.h>
#include <linux/module.h>
#include <linux/of.h>
#include <linux/regulator/consumer.h>

#include <video/mipi_display.h>

#include <drm/display/drm_dsc.h>
#include <drm/display/drm_dsc_helper.h>
#include <drm/drm_mipi_dsi.h>
#include <drm/drm_modes.h>
#include <drm/drm_panel.h>
#include <drm/drm_probe_helper.h>

struct panel_desc {
	const struct drm_display_mode *mode;
	unsigned int lanes;
	enum mipi_dsi_pixel_format format;
	unsigned long mode_flags;
	void (*init)(struct mipi_dsi_multi_context *dsi_ctx);
	bool dsc;
};

struct ili7807s {
	struct drm_panel panel;
	struct mipi_dsi_device *dsi;
	const struct panel_desc *desc;
	struct drm_dsc_config dsc;

	struct regulator_bulk_data *supplies;
	struct gpio_desc *reset_gpio;
};

static const struct regulator_bulk_data ili7807s_supplies[] = {
	{ .supply = "vddi" },
	{ .supply = "avdd" },
	{ .supply = "avee" },
};

static inline struct ili7807s *to_ili7807s(struct drm_panel *panel)
{
	return container_of(panel, struct ili7807s, panel);
}

static void ili7807s_reset(struct ili7807s *ctx)
{
	if (ctx->desc->dsc) {
		/* GPIO_ACTIVE_LOW: electrical high 4 ms, low 1 ms, high 12 ms. */
		gpiod_set_value_cansleep(ctx->reset_gpio, 0);
		usleep_range(4000, 5000);
		gpiod_set_value_cansleep(ctx->reset_gpio, 1);
		usleep_range(1000, 2000);
		gpiod_set_value_cansleep(ctx->reset_gpio, 0);
		usleep_range(12000, 13000);
		return;
	}

	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
	usleep_range(10000, 11000);
	gpiod_set_value_cansleep(ctx->reset_gpio, 0);
	usleep_range(10000, 11000);
	gpiod_set_value_cansleep(ctx->reset_gpio, 1);
	usleep_range(10000, 11000);
}

static void dlc0697_init_sequence(struct mipi_dsi_multi_context *dsi_ctx)
{
	mipi_dsi_dcs_soft_reset_multi(dsi_ctx);
	mipi_dsi_msleep(dsi_ctx, 120);

	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x78, 0x07, 0x00);
	mipi_dsi_dcs_set_tear_on_multi(dsi_ctx, MIPI_DSI_DCS_TEAR_MODE_VBLANK);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, MIPI_DCS_SET_CABC_MIN_BRIGHTNESS, 0x00);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, MIPI_DCS_WRITE_CONTROL_DISPLAY, 0x20);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, MIPI_DCS_WRITE_POWER_SAVE, 0x01);
	mipi_dsi_dcs_set_display_brightness_multi(dsi_ctx, 0x1fff);

	mipi_dsi_dcs_exit_sleep_mode_multi(dsi_ctx);
	mipi_dsi_msleep(dsi_ctx, 120);

	mipi_dsi_dcs_set_display_on_multi(dsi_ctx);
	mipi_dsi_msleep(dsi_ctx, 20);
}

static void tianma_hanoip_init_sequence(struct mipi_dsi_multi_context *dsi_ctx)
{
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x78, 0x07, 0x00);

	mipi_dsi_dcs_exit_sleep_mode_multi(dsi_ctx);
	mipi_dsi_msleep(dsi_ctx, 120);

	mipi_dsi_dcs_set_display_on_multi(dsi_ctx);
	mipi_dsi_msleep(dsi_ctx, 20);

	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x78, 0x07, 0x06);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x3e, 0xe3);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x80, 0x00);

	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x78, 0x07, 0x08);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfd, 0x00, 0x9f);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xe1, 0xd9);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xfd, 0x00, 0x00);

	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0xff, 0x78, 0x07, 0x00);
	/* Stock Tianma command is 51 03 32, not the legacy helper's LE order. */
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, MIPI_DCS_SET_DISPLAY_BRIGHTNESS, 0x03, 0x32);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x53, 0x2c);
	mipi_dsi_dcs_write_seq_multi(dsi_ctx, 0x55, 0x01);
}

static int ili7807s_on(struct ili7807s *ctx)
{
	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };
	struct drm_dsc_picture_parameter_set pps;

	ctx->dsi->mode_flags |= MIPI_DSI_MODE_LPM;
	ctx->desc->init(&dsi_ctx);
	if (ctx->desc->dsc) {
		/* MSM DSI fills the RC parameters during mode_set, before prepare. */
		drm_dsc_pps_payload_pack(&pps, &ctx->dsc);
		mipi_dsi_picture_parameter_set_multi(&dsi_ctx, &pps);
	}

	return dsi_ctx.accum_err;
}

static int ili7807s_off(struct ili7807s *ctx)
{
	struct mipi_dsi_multi_context dsi_ctx = { .dsi = ctx->dsi };

	if (ctx->desc->dsc)
		ctx->dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;
	mipi_dsi_dcs_set_display_off_multi(&dsi_ctx);
	mipi_dsi_msleep(&dsi_ctx, 50);

	mipi_dsi_dcs_enter_sleep_mode_multi(&dsi_ctx);
	mipi_dsi_msleep(&dsi_ctx, 150);

	return dsi_ctx.accum_err;
}

static int ili7807s_prepare(struct drm_panel *panel)
{
	struct ili7807s *ctx = to_ili7807s(panel);
	int ret, cleanup_ret;

	ret = regulator_bulk_enable(ARRAY_SIZE(ili7807s_supplies), ctx->supplies);
	if (ret < 0) {
		dev_err(ctx->panel.dev, "failed to enable regulators: %d\n", ret);
		return ret;
	}

	msleep(20);

	ili7807s_reset(ctx);

	ret = ili7807s_on(ctx);
	if (ret < 0) {
		dev_err(ctx->panel.dev, "failed to initialise panel: %d\n", ret);
		goto err;
	}

	return 0;

err:
	gpiod_set_value_cansleep(ctx->reset_gpio, 1);

	cleanup_ret = regulator_bulk_disable(ARRAY_SIZE(ili7807s_supplies),
					     ctx->supplies);
	if (cleanup_ret)
		dev_err(ctx->panel.dev, "failed to unwind regulators: %d\n",
			cleanup_ret);
	return ret;
}

static int ili7807s_unprepare(struct drm_panel *panel)
{
	struct ili7807s *ctx = to_ili7807s(panel);
	int ret;

	ret = ili7807s_off(ctx);
	if (ret < 0)
		dev_err(ctx->panel.dev, "failed to disable panel: %d\n", ret);

	gpiod_set_value_cansleep(ctx->reset_gpio, 1);

	ret = regulator_bulk_disable(ARRAY_SIZE(ili7807s_supplies), ctx->supplies);
	if (ret) {
		dev_err(ctx->panel.dev, "failed to disable regulators: %d\n", ret);
		return ret;
	}

	return 0;
}

static int ili7807s_get_modes(struct drm_panel *panel, struct drm_connector *connector)
{
	struct ili7807s *ctx = to_ili7807s(panel);

	return drm_connector_helper_get_modes_fixed(connector, ctx->desc->mode);
}

static const struct drm_panel_funcs ili7807s_panel_funcs = {
	.prepare = ili7807s_prepare,
	.unprepare = ili7807s_unprepare,
	.get_modes = ili7807s_get_modes,
};

static int ili7807s_bl_update_status(struct backlight_device *bl)
{
	struct mipi_dsi_device *dsi = bl_get_data(bl);
	u16 brightness = backlight_get_brightness(bl);
	int ret;

	dsi->mode_flags &= ~MIPI_DSI_MODE_LPM;

	ret = mipi_dsi_dcs_set_display_brightness_large(dsi, brightness);

	dsi->mode_flags |= MIPI_DSI_MODE_LPM;

	return ret;
}

static const struct backlight_ops ili7807s_bl_ops = {
	.update_status = ili7807s_bl_update_status,
};

static struct backlight_device *ili7807s_create_backlight(struct mipi_dsi_device *dsi)
{
	struct device *dev = &dsi->dev;
	const struct backlight_properties props = {
		.type           = BACKLIGHT_RAW,
		.brightness     = 0x3fff,
		.max_brightness = 0x3fff,
	};

	return devm_backlight_device_register(dev, dev_name(dev), dev, dsi,
					     &ili7807s_bl_ops, &props);
}

static const struct drm_display_mode dlc0697_mode = {
	.clock = (1080 + 18 + 2 + 16) * (1920 + 26 + 4 + 20) * 60 / 1000,

	.hdisplay    = 1080,
	.hsync_start = 1080 + 18,
	.hsync_end   = 1080 + 18 + 2,
	.htotal      = 1080 + 18 + 2 + 16,

	.vdisplay    = 1920,
	.vsync_start = 1920 + 26,
	.vsync_end   = 1920 + 26 + 4,
	.vtotal      = 1920 + 26 + 4 + 20,

	.width_mm  = 87,
	.height_mm = 154,
	.type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
};

static const struct panel_desc dlc0697_desc = {
	.mode       = &dlc0697_mode,
	.lanes      = 4,
	.format     = MIPI_DSI_FMT_RGB888,
	.mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST,
	.init       = dlc0697_init_sequence,
};

static const struct drm_display_mode tianma_hanoip_mode = {
	.clock = (1080 + 28 + 4 + 24) * (2460 + 12 + 2 + 2565) * 60 / 1000,

	.hdisplay    = 1080,
	.hsync_start = 1080 + 28,
	.hsync_end   = 1080 + 28 + 4,
	.htotal      = 1080 + 28 + 4 + 24,

	.vdisplay    = 2460,
	.vsync_start = 2460 + 2565,
	.vsync_end   = 2460 + 2565 + 2,
	.vtotal      = 2460 + 12 + 2 + 2565,

	.width_mm  = 69,
	.height_mm = 158,
	.type = DRM_MODE_TYPE_DRIVER | DRM_MODE_TYPE_PREFERRED,
};

static const struct panel_desc tianma_hanoip_desc = {
	.mode       = &tianma_hanoip_mode,
	.lanes      = 4,
	.format     = MIPI_DSI_FMT_RGB888,
	.mode_flags = MIPI_DSI_MODE_VIDEO | MIPI_DSI_MODE_VIDEO_BURST |
		      MIPI_DSI_MODE_LPM | MIPI_DSI_MODE_DSC_ALL_SLICES_IN_PKT,
	.init       = tianma_hanoip_init_sequence,
	.dsc        = true,
};

static int ili7807s_probe(struct mipi_dsi_device *dsi)
{
	struct device *dev = &dsi->dev;
	const struct panel_desc *desc;
	struct ili7807s *ctx;
	int ret;

	ctx = devm_drm_panel_alloc(dev, struct ili7807s, panel,
				   &ili7807s_panel_funcs,
				   DRM_MODE_CONNECTOR_DSI);
	if (IS_ERR(ctx))
		return PTR_ERR(ctx);

	desc = of_device_get_match_data(dev);
	ctx->desc = desc;

	ret = devm_regulator_bulk_get_const(dev, ARRAY_SIZE(ili7807s_supplies),
					    ili7807s_supplies, &ctx->supplies);
	if (ret < 0)
		return dev_err_probe(dev, ret, "failed to get regulators\n");

	ctx->reset_gpio = devm_gpiod_get(dev, "reset", GPIOD_OUT_HIGH);
	if (IS_ERR(ctx->reset_gpio))
		return dev_err_probe(dev, PTR_ERR(ctx->reset_gpio),
				     "failed to get reset gpio\n");

	ctx->dsi = dsi;
	mipi_dsi_set_drvdata(dsi, ctx);

	dsi->lanes      = desc->lanes;
	dsi->format     = desc->format;
	dsi->mode_flags = desc->mode_flags | MIPI_DSI_MODE_LPM;
	if (desc->dsc) {
		ctx->dsc.dsc_version_major = 1;
		ctx->dsc.dsc_version_minor = 1;
		ctx->dsc.slice_width = 540;
		ctx->dsc.slice_height = 10;
		ctx->dsc.slice_count = desc->mode->hdisplay / ctx->dsc.slice_width;
		ctx->dsc.bits_per_component = 8;
		ctx->dsc.bits_per_pixel = 8 << 4;
		ctx->dsc.block_pred_enable = true;
		dsi->dsc = &ctx->dsc;
	}

	ctx->panel.prepare_prev_first = true;

	ret = drm_panel_of_backlight(&ctx->panel);
	if (ret)
		return ret;

	if (!ctx->panel.backlight) {
		ctx->panel.backlight = ili7807s_create_backlight(dsi);
		if (IS_ERR(ctx->panel.backlight))
			return dev_err_probe(dev, PTR_ERR(ctx->panel.backlight),
					     "failed to create backlight\n");
	}

	ret = devm_drm_panel_add(dev, &ctx->panel);
	if (ret < 0)
		return dev_err_probe(dev, ret, "failed to add panel\n");

	return devm_mipi_dsi_attach(dev, dsi);
}

static const struct of_device_id ili7807s_of_match[] = {
	{ .compatible = "dlc,dlc0697", .data = &dlc0697_desc },
	{ .compatible = "tianma,ili7807s-hanoip", .data = &tianma_hanoip_desc },
	{ }
};
MODULE_DEVICE_TABLE(of, ili7807s_of_match);

/* Bring-up diagnostics: DCS reads only, no panel reconfiguration or reset. */
static ssize_t panel_status_show(struct device *dev,
				struct device_attribute *attr, char *buf)
{
	struct ili7807s *ctx = dev_get_drvdata(dev);
	unsigned long flags = ctx->dsi->mode_flags;
	u8 power = 0, pixel = 0, diagnostic = 0;
	ssize_t power_ret, pixel_ret, diagnostic_ret;

	if (!ctx->panel.prepared)
		return -EAGAIN;
	ctx->dsi->mode_flags |= MIPI_DSI_MODE_LPM;
	power_ret = mipi_dsi_dcs_read(ctx->dsi, MIPI_DCS_GET_POWER_MODE, &power, 1);
	pixel_ret = mipi_dsi_dcs_read(ctx->dsi, MIPI_DCS_GET_PIXEL_FORMAT, &pixel, 1);
	diagnostic_ret = mipi_dsi_dcs_read(ctx->dsi, MIPI_DCS_GET_DIAGNOSTIC_RESULT,
					&diagnostic, 1);
	ctx->dsi->mode_flags = flags;
	return sysfs_emit(buf,
		"prepared=%d enabled=%d reset_logical=%d power_ret=%zd power=0x%02x pixel_ret=%zd pixel=0x%02x diagnostic_ret=%zd diagnostic=0x%02x\n",
		ctx->panel.prepared, ctx->panel.enabled,
		gpiod_get_value_cansleep(ctx->reset_gpio), power_ret, power,
		pixel_ret, pixel, diagnostic_ret, diagnostic);
}
static DEVICE_ATTR_RO(panel_status);
static struct attribute *ili7807s_attrs[] = { &dev_attr_panel_status.attr, NULL };
ATTRIBUTE_GROUPS(ili7807s);

static struct mipi_dsi_driver ili7807s_dsi_driver = {
	.probe  = ili7807s_probe,
	.driver = {
		.name           = "panel-ilitek-ili7807s",
		.of_match_table = ili7807s_of_match,
		.dev_groups     = ili7807s_groups,
	},
};
module_mipi_dsi_driver(ili7807s_dsi_driver);

MODULE_AUTHOR("Arpit Saini <asaini@codeaurora.org>");
MODULE_DESCRIPTION("Panel driver for Ilitek ILI7807S LCD DSI panel");
MODULE_LICENSE("GPL");
