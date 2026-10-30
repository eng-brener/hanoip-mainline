    4324: b5f0         	push	{r4, r5, r6, r7, lr}
    4326: af03         	add	r7, sp, #0xc
    4328: e92d 0700    	push.w	{r8, r9, r10}
    432c: b088         	sub	sp, #0x20
    432e: f24c 05a1    	movw	r5, #0xc0a1
    4332: 4681         	mov	r9, r0
    4334: f6ce 05a1    	movt	r5, #0xe8a1
    4338: 4616         	mov	r6, r2
    433a: 462c         	mov	r4, r5
    433c: f1b9 0f00    	cmp.w	r9, #0x0
    4340: f000 8067    	beq.w	0x4412 <PT_LOAD#2+0x4412> @ imm = #0xce
    4344: 2934         	cmp	r1, #0x34
    4346: f0c0 8064    	blo.w	0x4412 <PT_LOAD#2+0x4412> @ imm = #0xc8
    434a: f00c ff5d    	bl	0x11208 <PT_LOAD#2+0x11208> @ imm = #0xceba
    434e: 4604         	mov	r4, r0
    4350: 2c00         	cmp	r4, #0x0
    4352: f040 805e    	bne.w	0x4412 <PT_LOAD#2+0x4412> @ imm = #0xbc
    4356: f7fb ff77    	bl	0x248 <PT_LOAD#2+0x248> @ imm = #-0x4112
    435a: 4680         	mov	r8, r0
    435c: f105 042d    	add.w	r4, r5, #0x2d
    4360: f7fc fc98    	bl	0xc94 <PT_LOAD#2+0xc94> @ imm = #-0x36d0
    4364: 2e06         	cmp	r6, #0x6
    4366: f200 804f    	bhi.w	0x4408 <PT_LOAD#2+0x4408> @ imm = #0x9e
    436a: e8df f006    	tbb	[pc, r6]
    436e: 0904         	lsrs	r4, r0, #0x4
    4370: 130e         	asrs	r6, r1, #0xc
    4372: 4d27         	ldr	r5, [pc, #0x9c]         @ 0x4410 <PT_LOAD#2+0x4410>
    4374: 0048         	lsls	r0, r1, #0x1
    4376: f109 012c    	add.w	r1, r9, #0x2c
    437a: f018 fbd9    	bl	0x1cb30 <PT_LOAD#2+0x1cb30> @ imm = #0x187b2
    437e: e042         	b	0x4406 <PT_LOAD#2+0x4406> @ imm = #0x84
    4380: f109 012c    	add.w	r1, r9, #0x2c
    4384: f018 faba    	bl	0x1c8fc <PT_LOAD#2+0x1c8fc> @ imm = #0x18574
    4388: e03d         	b	0x4406 <PT_LOAD#2+0x4406> @ imm = #0x7a
    438a: f109 012c    	add.w	r1, r9, #0x2c
    438e: f018 fc2b    	bl	0x1cbe8 <PT_LOAD#2+0x1cbe8> @ imm = #0x18856
    4392: e038         	b	0x4406 <PT_LOAD#2+0x4406> @ imm = #0x70
    4394: f8d9 5008    	ldr.w	r5, [r9, #0x8]
    4398: f7fc fc7c    	bl	0xc94 <PT_LOAD#2+0xc94> @ imm = #-0x3708
    439c: 2d0c         	cmp	r5, #0xc
    439e: f200 8074    	bhi.w	0x448a <PT_LOAD#2+0x448a> @ imm = #0xe8
    43a2: 2401         	movs	r4, #0x1
    43a4: e8df f005    	tbb	[pc, r5]
    43a8: 7330         	strb	r0, [r6, #0xc]
    43aa: 7976         	ldrb	r6, [r6, #0x5]
    43ac: 807c         	strh	r4, [r7, #0x2]
    43ae: 8683         	strh	r3, [r0, #0x34]
    43b0: 8930         	ldrh	r0, [r6, #0x8]
    43b2: 0707         	lsls	r7, r0, #0x1c
    43b4: 0007         	movs	r7, r0
    43b6: f017 fb54    	bl	0x1ba62 <PT_LOAD#2+0x1ba62> @ imm = #0x176a8
    43ba: e024         	b	0x4406 <PT_LOAD#2+0x4406> @ imm = #0x48
    43bc: f8d9 4008    	ldr.w	r4, [r9, #0x8]
    43c0: f7fb ff42    	bl	0x248 <PT_LOAD#2+0x248> @ imm = #-0x417c
    43c4: 4605         	mov	r5, r0
    43c6: f7fc fc65    	bl	0xc94 <PT_LOAD#2+0xc94> @ imm = #-0x3736
    43ca: 2200         	movs	r2, #0x0
    43cc: 464e         	mov	r6, r9
    43ce: 68a9         	ldr	r1, [r5, #0x8]
