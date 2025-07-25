    title Tides Rider BIOS with Z280 support
    subttl First part of the Z280 resident code

    name('Z280_RESIDENT')

.COMMENT \

This file contains the first part of the Z280 resident code, containing:

- The interrupt/trap vector table
- The default exception handler (shows a "blue screen of death")
- The data area

This code must be linked at address A000h (it will be run by the Z280 from that address)
and also must be placed at address A000h in the ROM (it will be copied to the Z280 RAM from that address).

Specific exception handlers are located in separate files which are to be linked right after this one
(and placed consecutively after this one in the ROM too).

\
    public Z280.RESIDENT_CODE
    extrn PRINT
    extrn CHGCPU.RUN
    extrn CHGCPU.CONTINUE

    .extroot

    module Z280

    include "msx.inc"

DEFAULT_MSR: equ 0 ;Run in system mode, disable breakpoint-on-halt and single-step, disable all interrupts

VECTOR_ENTRY: macro name,msr
    ifb <name>
    db 0,0,0,0 ;Reserved entry
    else
    ifb <msr>
    dw DEFAULT_MSR
    else
    dw msr
    endif
    dw HANDLE_&name
    endif
    endm

    .cpu Z280

RESIDENT_CODE:


    ;--- Interrupt/trap vector table

    VECTOR_ENTRY
    VECTOR_ENTRY NMI
    VECTOR_ENTRY INT_A
    VECTOR_ENTRY INT_B
    VECTOR_ENTRY INT_C
    VECTOR_ENTRY COUNTER_TIMER_0
    VECTOR_ENTRY COUNTER_TIMER_1
    VECTOR_ENTRY
    VECTOR_ENTRY COUNTER_TIMER_2
    VECTOR_ENTRY DMA_0
    VECTOR_ENTRY DMA_1
    VECTOR_ENTRY DMA_2
    VECTOR_ENTRY DMA_3
    VECTOR_ENTRY UART_RX
    VECTOR_ENTRY UART_TX
    VECTOR_ENTRY SINGLE_STEP
    VECTOR_ENTRY BP_ON_HALT
    VECTOR_ENTRY DIVISION
    VECTOR_ENTRY STACK_OVERFLOW
    VECTOR_ENTRY ACCESS_VIOLATION
    VECTOR_ENTRY SYSTEM_CALL
    VECTOR_ENTRY PRIVILEGED_INSTR
    VECTOR_ENTRY MEM_TO_EPU
    VECTOR_ENTRY EPU_TO_MEM
    VECTOR_ENTRY EPU_TO_A
    VECTOR_ENTRY EPU_INTERNAL
    VECTOR_ENTRY
    VECTOR_ENTRY
    rept 300h
    db 0 ;PC values for vectored interrupts
    endm


    ;--- Interrupt/trap primary handlers:
    ;    Call the custom handlers and if these just return, jump to the default handler.

EXCEPTION_HANDLER: macro name,string
HANDLE_&name:
    call TRY_HANDLE_&name
    push hl
    ld hl,&name&_S
    ld (EXCEPTION_NAME_ADDRESS),hl
    pop hl
    jp DEFAULT_HANDLER

&name&_S: db "&string",0
    endm

    EXCEPTION_HANDLER NMI,NMI
    EXCEPTION_HANDLER INT_A,Interrupt! A
    EXCEPTION_HANDLER INT_B,Interrupt! B
    EXCEPTION_HANDLER INT_C,Interrupt! C
    EXCEPTION_HANDLER COUNTER_TIMER_0,Counter/Timer! 0
    EXCEPTION_HANDLER COUNTER_TIMER_1,Counter/Timer! 1
    EXCEPTION_HANDLER COUNTER_TIMER_2,Counter/Timer! 2
    EXCEPTION_HANDLER DMA_0,DMA! channel! 0
    EXCEPTION_HANDLER DMA_1,DMA! channel! 1
    EXCEPTION_HANDLER DMA_2,DMA! channel! 2
    EXCEPTION_HANDLER DMA_3,DMA! channel! 3
    EXCEPTION_HANDLER UART_RX,UART! receiver
    EXCEPTION_HANDLER UART_TX,UART! transmitter
    EXCEPTION_HANDLER SINGLE_STEP,Single! Step
    EXCEPTION_HANDLER BP_ON_HALT,Breakpoint! on! HALT
    EXCEPTION_HANDLER DIVISION,Division! exception
    EXCEPTION_HANDLER STACK_OVERFLOW,Stack! overflow! warning
    EXCEPTION_HANDLER ACCESS_VIOLATION,Access! violation
    EXCEPTION_HANDLER SYSTEM_CALL,System! call
    EXCEPTION_HANDLER PRIVILEGED_INSTR,Privileged! instruction
    EXCEPTION_HANDLER MEM_TO_EPU,Memory! to! EPU
    EXCEPTION_HANDLER EPU_TO_MEM,EPU! to! memory
    EXCEPTION_HANDLER EPU_TO_A,EPU! to! A
    EXCEPTION_HANDLER EPU_INTERNAL,EPU! internal! operation


    ;--- Default exception handler: show an error message and halt

DEFAULT_HANDLER:
    di

    ld (0FFFDh),sp

    push af
    push hl

    ;Enable BIOS in page 0

    in a,(0A8h)
    and 11111100b
    out (0A8h),a

    ;Set text mode

    ld a,80
    ld (LINL40),a   ;TODO: Set TXTNAM and TXTCGP too, just in case
    ld ix,INITXT
    call EXTROM

    ;Print message

    ld hl,UHNANDLED_S
    call PRINT
    ld hl,(EXCEPTION_NAME_ADDRESS)
    call PRINT

    pop hl
    pop af

    ;TODO: Show registers, MMU descriptors, stack dump

    di
    halt

UHNANDLED_S:
    db "Unhandled exception: ",0


    ;--- Custom exception handlers.
    ;    If they can handle the exception, they should POP the return value
    ;    from the stack and then execute RETIL.
    ;    If they can't, they should just RET with registers unchanged.

    ;TODO: Develop the handlers in separate files, for now all of them will fail.

TRY_HANDLE_NMI:
TRY_HANDLE_INT_B:
TRY_HANDLE_INT_C:
TRY_HANDLE_COUNTER_TIMER_0:
TRY_HANDLE_COUNTER_TIMER_1:
TRY_HANDLE_COUNTER_TIMER_2:
TRY_HANDLE_DMA_0:
TRY_HANDLE_DMA_1:
TRY_HANDLE_DMA_2:
TRY_HANDLE_DMA_3:
TRY_HANDLE_UART_RX:
TRY_HANDLE_UART_TX:
TRY_HANDLE_SINGLE_STEP:
TRY_HANDLE_BP_ON_HALT:
TRY_HANDLE_DIVISION:
TRY_HANDLE_STACK_OVERFLOW:
TRY_HANDLE_ACCESS_VIOLATION:
TRY_HANDLE_PRIVILEGED_INSTR:
TRY_HANDLE_MEM_TO_EPU:
TRY_HANDLE_EPU_TO_MEM:
TRY_HANDLE_EPU_TO_A:
TRY_HANDLE_EPU_INTERNAL:

    ret


TRY_HANDLE_SYSTEM_CALL:
    ;TODO: Implement. For now just return the argument in HL.
    pop hl
    retil


TRY_HANDLE_INT_A:
    ;TODO: set Z80 CPU, call custom handlers, call 0038h, restore Z280, return.

    inc sp
    inc sp
    call 0038h
    retil


    ;--- Variables area

EXCEPTION_NAME_ADDRESS: dw 0

    endmod

    end
