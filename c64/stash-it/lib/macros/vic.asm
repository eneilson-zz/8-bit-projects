// VIC-II helpers.
// C64 color constants for VIC-II and color RAM use.
.const C_BLACK       = $00 // 0: Black
.const C_WHITE       = $01 // 1: White
.const C_RED         = $02 // 2: Red
.const C_CYAN        = $03 // 3: Cyan
.const C_PURPLE      = $04 // 4: Purple
.const C_GREEN       = $05 // 5: Green
.const C_BLUE        = $06 // 6: Blue
.const C_YELLOW      = $07 // 7: Yellow
.const C_ORANGE      = $08 // 8: Orange
.const C_BROWN       = $09 // 9: Brown
.const C_LIGHT_RED   = $0a // 10: Light Red
.const C_DARK_GRAY   = $0b // 11: Dark Gray
.const C_GRAY        = $0c // 12: Gray
.const C_LIGHT_GREEN = $0d // 13: Light Green
.const C_LIGHT_BLUE  = $0e // 14: Light Blue
.const C_LIGHT_GRAY  = $0f // 15: Light Gray

// Sets the border color register at $D020.
.macro set_border(colorLabel) {
    lda #colorLabel
    sta $d020
}

// Sets the background color register at $D021.
.macro set_bg(colorLabel) {
    lda #colorLabel
    sta $d021
}

// Sets border and background colors together.
.macro set_border_bg(borderColorLabel, bgColorLabel) {
    lda #borderColorLabel
    sta $d020
    lda #bgColorLabel
    sta $d021
}

// Sets the VIC-II screen memory pointer bits in $D018 for the current VIC bank.
.macro set_screen_ptr(screenBase) {
    lda $d018
    and #$0f
    ora #((((screenBase & $3fff) / $0400) & $0f) << 4)
    sta $d018
}

// Sets the VIC-II character generator pointer bits in $D018 for the current VIC bank.
.macro set_charset_ptr(charBase) {
    lda $d018
    and #$f1
    ora #((((charBase & $3fff) / $0800) & $07) << 1)
    sta $d018
}

// Enables or disables VIC-II text multicolor mode (bit 4 of $D016).
.macro set_multicolor_mode(onOff) {
    lda $d016
    .if (onOff) {
        ora #$10
    } else {
        and #$ef
    }
    sta $d016
}

// Fills screen RAM and color RAM with one character and one color value.
.macro screen_clear(fillChar, fillColorLabel) {
    ldx #$00
    lda #fillChar
!char_loop:
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne !char_loop-

    ldx #$00
    lda #fillColorLabel
!color_loop:
    sta $d800,x
    sta $d900,x
    sta $da00,x
    sta $db00,x
    inx
    bne !color_loop-
}

// Fills one 40-column text row in screen and color RAM.
.macro screen_fill_row(row, charValue, colorLabel) {
    ldx #$00
    lda #charValue
!char_loop:
    sta $0400 + (row * 40),x
    inx
    cpx #40
    bne !char_loop-

    ldx #$00
    lda #colorLabel
!color_loop:
    sta $d800 + (row * 40),x
    inx
    cpx #40
    bne !color_loop-
}
