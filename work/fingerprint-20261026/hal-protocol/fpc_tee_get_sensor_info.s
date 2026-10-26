
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   1e7f0: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   1e7f4: a90157f6     	stp	x22, x21, [sp, #0x10]
   1e7f8: a9024ff4     	stp	x20, x19, [sp, #0x20]
   1e7fc: 910003fd     	mov	x29, sp
   1e800: aa0203f3     	mov	x19, x2
   1e804: aa0103f4     	mov	x20, x1
   1e808: d0ffff61     	adrp	x1, 0xc000
   1e80c: 90ffff62     	adrp	x2, 0xa000
   1e810: d0ffff63     	adrp	x3, 0xc000
   1e814: aa0003f5     	mov	x21, x0
   1e818: 91301421     	add	x1, x1, #0xc05
   1e81c: 9103e042     	add	x2, x2, #0xf8
   1e820: 913a8463     	add	x3, x3, #0xea1
   1e824: 52800060     	mov	w0, #0x3                // =3
   1e828: 94001f62     	bl	0x265b0 <__android_log_print@plt>
   1e82c: f94006a8     	ldr	x8, [x21, #0x8]
   1e830: 90ffff89     	adrp	x9, 0xe000
   1e834: fd40e520     	ldr	d0, [x9, #0x1c8]
   1e838: f9400116     	ldr	x22, [x8]
   1e83c: f90006df     	str	xzr, [x22, #0x8]
   1e840: fd0002c0     	str	d0, [x22]
   1e844: a94006a0     	ldp	x0, x1, [x21]
   1e848: 9400116a     	bl	0x22df0 ; fpc_tac_transfer <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   1e84c: 394022c8     	ldrb	w8, [x22, #0x8]
   1e850: 39000288     	strb	w8, [x20]
   1e854: 394026c8     	ldrb	w8, [x22, #0x9]
   1e858: 39000268     	strb	w8, [x19]
   1e85c: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   1e860: a94157f6     	ldp	x22, x21, [sp, #0x10]
   1e864: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   1e868: d65f03c0     	ret
