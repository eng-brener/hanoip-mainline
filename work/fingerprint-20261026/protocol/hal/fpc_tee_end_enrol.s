
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   224dc: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   224e0: f9000bf5     	str	x21, [sp, #0x10]
   224e4: a9024ff4     	stp	x20, x19, [sp, #0x20]
   224e8: 910003fd     	mov	x29, sp
   224ec: aa0103f3     	mov	x19, x1
   224f0: d0ffff41     	adrp	x1, 0xc000
   224f4: 90ffff42     	adrp	x2, 0xa000
   224f8: d0ffff43     	adrp	x3, 0xc000
   224fc: aa0003f4     	mov	x20, x0
   22500: 91301421     	add	x1, x1, #0xc05
   22504: 9103e042     	add	x2, x2, #0xf8
   22508: 91201863     	add	x3, x3, #0x806
   2250c: 52800060     	mov	w0, #0x3                // =3
   22510: 94001028     	bl	0x265b0 <__android_log_print@plt>
   22514: f9400688     	ldr	x8, [x20, #0x8]
   22518: 90ffff69     	adrp	x9, 0xe000
   2251c: fd407920     	ldr	d0, [x9, #0xf0]
   22520: f9400115     	ldr	x21, [x8]
   22524: fd0002a0     	str	d0, [x21]
   22528: a9400680     	ldp	x0, x1, [x20]
   2252c: 94000231     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   22530: 35000060     	cbnz	w0, 0x2253c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd7d4>
   22534: b9400aa8     	ldr	w8, [x21, #0x8]
   22538: b9000268     	str	w8, [x19]
   2253c: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   22540: f9400bf5     	ldr	x21, [sp, #0x10]
   22544: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   22548: d65f03c0     	ret
