    title Tides Rider BIOS with Z280 support
    subttl Change CPU routine

    name('CHGCPU')

.COMMENT \

This is the routine that switches to the Z80 or the Z280.
The change to Z280 should be done by application programs by using
the "Run Z280 program" UNAPI function, and the change to Z80
should be done by executing SC 0 from within the Z280 code.

\

    public CHGCPU.RUN
    public CHGCPU.CONTINUE

    module CHGCPU

    ;Input: A=0 to switch to Z80
    ;         1 to switch to Z280
    ;
    ;Note that this routine returns with interrupts disabled.
    
RUN:
    DI
    PUSH    HL
    PUSH    DE
    PUSH    BC
    PUSH    AF
    PUSH    IX
    PUSH    IY
    EXX
    EX      AF,AF'
    PUSH    HL
    PUSH    DE
    PUSH    BC
    PUSH    AF                      ; save all Z80 registers
    LD      A,I
    PUSH    AF                      ; save interrupttable pointer
    LD      (0FFFDh),SP             ; save stackpointer
    EX      AF,AF'

CONTINUE:
    and 1
    ld b,a
    in a,(0F0h) ;TODO: Adjust to the definitive port
    and 11111110b
    or b
    ifndef FAKE_Z280
        out (0F0h),a
    endif

    DI
    NOP
    LD      SP,(0FFFDh)             ; restore stackpointer
    POP     AF
    LD      I,A                     ; restore interrupttable pointer
    POP     AF
    POP     BC
    POP     DE
    POP     HL
    EXX
    EX      AF,AF'
    POP     IY
    POP     IX
    POP     AF
    POP     BC
    POP     DE
    POP     HL                      ; restore all Z80 registers
    ex af,af'
    RET

    endmod

    end