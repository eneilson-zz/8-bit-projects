// stash-it — Step 2: NMI intercept
// 8K cartridge (EXROM=0, GAME=1): ROML $8000-$9FFF only
//
// 8K mode keeps BASIC ($A000-$BFFF) and Kernal ($E000-$FFFF) fully intact.
// After init, we JMP to BASIC cold start — system boots normally to READY prompt.
// NMI routing:
//   Hardware NMI → Kernal $FE43 (SEI + JMP ($0318))
//   coldStart patches $0318 → our nmiHandler before handing off to BASIC

* = $8000 "ROML"

// ── Cartridge Header ───────────────────────────────────────────────────────
//    $8000-$8001  RESET/cold-start vector  (Kernal does JMP ($8000) after finding CBM80)
//    $8002-$8003  NMI vector               (unused in 8K mode — we patch $0318 instead)
//    $8004-$8008  "CBM80" signature        (required for Kernal to detect cart)
.word coldStart
.word nmiHandler
.byte $C3, $C2, $CD, $38, $30

// ── Cold Start ─────────────────────────────────────────────────────────────
// The Kernal calls us via JMP ($8000) before completing its own init.
// We use ONLY the stable Kernal jump table entries ($FF81-$FF8A) so this
// works with any Kernal ROM: stock, JiffyDOS, EXOS, etc.
// After RESTOR resets $0318 to the default handler, we re-patch it.
// JMP ($A000) reads the BASIC warm-start vector from BASIC ROM — also stable.
coldStart:
    sei
    cld
    ldx #$FF
    txs

    jsr $FF84           // IOINIT — init I/O: sets $01=$37, VIC, SID, CIA
    jsr $FF87           // RAMTAS — RAM test, clear zero page
    jsr $FF8A           // RESTOR — restore default RAM vectors (resets $0318)
    jsr $FF81           // CINT   — init screen editor

    // Patch NMI vector now (after RESTOR, which reset $0318 to Kernal default)
    lda #<nmiHandler
    sta $0318
    lda #>nmiHandler
    sta $0319

    jmp ($A000)         // jump through BASIC warm-start vector in BASIC ROM

// ── NMI Handler ───────────────────────────────────────────────────────────
// Called when cartridge button is pressed (Cmd-Z in VICE)
// Proof of intercept: cycles border color on each press
nmiHandler:
    pha
    txa
    pha
    tya
    pha

    inc $D020           // cycle border color — visible proof NMI was caught

    pla
    tay
    pla
    tax
    pla
    rti

// ── Pad ROML to full 8K ($8000-$9FFF) ────────────────────────────────────
.fill $A000 - *, $EA
