#include <linux/module.h>
#include <linux/export-internal.h>
#include <linux/compiler.h>

MODULE_INFO(name, KBUILD_MODNAME);

__visible struct module __this_module
__section(".gnu.linkonce.this_module") = {
	.name = KBUILD_MODNAME,
	.init = init_module,
#ifdef CONFIG_MODULE_UNLOAD
	.exit = cleanup_module,
#endif
	.arch = MODULE_ARCH_INIT,
};


MODULE_INFO(depends, "");

MODULE_ALIAS("of:N*T*Cqcom,spmi-adc5");
MODULE_ALIAS("of:N*T*Cqcom,spmi-adc5C*");
MODULE_ALIAS("of:N*T*Cqcom,spmi-adc7");
MODULE_ALIAS("of:N*T*Cqcom,spmi-adc7C*");
MODULE_ALIAS("of:N*T*Cqcom,spmi-adc-rev2");
MODULE_ALIAS("of:N*T*Cqcom,spmi-adc-rev2C*");
