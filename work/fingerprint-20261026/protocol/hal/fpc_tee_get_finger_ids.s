
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   227ac: a9bc7bfd     	stp	x29, x30, [sp, #-0x40]!
   227b0: f9000bf7     	str	x23, [sp, #0x10]
   227b4: a90257f6     	stp	x22, x21, [sp, #0x20]
   227b8: a9034ff4     	stp	x20, x19, [sp, #0x30]
   227bc: 910003fd     	mov	x29, sp
   227c0: aa0203f3     	mov	x19, x2
   227c4: aa0103f4     	mov	x20, x1
   227c8: d0ffff41     	adrp	x1, 0xc000
   227cc: 90ffff42     	adrp	x2, 0xa000
   227d0: f0ffff43     	adrp	x3, 0xd000
   227d4: aa0003f5     	mov	x21, x0
   227d8: 91301421     	add	x1, x1, #0xc05
   227dc: 9103e042     	add	x2, x2, #0xf8
   227e0: 91102c63     	add	x3, x3, #0x40b
   227e4: 52800060     	mov	w0, #0x3                // =3
   227e8: 94000f72     	bl	0x265b0 <__android_log_print@plt>
   227ec: f94006a8     	ldr	x8, [x21, #0x8]
   227f0: aa1503e0     	mov	x0, x21
   227f4: f9400116     	ldr	x22, [x8]
   227f8: b9400288     	ldr	w8, [x20]
   227fc: b9000ac8     	str	w8, [x22, #0x8]
   22800: b9400297     	ldr	w23, [x20]
   22804: 97ffef6f     	bl	0x1e5c0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9858>
   22808: 6b0002ff     	cmp	w23, w0
   2280c: 540000a8     	b.hi	0x22820 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdab8>
   22810: aa1503e0     	mov	x0, x21
   22814: 97ffef6b     	bl	0x1e5c0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9858>
   22818: 7100641f     	cmp	w0, #0x19
   2281c: 540000e9     	b.ls	0x22838 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdad0>
   22820: 12800120     	mov	w0, #-0xa               // =-10
   22824: a9434ff4     	ldp	x20, x19, [sp, #0x30]
   22828: a94257f6     	ldp	x22, x21, [sp, #0x20]
   2282c: f9400bf7     	ldr	x23, [sp, #0x10]
   22830: a8c47bfd     	ldp	x29, x30, [sp], #0x40
   22834: d65f03c0     	ret
   22838: f94006a8     	ldr	x8, [x21, #0x8]
   2283c: 90ffff69     	adrp	x9, 0xe000
   22840: fd40dd20     	ldr	d0, [x9, #0x1b8]
   22844: f9400108     	ldr	x8, [x8]
   22848: fd000100     	str	d0, [x8]
   2284c: a94006a0     	ldp	x0, x1, [x21]
   22850: 94000168     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   22854: 35fffe80     	cbnz	w0, 0x22824 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdabc>
   22858: b9400284     	ldr	w4, [x20]
   2285c: b9400ac5     	ldr	w5, [x22, #0x8]
   22860: 6b05009f     	cmp	w4, w5
   22864: 54000162     	b.hs	0x22890 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdb28>
   22868: d0ffff41     	adrp	x1, 0xc000
   2286c: 90ffff42     	adrp	x2, 0xa000
   22870: f0ffff43     	adrp	x3, 0xd000
   22874: 91301421     	add	x1, x1, #0xc05
   22878: 9124c842     	add	x2, x2, #0x932
   2287c: 91102c63     	add	x3, x3, #0x40b
   22880: 528000c0     	mov	w0, #0x6                // =6
   22884: 94000f4b     	bl	0x265b0 <__android_log_print@plt>
   22888: 12800120     	mov	w0, #-0xa               // =-10
   2288c: 17ffffe6     	b	0x22824 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdabc>
   22890: 910032c1     	add	x1, x22, #0xc
   22894: d37ef4a2     	lsl	x2, x5, #2
   22898: aa1303e0     	mov	x0, x19
   2289c: b9000285     	str	w5, [x20]
   228a0: 94000f84     	bl	0x266b0 <memcpy@plt>
   228a4: 2a1f03e0     	mov	w0, wzr
   228a8: 17ffffdf     	b	0x22824 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdabc>
