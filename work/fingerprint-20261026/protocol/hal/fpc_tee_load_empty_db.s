
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   2297c: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   22980: f9000bf3     	str	x19, [sp, #0x10]
   22984: 910003fd     	mov	x29, sp
   22988: d0ffff41     	adrp	x1, 0xc000
   2298c: 90ffff42     	adrp	x2, 0xa000
   22990: 90ffff43     	adrp	x3, 0xa000
   22994: aa0003f3     	mov	x19, x0
   22998: 91301421     	add	x1, x1, #0xc05
   2299c: 9103e042     	add	x2, x2, #0xf8
   229a0: 9119a463     	add	x3, x3, #0x669
   229a4: 52800060     	mov	w0, #0x3                // =3
   229a8: 94000f02     	bl	0x265b0 <__android_log_print@plt>
   229ac: f9400668     	ldr	x8, [x19, #0x8]
   229b0: 90ffff69     	adrp	x9, 0xe000
   229b4: fd405120     	ldr	d0, [x9, #0xa0]
   229b8: f9400108     	ldr	x8, [x8]
   229bc: fd000100     	str	d0, [x8]
   229c0: a9400660     	ldp	x0, x1, [x19]
   229c4: f9400bf3     	ldr	x19, [sp, #0x10]
   229c8: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   229cc: 14000109     	b	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
