
work/fingerprint-20261026/fpctzapp-reconstructed.elf:	file format elf32-littlearm

Disassembly of section PT_LOAD#2:

00000000 <PT_LOAD#2>:
   1069c: 4613         	mov	r3, r2
   1069e: f8d3 c000    	ldr.w	r12, [r3]
   106a2: f244 0277    	movw	r2, #0x4077
   106a6: f6cf 02a7    	movt	r2, #0xf8a7
   106aa: f1bc 0f33    	cmp.w	r12, #0x33
   106ae: d802         	bhi	0x106b6 <PT_LOAD#2+0x106b6> @ imm = #0x4
   106b0: 2034         	movs	r0, #0x34
   106b2: 6018         	str	r0, [r3]
   106b4: e01e         	b	0x106f4 <PT_LOAD#2+0x106f4> @ imm = #0x3c
   106b6: b1e1         	cbz	r1, 0x106f2 <PT_LOAD#2+0x106f2> @ imm = #0x38
   106b8: b5f0         	push	{r4, r5, r6, r7, lr}
   106ba: af03         	add	r7, sp, #0xc
   106bc: b081         	sub	sp, #0x4
   106be: 4b0e         	ldr	r3, [pc, #0x38]         @ 0x106f8 <PT_LOAD#2+0x106f8>
   106c0: 460a         	mov	r2, r1
   106c2: f8df c038    	ldr.w	r12, [pc, #0x38]        @ 0x106fc <PT_LOAD#2+0x106fc>
   106c6: 447b         	add	r3, pc
   106c8: 6019         	str	r1, [r3]
   106ca: 44fc         	add	r12, pc
   106cc: e8bc 4038    	ldm.w	r12!, {r3, r4, r5, lr}
   106d0: e8a2 4038    	stm.w	r2!, {r3, r4, r5, lr}
   106d4: e8bc 4038    	ldm.w	r12!, {r3, r4, r5, lr}
   106d8: e8a2 4038    	stm.w	r2!, {r3, r4, r5, lr}
   106dc: e89c 4078    	ldm.w	r12, {r3, r4, r5, r6, lr}
   106e0: e882 4078    	stm.w	r2, {r3, r4, r5, r6, lr}
   106e4: f000 fe02    	bl	0x112ec <PT_LOAD#2+0x112ec> @ imm = #0xc04
   106e8: 2200         	movs	r2, #0x0
   106ea: b001         	add	sp, #0x4
   106ec: e8bd 40f0    	pop.w	{r4, r5, r6, r7, lr}
   106f0: e000         	b	0x106f4 <PT_LOAD#2+0x106f4> @ imm = #0x0
   106f2: 3206         	adds	r2, #0x6
   106f4: 4610         	mov	r0, r2
   106f6: 4770         	bx	lr
   106f8: dda2         	ble	0x10640 <PT_LOAD#2+0x10640> @ imm = #-0xbc
   106fa: 002b         	movs	r3, r5
   106fc: 3faa         	subs	r7, #0xaa
   106fe: 0007         	movs	r7, r0
