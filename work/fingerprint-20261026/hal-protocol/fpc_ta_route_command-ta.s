
work/fingerprint-20261026/fpctzapp-reconstructed.elf:	file format elf32-littlearm

Disassembly of section PT_LOAD#2:

00000000 <PT_LOAD#2>:
     1a8: b5b0         	push	{r4, r5, r7, lr}
     1aa: af02         	add	r7, sp, #0x8
     1ac: 4684         	mov	r12, r0
     1ae: 4824         	ldr	r0, [pc, #0x90]         @ 0x240 <PT_LOAD#2+0x240>
     1b0: 4478         	add	r0, pc
     1b2: 7800         	ldrb	r0, [r0]
     1b4: 2801         	cmp	r0, #0x1
     1b6: bf1e         	ittt	ne
     1b8: f244 00be    	movwne	r0, #0x40be
     1bc: f6ce 1010    	movtne	r0, #0xe910
     1c0: bdb0         	popne	{r4, r5, r7, pc}
     1c2: f244 00c6    	movw	r0, #0x40c6
     1c6: f1bc 0f00    	cmp.w	r12, #0x0
     1ca: f6ce 00a0    	movt	r0, #0xe8a0
     1ce: d00f         	beq	0x1f0 <PT_LOAD#2+0x1f0> @ imm = #0x1e
     1d0: 2908         	cmp	r1, #0x8
     1d2: d30d         	blo	0x1f0 <PT_LOAD#2+0x1f0> @ imm = #0x1a
     1d4: 4a1b         	ldr	r2, [pc, #0x6c]         @ 0x244 <PT_LOAD#2+0x244>
     1d6: 2400         	movs	r4, #0x0
     1d8: f8dc e000    	ldr.w	lr, [r12]
     1dc: 447a         	add	r2, pc
     1de: 6813         	ldr	r3, [r2]
     1e0: 68dd         	ldr	r5, [r3, #0xc]
     1e2: 4575         	cmp	r5, lr
     1e4: d005         	beq	0x1f2 <PT_LOAD#2+0x1f2> @ imm = #0xa
     1e6: 3401         	adds	r4, #0x1
     1e8: 3204         	adds	r2, #0x4
     1ea: 2c07         	cmp	r4, #0x7
     1ec: d9f7         	bls	0x1de <PT_LOAD#2+0x1de> @ imm = #-0x12
     1ee: 300e         	adds	r0, #0xe
     1f0: bdb0         	pop	{r4, r5, r7, pc}
     1f2: f1be 0f03    	cmp.w	lr, #0x3
     1f6: d008         	beq	0x20a <PT_LOAD#2+0x20a> @ imm = #0x10
     1f8: f1be 0f08    	cmp.w	lr, #0x8
     1fc: d118         	bne	0x230 <PT_LOAD#2+0x230> @ imm = #0x30
     1fe: f8dc 2004    	ldr.w	r2, [r12, #0x4]
     202: 2a07         	cmp	r2, #0x7
     204: d116         	bne	0x234 <PT_LOAD#2+0x234> @ imm = #0x2c
     206: 2207         	movs	r2, #0x7
     208: e004         	b	0x214 <PT_LOAD#2+0x214> @ imm = #0x8
     20a: f8dc 2004    	ldr.w	r2, [r12, #0x4]
     20e: 1ed5         	subs	r5, r2, #0x3
     210: 2d03         	cmp	r5, #0x3
     212: d20f         	bhs	0x234 <PT_LOAD#2+0x234> @ imm = #0x1e
     214: f8dc 4008    	ldr.w	r4, [r12, #0x8]
     218: 3006         	adds	r0, #0x6
     21a: f104 050c    	add.w	r5, r4, #0xc
     21e: 428d         	cmp	r5, r1
     220: d8e6         	bhi	0x1f0 <PT_LOAD#2+0x1f0> @ imm = #-0x34
     222: 290c         	cmp	r1, #0xc
     224: d3e4         	blo	0x1f0 <PT_LOAD#2+0x1f0> @ imm = #-0x38
     226: f114 0f0d    	cmn.w	r4, #0xd
     22a: bf88         	it	hi
     22c: bdb0         	pophi	{r4, r5, r7, pc}
     22e: e001         	b	0x234 <PT_LOAD#2+0x234> @ imm = #0x2
     230: f8dc 2004    	ldr.w	r2, [r12, #0x4]
     234: 689b         	ldr	r3, [r3, #0x8]
     236: 4660         	mov	r0, r12
     238: e8bd 40b0    	pop.w	{r4, r5, r7, lr}
     23c: 4718         	bx	r3
     23e: bf00         	nop
     240: 8814         	ldrh	r4, [r2]
     242: 0011         	movs	r1, r2
     244: 5e20         	ldrsh	r0, [r4, r0]
     246: 0011         	movs	r1, r2
