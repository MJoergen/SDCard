SRC += ../src/SDCard/sdcard_globals.vhd
SRC += ../src/SDCard/sdcard_cmd.vhd
SRC += ../src/SDCard/sdcard_dat.vhd
SRC += ../src/SDCard/sdcard_ctrl.vhd
SRC += ../src/SDCard/sdcard_wrapper.vhd
SRC += sdcard_sim.vhd
SRC += ../src/Example_Design/lfsr.vhd
SRC += ../src/Example_Design/random.vhd
SRC += ../src/Example_Design/host.vhd

DUT ?= sdcard

TB = tb_$(DUT)
SRC += $(TB).vhd
WAVE = $(TB).ghw
SAVE = $(TB).gtkw

sim: $(SRC)
	ghdl -c --std=08 $(SRC) -e $(TB)
	ghdl -r --std=08 $(TB) $(GENERIC) --assert-level=error --wave=$(WAVE) --stop-time=6ms

show: $(WAVE)
	gtkwave $(WAVE) $(SAVE)

clean:
	rm -rf *.o
	rm -rf work-obj08.cf
	rm -rf $(TB)
	rm -rf $(WAVE)
	rm -rf $(DUT)_bmc
	rm -rf $(DUT)_cover

