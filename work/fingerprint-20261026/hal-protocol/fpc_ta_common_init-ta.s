
work/fingerprint-20261026/fpctzapp-reconstructed.elf:	file format elf32-littlearm

Disassembly of section PT_LOAD#2:

00000000 <PT_LOAD#2>:
     254: b5f0         	push	{r4, r5, r6, r7, lr}
     256: af03         	add	r7, sp, #0xc
     258: f84d 8d04    	str	r8, [sp, #-4]!
     25c: b082         	sub	sp, #0x8
     25e: f010 fa1b    	bl	0x10698 ; fpc_common_get_info_size <PT_LOAD#2+0x10698> @ imm = #0x10436
     262: 4604         	mov	r4, r0
     264: 9401         	str	r4, [sp, #0x4]
     266: f000 fd15    	bl	0xc94 ; fpc_sensor_get_handle <PT_LOAD#2+0xc94> @ imm = #0xa2a
     26a: 4605         	mov	r5, r0
     26c: 4620         	mov	r0, r4
     26e: f005 fb57    	bl	0x5920 <PT_LOAD#2+0x5920> @ imm = #0x56ae
     272: f8df 807c    	ldr.w	r8, [pc, #0x7c]         @ 0x2f0 <PT_LOAD#2+0x2f0>
     276: f248 047b    	movw	r4, #0x807b
     27a: 4601         	mov	r1, r0
     27c: f6ce 0490    	movt	r4, #0xe890
     280: 44f8         	add	r8, pc
     282: 2900         	cmp	r1, #0x0
     284: f8c8 1000    	str.w	r1, [r8]
     288: d02c         	beq	0x2e4 <PT_LOAD#2+0x2e4> @ imm = #0x58
     28a: aa01         	add	r2, sp, #0x4
     28c: 4628         	mov	r0, r5
     28e: f010 fa05    	bl	0x1069c ; fpc_common_init <PT_LOAD#2+0x1069c> @ imm = #0x1040a
     292: 4606         	mov	r6, r0
     294: f1b6 3fff    	cmp.w	r6, #0xffffffff
     298: dd15         	ble	0x2c6 <PT_LOAD#2+0x2c6> @ imm = #0x2a
     29a: f010 fa31    	bl	0x10700 ; fpc_common_get_image_size <PT_LOAD#2+0x10700> @ imm = #0x10462
     29e: 4606         	mov	r6, r0
     2a0: f005 fb3e    	bl	0x5920 <PT_LOAD#2+0x5920> @ imm = #0x567c
     2a4: 4601         	mov	r1, r0
     2a6: b1a9         	cbz	r1, 0x2d4 <PT_LOAD#2+0x2d4> @ imm = #0x2a
     2a8: 4628         	mov	r0, r5
     2aa: 4632         	mov	r2, r6
     2ac: f010 fa30    	bl	0x10710 ; fpc_common_init_default_image <PT_LOAD#2+0x10710> @ imm = #0x10460
     2b0: 4910         	ldr	r1, [pc, #0x40]         @ 0x2f4 <PT_LOAD#2+0x2f4>
     2b2: 2400         	movs	r4, #0x0
     2b4: f04f 32ff    	mov.w	r2, #0xffffffff
     2b8: 4479         	add	r1, pc
     2ba: e9c1 2200    	strd	r2, r2, [r1]
     2be: 6088         	str	r0, [r1, #0x8]
     2c0: 730c         	strb	r4, [r1, #0xc]
     2c2: 610c         	str	r4, [r1, #0x10]
     2c4: e00e         	b	0x2e4 <PT_LOAD#2+0x2e4> @ imm = #0x1c
     2c6: f8d8 0000    	ldr.w	r0, [r8]
     2ca: f005 fb2d    	bl	0x5928 <PT_LOAD#2+0x5928> @ imm = #0x565a
     2ce: 2000         	movs	r0, #0x0
     2d0: 4634         	mov	r4, r6
     2d2: e005         	b	0x2e0 <PT_LOAD#2+0x2e0> @ imm = #0xa
     2d4: f8d8 0000    	ldr.w	r0, [r8]
     2d8: f005 fb26    	bl	0x5928 <PT_LOAD#2+0x5928> @ imm = #0x564c
     2dc: 2000         	movs	r0, #0x0
     2de: 3411         	adds	r4, #0x11
     2e0: f8c8 0000    	str.w	r0, [r8]
     2e4: 4620         	mov	r0, r4
     2e6: b002         	add	sp, #0x8
     2e8: f85d 8b04    	ldr	r8, [sp], #4
     2ec: bdf0         	pop	{r4, r5, r6, r7, pc}
     2ee: bf00         	nop
     2f0: 8764         	strh	r4, [r4, #0x3a]
     2f2: 0011         	movs	r1, r2
     2f4: 8714         	strh	r4, [r2, #0x38]
     2f6: 0011         	movs	r1, r2
