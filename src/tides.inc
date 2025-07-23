; Include file with constants related to the Tides Rider

    ifndef RAM_SLOT
RAM_SLOT: equ 10001011b
    endif

RAM_SLOT_SLTWRK: equ 0FD09h + (RAM_SLOT and 11b)*4*8 + ((RAM_SLOT AND 1100b) SHR 2)*8

OLD_EXTBIO_PNT: equ RAM_SLOT_SLTWRK
UNAPI_P3_ENTRY_PNT: equ RAM_SLOT_SLTWRK+2
UNAPI_NAME_PNT: equ RAM_SLOT_SLTWRK+4

    ifndef Z280.RESIDENT_CODE_START_ADDRESS
    ;Note that the Z280 RAM starts at address 010000,
    ;but the first 64K are for the BIOS shadowing
    ;so the first actual usable address is 020000.
RESIDENT_CODE_START_ADDRESS: equ 0200h ;Bits 23 to 12 (11 to 0 are always 0)
    endif

ZTPA_START_ADDRESS: equ RESIDENT_CODE_START_ADDRESS + 0020h
