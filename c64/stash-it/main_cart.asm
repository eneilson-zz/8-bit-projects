// stash-it — Step 3: Full 64K snapshot + CPU state → REU
// 8K cartridge (EXROM=0, GAME=1): ROML $8000-$9FFF only
//
// REU layout:
//   Banks 0-6  User memory snapshots (one 64K slot per bank)
//   Bank 7     Stash-it housekeeping: CPU state, bank labels, metadata
//
// NMI handler performs 5 DMA passes:
//
//   T1  Stack (6 bytes)     → REU bank 7 $70000  CPU regs: Y,X,A,SR,PClo,PChi
//   T2  C64 $0000-$7FFF     → REU bank 0 $00000  32K pure RAM
//   T3  C64 $8000-$9FFF     → REU bank 0 $08000  8K ROML (ROM bytes, hw limit)
//   T4-pre: save orig $01   → REU bank 7 $70007  (before changing $01)
//   T4  C64 $A000-$FFFF     → REU bank 0 $0A000  24K RAM-under-ROM ($01=$34)
//   T5  orig SP (via $D020) → REU bank 7 $70006  (fixed C64 addr, no ZP)
//
// REU bank 7 CPU state block ($70000, 8 bytes):
//   $70000  Y      $70001  X       $70002  A      $70003  SR
//   $70004  PClo   $70005  PChi    $70006  SP     $70007  orig $01
//
// No user RAM is written at any point. SP is staged via $D020 (border color
// register) and DMA'd with fixed C64 address — no ZP scratch required.
//
// REU registers ($DF00-$DF0A):
//   $DF00  STATUS     read-only: bit6=EOB, bit5=verify fault, bit4=REU size
//   $DF01  COMMAND    $90=C64→REU  $91=REU→C64  $92=swap  $93=verify
//   $DF02  C64_LO     C64 address low byte
//   $DF03  C64_HI     C64 address high byte
//   $DF04  REU_LO     REU address low byte
//   $DF05  REU_MI     REU address middle byte
//   $DF06  REU_HI     REU address high byte / bank select
//   $DF07  LEN_LO     transfer length low byte
//   $DF08  LEN_HI     transfer length high byte
//   $DF09  IRQ_MASK   interrupt enable bits
//   $DF0A  ADDR_CTRL  bit7=C64 addr fixed, bit6=REU addr fixed

// ── REU Bank Layout ────────────────────────────────────────────────────────
// Banks 0-6: user memory snapshots (7 slots, one 64K image each)
// Bank 7:    stash-it housekeeping (CPU state, bank labels, metadata)
.const REU_USER_BANKS        = 7         // number of user snapshot slots
.const REU_HOUSEKEEPING_BANK = 7         // bank 7 = $70000-$7FFFF

// Bank 7 CPU state block layout (8 bytes at $70000)
.const REU_CPU_Y             = $70000
.const REU_CPU_X             = $70001
.const REU_CPU_A             = $70002
.const REU_CPU_SR            = $70003
.const REU_CPU_PCLO          = $70004
.const REU_CPU_PCHI          = $70005
.const REU_CPU_SP            = $70006
.const REU_CPU_MEM_CONFIG    = $70007    // orig $01 (memory map config at NMI)

// User snapshot sub-regions (offsets within each bank, bank byte set separately)
.const REU_SNAP_LO_RAM       = $0000     // C64 $0000-$7FFF (32K)  bank 0
.const REU_SNAP_ROML         = $8000     // C64 $8000-$9FFF (8K)   bank 0
.const REU_SNAP_HI_RAM       = $A000     // C64 $A000-$FFFF (24K)  bank 0

* = $8000 "ROML"

// ── Cartridge Header ───────────────────────────────────────────────────────
.word coldStart
.word nmiHandler
.byte $C3, $C2, $CD, $38, $30

// ── Cold Start ─────────────────────────────────────────────────────────────
coldStart:
    sei
    cld
    ldx #$FF
    txs

    jsr $FF84           // IOINIT  — init CIA, SID, VIC
    jsr $FF87           // RAMTAS  — test RAM, set top/bottom pointers
    jsr $FF8A           // RESTOR  — restore $0314-$0333 NMI/IRQ vectors to default
    jsr $FF81           // CINT    — init screen editor, clear screen

    // Patch NMI vector to our handler (must be after RESTOR resets $0318)
    lda #<nmiHandler
    sta $0318
    lda #>nmiHandler
    sta $0319

    jmp ($A000)         // jump through BASIC warm-start vector → BASIC ready prompt

// ── NMI Handler ───────────────────────────────────────────────────────────
// Entered when RESTORE key pressed (or cartridge button on real hardware).
// Hardware has already pushed PChi, PClo, SR onto stack.
// We push A, X, Y — stack layout after all 6 pushes (SP pointing below Y):
//   $01,SP+1 = Y    $01,SP+2 = X    $01,SP+3 = A
//   $01,SP+4 = SR   $01,SP+5 = PClo $01,SP+6 = PChi
nmiHandler:
    pha                 // push A
    txa
    pha                 // push X
    tya
    pha                 // push Y

    // Border yellow = snapshot in progress
    lda #$07
    sta $D020

    // ── T1: 6 CPU regs from stack → REU bank 7 $70000-$70005 ─────────────
    // Source: stack page $01xx starting at SP+1 (bottom of saved regs = Y)
    // Dest:   REU bank 7 offset $0000 (Y,X,A,SR,PClo,PChi in that order)
    tsx                 // X = current SP
    txa
    clc
    adc #$01            // A = SP+1 = address of Y on stack (low byte, page $01)
    sta $DF02           // C64 addr lo = SP+1
    lda #$01
    sta $DF03           // C64 addr hi = $01 (stack page)
    lda #$00
    sta $DF04           // REU addr lo = $00
    sta $DF05           // REU addr mi = $00
    lda #$07
    sta $DF06           // REU addr hi = $07 (bank 7)
    lda #$06
    sta $DF07           // length lo = 6 bytes
    lda #$00
    sta $DF08           // length hi = 0
    sta $DF0A           // addr ctrl = $00: auto-increment both C64 and REU sides
    lda #$90
    sta $DF01           // execute: C64 → REU

    // ── T2: C64 $0000-$7FFF → REU bank 0 $0000-$7FFF (32K pure RAM) ─────
    lda #$00
    sta $DF02           // C64 addr lo = $00
    sta $DF03           // C64 addr hi = $00  (start of RAM at $0000)
    sta $DF04           // REU addr lo = $00
    sta $DF05           // REU addr mi = $00
    sta $DF06           // REU addr hi = $00  (bank 0)
    lda #$00
    sta $DF07           // length lo = $00
    lda #$80
    sta $DF08           // length hi = $80  → $8000 = 32768 bytes
    lda #$00
    sta $DF0A           // addr ctrl = auto-increment both
    lda #$90
    sta $DF01           // execute: C64 → REU

    // ── T3: C64 $8000-$9FFF → REU bank 0 $8000-$9FFF (8K ROML) ──────────
    // EXROM tied low = ROML always visible; saves ROM bytes not RAM underneath
    lda #$00
    sta $DF02           // C64 addr lo = $00
    lda #$80
    sta $DF03           // C64 addr hi = $80  ($8000)
    lda #$00
    sta $DF04           // REU addr lo = $00
    lda #$80
    sta $DF05           // REU addr mi = $80  (REU offset $8000 within bank 0)
    lda #$00
    sta $DF06           // REU addr hi = $00  (bank 0)
    lda #$00
    sta $DF07           // length lo = $00
    lda #$20
    sta $DF08           // length hi = $20  → $2000 = 8192 bytes
    lda #$00
    sta $DF0A           // addr ctrl = auto-increment both
    lda #$90
    sta $DF01           // execute: C64 → REU

    // ── T4-T5 disabled for T3 isolation testing ───────────────────────────
    // T4-pre: orig $01    → REU bank 7 $70007
    // T4: C64 $A000-$FFFF → REU bank 0
    // T5: orig SP         → REU bank 7 $70006

    // Border green = snapshot complete
    lda #$05
    sta $D020

    pla
    tay                 // restore Y
    pla
    tax                 // restore X
    pla                 // restore A
    rti                 // restore SR, PC from stack → resume interrupted code

// ── Pad ROML to full 8K ────────────────────────────────────────────────────
.fill $A000 - *, $EA
