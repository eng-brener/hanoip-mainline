
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   223e0: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   223e4: f9000bf3     	str	x19, [sp, #0x10]
   223e8: 910003fd     	mov	x29, sp
   223ec: d0ffff41     	adrp	x1, 0xc000
   223f0: 90ffff42     	adrp	x2, 0xa000
   223f4: d0ffff43     	adrp	x3, 0xc000
   223f8: aa0003f3     	mov	x19, x0
   223fc: 91301421     	add	x1, x1, #0xc05
   22400: 9103e042     	add	x2, x2, #0xf8
   22404: 91074c63     	add	x3, x3, #0x1d3
   22408: 52800060     	mov	w0, #0x3                // =3
   2240c: 94001069     	bl	0x265b0 <__android_log_print@plt>
   22410: f9400668     	ldr	x8, [x19, #0x8]
   22414: 90ffff69     	adrp	x9, 0xe000
   22418: fd40a520     	ldr	d0, [x9, #0x148]
   2241c: f9400108     	ldr	x8, [x8]
   22420: fd000100     	str	d0, [x8]
   22424: a9400660     	ldp	x0, x1, [x19]
   22428: f9400bf3     	ldr	x19, [sp, #0x10]
   2242c: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   22430: 14000270     	b	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
