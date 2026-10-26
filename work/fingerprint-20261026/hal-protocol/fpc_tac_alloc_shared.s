
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   22c2c: a9bd7bfd     	stp	x29, x30, [sp, #-0x30]!
   22c30: f9000bf5     	str	x21, [sp, #0x10]
   22c34: a9024ff4     	stp	x20, x19, [sp, #0x20]
   22c38: 910003fd     	mov	x29, sp
   22c3c: 52800300     	mov	w0, #0x18               // =24
   22c40: 2a0103f5     	mov	w21, w1
   22c44: 94000f8f     	bl	0x26a80 <malloc@plt>
   22c48: aa0003f3     	mov	x19, x0
   22c4c: b4000820     	cbz	x0, 0x22d50 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdfe8>
   22c50: 113ffeaa     	add	w10, w21, #0xfff
   22c54: 12800008     	mov	w8, #-0x1               // =-1
   22c58: aa1303f4     	mov	x20, x19
   22c5c: 92800009     	mov	x9, #-0x1               // =-1
   22c60: 12144d55     	and	w21, w10, #0xfffff000
   22c64: b8010e88     	str	w8, [x20, #0x10]!
   22c68: f9000269     	str	x9, [x19]
   22c6c: b9000a75     	str	w21, [x19, #0x8]
   22c70: 94001078     	bl	0x26e50 <ion_open@plt>
   22c74: 3100041f     	cmn	w0, #0x1
   22c78: b9000e60     	str	w0, [x19, #0xc]
   22c7c: 540002a0     	b.eq	0x22cd0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdf68>
   22c80: 2a1503e1     	mov	w1, w21
   22c84: 52820002     	mov	w2, #0x1000             // =4096
   22c88: 52a10003     	mov	w3, #0x8000000          // =134217728
   22c8c: 2a1f03e4     	mov	w4, wzr
   22c90: aa1403e5     	mov	x5, x20
   22c94: 94001073     	bl	0x26e60 <ion_alloc_fd@plt>
   22c98: 340002c0     	cbz	w0, 0x22cf0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdf88>
   22c9c: 94000ee9     	bl	0x26840 <__errno@plt>
   22ca0: b9400008     	ldr	w8, [x0]
   22ca4: b9400a65     	ldr	w5, [x19, #0x8]
   22ca8: d0ffff41     	adrp	x1, 0xc000
   22cac: f0ffff22     	adrp	x2, 0x9000
   22cb0: 90ffff43     	adrp	x3, 0xa000
   22cb4: 4b0803e4     	neg	w4, w8
   22cb8: 91301421     	add	x1, x1, #0xc05
   22cbc: 91226042     	add	x2, x2, #0x898
   22cc0: 9119fc63     	add	x3, x3, #0x67f
   22cc4: 528000c0     	mov	w0, #0x6                // =6
   22cc8: 94000e3a     	bl	0x265b0 <__android_log_print@plt>
   22ccc: 1400001e     	b	0x22d44 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdfdc>
   22cd0: 94000edc     	bl	0x26840 <__errno@plt>
   22cd4: b9400008     	ldr	w8, [x0]
   22cd8: d0ffff41     	adrp	x1, 0xc000
   22cdc: d0ffff42     	adrp	x2, 0xc000
   22ce0: 91301421     	add	x1, x1, #0xc05
   22ce4: 4b0803e4     	neg	w4, w8
   22ce8: 91079c42     	add	x2, x2, #0x1e7
   22cec: 14000012     	b	0x22d34 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdfcc>
   22cf0: b9400a61     	ldr	w1, [x19, #0x8]
   22cf4: b9401264     	ldr	w4, [x19, #0x10]
   22cf8: 52800062     	mov	w2, #0x3                // =3
   22cfc: 52800023     	mov	w3, #0x1                // =1
   22d00: aa1f03e0     	mov	x0, xzr
   22d04: aa1f03e5     	mov	x5, xzr
   22d08: 9400105a     	bl	0x26e70 <mmap@plt>
   22d0c: b100041f     	cmn	x0, #0x1
   22d10: f9000260     	str	x0, [x19]
   22d14: 540001e1     	b.ne	0x22d50 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdfe8>
   22d18: 94000eca     	bl	0x26840 <__errno@plt>
   22d1c: b9400008     	ldr	w8, [x0]
   22d20: d0ffff41     	adrp	x1, 0xc000
   22d24: 90ffff42     	adrp	x2, 0xa000
   22d28: 91301421     	add	x1, x1, #0xc05
   22d2c: 4b0803e4     	neg	w4, w8
   22d30: 911a5042     	add	x2, x2, #0x694
   22d34: 90ffff43     	adrp	x3, 0xa000
   22d38: 9119fc63     	add	x3, x3, #0x67f
   22d3c: 528000c0     	mov	w0, #0x6                // =6
   22d40: 94000e1c     	bl	0x265b0 <__android_log_print@plt>
   22d44: aa1303e0     	mov	x0, x19
   22d48: 94000007     	bl	0x22d64 ; fpc_tac_free_shared <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdffc>
   22d4c: aa1f03f3     	mov	x19, xzr
   22d50: aa1303e0     	mov	x0, x19
   22d54: a9424ff4     	ldp	x20, x19, [sp, #0x20]
   22d58: f9400bf5     	ldr	x21, [sp, #0x10]
   22d5c: a8c37bfd     	ldp	x29, x30, [sp], #0x30
   22d60: d65f03c0     	ret
