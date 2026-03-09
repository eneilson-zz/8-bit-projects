#!/usr/bin/env python3
"""
Apple IIe ROM Patcher for KRK (Krackist's ROM Kit)

Applies the three binary patches (ROMP1, ROMP2, ROMP3) to original Apple IIe
CD and EF ROM files to create modified "KRK" ROMs that allow breaking into
the Monitor at any time.

Patch locations (from ROMKRK.txt):
- Part 0: NMI and Reset vectors at EF ROM offset $1FFA (4 bytes)
- Part 1: ROMP1 at EF ROM offset $1EFD (12 bytes) - Reset vector handler
- Part 2: ROMP2 at CD ROM offset $0600 (81 bytes) - Main logic at $C600
- Part 3: ROMP3 at EF ROM offset $1ECD (6 bytes) - Monitor exit
- Apple //k: Change "e" to "k" at EF ROM offset $1F12 (1 byte)
"""

import os
import sys

# Directories
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
OBJS_DIR = os.path.join(SCRIPT_DIR, "objs")
ORIGINAL_ROMS_DIR = os.path.join(SCRIPT_DIR, "original_apple_roms")
MODIFIED_ROMS_DIR = os.path.join(SCRIPT_DIR, "modified_apple_roms")

# Original ROM filenames
CD_ROM_ORIGINAL = "Apple IIe CD Enhanced - 342-0304-A - 2764.bin"
EF_ROM_ORIGINAL = "Apple IIe EF Enhanced - 342-0303-A - 2764.bin"

# Modified ROM filenames
CD_ROM_MODIFIED = "Apple IIe CD Enhanced KRK - 342-0304-A - 2764.bin"
EF_ROM_MODIFIED = "Apple IIe EF Enhanced KRK - 342-0303-A - 2764.bin"
COMBINED_ROM = "APPLE2EKRK.ROM"
CF_ROM = "Apple IIe Platinum CF KRK ROM 27128.bin"

# Patch definitions: (file_offset, original_bytes, description)
# Original bytes from ROMKRK.txt for verification

# EF ROM patches
EF_PATCHES = {
    "vectors": {
        "offset": 0x1FFA,
        "original": bytes.fromhex("FB0362FA"),
        "description": "NMI and Reset vectors"
    },
    "part1": {
        "offset": 0x1EFD,
        "original": bytes.fromhex("8D07C020D1C58D06C0F032D0"),
        "description": "Part 1 - Reset vector handler (ROMP1)"
    },
    "part3": {
        "offset": 0x1ECD,
        "original": bytes.fromhex("A9408D07C020"),
        "description": "Part 3 - Monitor exit (ROMP3)"
    },
    "apple_k": {
        "offset": 0x1F12,
        "original": bytes.fromhex("E5"),
        "new": bytes.fromhex("EB"),
        "description": "Apple //e -> Apple //k"
    }
}

# CD ROM patches
CD_PATCHES = {
    "part2": {
        "offset": 0x0600,
        "original": bytes.fromhex(
            "8D50C0A004A2001879B4C79500E8D0F71879B4C7D500D010E8D0F56A2C19C0100249A58810E130065500184CCDC6860186028603A2048604E601A88D83C08D83C0A50129F0C9C0D00CAD8BC0AD8BC0A501"
        ),
        "description": "Part 2 - Main logic at $C600 (ROMP2)"
    }
}

# New vector bytes for EF ROM
NEW_VECTORS = bytes.fromhex("FDFEFDFE")


def read_file(filepath):
    """Read binary file and return contents."""
    with open(filepath, "rb") as f:
        return bytearray(f.read())


def write_file(filepath, data):
    """Write binary data to file."""
    with open(filepath, "wb") as f:
        f.write(data)


def verify_original_bytes(rom_data, offset, expected, description):
    """Verify that the original bytes at offset match expected."""
    actual = bytes(rom_data[offset:offset + len(expected)])
    if actual != expected:
        print(f"ERROR: {description}")
        print(f"  Offset: 0x{offset:04X}")
        print(f"  Expected: {expected.hex().upper()}")
        print(f"  Actual:   {actual.hex().upper()}")
        return False
    print(f"  Verified: {description} at 0x{offset:04X}")
    return True


def apply_patch(rom_data, offset, patch_data, description):
    """Apply patch data at the specified offset."""
    rom_data[offset:offset + len(patch_data)] = patch_data
    print(f"  Applied:  {description} ({len(patch_data)} bytes at 0x{offset:04X})")


def main():
    print("=" * 60)
    print("Apple IIe ROM Patcher for KRK")
    print("=" * 60)
    
    # Create output directory if it doesn't exist
    os.makedirs(MODIFIED_ROMS_DIR, exist_ok=True)
    
    # Load patch files
    print("\nLoading patch files...")
    try:
        romp1 = read_file(os.path.join(OBJS_DIR, "ROMP1"))
        romp2 = read_file(os.path.join(OBJS_DIR, "ROMP2"))
        romp3 = read_file(os.path.join(OBJS_DIR, "ROMP3"))
        print(f"  ROMP1: {len(romp1)} bytes")
        print(f"  ROMP2: {len(romp2)} bytes")
        print(f"  ROMP3: {len(romp3)} bytes")
    except FileNotFoundError as e:
        print(f"ERROR: Could not load patch file: {e}")
        print("Run 'make' first to build the patch binaries.")
        return 1
    
    # Load original ROMs
    print("\nLoading original ROMs...")
    try:
        ef_rom = read_file(os.path.join(ORIGINAL_ROMS_DIR, EF_ROM_ORIGINAL))
        cd_rom = read_file(os.path.join(ORIGINAL_ROMS_DIR, CD_ROM_ORIGINAL))
        print(f"  EF ROM: {len(ef_rom)} bytes")
        print(f"  CD ROM: {len(cd_rom)} bytes")
    except FileNotFoundError as e:
        print(f"ERROR: Could not load original ROM: {e}")
        return 1
    
    # Verify and patch EF ROM
    print("\nProcessing EF ROM...")
    print("Verifying original bytes...")
    
    ef_ok = True
    for name, patch_info in EF_PATCHES.items():
        if not verify_original_bytes(ef_rom, patch_info["offset"], 
                                     patch_info["original"], patch_info["description"]):
            ef_ok = False
    
    if not ef_ok:
        print("ERROR: EF ROM verification failed!")
        return 1
    
    print("Applying patches...")
    apply_patch(ef_rom, EF_PATCHES["vectors"]["offset"], NEW_VECTORS, 
                "New NMI/Reset vectors (FDFE FDFE)")
    apply_patch(ef_rom, EF_PATCHES["part1"]["offset"], romp1, 
                "ROMP1 - Reset vector handler")
    apply_patch(ef_rom, EF_PATCHES["part3"]["offset"], romp3, 
                "ROMP3 - Monitor exit")
    apply_patch(ef_rom, EF_PATCHES["apple_k"]["offset"], 
                EF_PATCHES["apple_k"]["new"],
                "Apple //e -> Apple //k")
    
    # Verify and patch CD ROM
    print("\nProcessing CD ROM...")
    print("Verifying original bytes...")
    
    cd_ok = True
    for name, patch_info in CD_PATCHES.items():
        if not verify_original_bytes(cd_rom, patch_info["offset"],
                                     patch_info["original"], patch_info["description"]):
            cd_ok = False
    
    if not cd_ok:
        print("ERROR: CD ROM verification failed!")
        return 1
    
    print("Applying patches...")
    apply_patch(cd_rom, CD_PATCHES["part2"]["offset"], romp2,
                "ROMP2 - Main logic at $C600")
    
    # Write modified ROMs
    print("\nWriting modified ROMs...")
    ef_output = os.path.join(MODIFIED_ROMS_DIR, EF_ROM_MODIFIED)
    cd_output = os.path.join(MODIFIED_ROMS_DIR, CD_ROM_MODIFIED)
    combined_output = os.path.join(MODIFIED_ROMS_DIR, COMBINED_ROM)
    
    write_file(ef_output, ef_rom)
    print(f"  Written: {EF_ROM_MODIFIED}")
    
    write_file(cd_output, cd_rom)
    print(f"  Written: {CD_ROM_MODIFIED}")
    
    # Create combined ROM for emulators (CD + EF = $C000-$FFFF)
    combined_rom = cd_rom + ef_rom
    write_file(combined_output, combined_rom)
    print(f"  Written: {COMBINED_ROM} ({len(combined_rom)} bytes)")
    
    # Create CF ROM for Apple //e Platinum (same as combined ROM)
    cf_output = os.path.join(MODIFIED_ROMS_DIR, CF_ROM)
    write_file(cf_output, combined_rom)
    print(f"  Written: {CF_ROM}")
    
    print("\n" + "=" * 60)
    print("SUCCESS: All patches applied!")
    print("=" * 60)
    
    return 0


if __name__ == "__main__":
    sys.exit(main())
