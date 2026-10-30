     420: b5f0         	push	{r4, r5, r6, r7, lr}
     422: af03         	add	r7, sp, #0xc
     424: e92d 0f00    	push.w	{r8, r9, r10, r11}
     428: b097         	sub	sp, #0x5c
     42a: f248 15cf    	movw	r5, #0x81cf
     42e: 4681         	mov	r9, r0
     430: f6ce 05a2    	movt	r5, #0xe8a2
     434: f1b9 0f00    	cmp.w	r9, #0x0
     438: f505 7b88    	add.w	r11, r5, #0x110
     43c: f000 82a9    	beq.w	0x992 <PT_LOAD#2+0x992> @ imm = #0x552
     440: 2970         	cmp	r1, #0x70
     442: f0c0 82a6    	blo.w	0x992 <PT_LOAD#2+0x992> @ imm = #0x54c
     446: f8d9 1008    	ldr.w	r1, [r9, #0x8]
     44a: f248 3b10    	movw	r11, #0x8310
     44e: f6ce 0ba2    	movt	r11, #0xe8a2
     452: 2a0b         	cmp	r2, #0xb
     454: 9105         	str	r1, [sp, #0x14]
     456: f200 8299    	bhi.w	0x98c <PT_LOAD#2+0x98c> @ imm = #0x532
     45a: f248 1aea    	movw	r10, #0x81ea
     45e: f248 2473    	movw	r4, #0x8273
     462: f248 0650    	movw	r6, #0x8050
     466: f6ce 0a12    	movt	r10, #0xe812
     46a: f6ce 0492    	movt	r4, #0xe892
     46e: f6ce 06a2    	movt	r6, #0xe8a2
     472: e8df f012    	tbh	[pc, r2, lsl #1]
     476: 000c         	movs	r4, r1
     478: 0035         	movs	r5, r6
     47a: 006c         	lsls	r4, r5, #0x1
     47c: 00a9         	lsls	r1, r5, #0x2
     47e: 00e9         	lsls	r1, r5, #0x3
     480: 01a6         	lsls	r6, r4, #0x6
     482: 028b         	lsls	r3, r1, #0xa
     484: 0221         	lsls	r1, r4, #0x8
     486: 022d         	lsls	r5, r5, #0x8
     488: 0265         	lsls	r5, r4, #0x9
     48a: 027b         	lsls	r3, r7, #0x9
     48c: 0282         	lsls	r2, r0, #0xa
     48e: f8df 66d0    	ldr.w	r6, [pc, #0x6d0]        @ 0xb60 <PT_LOAD#2+0xb60>
     492: 2100         	movs	r1, #0x0
     494: 22e8         	movs	r2, #0xe8
     496: 447e         	add	r6, pc
     498: 6835         	ldr	r5, [r6]
     49a: 4628         	mov	r0, r5
     49c: f005 f916    	bl	0x56cc <PT_LOAD#2+0x56cc> @ imm = #0x522c
     4a0: f04f 30ff    	mov.w	r0, #0xffffffff
     4a4: 2100         	movs	r1, #0x0
     4a6: 6068         	str	r0, [r5, #0x4]
     4a8: 4628         	mov	r0, r5
     4aa: 2200         	movs	r2, #0x0
     4ac: f000 ff76    	bl	0x139c <PT_LOAD#2+0x139c> @ imm = #0xeec
     4b0: 4683         	mov	r11, r0
     4b2: f1bb 0f00    	cmp.w	r11, #0x0
     4b6: f040 8269    	bne.w	0x98c <PT_LOAD#2+0x98c> @ imm = #0x4d2
     4ba: a906         	add	r1, sp, #0x18
     4bc: 2000         	movs	r0, #0x0
     4be: f005 ff4f    	bl	0x6360 <PT_LOAD#2+0x6360> @ imm = #0x5e9e
     4c2: 3009         	adds	r0, #0x9
     4c4: f040 8292    	bne.w	0x9ec <PT_LOAD#2+0x9ec> @ imm = #0x524
     4c8: 9806         	ldr	r0, [sp, #0x18]
     4ca: f005 fa29    	bl	0x5920 <PT_LOAD#2+0x5920> @ imm = #0x5452
     4ce: 6831         	ldr	r1, [r6]
     4d0: 2800         	cmp	r0, #0x0
     4d2: f8c1 00d8    	str.w	r0, [r1, #0xd8]
     4d6: f040 828c    	bne.w	0x9f2 <PT_LOAD#2+0x9f2> @ imm = #0x518
     4da: f104 0bba    	add.w	r11, r4, #0xba
     4de: e255         	b	0x98c <PT_LOAD#2+0x98c> @ imm = #0x4aa
     4e0: f8df 8674    	ldr.w	r8, [pc, #0x674]        @ 0xb58 <PT_LOAD#2+0xb58>
     4e4: 44f8         	add	r8, pc
     4e6: f8d8 0000    	ldr.w	r0, [r8]
     4ea: 6800         	ldr	r0, [r0]
     4ec: 2800         	cmp	r0, #0x0
     4ee: f000 8255    	beq.w	0x99c <PT_LOAD#2+0x99c> @ imm = #0x4aa
     4f2: f8d8 5000    	ldr.w	r5, [r8]
     4f6: 2401         	movs	r4, #0x1
     4f8: f7ff fea6    	bl	0x248 <PT_LOAD#2+0x248> @ imm = #-0x2b4
     4fc: 7304         	strb	r4, [r0, #0xc]
     4fe: 2005         	movs	r0, #0x5
     500: 462a         	mov	r2, r5
     502: f842 0f9c    	str	r0, [r2, #156]!
     506: f855 0b74    	ldr	r0, [r5], #116
     50a: 4629         	mov	r1, r5
     50c: f001 ffc1    	bl	0x2492 <PT_LOAD#2+0x2492> @ imm = #0x1f82
     510: 4683         	mov	r11, r0
     512: f1bb 0f00    	cmp.w	r11, #0x0
     516: f040 8239    	bne.w	0x98c <PT_LOAD#2+0x98c> @ imm = #0x472
     51a: f8d8 1000    	ldr.w	r1, [r8]
     51e: f8d1 209c    	ldr.w	r2, [r1, #0x9c]
