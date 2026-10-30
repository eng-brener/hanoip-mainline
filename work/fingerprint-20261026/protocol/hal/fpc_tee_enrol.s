
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22434: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   22438: f9000bf5     	str	x21, [sp, #0x10]
   2243c: a9024ff4     	stp	x20, x19, [sp, #0x20]
   22440: 910003fd     	mov	x29, sp
   22444: aa0103f3     	mov	x19, x1
   22448: d0ffff41     	adrp	x1, 0xc000
   2244c: 90ffff42     	adrp	x2, 0xa000
   22450: d0ffff43     	adrp	x3, 0xc000
   22454: aa0003f4     	mov	x20, x0
   22458: 91301421     	add	x1, x1, #0xc05
   2245c: 9103e042     	add	x2, x2, #0xf8
   22460: 913cfc63     	add	x3, x3, #0xf3f
   22464: 52800060     	mov	w0, #0x3                // =3
   22468: 94001052     	bl	0x265b0 <__android_log_print@plt>
   2246c: f9400688     	ldr	x8, [x20, #0x8]
   22470: 90ffff69     	adrp	x9, 0xe000
   22474: fd40ed20     	ldr	d0, [x9, #0x1d8]
   22478: f9400115     	ldr	x21, [x8]
   2247c: fd0002a0     	str	d0, [x21]
   22480: a9400680     	ldp	x0, x1, [x20]
   22484: 9400025b     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   22488: 2a0003f4     	mov	w20, w0
   2248c: 37f801e0     	tbnz	w0, #0x1f, 0x224c8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd760>
   22490: b9400aa8     	ldr	w8, [x21, #0x8]
   22494: 2a1403e0     	mov	w0, w20
   22498: b9000268     	str	w8, [x19]
   2249c: 94000165     	bl	0x22a30 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdcc8>
   224a0: b9400265     	ldr	w5, [x19]
   224a4: d0ffff41     	adrp	x1, 0xc000
   224a8: f0ffff42     	adrp	x2, 0xd000
   224ac: d0ffff43     	adrp	x3, 0xc000
   224b0: aa0003e4     	mov	x4, x0
   224b4: 91301421     	add	x1, x1, #0xc05
   224b8: 9132a842     	add	x2, x2, #0xcaa
   224bc: 913cfc63     	add	x3, x3, #0xf3f
   224c0: 52800060     	mov	w0, #0x3                // =3
   224c4: 9400103b     	bl	0x265b0 <__android_log_print@plt>
   224c8: 2a1403e0     	mov	w0, w20
   224cc: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   224d0: f9400bf5     	ldr	x21, [sp, #0x10]
   224d4: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   224d8: d65f03c0     	ret
