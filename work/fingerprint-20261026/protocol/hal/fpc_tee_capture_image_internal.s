
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   216c0: d10243ff     	sub	sp, sp, #0x90
   216c4: a9037bfd     	stp	x29, x30, [sp, #0x30]
   216c8: a9046ffc     	stp	x28, x27, [sp, #0x40]
   216cc: a90567fa     	stp	x26, x25, [sp, #0x50]
   216d0: a9065ff8     	stp	x24, x23, [sp, #0x60]
   216d4: a90757f6     	stp	x22, x21, [sp, #0x70]
   216d8: a9084ff4     	stp	x20, x19, [sp, #0x80]
   216dc: 9100c3fd     	add	x29, sp, #0x30
   216e0: d53bd048     	mrs	x8, TPIDR_EL0
   216e4: f90003e8     	str	x8, [sp]
   216e8: f9401508     	ldr	x8, [x8, #0x28]
   216ec: aa0303f5     	mov	x21, x3
   216f0: 2a0103f4     	mov	w20, w1
   216f4: 12001c36     	and	w22, w1, #0xff
   216f8: f0ffff41     	adrp	x1, 0xc000
   216fc: b0ffff42     	adrp	x2, 0xa000
   21700: b0ffff43     	adrp	x3, 0xa000
   21704: aa0003f3     	mov	x19, x0
   21708: 91301421     	add	x1, x1, #0xc05
   2170c: 9103e042     	add	x2, x2, #0xf8
   21710: 913a4863     	add	x3, x3, #0xe92
   21714: 52800060     	mov	w0, #0x3                // =3
   21718: f81f83a8     	stur	x8, [x29, #-0x8]
   2171c: 940013a5     	bl	0x265b0 <__android_log_print@plt>
   21720: f9400268     	ldr	x8, [x19]
   21724: b9004a7f     	str	wzr, [x19, #0x48]
   21728: 72001e9f     	tst	w20, #0xff
   2172c: 52800089     	mov	w9, #0x4                // =4
   21730: f9400508     	ldr	x8, [x8, #0x8]
   21734: 1a9f153c     	csinc	w28, w9, wzr, ne
   21738: f9400117     	ldr	x23, [x8]
   2173c: 390022f4     	strb	w20, [x23, #0x8]
   21740: b9000eff     	str	wzr, [x23, #0xc]
   21744: b9404e68     	ldr	w8, [x19, #0x4c]
   21748: b90016e8     	str	w8, [x23, #0x14]
   2174c: 340003f6     	cbz	w22, 0x217c8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xca60>
   21750: f9401e60     	ldr	x0, [x19, #0x38]
   21754: 97ffc62c     	bl	0x13004 <.text+0x1004>
   21758: 2a0003fb     	mov	w27, w0
   2175c: 35001120     	cbnz	w0, 0x21980 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc18>
   21760: 14000009     	b	0x21784 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xca1c>
   21764: f9401e60     	ldr	x0, [x19, #0x38]
   21768: 52800021     	mov	w1, #0x1                // =1
   2176c: 97fff028     	bl	0x1d80c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8aa4>
   21770: 35000120     	cbnz	w0, 0x21794 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xca2c>
   21774: 52800021     	mov	w1, #0x1                // =1
   21778: aa1303e0     	mov	x0, x19
   2177c: 97ffff3f     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   21780: 350000e0     	cbnz	w0, 0x2179c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xca34>
   21784: 52800041     	mov	w1, #0x2                // =2
   21788: aa1303e0     	mov	x0, x19
   2178c: 97ffff3b     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   21790: 34fffea0     	cbz	w0, 0x21764 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc9fc>
   21794: 2a0003fb     	mov	w27, w0
   21798: 14000078     	b	0x21978 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc10>
   2179c: 2a0003fb     	mov	w27, w0
   217a0: 7100041f     	cmp	w0, #0x1
   217a4: 54000ea1     	b.ne	0x21978 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc10>
   217a8: f0ffff41     	adrp	x1, 0xc000
   217ac: d0ffff42     	adrp	x2, 0xb000
   217b0: b0ffff43     	adrp	x3, 0xa000
   217b4: 91301421     	add	x1, x1, #0xc05
   217b8: 913d7442     	add	x2, x2, #0xf5d
   217bc: 913a4863     	add	x3, x3, #0xe92
   217c0: 52800060     	mov	w0, #0x3                // =3
   217c4: 9400137b     	bl	0x265b0 <__android_log_print@plt>
   217c8: f0ffff56     	adrp	x22, 0xc000
   217cc: b0ffff59     	adrp	x25, 0xa000
   217d0: 2a1f03fa     	mov	w26, wzr
   217d4: 52807d18     	mov	w24, #0x3e8             // =1000
   217d8: 913016d6     	add	x22, x22, #0xc05
   217dc: 913a4b39     	add	x25, x25, #0xe92
   217e0: 72001e9f     	tst	w20, #0xff
   217e4: 540005a0     	b.eq	0x21898 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcb30>
   217e8: 910063e1     	add	x1, sp, #0x18
   217ec: 52800080     	mov	w0, #0x4                // =4
   217f0: a901ffff     	stp	xzr, xzr, [sp, #0x18]
   217f4: a900ffff     	stp	xzr, xzr, [sp, #0x8]
   217f8: 94001492     	bl	0x26a40 <clock_gettime@plt>
   217fc: 52800061     	mov	w1, #0x3                // =3
   21800: aa1303e0     	mov	x0, x19
   21804: 97ffff1d     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   21808: 2a0003fb     	mov	w27, w0
   2180c: 350000a0     	cbnz	w0, 0x21820 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcab8>
   21810: f9401e60     	ldr	x0, [x19, #0x38]
   21814: 52800021     	mov	w1, #0x1                // =1
   21818: 97ffeffd     	bl	0x1d80c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x8aa4>
   2181c: 2a0003fb     	mov	w27, w0
   21820: 910023e1     	add	x1, sp, #0x8
   21824: 52800080     	mov	w0, #0x4                // =4
   21828: 94001486     	bl	0x26a40 <clock_gettime@plt>
   2182c: a940a7e8     	ldp	x8, x9, [sp, #0x8]
   21830: a941afea     	ldp	x10, x11, [sp, #0x18]
   21834: cb0a0108     	sub	x8, x8, x10
   21838: 5288480a     	mov	w10, #0x4240            // =16960
   2183c: cb0b0129     	sub	x9, x9, x11
   21840: 72a001ea     	movk	w10, #0xf, lsl #16
   21844: 9aca0d29     	sdiv	x9, x9, x10
   21848: 9b187d0a     	mul	x10, x8, x24
   2184c: f100011f     	cmp	x8, #0x0
   21850: 9a9fc148     	csel	x8, x10, xzr, gt
   21854: 8b080128     	add	x8, x9, x8
   21858: f107d51f     	cmp	x8, #0x1f5
   2185c: 5400010b     	b.lt	0x2187c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcb14>
   21860: b0ffff42     	adrp	x2, 0xa000
   21864: 52800060     	mov	w0, #0x3                // =3
   21868: 52803e83     	mov	w3, #0x1f4              // =500
   2186c: aa1603e1     	mov	x1, x22
   21870: 912e4042     	add	x2, x2, #0xb90
   21874: 9400134f     	bl	0x265b0 <__android_log_print@plt>
   21878: 2a1f03fa     	mov	w26, wzr
   2187c: d0ffff42     	adrp	x2, 0xb000
   21880: 52800060     	mov	w0, #0x3                // =3
   21884: aa1603e1     	mov	x1, x22
   21888: 910f4842     	add	x2, x2, #0x3d2
   2188c: aa1903e3     	mov	x3, x25
   21890: 94001348     	bl	0x265b0 <__android_log_print@plt>
   21894: 3500077b     	cbnz	w27, 0x21980 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc18>
   21898: d0ffff42     	adrp	x2, 0xb000
   2189c: 52800060     	mov	w0, #0x3                // =3
   218a0: aa1603e1     	mov	x1, x22
   218a4: 913dac42     	add	x2, x2, #0xf6b
   218a8: aa1903e3     	mov	x3, x25
   218ac: 94001341     	bl	0x265b0 <__android_log_print@plt>
   218b0: b40003d5     	cbz	x21, 0x21928 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcbc0>
   218b4: 910063e1     	add	x1, sp, #0x18
   218b8: 52800080     	mov	w0, #0x4                // =4
   218bc: a901ffff     	stp	xzr, xzr, [sp, #0x18]
   218c0: a900ffff     	stp	xzr, xzr, [sp, #0x8]
   218c4: 9400145f     	bl	0x26a40 <clock_gettime@plt>
   218c8: 52800081     	mov	w1, #0x4                // =4
   218cc: aa1303e0     	mov	x0, x19
   218d0: 97fffeea     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   218d4: b94012e8     	ldr	w8, [x23, #0x10]
   218d8: 2a0003fb     	mov	w27, w0
   218dc: 910023e1     	add	x1, sp, #0x8
   218e0: 52800080     	mov	w0, #0x4                // =4
   218e4: b9004a68     	str	w8, [x19, #0x48]
   218e8: 94001456     	bl	0x26a40 <clock_gettime@plt>
   218ec: a940a7e8     	ldp	x8, x9, [sp, #0x8]
   218f0: a941afea     	ldp	x10, x11, [sp, #0x18]
   218f4: cb0a0108     	sub	x8, x8, x10
   218f8: 5288480a     	mov	w10, #0x4240            // =16960
   218fc: cb0b0129     	sub	x9, x9, x11
   21900: 72a001ea     	movk	w10, #0xf, lsl #16
   21904: 9aca0d29     	sdiv	x9, x9, x10
   21908: 1b187d0a     	mul	w10, w8, w24
   2190c: f100011f     	cmp	x8, #0x0
   21910: 1a9fc148     	csel	w8, w10, wzr, gt
   21914: 0b080128     	add	w8, w9, w8
   21918: b90002a8     	str	w8, [x21]
   2191c: 7100077f     	cmp	w27, #0x1
   21920: 54000140     	b.eq	0x21948 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcbe0>
   21924: 14000015     	b	0x21978 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc10>
   21928: 52800081     	mov	w1, #0x4                // =4
   2192c: aa1303e0     	mov	x0, x19
   21930: 97fffed2     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   21934: b94012e8     	ldr	w8, [x23, #0x10]
   21938: 2a0003fb     	mov	w27, w0
   2193c: b9004a68     	str	w8, [x19, #0x48]
   21940: 7100077f     	cmp	w27, #0x1
   21944: 540001a1     	b.ne	0x21978 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc10>
   21948: 1100075a     	add	w26, w26, #0x1
   2194c: 6b1c035f     	cmp	w26, w28
   21950: 54fff48b     	b.lt	0x217e0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xca78>
   21954: f0ffff41     	adrp	x1, 0xc000
   21958: d0ffff42     	adrp	x2, 0xb000
   2195c: b0ffff43     	adrp	x3, 0xa000
   21960: 91301421     	add	x1, x1, #0xc05
   21964: 911a5c42     	add	x2, x2, #0x697
   21968: 913a4863     	add	x3, x3, #0xe92
   2196c: 52800060     	mov	w0, #0x3                // =3
   21970: 94001310     	bl	0x265b0 <__android_log_print@plt>
   21974: 5280003b     	mov	w27, #0x1               // =1
   21978: 72001e9f     	tst	w20, #0xff
   2197c: 54000060     	b.eq	0x21988 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc20>
   21980: f9401e60     	ldr	x0, [x19, #0x38]
   21984: 97ffc5a0     	bl	0x13004 <.text+0x1004>
   21988: 528000a1     	mov	w1, #0x5                // =5
   2198c: aa1303e0     	mov	x0, x19
   21990: 97fffeba     	bl	0x21478 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc710>
   21994: f94003e8     	ldr	x8, [sp]
   21998: f9401508     	ldr	x8, [x8, #0x28]
   2199c: f85f83a9     	ldur	x9, [x29, #-0x8]
   219a0: eb09011f     	cmp	x8, x9
   219a4: 54000141     	b.ne	0x219cc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xcc64>
   219a8: 2a1b03e0     	mov	w0, w27
   219ac: a9484ff4     	ldp	x20, x19, [sp, #0x80]
   219b0: a94757f6     	ldp	x22, x21, [sp, #0x70]
   219b4: a9465ff8     	ldp	x24, x23, [sp, #0x60]
   219b8: a94567fa     	ldp	x26, x25, [sp, #0x50]
   219bc: a9446ffc     	ldp	x28, x27, [sp, #0x40]
   219c0: a9437bfd     	ldp	x29, x30, [sp, #0x30]
   219c4: 910243ff     	add	sp, sp, #0x90
   219c8: d65f03c0     	ret
   219cc: 94001329     	bl	0x26670 <__stack_chk_fail@plt>
