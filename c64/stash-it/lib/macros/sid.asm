// SID helpers.
// Sets SID master volume using register $D418.
.macro sid_set_volume(volume) {
    lda #volume
    sta $d418
}

// Enables gate on voice 1 with a basic control value.
.macro sid_gate_voice1_on() {
    lda #$11
    sta $d404
}

// Sets voice 1 frequency from an immediate 16-bit value.
.macro sid_voice1_set_freq(freq16) {
    lda #<freq16
    sta $d400
    lda #>freq16
    sta $d401
}

// Clears all three SID voice control registers to silence gates/waveforms.
.macro sid_all_voices_off() {
    lda #$00
    sta $d404
    sta $d40b
    sta $d412
}
