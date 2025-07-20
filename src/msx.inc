; Include filw tih constans for the MSX BIOS and work area


;--- MSX BIOS

CHPUT: equ 00A2h
INITXT: equ 00D5h
EXTROM: equ 015Fh


;--- MSX work area

LINL40: equ 0F3AEh
ARG:  equ  0F847h
HOKVLD:  equ  0FB20h
HIMEM: equ 0FC4Ah
EXPTBL:  equ  0FCC1h
SLTTBL: equ 0FCC5h
SLTWRK:  equ  0FD09h
H.CLEA  EQU     0FED0h
H.LOPD	EQU	0FED5H
H_STKE: equ 0FEDAh
EXTBIO: equ 0FFCAh
H.PHYD	EQU	0FFA7h
