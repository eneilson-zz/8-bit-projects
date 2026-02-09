=====================================================================

# **KMOVCPM - Kaypro CP/M Memory Relocator**

=====================================================================

 Based on Digital Research MOVCPM, customized for Kaypro systems.
 Modified to fix the notorious Kaypro issue that hard-coded the 
 TPA size to 63k in some versions of MOVCPM. This version will
 relocate CP/M to any TPA size and update the boot sign-on 
 message to show the correct memory size.

 Original: COPYRIGHT (C) DIGITAL RESEARCH, 1980
 Enhancement by eneilson-zz, 2026

 Usage:
   KMOVCPM 62        - Build CP/M for 62K TPA
   KMOVCPM 62 *      - Build and install in-place for warm boot

   Run SYSGEN to write the relocated CP/M BIOS to a disk track

 Assemble with zmac:
 
    zmac --zmac -z kmovcpm.z
    cp zout/kmovcpm.cim kmovcpm.com

=====================================================================
