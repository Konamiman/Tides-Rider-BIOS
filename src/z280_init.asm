    title Tides Rider BIOS with Z280 support
    subttl Z280 initialization code

.COMMENT \

This routine initializes the Z280 processor to its initial state
(control registers and MMU descriptors) and copies the resident code.
It runs at boot time but can also be executed manually via a dedicated
UNAPI routine. The Z280 CPU active in system mode is assumed.

See the comments in the file for the details on how the Z280 is initialized.

\

    public Z280.INIT
    extrn Z280.MAP_CONSECUTIVE
    extrn Z280.RESIDENT_CODE ;Assumed to be A000h

    module Z280

    ifndef Z280.USE_CACHE
USE_CACHE: equ 3 ;0 = no, 1 = data, 2 = instructions, 3 = both
    endif

    include "z280.inc"
    include "tides.inc"

    .cpu Z280

    .extroot
    .relab

INIT:

    di

    ;--- Set the I/O page to FFh, the value used for all the Z280 internal ports.

    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,0FFh
    ldctl (c),hl

    ;--- Temporarly (or not, depending on USE_CACHE) disable the cache
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

    ;--- Configure the MMU and copy the resident code 

    ;Configure the MMU page descriptors so they match the MSX addressing space
    ;(so the Z280 addresses 000000-00FFFF are mapped into 0000-FFFF)
    ;for system mode. This is the same as what the Z280 sees when the MMU is disabled.
    ;User mode mappings will be done right before a user application runs.

    ld a,16 ;Index of first MMU page descriptor for system mode
    ld b,a  ;Map 16 4K pages = 64K
    ld hl,0 ;Map from the beginning of the Z280 memory = the MSX memory
    call Z280.MAP_CONSECUTIVE

    ;Activate the MMU. Given the mappings done, nothing changes regarding the visible memory.

    ld c,Z280.MMU_PORTS.MASTER_CONTROL
    ld hl,1011101111100000b ;UTE=STE=1 (enable MMU), UPD=SPD=0 (disable program/data separation)
    outw (c),hl

    ;Copy the Z280 resident code (including the interrupt/trap vectors table),
    ;which is located at addresses A000-BFFF in this ROM (second 8K half of page 2),
    ;into the Z280 RAM at address RESIDENT_CODE_START_ADDRESS.
    ;That code is intended to be mapped at A000-BFFF too when being used.
    ;
    ;We'll make the copy in two steps, using a "zig zag" strategy:
    ;1. Map RESIDENT_CODE_START_ADDRESS+1000h into A000-AFFF and copy the second half.
    ;2. Map RESIDENT_CODE_START_ADDRESS into B000-BFFF and copy the first half.
    ;
    ;See Z280 Technical Manual, chapter 7
    
    ld c,Z280.MMU_PORTS.BLOCK_MOVE ;Writing to this port autoincreases the value at PAGE_DESCRIPTOR

    ld a,16 + 0A000h/1000h  ;+16 because system page descriptors go after the 16 user page descriptors
    out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a
    ld hl,RESIDENT_CODE_START_ADDRESS + 0010h ;Map second half of Z280 resident code memory to A000
    outw (c),hl

    ld hl,Z280.RESIDENT_CODE+1000h  ;Second half of the 8K resident code (expected to be B000)
    ld de,0A000h
    ld bc,1000h
    ldir    ;TODO: Worth trying to use DMA for this?

    ld hl,RESIDENT_CODE_START_ADDRESS ;Map first half of Z280 resident code memory to B000
    outw (c),hl ;(remember: the previous out increased PAGE_DESCRIPTOR, so we're mapping B000-BFFF now)

    ld a,16 + 0A000h/1000h
    out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a    
    ld hl,00A0h
    outw (c),hl ;...and map the A000-AFFF area back to the MSX memory too!

    ld hl,Z280.RESIDENT_CODE ;Note that this is expected to be A000
    ld de,0B000h
    ld bc,1000h
    ldir

    ;Now modify the mapping for system mode so that the full Z280 resident code RAM
    ;(8K) is mapped to A000-BFFF.

    ld a,16 + 0A000h/1000h
    ld b,2
    if USE_CACHE eq 0
    ld hl,RESIDENT_CODE_START_ADDRESS ;Map RESIDENT_CODE_START_ADDRESS to A000, not cacheable
    else
    ld hl,RESIDENT_CODE_START_ADDRESS + 2 ;Map RESIDENT_CODE_START_ADDRESS to A000, cacheable
    endif
    call Z280.MAP_CONSECUTIVE

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
    ld hl,RESIDENT_CODE_START_ADDRESS
    ld c,Z280.CONTROL_REGISTERS.INT_TRAP_VECTOR_POINTER
    outw (c),hl

    ;Stay in system mode, no breakpoint-on-halt, no single-step, enable all interrupt sources
    ld hl,0000000001111111b
    ld c,Z280.CONTROL_REGISTERS.MSR
    outw (c),hl

    ;--- Reset I/O page register to 0

    if 0

    ;No need for that! We'll never access the MSX ports while in Z280 system mode,
    ;so it's actually more convenient to leave it at FFh for quick access
    ;to the built-in port-mapped registers.

    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,0
    ldctl (c),hl

    endif

    ;--- Set the interrupt mode, but return with interrupts disabled

    im 3

    if USE_CACHE neq 0
    pcache
    endif

    ret

    endmod

    end
