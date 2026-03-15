// 16-bit math helpers.
// Increments a little-endian 16-bit value stored at addr/addr+1.
.macro math_inc16(addr) {
    inc addr
    bne !done+
    inc addr + 1
!done:
}

// Adds an immediate 16-bit value to a 16-bit little-endian variable.
.macro math_add16_imm(addr, value) {
    clc
    lda addr
    adc #<value
    sta addr
    lda addr + 1
    adc #>value
    sta addr + 1
}

// Decrements a little-endian 16-bit value stored at addr/addr+1.
.macro math_dec16(addr) {
    lda addr
    bne !dec_lo+
    dec addr + 1
!dec_lo:
    dec addr
}

// Adds a 16-bit source value into a 16-bit destination value.
.macro math_add16(dstAddr, srcAddr) {
    clc
    lda dstAddr
    adc srcAddr
    sta dstAddr
    lda dstAddr + 1
    adc srcAddr + 1
    sta dstAddr + 1
}
