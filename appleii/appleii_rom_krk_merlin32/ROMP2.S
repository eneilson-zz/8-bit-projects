* APPLE IIE ROM PATCH FOR BREAKING INTO DEBUGGER
* PART 2: THIS ROUTINE REPLACES THE SELF-TEST
* ROM CODE AND STARTS AT $C600.
* WHEN INVOKED THE USER CAN
* PRESS EITHER ESC OR SPC.
* ESC-GO DIRECTLY TO MONITOR
* SPC-COPY MEMORY LOCATIONS $0000-$08FF
*    TO $2000-$2FFF THEN JUMP TO MONITOR
* ANY OTHER KEY - PROCEED NORMALLY
* CALLED FROM $FECD WHEN RESET IS PRESSED
* THANKS TO THE COMPUTIST MAGAZINE (ISSUE #6)
* AND KRAKOWITZ TEXT FILES FOR THE INSPIRATION

A1L         EQU   $003C       ;LSB ADDRESS
A1H         EQU   $003D       ;MSB ADDRESS
A2L         EQU   $003E       ;LSB OF ADDRESS 2
A2H         EQU   $003F       ;MSB OF ADDRESS 2
A4L         EQU   $0042       ;LSB OF ADDRESS 4
A4H         EQU   $0043       ;MSB OF ADDRESS 4
MONMOVE     EQU   $FE2C       ;MONITOR MOVE ROUTINE
HME         EQU   $FC58       ;CLEARS TEXT SCREEN
TXT         EQU   $FB2F       ;SELECTS TEXT SCREEN
MONEXIT     EQU   $FECD       ;PART 3 AND TAPE WRITE SECTION
KEYBD       EQU   $C000       ;KEYBOARD
NORMAL      EQU   $FF03       ;EXIT LCOATION IN PART 1
            TYP   BIN
            DSK   ROMP2
            ORG   $C600       ;LOCATE IN SELF-TEST SECITON OF MEM
START       PHA               ;SAVE ACCUMULATOR
LOOP        LDA   KEYBD       ;LOOK AT KEYBOARD
            BPL   LOOP        ;KEEP READING UNTIL A KEY PRESSED
            CMP   #$A0        ;WAS SPC PRESSED?
            BEQ   CPY         ;YES, START MEM COPY
            CMP   #$9B        ;WAS ESC PRESSED?
            BEQ   END         ;YES, JUMP STRAIGHT TO MONITOR
            PLA               ;RESTORE ACCUMULATOR
            JMP   NORMAL      ;BACK TO PART 1 FOR PASSTHROUGH
CPY         PLA               ;RESTORE ACCUMULATOR
            STA   $2902       ;SAVE REGISTERS
            STX   $2903
            STY   $2904
            TSX
            STX   $2901
            LDY   #0          ;START WITH BYTE 0
SAVE1       LDA   0,Y         ;GET A ZERO PAGE BYTE
            STA   $2000,Y     ;SAVE IT
            LDA   $100,Y      ;GET A STACK BYTE
            STA   $2100,Y     ;SAVE IT
            INY
            BNE   SAVE1       ;IF NOT DONE, MOVE ANOTHER BYTE
            STY   A1L         ;MSB FROM ADDRESS IS 0
            STY   A4L         ;MSB OF THE TO ADDRESS IS 0
            STY   A2L         ;MOVE CODE THROUGH $900
            LDA   #9
            STA   A2H
            LDA   #2          ;MOVE CODE STARTING AT $200
            STA   A1H
            LDA   #$22        ;MOVE CODE INTO PAGE 22
            STA   A4H
            JSR   MONMOVE
            JSR   TXT
            JSR   HME
            PHA
END         PLA               ;RESTORE ACCUMULATOR
            JMP   MONEXIT     ;JUMP TO PART 3 AND EXIT TO MON


