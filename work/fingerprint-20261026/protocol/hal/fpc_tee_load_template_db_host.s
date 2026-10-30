
0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   21060: d10403ff     	sub	sp, sp, #0x100
   21064: a90a7bfd     	stp	x29, x30, [sp, #0xa0]
   21068: a90b6ffc     	stp	x28, x27, [sp, #0xb0]
   2106c: a90c67fa     	stp	x26, x25, [sp, #0xc0]
   21070: a90d5ff8     	stp	x24, x23, [sp, #0xd0]
   21074: a90e57f6     	stp	x22, x21, [sp, #0xe0]
   21078: a90f4ff4     	stp	x20, x19, [sp, #0xf0]
   2107c: 910283fd     	add	x29, sp, #0xa0
   21080: d53bd05b     	mrs	x27, TPIDR_EL0
   21084: f9401768     	ldr	x8, [x27, #0x28]
   21088: aa0103f5     	mov	x21, x1
   2108c: aa0003f3     	mov	x19, x0
   21090: 6f00e400     	movi	v0.2d, #0000000000000000
   21094: 910043e1     	add	x1, sp, #0x10
   21098: aa1503e0     	mov	x0, x21
   2109c: f81f83a8     	stur	x8, [x29, #-0x8]
   210a0: ad0383e0     	stp	q0, q0, [sp, #0x70]
   210a4: ad0283e0     	stp	q0, q0, [sp, #0x50]
   210a8: ad0183e0     	stp	q0, q0, [sp, #0x30]
   210ac: ad0083e0     	stp	q0, q0, [sp, #0x10]
   210b0: 9400168c     	bl	0x26ae0 <stat@plt>
   210b4: 34000220     	cbz	w0, 0x210f8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc390>
   210b8: 940015e2     	bl	0x26840 <__errno@plt>
   210bc: b9400000     	ldr	w0, [x0]
   210c0: 7100081f     	cmp	w0, #0x2
   210c4: 54000b20     	b.eq	0x21228 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc4c0>
   210c8: 940016fe     	bl	0x26cc0 <strerror@plt>
   210cc: f0ffff41     	adrp	x1, 0xc000
   210d0: f0ffff42     	adrp	x2, 0xc000
   210d4: b0ffff43     	adrp	x3, 0xa000
   210d8: aa0003e4     	mov	x4, x0
   210dc: 91301421     	add	x1, x1, #0xc05
   210e0: 911ebc42     	add	x2, x2, #0x7af
   210e4: 91196c63     	add	x3, x3, #0x65b
   210e8: 528000c0     	mov	w0, #0x6                // =6
   210ec: 94001531     	bl	0x265b0 <__android_log_print@plt>
   210f0: 128000b6     	mov	w22, #-0x6              // =-6
   210f4: 140000c3     	b	0x21400 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc698>
   210f8: f94023f7     	ldr	x23, [sp, #0x40]
   210fc: b4000977     	cbz	x23, 0x21228 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc4c0>
   21100: f9400668     	ldr	x8, [x19, #0x8]
   21104: b0ffff69     	adrp	x9, 0xe000
   21108: fd407520     	ldr	d0, [x9, #0xe8]
   2110c: 52800029     	mov	w9, #0x1                // =1
   21110: f9400108     	ldr	x8, [x8]
   21114: fd000100     	str	d0, [x8]
   21118: 2901dd09     	stp	w9, w23, [x8, #0xc]
   2111c: a9400660     	ldp	x0, x1, [x19]
   21120: 94000734     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   21124: 37f80900     	tbnz	w0, #0x1f, 0x21244 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc4dc>
   21128: aa1703e0     	mov	x0, x23
   2112c: 94001655     	bl	0x26a80 <malloc@plt>
   21130: b4000ac0     	cbz	x0, 0x21288 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc520>
   21134: aa0003f4     	mov	x20, x0
   21138: aa1503e0     	mov	x0, x21
   2113c: 2a1f03e1     	mov	w1, wzr
   21140: 940016e4     	bl	0x26cd0 <__open_2@plt>
   21144: 37f80a60     	tbnz	w0, #0x1f, 0x21290 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc528>
   21148: 93407ee2     	sxtw	x2, w23
   2114c: 92800003     	mov	x3, #-0x1               // =-1
   21150: aa1403e1     	mov	x1, x20
   21154: 2a0003f6     	mov	w22, w0
   21158: 9400172e     	bl	0x26e10 <__read_chk@plt>
   2115c: aa0003f8     	mov	x24, x0
   21160: 2a1603e0     	mov	w0, w22
   21164: 9400166f     	bl	0x26b20 <close@plt>
   21168: f0ffff41     	adrp	x1, 0xc000
   2116c: 91301421     	add	x1, x1, #0xc05
   21170: 6b17031f     	cmp	w24, w23
   21174: 54000ac1     	b.ne	0x212cc <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc564>
   21178: 90ffff62     	adrp	x2, 0xd000
   2117c: f0ffff43     	adrp	x3, 0xc000
   21180: 91282042     	add	x2, x2, #0xa08
   21184: 9110b463     	add	x3, x3, #0x42d
   21188: 52800060     	mov	w0, #0x3                // =3
   2118c: aa1503e4     	mov	x4, x21
   21190: 94001508     	bl	0x265b0 <__android_log_print@plt>
   21194: 529ff208     	mov	w8, #0xff90             // =65424
   21198: 72a001e8     	movk	w8, #0xf, lsl #16
   2119c: f9400260     	ldr	x0, [x19]
   211a0: eb0802ff     	cmp	x23, x8
   211a4: 1a8832f6     	csel	w22, w23, w8, lo
   211a8: 1101c2c1     	add	w1, w22, #0x70
   211ac: 940006a0     	bl	0x22c2c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdec4>
   211b0: b4000a00     	cbz	x0, 0x212f0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc588>
   211b4: b0ffff69     	adrp	x9, 0xe000
   211b8: f9400008     	ldr	x8, [x0]
   211bc: fd404520     	ldr	d0, [x9, #0x88]
   211c0: b9000916     	str	w22, [x8, #0x8]
   211c4: fd000100     	str	d0, [x8]
   211c8: 34000997     	cbz	w23, 0x212f8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc590>
   211cc: 529ff218     	mov	w24, #0xff90            // =65424
   211d0: 2a1f03fc     	mov	w28, wzr
   211d4: 72a001f8     	movk	w24, #0xf, lsl #16
   211d8: 91003119     	add	x25, x8, #0xc
   211dc: f90007e0     	str	x0, [sp, #0x8]
   211e0: 6b1802ff     	cmp	w23, w24
   211e4: 1a9832fa     	csel	w26, w23, w24, lo
   211e8: 8b3c4281     	add	x1, x20, w28, uxtw
   211ec: aa1903e0     	mov	x0, x25
   211f0: aa1a03e2     	mov	x2, x26
   211f4: 9400152f     	bl	0x266b0 <memcpy@plt>
   211f8: f9400260     	ldr	x0, [x19]
   211fc: f94007e1     	ldr	x1, [sp, #0x8]
   21200: 940006fc     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   21204: 2a0003f6     	mov	w22, w0
   21208: 37f807c0     	tbnz	w0, #0x1f, 0x21300 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc598>
   2120c: 4b1a02e4     	sub	w4, w23, w26
   21210: 6b16009f     	cmp	w4, w22
   21214: 54000ba1     	b.ne	0x21388 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc620>
   21218: 0b1c035c     	add	w28, w26, w28
   2121c: 2a1603f7     	mov	w23, w22
   21220: 35fffe16     	cbnz	w22, 0x211e0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc478>
   21224: 14000063     	b	0x213b0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc648>
   21228: aa1303e0     	mov	x0, x19
   2122c: 940005d4     	bl	0x2297c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdc14>
   21230: f9401768     	ldr	x8, [x27, #0x28]
   21234: f85f83a9     	ldur	x9, [x29, #-0x8]
   21238: eb09011f     	cmp	x8, x9
   2123c: 54000ec0     	b.eq	0x21414 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc6ac>
   21240: 1400007d     	b	0x21434 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc6cc>
   21244: f0ffff54     	adrp	x20, 0xc000
   21248: 91301694     	add	x20, x20, #0xc05
   2124c: 90ffff62     	adrp	x2, 0xd000
   21250: d0ffff43     	adrp	x3, 0xb000
   21254: 2a0003f6     	mov	w22, w0
   21258: 91318042     	add	x2, x2, #0xc60
   2125c: 91052063     	add	x3, x3, #0x148
   21260: 528000c0     	mov	w0, #0x6                // =6
   21264: aa1403e1     	mov	x1, x20
   21268: 940014d2     	bl	0x265b0 <__android_log_print@plt>
   2126c: b0ffff42     	adrp	x2, 0xa000
   21270: 9117c042     	add	x2, x2, #0x5f0
   21274: 528000c0     	mov	w0, #0x6                // =6
   21278: aa1403e1     	mov	x1, x20
   2127c: aa1703e3     	mov	x3, x23
   21280: 940014cc     	bl	0x265b0 <__android_log_print@plt>
   21284: 1400004f     	b	0x213c0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc658>
   21288: 12800116     	mov	w22, #-0x9              // =-9
   2128c: 1400005d     	b	0x21400 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc698>
   21290: 9400156c     	bl	0x26840 <__errno@plt>
   21294: b9400000     	ldr	w0, [x0]
   21298: 9400168a     	bl	0x26cc0 <strerror@plt>
   2129c: f0ffff41     	adrp	x1, 0xc000
   212a0: 90ffff62     	adrp	x2, 0xd000
   212a4: f0ffff43     	adrp	x3, 0xc000
   212a8: aa0003e5     	mov	x5, x0
   212ac: 91301421     	add	x1, x1, #0xc05
   212b0: 91386842     	add	x2, x2, #0xe1a
   212b4: 9110b463     	add	x3, x3, #0x42d
   212b8: 528000c0     	mov	w0, #0x6                // =6
   212bc: aa1503e4     	mov	x4, x21
   212c0: 940014bc     	bl	0x265b0 <__android_log_print@plt>
   212c4: 128000b6     	mov	w22, #-0x6              // =-6
   212c8: 1400003c     	b	0x213b8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc650>
   212cc: 90ffff42     	adrp	x2, 0x9000
   212d0: f0ffff43     	adrp	x3, 0xc000
   212d4: 91203442     	add	x2, x2, #0x80d
   212d8: 9110b463     	add	x3, x3, #0x42d
   212dc: 528000c0     	mov	w0, #0x6                // =6
   212e0: aa1503e4     	mov	x4, x21
   212e4: 940014b3     	bl	0x265b0 <__android_log_print@plt>
   212e8: 128000b6     	mov	w22, #-0x6              // =-6
   212ec: 14000033     	b	0x213b8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc650>
   212f0: 12800116     	mov	w22, #-0x9              // =-9
   212f4: 14000031     	b	0x213b8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc650>
   212f8: 2a1f03f6     	mov	w22, wzr
   212fc: 1400002e     	b	0x213b4 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc64c>
   21300: f0ffff41     	adrp	x1, 0xc000
   21304: f0ffff42     	adrp	x2, 0xc000
   21308: 90ffff63     	adrp	x3, 0xd000
   2130c: 91301421     	add	x1, x1, #0xc05
   21310: 91272842     	add	x2, x2, #0x9ca
   21314: 91394863     	add	x3, x3, #0xe52
   21318: 528000c0     	mov	w0, #0x6                // =6
   2131c: 2a1a03e4     	mov	w4, w26
   21320: 2a1603e5     	mov	w5, w22
   21324: 940014a3     	bl	0x265b0 <__android_log_print@plt>
   21328: f94007e0     	ldr	x0, [sp, #0x8]
   2132c: 9400068e     	bl	0x22d64 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdffc>
   21330: 531a7ac9     	ubfx	w9, w22, #26, #5
   21334: 2a1603e8     	mov	w8, w22
   21338: 340000c9     	cbz	w9, 0x21350 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc5e8>
   2133c: 71007d3f     	cmp	w9, #0x1f
   21340: 2a1603e8     	mov	w8, w22
   21344: 54000060     	b.eq	0x21350 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc5e8>
   21348: 531466c8     	ubfx	w8, w22, #20, #6
   2134c: 4b0803e8     	neg	w8, w8
   21350: 3100491f     	cmn	w8, #0x12
   21354: 54000321     	b.ne	0x213b8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc650>
   21358: f0ffff41     	adrp	x1, 0xc000
   2135c: f0ffff42     	adrp	x2, 0xc000
   21360: 91301421     	add	x1, x1, #0xc05
   21364: 911a4042     	add	x2, x2, #0x690
   21368: 52800080     	mov	w0, #0x4                // =4
   2136c: 94001491     	bl	0x265b0 <__android_log_print@plt>
   21370: aa1503e0     	mov	x0, x21
   21374: 940016ab     	bl	0x26e20 <remove@plt>
   21378: aa1303e0     	mov	x0, x19
   2137c: 94000580     	bl	0x2297c <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdc14>
   21380: 2a0003f6     	mov	w22, w0
   21384: 1400000d     	b	0x213b8 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc650>
   21388: f0ffff41     	adrp	x1, 0xc000
   2138c: 90ffff62     	adrp	x2, 0xd000
   21390: 90ffff63     	adrp	x3, 0xd000
   21394: 91301421     	add	x1, x1, #0xc05
   21398: 913ea842     	add	x2, x2, #0xfaa
   2139c: 91394863     	add	x3, x3, #0xe52
   213a0: 528000c0     	mov	w0, #0x6                // =6
   213a4: 2a1603e5     	mov	w5, w22
   213a8: 94001482     	bl	0x265b0 <__android_log_print@plt>
   213ac: 12800016     	mov	w22, #-0x1              // =-1
   213b0: f94007e0     	ldr	x0, [sp, #0x8]
   213b4: 9400066c     	bl	0x22d64 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xdffc>
   213b8: aa1403e0     	mov	x0, x20
   213bc: 940015ad     	bl	0x26a70 <free@plt>
   213c0: f9400668     	ldr	x8, [x19, #0x8]
   213c4: b0ffff69     	adrp	x9, 0xe000
   213c8: fd40fd20     	ldr	d0, [x9, #0x1f8]
   213cc: f9400108     	ldr	x8, [x8]
   213d0: fd000100     	str	d0, [x8]
   213d4: a9400660     	ldp	x0, x1, [x19]
   213d8: 94000686     	bl	0x22df0 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xe088>
   213dc: 36f80120     	tbz	w0, #0x1f, 0x21400 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc698>
   213e0: f0ffff41     	adrp	x1, 0xc000
   213e4: 90ffff62     	adrp	x2, 0xd000
   213e8: 90ffff63     	adrp	x3, 0xd000
   213ec: 91301421     	add	x1, x1, #0xc05
   213f0: 91318042     	add	x2, x2, #0xc60
   213f4: 9114e063     	add	x3, x3, #0x538
   213f8: 528000c0     	mov	w0, #0x6                // =6
   213fc: 9400146d     	bl	0x265b0 <__android_log_print@plt>
   21400: f9401768     	ldr	x8, [x27, #0x28]
   21404: f85f83a9     	ldur	x9, [x29, #-0x8]
   21408: eb09011f     	cmp	x8, x9
   2140c: 54000141     	b.ne	0x21434 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xc6cc>
   21410: 2a1603e0     	mov	w0, w22
   21414: a94f4ff4     	ldp	x20, x19, [sp, #0xf0]
   21418: a94e57f6     	ldp	x22, x21, [sp, #0xe0]
   2141c: a94d5ff8     	ldp	x24, x23, [sp, #0xd0]
   21420: a94c67fa     	ldp	x26, x25, [sp, #0xc0]
   21424: a94b6ffc     	ldp	x28, x27, [sp, #0xb0]
   21428: a94a7bfd     	ldp	x29, x30, [sp, #0xa0]
   2142c: 910403ff     	add	sp, sp, #0x100
   21430: d65f03c0     	ret
   21434: 9400148f     	bl	0x26670 <__stack_chk_fail@plt>
