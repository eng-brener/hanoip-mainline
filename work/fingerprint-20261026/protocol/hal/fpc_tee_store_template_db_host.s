
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   20ae0: a9ba7bfd     	stp	x29, x30, [sp, #-0x60]!
   20ae4: a9016ffc     	stp	x28, x27, [sp, #0x10]
   20ae8: a90267fa     	stp	x26, x25, [sp, #0x20]
   20aec: a9035ff8     	stp	x24, x23, [sp, #0x30]
   20af0: a90457f6     	stp	x22, x21, [sp, #0x40]
   20af4: a9054ff4     	stp	x20, x19, [sp, #0x50]
   20af8: 910003fd     	mov	x29, sp
   20afc: d14007ff     	sub	sp, sp, #0x1, lsl #12   // =0x1000
   20b00: d10083ff     	sub	sp, sp, #0x20
   20b04: d53bd05a     	mrs	x26, TPIDR_EL0
   20b08: f9401748     	ldr	x8, [x26, #0x28]
   20b0c: aa0103f4     	mov	x20, x1
   20b10: aa0003f3     	mov	x19, x0
   20b14: 910043e0     	add	x0, sp, #0x10
   20b18: 52820002     	mov	w2, #0x1000             // =4096
   20b1c: 2a1f03e1     	mov	w1, wzr
   20b20: f81f03a8     	stur	x8, [x29, #-0x10]
   20b24: 9400170b     	bl	0x26750 <memset@plt>
   20b28: aa1403e0     	mov	x0, x20
   20b2c: 940017e5     	bl	0x26ac0 <strlen@plt>
   20b30: f140041f     	cmp	x0, #0x1, lsl #12       // =0x1000
   20b34: 540000c3     	b.lo	0x20b4c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbde4>
   20b38: 90ffff61     	adrp	x1, 0xc000
   20b3c: f0ffff42     	adrp	x2, 0xb000
   20b40: 91301421     	add	x1, x1, #0xc05
   20b44: 910e2442     	add	x2, x2, #0x389
   20b48: 14000018     	b	0x20ba8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe40>
   20b4c: 910043e0     	add	x0, sp, #0x10
   20b50: 52820002     	mov	w2, #0x1000             // =4096
   20b54: aa1403e1     	mov	x1, x20
   20b58: 940018a2     	bl	0x26de0 <__strcpy_chk@plt>
   20b5c: 910043e0     	add	x0, sp, #0x10
   20b60: 940018a4     	bl	0x26df0 <dirname@plt>
   20b64: 52803801     	mov	w1, #0x1c0              // =448
   20b68: aa0003f5     	mov	x21, x0
   20b6c: 940017e1     	bl	0x26af0 <mkdir@plt>
   20b70: 340000a0     	cbz	w0, 0x20b84 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe1c>
   20b74: 94001733     	bl	0x26840 <__errno@plt>
   20b78: b9400000     	ldr	w0, [x0]
   20b7c: 7100441f     	cmp	w0, #0x11
   20b80: 54000ec1     	b.ne	0x20d58 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbff0>
   20b84: 910043e0     	add	x0, sp, #0x10
   20b88: aa1403e4     	mov	x4, x20
   20b8c: 940000c5     	bl	0x20ea0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc138>
   20b90: 7140041f     	cmp	w0, #0x1, lsl #12       // =0x1000
   20b94: 5400030b     	b.lt	0x20bf4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe8c>
   20b98: 90ffff61     	adrp	x1, 0xc000
   20b9c: b0ffff62     	adrp	x2, 0xd000
   20ba0: 91301421     	add	x1, x1, #0xc05
   20ba4: 91312442     	add	x2, x2, #0xc49
   20ba8: b0ffff43     	adrp	x3, 0x9000
   20bac: 91356063     	add	x3, x3, #0xd58
   20bb0: 528000c0     	mov	w0, #0x6                // =6
   20bb4: 9400167f     	bl	0x265b0 <__android_log_print@plt>
   20bb8: 1280013b     	mov	w27, #-0xa              // =-10
   20bbc: f9401748     	ldr	x8, [x26, #0x28]
   20bc0: f85f03a9     	ldur	x9, [x29, #-0x10]
   20bc4: eb09011f     	cmp	x8, x9
   20bc8: 540016a1     	b.ne	0x20e9c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc134>
   20bcc: 2a1b03e0     	mov	w0, w27
   20bd0: 914007ff     	add	sp, sp, #0x1, lsl #12   // =0x1000
   20bd4: 910083ff     	add	sp, sp, #0x20
   20bd8: a9454ff4     	ldp	x20, x19, [sp, #0x50]
   20bdc: a94457f6     	ldp	x22, x21, [sp, #0x40]
   20be0: a9435ff8     	ldp	x24, x23, [sp, #0x30]
   20be4: a94267fa     	ldp	x26, x25, [sp, #0x20]
   20be8: a9416ffc     	ldp	x28, x27, [sp, #0x10]
   20bec: a8c67bfd     	ldp	x29, x30, [sp], #0x60
   20bf0: d65f03c0     	ret
   20bf4: f9400668     	ldr	x8, [x19, #0x8]
   20bf8: d0ffff69     	adrp	x9, 0xe000
   20bfc: fd409d20     	ldr	d0, [x9, #0x138]
   20c00: f9400115     	ldr	x21, [x8]
   20c04: fd0002a0     	str	d0, [x21]
   20c08: b9000abf     	str	wzr, [x21, #0x8]
   20c0c: a9400660     	ldp	x0, x1, [x19]
   20c10: 94000878     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   20c14: 37f80bc0     	tbnz	w0, #0x1f, 0x20d8c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc024>
   20c18: b9400ab7     	ldr	w23, [x21, #0x8]
   20c1c: 34000bd7     	cbz	w23, 0x20d94 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc02c>
   20c20: f9400668     	ldr	x8, [x19, #0x8]
   20c24: d0ffff69     	adrp	x9, 0xe000
   20c28: fd407520     	ldr	d0, [x9, #0xe8]
   20c2c: f9400108     	ldr	x8, [x8]
   20c30: fd000100     	str	d0, [x8]
   20c34: 2901dd1f     	stp	wzr, w23, [x8, #0xc]
   20c38: a9400660     	ldp	x0, x1, [x19]
   20c3c: 9400086d     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   20c40: 37f80ae0     	tbnz	w0, #0x1f, 0x20d9c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc034>
   20c44: aa1703e0     	mov	x0, x23
   20c48: 9400178e     	bl	0x26a80 <malloc@plt>
   20c4c: f90007e0     	str	x0, [sp, #0x8]
   20c50: b4000cc0     	cbz	x0, 0x20de8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc080>
   20c54: 529ff208     	mov	w8, #0xff90             // =65424
   20c58: 72a001e8     	movk	w8, #0xf, lsl #16
   20c5c: f9400260     	ldr	x0, [x19]
   20c60: 6b0802ff     	cmp	w23, w8
   20c64: 1a8832f5     	csel	w21, w23, w8, lo
   20c68: 1101c2a1     	add	w1, w21, #0x70
   20c6c: 940007f0     	bl	0x22c2c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdec4>
   20c70: b4000c00     	cbz	x0, 0x20df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc088>
   20c74: f9400008     	ldr	x8, [x0]
   20c78: d0ffff69     	adrp	x9, 0xe000
   20c7c: fd40f920     	ldr	d0, [x9, #0x1f0]
   20c80: aa0003f8     	mov	x24, x0
   20c84: 2a1f03fc     	mov	w28, wzr
   20c88: b9000915     	str	w21, [x8, #0x8]
   20c8c: 91003119     	add	x25, x8, #0xc
   20c90: 2a1703f5     	mov	w21, w23
   20c94: fd000100     	str	d0, [x8]
   20c98: f9400260     	ldr	x0, [x19]
   20c9c: 529ff208     	mov	w8, #0xff90             // =65424
   20ca0: 72a001e8     	movk	w8, #0xf, lsl #16
   20ca4: 6b0802bf     	cmp	w21, w8
   20ca8: aa1803e1     	mov	x1, x24
   20cac: 1a8832b6     	csel	w22, w21, w8, lo
   20cb0: 94000850     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   20cb4: 2a0003fb     	mov	w27, w0
   20cb8: 37f80b40     	tbnz	w0, #0x1f, 0x20e20 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0b8>
   20cbc: 4b1602a4     	sub	w4, w21, w22
   20cc0: 6b1b009f     	cmp	w4, w27
   20cc4: 540009a1     	b.ne	0x20df8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc090>
   20cc8: f94007e8     	ldr	x8, [sp, #0x8]
   20ccc: 2a1603e2     	mov	w2, w22
   20cd0: aa1903e1     	mov	x1, x25
   20cd4: 8b3c4100     	add	x0, x8, w28, uxtw
   20cd8: 94001676     	bl	0x266b0 <memcpy@plt>
   20cdc: 0b1c02dc     	add	w28, w22, w28
   20ce0: 2a1b03f5     	mov	w21, w27
   20ce4: 35fffdbb     	cbnz	w27, 0x20c98 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbf30>
   20ce8: aa1803e0     	mov	x0, x24
   20cec: 9400081e     	bl	0x22d64 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdffc>
   20cf0: f94007e0     	ldr	x0, [sp, #0x8]
   20cf4: 910043e2     	add	x2, sp, #0x10
   20cf8: 2a1703e1     	mov	w1, w23
   20cfc: 94000091     	bl	0x20f40 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc1d8>
   20d00: 2a0003fb     	mov	w27, w0
   20d04: 37f80b80     	tbnz	w0, #0x1f, 0x20e74 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc10c>
   20d08: 910043e0     	add	x0, sp, #0x10
   20d0c: aa1403e1     	mov	x1, x20
   20d10: 940016c8     	bl	0x26830 <rename@plt>
   20d14: 36f808a0     	tbz	w0, #0x1f, 0x20e28 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0c0>
   20d18: 940016ca     	bl	0x26840 <__errno@plt>
   20d1c: b9400000     	ldr	w0, [x0]
   20d20: 940017e8     	bl	0x26cc0 <strerror@plt>
   20d24: 90ffff61     	adrp	x1, 0xc000
   20d28: 90ffff62     	adrp	x2, 0xc000
   20d2c: b0ffff43     	adrp	x3, 0x9000
   20d30: aa0003e4     	mov	x4, x0
   20d34: 91301421     	add	x1, x1, #0xc05
   20d38: 913c7842     	add	x2, x2, #0xf1e
   20d3c: 91356063     	add	x3, x3, #0xd58
   20d40: 528000c0     	mov	w0, #0x6                // =6
   20d44: 9400161b     	bl	0x265b0 <__android_log_print@plt>
   20d48: 910043e0     	add	x0, sp, #0x10
   20d4c: 9400178d     	bl	0x26b80 <unlink@plt>
   20d50: 128000bb     	mov	w27, #-0x6              // =-6
   20d54: 14000035     	b	0x20e28 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0c0>
   20d58: 940017da     	bl	0x26cc0 <strerror@plt>
   20d5c: 90ffff61     	adrp	x1, 0xc000
   20d60: 90ffff62     	adrp	x2, 0xc000
   20d64: b0ffff43     	adrp	x3, 0x9000
   20d68: aa0003e5     	mov	x5, x0
   20d6c: 91301421     	add	x1, x1, #0xc05
   20d70: 913be842     	add	x2, x2, #0xefa
   20d74: 91356063     	add	x3, x3, #0xd58
   20d78: 528000c0     	mov	w0, #0x6                // =6
   20d7c: aa1503e4     	mov	x4, x21
   20d80: 9400160c     	bl	0x265b0 <__android_log_print@plt>
   20d84: 128000bb     	mov	w27, #-0x6              // =-6
   20d88: 17ffff8d     	b	0x20bbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe54>
   20d8c: 2a0003fb     	mov	w27, w0
   20d90: 17ffff8b     	b	0x20bbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe54>
   20d94: 128000bb     	mov	w27, #-0x6              // =-6
   20d98: 17ffff89     	b	0x20bbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe54>
   20d9c: 90ffff74     	adrp	x20, 0xc000
   20da0: 91301694     	add	x20, x20, #0xc05
   20da4: b0ffff62     	adrp	x2, 0xd000
   20da8: f0ffff43     	adrp	x3, 0xb000
   20dac: 2a0003fb     	mov	w27, w0
   20db0: 91318042     	add	x2, x2, #0xc60
   20db4: 91052063     	add	x3, x3, #0x148
   20db8: 528000c0     	mov	w0, #0x6                // =6
   20dbc: aa1403e1     	mov	x1, x20
   20dc0: 940015fc     	bl	0x265b0 <__android_log_print@plt>
   20dc4: 90ffff62     	adrp	x2, 0xc000
   20dc8: b0ffff43     	adrp	x3, 0x9000
   20dcc: 9106c442     	add	x2, x2, #0x1b1
   20dd0: 91356063     	add	x3, x3, #0xd58
   20dd4: 528000c0     	mov	w0, #0x6                // =6
   20dd8: aa1403e1     	mov	x1, x20
   20ddc: 2a1b03e4     	mov	w4, w27
   20de0: 940015f4     	bl	0x265b0 <__android_log_print@plt>
   20de4: 14000013     	b	0x20e30 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0c8>
   20de8: 1280011b     	mov	w27, #-0x9              // =-9
   20dec: 14000011     	b	0x20e30 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0c8>
   20df0: 1280011b     	mov	w27, #-0x9              // =-9
   20df4: 1400000d     	b	0x20e28 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0c0>
   20df8: 90ffff61     	adrp	x1, 0xc000
   20dfc: b0ffff62     	adrp	x2, 0xd000
   20e00: d0ffff43     	adrp	x3, 0xa000
   20e04: 91301421     	add	x1, x1, #0xc05
   20e08: 913ea842     	add	x2, x2, #0xfaa
   20e0c: 9139f063     	add	x3, x3, #0xe7c
   20e10: 528000c0     	mov	w0, #0x6                // =6
   20e14: 2a1b03e5     	mov	w5, w27
   20e18: 940015e6     	bl	0x265b0 <__android_log_print@plt>
   20e1c: 1280021b     	mov	w27, #-0x11             // =-17
   20e20: aa1803e0     	mov	x0, x24
   20e24: 940007d0     	bl	0x22d64 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdffc>
   20e28: f94007e0     	ldr	x0, [sp, #0x8]
   20e2c: 94001711     	bl	0x26a70 <free@plt>
   20e30: f9400668     	ldr	x8, [x19, #0x8]
   20e34: d0ffff69     	adrp	x9, 0xe000
   20e38: fd40fd20     	ldr	d0, [x9, #0x1f8]
   20e3c: f9400108     	ldr	x8, [x8]
   20e40: fd000100     	str	d0, [x8]
   20e44: a9400660     	ldp	x0, x1, [x19]
   20e48: 940007ea     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   20e4c: 36ffeb80     	tbz	w0, #0x1f, 0x20bbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe54>
   20e50: 90ffff61     	adrp	x1, 0xc000
   20e54: b0ffff62     	adrp	x2, 0xd000
   20e58: b0ffff63     	adrp	x3, 0xd000
   20e5c: 91301421     	add	x1, x1, #0xc05
   20e60: 91318042     	add	x2, x2, #0xc60
   20e64: 9114e063     	add	x3, x3, #0x538
   20e68: 528000c0     	mov	w0, #0x6                // =6
   20e6c: 940015d1     	bl	0x265b0 <__android_log_print@plt>
   20e70: 17ffff53     	b	0x20bbc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xbe54>
   20e74: 90ffff61     	adrp	x1, 0xc000
   20e78: b0ffff62     	adrp	x2, 0xd000
   20e7c: b0ffff43     	adrp	x3, 0x9000
   20e80: 91301421     	add	x1, x1, #0xc05
   20e84: 911cf042     	add	x2, x2, #0x73c
   20e88: 91356063     	add	x3, x3, #0xd58
   20e8c: 528000c0     	mov	w0, #0x6                // =6
   20e90: 2a1b03e4     	mov	w4, w27
   20e94: 940015c7     	bl	0x265b0 <__android_log_print@plt>
   20e98: 17ffffe4     	b	0x20e28 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc0c0>
   20e9c: 940015f5     	bl	0x26670 <__stack_chk_fail@plt>
