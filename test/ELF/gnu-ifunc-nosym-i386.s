// RUN: llvm-mc -filetype=obj -triple=i686-pc-linux %s -o %t.o
// RUN: ld.lld -static %t.o -o %tout
// RUN: llvm-readobj -symbols %tout | FileCheck %s
// REQUIRES: x86

// Check that no __rel_iplt_end/__rel_iplt_start
// appear in symtab if there is no references to them.
// CHECK:      Symbols [
// CHECK-NEXT-NOT: __rel_iplt_end
// CHECK-NEXT-NOT: __rel_iplt_start
// CHECK: ]

.text
.type foo STT_GNU_IFUNC
.globl foo
.type foo, @function
foo:
 ret

.type bar STT_GNU_IFUNC
.globl bar
.type bar, @function
bar:
 ret

.globl _start
_start:
 call foo
 call bar
