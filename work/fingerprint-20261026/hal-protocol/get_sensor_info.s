
work/fingerprint-20261026/android-live-readonly/programs/fingerprint-service-fpc:	file format elf64-littleaarch64

Disassembly of section .text:

0000000000014d68 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_>:
   1aff8: a9be7bfd     	stp	x29, x30, [sp, #-0x20]!
   1affc: a9014ff4     	stp	x20, x19, [sp, #0x10]
   1b000: 910003fd     	mov	x29, sp
   1b004: f0ffff62     	adrp	x2, 0xa000
   1b008: b0ffff83     	adrp	x3, 0xc000
   1b00c: aa0103f4     	mov	x20, x1
   1b010: aa0003f3     	mov	x19, x0
   1b014: 9103e042     	add	x2, x2, #0xf8
   1b018: 911d4863     	add	x3, x3, #0x752
   1b01c: 52800060     	mov	w0, #0x3                // =3
   1b020: aa1f03e1     	mov	x1, xzr
   1b024: 94002d63     	bl	0x265b0 <__android_log_print@plt>
   1b028: f9413668     	ldr	x8, [x19, #0x268]
   1b02c: 91008100     	add	x0, x8, #0x20
   1b030: 94002e70     	bl	0x269f0 <pthread_mutex_lock@plt>
   1b034: f9413660     	ldr	x0, [x19, #0x268]
   1b038: 97ffeca5     	bl	0x162cc ; fingerprint_hal_goto_idle <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x1564>
   1b03c: f9413668     	ldr	x8, [x19, #0x268]
   1b040: aa1403e1     	mov	x1, x20
   1b044: f9403d00     	ldr	x0, [x8, #0x78]
   1b048: 94001bec     	bl	0x21ff8 ; fpc_tee_get_sensor_otp_info <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0xd290>
   1b04c: 2a0003f4     	mov	w20, w0
   1b050: 34000120     	cbz	w0, 0x1b074 <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x630c>
   1b054: f0ffff62     	adrp	x2, 0xa000
   1b058: b0ffff83     	adrp	x3, 0xc000
   1b05c: 91358042     	add	x2, x2, #0xd60
   1b060: 911d4863     	add	x3, x3, #0x752
   1b064: 528000c0     	mov	w0, #0x6                // =6
   1b068: aa1f03e1     	mov	x1, xzr
   1b06c: 2a1403e4     	mov	w4, w20
   1b070: 94002d50     	bl	0x265b0 <__android_log_print@plt>
   1b074: f9413660     	ldr	x0, [x19, #0x268]
   1b078: 97ffecb5     	bl	0x1634c ; fingerprint_hal_resume <_ZNSt3__17getlineIcNS_11char_traitsIcEENS_9allocatorIcEEEERNS_13basic_istreamIT_T0_EES9_RNS_12basic_stringIS6_S7_T1_EES6_+0x15e4>
   1b07c: f9413668     	ldr	x8, [x19, #0x268]
   1b080: 91008100     	add	x0, x8, #0x20
   1b084: 94002e5f     	bl	0x26a00 <pthread_mutex_unlock@plt>
   1b088: 2a1403e0     	mov	w0, w20
   1b08c: a9414ff4     	ldp	x20, x19, [sp, #0x10]
   1b090: a8c27bfd     	ldp	x29, x30, [sp], #0x20
   1b094: d65f03c0     	ret
