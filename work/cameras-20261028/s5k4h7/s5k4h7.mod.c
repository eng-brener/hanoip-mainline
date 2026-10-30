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


MODULE_INFO(depends, "v4l2-async,videodev,v4l2-fwnode,mc");

MODULE_ALIAS("of:N*T*Csamsung,s5k4h7");
MODULE_ALIAS("of:N*T*Csamsung,s5k4h7C*");
