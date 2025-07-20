    title Tides Rider BIOS with Z280 support
    subttl Dummy byte at the end of the ROM

    ;Dummy byte to be used in the linking process
    ;to pad the ROM size to 16K.
    ;This file must be the last one linked, and at address BFFFh.

    db 0FFh

    end
