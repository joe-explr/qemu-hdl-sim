
set proj_name       riscv_test_sume 
set device          xc7vx690tffg1761-3
set vcs_sim_lib     /compas/opt/Xilinx/Vivado/simlib/simlib_vvd191_vcs2017_gcc540 

set PWD [pwd]

create_project ${proj_name} . -part ${device}

set_property target_simulator VCS [current_project]
set_property compxlib.vcs_compiled_library_dir ${vcs_sim_lib} [current_project]
set_property -name {vcs.compile.vlogan.more_options} -value {-sverilog -sv -v2005 -assert svaext -timescale=1ns/1ps} -objects [get_filesets sim_1]
set_property -name {vcs.elaborate.vcs.more_options} -value {-cpp g++-4.8 -cc gcc-4.8 -O4 +rad +notimingcheck  -LDFLAGS -Wl,--no-as-needed   -P ${NOVAS_HOME}/share/PLI/VCS/LINUX64/verdi.tab ${NOVAS_HOME}/share/PLI/VCS/LINUX64/pli.a ${COSIM_REPO_HOME}/bridge-ip/QEMUPCIeBridge/hdl/dpi-pcie.c ${COSIM_REPO_HOME}/bridge-ip/nic_sim_bridge/hdl/dpi-nic.c ${COSIM_REPO_HOME}/bridge-ip/uart_sim_1.0/hdl/dpi-uart.c -lczmq} -objects [get_filesets sim_1]
set_property -name {vcs.simulate.runtime} -value {0ns} -objects [get_filesets sim_1]
set_property SOURCE_SET sources_1 [get_filesets sim_1]

set_property  ip_repo_paths {\
./ip_repo \
/compas/projects/qemu-hdl-cosim/bridge-ip \
/compas/projects/NPU/ip \
/compas/projects/ip_misc\
} [current_project]

update_ip_catalog

add_files -norecurse ./top_syn.sv
set_property used_in_simulation false [get_files  ./top_syn.sv]


update_compile_order -fileset sources_1
add_files -fileset sim_1 -norecurse ./top_sim.sv
set_property used_in_implementation false [get_files ./top_sim.sv]
set_property used_in_synthesis false [get_files ./top_sim.sv]

add_files -fileset constrs_1 -norecurse ./debug.xdc
add_files -fileset constrs_1 -norecurse ./SUME_Master.xdc
add_files -fileset constrs_1 -norecurse ./user.xdc
set_property target_constrs_file ./debug.xdc [current_fileset -constrset]

source ariane_read_file.tcl

source top_bd.tcl
cr_bd_top {}

update_compile_order -fileset sources_1
make_wrapper -files [get_files ./${proj_name}.srcs/sources_1/bd/top/top.bd] -top
add_files -norecurse ./${proj_name}.srcs/sources_1/bd/top/hdl/top_wrapper.v
update_compile_order -fileset sources_1

create_ip -name uart_sim -vendor COMPAS -library COMPAS -module_name uart_sim_0
set_property used_in_synthesis false [get_files  ./${proj_name}.srcs/sources_1/ip/uart_sim_0/uart_sim_0.xci]
set_property used_in_implementation false [get_files  ./${proj_name}.srcs/sources_1/ip/uart_sim_0/uart_sim_0.xci]
set_property GENERATE_SYNTH_CHECKPOINT 0 [get_files  ./${proj_name}.srcs/sources_1/ip/uart_sim_0/uart_sim_0.xci]
#generate_target -quiet {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/uart_sim_0/uart_sim_0.xci]

create_ip -name axi_uartlite -vendor xilinx.com -library ip -module_name axi_uartlite_0
set_property used_in_simulation false [get_files ./${proj_name}.srcs/sources_1/ip/axi_uartlite_0/axi_uartlite_0.xci]
set_property -dict [list CONFIG.C_S_AXI_ACLK_FREQ_HZ {250000000} CONFIG.C_S_AXI_ACLK_FREQ_HZ_d {250}] [get_ips axi_uartlite_0]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/axi_uartlite_0/axi_uartlite_0.xci]


create_ip -name QEMUPCIeBridge -vendor COMPAS -library COMPAS -module_name QEMUPCIeBridge_0
set_property -dict [list CONFIG.DATW {256} CONFIG.STBW {32} CONFIG.NSTB {128}] [get_ips QEMUPCIeBridge_0]
set_property -dict [list CONFIG.MSIX_VEC_NUM {4}] [get_ips QEMUPCIeBridge_0]
set_property -dict [list \
CONFIG.PREFETCH {1} \
CONFIG.BAR0_SIZE {28} \
CONFIG.BAR0_OFFSET {0x0000010000000000} \
CONFIG.BAR2_SIZE {33} \
CONFIG.BAR2_OFFSET {0x0000020000000000} \
CONFIG.MSIX_VEC_NUM {6} \
CONFIG.MSIX_TABLE_OFFSET {0x0000000000003000} \
CONFIG.MSIX_PBA_OFFSET {0x0000000000003800}\
] [get_ips QEMUPCIeBridge_0]
set_property used_in_synthesis false [get_files  ./${proj_name}.srcs/sources_1/ip/QEMUPCIeBridge_0/QEMUPCIeBridge_0.xci]
set_property used_in_implementation false [get_files  ./${proj_name}.srcs/sources_1/ip/QEMUPCIeBridge_0/QEMUPCIeBridge_0.xci]
set_property GENERATE_SYNTH_CHECKPOINT 0 [get_files  ./${proj_name}.srcs/sources_1/ip/QEMUPCIeBridge_0/QEMUPCIeBridge_0.xci]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/QEMUPCIeBridge_0/QEMUPCIeBridge_0.xci]

create_ip -name axi_pcie3 -vendor xilinx.com -library ip -module_name axi_pcie3_0
set_property -dict [list \
CONFIG.pcie_blk_locn {X0Y1} \
CONFIG.pl_link_cap_max_link_width {X8} \
CONFIG.pl_link_cap_max_link_speed {8.0_GT/s} \
CONFIG.axi_addr_width {64} \
CONFIG.axi_data_width {256_bit} \
CONFIG.plltype {QPLL1} \
CONFIG.axisten_freq {250} \
CONFIG.dedicate_perst {false} \
CONFIG.pf0_device_id {C951} \
CONFIG.pf0_base_class_menu {Network_controller} \
CONFIG.pf0_class_code_base {02} \
CONFIG.pf0_sub_class_interface_menu {Ethernet_controller} \
CONFIG.pf0_class_code_sub {00} \
CONFIG.pf0_class_code {020000} \
CONFIG.pf0_bar0_size {256} \
CONFIG.pf0_bar0_scale {Megabytes} \
CONFIG.pf0_bar0_64bit {true} \
CONFIG.pf0_bar2_enabled {true} \
CONFIG.pf0_bar2_size {8} \
CONFIG.pf0_bar2_scale {Gigabytes} \
CONFIG.pf0_bar2_64bit {true} \
CONFIG.pf0_bar2_prefetchable {true} \
CONFIG.pciebar2axibar_0 {0x0000010000000000} \
CONFIG.pciebar2axibar_2 {0x0000020080000000} \
CONFIG.pf0_interrupt_pin {NONE} \
CONFIG.pf0_msi_enabled {false} \
CONFIG.axibar_highaddr_0 {0x000000FFFFFFFFFF} \
CONFIG.s_axi_id_width {8} \
CONFIG.pf0_msix_enabled {true} \
CONFIG.pf0_msix_cap_table_size {3ff} \
CONFIG.pf0_msix_cap_table_offset {00003000} \
CONFIG.pf0_msix_cap_table_bir {BAR_1:0} \
CONFIG.pf0_msix_cap_pba_offset {00003800} \
CONFIG.pf0_msix_cap_pba_bir {BAR_1:0} \
CONFIG.c_s_axi_supports_narrow_burst {true}\
] [get_ips axi_pcie3_0]
set_property used_in_simulation false [get_files  ./${proj_name}.srcs/sources_1/ip/axi_pcie3_0/axi_pcie3_0.xci]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/axi_pcie3_0/axi_pcie3_0.xci]

create_ip -name mig_7series -vendor xilinx.com -library ip -module_name mig_7series_0
#file copy -force ./mig_a.prj ./${proj_name}.srcs/sources_1/ip/mig_7series_0/
set_property -dict [list CONFIG.XML_INPUT_FILE {../../../../mig_a.prj} CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom}] [get_ips mig_7series_0]
set_property used_in_simulation false [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]
set_property GENERATE_SYNTH_CHECKPOINT 1 [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]

create_ip -name axi_vip -vendor xilinx.com -library ip -module_name axi_vip_0
set_property -dict [list CONFIG.INTERFACE_MODE {SLAVE} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {3} ] [get_ips axi_vip_0]
set_property -dict [list CONFIG.HAS_LOCK {0} CONFIG.HAS_CACHE {0} CONFIG.HAS_REGION {0} CONFIG.HAS_QOS {0} CONFIG.HAS_PROT {0}] [get_ips axi_vip_0]
set_property used_in_synthesis false [get_files ./${proj_name}.srcs/sources_1/ip/axi_vip_0/axi_vip_0.xci]
set_property used_in_implementation false [get_files ./${proj_name}.srcs/sources_1/ip/axi_vip_0/axi_vip_0.xci]
set_property GENERATE_SYNTH_CHECKPOINT 0 [get_files  ./${proj_name}.srcs/sources_1/ip/axi_vip_0/axi_vip_0.xci]


create_ip -name NICSimBridge -vendor COMPAS -library COMPAS -module_name NICSimBridge_0
set_property used_in_synthesis false [get_files  ./${proj_name}.srcs/sources_1/ip/NICSimBridge_0/NICSimBridge_0.xci]
set_property used_in_implementation false [get_files  ./${proj_name}.srcs/sources_1/ip/NICSimBridge_0/NICSimBridge_0.xci]
set_property GENERATE_SYNTH_CHECKPOINT 0 [get_files  ./${proj_name}.srcs/sources_1/ip/NICSimBridge_0/NICSimBridge_0.xci]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/NICSimBridge_0/NICSimBridge_0.xci]

create_ip -name axi_10g_ethernet -vendor xilinx.com -library ip -module_name axi_10g_ethernet_0
set_property -dict [list \
CONFIG.Management_Interface {false} \
CONFIG.base_kr {BASE-R} \
CONFIG.autonegotiation {0} \
CONFIG.fec {0} \
CONFIG.Statistics_Gathering {0} \
CONFIG.SupportLevel {1}\
] [get_ips axi_10g_ethernet_0]
set_property used_in_simulation false [get_files  ./${proj_name}.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xci]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xci]


create_ip -name MsixController -vendor compas.stonybrook -library user -module_name MsixController_sim
set_property -dict [list CONFIG.Component_Name {MsixController_sim} CONFIG.cosim {1}] [get_ips MsixController_sim]
set_property -dict [list CONFIG.numOfIntrs {6}] [get_ips MsixController_sim]
set_property used_in_synthesis false [get_files  ./${proj_name}.srcs/sources_1/ip/MsixController_sim/MsixController_sim.xci]
set_property used_in_implementation false [get_files  ./${proj_name}.srcs/sources_1/ip/MsixController_sim/MsixController_sim.xci]
set_property GENERATE_SYNTH_CHECKPOINT 0 [get_files  ./${proj_name}.srcs/sources_1/ip/MsixController_sim/MsixController_sim.xci]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/MsixController_sim/MsixController_sim.xci]

create_ip -name MsixController -vendor compas.stonybrook -library user -module_name MsixController_syn
set_property -dict [list CONFIG.Component_Name {MsixController_syn} CONFIG.cosim {0}] [get_ips MsixController_syn]
set_property -dict [list CONFIG.numOfIntrs {6}] [get_ips MsixController_syn]
set_property used_in_simulation false [get_files  ./${proj_name}.srcs/sources_1/ip/MsixController_syn/MsixController_syn.xci]
set_property GENERATE_SYNTH_CHECKPOINT 1 [get_files  ./${proj_name}.srcs/sources_1/ip/MsixController_syn/MsixController_syn.xci]
#generate_target {instantiation_template} [get_files ./${proj_name}.srcs/sources_1/ip/MsixController_syn/MsixController_syn.xci]

update_compile_order -fileset sources_1


generate_target all [get_files  ./${proj_name}.srcs/sources_1/bd/top/top.bd]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/bd/top/top.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/bd/top/top.bd]

generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/axi_pcie3_0/axi_pcie3_0.xci]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/ip/axi_pcie3_0/axi_pcie3_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/ip/axi_pcie3_0/axi_pcie3_0.xci]

generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xci]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/ip/axi_10g_ethernet_0/axi_10g_ethernet_0.xci]

generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/MsixController_syn/MsixController_syn.xci]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/ip/MsixController_syn/MsixController_syn.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/ip/MsixController_syn/MsixController_syn.xci]

generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/axi_uartlite_0/axi_uartlite_0.xci]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/ip/axi_uartlite_0/axi_uartlite_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/ip/axi_uartlite_0/axi_uartlite_0.xci]

if {[catch {generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]} issue]} {
    puts "There is a failure and it is ignored"
    puts "Reason for failure : $issue"
}
catch {generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]}

remove_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci
file delete -force ./${proj_name}.srcs/sources_1/ip/mig_7series_0
create_ip -name mig_7series -vendor xilinx.com -library ip -module_name mig_7series_0
set_property -dict [list CONFIG.XML_INPUT_FILE {../../../../mig_a.prj} CONFIG.RESET_BOARD_INTERFACE {Custom} CONFIG.MIG_DONT_TOUCH_PARAM {Custom} CONFIG.BOARD_MIG_PARAM {Custom}] [get_ips mig_7series_0]
set_property used_in_simulation false [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]
set_property GENERATE_SYNTH_CHECKPOINT 1 [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]

generate_target all [get_files  ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/ip/mig_7series_0/mig_7series_0.xci]

open_bd_design ./${proj_name}.srcs/sources_1/bd/top/top.bd
#startgroup
#set_property -dict [list CONFIG.M04_HAS_REGSLICE {1}] [get_bd_cells microblaze_0_axi_periph]
#endgroup
save_bd_design
validate_bd_design
save_bd_design
generate_target all [get_files  ./${proj_name}.srcs/sources_1/bd/top/top.bd]
export_ip_user_files -of_objects [get_files ./${proj_name}.srcs/sources_1/bd/top/top.bd] -no_script -sync -force -quiet
create_ip_run [get_files -of_objects [get_fileset sources_1] ./${proj_name}.srcs/sources_1/bd/top/top.bd]
set_property top top_sim [get_filesets sim_1]
