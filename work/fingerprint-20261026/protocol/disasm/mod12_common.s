     328: b5f0         	push	{r4, r5, r6, r7, lr}
     32a: af03         	add	r7, sp, #0xc
     32c: e92d 0b00    	push.w	{r8, r9, r11}
     330: f248 0631    	movw	r6, #0x8031
     334: 4604         	mov	r4, r0
     336: f6ce 06a0    	movt	r6, #0xe8a0
     33a: 2c00         	cmp	r4, #0x0
     33c: f106 0026    	add.w	r0, r6, #0x26
     340: d033         	beq	0x3aa <PT_LOAD#2+0x3aa> @ imm = #0x66
     342: f5b1 6f83    	cmp.w	r1, #0x418
     346: d330         	blo	0x3aa <PT_LOAD#2+0x3aa> @ imm = #0x60
     348: b142         	cbz	r2, 0x35c <PT_LOAD#2+0x35c> @ imm = #0x10
     34a: 2a01         	cmp	r2, #0x1
     34c: d108         	bne	0x360 <PT_LOAD#2+0x360> @ imm = #0x10
     34e: 6965         	ldr	r5, [r4, #0x14]
     350: f5b5 6f80    	cmp.w	r5, #0x400
     354: d907         	bls	0x366 <PT_LOAD#2+0x366> @ imm = #0xe
     356: f106 0033    	add.w	r0, r6, #0x33
     35a: e026         	b	0x3aa <PT_LOAD#2+0x3aa> @ imm = #0x4c
     35c: 2000         	movs	r0, #0x0
     35e: e024         	b	0x3aa <PT_LOAD#2+0x3aa> @ imm = #0x48
     360: f106 003a    	add.w	r0, r6, #0x3a
     364: e021         	b	0x3aa <PT_LOAD#2+0x3aa> @ imm = #0x42
     366: f010 f98b    	bl	0x10680 <PT_LOAD#2+0x10680> @ imm = #0x10316
     36a: 4681         	mov	r9, r0
     36c: f1b9 0f00    	cmp.w	r9, #0x0
     370: bf1c         	itt	ne
     372: f899 0000    	ldrbne.w	r0, [r9]
     376: 2800         	cmpne	r0, #0x0
     378: d102         	bne	0x380 <PT_LOAD#2+0x380> @ imm = #0x4
     37a: f8df 9034    	ldr.w	r9, [pc, #0x34]         @ 0x3b0 <PT_LOAD#2+0x3b0>
     37e: 44f9         	add	r9, pc
     380: 4648         	mov	r0, r9
     382: f005 f9f7    	bl	0x5774 <PT_LOAD#2+0x5774> @ imm = #0x53ee
     386: f100 0801    	add.w	r8, r0, #0x1
     38a: 4630         	mov	r0, r6
     38c: 45a8         	cmp	r8, r5
     38e: d80c         	bhi	0x3aa <PT_LOAD#2+0x3aa> @ imm = #0x18
     390: f104 0018    	add.w	r0, r4, #0x18
     394: 4649         	mov	r1, r9
     396: 4642         	mov	r2, r8
     398: f004 ff8f    	bl	0x52ba <PT_LOAD#2+0x52ba> @ imm = #0x4f1e
     39c: 2000         	movs	r0, #0x0
     39e: 2206         	movs	r2, #0x6
     3a0: 2105         	movs	r1, #0x5
     3a2: e9c4 2002    	strd	r2, r0, [r4, #8]
     3a6: e9c4 1804    	strd	r1, r8, [r4, #16]
     3aa: e8bd 0b00    	pop.w	{r8, r9, r11}
     3ae: bdf0         	pop	{r4, r5, r6, r7, pc}
     3b0: 0008         	movs	r0, r1
     3b2: 0008         	movs	r0, r1
