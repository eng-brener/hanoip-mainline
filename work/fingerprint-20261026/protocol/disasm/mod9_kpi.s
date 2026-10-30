    2cba: b580         	push	{r7, lr}
    2cbc: 466f         	mov	r7, sp
    2cbe: 4603         	mov	r3, r0
    2cc0: f244 001e    	movw	r0, #0x401e
    2cc4: f6ce 00a1    	movt	r0, #0xe8a1
    2cc8: b1f3         	cbz	r3, 0x2d08 <PT_LOAD#2+0x2d08> @ imm = #0x3c
    2cca: 290c         	cmp	r1, #0xc
    2ccc: d31c         	blo	0x2d08 <PT_LOAD#2+0x2d08> @ imm = #0x38
    2cce: 2a01         	cmp	r2, #0x1
    2cd0: d015         	beq	0x2cfe <PT_LOAD#2+0x2cfe> @ imm = #0x2a
    2cd2: b9c2         	cbnz	r2, 0x2d06 <PT_LOAD#2+0x2d06> @ imm = #0x30
    2cd4: 469e         	mov	lr, r3
    2cd6: 3007         	adds	r0, #0x7
    2cd8: f85e cf08    	ldr	r12, [lr, #8]!
    2cdc: f10c 020c    	add.w	r2, r12, #0xc
    2ce0: 428a         	cmp	r2, r1
    2ce2: d811         	bhi	0x2d08 <PT_LOAD#2+0x2d08> @ imm = #0x22
    2ce4: 290c         	cmp	r1, #0xc
    2ce6: d30f         	blo	0x2d08 <PT_LOAD#2+0x2d08> @ imm = #0x1e
    2ce8: f11c 0f0d    	cmn.w	r12, #0xd
    2cec: bf88         	it	hi
    2cee: bd80         	pophi	{r7, pc}
    2cf0: f103 000c    	add.w	r0, r3, #0xc
    2cf4: 4671         	mov	r1, lr
    2cf6: e8bd 4080    	pop.w	{r7, lr}
    2cfa: f010 baaf    	b.w	0x1325c <PT_LOAD#2+0x1325c> @ imm = #0x1055e
    2cfe: e8bd 4080    	pop.w	{r7, lr}
    2d02: f010 b9ff    	b.w	0x13104 <PT_LOAD#2+0x13104> @ imm = #0x103fe
    2d06: 3012         	adds	r0, #0x12
    2d08: bd80         	pop	{r7, pc}
    2d0a: ba00         	rev	r0, r0
    2d0c: 4770         	bx	lr
    2d0e: ba0a         	rev	r2, r1
    2d10: ba01         	rev	r1, r0
    2d12: 4610         	mov	r0, r2
    2d14: 4770         	bx	lr
    2d16: 2000         	movs	r0, #0x0
    2d18: 4770         	bx	lr
    2d1a: 0000         	movs	r0, r0
    2d1c: 0000         	movs	r0, r0
    2d1e: 0000         	movs	r0, r0
    2d20: b5f0         	push	{r4, r5, r6, r7, lr}
    2d22: af03         	add	r7, sp, #0xc
    2d24: e92d 0f00    	push.w	{r8, r9, r10, r11}
    2d28: b081         	sub	sp, #0x4
    2d2a: ed2d 8b0c    	vpush	{d8, d9, d10, d11, d12, d13}
    2d2e: b092         	sub	sp, #0x48
    2d30: 469b         	mov	r11, r3
    2d32: 4616         	mov	r6, r2
    2d34: b109         	cbz	r1, 0x2d3a <PT_LOAD#2+0x2d3a> @ imm = #0x2
    2d36: 2200         	movs	r2, #0x0
    2d38: 7002         	strb	r2, [r0]
    2d3a: eebe ab00    	vmov.f64	d10, #-5.000000e-01
    2d3e: f04f 0800    	mov.w	r8, #0x0
    2d42: eeb6 bb00    	vmov.f64	d11, #5.000000e-01
    2d46: ad0a         	add	r5, sp, #0x28
    2d48: f8df 47ec    	ldr.w	r4, [pc, #0x7ec]        @ 0x3538 <PT_LOAD#2+0x3538>
    2d4c: f10d 0e3c    	add.w	lr, sp, #0x3c
    2d50: ed9f 8bb1    	vldr	d8, [pc, #708]          @ 0x3018 <PT_LOAD#2+0x3018>
    2d54: ed9f 9bb2    	vldr	d9, [pc, #712]          @ 0x3020 <PT_LOAD#2+0x3020>
    2d58: 447c         	add	r4, pc
    2d5a: 900f         	str	r0, [sp, #0x3c]
    2d5c: 203f         	movs	r0, #0x3f
    2d5e: e9cd 8110    	strd	r8, r1, [sp, #64]
