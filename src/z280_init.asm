    extrn Z280.RESIDENT_CODE ;Assumed to be A000h
    extrn Z280.INT_TRAP_VECTOR

    module Z280

    ifndef Z280.USE_CACHE
USE_CACHE: equ 3 ;0 = no, 1 = data, 2 = instructions, 3 = both
    endif

    ifndef Z280.USE_IM3
USE_IM3: equ 1
    endif

    ifndef Z280.RESIDENT_CODE_START_ADDRESS
    ;Note that the Z280 RAM starts at address 010000,
    ;but the first 64K are for the BIOS shadowing
    ;so the first actual usable address is 020000.
RESIDENT_CODE_START_ADDRESS: equ 0200h ;Bits 23 to 12 (11 to 0 are always 0)
    endif

    include "z280.inc"

    .cpu Z280

    .extroot
    .relab

INIT:

    di

    ;--- Set the I/O page to FFh, the value used for all the Z280 internal ports

    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,0FFh
    ldctl (c),hl

    if USE_CACHE eq 0

    ;--- Disable the cache
    ;    (see Z280 Technical Manual, 3.2.4 and 8.3)

    ld c,Z280.CONTROL_REGISTERS.CACHE_CONTROL
    ld l,01000000b  ;Enable cache for data only
    ldctl (c),hl

    pcache

    ld b,16     ;Read 16 addresses separated 16 bytes, starting at C000h
    xor a
    ld h,0C0h
.CACHE_LOOP:
    ld l,a
    ld d,(hl)
    add 16
    djnz .CACHE_LOOP

    ld l,11100000b  ;Disable cache
    ldctl (c),hl

    endif

    ;--- Copy the resident code and configure the MMU

    ;Configure the MMU page descriptors so they match the MSX addressing space
    ;(so the Z280 addresses 000000-00FFFF are mapped to 0000-FFFF)
    ;for both user mode and system mode, with nothing being cacheable.

    xor a
    out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a

    ld bc,1000h + Z280.MMU_PORTS.BLOCK_MOVE
    ld hl,0
SET_MMU_LOOP_USER:
    outw (c),hl
    addw hl,0010h   ;Next 4K page
    djnz SET_MMU_LOOP_USER

    ld b,10h
    ld hl,0
SET_MMU_LOOP_SYSTEM:
    outw (c),hl
    addw hl,0010h   ;Next 4K page
    djnz SET_MMU_LOOP_SYSTEM

    ;Copy the Z280 resident code (including the interrupt/trap vectors table),
    ;which is located at addresses A000-BFFF in this ROM (second 8K half of page 2),
    ;into the Z280 RAM at address RESIDENT_CODE_START_ADDRESS.
    ;That code is intended to be mapped at A000-BFFF too when being used.
    ;
    ;We'll make the copy in two steps:
    ;1. Map RESIDENT_CODE_START_ADDRESS+1000h into A000-AFFF and copy the second half.
    ;2. Map RESIDENT_CODE_START_ADDRESS into B000-BFFF and copy the first half.
    ;
    ;See Z280 Technical Manual, chapter 7
    
    ld a,0A000h/1000h
    out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a
    ld hl,RESIDENT_CODE_START_ADDRESS + 0010h ;Map 021000 to A000
    outw (c),hl ;C is still BLOCK_MOVE, so this increases PAGE_DESCRIPTOR

    ld hl,Z280.RESIDENT_CODE+4000h
    ld de,0A000h
    ld bc,1000h
    ldir

    ld hl,RESIDENT_CODE_START_ADDRESS ;Map 020000 to B000
    outw (c),hl

    ld hl,Z280.RESIDENT_CODE
    ld de,0B000h
    ld bc,1000h
    ldir

    ;Now modify the mapping for system mode so that the resident code
    ;is mapped to A000-BFFF.

    ld a,0A000h/1000h
    out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a

    if USE_CACHE eq 0
    ld hl,RESIDENT_CODE_START_ADDRESS ;Map RESIDENT_CODE_START_ADDRESS to A000, not cacheable
    else
    ld hl,RESIDENT_CODE_START_ADDRESS + 2 ;Map RESIDENT_CODE_START_ADDRESS to A000, cacheable
    endif
    outw (c),hl ;C is still BLOCK_MOVE, so this increases PAGE_DESCRIPTOR
    inc h ;Map RESIDENT_CODE_START_ADDRESS+1000h to B000, cacheable
    outw (c),hl

    ;Finally, activate the MMU

    ld c,Z280.MMU_PORTS.MASTER_CONTROL
    ld hl,1011101111100000b ;UTE=STE=1 (enable MMU), UPD=SPD=0 (disable program/data separation)
    outw (c),hl

    if USE_CACHE neq 0

    ;--- Configure the cache appropriately
    ;    (see Z280 Technical Manual, chapter 3.2.4)

    ld c,Z280.CONTROL_REGISTERS.CACHE_CONTROL
    ld l,(USE_CACHE XOR 3) SHL 5
    ldctl (c),hl

    endif

    ;--- Additional control register setup
    ;    (see Z280 Technical Manual, chapter 3)

    ;No additional I/O wait states
    xor a
    out (Z280.CONTROL_REGISTERS.BUS_TIMING_CONTROL),a
    
    ;Allow user I/O, no EPU, no system stack overflow exceptions
    ;xor a
    out (Z280.CONTROL_REGISTERS.TRAP_CONTROL),a

    ;None of the interrupts are vectored
    ld hl,0
    ld c,Z280.CONTROL_REGISTERS.INTERRUPT_STATUS
    outw (c),hl

    ;Set interrupt/trap vector pointer
    ld hl,RESIDENT_CODE_START_ADDRESS-(INT_TRAP_VECTOR-RESIDENT_CODE)
    ld c,Z280.CONTROL_REGISTERS.INT_TRAP_VECTOR_POINTER
    outw (c),hl

    ;Stay in system mode, no breakpoint-on-halt, no single step, enable all interrupt sources
    ld hl,0000000001111111b
    ld c,Z280.CONTROL_REGISTERS.MSR
    outw (c),hl

    ;--- Reset I/O page register to 0

    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,0
    ldctl (c),hl

    ;--- Set the interrupt mode

    if USE_IM3 eq 0
    im 1
    else
    im 3
    endif

    ret

    endmod

    end
