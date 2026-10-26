
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22a74: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   22a78: f9000bfc     	str	x28, [sp, #0x10]
   22a7c: a9024ff4     	stp	x20, x19, [sp, #0x20]
   22a80: 910003fd     	mov	x29, sp
   22a84: d14007ff     	sub	sp, sp, #0x1, lsl #12   // =0x1000
   22a88: d10043ff     	sub	sp, sp, #0x10
   22a8c: d53bd054     	mrs	x20, TPIDR_EL0
   22a90: f9401688     	ldr	x8, [x20, #0x28]
   22a94: 52800200     	mov	w0, #0x10               // =16
   22a98: f81f83a8     	stur	x8, [x29, #-0x8]
   22a9c: 94000ff9     	bl	0x26a80 <malloc@plt>
   22aa0: aa0003f3     	mov	x19, x0
   22aa4: b40007a0     	cbz	x0, 0x22b98 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde30>
   22aa8: b2607fe8     	mov	x8, #-0x100000000       // =-4294967296
   22aac: 910023e0     	add	x0, sp, #0x8
   22ab0: 52820002     	mov	w2, #0x1000             // =4096
   22ab4: 2a1f03e1     	mov	w1, wzr
   22ab8: a900227f     	stp	xzr, x8, [x19]
   22abc: 94000f25     	bl	0x26750 <memset@plt>
   22ac0: b0ffff40     	adrp	x0, 0xb000
   22ac4: f0ffff41     	adrp	x1, 0xd000
   22ac8: 90ffff42     	adrp	x2, 0xa000
   22acc: 910c2c00     	add	x0, x0, #0x30b
   22ad0: 91380c21     	add	x1, x1, #0xe03
   22ad4: 91367042     	add	x2, x2, #0xd9c
   22ad8: 910023e3     	add	x3, sp, #0x8
   22adc: 52820004     	mov	w4, #0x1000             // =4096
   22ae0: 97ffec75     	bl	0x1dcb4 ; fpc_sysfs_path_by_attr <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8f4c>
   22ae4: 340004c0     	cbz	w0, 0x22b7c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde14>
   22ae8: 910023e0     	add	x0, sp, #0x8
   22aec: 2a1f03e1     	mov	w1, wzr
   22af0: 94001078     	bl	0x26cd0 <__open_2@plt>
   22af4: 3100041f     	cmn	w0, #0x1
   22af8: b9000e60     	str	w0, [x19, #0xc]
   22afc: 540002a0     	b.eq	0x22b50 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdde8>
   22b00: 90ffff41     	adrp	x1, 0xa000
   22b04: f0ffff42     	adrp	x2, 0xd000
   22b08: 52801008     	mov	w8, #0x80               // =128
   22b0c: 913b0c21     	add	x1, x1, #0xec3
   22b10: 91111042     	add	x2, x2, #0x444
   22b14: 52801003     	mov	w3, #0x80               // =128
   22b18: aa1303e0     	mov	x0, x19
   22b1c: b9000a68     	str	w8, [x19, #0x8]
   22b20: 940010c4     	bl	0x26e30 <QSEECom_start_app@plt>
   22b24: 340003a0     	cbz	w0, 0x22b98 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde30>
   22b28: d0ffff41     	adrp	x1, 0xc000
   22b2c: d0ffff42     	adrp	x2, 0xc000
   22b30: f0ffff23     	adrp	x3, 0x9000
   22b34: 2a0003e4     	mov	w4, w0
   22b38: 91301421     	add	x1, x1, #0xc05
   22b3c: 913dac42     	add	x2, x2, #0xf6b
   22b40: 913ddc63     	add	x3, x3, #0xf77
   22b44: 528000c0     	mov	w0, #0x6                // =6
   22b48: 94000e9a     	bl	0x265b0 <__android_log_print@plt>
   22b4c: 1400000c     	b	0x22b7c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde14>
   22b50: 94000f3c     	bl	0x26840 <__errno@plt>
   22b54: b9400005     	ldr	w5, [x0]
   22b58: d0ffff41     	adrp	x1, 0xc000
   22b5c: d0ffff42     	adrp	x2, 0xc000
   22b60: f0ffff23     	adrp	x3, 0x9000
   22b64: 91301421     	add	x1, x1, #0xc05
   22b68: 91037842     	add	x2, x2, #0xde
   22b6c: 913ddc63     	add	x3, x3, #0xf77
   22b70: 910023e4     	add	x4, sp, #0x8
   22b74: 528000c0     	mov	w0, #0x6                // =6
   22b78: 94000e8e     	bl	0x265b0 <__android_log_print@plt>
   22b7c: b9400e60     	ldr	w0, [x19, #0xc]
   22b80: 3100041f     	cmn	w0, #0x1
   22b84: 54000040     	b.eq	0x22b8c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde24>
   22b88: 94000fe6     	bl	0x26b20 <close@plt>
   22b8c: aa1303e0     	mov	x0, x19
   22b90: 94000fb8     	bl	0x26a70 <free@plt>
   22b94: aa1f03f3     	mov	x19, xzr
   22b98: f9401688     	ldr	x8, [x20, #0x28]
   22b9c: f85f83a9     	ldur	x9, [x29, #-0x8]
   22ba0: eb09011f     	cmp	x8, x9
   22ba4: 54000101     	b.ne	0x22bc4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde5c>
   22ba8: aa1303e0     	mov	x0, x19
   22bac: 914007ff     	add	sp, sp, #0x1, lsl #12   // =0x1000
   22bb0: 910043ff     	add	sp, sp, #0x10
   22bb4: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   22bb8: f9400bfc     	ldr	x28, [sp, #0x10]
   22bbc: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   22bc0: d65f03c0     	ret
   22bc4: 94000eab     	bl	0x26670 <__stack_chk_fail@plt>
