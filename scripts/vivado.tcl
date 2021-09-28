# *******************************************
# Vivado project generation script
# A appeler depuis le dossier framework racine
# *******************************************

set ROOT_DIR [pwd]

source $ROOT_DIR/hw/ips/parameters/parameters.tcl

# PROJECT & BOARD SETTINGS
create_project vivado $ROOT_DIR/vivado -part $part
set_property board_part $board [current_project]
set_property target_language VHDL [current_project]
create_bd_design "design_1"
update_compile_order -fileset sources_1
open_bd_design $ROOT_DIR/vivado/vivado.srcs/sources_1/bd/design_1/design_1.bd

# USER IP REPO
set_property  ip_repo_paths  $ROOT_DIR/hw/ips [current_project]
update_ip_catalog

# IMPORTING CONSTRAINTS
import_files -fileset constrs_1 $ROOT_DIR/hw/constr/io_planning.xdc
import_files -fileset constrs_1 $ROOT_DIR/hw/constr/timing.xdc

# IMPORTTING SIMULATION
# add_files -fileset sim_1 $ROOT_DIR/hw/sim/design_tb.vhd

# DESIGN

## PS7
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable" }  [get_bd_cells processing_system7_0]
set_property -dict [list CONFIG.PCW_TTC0_PERIPHERAL_ENABLE {0} CONFIG.PCW_USB0_PERIPHERAL_ENABLE {0}] [get_bd_cells processing_system7_0]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]

## RESET
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Manual_Source {Auto}}  [get_bd_pins proc_sys_reset_0/ext_reset_in]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/processing_system7_0/FCLK_CLK0 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

## Generic Fully-Connected Neural Network 
create_bd_cell -type ip -vlnv user.org:user:generic_fc_nn:1.0 generic_fc_nn_0
apply_bd_automation -rule xilinx.com:bd_rule:axi4 -config { Clk_master {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_slave {/processing_system7_0/FCLK_CLK0 (100 MHz)} Clk_xbar {/processing_system7_0/FCLK_CLK0 (100 MHz)} Master {/processing_system7_0/M_AXI_GP0} Slave {/generic_fc_nn_0/s_axi} ddr_seg {Auto} intc_ip {New AXI Interconnect} master_apm {0}}  [get_bd_intf_pins generic_fc_nn_0/s_axi]

# BLOCK DESIGN VALIDATION
regenerate_bd_layout
save_bd_design
validate_bd_design

# GENERATING WRAPPER 
make_wrapper -files [get_files $ROOT_DIR/vivado/vivado.srcs/sources_1/bd/design_1/design_1.bd] -top
add_files -norecurse $ROOT_DIR/vivado/vivado.gen/sources_1/bd/design_1/hdl/design_1_wrapper.vhd

# CREATING BITSTREAM
# launch_runs impl_1 -to_step write_bitstream -jobs 4
# wait_on_run impl_1

# HARDWARE EXPORTATION
# write_hw_platform -fixed -include_bit -force -file $ROOT_DIR/vivado/design_1_wrapper.xsa

