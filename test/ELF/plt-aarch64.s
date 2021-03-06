// RUN: llvm-mc -filetype=obj -triple=aarch64-pc-freebsd %s -o %t.o
// RUN: llvm-mc -filetype=obj -triple=aarch64-pc-freebsd %p/Inputs/shared.s -o %t2.o
// RUN: ld.lld -shared %t2.o -o %t2.so
// RUN: ld.lld -shared %t.o %t2.so -o %t.so
// RUN: ld.lld %t.o %t2.so -o %t.exe
// RUN: llvm-readobj -s -r %t.so | FileCheck --check-prefix=CHECKDSO %s
// RUN: llvm-objdump -s -section=.got.plt %t.so | FileCheck --check-prefix=DUMPDSO %s
// RUN: llvm-objdump -d %t.so | FileCheck --check-prefix=DISASMDSO %s
// RUN: llvm-readobj -s -r %t.exe | FileCheck --check-prefix=CHECKEXE %s
// RUN: llvm-objdump -s -section=.got.plt %t.exe | FileCheck --check-prefix=DUMPEXE %s
// RUN: llvm-objdump -d %t.exe | FileCheck --check-prefix=DISASMEXE %s

// REQUIRES: aarch64

// CHECKDSO:     Name: .plt
// CHECKDSO-NEXT:     Type: SHT_PROGBITS
// CHECKDSO-NEXT:     Flags [
// CHECKDSO-NEXT:       SHF_ALLOC
// CHECKDSO-NEXT:       SHF_EXECINSTR
// CHECKDSO-NEXT:     ]
// CHECKDSO-NEXT:     Address: 0x1010
// CHECKDSO-NEXT:     Offset:
// CHECKDSO-NEXT:     Size: 80
// CHECKDSO-NEXT:     Link:
// CHECKDSO-NEXT:     Info:
// CHECKDSO-NEXT:     AddressAlignment: 16

// CHECKDSO:     Name: .got.plt
// CHECKDSO-NEXT:     Type: SHT_PROGBITS
// CHECKDSO-NEXT:     Flags [
// CHECKDSO-NEXT:       SHF_ALLOC
// CHECKDSO-NEXT:       SHF_WRITE
// CHECKDSO-NEXT:     ]
// CHECKDSO-NEXT:     Address: 0x3000
// CHECKDSO-NEXT:     Offset:
// CHECKDSO-NEXT:     Size: 48
// CHECKDSO-NEXT:     Link:
// CHECKDSO-NEXT:     Info:
// CHECKDSO-NEXT:     AddressAlignment: 8

// CHECKDSO: Relocations [
// CHECKDSO-NEXT:   Section ({{.*}}) .rela.plt {

// &(.got.plt[3]) = 0x3000 + 3 * 8 = 0x3018
// CHECKDSO-NEXT:     0x3018 R_AARCH64_JUMP_SLOT foo

// &(.got.plt[4]) = 0x3000 + 4 * 8 = 0x3020
// CHECKDSO-NEXT:     0x3020 R_AARCH64_JUMP_SLOT bar

// &(.got.plt[5]) = 0x3000 + 5 * 8 = 0x3028
// CHECKDSO-NEXT:     0x3028 R_AARCH64_JUMP_SLOT weak
// CHECKDSO-NEXT:   }
// CHECKDSO-NEXT: ]

// DUMPDSO: Contents of section .got.plt:
// .got.plt[0..2] = 0 (reserved)
// .got.plt[3..5] = .plt = 0x1010
// DUMPDSO-NEXT:  3000 00000000 00000000 00000000 00000000  ................
// DUMPDSO-NEXT:  3010 00000000 00000000 10100000 00000000  ................
// DUMPDSO-NEXT:  3020 10100000 00000000 10100000 00000000  ................

// DISASMDSO: _start:
// 0x1030 - 0x1000 = 0x30 = 48
// DISASMDSO-NEXT:     1000:	0c 00 00 14 	b	#48
// 0x1040 - 0x1004 = 0x3c = 60
// DISASMDSO-NEXT:     1004:	0f 00 00 14 	b	#60
// 0x1050 - 0x1008 = 0x48 = 72
// DISASMDSO-NEXT:     1008:	12 00 00 14 	b	#72

// DISASMDSO: foo:
// DISASMDSO-NEXT:     100c:	1f 20 03 d5 	nop

// DISASMDSO: Disassembly of section .plt:
// DISASMDSO-NEXT: .plt:
// DISASMDSO-NEXT:     1010:	f0 7b bf a9 	stp	x16, x30, [sp, #-16]!
// &(.got.plt[2]) = 0x3000 + 2 * 8 = 0x3010
// Page(0x3010) - Page(0x1014) = 0x3000 - 0x1000 = 0x2000 = 8192
// DISASMDSO-NEXT:     1014:	10 00 00 d0 	adrp	x16, #8192
// 0x3010 & 0xFFF = 0x10 = 16
// DISASMDSO-NEXT:     1018:	11 0a 40 f9 ldr x17, [x16, #16]
// DISASMDSO-NEXT:     101c:	10 42 00 91 	add	x16, x16, #16
// DISASMDSO-NEXT:     1020:	20 02 1f d6 	br	x17
// DISASMDSO-NEXT:     1024:	1f 20 03 d5 	nop
// DISASMDSO-NEXT:     1028:	1f 20 03 d5 	nop
// DISASMDSO-NEXT:     102c:	1f 20 03 d5 	nop

// foo@plt
// Page(0x3018) - Page(0x1030) = 0x3000 - 0x1000 = 0x2000 = 8192
// DISASMDSO-NEXT:     1030:	10 00 00 d0 	adrp	x16, #8192
// 0x3018 & 0xFFF = 0x18 = 24
// DISASMDSO-NEXT:     1034:	11 0e 40 f9 	ldr	x17, [x16, #24]
// DISASMDSO-NEXT:     1038:	10 62 00 91 	add	x16, x16, #24
// DISASMDSO-NEXT:     103c:	20 02 1f d6 	br	x17

// bar@plt
// Page(0x3020) - Page(0x1040) = 0x3000 - 0x1000 = 0x2000 = 8192
// DISASMDSO-NEXT:     1040:	10 00 00 d0 	adrp	x16, #8192
// 0x3020 & 0xFFF = 0x20 = 32
// DISASMDSO-NEXT:     1044:	11 12 40 f9 	ldr	x17, [x16, #32]
// DISASMDSO-NEXT:     1048:	10 82 00 91 	add	x16, x16, #32
// DISASMDSO-NEXT:     104c:	20 02 1f d6 	br	x17

// weak@plt
// Page(0x3028) - Page(0x1050) = 0x3000 - 0x1000 = 0x2000 = 8192
// DISASMDSO-NEXT:     1050:	10 00 00 d0 	adrp	x16, #8192
// 0x3028 & 0xFFF = 0x28 = 40
// DISASMDSO-NEXT:     1054:	11 16 40 f9 	ldr	x17, [x16, #40]
// DISASMDSO-NEXT:     1058:	10 a2 00 91 	add	x16, x16, #40
// DISASMDSO-NEXT:     105c:	20 02 1f d6 	br	x17

// CHECKEXE:     Name: .plt
// CHECKEXE-NEXT:     Type: SHT_PROGBITS
// CHECKEXE-NEXT:     Flags [
// CHECKEXE-NEXT:       SHF_ALLOC
// CHECKEXE-NEXT:       SHF_EXECINSTR
// CHECKEXE-NEXT:     ]
// CHECKEXE-NEXT:     Address: 0x11010
// CHECKEXE-NEXT:     Offset:
// CHECKEXE-NEXT:     Size: 64
// CHECKEXE-NEXT:     Link:
// CHECKEXE-NEXT:     Info:
// CHECKEXE-NEXT:     AddressAlignment: 16

// CHECKEXE:     Name: .got.plt
// CHECKEXE-NEXT:     Type: SHT_PROGBITS
// CHECKEXE-NEXT:     Flags [
// CHECKEXE-NEXT:       SHF_ALLOC
// CHECKEXE-NEXT:       SHF_WRITE
// CHECKEXE-NEXT:     ]
// CHECKEXE-NEXT:     Address: 0x13000
// CHECKEXE-NEXT:     Offset:
// CHECKEXE-NEXT:     Size: 40
// CHECKEXE-NEXT:     Link:
// CHECKEXE-NEXT:     Info:
// CHECKEXE-NEXT:     AddressAlignment: 8

// CHECKEXE: Relocations [
// CHECKEXE-NEXT:   Section ({{.*}}) .rela.plt {

// &(.got.plt[3]) = 0x13000 + 3 * 8 = 0x13018
// CHECKEXE-NEXT:     0x13018 R_AARCH64_JUMP_SLOT bar 0x0

// &(.got.plt[4]) = 0x13000 + 4 * 8 = 0x13020
// CHECKEXE-NEXT:     0x13020 R_AARCH64_JUMP_SLOT weak 0x0
// CHECKEXE-NEXT:   }
// CHECKEXE-NEXT: ]

// DUMPEXE: Contents of section .got.plt:
// .got.plt[0..2] = 0 (reserved)
// .got.plt[3..4] = .plt = 0x11010
// DUMPEXE-NEXT:  13000 00000000 00000000 00000000 00000000  ................
// DUMPEXE-NEXT:  13010 00000000 00000000 10100100 00000000  ................
// DUMPEXE-NEXT:  13020 10100100 00000000                    ........

// DISASMEXE: _start:
// 0x1100c - 0x11000 = 0xc = 12
// DISASMEXE-NEXT:    11000:	03 00 00 14 	b	#12
// 0x11030 - 0x11004 = 0x2c = 44
// DISASMEXE-NEXT:    11004:	0b 00 00 14 	b	#44
// 0x11040 - 0x11008 = 0x38 = 56
// DISASMEXE-NEXT:    11008:	0e 00 00 14 	b	#56

// DISASMEXE: foo:
// DISASMEXE-NEXT:    1100c:	1f 20 03 d5 	nop

// DISASMEXE: Disassembly of section .plt:
// DISASMEXE-NEXT: .plt:
// DISASMEXE-NEXT:    11010:	f0 7b bf a9 	stp	x16, x30, [sp, #-16]!
// &(.got.plt[2]) = 0x120B0 + 2 * 8 = 0x120C0
// Page(0x13010) - Page(0x11014) = 0x13000 - 0x11000 = 0x1000 = 8192
// DISASMEXE-NEXT:    11014:	10 00 00 d0  	adrp	x16, #8192
// 0x120c0 & 0xFFF = 0xC0 = 192
// DISASMEXE-NEXT:    11018:	11 0a 40 f9 	ldr	x17, [x16, #16]
// DISASMEXE-NEXT:    1101c:	10 42 00 91 	add	x16, x16, #16
// DISASMEXE-NEXT:    11020:	20 02 1f d6 	br	x17
// DISASMEXE-NEXT:    11024:	1f 20 03 d5 	nop
// DISASMEXE-NEXT:    11028:	1f 20 03 d5 	nop
// DISASMEXE-NEXT:    1102c:	1f 20 03 d5 	nop

// bar@plt
// Page(0x13018) - Page(0x11030) = 0x12000 - 0x11000 = 0x1000 = 8192
// DISASMEXE-NEXT:    11030:	10 00 00 d0 	adrp	x16, #8192
// 0x120C8 & 0xFFF = 0xC8 = 200
// DISASMEXE-NEXT:    11034:	11 0e 40 f9 	ldr	x17, [x16, #24]
// DISASMEXE-NEXT:    11038:	10 62 00 91 	add	x16, x16, #24
// DISASMEXE-NEXT:    1103c:	20 02 1f d6 	br	x17

// weak@plt
// Page(0x13020) - Page(0x11040) = 0x12000 - 0x11000 = 0x1000 = 8192
// DISASMEXE-NEXT:    11040:	10 00 00 d0 	adrp	x16, #8192
// 0x120D0 & 0xFFF = 0xD0 = 208
// DISASMEXE-NEXT:    11044:	11 12 40 f9 	ldr	x17, [x16, #32]
// DISASMEXE-NEXT:    11048:	10 82 00 91 	add	x16, x16, #32
// DISASMEXE-NEXT:    1104c:	20 02 1f d6 	br	x17

.global _start,foo,bar
.weak weak
_start:
  b foo
  b bar
  b weak

.section .text2,"ax",@progbits
foo:
  nop
