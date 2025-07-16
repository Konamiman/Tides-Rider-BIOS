    public GETSLT2
    public GETSLT3
    public GETWRK
    public TOUPPER

    include "msx.inc"

    .relab


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


;--- Get slot connected on page 3
;    Input:  -
;    Output: A = Slot number
;    Modifies: AF, HL, E, BC

GETSLT3:
  di
  exx
  in  a,(0A8h)
  ld  e,a
  and  11000000b
  rlca
  rlca
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
  and  11000000b
  rrca
  rrca
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


;--- Obtain slot work area (8 bytes) on SLTWRK
;    Input:  A  = Slot number
;    Output: HL = Work area address
;    Modifies: AF, BC

GETWRK:
  ld  b,a
  rrca
  rrca
  rrca
  and  01100000b
  ld  c,a  ;C = Slot * 32
  ld  a,b
  rlca
  and  00011000b  ;A = Subslot * 8
  or  c
  ld  c,a
  ld  b,0
  ld  hl,SLTWRK
  add  hl,bc
  ret


;--- Convert a character to upper-case if it is a lower-case letter

TOUPPER:
  cp  "a"
  ret  c
  cp  "z"+1
  ret  nc
  and  0DFh
  ret

  end
