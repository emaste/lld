# RUN: llvm-mc -filetype=obj -triple=x86_64-unknown-freebsd %s -o %t
# RUN: ld.lld %t -o %t2
# RUN: llvm-readobj -sections -program-headers %t2 | FileCheck --check-prefix=DEFAULT %s
# RUN: ld.lld -Ttext 0x60000 %t -o %t2
# RUN: llvm-readobj -sections -program-headers %t2 | FileCheck --check-prefix=TTEXT %s
# RUN: ld.lld -Ttext 0x800000 %t -o %t2
# RUN: llvm-readobj -sections -program-headers %t2 | FileCheck --check-prefix=TTEXT-SEGMENT %s
# REQUIRES: x86

# Check that -Ttext and -Ttext-segment set the text segment start address

.section .text,"a"
.globl _start
_start:
.quad 0

.section .data,"aw"
.quad 1

.section .bss,"aw"
.quad 0

# DEFAULT:      ProgramHeaders [
# DEFAULT-NEXT:   ProgramHeader {
# DEFAULT-NEXT:     Type: PT_PHDR (0x6)
# DEFAULT-NEXT:     Offset: 0x40
# DEFAULT-NEXT:     VirtualAddress: 0x10040
# DEFAULT-NEXT:     PhysicalAddress: 0x10040
# DEFAULT-NEXT:     FileSize: 280
# DEFAULT-NEXT:     MemSize: 280
# DEFAULT-NEXT:     Flags [ (0x4)
# DEFAULT-NEXT:       PF_R (0x4)
# DEFAULT-NEXT:     ]
# DEFAULT-NEXT:     Alignment: 8
# DEFAULT-NEXT:   }
# DEFAULT-NEXT:   ProgramHeader {
# DEFAULT-NEXT:     Type: PT_LOAD
# DEFAULT-NEXT:     Offset: 0x0
# DEFAULT-NEXT:     VirtualAddress: 0x10000
# DEFAULT-NEXT:     PhysicalAddress:
# DEFAULT-NEXT:     FileSize: 344
# DEFAULT-NEXT:     MemSize: 344
# DEFAULT-NEXT:     Flags [
# DEFAULT-NEXT:       PF_R
# DEFAULT-NEXT:     ]
# DEFAULT-NEXT:     Alignment:
# DEFAULT-NEXT:   }

# TTEXT:      ProgramHeaders [
# TTEXT-NEXT:   ProgramHeader {
# TTEXT-NEXT:     Type: PT_PHDR (0x6)
# TTEXT-NEXT:     Offset: 0x40
# TTEXT-NEXT:     VirtualAddress: 0x60040
# TTEXT-NEXT:     PhysicalAddress: 0x60040
# TTEXT-NEXT:     FileSize: 280
# TTEXT-NEXT:     MemSize: 280
# TTEXT-NEXT:     Flags [ (0x4)
# TTEXT-NEXT:       PF_R (0x4)
# TTEXT-NEXT:     ]
# TTEXT-NEXT:     Alignment: 8
# TTEXT-NEXT:   }
# TTEXT-NEXT:   ProgramHeader {
# TTEXT-NEXT:     Type: PT_LOAD
# TTEXT-NEXT:     Offset: 0x0
# TTEXT-NEXT:     VirtualAddress: 0x60000
# TTEXT-NEXT:     PhysicalAddress:
# TTEXT-NEXT:     FileSize: 344
# TTEXT-NEXT:     MemSize: 344
# TTEXT-NEXT:     Flags [
# TTEXT-NEXT:       PF_R
# TTEXT-NEXT:     ]
# TTEXT-NEXT:     Alignment:
# TTEXT-NEXT:   }

# TTEXT-SEGMENT:      ProgramHeaders [
# TTEXT-SEGMENT-NEXT:   ProgramHeader {
# TTEXT-SEGMENT-NEXT:     Type: PT_PHDR (0x6)
# TTEXT-SEGMENT-NEXT:     Offset: 0x40
# TTEXT-SEGMENT-NEXT:     VirtualAddress: 0x800040
# TTEXT-SEGMENT-NEXT:     PhysicalAddress: 0x800040
# TTEXT-SEGMENT-NEXT:     FileSize: 280
# TTEXT-SEGMENT-NEXT:     MemSize: 280
# TTEXT-SEGMENT-NEXT:     Flags [ (0x4)
# TTEXT-SEGMENT-NEXT:       PF_R (0x4)
# TTEXT-SEGMENT-NEXT:     ]
# TTEXT-SEGMENT-NEXT:     Alignment: 8
# TTEXT-SEGMENT-NEXT:   }
# TTEXT-SEGMENT-NEXT:   ProgramHeader {
# TTEXT-SEGMENT-NEXT:     Type: PT_LOAD
# TTEXT-SEGMENT-NEXT:     Offset: 0x0
# TTEXT-SEGMENT-NEXT:     VirtualAddress: 0x800000
# TTEXT-SEGMENT-NEXT:     PhysicalAddress:
# TTEXT-SEGMENT-NEXT:     FileSize: 344
# TTEXT-SEGMENT-NEXT:     MemSize: 344
# TTEXT-SEGMENT-NEXT:     Flags [
# TTEXT-SEGMENT-NEXT:       PF_R
# TTEXT-SEGMENT-NEXT:     ]
# TTEXT-SEGMENT-NEXT:     Alignment:
# TTEXT-SEGMENT-NEXT:   }

