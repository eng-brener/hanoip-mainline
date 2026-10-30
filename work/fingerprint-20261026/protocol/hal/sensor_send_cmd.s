
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   21478: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   2147c: f9000bf5     	str	x21, [sp, #0x10]
   21480: a9024ff4     	stp	x20, x19, [sp, #0x20]
   21484: 910003fd     	mov	x29, sp
   21488: b40005c0     	cbz	x0, 0x21540 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7d8>
   2148c: f9400008     	ldr	x8, [x0]
   21490: b4000588     	cbz	x8, 0x21540 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7d8>
   21494: f9400508     	ldr	x8, [x8, #0x8]
   21498: b4000548     	cbz	x8, 0x21540 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7d8>
   2149c: f9400108     	ldr	x8, [x8]
   214a0: 52800149     	mov	w9, #0xa                // =10
   214a4: 2a0103f3     	mov	w19, w1
   214a8: 29000509     	stp	w9, w1, [x8]
   214ac: f9400015     	ldr	x21, [x0]
   214b0: a94006a0     	ldp	x0, x1, [x21]
   214b4: 9400064f     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   214b8: 2a0003f4     	mov	w20, w0
   214bc: 531a7809     	ubfx	w9, w0, #26, #5
   214c0: 2a0003e8     	mov	w8, w0
   214c4: 34000109     	cbz	w9, 0x214e4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc77c>
   214c8: 71007d3f     	cmp	w9, #0x1f
   214cc: 2a1403e8     	mov	w8, w20
   214d0: 540000a0     	b.eq	0x214e4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc77c>
   214d4: 7100029f     	cmp	w20, #0x0
   214d8: 5400036c     	b.gt	0x21544 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7dc>
   214dc: 53146688     	ubfx	w8, w20, #20, #6
   214e0: 4b0803e8     	neg	w8, w8
   214e4: 3100391f     	cmn	w8, #0xe
   214e8: 54000381     	b.ne	0x21558 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7f0>
   214ec: 5284e200     	mov	w0, #0x2710             // =10000
   214f0: 940015ec     	bl	0x26ca0 <usleep@plt>
   214f4: a94006a0     	ldp	x0, x1, [x21]
   214f8: 9400063e     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   214fc: 2a0003f4     	mov	w20, w0
   21500: 531a7809     	ubfx	w9, w0, #26, #5
   21504: 2a0003e8     	mov	w8, w0
   21508: 34000109     	cbz	w9, 0x21528 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7c0>
   2150c: 71007d3f     	cmp	w9, #0x1f
   21510: 2a1403e8     	mov	w8, w20
   21514: 540000a0     	b.eq	0x21528 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7c0>
   21518: 7100029f     	cmp	w20, #0x0
   2151c: 5400014c     	b.gt	0x21544 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7dc>
   21520: 53146688     	ubfx	w8, w20, #20, #6
   21524: 4b0803e8     	neg	w8, w8
   21528: 3100391f     	cmn	w8, #0xe
   2152c: 54000161     	b.ne	0x21558 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7f0>
   21530: 5289c400     	mov	w0, #0x4e20             // =20000
   21534: 940015db     	bl	0x26ca0 <usleep@plt>
   21538: 12800194     	mov	w20, #-0xd              // =-13
   2153c: 14000008     	b	0x2155c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7f4>
   21540: 12800134     	mov	w20, #-0xa              // =-10
   21544: 2a1403e0     	mov	w0, w20
   21548: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   2154c: f9400bf5     	ldr	x21, [sp, #0x10]
   21550: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   21554: d65f03c0     	ret
   21558: 36ffff74     	tbz	w20, #0x1f, 0x21544 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7dc>
   2155c: f0ffff41     	adrp	x1, 0xc000
   21560: f0ffff42     	adrp	x2, 0xc000
   21564: 90ffff63     	adrp	x3, 0xd000
   21568: 91301421     	add	x1, x1, #0xc05
   2156c: 9128c042     	add	x2, x2, #0xa30
   21570: 913a2063     	add	x3, x3, #0xe88
   21574: 528000c0     	mov	w0, #0x6                // =6
   21578: 2a1303e4     	mov	w4, w19
   2157c: 2a1403e5     	mov	w5, w20
   21580: 9400140c     	bl	0x265b0 <__android_log_print@plt>
   21584: 17fffff0     	b	0x21544 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc7dc>
   21588: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   2158c: f9000bf3     	str	x19, [sp, #0x10]
   21590: 910003fd     	mov	x29, sp
   21594: 52800061     	mov	w1, #0x3                // =3
   21598: aa0003f3     	mov	x19, x0
   2159c: 97ffffb7     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   215a0: 34000080     	cbz	w0, 0x215b0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc848>
   215a4: f9400bf3     	ldr	x19, [sp, #0x10]
   215a8: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   215ac: d65f03c0     	ret
   215b0: f9401e60     	ldr	x0, [x19, #0x38]
   215b4: f9400bf3     	ldr	x19, [sp, #0x10]
   215b8: 52800021     	mov	w1, #0x1                // =1
   215bc: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   215c0: 17fff093     	b	0x1d80c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8aa4>
