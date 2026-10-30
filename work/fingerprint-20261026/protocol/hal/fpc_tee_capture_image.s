
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   2163c: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   21640: a90157f6     	stp	x22, x21, [sp, #0x10]
   21644: a9024ff4     	stp	x20, x19, [sp, #0x20]
   21648: 910003fd     	mov	x29, sp
   2164c: f0ffff55     	adrp	x21, 0xc000
   21650: 90ffff76     	adrp	x22, 0xd000
   21654: 913016b5     	add	x21, x21, #0xc05
   21658: f0ffff42     	adrp	x2, 0xc000
   2165c: 910fd6d6     	add	x22, x22, #0x3f5
   21660: 2a0103f3     	mov	w19, w1
   21664: aa0003f4     	mov	x20, x0
   21668: 911ca442     	add	x2, x2, #0x729
   2166c: 52800060     	mov	w0, #0x3                // =3
   21670: aa1503e1     	mov	x1, x21
   21674: aa1603e3     	mov	x3, x22
   21678: 940013ce     	bl	0x265b0 <__android_log_print@plt>
   2167c: aa1403e0     	mov	x0, x20
   21680: 2a1303e1     	mov	w1, w19
   21684: 2a1f03e2     	mov	w2, wzr
   21688: aa1f03e3     	mov	x3, xzr
   2168c: 9400000d     	bl	0x216c0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc958>
   21690: 90ffff42     	adrp	x2, 0x9000
   21694: 2a0003f3     	mov	w19, w0
   21698: 91274042     	add	x2, x2, #0x9d0
   2169c: 52800060     	mov	w0, #0x3                // =3
   216a0: aa1503e1     	mov	x1, x21
   216a4: aa1603e3     	mov	x3, x22
   216a8: 940013c2     	bl	0x265b0 <__android_log_print@plt>
   216ac: 2a1303e0     	mov	w0, w19
   216b0: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   216b4: a94157f6     	ldp	x22, x21, [sp, #0x10]
   216b8: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   216bc: d65f03c0     	ret
