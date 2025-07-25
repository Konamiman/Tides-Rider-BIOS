    title Tides Rider BIOS with Z280 support
    subttl ROM boot code

.COMMENT \

This file provides the ROM boot code, which will run when the MSX boots.
It does the following:

1. Reset the Z280 processor and bring its PC register it to a controller location
   inside the CHGCPU routine (if that hadn't been done already).
2. Run the Z280 initialization routine to configure its control registers
   and MMU page mappings.
3. Initialize the EXTBIO hook for the UNAPI implementation.

Regarding the UNAPI implementation, there's a catch: this is a page 2 ROM,
but the UNAPI standard only allows implementations to live in page 1 ROM,
page 3 RAM, or mapped RAM. To workaround this we allocate a small space in page 3
with an interslot call to the UNAPI entry point, and we announce the address
of this page 3 area as the "official" UNAPI entry point for the implementation
(this implies that we need to copy the implementation name to page 3 too).

And this brings us to the second catch: the only reliable way to allocate page 3
RAM from within a ROM, playing nicely with MSX-DOS/Nextor, is the H.CLEA hook,
which runs when the BASIC environment is initialized. Therefore, the UNAPI
implementation won't be available if the system boots in the DOS prompt
until one jump to BASIC is made.

As for the Z280 boot procedure, the strategy followed is temporarily switching
RAM in page 0, inserting a jump to the Z280 boot code at address 0, and then
passing control to the Z280 CPU. The Z280 boot code will set a 0 byte at address 0
(replacing the JP instruction that we had set earlier) and we'll use this to detect
that the Z280 CPU was present and booted.

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
    extrn Z280.INIT
    extrn CHGCPU.RUN
    extrn CHGCPU.CONTINUE
    extrn PRINT
    extrn BIT_76_TO_10

    .extroot
    .relab

    module BOOT

    include "msx.inc"
    include "tides.inc"


    ;--- ROM boot code

RUN:
    ;Stop if wew are not in page 2 or in slot 0
    ;(prevents double boot due to ROM mirroring)

    ld a,h
    and 11000000b
    cp 10000000b
    ret nz

    in a,(0A8h)
    and 00110000b
    ret nz

    ;Print intro and boot Z280 if needed

    ld hl,INTRO_S
    call PRINT

    in a,(0F4h) ;TODO: Adjust to the definitive port
    and 20h
    call z,BOOT_Z280

    ;If Z280 wasn't found we have nothing else to do

    in a,(0F4h) ;TODO: Adjust to the definitive port
    and 20h
    ld hl,Z280INIT_FAIL_S
    jp z,PRINT_AND_PAUSE

    ;Switch to the Z280 and initialize it

    ld a,1
    call CHGCPU.RUN

    call Z280.INIT

    xor a
    call CHGCPU.RUN

    ld hl,Z280INIT_OK_S
    call PRINT_AND_PAUSE


    ;Patch H.CLEAN and H.LOPD for the UNAPI hook initialization
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


PRINT_AND_PAUSE:
    call PRINT
    ei
    ld b,50
.HALT_LOOP:
    halt
    djnz .HALT_LOOP
    ret


    ;--- Target of H.LOPD

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


    ;--- Target of H.CLEAN:
    ;    Allocate memory for UNAPI and initialize the EXTBIO hook

RUN_HCLEAN:
    push hl ;Save BASIC text pointer
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

    ;Allocate space for the old EXTBIO hook, the jump to our UNAPI entry point, and the UNAPI implementation name.
    ;We'll use SLTWRK of the RAM slot to store the pointers, because the area for the BIOS slot (where we are)
    ;is used by CALL MEMINI and the kanji ROM.

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

    ld (hl),0F7h  ;code for "RST 30h"
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

    ei

    ;Print success message

    ld hl,ALLOC_OK_S
    call PRINT

    ret


    ;--- Z280 boot procedure

BOOT_Z280:

    ;Hold the Z280 RESET for a while and then release it

    in a,(0F0h) ;TODO: Adjust to the definitive port
    or 00001000b
    out (0F0h),a
    
    ei
    halt
    halt
    di

    and 11110111b
    out (0F0h),a ;TODO: Adjust to the definitive port

    ;Switch RAM slot in page 0
    ;(assumes RAM slot visible in page 3)

    in a,(0A8h)
    call BIT_76_TO_10
    out (0A8h),a

    ld a,(0FFFFh)
    cpl
    call BIT_76_TO_10
    ld (0FFFFh),a

    ;Copy jump instruction in address 0, to be run by the Z280 when it boots
    ;(first we save the RAM contents we are overwriting)

    ld a,(0)
    push af
    ld hl,(1)
    push hl

    ld a,0C3h ;JP
    ld (0),a
    ld hl,START_Z280
    ld (1),hl

    ;Activate Z280 and wait for it to boot and pass control to Z80 again

    ld a,1
    call CHGCPU.RUN

    ifdef FAKE_Z280
        xor a
        ld (0),a
    endif

    ;> At this point either the Z280 was found (and then booted and wrote a 0 at address 0)
    ;  or not (and then address 0 still contains the JP instructiom)

    ;Save the value at address 0, restore RAM contents, and restore BIOS in page 0

    ld bc,(0)
    pop hl
    ld (1),hl
    pop af
    ld (0),a

    ld a,c
    push af

    in a,(0A8h)
    and 11111100b
    out (0A8h),a

    ld a,(SLTTBL + (RAM_SLOT and 3))
    ld (0FFFFh),a

    ;If the Z280 was found, set the booted flag

    pop af
    or a
    jr Z280_BOOT_OK

Z280_BOOT_FAIL:
    ld hl,Z280INIT_FAIL_S
    call PRINT

    ei
    ret

Z280_BOOT_OK:
    ld hl,Z280INIT_OK_S
    call PRINT

    in a,(0F4h) ;TODO: Adjust to the definitive port
    or 20h
    out (0F4h),a

    ei
    ret


    ;--- Code that the Z280 runs when it boots

START_Z280:
    di
    xor a
    ld (0),a ;We'll use this change to detect that the Z280 was present and booted
    jp CHGCPU.CONTINUE


    ;--- Printable strings

INTRO_S:
    db "Tides Rider BIOS 0.1\r\n",0
ALLOC_OK_S:
    db "Z280 UNAPI initialized\r\n",0
ALLOC_FAIL_S:
    db "*** Failed to allocate space in page 3, Z280 UNAPI not initialized\r\n",0
Z280INIT_OK_S:
    db "Z280 CPU initialized\r\n",0
Z280INIT_FAIL_S:
    db "*** Z280 CPU not found\r\n",0

    endmod

    end
