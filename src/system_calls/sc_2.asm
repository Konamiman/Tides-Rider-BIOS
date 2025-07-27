    title Tides Rider BIOS with Z280 support
    subttl System call 0: Map memory

	name ('SC_2')

    public HANDLE_SC_2
    extrn Z280.MAP_CONSECUTIVE

    include "z280.inc"
    include "tides.inc"

    .cpu z280


;--- System call 2: Map memory
;    Input: A = High byte of the first 4K page (visible addressing space) to map
;               The low nibble is ignored
;               e.g. 90h to map visible memory starting at 9000h
;           B = How many 4K consecutive pages to map
;           C = Mapping mode:
;               0: MSX memory corresponding the the pages being mapped
;               1: ZTPA corresponding the the pages being mapped
;               2: Specific memory address
;               Bit 7 set to disable cache (mapping modes 1 and 2 only)
;           HL = Two high bytes of the first memory address to map (mapping mode 2 only)
;                Address must be a multiple of 4K, thus the low nibble of L is ignored
;                e.g. 1230h to map address 123000h
;    Output: -
;    Modifies: -

HANDLE_SC_2:

    ;Convert A to a page descriptor index (for user mode) and save it

    ld d,a

    sra a
    sra a
    sra a
    sra a
    push af

    ld a,c
    and 11h ;We'll look at the "disable cache" flag later
    cp 2
    jr z,.SET_CACHE_FLAG
    dec a
    jr z,.MAP_ZTPA

.MAP_MSX:
    ld h,0
    ld l,d
    jr .DO_MAP  ;MSX memory is never cacheable

.MAP_ZTPA:
    ld h,0
    ld l,d
    addw hl,ZTPA_START_ADDRESS

.SET_CACHE_FLAG:

    ;Here we have the two high bytes of the address to map in HL.

    bit 7,c
    jr nz,.DO_MAP
    set 1,l

.DO_MAP:

    ;Here we have the two high bytes of the address to map in HL
    ;AND the corresponding cache flag set in bit 1 of L.

    push hl
    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,a
    ldctl hl,(c)
    ld d,l  ;Save current I/O page
    ld l,0FFh
    ldctl (c),hl ;Set I/O page FFh, required by MAP_CONSECUTIVE
    pop hl

    pop af  ;Page descriptor index
    call Z280.MAP_CONSECUTIVE

    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,d
    ldctl (c),hl    ;Restore previous I/O page

    ret

    end


