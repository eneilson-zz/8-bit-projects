// t2-test.asm — Stash-It T2 verification
//
// Pure machine code at $C000. No BASIC stub.
// Load with: LOAD"T2-TEST",8,1
// Run with:  SYS 49152  (after pressing RESTORE)
//
// Verifies T2 DMA copied C64 $0000-$7FFF into REU bank 0.
//   CHK1: REU bank 0 $0000-$0001 = ZP DDR + mem config (expect 2F 37)
//   CHK2: REU bank 0 $0318-$0319 = NMI vector (expect 27 80)
//   CHK3: REU bank 0 stack area vs T1 bank 7 reference (should match)

.const CHROUT  = $FFD2
.const SCRATCH = $C300      // scratch above end of program (program ends ~$C210)

* = $C000 "Main"
main:
    // ── CHK1: ZP $0000-$0001 from REU bank 0 ─────────────────────────────
    // $0000 = 6510 DDR (expect $2F)   $0001 = mem config (expect $37)
    lda #<str_chk1
    sta $FB
    lda #>str_chk1
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03           // C64 dest = SCRATCH ($C080)
    lda #$00
    sta $DF04           // REU offset lo = $00
    sta $DF05           // REU offset mi = $00
    sta $DF06           // REU bank = 0
    lda #$02
    sta $DF07           // length = 2 bytes
    lda #$00
    sta $DF08
    sta $DF0A           // addr ctrl = auto-increment both
    lda #$91
    sta $DF01           // execute: REU → C64

    lda SCRATCH         // $0000 DDR (expect $2F)
    jsr print_hex
    lda #32
    jsr CHROUT
    lda SCRATCH+1       // $0001 mem config (expect $37)
    jsr print_hex
    lda #13
    jsr CHROUT

    // ── CHK2: NMI vector $0318-$0319 from REU bank 0 (expect 27 80) ──────
    lda #<str_chk2
    sta $FB
    lda #>str_chk2
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03           // C64 dest = SCRATCH
    lda #$18
    sta $DF04           // REU offset lo = $18
    lda #$03
    sta $DF05           // REU offset mi = $03  → $0318
    lda #$00
    sta $DF06           // REU bank = 0
    lda #$02
    sta $DF07           // length = 2 bytes
    lda #$00
    sta $DF08
    sta $DF0A
    lda #$91
    sta $DF01           // execute: REU → C64

    lda SCRATCH         // lo byte (expect $27)
    jsr print_hex
    lda #32
    jsr CHROUT
    lda SCRATCH+1       // hi byte (expect $80)
    jsr print_hex
    lda #13
    jsr CHROUT

    // ── CHK3: stack snapshot bank 0 vs T1 bank 7 reference ───────────────
    // Fetch SP from REU bank 7 $70006 to locate stack bytes in bank 0
    lda #<str_chk3
    sta $FB
    lda #>str_chk3
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03
    lda #$06
    sta $DF04           // REU offset $0006 = CPU_SP
    lda #$00
    sta $DF05
    lda #$07
    sta $DF06           // bank 7
    lda #$01
    sta $DF07           // length = 1
    lda #$00
    sta $DF08
    sta $DF0A
    lda #$91
    sta $DF01           // REU → C64: fetch SP value into SCRATCH

    lda SCRATCH         // SP value at NMI time
    clc
    adc #$01            // SP+1 = address of Y on stack (page $01)
    sta $DF04           // REU offset lo
    lda #$01
    sta $DF05           // REU offset mi = $01 (stack page)
    lda #$00
    sta $DF06           // bank 0
    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03
    lda #$06
    sta $DF07           // 6 bytes: Y,X,A,SR,PClo,PChi
    lda #$00
    sta $DF08
    sta $DF0A
    lda #$91
    sta $DF01           // REU → C64: stack from bank 0

    ldx #0
!:  lda SCRATCH,x
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #6
    bne !-
    lda #13
    jsr CHROUT

    // Print T1 bank 7 reference for comparison
    lda #<str_t1ref
    sta $FB
    lda #>str_t1ref
    sta $FC
    jsr print_str

    lda #<SCRATCH
    sta $DF02
    lda #>SCRATCH
    sta $DF03
    lda #$00
    sta $DF04
    sta $DF05
    lda #$07
    sta $DF06           // bank 7
    lda #$06
    sta $DF07           // 6 bytes
    lda #$00
    sta $DF08
    sta $DF0A
    lda #$91
    sta $DF01           // REU → C64: T1 data from bank 7

    ldx #0
!:  lda SCRATCH,x
    jsr print_hex
    lda #32
    jsr CHROUT
    inx
    cpx #6
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
str_chk1:  .text "CHK1 ZP $00-01 (exp 2F 37): "
           .byte 0
str_chk2:  .text "CHK2 NMI $0318 (exp 27 80): "
           .byte 0
str_chk3:  .text "CHK3 STACK SNAP (bank0): "
           .byte 0
str_t1ref: .text "     T1 REF    (bank7): "
           .byte 0
str_done:  .text "PRESS ANY KEY..."
           .byte 13, 0
