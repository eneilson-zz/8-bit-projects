// Text and print helpers.
// Outputs one PETSCII character value using KERNAL CHROUT.
.macro print_char(charValue) {
    lda #charValue
    jsr $ffd2
}

// Prints a null-terminated string from memory via CHROUT.
.macro print_string(strLabel) {
    ldy #$00
!loop:
    lda strLabel,y
    beq !done+
    jsr $ffd2
    iny
    bne !loop-
!done:
}

// Outputs a PETSCII carriage return/newline using KERNAL CHROUT.
.macro print_newline() {
    lda #$0d
    jsr $ffd2
}

// Outputs the C64 CLR/HOME control code using KERNAL CHROUT.
.macro print_clear_home() {
    lda #$93
    jsr $ffd2
}

// Prints an 8-bit value as two uppercase hexadecimal characters.
.macro print_hex8(value) {
    lda #((value >> 4) & $0f)
    cmp #$0a
    bcc !hi_digit+
    adc #$36
    bne !hi_out+
!hi_digit:
    adc #$30
!hi_out:
    jsr $ffd2

    lda #(value & $0f)
    cmp #$0a
    bcc !lo_digit+
    adc #$36
    bne !lo_out+
!lo_digit:
    adc #$30
!lo_out:
    jsr $ffd2
}

// Prints a 16-bit value as four uppercase hexadecimal characters.
.macro print_hex16(value) {
    print_hex8((value >> 8) & $ff)
    print_hex8(value & $ff)
}

// Stores one PETSCII character directly to a screen memory address.
.macro print_at(screenAddr, charValue) {
    lda #charValue
    sta screenAddr
}

// Writes a null-terminated string directly into screen memory.
.macro print_string_at(screenAddr, strLabel) {
    ldx #$00
!loop:
    lda strLabel,x
    beq !done+
    sta screenAddr,x
    inx
    bne !loop-
!done:
}

// Sets the KERNAL cursor position to X column and Y row.
.macro set_cursor_xy(x, y) {
    ldx #x
    ldy #y
    sec
    jsr $fff0
}
