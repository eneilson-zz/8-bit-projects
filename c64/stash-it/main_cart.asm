// stash-it — Step 3a: DMA CPU registers from stack directly to REU
// 8K cartridge (EXROM=0, GAME=1): ROML $8000-$9FFF only
//
// On NMI: push A/X/Y, then DMA 6 bytes directly from the stack to REU bank 1.
// No user RAM is touched — only I/O registers ($D020, $DF02-$DF0A).
//
// Stack layout after our 3 pushes + hardware 3 (PChi,PClo,SR):
//   $0101+SP = Y
//   $0102+SP = X
//   $0103+SP = A
//   $0104+SP = SR
//   $0105+SP = PClo
//   $0106+SP = PChi
//
// REU bank 1 offset $0000: Y, X, A, SR, PClo, PChi  (6 bytes, stack order)

#import "lib/macros/reu.asm"

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

    // C64 DMA source = $0101 + current SP  (start of our 6 stack bytes)
    // Only writes go to REU I/O registers — no user RAM touched.
    tsx
    txa
    clc
    adc #$01            // A = SP+1 (lo byte of stack DMA address, always in page 1)
    sta REU_C64_ADDR_LO // $DF02
    lda #$01
    sta REU_C64_ADDR_HI // $DF03

    // Border yellow = saving
    lda #$07
    sta $D020

    // DMA 6 bytes from stack → REU bank 1, offset $0000
    reu_set_reu_addr($010000)
    reu_set_length(6)
    reu_set_addr_control($00)
    reu_cmd_c64_to_reu()

    // Border green = done
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
