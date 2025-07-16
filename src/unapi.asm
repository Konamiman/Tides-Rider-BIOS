    public UNAPI.SPEC_NAME
    public UNAPI.SPEC_NAME_LENGTH
    public UNAPI.IMPL_NAME
    public UNAPI.IMPL_NAME_LENGTH
    public UNAPI.EXTBIO_HANDLER
    public UNAPI.ENTRY_POINT
    extrn ALLOC.RUN
    extrn GETSLT2
    extrn GETSLT3
    extrn GETWRK
    extrn TOUPPER

    .extroot

    module UNAPI

    include "msx.inc"
    include "tides.inc"

;--- API version and implementation version

API_V_P:  equ  1
API_V_S:  equ  0
ROM_V_P:  equ  1
ROM_V_S:  equ  0

;--- Maximum number of available standard and implementation-specific function numbers

;Must be 0 to 127
MAX_FN:    equ  2

;Must be either zero (if no implementation-specific functions available), or 128 to 254
MAX_IMPFN:  equ  0


;*****************************
;***  EXTBIO HOOK HANDLER  ***
;*****************************

EXTBIO_HANDLER:
    push  hl
    push  bc
    push  af
    ld  a,d
    cp  22h
    jr  nz,JUMP_OLD
    cp  e
    jr  nz,JUMP_OLD

    ;Check API ID

    ld  hl,SPEC_NAME
    ld  de,ARG
LOOP:  ld  a,(de)
    call  TOUPPER
    cp  (hl)
    jr  nz,JUMP_OLD2
    inc  hl
    inc  de
    or  a
    jr  nz,LOOP

    ;A=255: Jump to old hook

    pop  af
    push  af
    inc  a
    jr  z,JUMP_OLD2

    ;A=0: B=B+1 and jump to old hook.

    pop  af
    pop  bc
    or  a
    jr  nz,DO_EXTBIO2
    inc  b
    ld hl,(OLD_EXTBIO_PNT)
    ex  (sp),hl
    ld  de,2222h
    ret
DO_EXTBIO2:

    ;A=1: Return A=Slot, B=Segment, HL=UNAPI entry address

    dec  a
    jr  nz,DO_EXTBIO3
    pop  hl
    call  GETSLT2
    ld  hl,(UNAPI_P3_ENTRY_PNT)
    ld  de,2222h
    ret

    ;A>1: A=A-1, and jump to old hook

DO_EXTBIO3:  ;A=A-1 already done
    ex  (sp),hl
    ld  de,2222h
    ret

  ;--- Jump here to execute old EXTBIO code

JUMP_OLD2:
    ld  de,2222h
JUMP_OLD:  ;Assumes "push hl,bc,af" done
    ld hl,(OLD_EXTBIO_PNT)
    pop  af
    pop  bc
    ex  (sp),hl
    ret
  

;************************************
;***  FUNCTIONS ENTRY POINT CODE  ***
;************************************

ENTRY_POINT:
    push  hl
    push  af
    ld  hl,FN_TABLE
    bit  7,a

    if MAX_IMPFN gte 128

    jr  z,IS_STANDARD
    ld  hl,IMPFN_TABLE
    and  01111111b
    cp  MAX_IMPFN-128
    jr  z,OK_FNUM
    jr  nc,UNDEFINED
IS_STANDARD:

    else

    jr  nz,UNDEFINED

    endif

    cp  MAX_FN
    jr  z,OK_FNUM
    jr  nc,UNDEFINED

OK_FNUM:
    add  a,a
    push  de
    ld  e,a
    ld  d,0
    add  hl,de
    pop  de

    ld  a,(hl)
    inc  hl
    ld  h,(hl)
    ld  l,a

    pop  af
    ex  (sp),hl
    ret

    ;--- Undefined function: return with registers unmodified

UNDEFINED:
    pop  af
    pop  hl
    ret


;***********************************
;***  FUNCTIONS ADDRESSES TABLE  ***
;***********************************

;TODO: Adjust for the routines of your implementation

;--- Standard routines addresses table

FN_TABLE:
FN_0:  dw  FN_INFO
FN_1:  dw  FN_ADD
FN_2:  dw  FN_MULT


;--- Implementation-specific routines addresses table

    if MAX_IMPFN gte 128

IMPFN_TABLE:
FN_128:  dw  FN_DUMMY

    endif


;************************
;***  FUNCTIONS CODE  ***
;************************

;--- Mandatory routine 0: return API information
;    Input:  A  = 0
;    Output: HL = Descriptive string for this implementation, on this slot, zero terminated
;            DE = API version supported, D.E
;            BC = This implementation version, B.C.
;            A  = 0 and Cy = 0

FN_INFO:
    ld hl,(UNAPI_NAME_PNT)
    ld bc,256*ROM_V_P+ROM_V_S
    ld de,256*API_V_P+API_V_S
    xor a
    ret

;TODO: Replace the FN_* routines below with the appropriate routines for your implementation

;--- Sample routine 1: adds two 8-bit numbers
;    Input: E, L = Numbers to add
;    Output: HL = Result

FN_ADD:
    ld  h,0
    ld  d,0
    add  hl,de
    ret


;--- Sample routine 2: multiplies two 8-bit numbers
;    Input: E, L = Numbers to multiply
;    Output: HL = Result

FN_MULT:
    ld  b,e
    ld  e,l
    ld  d,0
    ld  hl,0
MULT_LOOP:
    add  hl,de
    djnz  MULT_LOOP
    ret


;*****************
;***  STRINGS  ***
;*****************

SPEC_NAME:
    db "MSX280",0
SPEC_NAME_END:

IMPL_NAME:
    db "Tides Rider",0
IMPL_NAME_END:

SPEC_NAME_LENGTH: equ SPEC_NAME_END-SPEC_NAME
IMPL_NAME_LENGTH: equ IMPL_NAME_END-IMPL_NAME

    endmod

    end

