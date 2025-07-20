    title Tides Rider BIOS with Z280 support
    subttl Miscellaneous utility routines

    public GETSLT2
    public TOUPPER
    public PRINT
    public BIT_76_TO_10

    include "msx.inc"

    .relab


;--- Print a zero-terminated string (assumes BIOS visible in page 0)
;    Input: HL = pointer to string
;    Modifies: AF, HL

PRINT:
    ld a,(hl)
    or a
    ret z
    call CHPUT
    inc hl
    jr PRINT


;--- Copy bits 7 and 6 of a byte to bits 1 and 0
;    Input: A = original byte
;    Output: A = modified byte
;    Modifies: F, B

BIT_76_TO_10:
    ld b,a
    and 11000000b
    rlca
    rlca
    res 0,b
    res 1,b
    or b
    ret


;--- Get slot connected on page 2
;    Input:  -
;    Output: A = Slot number
;    Modifies: AF, HL, E, BC

GETSLT2:
  di
  exx
  in  a,(0A8h)
  ld  e,a
  and  00110000b
  rrca
  rrca
  rrca
  rrca
  ld  c,a  ;C = Slot
  ld  b,0
  ld  hl,EXPTBL
  add  hl,bc
  bit  7,(hl)
  jr  z,.NOT_EXPANDED
  inc  hl
  inc  hl
  inc  hl
  inc  hl ;Point to SLTTBL entry
  ld  a,(hl)
  and  00110000b
  rrca
  rrca
  or  c
  or  80h
  ld  c,a
.NOT_EXPANDED:
  ld  a,c
  exx
  ei
  ret


;--- Convert a character to upper-case if it is a lower-case letter
;    Input: A = original character
;    Output: A = modified character
;    Modifies: F

TOUPPER:
  cp  "a"
  ret  c
  cp  "z"+1
  ret  nc
  and  0DFh
  ret

  end
