
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   17b40: d102c3ff     	sub	sp, sp, #0xb0
   17b44: a9077bfd     	stp	x29, x30, [sp, #0x70]
   17b48: f90043f7     	str	x23, [sp, #0x80]
   17b4c: a90957f6     	stp	x22, x21, [sp, #0x90]
   17b50: a90a4ff4     	stp	x20, x19, [sp, #0xa0]
   17b54: 9101c3fd     	add	x29, sp, #0x70
   17b58: d53bd057     	mrs	x23, TPIDR_EL0
   17b5c: f94016e8     	ldr	x8, [x23, #0x28]
   17b60: aa0203f5     	mov	x21, x2
   17b64: f0ffff82     	adrp	x2, 0xa000
   17b68: f0ffff83     	adrp	x3, 0xa000
   17b6c: aa0103f6     	mov	x22, x1
   17b70: aa0003f3     	mov	x19, x0
   17b74: 9103e042     	add	x2, x2, #0xf8
   17b78: 91000c63     	add	x3, x3, #0x3
   17b7c: 52800060     	mov	w0, #0x3                // =3
   17b80: aa1f03e1     	mov	x1, xzr
   17b84: f81f83a8     	stur	x8, [x29, #-0x8]
   17b88: 94003a8a     	bl	0x265b0 <__android_log_print@plt>
   17b8c: 6f00e400     	movi	v0.2d, #0000000000000000
   17b90: 52822100     	mov	w0, #0x1108             // =4360
   17b94: f900027f     	str	xzr, [x19]
   17b98: 3c84c3e0     	stur	q0, [sp, #0x4c]
   17b9c: ad0183e0     	stp	q0, q0, [sp, #0x30]
   17ba0: ad0083e0     	stp	q0, q0, [sp, #0x10]
   17ba4: 3d8003e0     	str	q0, [sp]
   17ba8: 94003bb6     	bl	0x26a80 <malloc@plt>
   17bac: b40008c0     	cbz	x0, 0x17cc4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f5c>
   17bb0: 52821f02     	mov	w2, #0x10f8             // =4344
   17bb4: 2a1f03e1     	mov	w1, wzr
   17bb8: aa0003f4     	mov	x20, x0
   17bbc: 94003ae5     	bl	0x26750 <memset@plt>
   17bc0: 12800008     	mov	w8, #-0x1               // =-1
   17bc4: 91008280     	add	x0, x20, #0x20
   17bc8: aa1f03e1     	mov	x1, xzr
   17bcc: f9087e96     	str	x22, [x20, #0x10f8]
   17bd0: f9088295     	str	x21, [x20, #0x1100]
   17bd4: b9008a88     	str	w8, [x20, #0x88]
   17bd8: 94003bae     	bl	0x26a90 <pthread_mutex_init@plt>
   17bdc: 940018e0     	bl	0x1df5c ; fpc_tee_init <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x91f4>
   17be0: f9003a80     	str	x0, [x20, #0x70]
   17be4: b40007a0     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17be8: 940019f6     	bl	0x1e3c0 ; fpc_tee_log_build_info <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9658>
   17bec: 34000100     	cbz	w0, 0x17c0c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2ea4>
   17bf0: f0ffff82     	adrp	x2, 0xa000
   17bf4: f0ffff83     	adrp	x3, 0xa000
   17bf8: 91135442     	add	x2, x2, #0x4d5
   17bfc: 91000c63     	add	x3, x3, #0x3
   17c00: 52800060     	mov	w0, #0x3                // =3
   17c04: aa1f03e1     	mov	x1, xzr
   17c08: 94003a6a     	bl	0x265b0 <__android_log_print@plt>
   17c0c: f9403a80     	ldr	x0, [x20, #0x70]
   17c10: 94002964     	bl	0x221a0 ; fpc_tee_sensor_init <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd438>
   17c14: f9003e80     	str	x0, [x20, #0x78]
   17c18: b4000600     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17c1c: f9403a80     	ldr	x0, [x20, #0x70]
   17c20: 94002b6c     	bl	0x229d0 ; fpc_tee_bio_init <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdc68>
   17c24: f9004280     	str	x0, [x20, #0x80]
   17c28: b4000580     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17c2c: 90ffffa0     	adrp	x0, 0xb000
   17c30: 91374400     	add	x0, x0, #0xdd1
   17c34: 910003e1     	mov	x1, sp
   17c38: aa1f03e2     	mov	x2, xzr
   17c3c: 94003b79     	bl	0x26a20 <property_get@plt>
   17c40: 90ffffa2     	adrp	x2, 0xb000
   17c44: 913fc042     	add	x2, x2, #0xff0
   17c48: 910003e3     	mov	x3, sp
   17c4c: 52800060     	mov	w0, #0x3                // =3
   17c50: aa1f03e1     	mov	x1, xzr
   17c54: 94003a57     	bl	0x265b0 <__android_log_print@plt>
   17c58: f0ffff81     	adrp	x1, 0xa000
   17c5c: 91089021     	add	x1, x1, #0x224
   17c60: 910003e0     	mov	x0, sp
   17c64: 94003b8f     	bl	0x26aa0 <strstr@plt>
   17c68: b4000140     	cbz	x0, 0x17c90 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f28>
   17c6c: b0ffffa2     	adrp	x2, 0xc000
   17c70: 913f9042     	add	x2, x2, #0xfe4
   17c74: 52800080     	mov	w0, #0x4                // =4
   17c78: aa1f03e1     	mov	x1, xzr
   17c7c: 94003a4d     	bl	0x265b0 <__android_log_print@plt>
   17c80: f9403a88     	ldr	x8, [x20, #0x70]
   17c84: b9401109     	ldr	w9, [x8, #0x10]
   17c88: 121d7929     	and	w9, w9, #0xfffffffb
   17c8c: b9001109     	str	w9, [x8, #0x10]
   17c90: f9403a80     	ldr	x0, [x20, #0x70]
   17c94: 94001a39     	bl	0x1e578 ; fpc_tee_navigation_enabled <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9810>
   17c98: 360001a0     	tbz	w0, #0x0, 0x17ccc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f64>
   17c9c: 94001500     	bl	0x1d09c ; create_input_device <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8334>
   17ca0: 34000160     	cbz	w0, 0x17ccc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f64>
   17ca4: d0ffff82     	adrp	x2, 0x9000
   17ca8: f0ffff83     	adrp	x3, 0xa000
   17cac: 91374042     	add	x2, x2, #0xdd0
   17cb0: 91000c63     	add	x3, x3, #0x3
   17cb4: 528000c0     	mov	w0, #0x6                // =6
   17cb8: aa1f03e1     	mov	x1, xzr
   17cbc: 94003a3d     	bl	0x265b0 <__android_log_print@plt>
   17cc0: 14000006     	b	0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17cc4: 12800100     	mov	w0, #-0x9               // =-9
   17cc8: 1400000e     	b	0x17d00 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f98>
   17ccc: f9403a80     	ldr	x0, [x20, #0x70]
   17cd0: 94002c88     	bl	0x22ef0 ; fpc_tee_init_hw_auth <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe188>
   17cd4: 340002a0     	cbz	w0, 0x17d28 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2fc0>
   17cd8: f0ffff82     	adrp	x2, 0xa000
   17cdc: f0ffff83     	adrp	x3, 0xa000
   17ce0: 911c6c42     	add	x2, x2, #0x71b
   17ce4: 91000c63     	add	x3, x3, #0x3
   17ce8: 528000c0     	mov	w0, #0x6                // =6
   17cec: aa1f03e1     	mov	x1, xzr
   17cf0: 94003a30     	bl	0x265b0 <__android_log_print@plt>
   17cf4: aa1403e0     	mov	x0, x20
   17cf8: 97ffff3b     	bl	0x179e4 ; fpc_hal_close <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2c7c>
   17cfc: 12800000     	mov	w0, #-0x1               // =-1
   17d00: f94016e8     	ldr	x8, [x23, #0x28]
   17d04: f85f83a9     	ldur	x9, [x29, #-0x8]
   17d08: eb09011f     	cmp	x8, x9
   17d0c: 54000821     	b.ne	0x17e10 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x30a8>
   17d10: a94a4ff4     	ldp	x20, x19, [sp, #0xa0]
   17d14: a94957f6     	ldp	x22, x21, [sp, #0x90]
   17d18: f94043f7     	ldr	x23, [sp, #0x80]
   17d1c: a9477bfd     	ldp	x29, x30, [sp, #0x70]
   17d20: 9102c3ff     	add	sp, sp, #0xb0
   17d24: d65f03c0     	ret
   17d28: 940003ea     	bl	0x18cd0 ; fpc_worker_new <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x3f68>
   17d2c: f9000280     	str	x0, [x20]
   17d30: b4fffd40     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17d34: f9403a80     	ldr	x0, [x20, #0x70]
   17d38: 94001a0a     	bl	0x1e560 ; fpc_tee_engineering_enabled <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x97f8>
   17d3c: 360000c0     	tbz	w0, #0x0, 0x17d54 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2fec>
   17d40: aa1403e0     	mov	x0, x20
   17d44: 940004fa     	bl	0x1912c ; fpc_engineering_new <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x43c4>
   17d48: f9002a80     	str	x0, [x20, #0x50]
   17d4c: b4fffc60     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17d50: 94002ce7     	bl	0x230ec ; add_engineering_service <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe384>
   17d54: f9403a80     	ldr	x0, [x20, #0x70]
   17d58: 94001a05     	bl	0x1e56c ; fpc_tee_sensortest_enabled <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9804>
   17d5c: 360000c0     	tbz	w0, #0x0, 0x17d74 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x300c>
   17d60: aa1403e0     	mov	x0, x20
   17d64: 94000c83     	bl	0x1af70 ; fpc_sensortest_new <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x6208>
   17d68: f9002680     	str	x0, [x20, #0x48]
   17d6c: b4fffb60     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17d70: 94003421     	bl	0x24df4 ; add_sensortest_service <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x1008c>
   17d74: f9403a80     	ldr	x0, [x20, #0x70]
   17d78: 94001a0e     	bl	0x1e5b0 ; fpc_tee_sensetouch_enabled <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9848>
   17d7c: 36000100     	tbz	w0, #0x0, 0x17d9c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x3034>
   17d80: aa1403e0     	mov	x0, x20
   17d84: 940012c0     	bl	0x1c884 ; fpc_sense_touch_new <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x7b1c>
   17d88: f9003680     	str	x0, [x20, #0x68]
   17d8c: 940013d5     	bl	0x1cce0 ; fpc_sense_touch_load_config <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x7f78>
   17d90: f9403680     	ldr	x0, [x20, #0x68]
   17d94: b4fffa20     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17d98: 94003302     	bl	0x249a0 ; add_sense_touch_service <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xfc38>
   17d9c: f9403a80     	ldr	x0, [x20, #0x70]
   17da0: 940019f6     	bl	0x1e578 ; fpc_tee_navigation_enabled <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x9810>
   17da4: 360000c0     	tbz	w0, #0x0, 0x17dbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x3054>
   17da8: aa1403e0     	mov	x0, x20
   17dac: 940011b7     	bl	0x1c488 ; fpc_navigation_new <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x7720>
   17db0: f9003280     	str	x0, [x20, #0x60]
   17db4: b4fff920     	cbz	x0, 0x17cd8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f70>
   17db8: 94003258     	bl	0x24718 ; add_navigation_service <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xf9b0>
   17dbc: f0ffff82     	adrp	x2, 0xa000
   17dc0: f0ffff83     	adrp	x3, 0xa000
   17dc4: 9103e042     	add	x2, x2, #0xf8
   17dc8: 91000c63     	add	x3, x3, #0x3
   17dcc: 52800060     	mov	w0, #0x3                // =3
   17dd0: aa1f03e1     	mov	x1, xzr
   17dd4: 940039f7     	bl	0x265b0 <__android_log_print@plt>
   17dd8: 94000368     	bl	0x18b78 ; checkin_lib_version <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x3e10>
   17ddc: d0000088     	adrp	x8, 0x29000
   17de0: d0000089     	adrp	x9, 0x29000
   17de4: 912a8108     	add	x8, x8, #0xaa0
   17de8: 912ae129     	add	x9, x9, #0xab8
   17dec: aa1403e0     	mov	x0, x20
   17df0: a9007d1f     	stp	xzr, xzr, [x8]
   17df4: f900091f     	str	xzr, [x8, #0x10]
   17df8: a900fd3f     	stp	xzr, xzr, [x9, #0x8]
   17dfc: f900013f     	str	xzr, [x9]
   17e00: f9000274     	str	x20, [x19]
   17e04: 97fff952     	bl	0x1634c ; fingerprint_hal_resume <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x15e4>
   17e08: 2a1f03e0     	mov	w0, wzr
   17e0c: 17ffffbd     	b	0x17d00 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x2f98>
   17e10: 94003a18     	bl	0x26670 <__stack_chk_fail@plt>
