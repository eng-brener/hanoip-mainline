     ca0: b5b0         	push	{r4, r5, r7, lr}
     ca2: af02         	add	r7, sp, #0x8
     ca4: 4c05         	ldr	r4, [pc, #0x14]         @ 0xcbc <PT_LOAD#2+0xcbc>
     ca6: 447c         	add	r4, pc
     ca8: 6820         	ldr	r0, [r4]
     caa: b130         	cbz	r0, 0xcba <PT_LOAD#2+0xcba> @ imm = #0xc
     cac: f010 f940    	bl	0x10f30 <PT_LOAD#2+0x10f30> @ imm = #0x10280
     cb0: 6820         	ldr	r0, [r4]
     cb2: f004 fe39    	bl	0x5928 <PT_LOAD#2+0x5928> @ imm = #0x4c72
     cb6: 2000         	movs	r0, #0x0
     cb8: 6020         	str	r0, [r4]
     cba: bdb0         	pop	{r4, r5, r7, pc}
     cbc: 7d42         	ldrb	r2, [r0, #0x15]
     cbe: 0011         	movs	r1, r2
     cc0: b5f0         	push	{r4, r5, r6, r7, lr}
     cc2: af03         	add	r7, sp, #0xc
     cc4: e92d 0f00    	push.w	{r8, r9, r10, r11}
     cc8: b08b         	sub	sp, #0x2c
     cca: f240 147b    	movw	r4, #0x17b
     cce: 4605         	mov	r5, r0
     cd0: 4616         	mov	r6, r2
     cd2: f6ce 04a1    	movt	r4, #0xe8a1
     cd6: 2d00         	cmp	r5, #0x0
     cd8: f000 80f8    	beq.w	0xecc <PT_LOAD#2+0xecc> @ imm = #0x1f0
     cdc: 2970         	cmp	r1, #0x70
     cde: f0c0 80f5    	blo.w	0xecc <PT_LOAD#2+0xecc> @ imm = #0x1ea
     ce2: f010 fa91    	bl	0x11208 <PT_LOAD#2+0x11208> @ imm = #0x10522
     ce6: 2800         	cmp	r0, #0x0
     ce8: db45         	blt	0xd76 <PT_LOAD#2+0xd76> @ imm = #0x8a
     cea: 3436         	adds	r4, #0x36
     cec: 2e0a         	cmp	r6, #0xa
     cee: f200 80e8    	bhi.w	0xec2 <PT_LOAD#2+0xec2> @ imm = #0x1d0
     cf2: e8df f006    	tbb	[pc, r6]
     cf6: 4206         	tst	r6, r0
     cf8: 635d         	str	r5, [r3, #0x34]
     cfa: cb69         	ldm	r3, {r0, r3, r5, r6}
     cfc: e6d1         	b	0xaa2 <PT_LOAD#2+0xaa2> @ imm = #-0x25e
     cfe: 5bd9         	ldrh	r1, [r3, r7]
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
