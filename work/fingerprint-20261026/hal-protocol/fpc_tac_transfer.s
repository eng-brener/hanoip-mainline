
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22df0: d10183ff     	sub	sp, sp, #0x60
   22df4: a9037bfd     	stp	x29, x30, [sp, #0x30]
   22df8: f90023f5     	str	x21, [sp, #0x40]
   22dfc: a9054ff4     	stp	x20, x19, [sp, #0x50]
   22e00: 9100c3fd     	add	x29, sp, #0x30
   22e04: d53bd055     	mrs	x21, TPIDR_EL0
   22e08: f94016a8     	ldr	x8, [x21, #0x28]
   22e0c: 5280008a     	mov	w10, #0x4               // =4
   22e10: 910023e5     	add	x5, sp, #0x8
   22e14: 52800802     	mov	w2, #0x40               // =64
   22e18: f81f83a8     	stur	x8, [x29, #-0x8]
   22e1c: f9400008     	ldr	x8, [x0]
   22e20: b9400829     	ldr	w9, [x1, #0x8]
   22e24: 52800804     	mov	w4, #0x40               // =64
   22e28: f9400108     	ldr	x8, [x8]
   22e2c: b9000109     	str	w9, [x8]
   22e30: a9017fff     	stp	xzr, xzr, [sp, #0x10]
   22e34: f90013ff     	str	xzr, [sp, #0x20]
   22e38: b9401029     	ldr	w9, [x1, #0x10]
   22e3c: aa0803e1     	mov	x1, x8
   22e40: 29012be9     	stp	w9, w10, [sp, #0x8]
   22e44: f9400000     	ldr	x0, [x0]
   22e48: f9400009     	ldr	x9, [x0]
   22e4c: 91010133     	add	x19, x9, #0x40
   22e50: aa1303e3     	mov	x3, x19
   22e54: 94001013     	bl	0x26ea0 <QSEECom_send_modified_cmd@plt>
   22e58: 34000180     	cbz	w0, 0x22e88 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe120>
   22e5c: d0ffff41     	adrp	x1, 0xc000
   22e60: b0ffff42     	adrp	x2, 0xb000
   22e64: d0ffff43     	adrp	x3, 0xc000
   22e68: 2a0003e4     	mov	w4, w0
   22e6c: 91301421     	add	x1, x1, #0xc05
   22e70: 911bf842     	add	x2, x2, #0x6fe
   22e74: 91081063     	add	x3, x3, #0x204
   22e78: 528000c0     	mov	w0, #0x6                // =6
   22e7c: 94000dcd     	bl	0x265b0 <__android_log_print@plt>
   22e80: 128000b4     	mov	w20, #-0x6              // =-6
   22e84: 14000010     	b	0x22ec4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe15c>
   22e88: b9400274     	ldr	w20, [x19]
   22e8c: 36f801d4     	tbz	w20, #0x1f, 0x22ec4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe15c>
   22e90: 2a1403e0     	mov	w0, w20
   22e94: 97fffee7     	bl	0x22a30 ; fpc_error_str <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdcc8>
   22e98: d0ffff41     	adrp	x1, 0xc000
   22e9c: d0ffff42     	adrp	x2, 0xc000
   22ea0: d0ffff43     	adrp	x3, 0xc000
   22ea4: aa0003e5     	mov	x5, x0
   22ea8: 91301421     	add	x1, x1, #0xc05
   22eac: 91112042     	add	x2, x2, #0x448
   22eb0: 91081063     	add	x3, x3, #0x204
   22eb4: 528000c0     	mov	w0, #0x6                // =6
   22eb8: 2a1403e4     	mov	w4, w20
   22ebc: 94000dbd     	bl	0x265b0 <__android_log_print@plt>
   22ec0: b9400274     	ldr	w20, [x19]
   22ec4: f94016a8     	ldr	x8, [x21, #0x28]
   22ec8: f85f83a9     	ldur	x9, [x29, #-0x8]
   22ecc: eb09011f     	cmp	x8, x9
   22ed0: 540000e1     	b.ne	0x22eec <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe184>
   22ed4: 2a1403e0     	mov	w0, w20
   22ed8: a9454ff4     	ldp	x20, x19, [sp, #0x50]
   22edc: f94023f5     	ldr	x21, [sp, #0x40]
   22ee0: a9437bfd     	ldp	x29, x30, [sp, #0x30]
   22ee4: 910183ff     	add	sp, sp, #0x60
   22ee8: d65f03c0     	ret
   22eec: 94000de1     	bl	0x26670 <__stack_chk_fail@plt>
