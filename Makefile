# This Makefile is used for simulation testing of the module RANDOM.
# Simulation is done using the program ghdl. It may be available
# in your OS repository, otherwise it may be downloaded from here:
# https://github.com/ghdl/ghdl

TB       = tb_random
SOURCES  = src/Example_Design/lfsr.vhd src/Example_Design/random.vhd sim/tb_clk.vhd
SOURCES += sim/$(TB).vhd
SAVE     = sim/$(TB).gtkw
WAVE     = $(TB).ghw


#####################################
# Simulation
#####################################

.PHONY: sim
sim: $(SOURCES)
	ghdl -i --std=08 --work=work $(SOURCES)
	ghdl -m --std=08 --ieee=synopsys -frelaxed-rules $(TB)
	ghdl -r --std=08 $(TB) --max-stack-alloc=16384 --assert-level=error --wave=$(WAVE) --stop-time=10us
	gtkwave $(WAVE) $(SAVE)


#####################################
# Cleanup
#####################################

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf unisim-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)
	rm -rf a.out

