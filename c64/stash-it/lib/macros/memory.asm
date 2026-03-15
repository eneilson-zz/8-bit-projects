// Memory helpers.
// Stores an immediate 8-bit value at the given address.
.macro mem_write8(addr, value) {
    lda #value
    sta addr
}

// Fills one 256-byte page starting at baseAddr with fillValue.
.macro mem_clear_page(baseAddr, fillValue) {
    ldx #$00
    lda #fillValue
!loop:
    sta baseAddr,x
    inx
    bne !loop-
}

// Copies one 256-byte page from srcBase to dstBase.
.macro mem_copy_page(srcBase, dstBase) {
    ldx #$00
!loop:
    lda srcBase,x
    sta dstBase,x
    inx
    bne !loop-
}

// Stores an immediate 16-bit value (little-endian) at addr/addr+1.
.macro mem_write16(addr, value16) {
    lda #<value16
    sta addr
    lda #>value16
    sta addr + 1
}

// Copies len16 bytes from src to dst using compile-time generated loads/stores.
.macro mem_copy_block(src, dst, len16) {
    .for (var i = 0; i < len16; i++) {
        lda src + i
        sta dst + i
    }
}

// Fills len16 bytes at dst with value using compile-time generated stores.
.macro mem_fill_block(dst, value, len16) {
    lda #value
    .for (var i = 0; i < len16; i++) {
        sta dst + i
    }
}

// Compares len16 bytes and returns A=0 if equal or A=1 if any mismatch exists.
.macro mem_cmp_block(a, b, len16) {
    .for (var i = 0; i < len16; i++) {
        lda a + i
        cmp b + i
        bne !mismatch+
    }
    lda #$00
    beq !done+
!mismatch:
    lda #$01
!done:
}

// Alias that writes an immediate 16-bit value to ptr/ptr+1.
.macro mem_set16(ptr, value16) {
    mem_write16(ptr, value16)
}

// Clears a 16-bit little-endian value at addr/addr+1 to zero.
.macro mem_zero16(addr16) {
    lda #$00
    sta addr16
    sta addr16 + 1
}
