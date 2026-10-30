    3da4: b5f0         	push	{r4, r5, r6, r7, lr}
    3da6: af03         	add	r7, sp, #0xc
    3da8: e92d 0700    	push.w	{r8, r9, r10}
    3dac: b088         	sub	sp, #0x20
    3dae: f244 0363    	movw	r3, #0x4063
    3db2: 4604         	mov	r4, r0
    3db4: f6ce 03a3    	movt	r3, #0xe8a3
    3db8: 2c00         	cmp	r4, #0x0
    3dba: f103 00ce    	add.w	r0, r3, #0xce
    3dbe: f000 8113    	beq.w	0x3fe8 <PT_LOAD#2+0x3fe8> @ imm = #0x226
    3dc2: 2910         	cmp	r1, #0x10
    3dc4: f0c0 8110    	blo.w	0x3fe8 <PT_LOAD#2+0x3fe8> @ imm = #0x220
    3dc8: 1e50         	subs	r0, r2, #0x1
    3dca: 2805         	cmp	r0, #0x5
    3dcc: d810         	bhi	0x3df0 <PT_LOAD#2+0x3df0> @ imm = #0x20
    3dce: e8df f000    	tbb	[pc, r0]
    3dd2: 1203         	asrs	r3, r0, #0x8
    3dd4: 342e         	adds	r4, #0x2e
    3dd6: 513a         	str	r2, [r7, r4]
    3dd8: 4d89         	ldr	r5, [pc, #0x224]        @ 0x4000 <PT_LOAD#2+0x4000>
    3dda: e9d4 4602    	ldrd	r4, r6, [r4, #8]
    3dde: 447d         	add	r5, pc
    3de0: 6828         	ldr	r0, [r5]
    3de2: 30a8         	adds	r0, #0xa8
    3de4: f7fc faec    	bl	0x3c0 <PT_LOAD#2+0x3c0> @ imm = #-0x3a28
    3de8: e9c5 4602    	strd	r4, r6, [r5, #8]
    3dec: 2000         	movs	r0, #0x0
    3dee: e0fb         	b	0x3fe8 <PT_LOAD#2+0x3fe8> @ imm = #0x1f6
    3df0: f103 00e9    	add.w	r0, r3, #0xe9
    3df4: e0f8         	b	0x3fe8 <PT_LOAD#2+0x3fe8> @ imm = #0x1f0
    3df6: 4d81         	ldr	r5, [pc, #0x204]        @ 0x3ffc <PT_LOAD#2+0x3ffc>
    3df8: 2000         	movs	r0, #0x0
    3dfa: 2606         	movs	r6, #0x6
    3dfc: f844 0f08    	str	r0, [r4, #8]!
    3e00: 447d         	add	r5, pc
    3e02: 6060         	str	r0, [r4, #0x4]
    3e04: e9c5 0004    	strd	r0, r0, [r5, #16]
    3e08: 4620         	mov	r0, r4
    3e0a: 2108         	movs	r1, #0x8
    3e0c: f7ff fd96    	bl	0x393c <PT_LOAD#2+0x393c> @ imm = #-0x4d4
    3e10: e9d4 1200    	ldrd	r1, r2, [r4]
    3e14: 4311         	orrs	r1, r2
    3e16: d12f         	bne	0x3e78 <PT_LOAD#2+0x3e78> @ imm = #0x5e
    3e18: 3e01         	subs	r6, #0x1
    3e1a: 2e00         	cmp	r6, #0x0
    3e1c: dcf4         	bgt	0x3e08 <PT_LOAD#2+0x3e08> @ imm = #-0x18
    3e1e: f244 01ac    	movw	r1, #0x40ac
    3e22: 2800         	cmp	r0, #0x0
    3e24: f6ce 0153    	movt	r1, #0xe853
    3e28: bf08         	it	eq
    3e2a: 4608         	moveq	r0, r1
    3e2c: e0dc         	b	0x3fe8 <PT_LOAD#2+0x3fe8> @ imm = #0x1b8
    3e2e: 68a0         	ldr	r0, [r4, #0x8]
    3e30: 2845         	cmp	r0, #0x45
    3e32: d22e         	bhs	0x3e92 <PT_LOAD#2+0x3e92> @ imm = #0x5c
    3e34: f103 0059    	add.w	r0, r3, #0x59
    3e38: e0d6         	b	0x3fe8 <PT_LOAD#2+0x3fe8> @ imm = #0x1ac
    3e3a: 68a0         	ldr	r0, [r4, #0x8]
    3e3c: 2845         	cmp	r0, #0x45
    3e3e: d237         	bhs	0x3eb0 <PT_LOAD#2+0x3eb0> @ imm = #0x6e
