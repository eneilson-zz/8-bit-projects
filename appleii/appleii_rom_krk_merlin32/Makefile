# Makefile for Merlin32 assembly

MERLIN32 = Merlin32
CADIUS = cadius
MACRODIR = Library
OBJDIR = objs
DEBUGDIR = debug
DSKDIR = dsk
DSKNAME = ROMKRKS.po
VOLNAME = ROMKRKS

SOURCES = ROMP1.S ROMP2.S ROMP3.S

.PHONY: all clean check-tools init-dirs

PATCH_BINS = $(patsubst %.S,%,$(SOURCES))
OUTPUT_TXT = $(patsubst %.S,%_S01_Segment1_Output.txt,$(SOURCES))
SYMBOL_TXT = $(patsubst %.S,%_Symbols.txt,$(SOURCES))

all: clean check-tools init-dirs
	@for src in $(SOURCES); do \
		$(MERLIN32) -V $(MACRODIR) $$src || exit 1; \
	done
	@mv $(PATCH_BINS) $(OBJDIR)/
	@mv $(OUTPUT_TXT) $(SYMBOL_TXT) $(DEBUGDIR)/ 2>/dev/null || true
	@if [ -f _FileInformation.txt ]; then mv _FileInformation.txt $(DEBUGDIR)/; fi
	@python3 patch_roms.py
	@echo "Creating ProDOS disk image..."
	@mkdir -p $(DSKDIR)/staging
	@cp ROMP1.S ROMP2.S ROMP3.S $(DSKDIR)/staging/
	@sed -i '' 's/^.*TYP/\*&/' $(DSKDIR)/staging/ROMP1.S
	@sed -i '' 's/^.*TYP/\*&/' $(DSKDIR)/staging/ROMP2.S
	@sed -i '' 's/^.*TYP/\*&/' $(DSKDIR)/staging/ROMP3.S
	@$(CADIUS) SETHIGHBIT $(DSKDIR)/staging/ROMP1.S
	@$(CADIUS) SETHIGHBIT $(DSKDIR)/staging/ROMP2.S
	@$(CADIUS) SETHIGHBIT $(DSKDIR)/staging/ROMP3.S
	@cp $(OBJDIR)/ROMP1 $(OBJDIR)/ROMP2 $(OBJDIR)/ROMP3 $(DSKDIR)/staging/
	@echo "ROMP1.S=Type(04),AuxType(0000),Access(E3)" > $(DSKDIR)/staging/_FileInformation.txt
	@echo "ROMP2.S=Type(04),AuxType(0000),Access(E3)" >> $(DSKDIR)/staging/_FileInformation.txt
	@echo "ROMP3.S=Type(04),AuxType(0000),Access(E3)" >> $(DSKDIR)/staging/_FileInformation.txt
	@echo "ROMP1=Type(06),AuxType(0000),Access(E3)" >> $(DSKDIR)/staging/_FileInformation.txt
	@echo "ROMP2=Type(06),AuxType(0000),Access(E3)" >> $(DSKDIR)/staging/_FileInformation.txt
	@echo "ROMP3=Type(06),AuxType(0000),Access(E3)" >> $(DSKDIR)/staging/_FileInformation.txt
	@$(CADIUS) CREATEVOLUME $(DSKDIR)/$(DSKNAME) $(VOLNAME) 140KB
	@$(CADIUS) ADDFOLDER $(DSKDIR)/$(DSKNAME) /$(VOLNAME)/ $(DSKDIR)/staging/
	@rm -rf $(DSKDIR)/staging

check-tools:
	@command -v $(MERLIN32) >/dev/null 2>&1 || { echo "ERROR: $(MERLIN32) not found in PATH"; exit 1; }
	@command -v $(CADIUS) >/dev/null 2>&1 || { echo "ERROR: $(CADIUS) not found in PATH"; exit 1; }
	@command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found in PATH"; exit 1; }

init-dirs:
	@mkdir -p $(OBJDIR) $(DEBUGDIR) $(DSKDIR) modified_apple_roms

clean:
	@mkdir -p $(OBJDIR) $(DEBUGDIR) $(DSKDIR) modified_apple_roms
	rm -f $(OBJDIR)/* $(DEBUGDIR)/* modified_apple_roms/* $(DSKDIR)/*
