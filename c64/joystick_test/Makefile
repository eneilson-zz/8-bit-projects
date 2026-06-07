KICKASS_JAR ?= /Applications/KickAssembler/KickAss.jar
JAVA        ?= java
C1541       ?= c1541

SRC  = joystick_test.asm
OUT  = bin
PRG  = $(OUT)/joystick_test.prg
D64  = $(OUT)/joystick_test.d64

.PHONY: all clean

all: $(D64)

$(PRG): $(SRC)
	mkdir -p $(OUT)
	$(JAVA) -jar $(KICKASS_JAR) $(SRC) -odir $(OUT) -showmem -symbolfile -vicesymbols | tee $(OUT)/buildlog.txt

$(D64): $(PRG)
	$(C1541) -format "joystick,jt" d64 "$(D64)" -write "$(PRG)" "joystick test" >/dev/null

clean:
	rm -f $(OUT)/*.prg $(OUT)/*.d64 $(OUT)/*.dbg $(OUT)/*.vs $(OUT)/*.sym $(OUT)/buildlog.txt
