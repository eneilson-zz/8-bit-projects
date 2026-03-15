// Sprite helpers.
// Enables sprite bits from mask while preserving current enable state.
.macro spr_enable(mask) {
    lda $d015
    ora #mask
    sta $d015
}

// Sets X/Y position registers for the selected sprite number.
.macro spr_set_xy(spriteNum, xPos, yPos) {
    lda #xPos
    sta $d000 + (spriteNum * 2)
    lda #yPos
    sta $d001 + (spriteNum * 2)
}

// Disables sprite bits from mask while preserving other sprite states.
.macro spr_disable(mask) {
    lda $d015
    and #($ff - mask)
    sta $d015
}

// Sets the color register for a specific sprite number.
.macro spr_set_color(spriteNum, color) {
    lda #color
    sta $d027 + spriteNum
}

// Sets the sprite data pointer byte for one sprite (value is 64-byte block index).
.macro spr_set_ptr(spriteNum, ptrVal) {
    lda #ptrVal
    sta $07f8 + spriteNum
}

// Enables multicolor mode for sprites selected by mask.
.macro spr_set_multicolor(mask) {
    lda $d01c
    ora #mask
    sta $d01c
}

// Enables X expansion for sprites selected by mask.
.macro spr_set_expand_x(mask) {
    lda $d01d
    ora #mask
    sta $d01d
}

// Enables Y expansion for sprites selected by mask.
.macro spr_set_expand_y(mask) {
    lda $d017
    ora #mask
    sta $d017
}
