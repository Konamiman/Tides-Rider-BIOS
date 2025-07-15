    .COMMENT \
Tides Rider BIOS

    \


;----- Constants -----

ROM_BASE: equ 8000h

CHPUT: equ 00A2h


;---- ROM header

    org ROM_BASE

    db 41h,42h
    dw ROM_BOOT
    ds (ROM_BASE+0010h)-$


;--- Z80 boot (standard MSX ROM boot)

ROM_BOOT:
    in a,(0A8h)
    and 00110000b
    ret nz

    ld hl,INTRO_S
    call PRINT

    ;Switch slot 3-2 (RAM) in page 0

    di
    in a,(0A8h)
    and 11111100b
    or 00000011b
    out (0A8h),a

    ld a,(0FFFFh)
    cpl
    and 11111100b
    or 00000010b
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
    rept 60
    halt
    endm

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
    
INTRO_S:
    db "Tides Rider BIOS!\r\n",0
STARTZ280_S:
    db "Hi, I'm the Z280!\r\n",0

    ds (ROM_BASE+4000h)-$


