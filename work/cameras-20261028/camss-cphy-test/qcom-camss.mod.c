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


MODULE_INFO(depends, "videobuf2-v4l2,videobuf2-dma-sg,videodev,mc,v4l2-async,videobuf2-common,v4l2-fwnode");

MODULE_ALIAS("of:N*T*Cqcom,msm8916-camss");
MODULE_ALIAS("of:N*T*Cqcom,msm8916-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8939-camss");
MODULE_ALIAS("of:N*T*Cqcom,msm8939-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8953-camss");
MODULE_ALIAS("of:N*T*Cqcom,msm8953-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,msm8996-camss");
MODULE_ALIAS("of:N*T*Cqcom,msm8996-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,qcm2290-camss");
MODULE_ALIAS("of:N*T*Cqcom,qcm2290-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,qcs8300-camss");
MODULE_ALIAS("of:N*T*Cqcom,qcs8300-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sa8775p-camss");
MODULE_ALIAS("of:N*T*Cqcom,sa8775p-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sc7280-camss");
MODULE_ALIAS("of:N*T*Cqcom,sc7280-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sc8280xp-camss");
MODULE_ALIAS("of:N*T*Cqcom,sc8280xp-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sdm660-camss");
MODULE_ALIAS("of:N*T*Cqcom,sdm660-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sdm670-camss");
MODULE_ALIAS("of:N*T*Cqcom,sdm670-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sdm845-camss");
MODULE_ALIAS("of:N*T*Cqcom,sdm845-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sm6150-camss");
MODULE_ALIAS("of:N*T*Cqcom,sm6150-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sm6350-camss");
MODULE_ALIAS("of:N*T*Cqcom,sm6350-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sm7150-camss");
MODULE_ALIAS("of:N*T*Cqcom,sm7150-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sm8250-camss");
MODULE_ALIAS("of:N*T*Cqcom,sm8250-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sm8550-camss");
MODULE_ALIAS("of:N*T*Cqcom,sm8550-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,sm8650-camss");
MODULE_ALIAS("of:N*T*Cqcom,sm8650-camssC*");
MODULE_ALIAS("of:N*T*Cqcom,x1e80100-camss");
MODULE_ALIAS("of:N*T*Cqcom,x1e80100-camssC*");
