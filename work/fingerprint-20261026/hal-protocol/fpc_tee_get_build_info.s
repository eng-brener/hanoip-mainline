
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   1e2e0: a9bc7bfd     	stp	x29, x30, [sp, #-0x40]!
   1e2e4: f9000bf7     	str	x23, [sp, #0x10]
   1e2e8: a90257f6     	stp	x22, x21, [sp, #0x20]
   1e2ec: a9034ff4     	stp	x20, x19, [sp, #0x30]
   1e2f0: 910003fd     	mov	x29, sp
   1e2f4: aa0203f4     	mov	x20, x2
   1e2f8: aa0103f3     	mov	x19, x1
   1e2fc: d0ffff61     	adrp	x1, 0xc000
   1e300: 90ffff62     	adrp	x2, 0xa000
   1e304: f0ffff63     	adrp	x3, 0xd000
   1e308: aa0003f6     	mov	x22, x0
   1e30c: 91301421     	add	x1, x1, #0xc05
   1e310: 9103e042     	add	x2, x2, #0xf8
   1e314: 9104e463     	add	x3, x3, #0x139
   1e318: 52800060     	mov	w0, #0x3                // =3
   1e31c: 940020a5     	bl	0x265b0 <__android_log_print@plt>
   1e320: f94002c0     	ldr	x0, [x22]
   1e324: 52808301     	mov	w1, #0x418              // =1048
   1e328: 94001241     	bl	0x22c2c ; fpc_tac_alloc_shared <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdec4>
   1e32c: b40002e0     	cbz	x0, 0x1e388 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9620>
   1e330: 90ffff88     	adrp	x8, 0xe000
   1e334: f9400017     	ldr	x23, [x0]
   1e338: fd40b500     	ldr	d0, [x8, #0x168]
   1e33c: 52808008     	mov	w8, #0x400              // =1024
   1e340: aa0003f5     	mov	x21, x0
   1e344: b90016e8     	str	w8, [x23, #0x14]
   1e348: fd0002e0     	str	d0, [x23]
   1e34c: f94002c0     	ldr	x0, [x22]
   1e350: aa1503e1     	mov	x1, x21
   1e354: 940012a7     	bl	0x22df0 ; fpc_tac_transfer <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   1e358: 2a0003f6     	mov	w22, w0
   1e35c: 340001a0     	cbz	w0, 0x1e390 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9628>
   1e360: d0ffff61     	adrp	x1, 0xc000
   1e364: d0ffff62     	adrp	x2, 0xc000
   1e368: f0ffff63     	adrp	x3, 0xd000
   1e36c: 91301421     	add	x1, x1, #0xc05
   1e370: 91267042     	add	x2, x2, #0x99c
   1e374: 9104e463     	add	x3, x3, #0x139
   1e378: 528000c0     	mov	w0, #0x6                // =6
   1e37c: 2a1603e4     	mov	w4, w22
   1e380: 9400208c     	bl	0x265b0 <__android_log_print@plt>
   1e384: 14000007     	b	0x1e3a0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9638>
   1e388: 12800016     	mov	w22, #-0x1              // =-1
   1e38c: 14000007     	b	0x1e3a8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9640>
   1e390: b4000093     	cbz	x19, 0x1e3a0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9638>
   1e394: aa1703e0     	mov	x0, x23
   1e398: aa1403e1     	mov	x1, x20
   1e39c: d63f0260     	blr	x19
   1e3a0: aa1503e0     	mov	x0, x21
   1e3a4: 94001270     	bl	0x22d64 ; fpc_tac_free_shared <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdffc>
   1e3a8: 2a1603e0     	mov	w0, w22
   1e3ac: a9434ff4     	ldp	x20, x19, [sp, #0x30]
   1e3b0: a94257f6     	ldp	x22, x21, [sp, #0x20]
   1e3b4: f9400bf7     	ldr	x23, [sp, #0x10]
   1e3b8: a8c47bfd     	ldp	x29, x30, [sp], #0x40
   1e3bc: d65f03c0     	ret
