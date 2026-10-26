
work/fingerprint-20261026/fpctzapp-reconstructed.elf:	file format elf32-littlearm

Disassembly of section PT_LOAD#2:

00000000 <PT_LOAD#2>:
   10764: 4a03         	ldr	r2, [pc, #0xc]          @ 0x10774 <PT_LOAD#2+0x10774>
   10766: 447a         	add	r2, pc
   10768: 6812         	ldr	r2, [r2]
   1076a: 7a13         	ldrb	r3, [r2, #0x8]
   1076c: 7003         	strb	r3, [r0]
   1076e: 7a90         	ldrb	r0, [r2, #0xa]
   10770: 7008         	strb	r0, [r1]
   10772: 4770         	bx	lr
   10774: dd02         	ble	0x1077c <PT_LOAD#2+0x1077c> @ imm = #0x4
   10776: 002b         	movs	r3, r5
