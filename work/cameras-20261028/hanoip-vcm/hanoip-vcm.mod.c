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


MODULE_INFO(depends, "v4l2-async,videodev,mc");

MODULE_ALIAS("of:N*T*Cdongwoon,dw9768");
MODULE_ALIAS("of:N*T*Cdongwoon,dw9768C*");
MODULE_ALIAS("of:N*T*Cdongwoon,dw9800");
MODULE_ALIAS("of:N*T*Cdongwoon,dw9800C*");
