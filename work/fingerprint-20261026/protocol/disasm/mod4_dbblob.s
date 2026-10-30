    4048: b5f0         	push	{r4, r5, r6, r7, lr}
    404a: af03         	add	r7, sp, #0xc
    404c: e92d 0f00    	push.w	{r8, r9, r10, r11}
    4050: b083         	sub	sp, #0xc
    4052: f24c 0b74    	movw	r11, #0xc074
    4056: 4614         	mov	r4, r2
    4058: f6ce 0ba0    	movt	r11, #0xe8a0
    405c: 460d         	mov	r5, r1
    405e: 4606         	mov	r6, r0
    4060: f10b 0aad    	add.w	r10, r11, #0xad
    4064: f7fc f9a6    	bl	0x3b4 <PT_LOAD#2+0x3b4> @ imm = #-0x3cb4
    4068: 4681         	mov	r9, r0
    406a: 2e00         	cmp	r6, #0x0
    406c: d04c         	beq	0x4108 <PT_LOAD#2+0x4108> @ imm = #0x98
    406e: 2d70         	cmp	r5, #0x70
    4070: d34a         	blo	0x4108 <PT_LOAD#2+0x4108> @ imm = #0x94
    4072: 1fa1         	subs	r1, r4, #0x6
    4074: f10b 0acd    	add.w	r10, r11, #0xcd
    4078: 290b         	cmp	r1, #0xb
    407a: d845         	bhi	0x4108 <PT_LOAD#2+0x4108> @ imm = #0x8a
    407c: f24c 006f    	movw	r0, #0xc06f
    4080: f6ce 1010    	movt	r0, #0xe910
    4084: e8df f001    	tbb	[pc, r1]
    4088: 4006         	ands	r6, r0
    408a: 4040         	eors	r0, r0
    408c: 4040         	eors	r0, r0
    408e: 4040         	eors	r0, r0
    4090: 3c14         	subs	r4, #0x14
    4092: 7245         	strb	r5, [r0, #0x9]
    4094: f8d9 0000    	ldr.w	r0, [r9]
    4098: a902         	add	r1, sp, #0x8
    409a: f7fd fec5    	bl	0x1e28 <PT_LOAD#2+0x1e28> @ imm = #-0x2276
    409e: 4682         	mov	r10, r0
    40a0: f1ba 0f00    	cmp.w	r10, #0x0
    40a4: d130         	bne	0x4108 <PT_LOAD#2+0x4108> @ imm = #0x60
    40a6: 9802         	ldr	r0, [sp, #0x8]
    40a8: f7ff fc6c    	bl	0x3984 <PT_LOAD#2+0x3984> @ imm = #-0x728
    40ac: 60b0         	str	r0, [r6, #0x8]
    40ae: e029         	b	0x4104 <PT_LOAD#2+0x4104> @ imm = #0x52
    40b0: 4c90         	ldr	r4, [pc, #0x240]        @ 0x42f4 <PT_LOAD#2+0x42f4>
    40b2: 2300         	movs	r3, #0x0
    40b4: e9d6 2103    	ldrd	r2, r1, [r6, #12]
    40b8: 4682         	mov	r10, r0
    40ba: 447c         	add	r4, pc
    40bc: 9302         	str	r3, [sp, #0x8]
    40be: 6823         	ldr	r3, [r4]
    40c0: 3301         	adds	r3, #0x1
    40c2: d121         	bne	0x4108 <PT_LOAD#2+0x4108> @ imm = #0x42
    40c4: f245 75ff    	movw	r5, #0x57ff
    40c8: 1e48         	subs	r0, r1, #0x1
    40ca: f2c0 051b    	movt	r5, #0x1b
    40ce: 46da         	mov	r10, r11
    40d0: 42a8         	cmp	r0, r5
    40d2: d819         	bhi	0x4108 <PT_LOAD#2+0x4108> @ imm = #0x32
    40d4: f24c 0a7e    	movw	r10, #0xc07e
    40d8: 2a00         	cmp	r2, #0x0
    40da: f6ce 0a90    	movt	r10, #0xe890
    40de: f000 80a9    	beq.w	0x4234 <PT_LOAD#2+0x4234> @ imm = #0x152
    40e2: 2a01         	cmp	r2, #0x1
    40e4: f040 80ed    	bne.w	0x42c2 <PT_LOAD#2+0x42c2> @ imm = #0x1da
    40e8: f8d9 00dc    	ldr.w	r0, [r9, #0xdc]
    40ec: 6120         	str	r0, [r4, #0x10]
    40ee: b158         	cbz	r0, 0x4108 <PT_LOAD#2+0x4108> @ imm = #0x16
