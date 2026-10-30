
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   221a0: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   221a4: f9000bf5     	str	x21, [sp, #0x10]
   221a8: a9024ff4     	stp	x20, x19, [sp, #0x20]
   221ac: 910003fd     	mov	x29, sp
   221b0: b4000380     	cbz	x0, 0x22220 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd4b8>
   221b4: aa0003f5     	mov	x21, x0
   221b8: 52800a00     	mov	w0, #0x50               // =80
   221bc: 94001231     	bl	0x26a80 <malloc@plt>
   221c0: aa0003f3     	mov	x19, x0
   221c4: b4000300     	cbz	x0, 0x22224 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd4bc>
   221c8: 6f00e400     	movi	v0.2d, #0000000000000000
   221cc: aa1303f4     	mov	x20, x19
   221d0: 3c808e80     	str	q0, [x20, #0x8]!
   221d4: aa1403e0     	mov	x0, x20
   221d8: aa1f03e1     	mov	x1, xzr
   221dc: f900267f     	str	xzr, [x19, #0x48]
   221e0: 3c838260     	stur	q0, [x19, #0x38]
   221e4: 3c828260     	stur	q0, [x19, #0x28]
   221e8: 3c818260     	stur	q0, [x19, #0x18]
   221ec: f9000275     	str	x21, [x19]
   221f0: 94001228     	bl	0x26a90 <pthread_mutex_init@plt>
   221f4: aa1303e0     	mov	x0, x19
   221f8: 2a1f03e1     	mov	w1, wzr
   221fc: 97fffc9f     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   22200: 340001c0     	cbz	w0, 0x22238 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd4d0>
   22204: aa1403e0     	mov	x0, x20
   22208: 94001216     	bl	0x26a60 <pthread_mutex_destroy@plt>
   2220c: f9401e60     	ldr	x0, [x19, #0x38]
   22210: b4000040     	cbz	x0, 0x22218 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd4b0>
   22214: 97ffed0f     	bl	0x1d650 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x88e8>
   22218: aa1303e0     	mov	x0, x19
   2221c: 94001215     	bl	0x26a70 <free@plt>
   22220: aa1f03f3     	mov	x19, xzr
   22224: aa1303e0     	mov	x0, x19
   22228: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   2222c: f9400bf5     	ldr	x21, [sp, #0x10]
   22230: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   22234: d65f03c0     	ret
   22238: 97ffed1c     	bl	0x1d6a8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8940>
   2223c: f9001e60     	str	x0, [x19, #0x38]
   22240: b4fffe20     	cbz	x0, 0x22204 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd49c>
   22244: 528000a1     	mov	w1, #0x5                // =5
   22248: aa1303e0     	mov	x0, x19
   2224c: 97fffc8b     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   22250: 35fffda0     	cbnz	w0, 0x22204 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd49c>
   22254: 17fffff4     	b	0x22224 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd4bc>
