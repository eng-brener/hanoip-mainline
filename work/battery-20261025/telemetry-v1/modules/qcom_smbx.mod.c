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

MODULE_ALIAS("of:N*T*Cmotorola,hanoip-smb5-monitor");
MODULE_ALIAS("of:N*T*Cmotorola,hanoip-smb5-monitorC*");
MODULE_ALIAS("of:N*T*Cqcom,pmi8998-charger");
MODULE_ALIAS("of:N*T*Cqcom,pmi8998-chargerC*");
MODULE_ALIAS("of:N*T*Cqcom,pm660-charger");
MODULE_ALIAS("of:N*T*Cqcom,pm660-chargerC*");
MODULE_ALIAS("of:N*T*Cqcom,pm7250b-charger");
MODULE_ALIAS("of:N*T*Cqcom,pm7250b-chargerC*");
MODULE_ALIAS("of:N*T*Cqcom,pm8150b-charger");
MODULE_ALIAS("of:N*T*Cqcom,pm8150b-chargerC*");
