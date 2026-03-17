// t3-test.asm — Stash-It T3 verification
//
// Pure machine code at $C000. No BASIC stub.
// Load with: LOAD"T3-TEST",8,1
// Run with:  SYS 49152  (after pressing RESTORE)
//
// Verifies T3 DMA copied C64 $8000-$9FFF (ROML) into REU bank 0 offset $8000.
//
// Since EXROM is tied low, ROML is always visible — the DMA captures ROM bytes,
// not RAM underneath. We know exactly what those bytes should be:
//
//   REU bank 0 $8000-$8001  = coldStart vector lo/hi  (expect $09 $80)
//   REU bank 0 $8002-$8003  = nmiHandler vector lo/hi (expect $27 $80)
//   REU bank 0 $8004-$8008  = CBM80 signature         (expect C3 C2 CD 38 30)
//
// These are the first 9 bytes of our ROML — stable and predictable.

.const CHROUT  = $FFD2
.const SCRATCH = $C300      // scratch above program end (program ends ~$C210)

* = $C000 "Main"
main:
    // ── CHK1: ROML header bytes from REU bank 0 offset $8000 ─────────────
    // coldStart vector + nmiHandler vector (4 bytes, expect 09 80 27 80)
    lda #<str_chk1
    sta $FB
    lda #>str_chk1
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03           // C64 dest = SCRATCH
    lda #$00
    sta $DF04           // REU offset lo = $00
    lda #$80
    sta $DF05           // REU offset mi = $80  → REU offset $8000 (bank 0)
    lda #$00
    sta $DF06           // REU bank = 0
    lda #$04
    sta $DF07           // length = 4 bytes
    lda #$00
    sta $DF08
    sta $DF0A           // addr ctrl = auto-increment both
    lda #$91
    sta $DF01           // execute: REU → C64

    ldx #0
!:  lda SCRATCH,x
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #4
    bne !-
    lda #13
    jsr CHROUT

    // ── CHK2: CBM80 signature from REU bank 0 offset $8004 ───────────────
    // 5 bytes: C3 C2 CD 38 30 ("CBM80" in PETSCII)
    lda #<str_chk2
    sta $FB
    lda #>str_chk2
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03           // C64 dest = SCRATCH
    lda #$04
    sta $DF04           // REU offset lo = $04  → $8004
    lda #$80
    sta $DF05           // REU offset mi = $80  (REU offset $8000 base)
    lda #$00
    sta $DF06           // REU bank = 0
    lda #$05
    sta $DF07           // length = 5 bytes
    lda #$00
    sta $DF08
    sta $DF0A
    lda #$91
    sta $DF01           // execute: REU → C64

    ldx #0
!:  lda SCRATCH,x
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #5
    bne !-
    lda #13
    jsr CHROUT

    // ── CHK3: cross-check against live ROML ───────────────────────────────
    // Read the same 9 bytes directly from live $8000 and compare
    // Since ROML is always mapped, live read should match REU snapshot exactly
    lda #<str_chk3
    sta $FB
    lda #>str_chk3
    sta $FC
    jsr print_str

    ldx #0
!:  lda $8000,x         // read directly from live ROML
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #9
    bne !-
    lda #13
    jsr CHROUT

    // Print REU snapshot of same 9 bytes for side-by-side comparison
    lda #<str_reu
    sta $FB
    lda #>str_reu
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03
    lda #$00
    sta $DF04           // REU offset lo = $00  → $8000
    lda #$80
    sta $DF05           // REU offset mi = $80
    lda #$00
    sta $DF06           // REU bank = 0
    lda #$09
    sta $DF07           // length = 9 bytes
    lda #$00
    sta $DF08
    sta $DF0A
    lda #$91
    sta $DF01           // execute: REU → C64

    ldx #0
!:  lda SCRATCH,x
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #9
    bne !-
    lda #13
    jsr CHROUT

    // Wait for keypress
    lda #<str_done
    sta $FB
    lda #>str_done
    sta $FC
    jsr print_str
wait_key:
    lda $DC01
    cmp #$FF
    beq wait_key
    rts

// ── print_str: print null-terminated string via ($FB/$FC) ─────────────────
print_str:
    ldy #0
!:  lda ($FB),y
    beq !+
    jsr CHROUT
    iny
    bne !-
!:  rts

// ── print_hex: print A as 2 hex digits ────────────────────────────────────
print_hex:
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_nybble
    pla
    and #$0F
print_nybble:
    clc
    adc #$30
    cmp #$3A
    bcc !+
    adc #$06
!:  jmp CHROUT

// ── Strings ───────────────────────────────────────────────────────────────
str_chk1:
    .text "CHK1 VECTORS (exp 09 80 27 80): "
    .byte 0
str_chk2:
    .text "CHK2 CBM80 (exp C3 C2 CD 38 30): "
    .byte 0
str_chk3:
    .text "CHK3 LIVE ROML $8000: "
    .byte 0
str_reu:
    .text "     REU  BANK0 $8000: "
    .byte 0
str_done:
    .text "PRESS ANY KEY..."
    .byte 13, 0
