
00000000 <PT_LOAD#2>:
     d00: 00de         	lsls	r6, r3, #0x3
     d02: 2000         	movs	r0, #0x0
     d04: a908         	add	r1, sp, #0x20
     d06: 9008         	str	r0, [sp, #0x20]
     d08: 2000         	movs	r0, #0x0
     d0a: f00f fe53    	bl	0x109b4 <PT_LOAD#2+0x109b4> @ imm = #0xfca6
     d0e: 4604         	mov	r4, r0
     d10: f114 0009    	adds.w	r0, r4, #0x9
     d14: d10c         	bne	0xd30 <PT_LOAD#2+0xd30> @ imm = #0x18
     d16: 9808         	ldr	r0, [sp, #0x20]
     d18: f004 fe02    	bl	0x5920 <PT_LOAD#2+0x5920> @ imm = #0x4c04
     d1c: 49a0         	ldr	r1, [pc, #0x280]        @ 0xfa0 <PT_LOAD#2+0xfa0>
     d1e: 2800         	cmp	r0, #0x0
     d20: 4479         	add	r1, pc
     d22: 6008         	str	r0, [r1]
     d24: f000 80eb    	beq.w	0xefe <PT_LOAD#2+0xefe> @ imm = #0x1d6
     d28: a908         	add	r1, sp, #0x20
     d2a: f00f fe43    	bl	0x109b4 <PT_LOAD#2+0x109b4> @ imm = #0xfc86
     d2e: 4604         	mov	r4, r0
     d30: 2c00         	cmp	r4, #0x0
     d32: f2c0 80e8    	blt.w	0xf06 <PT_LOAD#2+0xf06> @ imm = #0x1d0
     d36: f7ff fa8d    	bl	0x254 <PT_LOAD#2+0x254> @ imm = #-0xae6
     d3a: 4604         	mov	r4, r0
     d3c: 2c00         	cmp	r4, #0x0
     d3e: f2c0 80e2    	blt.w	0xf06 <PT_LOAD#2+0xf06> @ imm = #0x1c4
     d42: f7ff fa81    	bl	0x248 <PT_LOAD#2+0x248> @ imm = #-0xafe
     d46: 4e97         	ldr	r6, [pc, #0x25c]        @ 0xfa4 <PT_LOAD#2+0xfa4>
     d48: 4605         	mov	r5, r0
     d4a: 447e         	add	r6, pc
     d4c: 68a9         	ldr	r1, [r5, #0x8]
     d4e: 6830         	ldr	r0, [r6]
     d50: f010 f80c    	bl	0x10d6c <PT_LOAD#2+0x10d6c> @ imm = #0x10018
     d54: 4604         	mov	r4, r0
     d56: 2c00         	cmp	r4, #0x0
     d58: f2c0 80d5    	blt.w	0xf06 <PT_LOAD#2+0xf06> @ imm = #0x1aa
     d5c: 2001         	movs	r0, #0x1
     d5e: f105 0110    	add.w	r1, r5, #0x10
     d62: 7328         	strb	r0, [r5, #0xc]
     d64: 6830         	ldr	r0, [r6]
     d66: f010 fb5e    	bl	0x11426 <PT_LOAD#2+0x11426> @ imm = #0x106bc
     d6a: 4604         	mov	r4, r0
     d6c: f1b4 3fff    	cmp.w	r4, #0xffffffff
     d70: f300 80a7    	bgt.w	0xec2 <PT_LOAD#2+0xec2> @ imm = #0x14e
     d74: e0c7         	b	0xf06 <PT_LOAD#2+0xf06> @ imm = #0x18e
     d76: 4604         	mov	r4, r0
     d78: e0a8         	b	0xecc <PT_LOAD#2+0xecc> @ imm = #0x150
     d7a: f7ff fa65    	bl	0x248 <PT_LOAD#2+0x248> @ imm = #-0xb36
     d7e: 4e87         	ldr	r6, [pc, #0x21c]        @ 0xf9c <PT_LOAD#2+0xf9c>
     d80: 4605         	mov	r5, r0
     d82: 447e         	add	r6, pc
     d84: 68a9         	ldr	r1, [r5, #0x8]
     d86: 6830         	ldr	r0, [r6]
     d88: f010 f8e2    	bl	0x10f50 <PT_LOAD#2+0x10f50> @ imm = #0x101c4
     d8c: 4604         	mov	r4, r0
     d8e: f3c4 6184    	ubfx	r1, r4, #0x1a, #0x5
     d92: b139         	cbz	r1, 0xda4 <PT_LOAD#2+0xda4> @ imm = #0xe
     d94: 4620         	mov	r0, r4
     d96: 291f         	cmp	r1, #0x1f
     d98: d004         	beq	0xda4 <PT_LOAD#2+0xda4> @ imm = #0x8
     d9a: f3c4 5005    	ubfx	r0, r4, #0x14, #0x6
     d9e: 2c00         	cmp	r4, #0x0
     da0: bfd8         	it	le
     da2: 4240         	rsble	r0, r0, #0
     da4: 1e41         	subs	r1, r0, #0x1
     da6: 2902         	cmp	r1, #0x2
     da8: f080 8095    	bhs.w	0xed6 <PT_LOAD#2+0xed6> @ imm = #0x12a
     dac: 2400         	movs	r4, #0x0
     dae: e088         	b	0xec2 <PT_LOAD#2+0xec2> @ imm = #0x110
     db0: 4879         	ldr	r0, [pc, #0x1e4]        @ 0xf98 <PT_LOAD#2+0xf98>
     db2: 4478         	add	r0, pc
     db4: 6800         	ldr	r0, [r0]
     db6: f010 f97b    	bl	0x110b0 <PT_LOAD#2+0x110b0> @ imm = #0x102f6
     dba: e081         	b	0xec0 <PT_LOAD#2+0xec0> @ imm = #0x102
     dbc: 4875         	ldr	r0, [pc, #0x1d4]        @ 0xf94 <PT_LOAD#2+0xf94>
     dbe: 4478         	add	r0, pc
     dc0: 6800         	ldr	r0, [r0]
     dc2: f010 f959    	bl	0x11078 <PT_LOAD#2+0x11078> @ imm = #0x102b2
     dc6: e07b         	b	0xec0 <PT_LOAD#2+0xec0> @ imm = #0xf6
     dc8: ac02         	add	r4, sp, #0x8
     dca: 4620         	mov	r0, r4
     dcc: f00f fcf8    	bl	0x107c0 <PT_LOAD#2+0x107c0> @ imm = #0xf9f0
     dd0: 486f         	ldr	r0, [pc, #0x1bc]        @ 0xf90 <PT_LOAD#2+0xf90>
     dd2: 7a29         	ldrb	r1, [r5, #0x8]
     dd4: 4478         	add	r0, pc
     dd6: f8d5 8014    	ldr.w	r8, [r5, #0x14]
     dda: 2900         	cmp	r1, #0x0
     ddc: f8d5 900c    	ldr.w	r9, [r5, #0xc]
     de0: 6800         	ldr	r0, [r0]
     de2: f000 8086    	beq.w	0xef2 <PT_LOAD#2+0xef2> @ imm = #0x10c
     de6: 1d26         	adds	r6, r4, #0x4
     de8: 4631         	mov	r1, r6
     dea: f010 f97d    	bl	0x110e8 <PT_LOAD#2+0x110e8> @ imm = #0x102fa
     dee: 4604         	mov	r4, r0
     df0: f044 0002    	orr	r0, r4, #0x2
     df4: 2803         	cmp	r0, #0x3
     df6: f040 8091    	bne.w	0xf1c <PT_LOAD#2+0xf1c> @ imm = #0x122
     dfa: 2000         	movs	r0, #0x0
     dfc: a905         	add	r1, sp, #0x14
     dfe: e9cd 9800    	strd	r9, r8, [sp]
     e02: e9cd 0008    	strd	r0, r0, [sp, #32]
     e06: e9cd 0006    	strd	r0, r0, [sp, #24]
     e0a: e9cd 0004    	strd	r0, r0, [sp, #16]
     e0e: 4869         	ldr	r0, [pc, #0x1a4]        @ 0xfb4 <PT_LOAD#2+0xfb4>
     e10: 4478         	add	r0, pc
     e12: 6800         	ldr	r0, [r0]
     e14: f010 f9e8    	bl	0x111e8 <PT_LOAD#2+0x111e8> @ imm = #0x103d0
     e18: 4604         	mov	r4, r0
     e1a: 2c00         	cmp	r4, #0x0
     e1c: db7c         	blt	0xf18 <PT_LOAD#2+0xf18> @ imm = #0xf8
     e1e: a808         	add	r0, sp, #0x20
     e20: f002 fe37    	bl	0x3a92 <PT_LOAD#2+0x3a92> @ imm = #0x2c6e
     e24: f04f 39ff    	mov.w	r9, #0xffffffff
     e28: f10d 0a10    	add.w	r10, sp, #0x10
     e2c: f10d 0b18    	add.w	r11, sp, #0x18
     e30: f247 5830    	movw	r8, #0x7530
     e34: e9dd 0108    	ldrd	r0, r1, [sp, #32]
     e38: e9cd 0106    	strd	r0, r1, [sp, #24]
     e3c: f109 0901    	add.w	r9, r9, #0x1
     e40: f1b9 0f3b    	cmp.w	r9, #0x3b
     e44: d868         	bhi	0xf18 <PT_LOAD#2+0xf18> @ imm = #0xd0
     e46: 4859         	ldr	r0, [pc, #0x164]        @ 0xfac <PT_LOAD#2+0xfac>
     e48: 4651         	mov	r1, r10
     e4a: 4632         	mov	r2, r6
     e4c: 4478         	add	r0, pc
     e4e: 6800         	ldr	r0, [r0]
     e50: f010 f9a0    	bl	0x11194 <PT_LOAD#2+0x11194> @ imm = #0x10340
     e54: 4604         	mov	r4, r0
     e56: 2c00         	cmp	r4, #0x0
     e58: db5e         	blt	0xf18 <PT_LOAD#2+0xf18> @ imm = #0xbc
     e5a: e9dd 4004    	ldrd	r4, r0, [sp, #16]
     e5e: 4284         	cmp	r4, r0
     e60: d259         	bhs	0xf16 <PT_LOAD#2+0xf16> @ imm = #0xb2
     e62: 4658         	mov	r0, r11
     e64: f002 fe15    	bl	0x3a92 <PT_LOAD#2+0x3a92> @ imm = #0x2c2a
     e68: e9dd 0108    	ldrd	r0, r1, [sp, #32]
     e6c: 2c00         	cmp	r4, #0x0
     e6e: e9dd 2306    	ldrd	r2, r3, [sp, #24]
     e72: f04f 0401    	mov.w	r4, #0x1
     e76: bf08         	it	eq
     e78: 2403         	moveq	r4, #0x3
     e7a: 1a10         	subs	r0, r2, r0
     e7c: eb63 0101    	sbc.w	r1, r3, r1
     e80: ebb0 0008    	subs.w	r0, r0, r8
     e84: f171 0000    	sbcs	r0, r1, #0x0
     e88: d3d8         	blo	0xe3c <PT_LOAD#2+0xe3c> @ imm = #-0x50
     e8a: e045         	b	0xf18 <PT_LOAD#2+0xf18> @ imm = #0x8a
     e8c: 483f         	ldr	r0, [pc, #0xfc]         @ 0xf8c <PT_LOAD#2+0xf8c>
     e8e: 4478         	add	r0, pc
     e90: 6800         	ldr	r0, [r0]
     e92: f00f fd65    	bl	0x10960 <PT_LOAD#2+0x10960> @ imm = #0xfaca
     e96: e013         	b	0xec0 <PT_LOAD#2+0xec0> @ imm = #0x26
     e98: 483b         	ldr	r0, [pc, #0xec]         @ 0xf88 <PT_LOAD#2+0xf88>
     e9a: f105 0108    	add.w	r1, r5, #0x8
     e9e: 4478         	add	r0, pc
     ea0: 6800         	ldr	r0, [r0]
     ea2: f014 facf    	bl	0x15444 <PT_LOAD#2+0x15444> @ imm = #0x1459e
     ea6: e00b         	b	0xec0 <PT_LOAD#2+0xec0> @ imm = #0x16
     ea8: f240 1425    	movw	r4, #0x125
     eac: f6ce 04f1    	movt	r4, #0xe8f1
     eb0: e007         	b	0xec2 <PT_LOAD#2+0xec2> @ imm = #0xe
     eb2: 4834         	ldr	r0, [pc, #0xd0]         @ 0xf84 <PT_LOAD#2+0xf84>
     eb4: f105 0108    	add.w	r1, r5, #0x8
     eb8: 4478         	add	r0, pc
     eba: 6800         	ldr	r0, [r0]
     ebc: f010 fab8    	bl	0x11430 <PT_LOAD#2+0x11430> @ imm = #0x10570
     ec0: 4604         	mov	r4, r0
     ec2: f010 f9db    	bl	0x1127c <PT_LOAD#2+0x1127c> @ imm = #0x103b6
     ec6: 2800         	cmp	r0, #0x0
     ec8: bfb8         	it	lt
     eca: 4604         	movlt	r4, r0
     ecc: 4620         	mov	r0, r4
     ece: b00b         	add	sp, #0x2c
