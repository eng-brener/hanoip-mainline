    44c0: b5f0         	push	{r4, r5, r6, r7, lr}
    44c2: af03         	add	r7, sp, #0xc
    44c4: f84d 8d04    	str	r8, [sp, #-4]!
    44c8: b086         	sub	sp, #0x18
    44ca: 466c         	mov	r4, sp
    44cc: f36f 0403    	bfc	r4, #0, #4
    44d0: 46a5         	mov	sp, r4
    44d2: f248 0823    	movw	r8, #0x8023
    44d6: 4605         	mov	r5, r0
    44d8: f6ce 08a1    	movt	r8, #0xe8a1
    44dc: 4616         	mov	r6, r2
    44de: 4644         	mov	r4, r8
    44e0: 2d00         	cmp	r5, #0x0
    44e2: d054         	beq	0x458e <PT_LOAD#2+0x458e> @ imm = #0xa8
    44e4: 2920         	cmp	r1, #0x20
    44e6: d352         	blo	0x458e <PT_LOAD#2+0x458e> @ imm = #0xa4
    44e8: f00c fe8e    	bl	0x11208 <PT_LOAD#2+0x11208> @ imm = #0xcd1c
    44ec: 4604         	mov	r4, r0
    44ee: 2c00         	cmp	r4, #0x0
    44f0: d14d         	bne	0x458e <PT_LOAD#2+0x458e> @ imm = #0x9a
    44f2: 1e74         	subs	r4, r6, #0x1
    44f4: f7fc fbce    	bl	0xc94 <PT_LOAD#2+0xc94> @ imm = #-0x3864
    44f8: 4606         	mov	r6, r0
    44fa: 2c06         	cmp	r4, #0x6
    44fc: d80e         	bhi	0x451c <PT_LOAD#2+0x451c> @ imm = #0x1c
    44fe: e8df f004    	tbb	[pc, r4]
    4502: 1004         	asrs	r4, r0, #0x20
    4504: 291d         	cmp	r1, #0x1d
    4506: 352f         	adds	r5, #0x2f
    4508: 003a         	movs	r2, r7
    450a: 9600         	str	r6, [sp]
    450c: f7fb fe9c    	bl	0x248 <PT_LOAD#2+0x248> @ imm = #-0x42c8
    4510: 6880         	ldr	r0, [r0, #0x8]
    4512: 9001         	str	r0, [sp, #0x4]
    4514: 4668         	mov	r0, sp
    4516: f00f fbfb    	bl	0x13d10 <PT_LOAD#2+0x13d10> @ imm = #0xf7f6
    451a: e032         	b	0x4582 <PT_LOAD#2+0x4582> @ imm = #0x64
    451c: f108 0438    	add.w	r4, r8, #0x38
    4520: e030         	b	0x4584 <PT_LOAD#2+0x4584> @ imm = #0x60
    4522: f00f fcdd    	bl	0x13ee0 <PT_LOAD#2+0x13ee0> @ imm = #0xf9ba
    4526: 4604         	mov	r4, r0
    4528: 4630         	mov	r0, r6
    452a: f00c fa19    	bl	0x10960 <PT_LOAD#2+0x10960> @ imm = #0xc432
    452e: 2c00         	cmp	r4, #0x0
    4530: db28         	blt	0x4584 <PT_LOAD#2+0x4584> @ imm = #0x50
    4532: f1b0 3fff    	cmp.w	r0, #0xffffffff
    4536: bfd8         	it	le
    4538: 4604         	movle	r4, r0
    453a: e023         	b	0x4584 <PT_LOAD#2+0x4584> @ imm = #0x46
    453c: 466e         	mov	r6, sp
    453e: 4630         	mov	r0, r6
    4540: f00f fb58    	bl	0x13bf4 <PT_LOAD#2+0x13bf4> @ imm = #0xf6b0
    4544: f966 0acf    	vld1.64	{d16, d17}, [r6]
    4548: 4604         	mov	r4, r0
    454a: f105 0008    	add.w	r0, r5, #0x8
    454e: f940 0a8f    	vst1.32	{d16, d17}, [r0]
    4552: e017         	b	0x4584 <PT_LOAD#2+0x4584> @ imm = #0x2e
    4554: f105 0108    	add.w	r1, r5, #0x8
    4558: 4630         	mov	r0, r6
    455a: f00f fa73    	bl	0x13a44 <PT_LOAD#2+0x13a44> @ imm = #0xf4e6
    455e: e010         	b	0x4582 <PT_LOAD#2+0x4582> @ imm = #0x20
    4560: f105 0108    	add.w	r1, r5, #0x8
    4564: 4630         	mov	r0, r6
    4566: f00f facf    	bl	0x13b08 <PT_LOAD#2+0x13b08> @ imm = #0xf59e
    456a: e00a         	b	0x4582 <PT_LOAD#2+0x4582> @ imm = #0x14
    456c: f105 0008    	add.w	r0, r5, #0x8
