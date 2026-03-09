# 8-Bit Projects

This repo is a collection of software projects written for 1980s-era 8-bit computers, including CP/M systems, Apple II, Commodore 64, and other vintage platforms. These are original programs and enhanced versions of classic utilities, written in assembly language and designed to run on real hardware or period-accurate emulators.

## Projects

### CP/M

#### [KMOVCPM](cpm/kmovcpm/)

A Kaypro-specific CP/M memory relocator based on Digital Research's MOVCPM. This version fixes the notorious Kaypro bug where some versions of MOVCPM hard-coded the TPA size to 63K, preventing relocation to other memory sizes. KMOVCPM correctly relocates CP/M 2.2 to any specified TPA size (16K–64K), patches the BIOS sign-on message to display the actual memory size, and generates the appropriate SAVE command. Written in Z80 assembly and assembled with zmac.  It should run on any Kaypro OS.

#### [RAMMAPX](cpm/rammapx/)

A CP/M 2.2 memory map utility that displays key system addresses — warm boot vector, BDOS entry, CCP base, CBIOS base, and more — along with the calculated TPA size in XX.Xk format. Extended from David L. Ransen's original RAMMAP.ASM (1983) with TPA size display added by Eric C. Neilson. Written in Intel 8080 assembly and assembled with zmac.

#### [Apple //e Krackist ROM Patch](appleii/appleii_rom_krk_merlin32)

This project builds modified Apple //e Enhanced CD and EF ROM images (aka the "Krackist's ROM") that allow the user to do the following whenever the RESET button is pressed on the Apple //e:

    ESC -> enter Monitor immediately
    Space -> copy $0000-$08FF to $2000-$28FF, then enter Monitor
    Any other key -> continue normal boot

I originally created the Krakist ROM patch in 2009 using SC-MASM, and recently migrated everything over to Merlin-8, including the ability to cross-assemble the source on a modern PC. History of the project and details on how it works are here: https://planemo.org/2012/01/13/apple-e-rom-hacking/
