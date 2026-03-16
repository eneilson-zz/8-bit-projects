// t1-test.asm — Stash-It T1 verification
//
// Pure machine code at $C000. No BASIC stub.
// Load with: LOAD"T1-TEST",8,1
// Run with:  SYS 49152  (after pressing RESTORE)
//
// Verifies T1 DMA captured Y,X,A,SR,PClo,PChi into REU bank 7 $70000-$70005.

.const CHROUT = $FFD2

* = $C000 "Main"
main:
    // ── DMA: REU bank 7 $70000 → $C200, 6 bytes ───────────────────────────
    lda #$80
    sta $DF02           // C64 dest lo = $80
    lda #$C0
    sta $DF03           // C64 dest hi = $C0  → $C200
    lda #$00
    sta $DF04           // REU addr lo = $00
    sta $DF05           // REU addr mi = $00
    lda #$07
    sta $DF06           // REU bank = 7
    lda #$06
    sta $DF07           // length = 6 bytes
    lda #$00
    sta $DF08
    sta $DF0A           // addr ctrl = auto-increment both
    lda #$91
    sta $DF01           // execute: REU → C64

    // ── Print header ──────────────────────────────────────────────────────
    lda #<str_header
    sta $FB
    lda #>str_header
    sta $FC
    jsr print_str

    // ── Print 6 bytes with labels ─────────────────────────────────────────
    ldx #0
print_loop:
    lda label_lo,x
    sta $FB
    lda label_hi,x
    sta $FC
    jsr print_str
    lda $C200,x         // fetched REU byte
    jsr print_hex
    lda #13
    jsr CHROUT
    inx
    cpx #6
    bne print_loop

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
str_header: .text "T1 REU BANK7 SNAPSHOT"
            .byte 13, 0
str_done:   .text "PRESS ANY KEY..."
            .byte 13, 0

// ASCII: Y=89 X=88 A=65 S=83 R=82 P=80 C=67 L=76 H=72 space=32 colon=58
lbl_y:   .byte 89, 32, 32, 58, 32, 0
lbl_x:   .byte 88, 32, 32, 58, 32, 0
lbl_a:   .byte 65, 32, 32, 58, 32, 0
lbl_sr:  .byte 83, 82, 32, 58, 32, 0
lbl_pcl: .byte 80, 67, 76, 58, 32, 0
lbl_pch: .byte 80, 67, 72, 58, 32, 0

label_lo: .byte <lbl_y, <lbl_x, <lbl_a, <lbl_sr, <lbl_pcl, <lbl_pch
label_hi: .byte >lbl_y, >lbl_x, >lbl_a, >lbl_sr, >lbl_pcl, >lbl_pch
