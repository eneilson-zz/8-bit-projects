// t4-test.asm — Stash-It T4-pre + T4 verification
//
// Pure machine code at $C000. No BASIC stub.
// Load with: LOAD"T4-TEST",8,1
// Run with:  SYS 49152  (after pressing RESTORE)
//
// Verifies:
//   T4-pre: REU bank 7 $70007 = orig $01 (expect $37)
//   T4:     REU bank 0 $A000-$FFFF = RAM-under-ROM snapshot
//
// T4 checks:
//   CHK2: REU bank 0 $A000 — first 4 bytes of RAM under BASIC
//         No fixed expected value; just shows what was there
//   CHK3: REU bank 0 $A000 vs live $A000 — these should DIFFER
//         (REU has RAM, live read returns BASIC ROM) — proves $01=$34 trick worked
//   CHK4: REU bank 0 $FF00 — last 256 bytes area (RAM under Kernal vectors)
//         Shows first 4 bytes; no fixed expected value

.const CHROUT  = $FFD2
.const SCRATCH = $C300      // scratch above program end

* = $C000 "Main"
main:
    // ── CHK1: T4-pre — orig $01 from REU bank 7 $70007 (expect $37) ──────
    lda #<str_chk1
    sta $FB
    lda #>str_chk1
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03           // C64 dest = SCRATCH
    lda #$07
    sta $DF04           // REU offset lo = $07  (MEM_CONFIG byte)
    lda #$00
    sta $DF05           // REU offset mi = $00
    lda #$07
    sta $DF06           // REU bank = 7
    lda #$01
    sta $DF07           // length = 1 byte
    lda #$00
    sta $DF08
    sta $DF0A           // addr ctrl = auto-increment both
    lda #$91
    sta $DF01           // execute: REU → C64

    lda SCRATCH
    jsr print_hex
    lda #13
    jsr CHROUT

    // ── CHK2: RAM under BASIC — REU bank 0 $A000, first 4 bytes ──────────
    // No fixed expected value; shows what was in RAM under BASIC at freeze time
    lda #<str_chk2
    sta $FB
    lda #>str_chk2
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03
    lda #$00
    sta $DF04           // REU offset lo = $00
    lda #$A0
    sta $DF05           // REU offset mi = $A0  → REU offset $A000
    lda #$00
    sta $DF06           // REU bank = 0
    lda #$04
    sta $DF07           // length = 4 bytes
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
    cpx #4
    bne !-
    lda #13
    jsr CHROUT

    // ── CHK3: REU bank 0 $A000 vs live $A000 — should DIFFER ─────────────
    // REU has RAM bytes (captured with $01=$34)
    // Live $A000 with $01=$37 returns BASIC ROM bytes (expect $94 $E3 or similar)
    // If they differ, the $01=$34 trick worked correctly
    lda #<str_chk3a
    sta $FB
    lda #>str_chk3a
    sta $FC
    jsr print_str

    // Print live $A000 (BASIC ROM, $01=$37)
    ldx #0
!:  lda $A000,x
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #4
    bne !-
    lda #13
    jsr CHROUT

    lda #<str_chk3b
    sta $FB
    lda #>str_chk3b
    sta $FC
    jsr print_str

    // Print REU bank 0 $A000 (RAM under BASIC, captured with $01=$34)
    // Already in SCRATCH from CHK2 — reprint it
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

    // ── CHK4: RAM under Kernal — REU bank 0 $FF00, first 4 bytes ─────────
    lda #<str_chk4
    sta $FB
    lda #>str_chk4
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03
    lda #$00
    sta $DF04           // REU offset lo = $00
    lda #$FF
    sta $DF05           // REU offset mi = $FF  → REU offset $FF00
    lda #$00
    sta $DF06           // REU bank = 0
    lda #$04
    sta $DF07           // length = 4 bytes
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
    cpx #4
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
    .text "CHK1 ORIG $01 BANK7 (exp 37): "
    .byte 0
str_chk2:
    .text "CHK2 RAM UNDER BASIC $A000: "
    .byte 0
str_chk3a:
    .text "CHK3 LIVE $A000 (BASIC ROM): "
    .byte 0
str_chk3b:
    .text "     REU  $A000 (RAM): "
    .byte 0
str_chk4:
    .text "CHK4 RAM UNDER KERNAL $FF00: "
    .byte 0
str_done:
    .text "PRESS ANY KEY..."
    .byte 13, 0
