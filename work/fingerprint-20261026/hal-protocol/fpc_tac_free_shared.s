
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22d64: b4000440     	cbz	x0, 0x22dec <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe084>
   22d68: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   22d6c: f9000bf3     	str	x19, [sp, #0x10]
   22d70: 910003fd     	mov	x29, sp
   22d74: aa0003f3     	mov	x19, x0
   22d78: f9400000     	ldr	x0, [x0]
   22d7c: b100041f     	cmn	x0, #0x1
   22d80: 540001e0     	b.eq	0x22dbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe054>
   22d84: b9400a61     	ldr	w1, [x19, #0x8]
   22d88: 9400103e     	bl	0x26e80 <munmap@plt>
   22d8c: 34000180     	cbz	w0, 0x22dbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe054>
   22d90: 94000eac     	bl	0x26840 <__errno@plt>
   22d94: b9400008     	ldr	w8, [x0]
   22d98: d0ffff41     	adrp	x1, 0xc000
   22d9c: f0ffff42     	adrp	x2, 0xd000
   22da0: f0ffff43     	adrp	x3, 0xd000
   22da4: 4b0803e4     	neg	w4, w8
   22da8: 91301421     	add	x1, x1, #0xc05
   22dac: 911f3042     	add	x2, x2, #0x7cc
   22db0: 911fac63     	add	x3, x3, #0x7eb
   22db4: 528000c0     	mov	w0, #0x6                // =6
   22db8: 94000dfe     	bl	0x265b0 <__android_log_print@plt>
   22dbc: b9401260     	ldr	w0, [x19, #0x10]
   22dc0: 3100041f     	cmn	w0, #0x1
   22dc4: 54000040     	b.eq	0x22dcc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe064>
   22dc8: 94000f56     	bl	0x26b20 <close@plt>
   22dcc: b9400e60     	ldr	w0, [x19, #0xc]
   22dd0: 3100041f     	cmn	w0, #0x1
   22dd4: 54000040     	b.eq	0x22ddc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe074>
   22dd8: 9400102e     	bl	0x26e90 <ion_close@plt>
   22ddc: aa1303e0     	mov	x0, x19
   22de0: f9400bf3     	ldr	x19, [sp, #0x10]
   22de4: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   22de8: 14000f22     	b	0x26a70 <free@plt>
   22dec: d65f03c0     	ret
