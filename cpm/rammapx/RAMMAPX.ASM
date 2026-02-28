;
;                              RAMMAPX.ASM
;
;       Simple program to display key memory locations for CP/M 2.2
;
;                            David L. Ransen
;                               03/25/83
;
;            TPA size extension added by Eric C. Neilson 2026
;
;       Adapted from Jack Dennon, in "CP/M Revealed," Hayden 1982.
;
;Change Log:
;2026-06-01  Eric C. Neilson
;       - Added TPA size calculation and display in KB with one decimal place.
;       - Used K=1024 for TPA size calculation, as is standard, rather than 1000.
;
        ORG     100H
BDOS    EQU     5
GETVER  EQU     12
CONIN   EQU     1
CONOUT  EQU     2
PRSTR   EQU     9
CR      EQU     0DH
LF      EQU     0AH
ESC     EQU     1BH
;
START:  LXI     H,0
        DAD     SP
        SHLD    OLDSP
        LXI     SP,STACK
;
MMP1:   SHLD    MMPA
;
        LHLD    6               ; GET BDOS ENTRY ADDRESS
        SHLD    BDOSE
        LXI     B,-806H         ; COMPUTE CCP BASE ADDRESS
        DAD     B
        SHLD    CCPFWA
;
        DCX     H
        SHLD    TPALWA          ; COMPUTE TPA LAST WORD ADDRESS
        INX     H
;
        LXI     B,800H          ; COMPUTE BDOS FIRST WORD ADDRESS
        DAD     B
        SHLD    BDFWA
        LXI     B,6             ; COMPUTE BDOS ENTRY POINT
        DAD     B
        SHLD    BDOSE
;
        LXI     B,0
MMPA:   EQU     $-2
        DAD     B
        SHLD    CBFWA           ; CBIOS FIRST WORD ADDRESS
;
        LXI     B,3             ; CBIOS WARM BOOT ENTRY POINT
        DAD     B
        SHLD    WRMBT
;
;       DISPLAY MEMORY LOCATIONS
;
        LXI     D,CLRSC
        CALL    PRMSG           ; CLEAR SCREEN (CURRENTLY FOR H/Z-19)
;
        LXI     D,MMPB          ; PRINT DASHES
        CALL    PRMSG
        LXI     D,MMPC          ; PRINT CONSTANTS
        CALL    PRMSG
;
        LXI     H,0
TPALWA: EQU     $-2             ; DISPLAY TPA LWA
        CALL    DHW
        LXI     D,MMPD
        CALL    PRMSG
;
        LXI     H,0
CCPFWA: EQU     $-2             ;DISPLAY CCP FWA
        CALL    DHW
        LXI     D,MMPE
        CALL    PRMSG
;
        LXI     H,0
BDFWA:  EQU     $-2             ; DISPLAY BDOS FWA
        CALL    DHW
        LXI     D,MMPF
        CALL    PRMSG
;
        LXI     H,0
BDOSE:  EQU     $-2             ; DISPLAY BDOS ENTRY POINT
        CALL    DHW
        LXI     D,MMPG
        CALL    PRMSG
;
        LXI     H,0             ; DISPLAY CBIOS FWA
CBFWA:  EQU     $-2
        CALL    DHW
        LXI     D,MMPH
        CALL    PRMSG
;
        LXI     H,0
WRMBT:  EQU     $-2             ; DISPLAY WARMBOOT ENTRY POINT
        CALL    DHW
        LXI     D,MMPI
        CALL    PRMSG
;
        LXI     D,MMPJ          ; DASHES (SINGLE NEWLINE)
        CALL    PRMSG
;
;       DISPLAY TPA SIZE
;
        LXI     D,TPAMSG
        CALL    PRMSG
        LHLD    6               ; GET BDOS ENTRY ADDRESS
        LXI     D,0FF00H        ; SUBTRACT 100H (TPA BASE)
        DAD     D               ; HL = TPA SIZE IN BYTES
;
;       CONVERT TO XX.Xk FORMAT (K=1024) WITH ROUNDING
;
        LXI     D,1024
        CALL    DIV16           ; BC = INTEGER K, HL = REMAINDER (0-1023)
        PUSH    B               ; SAVE INTEGER K
;
;       TENTHS DIGIT = REMAINDER * 10 / 1024
;
        MOV     B,H
        MOV     C,L             ; BC = REMAINDER
        DAD     H               ; HL = REM * 2
        DAD     H               ; HL = REM * 4
        DAD     B               ; HL = REM * 5
        DAD     H               ; HL = REM * 10
        LXI     D,1024
        CALL    DIV16           ; BC = TENTHS (0-9), HL = SUB-REMAINDER
;
;       ROUND IF SUB-REMAINDER >= 512
;
        MOV     A,H
        CPI     2
        JC      NORND           ; SUB-REMAINDER < 512, NO ROUND
        INX     B               ; ROUND UP TENTHS
NORND:  MOV     A,C             ; A = TENTHS DIGIT
        POP     H               ; HL = INTEGER K
        CPI     10
        JC      NOCRY           ; TENTHS < 10, OK
        XRA     A               ; TENTHS = 0, CARRY INTO INTEGER
        INX     H
NOCRY:  PUSH    PSW             ; SAVE TENTHS DIGIT
        CALL    PDEC            ; PRINT INTEGER K
        MVI     A,'.'
        CALL    DCH             ; PRINT DECIMAL POINT
        POP     PSW             ; RESTORE TENTHS DIGIT
        ADI     '0'
        CALL    DCH             ; PRINT TENTHS DIGIT
        LXI     D,TPAK
        CALL    PRMSG
        LXI     D,MMPB          ; FINAL DASHES
        CALL    PRMSG
;
        LHLD    OLDSP
        SPHL
        RET
;
;
CLRSC:  DB      ESC,'E'        ; FOR H/Z-19
        DB      CR,LF,LF,'     CP/M 2.2 Key Memory Locations      ',CR,LF,LF,'$'
MMPB:   DB      '----------------------------------------',CR,LF,LF,'$'
MMPC:   DB      '0000  warm boot vector',CR,LF
        DB      '0005  BDOS vector',CR,LF
        DB      '005C  default FCB',CR,LF
        DB      '0080  CP/M record buffer',CR,LF
        DB      '0100  base (FWA) of TPA',CR,LF,'$'
MMPD:   DB      '  Last  Word Address of TPA',CR,LF,'$'
MMPE:   DB      '  CCP   base (FWA)',CR,LF,'$'
MMPF:   DB      '  BDOS  base (FWA)',CR,LF,'$'
MMPG:   DB      '  BDOS  entry point',CR,LF,'$'
MMPH:   DB      '  CBIOS base (FWA)',CR,LF,'$'
MMPI:   DB      '  CBIOS warm boot entry point',CR,LF,'$'
MMPJ:   DB      '----------------------------------------',CR,LF,'$'
TPAMSG: DB      'TPA size is $'
TPAK:   DB      'k',CR,LF,'$'
;
;       DHW -- DISPLAY HEX WORD
;              ENTRY: HL = WORD TO BE DISPLAYED
;
DHW:    PUSH    H
        MOV     A,H             ; DISPLAY HIGH BYTE
        CALL    DHB
        POP     H
        MOV     A,L             ; DISPLAY LOW BYTE
;
;       DHB --  DISPLAY HEX BYTE
;               DISPLAY 2 HEX DIGITS
;               ENTRY: A = BYTE TO BE DISPLAYED
;
DHB:    PUSH    PSW
        RRC
        RRC
        RRC
        RRC
        CALL    DHD
        POP     PSW
;
;       DHD --  DISPLAY HEX DIGIT
;               ENTRY: A, LOW 4 BITS = DIGIT
;
DHD:    ANI     0FH
        CPI     10
        JNC     DHD1            ; IF NOT ASCII 0 THRU 9
;
        ADI     '0'
        JMP     DCH
;
DHD1:   ADI     'A'-10          ; CREATE "A, B, C, D, E, OR F"
;
;       DCH --  DISPLAY ONE CHARACTER
;               ENTRY: A = ASCII CHAR
;
DCH:    MOV     E,A
        MVI     C,CONOUT
        CALL    BDOS
        RET
;
;       PDEC -- PRINT 16-BIT DECIMAL NUMBER
;               ENTRY: HL = NUMBER TO PRINT
;               LEADING ZEROS ARE SUPPRESSED
;
PDEC:   PUSH    PSW
        PUSH    B
        PUSH    D
        PUSH    H
        XRA     A
        STA     LZSUP           ; CLEAR LEADING ZERO FLAG
        LXI     D,10000
        CALL    PDIV
        LXI     D,1000
        CALL    PDIV
        LXI     D,100
        CALL    PDIV
        LXI     D,10
        CALL    PDIV
        MOV     A,L             ; ONES DIGIT (ALWAYS PRINT)
        ADI     '0'
        CALL    DCH
        POP     H
        POP     D
        POP     B
        POP     PSW
        RET
;
;       PDIV -- DIVIDE HL BY DE, PRINT QUOTIENT DIGIT
;               ENTRY: HL = DIVIDEND, DE = DIVISOR
;               EXIT:  HL = REMAINDER
;
PDIV:   MVI     C,0             ; QUOTIENT = 0
PDIV1:  MOV     A,L
        SUB     E
        MOV     L,A
        MOV     A,H
        SBB     D
        MOV     H,A
        JC      PDIV2           ; WENT NEGATIVE, DONE
        INR     C
        JMP     PDIV1
PDIV2:  MOV     A,L             ; ADD BACK DIVISOR
        ADD     E
        MOV     L,A
        MOV     A,H
        ADC     D
        MOV     H,A
        MOV     A,C             ; GET QUOTIENT DIGIT
        ORA     A
        JNZ     PDIV3           ; NON-ZERO, PRINT IT
        LDA     LZSUP           ; ZERO DIGIT, CHECK FLAG
        ORA     A
        RZ                      ; STILL SUPPRESSING, SKIP
PDIV3:  MVI     A,1
        STA     LZSUP           ; STOP SUPPRESSING
        MOV     A,C
        ADI     '0'
        PUSH    H               ; SAVE REMAINDER
        CALL    DCH
        POP     H               ; RESTORE REMAINDER
        RET
;
;       DIV16 -- 16-BIT UNSIGNED DIVISION
;                ENTRY: HL = DIVIDEND, DE = DIVISOR
;                EXIT:  BC = QUOTIENT, HL = REMAINDER
;
DIV16:  LXI     B,0             ; QUOTIENT = 0
DIV1:   MOV     A,L
        SUB     E
        MOV     L,A
        MOV     A,H
        SBB     D
        MOV     H,A
        JC      DIV2            ; WENT NEGATIVE, DONE
        INX     B
        JMP     DIV1
DIV2:   MOV     A,L             ; ADD BACK DIVISOR
        ADD     E
        MOV     L,A
        MOV     A,H
        ADC     D
        MOV     H,A
        RET
;
;       FCC --  FILTER OUT CONTROL CODES
;               ENTRY: A = ASCII CODE
;               EXIT:  B = ASCII CHAR
;                      A = UP-ARROW IF CONTROL CODE
;                        = OR BLANK IF NOT
;
FCC:    CPI     20H
        JNC     FCC1            ; IF NOT A CONTROL CODE
;
        ADI     40H             ; MUST BE A CONTROL CODE
        MOV     B,A
        MVI     A,5EH           ; UP-ARROW
        RET
FCC1:   MOV     B,A
        MVI     A,20H
        RET
;
PRMSG:  MVI     C,PRSTR
        CALL    BDOS
        RET
;
RCC:    MVI     C,CONIN
        CALL    BDOS
        RET
;
LZSUP:  DS      1
OLDSP:  DS      2
        DS      34
STACK:
        END
