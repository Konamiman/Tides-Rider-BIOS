    title Tides Rider BIOS with Z280 support
    subttl System call 0: Terminate Z280 application

	name ('SC_0')

    public HANDLE_SC_0
    extrn Z280.SP_FOR_RETIL
    extrn CHGCPU.SETZ80
    extrn Z280.SAVE_Z80_STACK

    include "msx.inc"
    include "z280.inc"

    .cpu z280


;--- System call 0: Terminate Z280 application
;    Input: All registers as they will be passed to the Z80
;    Output: (ARG) = PC in the Z280 after the SC 0
;            (ARG+2) = SP in the Z280

HANDLE_SC_0:
    ld (ARG+4),hl
    push af
    pop hl
    ld (ARG+6),hl

    ;Save user PC and SP in ARG

    push ix
    ld ix,(Z280.SP_FOR_RETIL)
    ld hl,(ix+2) ;PC
    pop ix
    ld (ARG),hl
    ldctl hl,usp
    ld (ARG+2),hl

    ;Set the I/O page to FF

    push bc
    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    ld l,0FFh
    ldctl (c),hl
    pop bc

    ;If page 2 isn't connected to slot 0, connect it

    in a,(0A8h)
    and 11001111b
    jr z,.PAGE2_SLOT_OK

    push bc
    push de
    push ix
    push iy
    xor a
    ld h,40h
    call ENASLT
    pop iy
    pop ix
    pop de
    pop bc
.PAGE2_SLOT_OK:

    ;Restore the Z80 stack pointer and give control back to the Z80

    ld hl,(Z280.SAVE_Z80_STACK)
    ld sp,hl

    ld hl,(ARG+6)
    push hl
    pop af
    ld hl,(ARG+4)

    ;Note that we are right now running code in the Z280 memory in B000-BFFF,
    ;but once the Z80 gets control again this part of the memory will be
    ;in the MSX addressing space. Thus we can't CALL the CPU changing routine,
    ;we need to JP to it. Once it finishes control will return to the code
    ;that executed the "run Z280 application" UNAPI routine.
    jp CHGCPU.SETZ80

    end
