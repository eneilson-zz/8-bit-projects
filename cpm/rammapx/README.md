# RAMMAPX

A CP/M 2.2 memory map utility that displays key system addresses and TPA size.

Written in Intel 8080 assembly. Extended from David L. Ransen's original
RAMMAP.ASM (1983), itself adapted from Jack Dennon's work in
*CP/M Revealed* (Hayden, 1982). TPA size display added by Eric C. Neilson (2026).

## Sample Output

```
     CP/M 2.2 Key Memory Locations

----------------------------------------

0000  warm boot vector
0005  BDOS vector
005C  default FCB
0080  CP/M record buffer
0100  base (FWA) of TPA
E3FF  Last  Word Address of TPA
E400  CCP   base (FWA)
EC00  BDOS  base (FWA)
EC06  BDOS  entry point
FA00  CBIOS base (FWA)
FA03  CBIOS warm boot entry point
----------------------------------------
TPA size is 56.0k
----------------------------------------
```

*Addresses and TPA size will vary depending on your system configuration.*

## Building

Requires [zmac](http://48k.ca/zmac.html), a Z80/8080 cross-assembler.

```
brew install zmac                        # macOS (Homebrew)
```

On Linux, build zmac from [source](https://github.com/sehugg/zmac):

```
git clone https://github.com/sehugg/zmac.git
cd zmac && make && sudo cp zmac /usr/local/bin/
```

Then:

```
make                   # Produces RAMMAPX.COM
make clean             # Remove build artifacts
```

## Usage

Copy `RAMMAPX.COM` to a CP/M disk image and run:

```
A>RAMMAPX
```

## Files

| File | Description |
|------|-------------|
| `RAMMAPX.ASM` | Main source (Intel 8080 mnemonics) |
| `Makefile` | Build automation using zmac |
| `README.md` | This file |

## Technical Notes

- TPA size is calculated as the BDOS entry address (from location 0006h) minus
  0100h, displayed in XX.Xk format with K=1024 bytes with rounding.
- The screen-clear escape sequence is ESC+E.
  Remove or change it for other terminals.
- Division on the 8080 is implemented via repeated subtraction (no hardware
  divide instruction).

## License

Public domain. The original RAMMAP.ASM was published in 1983 with no
license restrictions.
