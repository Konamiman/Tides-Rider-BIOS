    title Tides Rider BIOS with Z280 support
    subttl System call 0: Get or set the value of the I/O page register

	name ('SC_1')

    public HANDLE_SC_1

    include "z280.inc"

    .cpu z280


;--- System call 1: Get or set the value of the I/O page register
;    Input: Cy = 0 to get, 1 to set
;           A = New value for the I/O page register (if set)
;    Output: A = Current value of the I/O page register (if get)
;    Modifies: -

HANDLE_SC_1:
    push hl
    push bc
    ld c,Z280.CONTROL_REGISTERS.IO_PAGE
    jr c,.SET
.GET:
    ldctl hl,(c)
    ld a,l
    jr .END
.SET:
    ld l,a
    ldctl (c),hl
.END:
    pop bc
    pop hl
    ret

    end
