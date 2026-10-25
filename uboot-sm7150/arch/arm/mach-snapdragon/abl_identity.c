// SPDX-License-Identifier: GPL-2.0+
/*
 * Carry device identity from the Android bootloader (ABL) to Linux.
 *
 * When U-Boot is chainloaded by ABL and boots Linux with its own built-in
 * devicetree, the identity ABL generated (androidboot.* arguments, serial
 * number and hardware revision in /chosen) would otherwise be lost. Copy
 * it into the Linux devicetree, and turn the Bluetooth and Wi-Fi addresses
 * into the standard local-bd-address and local-mac-address properties.
 * Nothing is done when no valid ABL devicetree was handed over.
 */

#define pr_fmt(fmt) "abl_identity: " fmt

#include <fdt_support.h>
#include <hexdump.h>
#include <init.h>
#include <log.h>
#include <linux/ctype.h>
#include <linux/errno.h>
#include <linux/libfdt.h>
#include <linux/string.h>

int qcom_fixup_abl_identity(void *blob);

static const char * const abl_chosen_u32_props[] = {
	"linux,seriallow",
	"linux,serialhigh",
	"linux,hwrev",
	"mmi,powerup_reason",
};

/* Find "key" in a space separated command line, return its value length. */
static int abl_cmdline_value(const char *cmdline, const char *key, const char **value)
{
	size_t keylen = strlen(key);
	const char *p = cmdline;

	while ((p = strstr(p, key))) {
		if (p == cmdline || p[-1] == ' ') {
			*value = p + keylen;
			return strcspn(*value, " ");
		}
		p += keylen;
	}

	return -ENOENT;
}

/* Parse "AA:BB:CC:DD:EE:FF" (the first address of a comma separated list). */
static int abl_parse_mac(const char *str, int len, u8 mac[6])
{
	int i;

	if (len < 17)
		return -EINVAL;

	for (i = 0; i < 6; i++) {
		const char *h = str + i * 3;

		if (!isxdigit(h[0]) || !isxdigit(h[1]) || (i < 5 && h[2] != ':'))
			return -EINVAL;
		mac[i] = (hex_to_bin(h[0]) << 4) | hex_to_bin(h[1]);
	}

	return 0;
}

static void abl_set_addr(void *blob, const char *compatible, const char *prop,
			 const u8 *addr)
{
	int node = fdt_node_offset_by_compatible(blob, -1, compatible);
	int ret;

	if (node < 0)
		return;

	ret = fdt_setprop(blob, node, prop, addr, 6);
	if (ret)
		log_warning("failed to set %s on %s: %s\n", prop, compatible,
			    fdt_strerror(ret));
}

int qcom_fixup_abl_identity(void *blob)
{
	const void *abl = (const void *)get_prev_bl_fdt_addr();
	const char *cmdline, *value;
	int abl_chosen, chosen, len, i;
	u8 addr[6], rev[6];

	if (!abl || fdt_check_header(abl))
		return 0;

	abl_chosen = fdt_path_offset(abl, "/chosen");
	if (abl_chosen < 0)
		return 0;

	chosen = fdt_find_or_add_subnode(blob, 0, "chosen");
	if (chosen < 0)
		return chosen;

	for (i = 0; i < ARRAY_SIZE(abl_chosen_u32_props); i++) {
		const void *val = fdt_getprop(abl, abl_chosen,
					      abl_chosen_u32_props[i], &len);

		if (val && len == sizeof(u32))
			fdt_setprop(blob, chosen, abl_chosen_u32_props[i], val, len);
	}

	cmdline = fdt_getprop(abl, abl_chosen, "bootargs", &len);
	if (!cmdline || len <= 1)
		return 0;

	fdt_setprop_string(blob, chosen, "u-boot,abl-bootargs", cmdline);

	len = abl_cmdline_value(cmdline, "androidboot.btmacaddr=", &value);
	if (len > 0 && !abl_parse_mac(value, len, addr)) {
		/* The Bluetooth binding stores the address in reverse order. */
		for (i = 0; i < 6; i++)
			rev[i] = addr[5 - i];
		abl_set_addr(blob, "qcom,wcn3990-bt", "local-bd-address", rev);
	}

	len = abl_cmdline_value(cmdline, "wifimacaddr=", &value);
	if (len > 0 && !abl_parse_mac(value, len, addr))
		abl_set_addr(blob, "qcom,wcn3990-wifi", "local-mac-address", addr);

	log_info("ABL identity copied to the Linux devicetree\n");
	return 0;
}
