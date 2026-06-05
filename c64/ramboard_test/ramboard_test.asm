//==============================================================================
// ramboard_test.asm — C64 RAMBoard tester, re-implemented in all 6502 assembly
// (C) CLD '89 WITH UPDATES BY ERIC NEILSON in 2026
//
// Faithful reproduction of playground/ramboard test.prg.
//   * HOST (C64): UI + DOS command-channel protocol. Uploads a 6502 routine to
//     the drive via "M-W", executes it via "M-E", reads the result back via
//     "M-R", prints Passed / Failed @ $hhhh.
//   * DRIVE (drive 6502): N-pass XOR fill/verify test of an 8 KB window
//     ($8000-$9FFF). byte = addr_lo EOR addr_hi. First mismatch -> fail address.
//   * MODIFIED to support more expanded RAM areas:
//     $8000 (default), $2000, $4000, $6000, $A000.
//
// Build: scripts/build.sh  (or `make`)  ->  bin/ramboard test.d64
// Run:   LOAD"*",8,1  then  RUN
//==============================================================================

//------------------------------------------------------------------------------
// Constants
//------------------------------------------------------------------------------
.const DRIVE_LOAD   = $0500     // where the routine is M-W'd into drive RAM
.const WIN_LO_PAGE  = $80       // default test window start page ($8000)
.const WIN_SPAN     = $20       // window size in pages ($20 = 8 KB)
.const WIN_HI_PAGE  = WIN_LO_PAGE + WIN_SPAN  // default end page, exclusive
.const DEFAULT_PASS = $02       // default number of passes

// PETSCII control codes
.const CR     = $0d             // carriage return
.const CSR_L  = $9d             // cursor left (back over a printed default)

// PETSCII color control codes (set the text color from here on)
.const COL_WHITE = $05          // body text
.const COL_CYAN  = $9f          // banner
.const COL_GREEN = $1e          // PASSED
.const COL_RED   = $1c          // FAILED
.const COL_GRAY  = $9b          // credit line (medium gray)

// VIC-II color registers + chosen palette (black bg/border, white text)
.const VIC_BORDER = $D020
.const VIC_BKGND  = $D021
.const C64_BLACK  = $00

.const CMD_LFN      = $0F       // logical file # for the command channel
.const CMD_DEV_DEF  = $08       // default device number
.const CMD_SA       = $0F       // secondary address 15 = command/error channel

// KERNAL entry points
.const SETLFS = $FFBA
.const SETNAM = $FFBD
.const OPEN   = $FFC0
.const CLOSE  = $FFC3
.const CHKIN  = $FFC6
.const CHKOUT = $FFC9
.const CLRCHN = $FFCC
.const CHRIN  = $FFCF
.const CHROUT = $FFD2
.const GETIN  = $FFE4
.const STOP   = $FFE1

// All on-screen text is sent through CHROUT, so encode .text as PETSCII (not
// the KickAss default screencode, where '@' assembles to $00 and would
// prematurely terminate NUL-terminated strings).
.encoding "petscii_upper"

// Host zero-page scratch
.const zp_src   = $FB           // 16-bit source pointer (blob upload)
.const zp_cnt   = $FD           // byte counter

// Drive-blob metrics. Defined here (with forward label refs resolved in the
// symbol pass) so host immediates like `lda #drive_blob_len` evaluate in pass 1.
.const drive_blob_len = drive_blob_end - drive_blob
.const result_offset  = d_result - drive_test

//==============================================================================
// BASIC autostart
//==============================================================================
BasicUpstart2(host_main)

* = $0810 "Host code"

//==============================================================================
// HOST: main flow
//==============================================================================
host_main:
        lda #C64_BLACK          // black border + background
        sta VIC_BORDER
        sta VIC_BKGND
        lda #COL_WHITE          // default body text color = white
        jsr CHROUT
        lda #$93                // clear screen (under white)
        jsr CHROUT
        jsr print_banner

        jsr prompt_device       // -> device
        jsr prompt_area         // -> win_lo / win_hi
        jsr prompt_passes       // -> passes

        jsr open_command_channel
        jsr upload_drive_routine
        jsr exec_drive_routine
        jsr read_result         // -> result_code, fail_lo, fail_hi

        jsr close_channel

        lda result_code
        bne show_fail
        jsr print_passed
        jmp restart
show_fail:
        jsr print_failed        // prints "Failed @ $" + hex address
restart:
        jsr print_restart
        jsr wait_key
        jmp host_main

//==============================================================================
// HOST: prompts
//
// UI model: print the prompt label (ending in ": "), then print the current
// default DIGIT, then a cursor-left so the flashing cursor sits ON TOP of the
// default. The editor reads the whole logical screen line on RETURN, so:
//   * just pressing RETURN returns the default digit that's still on screen,
//   * typing a digit overwrites it and returns the new value.
// We read the first char CHRIN gives back, validate it, and on invalid input
// keep the default. After input we emit two CRs for spacing.
//==============================================================================

// Device number: single digit (8 or 9); default 8. (10-15 would need two-digit
// entry; out of scope for now.)
prompt_device:
        ldx #<txt_dev
        ldy #>txt_dev
        jsr print_str
        lda device              // show current default at the input point...
        clc
        adc #$30                // value -> ascii digit
        jsr CHROUT
        lda #CSR_L              // ...and back the cursor onto it
        jsr CHROUT

        jsr CHRIN               // first char of the logical line
        pha
        jsr flush_line          // consume rest of line incl. CR
        pla
        sec
        sbc #$30                // ascii -> value
        cmp #$08
        bcc pd_done             // < 8 -> ignore, keep default
        cmp #$10
        bcs pd_done             // > 15 -> ignore
        sta device
pd_done:
        jsr crlf2               // two CRs of spacing after the input
        rts

// Passes: single digit 1-9; default DEFAULT_PASS.
prompt_passes:
        ldx #<txt_pass
        ldy #>txt_pass
        jsr print_str
        lda passes
        clc
        adc #$30
        jsr CHROUT
        lda #CSR_L
        jsr CHROUT

        jsr CHRIN
        pha
        jsr flush_line
        pla
        sec
        sbc #$30
        cmp #$01
        bcc pp_done
        cmp #$0a
        bcs pp_done
        sta passes
pp_done:
        jsr crlf2
        rts

// Test area: a numbered menu of 5 fixed 8 KB windows; user types 1-5, CR
// accepts the default (1 = $8000). The selection (1..5) indexes area_pages[]
// for the start page; the end page is start + WIN_SPAN (8 KB). The resolved
// start/end pages are written to win_lo/win_hi for the upload step to poke.
prompt_area:
        ldx #<txt_area          // the multi-line menu + "SELECT (1-5): "
        ldy #>txt_area
        jsr print_str
        lda area_sel            // show current default index at the input point
        clc
        adc #$30
        jsr CHROUT
        lda #CSR_L
        jsr CHROUT

        jsr CHRIN
        pha
        jsr flush_line
        pla
        sec
        sbc #$30                // ascii -> index value
        cmp #$01
        bcc pa_resolve          // < 1 -> keep default
        cmp #$06
        bcs pa_resolve          // > 5 -> keep default
        sta area_sel
pa_resolve:
        // win_lo = area_pages[area_sel-1]; win_hi = win_lo + WIN_SPAN
        ldx area_sel
        dex                     // 0-based index
        lda area_pages,x
        sta win_lo
        clc
        adc #WIN_SPAN
        sta win_hi
        jsr crlf2
        rts

// Consume the rest of the input line up to and including the CR.
flush_line:
        jsr CHRIN
        cmp #CR
        bne flush_line
        rts

// Emit two carriage returns (a blank line of spacing).
crlf2:
        lda #CR
        jsr CHROUT
        lda #CR
        jmp CHROUT

//==============================================================================
// HOST: command-channel helpers
//==============================================================================
open_command_channel:
        lda #CMD_LFN
        ldx device
        ldy #CMD_SA
        jsr SETLFS
        lda #$00                // empty filename
        jsr SETNAM
        jsr OPEN
        rts

close_channel:
        lda #CMD_LFN
        jsr CLOSE
        jsr CLRCHN
        rts

// Upload drive_blob (drive_blob_len bytes) to drive RAM at DRIVE_LOAD using a
// single "M-W" command (blob is well under the 34-byte-per-MW guideline? No —
// it can exceed it, so chunk it in <=32-byte pieces).
.const MW_CHUNK = 32

upload_drive_routine:
        // patch the run-time parameters into the blob before sending
        lda passes
        sta drive_passes_cell
        lda win_lo
        sta drive_winlo_cell
        lda win_hi
        sta drive_winhi_cell

        // set up source pointer and remaining count
        lda #<drive_blob
        sta zp_src
        lda #>drive_blob
        sta zp_src+1
        lda #<DRIVE_LOAD
        sta mw_addr_lo
        lda #>DRIVE_LOAD
        sta mw_addr_hi
        lda #drive_blob_len
        sta mw_remaining

uw_next:
        lda mw_remaining
        beq uw_done
        cmp #MW_CHUNK
        bcc uw_have_count       // remaining < chunk -> send remaining
        lda #MW_CHUNK
uw_have_count:
        sta mw_count            // bytes in this M-W

        jsr CLRCHN
        ldx #CMD_LFN
        jsr CHKOUT

        // "M-W" + addr_lo + addr_hi + count
        lda #$4d                // 'M'
        jsr CHROUT
        lda #$2d                // '-'
        jsr CHROUT
        lda #$57                // 'W'
        jsr CHROUT
        lda mw_addr_lo
        jsr CHROUT
        lda mw_addr_hi
        jsr CHROUT
        lda mw_count
        jsr CHROUT

        // data bytes
        ldy #$00
uw_data:
        cpy mw_count
        beq uw_data_done
        lda (zp_src),y
        jsr CHROUT
        iny
        bne uw_data
uw_data_done:
        jsr CLRCHN

        // advance source pointer by mw_count
        lda zp_src
        clc
        adc mw_count
        sta zp_src
        bcc uw_no_carry
        inc zp_src+1
uw_no_carry:
        // advance drive target address by mw_count
        lda mw_addr_lo
        clc
        adc mw_count
        sta mw_addr_lo
        bcc uw_no_carry2
        inc mw_addr_hi
uw_no_carry2:
        // remaining -= mw_count
        lda mw_remaining
        sec
        sbc mw_count
        sta mw_remaining
        jmp uw_next
uw_done:
        rts

// Execute the uploaded routine on the drive: "M-E" + addr_lo + addr_hi.
exec_drive_routine:
        jsr CLRCHN
        ldx #CMD_LFN
        jsr CHKOUT
        lda #$4d                // 'M'
        jsr CHROUT
        lda #$2d                // '-'
        jsr CHROUT
        lda #$45                // 'E'
        jsr CHROUT
        lda #<DRIVE_LOAD
        jsr CHROUT
        lda #>DRIVE_LOAD
        jsr CHROUT
        jsr CLRCHN
        rts

// Read the 3 result cells back from drive RAM with "M-R" + addr_lo + addr_hi +
// count. The drive returns <count> bytes on the channel.
read_result:
        jsr CLRCHN
        ldx #CMD_LFN
        jsr CHKOUT
        lda #$4d                // 'M'
        jsr CHROUT
        lda #$2d                // '-'
        jsr CHROUT
        lda #$52                // 'R'
        jsr CHROUT
        lda #<(DRIVE_LOAD + result_offset)
        jsr CHROUT
        lda #>(DRIVE_LOAD + result_offset)
        jsr CHROUT
        lda #$03                // read 3 bytes
        jsr CHROUT
        jsr CLRCHN

        ldx #CMD_LFN
        jsr CHKIN
        jsr CHRIN
        sta result_code
        jsr CHRIN
        sta fail_lo
        jsr CHRIN
        sta fail_hi
        jsr CLRCHN
        rts

//==============================================================================
// HOST: output helpers
//==============================================================================
print_banner:
        ldx #<txt_banner
        ldy #>txt_banner
        jmp print_str

print_passed:
        ldx #<txt_passed
        ldy #>txt_passed
        jmp print_str

print_restart:
        ldx #<txt_restart
        ldy #>txt_restart
        jmp print_str

print_failed:
        ldx #<txt_failed
        ldy #>txt_failed
        jsr print_str
        lda fail_hi
        jsr print_hex_byte
        lda fail_lo
        jsr print_hex_byte
        lda #COL_WHITE          // back to white for the restart prompt
        jsr CHROUT
        lda #CR
        jmp CHROUT

// Print a NUL-terminated string at X(lo)/Y(hi).
print_str:
        stx zp_src
        sty zp_src+1
        ldy #$00
ps_loop:
        lda (zp_src),y
        beq ps_done
        jsr CHROUT
        iny
        bne ps_loop
ps_done:
        rts

// A -> two PETSCII hex digits (high nibble first).
print_hex_byte:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr nibble
        pla
        and #$0f
nibble:
        and #$0f
        cmp #$0a
        bcc nb_dig
        clc
        adc #$07                // 'A'-'9'-1
nb_dig:
        adc #$30
        jmp CHROUT

wait_key:
        jsr GETIN
        beq wait_key
        rts

//==============================================================================
// HOST: data
//==============================================================================
device:         .byte CMD_DEV_DEF
passes:         .byte DEFAULT_PASS
result_code:    .byte $00
fail_lo:        .byte $00
fail_hi:        .byte $00

// Test-area selection. area_sel is the 1-based menu choice (default 1 = $8000);
// area_pages[] maps it to a start page. win_lo/win_hi are the resolved start +
// end (exclusive) pages poked into the drive blob before upload.
area_sel:       .byte $01
win_lo:         .byte WIN_LO_PAGE
win_hi:         .byte WIN_HI_PAGE
area_pages:     .byte $80, $20, $40, $60, $A0   // $8000,$2000,$4000,$6000,$A000

mw_addr_lo:     .byte $00
mw_addr_hi:     .byte $00
mw_count:       .byte $00
mw_remaining:   .byte $00

txt_banner:  .byte COL_CYAN         // title in cyan...
             .text "RAMBOARD 1541/41C/41-II/71 TESTER"
             .byte CR
             .byte COL_GRAY         // ...credit in gray, on one line
             .text "(C) CLD '89 WITH UPDATES BY ERIC NEILSON"
             .byte COL_WHITE        // back to white for the prompts
             .byte CR, CR, $00      // two CRs of spacing after the banner
txt_dev:     .text "DEVICE # (8-15): "
             .byte $00              // default digit printed at the input point
txt_area:    .text "EXPANDED RAM LOCATION (8K):"
             .byte CR
             .text "  1. $8000  (DEFAULT)"
             .byte CR
             .text "  2. $2000"
             .byte CR
             .text "  3. $4000"
             .byte CR
             .text "  4. $6000"
             .byte CR
             .text "  5. $A000"
             .byte CR
             .text "SELECT (1-5): "
             .byte $00
txt_pass:    .text "PASSES (1-9): "
             .byte $00
txt_passed:  .byte COL_GREEN
             .text "PASSED."
             .byte COL_WHITE, CR, $00
txt_failed:  .byte COL_RED
             .text "FAILED @ $"
             .byte $00              // hex address + CR appended by print_failed
txt_restart: .byte CR               // blank line, then the restart prompt
             .text "HIT A KEY TO RESTART."
             .byte CR, $00

//==============================================================================
// DRIVE-SIDE ROUTINE
// Assembled to run at DRIVE_LOAD in the drive's address space; the bytes are
// stored here (drive_blob..drive_blob_end) for the host to M-W upload.
//
// N-pass XOR fill/verify of [WIN_LO_PAGE, WIN_HI_PAGE) pages. On the first
// verify mismatch, store the failing address and set result_code=2; otherwise
// after all passes set result_code=0. Result cells sit at a fixed offset so the
// host can M-R them back.
//==============================================================================
.const d_ptr  = $C0             // drive zero-page pointer ($C0/$C1)

drive_blob:
.pseudopc DRIVE_LOAD {
drive_test:
        sei
        ldx d_passes            // pass counter
d_pass:
        // ---- FILL ----
        ldy #$00
        sty d_ptr
        lda d_winlo             // window start page (poked by host)
        sta d_ptr+1
d_fill:
        lda d_ptr
        eor d_ptr+1             // pattern = lo EOR hi
        sta (d_ptr),y
        inc d_ptr
        bne d_fill
        inc d_ptr+1
        lda d_ptr+1
        cmp d_winhi             // window end page, exclusive (poked by host)
        bne d_fill

        // ---- VERIFY ----
        ldy #$00
        sty d_ptr
        lda d_winlo
        sta d_ptr+1
d_verify:
        lda d_ptr
        eor d_ptr+1
        cmp (d_ptr),y
        bne d_fail
        inc d_ptr
        bne d_verify
        inc d_ptr+1
        lda d_ptr+1
        cmp d_winhi
        bne d_verify

        dex
        bne d_pass

        // ---- PASS ----
        lda #$00
        sta d_result
        rts
d_fail:
        lda d_ptr
        sta d_failo
        lda d_ptr+1
        sta d_failhi
        lda #$02
        sta d_result
        rts

        // Parameter + result cells. Host pokes d_passes/d_winlo/d_winhi before
        // upload; host reads d_result/d_failo/d_failhi back via M-R afterward.
        // Keep d_result first so result_offset stays the M-R address.
d_result:   .byte $00
d_failo:    .byte $00
d_failhi:   .byte $00
d_passes:   .byte DEFAULT_PASS
d_winlo:    .byte WIN_LO_PAGE   // start page (e.g. $80 = $8000)
d_winhi:    .byte WIN_HI_PAGE   // end page exclusive (start + $20 = 8 KB)
}
drive_blob_end:

// Host pokes these parameter cells in the local blob copy before upload.
.label drive_passes_cell = drive_blob + (d_passes - drive_test)
.label drive_winlo_cell  = drive_blob + (d_winlo - drive_test)
.label drive_winhi_cell  = drive_blob + (d_winhi - drive_test)
