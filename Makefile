HDL = ghdl 

SOURCES := constants.vhd mult.vhd signextend.vhd pc-bridge.vhd pc-next.vhd decoder.vhd memory-rw.vhd alu.vhd mips.vhd
		  
OBJECTS := $(patsubst %.vhd,%.o,$(SOURCES))

all : $(OBJECTS)

%.o : %.vhd
	$(HDL) -a --ieee=synopsys -fexplicit $<
	
testbench: $(OBJECTS) testbench.vhd
	$(HDL) -a --ieee=synopsys -fexplicit testbench.vhd
	$(HDL) -e --ieee=synopsys -fexplicit testbench

sim: testbench
	ghdl -r --ieee=synopsys -fexplicit testbench --vcd=mips.vcd
	gtkwave mips.vcd


clean:
	$(RM) *.o *.vcd testbench *.cf
