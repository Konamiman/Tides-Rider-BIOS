    title Tides Rider BIOS with Z280 support
    subttl Miscellaneous utility routines

    name('UTILS')

    public GETSLT2
    public GETSLT1
    public TOUPPER
    public PRINT
    public BIT_76_TO_10
    public Z280.MAP_CONSECUTIVE

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


;--- Get slot connected on page 1
;    Input:  -
;    Output: A = Slot number
;    Modifies: AF, HL, E, BC

GETSLT1:
  di
  exx
  in  a,(0A8h)
  ld  e,a
  and  00001100b
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
  and  00001100b
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


  .cpu z280

  module Z280

  include "z280.inc"


;--- Map a consecutive group of 4K pages to a consecutive group of 4K segments.
;    Assumes FFh in the I/O page regiser.
;    Input: A  = Index of first page descriptor
;                (00-0F for user mode, 10-1F for system mode)
;                00 and 10 = 0000-0FFF
;                01 and 11 = 1000-1FFF
;                ...
;                0F and 1F = F000-FFFF
;           B  = How many pages to map
;           HL = Address of first segment
;                (bits 23-12 of address in bits 15-4 of HL)
;                Bits 3-0 of L: V WP C 0
;                (valid, write-protect, cacheable)
;                H=0 maps the MSX memory
;    Modifies: F, BC, HL

MAP_CONSECUTIVE:
  out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a

  ld c,Z280.MMU_PORTS.BLOCK_MOVE
.MAP_LOOP:
  outw (c),hl
  addw hl,0010h   ;Next 4K page, note that lower nibble of L is unchanged
  djnz .MAP_LOOP

  ret

  endmod

  end
