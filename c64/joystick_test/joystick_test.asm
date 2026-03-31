// ============================================================
// joystick_test.asm  --  C64 Joystick Input Tester
// KickAssembler.  Load with LOAD"*",8,1 then RUN.
//
// C64 joystick bits (active-low):
//   Port 2 -> CIA1 Port A $DC00  (labeled "Joystick 2")
//   Port 1 -> CIA1 Port B $DC01  (labeled "Joystick 1")
//   Bit 0=Up  Bit 1=Down  Bit 2=Left  Bit 3=Right  Bit 4=Fire
//
// Static labels are drawn once.  At runtime only COLOR RAM
// is updated to highlight active directions/fire.
//
// Grid layout (each panel, rows 2 apart, cols 5 apart):
//   UL    U    UR    (row GR_TOP, cols +0 +5 +10)
//   L     *    R     (row GR_MID, cols +0 +5 +10)
//   DL    D    DR    (row GR_BOT, cols +0 +5 +10)
//   fire button      (row GR_FIRE)
//
// Press RUN/STOP to exit.
// ============================================================

BasicUpstart2(main)

.const CIA1_PRA  = $DC00
.const CIA1_PRB  = $DC01
.const SCRBASE   = $0400
.const COLBASE   = $D800
.const VICBORDER = $D020
.const VICBG     = $D021

.const BLACK   = 0
.const WHITE   = 1
.const RED     = 2
.const CYAN    = 3
.const PURPLE  = 4
.const GREEN   = 5
.const BLUE    = 6
.const YELLOW  = 7
.const ORANGE  = 8
.const BROWN   = 9
.const LTRED   = 10
.const DKGRAY  = 11
.const MDGRAY  = 12
.const LTGREEN = 13
.const LTBLUE  = 14
.const LTGRAY  = 15

.const COLS    = 40
.const ZPT     = $FB

// Panel left edges
.const J1C = 2
.const J2C = 22

// Grid col offsets within panel
.const GC_L = 0    // left column:   UL / L / DL
.const GC_M = 5    // middle column:  U / * / D
.const GC_R = 9    // right column:  UR / R / DR (2-char labels at 9-10)

// Grid rows
.const GR_TOP  = 5
.const GR_MID  = 7
.const GR_BOT  = 9
.const GR_FIRE = 11

// Bit display row
.const ROW_BITS = 14

// Highlight colors
.const COL_ON       = LTGREEN  // active direction
.const COL_OFF      = DKGRAY   // inactive direction
.const COL_CTR      = MDGRAY   // centre * always dim
.const COL_FIRE_ON  = LTRED    // fire active
.const COL_FIRE_OFF = DKGRAY   // fire inactive

// ============================================================
* = $0801
* = $0900
main:
    jsr init_screen
loop:
    // Check RUN/STOP (keyboard matrix col 7, row 7)
    lda #%01111111
    sta CIA1_PRA
    lda CIA1_PRB
    and #%10000000
    beq exit_pgm

    lda #$FF
    sta CIA1_PRA

    lda CIA1_PRA        // Joy2 on port A
    sta v_joy2
    lda CIA1_PRB        // Joy1 on port B
    sta v_joy1

    lda v_joy1
    jsr color_joy1
    lda v_joy2
    jsr color_joy2

    lda v_joy1
    jsr print_bits_j1
    lda v_joy2
    jsr print_bits_j2

    jmp loop

exit_pgm:
    lda #$FF
    sta CIA1_PRA
    jmp $FCE2       // C64 KERNAL cold reset

// ============================================================
// color_joy1 / color_joy2
// A = raw CIA byte.  Only write to COLOR RAM — chars stay.
// Diagonals active only when both constituent dirs pressed.
// ============================================================

// Helper: returns COL_ON in A if masked bits all zero, else COL_OFF
active_col:
    bne ac_off
    lda #COL_ON
    rts
ac_off:
    lda #COL_OFF
    rts

color_joy1:
    sta ZPT

    // UL (bits 2+0)
    lda ZPT
    and #%00000101
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J1C + GC_L
    sta COLBASE + GR_TOP*COLS + J1C + GC_L + 1  // 2nd char of "ul"

    // U (bit 0)
    lda ZPT
    and #%00000001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J1C + GC_M

    // UR (bits 3+0)
    lda ZPT
    and #%00001001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J1C + GC_R
    sta COLBASE + GR_TOP*COLS + J1C + GC_R + 1  // 2nd char of "ur"

    // L (bit 2)
    lda ZPT
    and #%00000100
    jsr active_col
    sta COLBASE + GR_MID*COLS + J1C + GC_L

    // R (bit 3)
    lda ZPT
    and #%00001000
    jsr active_col
    sta COLBASE + GR_MID*COLS + J1C + GC_R

    // DL (bits 2+1)
    lda ZPT
    and #%00000110
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J1C + GC_L
    sta COLBASE + GR_BOT*COLS + J1C + GC_L + 1

    // D (bit 1)
    lda ZPT
    and #%00000010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J1C + GC_M

    // DR (bits 3+1)
    lda ZPT
    and #%00001010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J1C + GC_R
    sta COLBASE + GR_BOT*COLS + J1C + GC_R + 1

    // FIRE (bit 4): color all 11 chars of "fire button"
    lda ZPT
    and #%00010000
    bne cj1_fire_off
    lda #COL_FIRE_ON
    bne cj1_fire_set
cj1_fire_off:
    lda #COL_FIRE_OFF
cj1_fire_set:
    ldx #10
cj1_fire_loop:
    sta COLBASE + GR_FIRE*COLS + J1C, x
    dex
    bpl cj1_fire_loop
    rts

color_joy2:
    sta ZPT

    lda ZPT
    and #%00000101
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J2C + GC_L
    sta COLBASE + GR_TOP*COLS + J2C + GC_L + 1

    lda ZPT
    and #%00000001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J2C + GC_M

    lda ZPT
    and #%00001001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J2C + GC_R
    sta COLBASE + GR_TOP*COLS + J2C + GC_R + 1

    lda ZPT
    and #%00000100
    jsr active_col
    sta COLBASE + GR_MID*COLS + J2C + GC_L

    lda ZPT
    and #%00001000
    jsr active_col
    sta COLBASE + GR_MID*COLS + J2C + GC_R

    lda ZPT
    and #%00000110
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J2C + GC_L
    sta COLBASE + GR_BOT*COLS + J2C + GC_L + 1

    lda ZPT
    and #%00000010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J2C + GC_M

    lda ZPT
    and #%00001010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J2C + GC_R
    sta COLBASE + GR_BOT*COLS + J2C + GC_R + 1

    lda ZPT
    and #%00010000
    bne cj2_fire_off
    lda #COL_FIRE_ON
    bne cj2_fire_set
cj2_fire_off:
    lda #COL_FIRE_OFF
cj2_fire_set:
    ldx #10
cj2_fire_loop:
    sta COLBASE + GR_FIRE*COLS + J2C, x
    dex
    bpl cj2_fire_loop
    rts

// ============================================================
// print_bits_j1 / print_bits_j2
// Print 8 binary digits MSB-first on ROW_BITS.
//   J1 at col 5, J2 at col 25
// ============================================================
print_bits_j1:
    sta v_bits_tmp
    ldx #0
pb1_loop:
    asl v_bits_tmp
    bcc pb1_one
    lda #$30
    sta SCRBASE + ROW_BITS*COLS + 5, x
    lda #COL_OFF
    sta COLBASE + ROW_BITS*COLS + 5, x
    inx
    cpx #8
    bne pb1_loop
    rts
pb1_one:
    lda #$31
    sta SCRBASE + ROW_BITS*COLS + 5, x
    lda #COL_ON
    sta COLBASE + ROW_BITS*COLS + 5, x
    inx
    cpx #8
    bne pb1_loop
    rts

print_bits_j2:
    sta v_bits_tmp
    ldx #0
pb2_loop:
    asl v_bits_tmp
    bcc pb2_one
    lda #$30
    sta SCRBASE + ROW_BITS*COLS + 25, x
    lda #COL_OFF
    sta COLBASE + ROW_BITS*COLS + 25, x
    inx
    cpx #8
    bne pb2_loop
    rts
pb2_one:
    lda #$31
    sta SCRBASE + ROW_BITS*COLS + 25, x
    lda #COL_ON
    sta COLBASE + ROW_BITS*COLS + 25, x
    inx
    cpx #8
    bne pb2_loop
    rts

// ============================================================
// init_screen
// ============================================================
init_screen:
    lda #BLACK
    sta VICBORDER
    sta VICBG

    lda #$20
    ldx #$00
is_cs:
    sta SCRBASE+$000,x
    sta SCRBASE+$100,x
    sta SCRBASE+$200,x
    sta SCRBASE+$300,x
    inx
    bne is_cs

    lda #WHITE
    ldx #$00
is_cc:
    sta COLBASE+$000,x
    sta COLBASE+$100,x
    sta COLBASE+$200,x
    sta COLBASE+$300,x
    inx
    bne is_cc

    jsr draw_title
    jsr draw_headers
    jsr draw_grid_chars
    jsr draw_bit_labels
    jsr draw_exit_hint

    // Initialize colors to all-OFF
    lda #$FF
    jsr color_joy1
    lda #$FF
    jsr color_joy2
    lda #$FF
    jsr print_bits_j1
    lda #$FF
    jsr print_bits_j2
    rts

// ---- title --------------------------------------------------
draw_title:
    ldx #(title_e - title - 1)
dt_loop:
    lda title, x
    sta SCRBASE + 0*COLS + 7, x
    lda #YELLOW
    sta COLBASE + 0*COLS + 7, x
    dex
    bpl dt_loop
    rts
title:    .text "** c64 joystick tester **"
title_e:

// ---- panel headers ------------------------------------------
// Grid spans J1C+0..J1C+10 (centre +5) and J2C+0..J2C+10 (centre +5).
// "joystick 1" = 10 chars -> offset 0  (centre at char 5) -> J1C+0
// "(port 2)"   =  8 chars -> offset 1  (centre at char 4) -> J1C+1
draw_headers:
    ldx #(j1name_e - j1name - 1)
dh1_loop:
    lda j1name, x
    sta SCRBASE + 2*COLS + J1C + 0, x
    lda #LTBLUE
    sta COLBASE + 2*COLS + J1C + 0, x
    dex
    bpl dh1_loop

    ldx #(j1port_e - j1port - 1)
dh2_loop:
    lda j1port, x
    sta SCRBASE + 3*COLS + J1C + 1, x
    lda #LTBLUE
    sta COLBASE + 3*COLS + J1C + 1, x
    dex
    bpl dh2_loop

    ldx #(j2name_e - j2name - 1)
dh3_loop:
    lda j2name, x
    sta SCRBASE + 2*COLS + J2C + 0, x
    lda #LTGREEN
    sta COLBASE + 2*COLS + J2C + 0, x
    dex
    bpl dh3_loop

    ldx #(j2port_e - j2port - 1)
dh4_loop:
    lda j2port, x
    sta SCRBASE + 3*COLS + J2C + 1, x
    lda #LTGREEN
    sta COLBASE + 3*COLS + J2C + 1, x
    dex
    bpl dh4_loop
    rts

j1name:  .text "joystick 1"
j1name_e:
j1port:  .text "(port 2)"
j1port_e:
j2name:  .text "joystick 2"
j2name_e:
j2port:  .text "(port 1)"
j2port_e:

// ---- static grid characters ---------------------------------
// Positions for each panel:
//   GR_TOP row: col+0="ul"  col+5="u"   col+10="ur"
//   GR_MID row: col+0="l"   col+5="*"   col+10="r"
//   GR_BOT row: col+0="dl"  col+5="d"   col+10="dr"
//   GR_FIRE row: col+0="fire button"
// Colors set to COL_OFF here; runtime only changes color.

draw_grid_chars:
    // --- Joy1 ---
    // Row GR_TOP
    ldx #(gtop_e - gtop - 1)
dgc1_loop:
    lda gtop, x
    sta SCRBASE + GR_TOP*COLS + J1C, x
    lda #COL_OFF
    sta COLBASE + GR_TOP*COLS + J1C, x
    dex
    bpl dgc1_loop

    // Row GR_MID
    ldx #(gmid_e - gmid - 1)
dgc2_loop:
    lda gmid, x
    sta SCRBASE + GR_MID*COLS + J1C, x
    lda #COL_OFF
    sta COLBASE + GR_MID*COLS + J1C, x
    dex
    bpl dgc2_loop
    // Centre * always dim
    lda #COL_CTR
    sta COLBASE + GR_MID*COLS + J1C + GC_M

    // Row GR_BOT
    ldx #(gbot_e - gbot - 1)
dgc3_loop:
    lda gbot, x
    sta SCRBASE + GR_BOT*COLS + J1C, x
    lda #COL_OFF
    sta COLBASE + GR_BOT*COLS + J1C, x
    dex
    bpl dgc3_loop

    // Fire row
    ldx #(gfire_e - gfire - 1)
dgc4_loop:
    lda gfire, x
    sta SCRBASE + GR_FIRE*COLS + J1C, x
    lda #COL_FIRE_OFF
    sta COLBASE + GR_FIRE*COLS + J1C, x
    dex
    bpl dgc4_loop

    // --- Joy2 ---
    ldx #(gtop_e - gtop - 1)
dgc5_loop:
    lda gtop, x
    sta SCRBASE + GR_TOP*COLS + J2C, x
    lda #COL_OFF
    sta COLBASE + GR_TOP*COLS + J2C, x
    dex
    bpl dgc5_loop

    ldx #(gmid_e - gmid - 1)
dgc6_loop:
    lda gmid, x
    sta SCRBASE + GR_MID*COLS + J2C, x
    lda #COL_OFF
    sta COLBASE + GR_MID*COLS + J2C, x
    dex
    bpl dgc6_loop
    lda #COL_CTR
    sta COLBASE + GR_MID*COLS + J2C + GC_M

    ldx #(gbot_e - gbot - 1)
dgc7_loop:
    lda gbot, x
    sta SCRBASE + GR_BOT*COLS + J2C, x
    lda #COL_OFF
    sta COLBASE + GR_BOT*COLS + J2C, x
    dex
    bpl dgc7_loop

    ldx #(gfire_e - gfire - 1)
dgc8_loop:
    lda gfire, x
    sta SCRBASE + GR_FIRE*COLS + J2C, x
    lda #COL_FIRE_OFF
    sta COLBASE + GR_FIRE*COLS + J2C, x
    dex
    bpl dgc8_loop
    rts

// 11-char strings.  Positions 0,5,10 = indicator labels.
// Two-char labels start at 0 and 10; single-char at 5.
gtop:  .text "ul   u   ur"
gtop_e:
gmid:  .text "l    *   r "
gmid_e:
gbot:  .text "dl   d   dr"
gbot_e:
gfire: .text "fire button"
gfire_e:

// ---- bit value labels ---------------------------------------
draw_bit_labels:
    ldx #(bitlbl1_e - bitlbl1 - 1)
bbl1_loop:
    lda bitlbl1, x
    sta SCRBASE + ROW_BITS*COLS + 0, x
    lda #MDGRAY
    sta COLBASE + ROW_BITS*COLS + 0, x
    dex
    bpl bbl1_loop

    ldx #(bitlbl2_e - bitlbl2 - 1)
bbl2_loop:
    lda bitlbl2, x
    sta SCRBASE + ROW_BITS*COLS + 20, x
    lda #MDGRAY
    sta COLBASE + ROW_BITS*COLS + 20, x
    dex
    bpl bbl2_loop
    rts

bitlbl1:  .text "j1="
bitlbl1_e:
bitlbl2:  .text "j2="
bitlbl2_e:

// ---- exit hint ----------------------------------------------
draw_exit_hint:
    ldx #(exhint_e - exhint - 1)
eh_loop:
    lda exhint, x
    sta SCRBASE + 23*COLS + 10, x
    lda #LTRED
    sta COLBASE + 23*COLS + 10, x
    dex
    bpl eh_loop
    rts
exhint:  .text "[ run/stop ] = exit"
exhint_e:

// ============================================================
// Variables
// ============================================================
v_joy1:     .byte $FF
v_joy2:     .byte $FF
v_bits_tmp: .byte 0
