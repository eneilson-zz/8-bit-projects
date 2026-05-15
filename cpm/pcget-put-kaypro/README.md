# PCGET / PCPUT — Kaypro II & Kaypro 10

This is an XMODEM file transfer utility for CP/M on the Kaypro, between the Kaypro and a modern PC over a serial port.

Original code by Mike Douglas for the Kaypro 10 (a gutted version of the Ward Christensen MODEM program). This repo ports the code to the **Kaypro II** while keeping the original Kaypro 10 build available behind a manually toggled comment block.

- **PCGET.COM** — receive a file from a PC and write it to the Kaypro disk
- **PCPUT.COM** — send a file from the Kaypro to the PC (checksum or CRC-16 XMODEM)

## Quick start

## Pre-compiled binaries
If you don't want to compile or cross-compile the apps, the pre-compiled binaries are in `cpm_binaries/`.

## Build requirements

Requires [`zmac`](https://48k.ca/zmac.html) on `PATH` (or pass `make ZMAC=/path/to/zmac`). 

## How to build

## Choose a Kaypro II or Kaypro 10 build target

In `src/PCGET.ASM` and `src/PCPUT.ASM` enable the appropriate comment block:

```asm
;----------------------------------------------------------
;  TARGET: KAYPRO II  (2.5 MHz, one serial port)
;----------------------------------------------------------
SIOCR	EQU	06h
SIODR	EQU	04h
KIOCR	EQU	07h
KIODR	EQU	05h
PIOCR	EQU	SIOCR        ; K2 has no 2nd serial port; alias to modem
PIODR	EQU	SIODR
TMOCNST	EQU	129          ; 1-sec timeout @ 2.5 MHz
TGTNAME	EQU	0            ; 0 = Kaypro II banner

;----------------------------------------------------------
;  TARGET: KAYPRO 10  (4 MHz, modem + printer serial ports)
;  Uncomment this block AND comment out the Kaypro II block above.
;----------------------------------------------------------
;SIOCR	EQU	06h
;SIODR	EQU	04h
;PIOCR	EQU	0Eh
;PIODR	EQU	0Ch
;KIOCR	EQU	07h
;KIODR	EQU	05h
;TMOCNST	EQU	206          ; 1-sec timeout @ 4 MHz
;TGTNAME	EQU	1            ; 1 = Kaypro 10 banner
```

Then do
```
make                 # builds both PCGET.COM and PCPUT.COM in build/
make clean
```

Copy `build/PCGET.COM` and `build/PCPUT.COM` to your Kaypro disk image (e.g. with [`cpmtools`](https://www.moria.de/~michael/cpmtools/)) and run them under CP/M.

## Usage on the Kaypro

```
A>PCGET filename.ext        receive from PC, write to Kaypro disk
A>PCPUT filename.ext        send from Kaypro disk to PC

A>PCGET filename.ext M      (Kaypro 10 only) use the modem port
                            instead of the printer port
```

**Set the baud rate first.** 
Most Kaypros have a program called BAUD.COM that let's you set the baud rate directly.

Set the same rate on the PC terminal (8N1, no flow control). 9600 baud is a reliable starting point.

## Bootstrapping — getting PCGET onto the Kaypro the first time

Once PCGET is on the Kaypro, transferring everything else (including PCPUT) is easy through XMODEM. But the first transfer is the classic chicken-and-egg problem: you need a file-transfer utility to get a file-transfer utility onto the machine. The solution is the original Mike Douglas method: ship the Intel HEX form of PCGET to CP/M's paper-tape reader device using `PIP`, then use `LOAD` to turn it into a `.COM`.

### Cabling and baud rate

- **Kaypro II**: Use a DB25 male to DB9 female RS-232 null modem serial cable - Make sure you purchase the NULL modem (cross-over) cable and not the straight-through.  This cable will attach to your J4 serial I/O port.  You also need a USB-Serial adapter (these usually come with a male DB9 connector).

- **Kaypro 10**: the *printer* serial port is wired as **DCE** and the *modem* serial port is wired as **DTE**. When connecting to a PC, the modem serial port will require a null-modem (cross-over) cable.
- Set the baud rate to the same value on both ends. 9600 is a reliable starting point. 8 data bits, no parity, 1 stop bit, no hardware flow control. On the Kaypro, `BAUDP` / `BAUDM` (or `BAUD` on the K2) sets the baud rate for the current session; `CONFIG` makes it permanent.

### Step 1 — `PCGET.HEX` on the PC

Use the precompiled file in [cpm_binaries/PCGET.HEX](cpm_binaries/PCGET.HEX), or build it yourself with `make` (the Makefile creates both `.COM` and `.HEX` and puts them in `build/`). 

You need a PC terminal program like Tera Term or Minicom (Minicom is for Linux/Mac).

### Step 2 — Transfer the HEX file to the Kaypro using `PIP`

On the Kaypro, tell PIP to copy from the paper-tape reader (`RDR:`) or the TTY device (`TTY:`) into a disk file:

```
A>PIP PCGET.HEX=RDR:
or A>PIP PCGET.HEX=TTY:

On my emulated Kaypro II, RDR: did not work for me and I had to use TTY:
```

Press RETURN and wait for CP/M to load PIP — you'll see a line-feed when it's ready.

Then on the PC side, send `PCGET.HEX` as a plain **ASCII** transfer over the serial port (most terminal programs call this "send text file" or "ASCII upload" — not XMODEM). When the transfer is complete, type **Ctrl-Z** on the PC to signal end-of-file. PIP returns to the `A>` prompt after a short delay.

**About `RDR:`** — under CP/M on the Kaypro 10, `RDR:` (and `TTY:`) maps to the *printer* serial port, not the modem serial port. On the Kaypro II there's only one serial port, so `RDR:` maps to that single port.  Just be aware that you might need to use the correct serial device for PIP.  You can change serial device mapping through CONFIG.COM.

**Flow control matters.** PIP doesn't apply flow control on `RDR:` — it just reads bytes as fast as they arrive. At 9600 baud on a Kaypro II (2.5 MHz) PIP can occasionally drop characters. If you see garbled output or `LOAD` fails in step 3, slow the baud rate down to 1200 or 2400, or have the PC terminal program insert a short inter-character delay (1–5 ms is plenty).

### Step 3 — convert the HEX file to a `.COM` with `LOAD`

```
A>LOAD PCGET
FIRST ADDRESS 0100
LAST  ADDRESS 048F
BYTES READ    0390
RECORDS WRITTEN 08
```

That produces `PCGET.COM` on the Kaypro disk. (The byte counts above are for the Kaypro 10 build; the Kaypro II build is slightly smaller.)

### Step 4 — use PCGET to receive PCPUT (and everything else) over XMODEM

From here on the bootstrap is over; XMODEM handles binary transfers normally:

```
A>PCGET PCPUT.COM
Send PCPUT.COM now using XMODEM over the serial port...
```

Send `PCPUT.COM` (from [cpm_binaries/](cpm_binaries/) or `build/`) using XMODEM from the PC. After that the Kaypro has the full toolkit and any subsequent file transfer is a one-liner.

## Project layout

```
.
├── Makefile             # build with zmac -8
├── README.md            # this file
├── src/
│   ├── PCGET.ASM
│   └── PCPUT.ASM
├── cpm_binaries/        # precompiled Kaypro II PCGET/PCPUT .COM + .HEX
└── build/               # created by make; .COM, .HEX, .cim, .lst
```

## Credits

- Original code: Mike Douglas (`https://deramp.com/`)
- Original protocol: Ward Christensen, MODEM/XMODEM
- Kaypro II port and cross-compiler support: Eric Neilson (`https://github.com/eneilson-zz/8-bit-projects/tree/main/cpm/pcget-put-kaypro`)
