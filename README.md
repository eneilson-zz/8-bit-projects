# 8-Bit Projects

This repo is a collection of software projects written for 1980s-era 8-bit computers, including CP/M systems, Apple II, Commodore 64, and other vintage platforms. These are original programs and enhanced versions of classic utilities, written in assembly language and designed to run on real hardware or period-accurate emulators.

## Projects

### CP/M

#### [KMOVCPM](cpm/kmovcpm/)

A Kaypro-specific CP/M memory relocator based on Digital Research's MOVCPM. This version fixes the notorious Kaypro bug where some versions of MOVCPM hard-coded the TPA size to 63K, preventing relocation to other memory sizes. KMOVCPM correctly relocates CP/M 2.2 to any specified TPA size (16K–64K), patches the BIOS sign-on message to display the actual memory size, and generates the appropriate SAVE command. Written in Z80 assembly and assembled with zmac.  It should run on any Kaypro OS.

#### [RAMMAPX](cpm/rammapx/)

A CP/M 2.2 memory map utility that displays key system addresses — warm boot vector, BDOS entry, CCP base, CBIOS base, and more — along with the calculated TPA size in XX.Xk format. Extended from David L. Ransen's original RAMMAP.ASM (1983) with TPA size display added by Eric C. Neilson. Written in Intel 8080 assembly and assembled with zmac.

### Commodore 64

#### [Joystick Tester](c64/joystick_test/)

A real-time joystick input diagnostic utility for the Commodore 64. Displays live input state for both joystick ports simultaneously, showing all 8 directions (cardinal and diagonal) and the fire button for each port. Direction labels highlight green when active; the fire button highlights red. Raw CIA register bits are displayed for each port. Press RUN/STOP to exit and cold-reset the machine. Written in 6502 assembly and assembled with KickAssembler.

### Apple II

#### [Apple //e Krackist ROM Patch](appleii/appleii_rom_krk_merlin32)

This project builds modified Apple //e Enhanced CD and EF ROM images (aka the "Krackist's ROM") that allow the user to do the following whenever the RESET button is pressed on the Apple //e:

    ESC -> enter Monitor immediately
    Space -> copy $0000-$08FF to $2000-$28FF, then enter Monitor
    Any other key -> continue normal boot

