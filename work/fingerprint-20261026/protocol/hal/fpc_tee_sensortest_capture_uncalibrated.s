
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   204b4: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   204b8: f9000bf3     	str	x19, [sp, #0x10]
   204bc: 910003fd     	mov	x29, sp
   204c0: 90ffff61     	adrp	x1, 0xc000
   204c4: d0ffff42     	adrp	x2, 0xa000
   204c8: b0ffff43     	adrp	x3, 0x9000
   204cc: aa0003f3     	mov	x19, x0
   204d0: 91301421     	add	x1, x1, #0xc05
   204d4: 9103e042     	add	x2, x2, #0xf8
   204d8: 913c5c63     	add	x3, x3, #0xf17
   204dc: 52800060     	mov	w0, #0x3                // =3
   204e0: 94001834     	bl	0x265b0 <__android_log_print@plt>
   204e4: f9400268     	ldr	x8, [x19]
   204e8: d0ffff6a     	adrp	x10, 0xe000
   204ec: fd40a940     	ldr	d0, [x10, #0x150]
   204f0: f9400bf3     	ldr	x19, [sp, #0x10]
   204f4: f9400509     	ldr	x9, [x8, #0x8]
   204f8: f9400129     	ldr	x9, [x9]
   204fc: fd000120     	str	d0, [x9]
   20500: a9400500     	ldp	x0, x1, [x8]
   20504: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   20508: 14000a3a     	b	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
