#-----------------------------------------------------------
# Vivado v2020.2 (64-bit)
# IP Packager Script
# A appeler depuis le dossier de l'ip
#-----------------------------------------------------------

source ../parameters/parameters.tcl

set ip_name "generic_layer" 

create_project $ip_name . -part $part
set_property board_part $board [current_project]

set_property target_language VHDL [current_project]
add_files -norecurse src/$ip_name.vhd
update_compile_order -fileset sources_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse tb/$ip_name\_tb.vhd
update_compile_order -fileset sim_1
ipx::package_project -root_dir . -vendor user.org -library user -taxonomy /UserIP -import_files
close_project
exit
