    extrn BOOT.RUN
    
ROM_HEADER:
    db 41h,42h
    dw BOOT.RUN
    dw 0 ;STATEMENT handler
    dw 0 ;DEVICE handler
    dw 0 ;TEXT handler
    ds 6,0 ;Reserved

    end
