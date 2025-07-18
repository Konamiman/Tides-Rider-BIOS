.COMMENT \

Strategy for initializing the Z280 at boot:

BOOT:
	Z280 booted flag set?
	No:
		di
		Set RAM in page 0
		Set jump tp BOOT280 in address 0
		call CHGCPU(Z280)
		if address 0 has a 0
			Z280 was found and has booted
			Set Z280 booted
		Restore BIOS in page 0
		if Z280 has booted
			Set Z280 booted flag
			Initialize UNAPI
	if Z280 booted flag set
		call CHGCPU(Z280)
		Init Z280 registers and RAM
		call CHGCPU(Z80)
    ei
	ret

CHGCPU:
	push push...
CHGCPU2:
	change CPU!
	pop pop...
	ret

BOOT280:
	Set 0 in address 0
	jp CHGCPU2(Z80)

\

    public BOOT.RUN
    extrn GETSLT2
    extrn UNAPI.SPEC_NAME
    extrn UNAPI.SPEC_NAME_LENGTH
    extrn UNAPI.IMPL_NAME
    extrn UNAPI.IMPL_NAME_LENGTH    
    extrn UNAPI.EXTBIO_HANDLER
    extrn UNAPI.ENTRY_POINT
    extrn ALLOC.RUN

    .extroot
    .relab

    module BOOT

    include "msx.inc"
    include "tides.inc"

;--- Z80 boot (standard MSX ROM boot)

RUN:
    ;Stop if wew are not in page 2 or in slot 0 (prevents ROM mirroring)

    ld a,h
    and 11000000b
    cp 10000000b
    ret nz

    in a,(0A8h)
    and 00110000b
    ret nz

    ;Patch H.CLEAN and H.LOPD for the real initialization
    ;See https://sourceforge.net/p/msxsyssrc/git/ci/master/tree/examples/allocate_system_memory/allocd.mac

    ld a,0F7h
    ld (H.CLEA),a
    ld (H.LOPD),a
    call GETSLT2
    ld (H.CLEA+1),a
    ld (H.LOPD+1),a
    ld hl,RUN_HCLEAN
    ld (H.CLEA+2),hl
    ld hl,RUN_HLOPD
    ld (H.LOPD+2),hl
    ld a,0C9h
    ld (H.CLEA+4),a
    ld (H.LOPD+4),a

    ret

    ;Target of H.LOPD

RUN_HLOPD:
    PUSH	HL
	PUSH	BC
	LD	HL,0C9C9H
	LD	(H.LOPD+0),HL
	LD	(H.LOPD+2),HL		; clean up H.LOPD
	LD	A,(H.PHYD)
	CP	0C9H			; disk system initialized ?
	JR	Z,.SKPADJ		; nope, skip
	LD	DE,(HIMEM)
	LD	(0F349h),DE		; yep, register disk system bottom
.SKPADJ:
    POP	BC
	POP	HL
	RET

    ;Target of H.CLEAN

RUN_HCLEAN:
    push hl
    call .RUN
    pop hl
    ret    

.RUN:
    ld hl,0c9c9h
    ld (H.CLEA),hl
    ld (H.CLEA+2),hl
    ld a,h
    ld (H.CLEA+4),a

    ;Initialize the EXTBIO hook if needed

    ld a,(HOKVLD)
    bit 0,a
    jr nz,.OK_INIEXTB

    ld hl,EXTBIO
    ld de,EXTBIO+1
    ld bc,5-1
    ld (hl),0C9h  ;code for RET
    ldir

    or  1
    ld  (HOKVLD),a
.OK_INIEXTB:

    ;Print intro

    ld hl,INTRO_S
    call PRINT

    ;Allocate space for old EXTBIO hook, a jump to our UNAPI entry point, and the UNAPI implementation name.
    ;We'll use SLTWRK of the RAM slot to store the pointer, because the one for the BIOS slot (where we are)
    ;is used by CALL MEMINI and the KANJI ROM.
    ;
    ;An indirect call to the UNAPI entry point via a page 3 entry point is needed because the UNAPI specification
    ;doesn't allow entry points in ROM page 2 (and the implementation name must then be in page 3 too).

    ld hl,5+5+UNAPI.IMPL_NAME_LENGTH
    call ALLOC.RUN
    jr nc,.ALLOC_OK

    ld hl,ALLOC_FAIL_S
    call PRINT
    ret
.ALLOC_OK:
    ld (OLD_EXTBIO_PNT),hl

    ex de,hl
    ld hl,EXTBIO
    ld bc,5
    ldir
    ex de,hl

    ld (UNAPI_P3_ENTRY_PNT),hl

    ld (hl),0F7h
    inc hl
    call GETSLT2
    ld (hl),a
    inc hl
    ld bc,UNAPI.ENTRY_POINT
    ld (hl),c
    inc hl
    ld (hl),b
    inc hl
    ld (hl),0C9h
    inc hl

    ld (UNAPI_NAME_PNT),hl

    ex de,hl
    ld hl,UNAPI.IMPL_NAME
    ld bc,UNAPI.IMPL_NAME_LENGTH
    ldir

    ;Setup the new EXTBIO hook

    di
    ld  a,0F7h  ;code for "RST 30h"
    ld  (EXTBIO),a
    call  GETSLT2
    ld  (EXTBIO+1),a
    ld  hl,UNAPI.EXTBIO_HANDLER
    ld  (EXTBIO+2),hl
    ld a,0C9h
    ld (EXTBIO+4),a

    ;Switch RAM slot in page 0
    ;(assumes RAM slot visible in page 3)

    in a,(0A8h)
    call BIT_76_TO_10
    out (0A8h),a

    ld a,(0FFFFh)
    cpl
    call BIT_76_TO_10
    ld (0FFFFh),a

    ;Copy jump to start Z80 routine

    ld a,(0)
    push af
    ld hl,(1)
    push hl

    ld a,0C3h ;JP
    ld (0),a
    ld hl,START_Z80
    ld (1),hl

    ;Simulate Z280 restarting at address 0 from RAM

    jp 0

NEXT:
    ei
    ret

START_Z80:
    ;Restore BIOS in page 0

    pop hl
    ld (1),hl
    pop af
    ld (0),hl

    in a,(0A8h)
    and 11111100b
    out (0A8h),a

    ei

    ld hl,STARTZ280_S
    call PRINT
    jr NEXT

PRINT:
    ld a,(hl)
    or a
    ret z
    call CHPUT
    inc hl
    jr PRINT

BIT_76_TO_10:
    ld b,a
    and 11000000b
    rlca
    rlca
    res 0,b
    res 1,b
    or b
    ret

INTRO_S:
    db "Tides Rider BIOS!\r\n",0
STARTZ280_S:
    db "Hi, I'm the Z280!\r\n",0
ALLOC_FAIL_S:
    db "*** Failed to allocate space in page 3\r\n",0

    endmod

    end
