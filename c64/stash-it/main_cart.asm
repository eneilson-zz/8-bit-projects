// stash-it cartridge prototype (tiny manual NMI hook)
//
// No CBM80 autostart signature yet.
// Install hook manually from BASIC:
//   SYS 32768
//
// Test behavior:
// - Trigger NMI (RESTORE/cart NMI in emulator)
// - Border turns red, then execution resumes

.import source "lib/macros/irq.asm"
.import source "lib/macros/vic.asm"

* = $8000 "ROML"

// KERNAL NMI indirect vector bytes.
.const NMI_VEC_LO = $0318
.const NMI_VEC_HI = $0319

// BASIC entry point: SYS 32768.
jmp install_nmi_hook

install_nmi_hook:
    // SEI masks IRQ while updating two-byte vector.
    // NMI is not maskable, so we also choose a race-safe hook address ($8047).
    irq_disable()

    // Write high first, then low. Default low byte is typically $47 ($FE47).
    // During update, vector still points to a valid address.
    lda #>nmi_hook
    sta NMI_VEC_HI
    lda #<nmi_hook
    sta NMI_VEC_LO

    irq_enable()
    rts

// Pad so nmi_hook lands at $8047.
.fill $8047 - *, $ff

nmi_hook:
    // Defensive IRQ masking while inside handler.
    irq_disable()
    irq_push_all()

    // Acknowledge CIA#1 NMI source early (RESTORE path).
    lda $dc0d

    // Visual proof we entered cartridge NMI code.
    set_border(C_RED)

    // Restore registers and return from interrupt.
    irq_pop_all()
    rti

// Pad full 8K ROM image.
.fill $a000 - *, $ff
