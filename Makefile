####### OUTPUTS #######

ips :
	cd hw/ips/ && $(MAKE) all

vivado :
	mkdir -p vivado
	vivado -source scripts/vivado.tcl	

vitis :
	mkdir -p vitis
	xsct scripts/vitis.tcl
	vitis

####### CLEANING #######

clean_ips : 
	cd hw/ips/ && $(MAKE) clean
	cd hw/sim/ && $(MAKE) clean

clean_vivado : clean_log
	rm -rf vivado

clean_vitis :
	rm -rf vitis

clean_log : 
	rm -f *.log *.jou *.str

clean_all : clean_ips clean_vivado clean_vitis clean_log 
	rm -rf .Xil


####### PHONY #######

.PHONY : ips vitis vivado all
