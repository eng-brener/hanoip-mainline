
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   1df5c: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   1df60: a9014ff4     	stp	x20, x19, [sp, #0x10]
   1df64: 910003fd     	mov	x29, sp
   1df68: 52800020     	mov	w0, #0x1                // =1
   1df6c: 52800c01     	mov	w1, #0x60               // =96
   1df70: 9400233c     	bl	0x26c60 <calloc@plt>
   1df74: aa0003f3     	mov	x19, x0
   1df78: b4000260     	cbz	x0, 0x1dfc4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x925c>
   1df7c: d28dcea8     	mov	x8, #0x6e75             // =28277
   1df80: f2adcd68     	movk	x8, #0x6e6b, lsl #16
   1df84: f2ceede8     	movk	x8, #0x776f, lsl #32
   1df88: f2e00dc8     	movk	x8, #0x6e, lsl #48
   1df8c: f9001268     	str	x8, [x19, #0x20]
   1df90: 940012b9     	bl	0x22a74 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdd0c>
   1df94: f9000260     	str	x0, [x19]
   1df98: b4000100     	cbz	x0, 0x1dfb8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9250>
   1df9c: 52829201     	mov	w1, #0x1490             // =5264
   1dfa0: aa0003f4     	mov	x20, x0
   1dfa4: 94001322     	bl	0x22c2c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdec4>
   1dfa8: f9000660     	str	x0, [x19, #0x8]
   1dfac: b50000c0     	cbnz	x0, 0x1dfc4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x925c>
   1dfb0: aa1403e0     	mov	x0, x20
   1dfb4: 94001305     	bl	0x22bc8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xde60>
   1dfb8: aa1303e0     	mov	x0, x19
   1dfbc: 940022ad     	bl	0x26a70 <free@plt>
   1dfc0: aa1f03f3     	mov	x19, xzr
   1dfc4: aa1303e0     	mov	x0, x19
   1dfc8: a9414ff4     	ldp	x20, x19, [sp, #0x10]
   1dfcc: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   1dfd0: d65f03c0     	ret
