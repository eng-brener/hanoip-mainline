// SPDX-License-Identifier: GPL-2.0-only
#include <linux/firmware.h>
#include <linux/module.h>
#include <linux/of.h>

static int overlay_id = -1;
static const struct firmware *overlay_fw;

static int __init hanoip_se11_overlay_init(void)
{
	int ret;

	ret = request_firmware(&overlay_fw, "hanoip/se11-i2c.dtbo", NULL);
	if (ret) {
		pr_err("hanoip-se11-overlay: cannot load overlay firmware: %d\n", ret);
		return ret;
	}

	ret = of_overlay_fdt_apply(overlay_fw->data, overlay_fw->size,
				   &overlay_id, NULL);
	release_firmware(overlay_fw);
	overlay_fw = NULL;
	if (ret) {
		pr_err("hanoip-se11-overlay: applying SE11 overlay failed: %d\n", ret);
		return ret;
	}

	pr_info("hanoip-se11-overlay: enabled I2C SE11 at a94000 (overlay %d)\n",
		overlay_id);
	return 0;
}

static void __exit hanoip_se11_overlay_exit(void)
{
	if (overlay_id >= 0) {
		int ret = of_overlay_remove(&overlay_id);

		if (ret)
			pr_err("hanoip-se11-overlay: remove failed: %d\n", ret);
	}
}

module_init(hanoip_se11_overlay_init);
module_exit(hanoip_se11_overlay_exit);
MODULE_DESCRIPTION("Apply the RAM-only Hanoip SE11 I2C diagnostic overlay");
MODULE_LICENSE("GPL");
