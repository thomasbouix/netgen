# *******************************************
# Vivado project generation script
# A appeler depuis le dossier framework racine
# *******************************************

set ROOT_DIR [pwd]

# PROJECT & BOARD SETTINGS
create_project vivado $ROOT_DIR/vivado -part xc7z020clg484-1
set_property board_part em.avnet.com:zed:part0:1.4 [current_project]
set_property target_language VHDL [current_project]
create_bd_design "design_1"
update_compile_order -fileset sources_1

# USER IP REPO
set_property  ip_repo_paths  $ROOT_DIR/hw/ips [current_project]
update_ip_catalog

# IMPORTING CONSTRAINTS
import_files -fileset constrs_1 $ROOT_DIR/hw/constr/io_planning.xdc
import_files -fileset constrs_1 $ROOT_DIR/hw/constr/timing.xdc

# IMPORTTING SIMULATION
# add_files -fileset sim_1 $ROOT_DIR/hw/sim/design_tb.vhd

# DESIGN

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

