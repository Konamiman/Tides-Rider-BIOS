    title Tides Rider BIOS with Z280 support
    subttl ROM header

.COMMENT \

The Tides Rider BIOS is a ROM intended to be flashed in page 2 of slot 0.
It provides code that handles the Balrog Z280 cartridge, and an implementation
of the MSX280 UNAPI specification.

This file is the ROM header and must be the first one specified in the linking process,
starting at address 8000h.

\

    extrn BOOT.RUN

    ifdef DEBUGGING
        extrn UNAPI.ENTRY_POINT
        extrn UNAPI.FN_COPY_MSX_TO_Z280
    endif
    
ROM_HEADER:
    db 41h,42h
    ifdef DEBUGGING
        dw _8010
    else
        dw BOOT.RUN
    endif
    dw 0 ;STATEMENT handler
    dw 0 ;DEVICE handler
    dw 0 ;TEXT handler
    ds 6,0 ;Reserved

    ifdef DEBUGGING
_8010: jp BOOT.RUN
_8013: jp UNAPI.FN_COPY_MSX_TO_Z280
    endif

    end
