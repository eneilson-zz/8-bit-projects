// IRQ and timing helpers.
// Disables maskable interrupts.
.macro irq_disable() {
    sei
}

// Enables maskable interrupts.
.macro irq_enable() {
    cli
}

// Saves CPU state used by interrupt handlers.
// Push order: P, A, X, Y.
.macro irq_push_all() {
    php
    pha
    txa
    pha
    tya
    pha
}

// Restores CPU state saved by irq_push_all().
// Pop order: Y, X, A, P.
.macro irq_pop_all() {
    pla
    tay
    pla
    tax
    pla
    plp
}

// Acknowledges VIC-II IRQ flags by writing a bit mask to $D019.
.macro irq_ack_vic(mask) {
    lda #mask
    sta $d019
}

// Waits until the raster register equals the given line value.
.macro wait_raster(line) {
!wait:
    lda $d012
    cmp #line
    bne !wait-
}
