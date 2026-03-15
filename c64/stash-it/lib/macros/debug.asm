// Debug helpers.
// Sets the border color to provide a visible debug marker on screen.
.macro dbg_set_border(color) {
    lda #color
    sta $d020
}

// Triggers a BRK instruction for monitor/debugger break handling.
.macro dbg_break() {
    brk
}

// Sets the background color to provide a second visual debug marker.
.macro dbg_set_bg(color) {
    lda #color
    sta $d021
}

// Pulses the border color briefly, then restores the original value.
.macro dbg_pulse_border(color) {
    lda $d020
    pha
    lda #color
    sta $d020
    pla
    sta $d020
}
