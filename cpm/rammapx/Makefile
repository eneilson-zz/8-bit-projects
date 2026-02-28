TARGET = RAMMAPX
ZMAC = zmac
ZMACFLAGS = -8 --oo cim

all: $(TARGET).COM

$(TARGET).COM: $(TARGET).ASM
	$(ZMAC) $(ZMACFLAGS) $(TARGET).ASM
	cp zout/$(TARGET).cim $(TARGET).COM

clean:
	rm -rf zout $(TARGET).COM
