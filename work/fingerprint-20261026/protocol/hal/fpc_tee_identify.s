
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22608: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   2260c: f9000bf5     	str	x21, [sp, #0x10]
   22610: a9024ff4     	stp	x20, x19, [sp, #0x20]
   22614: 910003fd     	mov	x29, sp
   22618: aa0103f3     	mov	x19, x1
   2261c: d0ffff41     	adrp	x1, 0xc000
   22620: 90ffff42     	adrp	x2, 0xa000
   22624: b0ffff43     	adrp	x3, 0xb000
   22628: aa0003f4     	mov	x20, x0
   2262c: 91301421     	add	x1, x1, #0xc05
   22630: 9103e042     	add	x2, x2, #0xf8
   22634: 91333863     	add	x3, x3, #0xcce
   22638: 52800060     	mov	w0, #0x3                // =3
   2263c: 94000fdd     	bl	0x265b0 <__android_log_print@plt>
   22640: f9400688     	ldr	x8, [x20, #0x8]
   22644: 90ffff69     	adrp	x9, 0xe000
   22648: fd404920     	ldr	d0, [x9, #0x90]
   2264c: f9400108     	ldr	x8, [x8]
   22650: fd000100     	str	d0, [x8]
   22654: a9400680     	ldp	x0, x1, [x20]
   22658: 940001e6     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   2265c: 2a0003f5     	mov	w21, w0
   22660: 350001c0     	cbnz	w0, 0x22698 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd930>
   22664: f9400688     	ldr	x8, [x20, #0x8]
   22668: d0ffff41     	adrp	x1, 0xc000
   2266c: f0ffff22     	adrp	x2, 0x9000
   22670: b0ffff43     	adrp	x3, 0xb000
   22674: f9400108     	ldr	x8, [x8]
   22678: 91301421     	add	x1, x1, #0xc05
   2267c: 913cfc42     	add	x2, x2, #0xf3f
   22680: 91333863     	add	x3, x3, #0xcce
   22684: b9400909     	ldr	w9, [x8, #0x8]
   22688: 52800060     	mov	w0, #0x3                // =3
   2268c: b9000269     	str	w9, [x19]
   22690: 29419504     	ldp	w4, w5, [x8, #0xc]
   22694: 94000fc7     	bl	0x265b0 <__android_log_print@plt>
   22698: 2a1503e0     	mov	w0, w21
   2269c: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   226a0: f9400bf5     	ldr	x21, [sp, #0x10]
   226a4: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   226a8: d65f03c0     	ret
