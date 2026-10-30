// SPDX-License-Identifier: GPL-2.0-only
/* Query only: never sends a command to the secure app or handles key data. */
#include <linux/module.h>
#include <linux/firmware/qcom/qcom_scm.h>

static int __init keymaster_lookup_init(void)
{
	u32 id = 0;
	int ret = qcom_scm_qseecom_app_get_id("keymaster64", &id);

	pr_info("fpc-keymaster-lookup: status=%d app_id=%u\n", ret, id);
	return 0;
}

static void __exit keymaster_lookup_exit(void) { }
module_init(keymaster_lookup_init);
module_exit(keymaster_lookup_exit);
MODULE_LICENSE("GPL");
MODULE_DESCRIPTION("Read-only lookup of keymaster64 secure app");
