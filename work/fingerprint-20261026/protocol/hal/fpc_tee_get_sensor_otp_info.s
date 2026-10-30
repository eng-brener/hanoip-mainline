
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   21ff8: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   21ffc: f9000bf5     	str	x21, [sp, #0x10]
   22000: a9024ff4     	stp	x20, x19, [sp, #0x20]
   22004: 910003fd     	mov	x29, sp
   22008: aa0103f3     	mov	x19, x1
   2200c: d0ffff41     	adrp	x1, 0xc000
   22010: 90ffff42     	adrp	x2, 0xa000
   22014: 90ffff43     	adrp	x3, 0xa000
   22018: aa0003f4     	mov	x20, x0
   2201c: 91301421     	add	x1, x1, #0xc05
   22020: 9103e042     	add	x2, x2, #0xf8
   22024: 912dd063     	add	x3, x3, #0xb74
   22028: 52800060     	mov	w0, #0x3                // =3
   2202c: 94001161     	bl	0x265b0 <__android_log_print@plt>
   22030: f9400288     	ldr	x8, [x20]
   22034: ad418a60     	ldp	q0, q2, [x19, #0x30]
   22038: 3dc01661     	ldr	q1, [x19, #0x50]
   2203c: 528000c1     	mov	w1, #0x6                // =6
   22040: f9400508     	ldr	x8, [x8, #0x8]
   22044: aa1403e0     	mov	x0, x20
   22048: f9400115     	ldr	x21, [x8]
   2204c: f9403268     	ldr	x8, [x19, #0x60]
   22050: 3c8382a0     	stur	q0, [x21, #0x38]
   22054: f90036a8     	str	x8, [x21, #0x68]
   22058: 3c8582a1     	stur	q1, [x21, #0x58]
   2205c: 3c8482a2     	stur	q2, [x21, #0x48]
   22060: ad400660     	ldp	q0, q1, [x19]
   22064: 3dc00a62     	ldr	q2, [x19, #0x20]
   22068: 3c8082a0     	stur	q0, [x21, #0x8]
   2206c: 3c8182a1     	stur	q1, [x21, #0x18]
   22070: 3c8282a2     	stur	q2, [x21, #0x28]
   22074: 97fffd01     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   22078: 2a0003f4     	mov	w20, w0
   2207c: 34000160     	cbz	w0, 0x220a8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd340>
   22080: d0ffff41     	adrp	x1, 0xc000
   22084: d0ffff42     	adrp	x2, 0xc000
   22088: 90ffff43     	adrp	x3, 0xa000
   2208c: 91301421     	add	x1, x1, #0xc05
   22090: 9127ec42     	add	x2, x2, #0x9fb
   22094: 912dd063     	add	x3, x3, #0xb74
   22098: 528000c0     	mov	w0, #0x6                // =6
   2209c: 2a1403e4     	mov	w4, w20
   220a0: 94001144     	bl	0x265b0 <__android_log_print@plt>
   220a4: 1400000c     	b	0x220d4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd36c>
   220a8: 910022a8     	add	x8, x21, #0x8
   220ac: ad408101     	ldp	q1, q0, [x8, #0x10]
   220b0: 3dc00102     	ldr	q2, [x8]
   220b4: ad008261     	stp	q1, q0, [x19, #0x10]
   220b8: 3d800262     	str	q2, [x19]
   220bc: f9403109     	ldr	x9, [x8, #0x60]
   220c0: ad420101     	ldp	q1, q0, [x8, #0x40]
   220c4: 3dc00d02     	ldr	q2, [x8, #0x30]
   220c8: f9003269     	str	x9, [x19, #0x60]
   220cc: ad020261     	stp	q1, q0, [x19, #0x40]
   220d0: 3d800e62     	str	q2, [x19, #0x30]
   220d4: 2a1403e0     	mov	w0, w20
   220d8: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   220dc: f9400bf5     	ldr	x21, [sp, #0x10]
   220e0: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   220e4: d65f03c0     	ret
