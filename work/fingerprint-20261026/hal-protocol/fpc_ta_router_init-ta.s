
work/fingerprint-20261026/fpctzapp-reconstructed.elf:	file format elf32-littlearm

Disassembly of section PT_LOAD#2:

00000000 <PT_LOAD#2>:
     150: b5b0         	push	{r4, r5, r7, lr}
     152: af02         	add	r7, sp, #0x8
     154: 4c09         	ldr	r4, [pc, #0x24]         @ 0x17c <PT_LOAD#2+0x17c>
     156: 2500         	movs	r5, #0x0
     158: 447c         	add	r4, pc
     15a: f854 0b04    	ldr	r0, [r4], #4
     15e: 6800         	ldr	r0, [r0]
     160: b118         	cbz	r0, 0x16a <PT_LOAD#2+0x16a> @ imm = #0x6
     162: 4780         	blx	r0
     164: 2800         	cmp	r0, #0x0
     166: bf18         	it	ne
     168: bdb0         	popne	{r4, r5, r7, pc}
     16a: 3501         	adds	r5, #0x1
     16c: 2d08         	cmp	r5, #0x8
     16e: d3f4         	blo	0x15a <PT_LOAD#2+0x15a> @ imm = #-0x18
     170: 4803         	ldr	r0, [pc, #0xc]          @ 0x180 <PT_LOAD#2+0x180>
     172: 2101         	movs	r1, #0x1
     174: 4478         	add	r0, pc
     176: 7001         	strb	r1, [r0]
     178: 2000         	movs	r0, #0x0
     17a: bdb0         	pop	{r4, r5, r7, pc}
     17c: 5ea4         	ldrsh	r4, [r4, r2]
     17e: 0011         	movs	r1, r2
     180: 8850         	ldrh	r0, [r2, #0x2]
     182: 0011         	movs	r1, r2
