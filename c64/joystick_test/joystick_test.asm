// ============================================================
// joystick_test.asm  --  C64 Joystick Input Tester
// KickAssembler.  Load with LOAD"*",8,1 then RUN.
//
// C64 joystick port wiring (bits are active-low: 0 = pressed):
//   Physical "Joystick 2" port -> CIA1 Port A $DC00
//   Physical "Joystick 1" port -> CIA1 Port B $DC01
//   Bit 0 = Up    Bit 1 = Down   Bit 2 = Left
//   Bit 3 = Right Bit 4 = Fire
//
// Display strategy:
//   Direction labels (ul/u/ur/l/*/r/dl/d/dr) and "fire button"
//   are drawn once at init and never changed.  At runtime only
//   COLOR RAM is updated — green = active, dark gray = inactive.
//   This avoids flicker and keeps the main loop simple.
//
// Screen grid per panel (rows 2 apart, cols 5 apart):
//   row GR_TOP:  ul    u    ur   (cols +0 +5 +9)
//   row GR_MID:  l     *    r    (cols +0 +5 +9)
//   row GR_BOT:  dl    d    dr   (cols +0 +5 +9)
//   row GR_FIRE: fire button
//
// Press RUN/STOP to exit and cold-reset the machine.
// ============================================================

// Generates the two-line BASIC stub: 10 SYS 2304
// so the program auto-runs when loaded with LOAD"*",8,1 / RUN
BasicUpstart2(main)

// ---- CIA / VIC hardware registers --------------------------
.const CIA1_PRA  = $DC00   // CIA1 Port A: Joy2 + keyboard column drive
.const CIA1_PRB  = $DC01   // CIA1 Port B: Joy1 + keyboard row read
.const SCRBASE   = $0400   // Default screen RAM base
.const COLBASE   = $D800   // Color RAM base (one byte per screen cell)
.const VICBORDER = $D020   // VIC border color register
.const VICBG     = $D021   // VIC background color register

// ---- VIC color palette values ------------------------------
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

// ---- Screen geometry ---------------------------------------
.const COLS    = 40        // Characters per screen row
.const ZPT     = $FB       // Zero-page scratch byte

// Left edge column of each joystick panel
.const J1C = 2             // Joystick 1 panel starts at col 2
.const J2C = 22            // Joystick 2 panel starts at col 22

// Column offsets within a panel for the 3-column direction grid.
// Each label is 1-2 chars; two-char labels (ul/ur/dl/dr) start
// at GC_L and GC_R so their second char lands at +1.
.const GC_L = 0            // Left indicators:   ul / l / dl
.const GC_M = 5            // Centre indicators:  u / * / d
.const GC_R = 9            // Right indicators:  ur / r / dr

// Screen rows for each grid row and the fire label.
// Rows are spaced 2 apart so the grid looks square.
.const GR_TOP  = 5         // Top row:    ul  u  ur
.const GR_MID  = 7         // Middle row:  l  *  r
.const GR_BOT  = 9         // Bottom row: dl  d  dr
.const GR_FIRE = 11        // Fire button label row

// Row where the 8-bit raw CIA register values are printed
.const ROW_BITS = 14

// ---- Color constants for highlighting ----------------------
.const COL_ON       = LTGREEN  // Direction/fire is active (pressed)
.const COL_OFF      = DKGRAY   // Direction/fire is inactive
.const COL_CTR      = MDGRAY   // Centre * marker — always dim
.const COL_FIRE_ON  = LTRED    // Fire button active
.const COL_FIRE_OFF = DKGRAY   // Fire button inactive

// ============================================================
// Program entry
// ============================================================
* = $0801               // BASIC stub placed at default BASIC start
* = $0900               // Main code at $0900 (SYS 2304)

main:
    jsr init_screen     // Draw all static screen elements

// ---- Main polling loop -------------------------------------
loop:
    // Scan keyboard matrix for RUN/STOP key.
    // The keyboard is a matrix: we drive a column low via CIA1_PRA
    // and read rows via CIA1_PRB.  RUN/STOP is at col 7 / row 7.
    // Writing %01111111 selects column 7 (bit 7 driven low).
    lda #%01111111
    sta CIA1_PRA
    lda CIA1_PRB
    and #%10000000          // Isolate row 7 bit
    beq exit_pgm            // Branch if bit = 0 (key pressed, active-low)

    // Restore CIA1_PRA to $FF so all joystick bits read correctly.
    // If left with a column selected, some direction bits read wrong.
    lda #$FF
    sta CIA1_PRA

    // Sample both joystick ports.
    // All unused/unpressed bits read as 1; pressed bits read as 0.
    lda CIA1_PRA            // Joy2: physical "Joystick 2" port
    sta v_joy2
    lda CIA1_PRB            // Joy1: physical "Joystick 1" port
    sta v_joy1

    // Update color RAM for each joystick grid (chars never change)
    lda v_joy1
    jsr color_joy1
    lda v_joy2
    jsr color_joy2

    // Print raw 8-bit CIA values as binary strings
    lda v_joy1
    jsr print_bits_j1
    lda v_joy2
    jsr print_bits_j2

    jmp loop

// ---- Exit: restore CIA and cold-reset the machine ----------
exit_pgm:
    lda #$FF
    sta CIA1_PRA            // Release keyboard column drive
    jmp $FCE2               // KERNAL cold reset — clears machine, back to READY.

// ============================================================
// active_col
// Input:  A = result of (raw_CIA AND bit_mask)
//         Zero means all masked bits are 0 = direction is active.
// Output: A = COL_ON if active, COL_OFF if inactive.
// Used by color_joy1 / color_joy2 before each color RAM write.
// ============================================================
active_col:
    bne ac_off              // Any bit still set = not pressed
    lda #COL_ON
    rts
ac_off:
    lda #COL_OFF
    rts

// ============================================================
// color_joy1
// Input:  A = raw byte from CIA1_PRB (Joy1 port)
// Writes the appropriate highlight color to every direction
// label and the fire button text in Joy1's panel.
// Only color RAM is touched; screen RAM chars are unchanged.
// ============================================================
color_joy1:
    sta ZPT                 // Preserve raw CIA byte for multiple tests

    // UL: active when both Left (bit 2) and Up (bit 0) are pressed
    lda ZPT
    and #%00000101          // Mask bits 2 and 0
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J1C + GC_L       // 'u' of "ul"
    sta COLBASE + GR_TOP*COLS + J1C + GC_L + 1   // 'l' of "ul"

    // U: active when Up (bit 0) is pressed
    lda ZPT
    and #%00000001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J1C + GC_M

    // UR: active when both Right (bit 3) and Up (bit 0) are pressed
    lda ZPT
    and #%00001001          // Mask bits 3 and 0
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J1C + GC_R       // 'u' of "ur"
    sta COLBASE + GR_TOP*COLS + J1C + GC_R + 1   // 'r' of "ur"

    // L: active when Left (bit 2) is pressed
    lda ZPT
    and #%00000100
    jsr active_col
    sta COLBASE + GR_MID*COLS + J1C + GC_L

    // R: active when Right (bit 3) is pressed
    lda ZPT
    and #%00001000
    jsr active_col
    sta COLBASE + GR_MID*COLS + J1C + GC_R

    // DL: active when both Left (bit 2) and Down (bit 1) are pressed
    lda ZPT
    and #%00000110          // Mask bits 2 and 1
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J1C + GC_L
    sta COLBASE + GR_BOT*COLS + J1C + GC_L + 1

    // D: active when Down (bit 1) is pressed
    lda ZPT
    and #%00000010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J1C + GC_M

    // DR: active when both Right (bit 3) and Down (bit 1) are pressed
    lda ZPT
    and #%00001010          // Mask bits 3 and 1
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J1C + GC_R
    sta COLBASE + GR_BOT*COLS + J1C + GC_R + 1

    // FIRE: active when bit 4 is pressed.
    // Color all 11 chars of "fire button" with a single loop.
    lda ZPT
    and #%00010000
    bne cj1_fire_off
    lda #COL_FIRE_ON        // Bit = 0 → pressed → highlight red
    bne cj1_fire_set
cj1_fire_off:
    lda #COL_FIRE_OFF       // Bit = 1 → not pressed → dim
cj1_fire_set:
    ldx #10                 // "fire button" is 11 chars (indices 0-10)
cj1_fire_loop:
    sta COLBASE + GR_FIRE*COLS + J1C, x
    dex
    bpl cj1_fire_loop
    rts

// ============================================================
// color_joy2
// Identical logic to color_joy1, targeting Joy2's panel (J2C).
// Input:  A = raw byte from CIA1_PRA (Joy2 port)
// ============================================================
color_joy2:
    sta ZPT

    // UL (bits 2+0)
    lda ZPT
    and #%00000101
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J2C + GC_L
    sta COLBASE + GR_TOP*COLS + J2C + GC_L + 1

    // U (bit 0)
    lda ZPT
    and #%00000001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J2C + GC_M

    // UR (bits 3+0)
    lda ZPT
    and #%00001001
    jsr active_col
    sta COLBASE + GR_TOP*COLS + J2C + GC_R
    sta COLBASE + GR_TOP*COLS + J2C + GC_R + 1

    // L (bit 2)
    lda ZPT
    and #%00000100
    jsr active_col
    sta COLBASE + GR_MID*COLS + J2C + GC_L

    // R (bit 3)
    lda ZPT
    and #%00001000
    jsr active_col
    sta COLBASE + GR_MID*COLS + J2C + GC_R

    // DL (bits 2+1)
    lda ZPT
    and #%00000110
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J2C + GC_L
    sta COLBASE + GR_BOT*COLS + J2C + GC_L + 1

    // D (bit 1)
    lda ZPT
    and #%00000010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J2C + GC_M

    // DR (bits 3+1)
    lda ZPT
    and #%00001010
    jsr active_col
    sta COLBASE + GR_BOT*COLS + J2C + GC_R
    sta COLBASE + GR_BOT*COLS + J2C + GC_R + 1

    // FIRE (bit 4)
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
// Prints the raw 8-bit CIA register value as a binary string
// on ROW_BITS.  Bit 7 is printed leftmost (MSB first).
//
// Technique: shift v_bits_tmp left with ASL on each iteration.
// Bit 7 falls into carry first.  Carry clear = bit was 1 (active).
// X counts 0..7 as the column offset, so bit 7 lands at col+0.
//
// J1 printed at col 5, J2 at col 25.
// ============================================================
print_bits_j1:
    sta v_bits_tmp          // Save value; we destroy it by shifting
    ldx #0                  // Column offset: 0 = leftmost (bit 7)
pb1_loop:
    asl v_bits_tmp          // Shift bit 7 into carry
    bcc pb1_one             // Carry clear = bit was 1 (pressed)
    lda #$30                // PETSCII '0' — bit was 0 (not pressed)
    sta SCRBASE + ROW_BITS*COLS + 5, x
    lda #COL_OFF            // Dim color for 0
    sta COLBASE + ROW_BITS*COLS + 5, x
    inx
    cpx #8
    bne pb1_loop
    rts
pb1_one:
    lda #$31                // PETSCII '1' — bit was 1 (pressed)
    sta SCRBASE + ROW_BITS*COLS + 5, x
    lda #COL_ON             // Highlight color for 1
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
// Clears screen and color RAM, draws all static elements,
// then calls color_joy1/2 and print_bits with $FF (all bits
// high = nothing pressed) to set the initial dim state.
// ============================================================
init_screen:
    lda #BLACK
    sta VICBORDER
    sta VICBG

    // Fill all 1000 screen cells with space ($20).
    // Four 256-byte pages cover $0400-$07E7 (1000 bytes).
    lda #$20
    ldx #$00
is_cs:
    sta SCRBASE+$000,x
    sta SCRBASE+$100,x
    sta SCRBASE+$200,x
    sta SCRBASE+$300,x
    inx
    bne is_cs

    // Fill all 1000 color RAM cells with white.
    lda #WHITE
    ldx #$00
is_cc:
    sta COLBASE+$000,x
    sta COLBASE+$100,x
    sta COLBASE+$200,x
    sta COLBASE+$300,x
    inx
    bne is_cc

    jsr draw_title          // Title bar at row 0
    jsr draw_headers        // Panel name + port labels at rows 2-3
    jsr draw_grid_chars     // Direction labels + fire text at rows 5-11
    jsr draw_bit_labels     // "j1=" / "j2=" prefixes at row 14
    jsr draw_exit_hint      // RUN/STOP hint at row 23

    // Render initial state: $FF = all bits high = nothing pressed
    lda #$FF
    jsr color_joy1
    lda #$FF
    jsr color_joy2
    lda #$FF
    jsr print_bits_j1
    lda #$FF
    jsr print_bits_j2
    rts

// ---- draw_title --------------------------------------------
// Draws "** c64 joystick tester **" in yellow at row 0, col 7.
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

// ---- draw_headers ------------------------------------------
// Draws two-line panel headers:
//   Row 2: "joystick 1" / "joystick 2"  (10 chars, starts at J1C/J2C)
//   Row 3: "(port 2)"   / "(port 1)"    ( 8 chars, starts at J1C+1/J2C+1)
// Offset +1 on row 3 centres the 8-char port string under the 10-char name.
// Joy1 uses light blue; Joy2 uses light green.
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
j1port:  .text "(port 2)"       // Physical "Joystick 2" port on the C64
j1port_e:
j2name:  .text "joystick 2"
j2name_e:
j2port:  .text "(port 1)"       // Physical "Joystick 1" port on the C64
j2port_e:

// ---- draw_grid_chars ---------------------------------------
// Writes the 11-char direction strings and "fire button" text
// for both panels to screen RAM, with all colors set to their
// inactive (dim) state.  Color RAM is overwritten each frame
// by color_joy1/color_joy2; screen RAM is never touched again.
//
// String layout (11 chars, positions 0-10):
//   gtop: "ul   u   ur"   GC_L=0  GC_M=5  GC_R=9
//   gmid: "l    *   r "   GC_L=0  GC_M=5  GC_R=9
//   gbot: "dl   d   dr"   GC_L=0  GC_M=5  GC_R=9
//   gfire:"fire button"   full 11-char label
draw_grid_chars:
    // --- Joy1 panel ---

    // Top row: ul / u / ur
    ldx #(gtop_e - gtop - 1)
dgc1_loop:
    lda gtop, x
    sta SCRBASE + GR_TOP*COLS + J1C, x
    lda #COL_OFF
    sta COLBASE + GR_TOP*COLS + J1C, x
    dex
    bpl dgc1_loop

    // Middle row: l / * / r
    ldx #(gmid_e - gmid - 1)
dgc2_loop:
    lda gmid, x
    sta SCRBASE + GR_MID*COLS + J1C, x
    lda #COL_OFF
    sta COLBASE + GR_MID*COLS + J1C, x
    dex
    bpl dgc2_loop
    lda #COL_CTR                            // Centre * is always dim
    sta COLBASE + GR_MID*COLS + J1C + GC_M

    // Bottom row: dl / d / dr
    ldx #(gbot_e - gbot - 1)
dgc3_loop:
    lda gbot, x
    sta SCRBASE + GR_BOT*COLS + J1C, x
    lda #COL_OFF
    sta COLBASE + GR_BOT*COLS + J1C, x
    dex
    bpl dgc3_loop

    // Fire label row
    ldx #(gfire_e - gfire - 1)
dgc4_loop:
    lda gfire, x
    sta SCRBASE + GR_FIRE*COLS + J1C, x
    lda #COL_FIRE_OFF
    sta COLBASE + GR_FIRE*COLS + J1C, x
    dex
    bpl dgc4_loop

    // --- Joy2 panel --- (same strings, different base column)

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

// Direction grid strings — shared by both panels.
// Indicator positions: GC_L=0, GC_M=5, GC_R=9 (11 chars total).
gtop:  .text "ul   u   ur"    // Top row:    UL  U  UR
gtop_e:
gmid:  .text "l    *   r "    // Middle row:  L  *  R
gmid_e:
gbot:  .text "dl   d   dr"    // Bottom row: DL  D  DR
gbot_e:
gfire: .text "fire button"    // Fire row: entire text highlighted on press
gfire_e:

// ---- draw_bit_labels ---------------------------------------
// Draws the static "j1=" and "j2=" prefixes before the binary
// bit fields on ROW_BITS.  The 8 binary digit characters are
// written (and rewritten each frame) by print_bits_j1/j2.
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

// ---- draw_exit_hint ----------------------------------------
// Draws "[ run/stop ] = exit" in light red at the bottom of
// the screen (row 23) so the user knows how to quit.
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
// Variables (placed after all code)
// ============================================================
v_joy1:     .byte $FF   // Last sampled CIA1_PRB value (Joy1)
v_joy2:     .byte $FF   // Last sampled CIA1_PRA value (Joy2)
v_bits_tmp: .byte 0     // Scratch byte used by print_bits routines
