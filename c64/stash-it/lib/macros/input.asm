// Keyboard input helpers.
// Reads one key from the KERNAL keyboard buffer into A (or 0 if none).
.macro get_key() {
    jsr $ffe4
}

// Polls until a non-zero key value is returned in A.
.macro wait_key() {
!wait:
    jsr $ffe4
    beq !wait-
}

// Polls until no key is pending in the KERNAL keyboard buffer.
.macro wait_key_release() {
!wait:
    jsr $ffe4
    bne !wait-
}

// Waits for a keypress and stores the resulting PETSCII value to addr.
.macro wait_key_store(addr) {
!wait:
    jsr $ffe4
    beq !wait-
    sta addr
}

// Alias that waits until no key is pending in the keyboard buffer.
.macro input_wait_key_release() {
    wait_key_release()
}

// Reads joystick state from the selected port (1 or 2) into A.
.macro input_get_joystick(port) {
    .if (port == 1) {
        lda $dc01
    } else {
        lda $dc00
    }
}

// Scans one keyboard matrix row and returns pressed column bits (active-high) in A.
.macro input_key_is_pressed(matrixRow, mask) {
    lda #$ff
    sta $dc02
    lda #$00
    sta $dc03
    lda #($ff ^ (1 << matrixRow))
    sta $dc00
    lda $dc01
    eor #$ff
    and #mask
    tay
    lda #$ff
    sta $dc00
    tya
}

// Reads a line into buf up to maxLen characters and zero-terminates it.
.macro input_read_line(buf, maxLen) {
    ldx #$00
!read:
    jsr $ffe4
    beq !read-
    cmp #$0d
    beq !done+
    cmp #$14
    bne !store+
    cpx #$00
    beq !read-
    dex
    lda #$00
    sta buf,x
    lda #$14
    jsr $ffd2
    jmp !read-
!store:
    cpx #maxLen
    bcs !read-
    sta buf,x
    jsr $ffd2
    inx
    jmp !read-
!done:
    lda #$00
    sta buf,x
}

// Removes one character from the end of a line buffer using lenVar as current length.
.macro input_backspace_line(bufPtr, lenVar) {
    lda lenVar
    beq !done+
    sec
    sbc #$01
    sta lenVar
    tax
    lda #$00
    sta bufPtr,x
!done:
}

// Drains pending keypresses from the KERNAL keyboard buffer.
.macro input_flush_buffer() {
!drain:
    jsr $ffe4
    bne !drain-
}
