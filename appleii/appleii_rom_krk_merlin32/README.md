# Apple IIe KRK ROM Hack (Merlin32)

This project builds modified Apple //e Enhanced CD and EF ROM images (aka the "Krackist's ROM") that allow the user to do the following whenever the RESET button is pressed on the Apple //e:

- `ESC` -> enter Monitor immediately
- `Space` -> copy `$0000-$08FF` to `$2000-$28FF`, then enter Monitor
- Any other key -> continue normal boot

I originally created the Krakist ROM patch in 2009 using SC-MASM, and recently migrated everything over to Merlin-8, including the ability to cross-assemble the source on a modern PC.  History of the project and details on how it works are here: https://planemo.org/2012/01/13/apple-e-rom-hacking/

The output of this project are four files in the modified_apple_roms directory:
- Patched CD Enhanced ROM
- Patched EF Enhanced ROM
- Patched IIe Platinum ROM
- Patched .ROM file for use with emulators like Virtual ][

You can use these ROM binaries in various emulators or burn actual ROMs with them.  A fun way to play with the Krackist ROM is to point your favorite emulator to the appropriate ROM file.

You can still build the patch source files natively on an Apple II using Merlin-8 for ProDOS.  When building this project, the makefile uses Cadius to create an Apple II-compatible .dsk file and transfer the source code to the .dsk image so that it can be natively compiled with Merlin-8 PRODOS for the Apple II.  The only difference beteween the cross-assembled source and the Apple II Merlin source is the "TYPE BIN" assembly command is not supported in the original Merlin-8.  The makefile tools  automatically comments this out before transferring the files to the .dsk image.

At boot, the modified ROM displays `Apple //k` at the top of the screen so you know it's active.

## Project Layout

- `ROMP1.S`, `ROMP2.S`, `ROMP3.S`: assembly source written in Merlin for the 3-part ROM patch
- `Makefile`: build automation
- `patch_roms.py`: patches original ROM binaries
- `original_apple_roms/`: required input ROM files (not generated)
- `objs/`, `debug/`, `modified_apple_roms/`, `dsk/`: generated build output

## Dependencies

Required tools in `PATH`:

1. `Merlin32` (Brutal Deluxe cross-assembler)
2. `cadius` (Brutal Deluxe ProDOS disk utility)
3. `python3` (used by `patch_roms.py`)
4. `make`

## OS Dependencies / Notes

- Current `Makefile` uses BSD `sed` syntax (`sed -i '' ...`), which is compatible with macOS.
- On Linux (GNU `sed`), adjust those lines to GNU syntax (typically `sed -i ...`) if needed.
- All project paths are relative to this project directory.

## Required Input ROMs

Place these original 8KB ROM files in `original_apple_roms/`:

- `Apple IIe CD Enhanced - 342-0304-A - 2764.bin`
- `Apple IIe EF Enhanced - 342-0303-A - 2764.bin`

`patch_roms.py` verifies expected original bytes before patching and exits on mismatch.

## How to Build

From this directory:

```bash
make
```

Clean generated output:

```bash
make clean
```

## Build Outputs

Generated ROM images in `modified_apple_roms/`:

- `Apple IIe CD Enhanced KRK - 342-0304-A - 2764.bin`
- `Apple IIe EF Enhanced KRK - 342-0303-A - 2764.bin`
- `APPLE2EKRK.ROM` (combined 16KB CD+EF image for emulators)
- `Apple IIe Platinum CF KRK ROM 27128.bin` (combined 16KB image)

Generated ProDOS disk image in `dsk/`:

- `ROMKRKS.po`

## ROM Patch Structure

- Part 1 (`ROMP1`): `$FEFD` (EF ROM offset `$1EFD`), 12 bytes
- Part 2 (`ROMP2`): `$C600` (CD ROM offset `$0600`), 81 bytes
- Part 3 (`ROMP3`): `$FECD` (EF ROM offset `$1ECD`), 6 bytes
- Vectors patch (EF): `$1FFA` (NMI/Reset -> `$FEFD`)
- Boot text patch (EF): `$1F12` (`//e` -> `//k`)

## Reference links:

- Background article: <https://planemo.org/2012/01/13/apple-e-rom-hacking/>
- Merlin32: <https://www.brutaldeluxe.fr/products/crossdevtools/merlin/>
- Cadius: <https://www.brutaldeluxe.fr/products/crossdevtools/cadius/>
