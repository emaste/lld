# REQUIRES: aarch64
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %p/Inputs/aarch64-tls-ie.s -o %ttlsie.o
# RUN: llvm-mc -filetype=obj -triple=aarch64-unknown-linux %s -o %tmain.o
# RUN: ld.lld -shared %ttlsie.o -o %t.so
# RUN: ld.lld %tmain.o -o %tout %t.so
# RUN: llvm-objdump -d %tout | FileCheck %s
# RUN: llvm-readobj -s -r %tout | FileCheck -check-prefix=RELOC %s

# Global-Dynamic to Initial-Exec relax creates a R_AARCH64_TPREL64
# RELOC:      Relocations [
# RELOC-NEXT:   Section ({{.*}}) .rela.dyn {
# RELOC-NEXT:    {{.*}} R_AARCH64_TLS_TPREL64 foo 0x0
# RELOC-NEXT:   }
# RELOC-NEXT: ]

# CHECK: Disassembly of section .text:
# CHECK: _start:
# CHECK:  11000:	00 00 00 b0	adrp    x0, #4096
# CHECK:  11004:	00 58 40 f9 	ldr     x0, [x0, #176]
# CHECK:  11008:	1f 20 03 d5 	nop
# CHECK:  1100c:	1f 20 03 d5 	nop

.text
.globl _start
_start:
 adrp    x0, :tlsdesc:foo
 ldr     x1, [x0, :tlsdesc_lo12:foo]
 add     x0, x0, :tlsdesc_lo12:foo
 .tlsdesccall foo
 blr     x1
