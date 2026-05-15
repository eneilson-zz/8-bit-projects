# Makefile for PCGET / PCPUT (Kaypro II / Kaypro 10 CP/M XMODEM utilities)
#
# Cross-assembles 8080 source to CP/M .COM binaries using zmac.
# Target selection (Kaypro II vs Kaypro 10) is done by commenting/uncommenting
# the TARGET blocks at the top of each .asm file -- not from here.
#
# Usage:
#   make           # builds both PCGET.COM and PCPUT.COM
#   make pcget     # PCGET only
#   make pcput     # PCPUT only
#   make clean     # remove build/
#
# Requires: zmac (https://48k.ca/zmac.html).  ~/bin/zmac or on PATH.

ZMAC      ?= zmac
ZMACFLAGS ?= -8 --oo cim,lst,hex

SRC_DIR   := src
BUILD_DIR := build

PROGS     := PCGET PCPUT
COMS      := $(addprefix $(BUILD_DIR)/,$(addsuffix .COM,$(PROGS)))

.PHONY: all pcget pcput clean help
.DEFAULT_GOAL := all

all: $(COMS)

pcget: $(BUILD_DIR)/PCGET.COM
pcput: $(BUILD_DIR)/PCPUT.COM

# zmac emits PCGET.cim (raw binary), PCGET.hex (Intel HEX) and PCGET.lst
# into --od dir. Copy .cim -> .COM and .hex -> .HEX for upper-case CP/M
# filenames (PIP / LOAD expect upper case). On case-insensitive filesystems
# (default macOS APFS) the .HEX copy is a no-op; on Linux it creates the
# upper-case variant.
$(BUILD_DIR)/%.COM: $(SRC_DIR)/%.ASM | $(BUILD_DIR)
	$(ZMAC) $(ZMACFLAGS) --od $(BUILD_DIR) $<
	cp $(BUILD_DIR)/$*.cim $(BUILD_DIR)/$*.COM
	@# zmac writes the .hex file with Unix LF endings. CP/M's PIP expects
	@# CRLF when receiving an ASCII text file (the bootstrap path uses
	@# "PIP PCGET.HEX=RDR:"), so convert to CRLF on the way to .HEX.
	@# On case-insensitive filesystems (default macOS APFS) .hex and .HEX
	@# resolve to the same inode, so we read .hex into memory before
	@# writing back.
	awk 'BEGIN{ORS="\r\n"} {sub(/\r$$/,""); print}' \
	    $(BUILD_DIR)/$*.hex > $(BUILD_DIR)/$*.HEX.tmp
	mv $(BUILD_DIR)/$*.HEX.tmp $(BUILD_DIR)/$*.HEX
	@echo "  -> $(BUILD_DIR)/$*.COM"
	@echo "  -> $(BUILD_DIR)/$*.HEX (CRLF)"

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)

help:
	@echo "Targets:"
	@echo "  all      build PCGET.COM/.HEX and PCPUT.COM/.HEX (default)"
	@echo "  pcget    build PCGET.COM and PCGET.HEX"
	@echo "  pcput    build PCPUT.COM and PCPUT.HEX"
	@echo "  clean    remove build/"
	@echo ""
	@echo "Override the assembler with:  make ZMAC=/path/to/zmac"
	@echo "Switch K2 <-> K10: edit the TARGET block in src/PCGET.ASM and"
	@echo "src/PCPUT.ASM, then run 'make clean && make'."
