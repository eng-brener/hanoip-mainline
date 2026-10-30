
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   2273c: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   22740: a9014ff4     	stp	x20, x19, [sp, #0x10]
   22744: 910003fd     	mov	x29, sp
   22748: aa0103f3     	mov	x19, x1
   2274c: d0ffff41     	adrp	x1, 0xc000
   22750: 90ffff42     	adrp	x2, 0xa000
   22754: f0ffff43     	adrp	x3, 0xd000
   22758: aa0003f4     	mov	x20, x0
   2275c: 91301421     	add	x1, x1, #0xc05
   22760: 9103e042     	add	x2, x2, #0xf8
   22764: 91150463     	add	x3, x3, #0x541
   22768: 52800060     	mov	w0, #0x3                // =3
   2276c: 94000f91     	bl	0x265b0 <__android_log_print@plt>
   22770: f9400688     	ldr	x8, [x20, #0x8]
   22774: 90ffff69     	adrp	x9, 0xe000
   22778: fd40c120     	ldr	d0, [x9, #0x180]
   2277c: f9400108     	ldr	x8, [x8]
   22780: fd000100     	str	d0, [x8]
   22784: a9400680     	ldp	x0, x1, [x20]
   22788: 9400019a     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   2278c: 350000a0     	cbnz	w0, 0x227a0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xda38>
   22790: f9400688     	ldr	x8, [x20, #0x8]
   22794: f9400108     	ldr	x8, [x8]
   22798: b9400908     	ldr	w8, [x8, #0x8]
   2279c: b9000268     	str	w8, [x19]
   227a0: a9414ff4     	ldp	x20, x19, [sp, #0x10]
   227a4: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   227a8: d65f03c0     	ret
