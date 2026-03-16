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
//   T5  orig SP             → REU bank 7 $70006  (after snapshot complete)
//
// REU bank 7 CPU state block ($70000, 8 bytes):
//   $70000  Y      $70001  X       $70002  A      $70003  SR
//   $70004  PClo   $70005  PChi    $70006  SP     $70007  orig $01
//
// Only I/O registers are written before snapshot completes.
// $FE (ZP scratch for SP) is written AFTER 64K snapshot is safely in REU.

#import "lib/macros/reu.asm"

// ── REU Bank Layout ────────────────────────────────────────────────────────
// Banks 0-6: user memory snapshots (7 slots, one 64K image each)
// Bank 7:    stash-it housekeeping (CPU state, bank labels, metadata)
.const REU_USER_BANKS       = 7          // number of user snapshot slots
.const REU_HOUSEKEEPING_BANK = 7         // bank 7 = $70000-$7FFFF

// Bank 7 CPU state block layout (8 bytes at $70000)
.const REU_CPU_STATE_BASE   = $070000
.const REU_CPU_Y            = $070000
.const REU_CPU_X            = $070001
.const REU_CPU_A            = $070002
.const REU_CPU_SR           = $070003
.const REU_CPU_PCLO         = $070004
.const REU_CPU_PCHI         = $070005
.const REU_CPU_SP           = $070006
.const REU_CPU_MEM_CONFIG   = $070007    // orig $01 (memory map config at NMI)

// User snapshot: each bank N occupies REU $N0000-$NFFFF
// Snapshot sub-regions within each bank:
.const REU_SNAP_LO_RAM      = $00000     // C64 $0000-$7FFF (32K)
.const REU_SNAP_ROML        = $08000     // C64 $8000-$9FFF (8K, ROM bytes)
.const REU_SNAP_HI_RAM      = $0A000     // C64 $A000-$FFFF (24K, RAM-under-ROM)

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

    jsr $FF84           // IOINIT
    jsr $FF87           // RAMTAS
    jsr $FF8A           // RESTOR
    jsr $FF81           // CINT

    lda #<nmiHandler
    sta $0318
    lda #>nmiHandler
    sta $0319

    jmp ($A000)

// ── NMI Handler ───────────────────────────────────────────────────────────
nmiHandler:
    pha
    txa
    pha
    tya
    pha
    // Stack after our 3 + hardware 3 (SR,PClo,PChi):
    //   SP+1=Y  SP+2=X  SP+3=A  SP+4=SR  SP+5=PClo  SP+6=PChi

    // Border yellow = saving
    lda #$07
    sta $D020

    // ── T1: 6 CPU regs from stack → REU_CPU_STATE_BASE (bank 7) ─────────
    tsx
    txa
    clc
    adc #$01            // C64 addr lo = SP+1 (bottom of saved regs)
    sta REU_C64_ADDR_LO
    lda #$01
    sta REU_C64_ADDR_HI // page 1
    reu_set_reu_addr(REU_CPU_STATE_BASE)
    reu_set_length(6)
    reu_set_addr_control($00)
    reu_cmd_c64_to_reu()

    // ── T2: $0000-$7FFF → REU bank 0, REU_SNAP_LO_RAM (32K pure RAM) ────
    reu_set_c64_addr($0000)
    reu_set_reu_addr(REU_SNAP_LO_RAM)
    reu_set_length($8000)
    reu_cmd_c64_to_reu()

    // ── T3: $8000-$9FFF → REU bank 0, REU_SNAP_ROML (8K ROML) ───────────
    // Saves our ROM bytes — EXROM tied low, cannot expose RAM underneath
    reu_set_c64_addr($8000)
    reu_set_reu_addr(REU_SNAP_ROML)
    reu_set_length($2000)
    reu_cmd_c64_to_reu()

    // ── T4-pre: save orig $01 → REU_CPU_MEM_CONFIG (before changing it) ──
    reu_set_c64_addr($0001)
    reu_set_reu_addr(REU_CPU_MEM_CONFIG)
    reu_set_length(1)
    reu_cmd_c64_to_reu()

    // ── T4: $A000-$FFFF → REU bank 0, REU_SNAP_HI_RAM (24K RAM-under-ROM)
    // $01=$34: HIRAM=0 LORAM=0 CHAREN=1
    //   → BASIC+Kernal ROM hidden, RAM exposed; I/O still live at $D000
    lda #$34
    sta $01
    reu_set_c64_addr($A000)
    reu_set_reu_addr(REU_SNAP_HI_RAM)
    reu_set_length($6000)
    reu_cmd_c64_to_reu()
    lda #$37            // restore: HIRAM=1 LORAM=1 CHAREN=1
    sta $01

    // ── T5: orig SP → REU_CPU_SP (bank 7) ────────────────────────────────
    // 64K snapshot complete — safe to use ZP scratch now
    // orig SP = SP_after_our_3_pushes + 6 (3 hw pushes + 3 ours)
    tsx
    txa
    clc
    adc #$06
    sta $FE             // ZP scratch (snapshot already in REU)
    reu_set_c64_addr($00FE)
    reu_set_reu_addr(REU_CPU_SP)
    reu_set_length(1)
    reu_cmd_c64_to_reu()

    // Border green = save complete
    lda #$05
    sta $D020

    pla
    tay
    pla
    tax
    pla
    rti

// ── Pad ROML to full 8K ────────────────────────────────────────────────────
.fill $A000 - *, $EA
