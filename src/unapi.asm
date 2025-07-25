    title Tides Rider BIOS with Z280 support
    subttl UNAPI handler

.COMMENT \

This file contains all the UNAPI related code: the EXTBIO hook handler,
the functions entry point, and the functions themselves.
The code that patches the EXTBIO hook is in boot.asm

\

    public UNAPI.SPEC_NAME
    public UNAPI.SPEC_NAME_LENGTH
    public UNAPI.IMPL_NAME
    public UNAPI.IMPL_NAME_LENGTH
    public UNAPI.EXTBIO_HANDLER
    public UNAPI.ENTRY_POINT
    extrn ALLOC.RUN
    extrn GETSLT1
    extrn GETSLT2
    extrn TOUPPER
    extrn CHGCPU.RUN
    extrn Z280.INIT

    ifdef DEBUGGING
        public UNAPI.FN_COPY_MSX_TO_Z280
    endif

    .extroot
    .relab

    module UNAPI

    include "msx.inc"
    include "tides.inc"
    include "z280.inc"

;--- API version and implementation version

API_V_P:  equ  1
API_V_S:  equ  0
ROM_V_P:  equ  1
ROM_V_S:  equ  0

;--- Maximum number of available standard and implementation-specific function numbers

;Must be 0 to 127
MAX_FN:    equ  ((FN_TABLE_END-FN_TABLE)/2)-1

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
FN_0: dw FN_INFO
FN_1: dw FN_Z280INFO
FN_2: dw FN_INITZ280
FN_3: dw FN_COPY_MSX_TO_Z280
FN_4: dw FN_COPY_Z280_TO_MSX
FN_5: dw FN_RUNZ280_MSX
FN_6: dw FN_RUNZ280_Z280
FN_TABLE_END:


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


;--- Routine 1: return information about the Z280 system
;    Input:  A = 1
;            B = Information block to return, only block 0 supported for now
;                The output when specifying an invalid block number is undefined
;    Output: A = Flags:
;                bit 0: 0 for Z280-on-demand system, 1 for native Z280 system
;            HL = Size of Z280 RAM in KB

FN_Z280INFO:
    xor a
    ld hl,1024 ;TODO: Actually calculate the Z280RAM size
    ret


;--- Routine 2: reinitialize the Z280 control registers and MMU mappings
;    Input: -
;    Output: -

FN_INITZ280:
    ld a,1
    call CHGCPU.RUN

    call Z280.INIT

    xor a
    jp CHGCPU.RUN


;--- Routine 3: copy data from the MSX memory to ZTPA
;    Input: HL = source address in MSX memory
;           DE = destination address in ZTPA
;           BC = length
;           Source data must be in the MSX TPA
;           (default mapped segments in the primary RAM slot)

FN_COPY_MSX_TO_Z280:

    ;We'll use the entire page 1 to map the source
    ;and the 4K page B000-BFFF to map the destination.

    ;--- If RAM is already visible in page 1, just do the copy.
    ;    Otherwise save current page 1 slot, switch RAM, do the copy, and restore slot.

    push hl
    push de
    push bc
    call GETSLT1
    cp RAM_SLOT
    jr z,.POP_DO_COPY

    push af
    ld a,RAM_SLOT
    ld h,40h
    call ENASLT
    pop af
    pop bc
    pop de
    pop hl
    push af
    call .DO_COPY
    pop af
    ld h,40h
    jp ENASLT

.POP_DO_COPY:
    pop bc
    pop de
    pop hl

    ;--- Here we assume that the MSX RAM slot is mapped to page 1.
    ;    Let's switch the appropriate TPA segment.

.DO_COPY:
    push bc

    ld b,3  ;TPA segment in page 0
    ld a,h
    and 11000000b
    jr z,.GOT_SEGMENT   ;Page 0?
    dec b
    cp 01000000b    ;Page 1?
    jr z,.GOT_SEGMENT
    dec b
    cp 10000000b    ;Page 2?
    jr z,.GOT_SEGMENT
    dec b   ;Page 3

.GOT_SEGMENT:
    ;Here B = source RAM segment
    ld a,b
    out (0FDh),a
    ld ixh,a    ;Save RAM segment number for later

    res 7,h ;Force source address to be in page 1
    set 6,h

    ld a,1
    call CHGCPU.RUN

    .cpu z280

    ld a,16 + 0B000h/1000h  ;+16 because system page descriptors go after the 16 user page descriptors
    ifdef FAKE_Z280
        nop
        nop
        nop
    else
        out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a
    endif
    ld c,Z280.MMU_PORTS.DESCRIPTOR_SELECT

    push hl
    ld h,0   ;Convert address to 4K segment number
    ld a,d
    and 11110000b
    ld l,a
    ifdef FAKE_Z280
        nop
        nop
        nop
    else
        addw hl,RESIDENT_CODE_START_ADDRESS ;Convert to a ZTPA address
        outw (c),hl
    endif
    pop hl

    xor a
    call CHGCPU.RUN

    .cpu z80

    ld a,d  ;Force destination address to be in the 4K page starting at B000
    and 00001111b
    or 0B0h
    ld d,a

.COPY_LOOP_STEP:

    ;--- If source address+length goes beyond page 1, reduce the size to be copied in one go.
    ;    Likewise if destination address+length goes beyond page 2.

    pop bc
    push bc

    push hl
    add hl,bc
    dec hl
    ld a,h
    cp 80h
    jr c,.OK_REDUCE_1
    
    pop bc  ;Source address
    push bc
    ld hl,8000h
    or a
    sbc hl,bc
    push hl
    pop bc

.OK_REDUCE_1:
    push de
    pop hl
    add hl,bc
    dec hl
    ld a,h
    cp 0C0h
    jr c,.OK_REDUCE_2

    ld hl,0C000h
    or a
    sbc hl,de
    push hl
    pop bc

.OK_REDUCE_2:
    pop hl

    ; Here HL = Source in page 1, DE = Destination at 4K page B000, BC = length to copy in one go

    ld a,1
    call CHGCPU.RUN

    push bc
    ifdef FAKE_Z280
        nop
        nop
        nop
        add hl,bc
        ex de,hl
        add hl,bc
        ex de,hl
        ld bc,0
    else
        ldir
    endif
    pop bc

    xor a
    call CHGCPU.RUN

    ;--- Update remaining length to copy, if it's 0 we're done

    ex (sp),hl  ;Now HL = original length, source address after the copy in the stack
    
    or a
    sbc hl,bc
    ld a,h
    or l
    jr z,.COPY_END

    ex (sp),hl  ;Now HL = source address after copy, remaining length in stack

    ;--- If source address went beyond page 1, reset it to beginning of page 1
    ;    and update the RAM segment number.

    ld a,h
    cp 80h
    jr c,.OK_UPDATE_SRC

    ld a,ixh
    dec a
    out (0FDh),a
    ld ixh,a
    ld hl,4000h
.OK_UPDATE_SRC:

    ;--- If destination address went beyond page 2, reset it to B000
    ;    and update the value of the page descriptor.

    ld a,d
    cp 0C0h
    jr c,.OK_UPDATE_DEST

    push hl

    ld a,1
    call CHGCPU.RUN

    .cpu z280

    ld a,16 + 0B000h/1000h  ;+16 because system page descriptors go after the 16 user page descriptors
    ifdef FAKE_Z280
        nop
        nop
        nop
    else
        out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a
    endif
    ld c,Z280.MMU_PORTS.DESCRIPTOR_SELECT
    ifdef FAKE_Z280
        nop
        nop
        nop
    else
        inw hl,(c)
        addw hl,0010h
        outw (c),hl
    endif

    xor a
    call CHGCPU.RUN

    pop hl
    ld de,0B000h

    .cpu z80

.OK_UPDATE_DEST:

    ;--- Proceed with the copy of the next block

    jr .COPY_LOOP_STEP

    ;--- Jump here once all the data has been copied

.COPY_END:
    pop hl

    ;Restore Z280 resident code at B000

    ld a,1
    call CHGCPU.RUN

    .cpu z280

    ifdef FAKE_Z280
        nop
        nop
        nop
    else
        ld a,16 + 0B000h/1000h
        out (Z280.MMU_PORTS.PAGE_DESCRIPTOR),a
        ld hl,RESIDENT_CODE_START_ADDRESS + 0010h
        ld c,Z280.MMU_PORTS.DESCRIPTOR_SELECT
        outw (c),hl
    endif

    .cpu z80

    ;Restore TPA segment in page 1

    ld a,2
    out (0FDh),a

    ret


;--- Routine 4: copy data from the Z280 memory to MSX memory
;    Input: HL = source address in Z280 memory
;           DE = destination address in MSX memory
;           BC = length
;           The values for HL and HL+BC-1 must be in the same 4K page range

FN_COPY_Z280_TO_MSX:
    ;TODO: Implement this thing!
    ret


;--- Routine 5: run a Z280 program in MSX memory
;    Input: All registers as they will be accepted by the Z280 program
;           Program address at TEMP9 (F7B8h)
;           AF for the program at TEMP8 (F69Fh)
;    Output: All registers as returned by the Z280 program

FN_RUNZ280_MSX:
    ;TODO: Implement this thing!
    ret


;--- Routine 6: run a Z280 program in Z280 memory
;    Input: All registers as they will be accepted by the Z280 program
;           Program address at TEMP9 (F7B8h)
;           AF for the program at TEMP8 (F69Fh)
;           Z280 RAM page id at TEMP3 (F69Dh)
;    Output: All registers as returned by the Z280 program

FN_RUNZ280_Z280:
    ;TODO: Implement this thing!
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

