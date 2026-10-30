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

MODULE_ALIAS("of:N*T*Cqcom,msm8226-cci");
MODULE_ALIAS("of:N*T*Cqcom,msm8226-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8953-cci");
MODULE_ALIAS("of:N*T*Cqcom,msm8953-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8974-cci");
MODULE_ALIAS("of:N*T*Cqcom,msm8974-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8996-cci");
MODULE_ALIAS("of:N*T*Cqcom,msm8996-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8916-cci");
MODULE_ALIAS("of:N*T*Cqcom,msm8916-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,sdm845-cci");
MODULE_ALIAS("of:N*T*Cqcom,sdm845-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,sm8250-cci");
MODULE_ALIAS("of:N*T*Cqcom,sm8250-cciC*");
MODULE_ALIAS("of:N*T*Cqcom,sm8450-cci");
MODULE_ALIAS("of:N*T*Cqcom,sm8450-cciC*");
