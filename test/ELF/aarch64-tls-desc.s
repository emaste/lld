# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-freebsd %s -o %tmain.o
# RUN: ld.lld %tmain.o -shared -o %tout
# RUN: llvm-objdump -d %tout | FileCheck %s
# RUN: llvm-readobj -s -r -dynamic-table %tout | FileCheck -check-prefix=READOBJ %s
# REQUIRES: aarch64

#READOBJ:      Section {
#READOBJ:       Index:
#READOBJ:       Name: .plt
#READOBJ-NEXT:   Type: SHT_PROGBITS
#READOBJ-NEXT:   Flags [
#READOBJ-NEXT:     SHF_ALLOC
#READOBJ-NEXT:     SHF_EXECINSTR
#READOBJ-NEXT:   ]
#READOBJ-NEXT:   Address: 0x1030
#READOBJ-NEXT:   Offset:
#READOBJ-NEXT:   Size: 80
#READOBJ-NEXT:   Link:
#READOBJ-NEXT:   Info:
#READOBJ-NEXT:   AddressAlignment:
#READOBJ-NEXT:   EntrySize:
#READOBJ-NEXT: }
#READOBJ:      Section {
#READOBJ:       Index:
#READOBJ:       Name: .got
#READOBJ-NEXT:     Type: SHT_PROGBITS
#READOBJ-NEXT:     Flags [
#READOBJ-NEXT:       SHF_ALLOC
#READOBJ-NEXT:       SHF_WRITE
#READOBJ-NEXT:     ]
#READOBJ-NEXT:   Address: 0x20C8
#READOBJ-NEXT:   Offset:
#READOBJ-NEXT:   Size: 8
#READOBJ-NEXT:   Link:
#READOBJ-NEXT:   Info:
#READOBJ-NEXT:   AddressAlignment:
#READOBJ-NEXT:   EntrySize:
#READOBJ-NEXT: }
#READOBJ:      Section {
#READOBJ:       Index:
#READOBJ:       Name: .got.plt
#READOBJ-NEXT:   Type: SHT_PROGBITS
#READOBJ-NEXT:   Flags [
#READOBJ-NEXT:     SHF_ALLOC
#READOBJ-NEXT:     SHF_WRITE
#READOBJ-NEXT:   ]
#READOBJ-NEXT:   Address: 0x3000
#READOBJ-NEXT:   Offset: 0x3000
#READOBJ-NEXT:   Size: 64
#READOBJ-NEXT:   Link: 0
#READOBJ-NEXT:   Info: 0
#READOBJ-NEXT:   AddressAlignment: 8
#READOBJ-NEXT:   EntrySize: 0
#READOBJ-NEXT: }
#READOBJ:      Relocations [
#READOBJ-NEXT:  Section ({{.*}}) .rela.plt {
## This also checks that SLOT relocations are placed vefore TLSDESC
## 0x3018 = .got.plt + 0x18 (reserved 3 entries)
## 0x3020 = next entry (first was single, 8 bytes)
## 0x3030 = 0x3018 + double entry size (16)
#READOBJ-NEXT:    0x3018 R_AARCH64_JUMP_SLOT slot 0x0
#READOBJ-NEXT:    0x3020 R_AARCH64_TLSDESC foo 0x0
#READOBJ-NEXT:    0x3030 R_AARCH64_TLSDESC bar 0x0
#READOBJ-NEXT:  }
#READOBJ-NEXT:]
#READOBJ:       DynamicSection [
#READOBJ-NEXT:    Tag                Type                 Name/Value
#READOBJ-NEXT:    0x0000000000000017 JMPREL               0x2C0
#READOBJ-NEXT:    0x0000000000000002 PLTRELSZ             72 (bytes)
#READOBJ-NEXT:    0x0000000000000003 PLTGOT               0x3000
#READOBJ-NEXT:    0x0000000000000014 PLTREL               RELA
## 0x20A8 = Location of GOT entry used by TLS descriptor resolver PLT entry
#READOBJ-NEXT:    0x000000006FFFFEF7 TLSDESC_GOT          0x20C8
## 0x1040 = Location of PLT entry for TLS descriptor resolver calls.
#READOBJ-NEXT:    0x000000006FFFFEF6 TLSDESC_PLT          0x1060
#READOBJ-NEXT:    0x0000000000000006 SYMTAB               0x200
#READOBJ-NEXT:    0x000000000000000B SYMENT               24 (bytes)
#READOBJ-NEXT:    0x0000000000000005 STRTAB               0x2A8
#READOBJ-NEXT:    0x000000000000000A STRSZ                21 (bytes)
#READOBJ-NEXT:    0x0000000000000004 HASH                 0x278
#READOBJ-NEXT:    0x0000000000000000 NULL                 0x0
#READOBJ-NEXT:  ]

#CHECK:      Disassembly of section .text:
#CHECK-NEXT: _start:
#CHECK-NEXT: 1000:	80 02 00 54 	b.eq	#80
#CHECK-NEXT: 1004:	00 00 00 d0 	adrp	x0, #8192
## Page(.got.plt[N]) - Page(0x1000) = Page(0x3020) - 0x1000 =
##   0x3000 - 0x1000 = 0x2000 = 8192
## 0x20 = 32
#CHECK-NEXT: 1008:	02 10 40 f9 	ldr	x2, [x0, #32]
#CHECK-NEXT: 100c:	00 80 00 91 	add	x0, x0, #32
#CHECK-NEXT: 1010:	40 00 3f d6 	blr	x2
## Page(.got.plt[N]) - Page(0x1000) = Page(0x3030) - 0x1000 =
##   0x3000 - 0x1000 = 0x2000 = 8192
## 0x30 = 48
#CHECK-NEXT: 1014:	00 00 00 d0 	adrp	x0, #8192
#CHECK-NEXT: 1018:	02 18 40 f9 	ldr	x2, [x0, #48]
#CHECK-NEXT: 101c:	00 c0 00 91 	add	x0, x0, #48
#CHECK-NEXT: 1020:	40 00 3f d6 	blr	x2
#CHECK-NEXT: Disassembly of section .plt:
#CHECK-NEXT: .plt:
#CHECK-NEXT:  1030:	f0 7b bf a9 	stp	x16, x30, [sp, #-16]!
#CHECK-NEXT:  1034:	10 00 00 d0 	adrp	x16, #8192
#CHECK-NEXT:  1038:	11 0a 40 f9 	ldr	x17, [x16, #16]
#CHECK-NEXT:  103c:	10 42 00 91 	add	x16, x16, #16
#CHECK-NEXT:  1040:	20 02 1f d6 	br	x17
#CHECK-NEXT:  1044:	1f 20 03 d5 	nop
#CHECK-NEXT:  1048:	1f 20 03 d5 	nop
#CHECK-NEXT:  104c:	1f 20 03 d5 	nop
#CHECK-NEXT:  1050:	10 00 00 d0 	adrp	x16, #8192
#CHECK-NEXT:  1054:	11 0e 40 f9 	ldr	x17, [x16, #24]
#CHECK-NEXT:  1058:	10 62 00 91 	add	x16, x16, #24
#CHECK-NEXT:  105c:	20 02 1f d6 	br	x17
## Page(.got[N]) - Page(P) = Page(0x20C8) - Page(0x1044) =
##  0x2000 - 0x1000 = 4096
## Page(.got.plt) - Page(P) = Page(0x3000) - Page(0x1048) =
##  0x3000 - 0x1000 = 8192
## 0xC8 = 200
## 0x0 = 0
#CHECK-NEXT:  1060: {{.*}} stp  x2, x3, [sp, #-16]!
#CHECK-NEXT:  1064: {{.*}} adrp x2, #4096
#CHECK-NEXT:  1068: {{.*}} adrp x3, #8192
#CHECK-NEXT:  106c: {{.*}} ldr  x2, [x2, #200]
#CHECK-NEXT:  1070: {{.*}} add  x3, x3, #0
#CHECK-NEXT:  1074: {{.*}} br   x2
#CHECK-NEXT:  1078: {{.*}} nop
#CHECK-NEXT:  107c: {{.*}} nop

.text
 .global foo
 .section .tdata,"awT",%progbits
 .align 2
 .type foo, %object
 .size foo, 4
foo:
 .word 5
 .text

.text
 .global bar
 .section .tdata,"awT",%progbits
 .align 2
 .type bar, %object
 .size bar, 4
bar:
 .word 5
 .text

.globl _start
_start:
 b.eq slot

 adrp x0, :tlsdesc:foo
 ldr x2, [x0, #:tlsdesc_lo12:foo]
 add x0, x0, :tlsdesc_lo12:foo
 .tlsdesccall foo
 blr x2

 adrp x0, :tlsdesc:bar
 ldr x2, [x0, #:tlsdesc_lo12:bar]
 add x0, x0, :tlsdesc_lo12:bar
 .tlsdesccall bar
 blr x2
