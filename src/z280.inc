; Include file with constants related to the Z280 CPU


    module Z280.CONTROL_REGISTERS

MSR: equ 00h
INTERRUPT_STATUS: equ 16h
INT_TRAP_VECTOR_POINTER: equ 06h
IO_PAGE: equ 08h
BUS_TIMING_INIT: equ 0FFh
BUS_TIMING_CONTROL: equ 02h
STACK_LIMIT: equ 04h
TRAP_CONTROL: equ 10h
CACHE_CONTROL: equ 12h
LOCAL_ADDRESS: equ 14h

    endmod


    module Z280.MMU_PORTS

    ;I/O page register must be FFh

MASTER_CONTROL: equ 0F0h
PAGE_DESCRIPTOR: equ 0F1h
DESCRIPTOR_SELECT: equ 0F5h
BLOCK_MOVE: equ 0F4h
INVALIDATION: equ 0F2h

    endmod
