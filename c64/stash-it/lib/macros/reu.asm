// Commodore REU (17xx) helpers.
.const REU_STATUS       = $df00 // Status flags (EOB, verify error, REU size/status bits).
.const REU_COMMAND      = $df01 // Command/mode register (execute, function select, autoload).
.const REU_C64_ADDR_LO  = $df02 // C64 transfer address low byte.
.const REU_C64_ADDR_HI  = $df03 // C64 transfer address high byte.
.const REU_REU_ADDR_LO  = $df04 // REU transfer address low byte.
.const REU_REU_ADDR_MI  = $df05 // REU transfer address middle byte.
.const REU_REU_ADDR_HI  = $df06 // REU transfer address high/bank byte.
.const REU_LENGTH_LO    = $df07 // Transfer length low byte.
.const REU_LENGTH_HI    = $df08 // Transfer length high byte.
.const REU_IRQ_MASK     = $df09 // IRQ mask/enable bits for REU events.
.const REU_ADDR_CTRL    = $df0a // Address control (fixed/increment behavior for C64/REU sides).

// Writes the 16-bit C64 source/destination address for the next DMA transfer.
.macro reu_set_c64_addr(addr16) {
    lda #<addr16
    sta REU_C64_ADDR_LO
    lda #>addr16
    sta REU_C64_ADDR_HI
}

// Writes the 24-bit REU source/destination address (A0-A18 used on 512KB REU).
.macro reu_set_reu_addr(addr24) {
    lda #<addr24
    sta REU_REU_ADDR_LO
    lda #>addr24
    sta REU_REU_ADDR_MI
    lda #((addr24 >> 16) & $ff)
    sta REU_REU_ADDR_HI
}

// Convenience helper to set only the REU high-address/bank register.
.macro reu_set_reu_bank(bank) {
    lda #(bank & $ff)
    sta REU_REU_ADDR_HI
}

// Writes the 16-bit transfer length in bytes.
.macro reu_set_length(len16) {
    lda #<len16
    sta REU_LENGTH_LO
    lda #>len16
    sta REU_LENGTH_HI
}

// Sets fixed-address behavior bits (bit7=C64 fixed, bit6=REU fixed).
.macro reu_set_addr_control(flags) {
    lda #flags
    sta REU_ADDR_CTRL
}

// Enables or disables REU AUTOLOAD without triggering execute.
.macro reu_set_autoload(onOff) {
    lda REU_COMMAND
    and #%00011111
    .if (onOff) {
        ora #%00100000
    }
    sta REU_COMMAND
}

// Starts DMA transfer from C64 memory to REU memory (immediate execute).
.macro reu_cmd_c64_to_reu() {
    lda #$90
    sta REU_COMMAND
}

// Starts DMA transfer from REU memory to C64 memory (immediate execute).
.macro reu_cmd_reu_to_c64() {
    lda #$91
    sta REU_COMMAND
}

// Starts DMA swap operation between C64 and REU memory blocks.
.macro reu_cmd_swap() {
    lda #$92
    sta REU_COMMAND
}

// Starts DMA verify operation comparing C64 and REU memory blocks.
.macro reu_cmd_verify() {
    lda #$93
    sta REU_COMMAND
}

// Waits until End-Of-Block is set, indicating the DMA transfer is complete.
.macro reu_wait_done() {
!wait:
    lda REU_STATUS
    and #$40
    beq !wait-
}

// Clears pending REU IRQ/EOB/verify status bits by reading status register.
.macro reu_clear_irq_flags() {
    lda REU_STATUS
}

// Writes REU interrupt mask/enable bits (bit7=IRQE, bit6=EOBE, bit5=VerifyE).
.macro reu_enable_irq(mask) {
    lda #mask
    sta REU_IRQ_MASK
}

// Clears REU transfer state and address control registers to defaults.
.macro reu_reset_state() {
    lda #$00
    sta REU_COMMAND
    sta REU_ADDR_CTRL
}

// Sets REU and C64 address counters to auto-increment mode.
.macro reu_set_increment_mode() {
    lda #$00
    sta REU_ADDR_CTRL
}
