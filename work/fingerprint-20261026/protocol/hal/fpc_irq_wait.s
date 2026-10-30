
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   1d80c: d10203ff     	sub	sp, sp, #0x80
   1d810: a9037bfd     	stp	x29, x30, [sp, #0x30]
   1d814: f90023f9     	str	x25, [sp, #0x40]
   1d818: a9055ff8     	stp	x24, x23, [sp, #0x50]
   1d81c: a90657f6     	stp	x22, x21, [sp, #0x60]
   1d820: a9074ff4     	stp	x20, x19, [sp, #0x70]
   1d824: 9100c3fd     	add	x29, sp, #0x30
   1d828: d53bd057     	mrs	x23, TPIDR_EL0
   1d82c: f94016e8     	ldr	x8, [x23, #0x28]
   1d830: aa0003f4     	mov	x20, x0
   1d834: 2a0103f5     	mov	w21, w1
   1d838: b0ffff61     	adrp	x1, 0xa000
   1d83c: f81f83a8     	stur	x8, [x29, #-0x8]
   1d840: b9400000     	ldr	w0, [x0]
   1d844: 91014421     	add	x1, x1, #0x51
   1d848: 52810002     	mov	w2, #0x800              // =2048
   1d84c: 94002535     	bl	0x26d20 <__openat_2@plt>
   1d850: 3100041f     	cmn	w0, #0x1
   1d854: 540004a0     	b.eq	0x1d8e8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8b80>
   1d858: b0ffff76     	adrp	x22, 0xa000
   1d85c: 2a0003f3     	mov	w19, w0
   1d860: 52800038     	mov	w24, #0x1               // =1
   1d864: 52800159     	mov	w25, #0xa               // =10
   1d868: 910146d6     	add	x22, x22, #0x51
   1d86c: 910053e1     	add	x1, sp, #0x14
   1d870: 52800022     	mov	w2, #0x1                // =1
   1d874: 2a1303e0     	mov	w0, w19
   1d878: 390053ff     	strb	wzr, [sp, #0x14]
   1d87c: 94002519     	bl	0x26ce0 <read@plt>
   1d880: 37f804e0     	tbnz	w0, #0x1f, 0x1d91c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8bb4>
   1d884: 34000620     	cbz	w0, 0x1d948 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8be0>
   1d888: 394053e8     	ldrb	w8, [sp, #0x14]
   1d88c: 5100c108     	sub	w8, w8, #0x30
   1d890: 6b15011f     	cmp	w8, w21
   1d894: 540005e0     	b.eq	0x1d950 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8be8>
   1d898: 290367f3     	stp	w19, w25, [sp, #0x18]
   1d89c: b9400688     	ldr	w8, [x20, #0x4]
   1d8a0: 910063e0     	add	x0, sp, #0x18
   1d8a4: 52800041     	mov	w1, #0x2                // =2
   1d8a8: 12800002     	mov	w2, #-0x1               // =-1
   1d8ac: 290463e8     	stp	w8, w24, [sp, #0x20]
   1d8b0: 94002520     	bl	0x26d30 <poll@plt>
   1d8b4: 3100041f     	cmn	w0, #0x1
   1d8b8: 54000560     	b.eq	0x1d964 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8bfc>
   1d8bc: 79c04fe8     	ldrsh	w8, [sp, #0x26]
   1d8c0: 350006c8     	cbnz	w8, 0x1d998 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8c30>
   1d8c4: 2a1303e0     	mov	w0, w19
   1d8c8: 94002496     	bl	0x26b20 <close@plt>
   1d8cc: b9400280     	ldr	w0, [x20]
   1d8d0: 52810002     	mov	w2, #0x800              // =2048
   1d8d4: aa1603e1     	mov	x1, x22
   1d8d8: 94002512     	bl	0x26d20 <__openat_2@plt>
   1d8dc: 2a0003f3     	mov	w19, w0
   1d8e0: 3100041f     	cmn	w0, #0x1
   1d8e4: 54fffc41     	b.ne	0x1d86c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8b04>
   1d8e8: 940023d6     	bl	0x26840 <__errno@plt>
   1d8ec: b9400008     	ldr	w8, [x0]
   1d8f0: f0ffff61     	adrp	x1, 0xc000
   1d8f4: b0ffff62     	adrp	x2, 0xa000
   1d8f8: f0ffff63     	adrp	x3, 0xc000
   1d8fc: 4b0803e4     	neg	w4, w8
   1d900: 91301421     	add	x1, x1, #0xc05
   1d904: 9116c442     	add	x2, x2, #0x5b1
   1d908: 91303463     	add	x3, x3, #0xc0d
   1d90c: 528000c0     	mov	w0, #0x6                // =6
   1d910: 94002328     	bl	0x265b0 <__android_log_print@plt>
   1d914: 128000b4     	mov	w20, #-0x6              // =-6
   1d918: 14000032     	b	0x1d9e0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8c78>
   1d91c: 940023c9     	bl	0x26840 <__errno@plt>
   1d920: b9400008     	ldr	w8, [x0]
   1d924: f0ffff61     	adrp	x1, 0xc000
   1d928: 90ffff82     	adrp	x2, 0xd000
   1d92c: f0ffff63     	adrp	x3, 0xc000
   1d930: 4b0803e4     	neg	w4, w8
   1d934: 91301421     	add	x1, x1, #0xc05
   1d938: 910f6042     	add	x2, x2, #0x3d8
   1d93c: 91303463     	add	x3, x3, #0xc0d
   1d940: 528000c0     	mov	w0, #0x6                // =6
   1d944: 9400231b     	bl	0x265b0 <__android_log_print@plt>
   1d948: 128000b4     	mov	w20, #-0x6              // =-6
   1d94c: 14000002     	b	0x1d954 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8bec>
   1d950: 2a1f03f4     	mov	w20, wzr
   1d954: 2a1303e0     	mov	w0, w19
   1d958: 94002472     	bl	0x26b20 <close@plt>
   1d95c: 35000434     	cbnz	w20, 0x1d9e0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8c78>
   1d960: 14000029     	b	0x1da04 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8c9c>
   1d964: 940023b7     	bl	0x26840 <__errno@plt>
   1d968: b9400008     	ldr	w8, [x0]
   1d96c: f0ffff61     	adrp	x1, 0xc000
   1d970: b0ffff62     	adrp	x2, 0xa000
   1d974: f0ffff63     	adrp	x3, 0xc000
   1d978: 4b0803e4     	neg	w4, w8
   1d97c: 91301421     	add	x1, x1, #0xc05
   1d980: 91015442     	add	x2, x2, #0x55
   1d984: 91303463     	add	x3, x3, #0xc0d
   1d988: 528000c0     	mov	w0, #0x6                // =6
   1d98c: 94002309     	bl	0x265b0 <__android_log_print@plt>
   1d990: 128000b4     	mov	w20, #-0x6              // =-6
   1d994: 14000011     	b	0x1d9d8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8c70>
   1d998: b9401be4     	ldr	w4, [sp, #0x18]
   1d99c: 79c03be5     	ldrsh	w5, [sp, #0x1c]
   1d9a0: 79c03fe6     	ldrsh	w6, [sp, #0x1e]
   1d9a4: b94023e7     	ldr	w7, [sp, #0x20]
   1d9a8: 79c04be9     	ldrsh	w9, [sp, #0x24]
   1d9ac: f0ffff61     	adrp	x1, 0xc000
   1d9b0: f0ffff62     	adrp	x2, 0xc000
   1d9b4: f0ffff63     	adrp	x3, 0xc000
   1d9b8: 91301421     	add	x1, x1, #0xc05
   1d9bc: 9103cc42     	add	x2, x2, #0xf3
   1d9c0: 91303463     	add	x3, x3, #0xc0d
   1d9c4: 528000c0     	mov	w0, #0x6                // =6
   1d9c8: b9000be8     	str	w8, [sp, #0x8]
   1d9cc: b90003e9     	str	w9, [sp]
   1d9d0: 940022f8     	bl	0x265b0 <__android_log_print@plt>
   1d9d4: 128000d4     	mov	w20, #-0x7              // =-7
   1d9d8: 2a1303e0     	mov	w0, w19
   1d9dc: 94002451     	bl	0x26b20 <close@plt>
   1d9e0: f0ffff61     	adrp	x1, 0xc000
   1d9e4: 90ffff82     	adrp	x2, 0xd000
   1d9e8: f0ffff63     	adrp	x3, 0xc000
   1d9ec: 91301421     	add	x1, x1, #0xc05
   1d9f0: 91259842     	add	x2, x2, #0x966
   1d9f4: 91303463     	add	x3, x3, #0xc0d
   1d9f8: 528000c0     	mov	w0, #0x6                // =6
   1d9fc: 2a1403e4     	mov	w4, w20
   1da00: 940022ec     	bl	0x265b0 <__android_log_print@plt>
   1da04: f94016e8     	ldr	x8, [x23, #0x28]
   1da08: f85f83a9     	ldur	x9, [x29, #-0x8]
   1da0c: eb09011f     	cmp	x8, x9
   1da10: 54000121     	b.ne	0x1da34 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8ccc>
   1da14: 2a1403e0     	mov	w0, w20
   1da18: a9474ff4     	ldp	x20, x19, [sp, #0x70]
   1da1c: a94657f6     	ldp	x22, x21, [sp, #0x60]
   1da20: a9455ff8     	ldp	x24, x23, [sp, #0x50]
   1da24: f94023f9     	ldr	x25, [sp, #0x40]
   1da28: a9437bfd     	ldp	x29, x30, [sp, #0x30]
   1da2c: 910203ff     	add	sp, sp, #0x80
   1da30: d65f03c0     	ret
   1da34: 9400230f     	bl	0x26670 <__stack_chk_fail@plt>
