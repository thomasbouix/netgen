# GHDL-GCC + VIVADO MAKEFILE

IP_NAME=generic_layer
STOP_TIME=150ns

# Elaboration of the simulation executable
ghdl : 
	ghdl -a --work=$(IP_NAME)_work ../parameters/parameters.vhd
	ghdl -a --work=$(IP_NAME)_work src/$(IP_NAME).vhd
	ghdl -a --work=$(IP_NAME)_work tb/$(IP_NAME)_tb.vhd
	ghdl -e --work=$(IP_NAME)_work $(IP_NAME)_tb

# Run and display of the simulation
sim : ghdl
	./$(IP_NAME)_tb --stop-time=$(STOP_TIME) --vcd=$(IP_NAME).vcd
	gtkwave $(IP_NAME).vcd

clean_ghdl :
	rm -f $(IP_NAME)_tb *.cf *.o *.vcd

# Package the IP
vivado :
	vivado -mode batch -source script/ip_packager.tcl

clean_vivado :
	rm -f *.log *.jou *.str 
	rm -rf $(IP_NAME).* xgui component.xml
	
clean_src :
	cd src && $(MAKE) clean

clean : clean_ghdl clean_vivado clean_src

all : ghdl vivado

# PHONY targets precise they are not files, but recipes
.PHONY: clean sim ghdl vivado
