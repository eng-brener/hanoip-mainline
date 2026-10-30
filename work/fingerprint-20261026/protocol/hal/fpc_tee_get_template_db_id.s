
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22910: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   22914: a9014ff4     	stp	x20, x19, [sp, #0x10]
   22918: 910003fd     	mov	x29, sp
   2291c: aa0103f3     	mov	x19, x1
   22920: d0ffff41     	adrp	x1, 0xc000
   22924: 90ffff42     	adrp	x2, 0xa000
   22928: f0ffff43     	adrp	x3, 0xd000
   2292c: aa0003f4     	mov	x20, x0
   22930: 91301421     	add	x1, x1, #0xc05
   22934: 9103e042     	add	x2, x2, #0xf8
   22938: 91156463     	add	x3, x3, #0x559
   2293c: 52800060     	mov	w0, #0x3                // =3
   22940: 94000f1c     	bl	0x265b0 <__android_log_print@plt>
   22944: f9400688     	ldr	x8, [x20, #0x8]
   22948: 0f000560     	movi	v0.2s, #0xb
   2294c: f9400108     	ldr	x8, [x8]
   22950: fd000100     	str	d0, [x8]
   22954: a9400680     	ldp	x0, x1, [x20]
   22958: 94000126     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   2295c: 350000a0     	cbnz	w0, 0x22970 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdc08>
   22960: f9400688     	ldr	x8, [x20, #0x8]
   22964: f9400108     	ldr	x8, [x8]
   22968: f9400908     	ldr	x8, [x8, #0x10]
   2296c: f9000268     	str	x8, [x19]
   22970: a9414ff4     	ldp	x20, x19, [sp, #0x10]
   22974: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   22978: d65f03c0     	ret
