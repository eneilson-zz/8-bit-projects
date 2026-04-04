KICKASS_JAR ?= /Applications/KickAssembler/KickAss.jar
JAVA        ?= java

SRC  = joystick_test.asm
OUT  = bin
PRG  = $(OUT)/joystick_test.prg

.PHONY: all clean

all: $(PRG)

$(PRG): $(SRC)
	mkdir -p $(OUT)
	$(JAVA) -jar $(KICKASS_JAR) $(SRC) -odir $(OUT) -showmem -symbolfile -vicesymbols | tee $(OUT)/buildlog.txt

clean:
	rm -f $(OUT)/*.prg $(OUT)/*.dbg $(OUT)/*.vs $(OUT)/*.sym $(OUT)/buildlog.txt
