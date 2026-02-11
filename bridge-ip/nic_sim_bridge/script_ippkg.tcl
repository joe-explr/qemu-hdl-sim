
##########################################################################
# User Setting
##########################################################################

set proj_dir                ./ip_proj

set ip_design               NICSimBridge
set ip_top                  qemu_nic_bridge 
set ip_vender               COMPAS
set ip_url                  {http://www.compas.cs.stonybrook.edu}
set ip_description          {FPGA NIC Simulation Bridge}
set ip_version              1.0.0
set ip_lib                  COMPAS
set ip_families             {{Production}}
set ip_taxonomy             {{/COMPAS/IP}}

set datw                    64
set kepw                     8

##########################################################################
# Create IP
##########################################################################

create_project -name ${ip_design} -force -dir "./${proj_dir}"
set_property source_mgmt_mode All [current_project]  
set_property top ${ip_top} [current_fileset]
set_property ip_repo_paths ./ip  [current_fileset]
puts "Creating IP"

##########################################################################
# Add Files
##########################################################################

#foreach vfile [glob ./hdl/*.v] {
#    read_verilog $vfile
#}

read_verilog ./hdl/qemu_nic_bridge.sv
read_verilog ./hdl/axis_m.sv
read_verilog ./hdl/axis_s.sv

##########################################################################
# Create IP
##########################################################################

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project -generated_files

set_property name                   ${ip_design}                            [ipx::current_core]
set_property display_name           ${ip_design}                            [ipx::current_core]
set_property vendor                 ${ip_vender}                            [ipx::current_core]
set_property vendor_display_name    ${ip_vender}                            [ipx::current_core]
set_property version                ${ip_version}                           [ipx::current_core]
set_property library                ${ip_lib}                               [ipx::current_core]
set_property company_url            ${ip_url}                               [ipx::current_core]
set_property description            ${ip_description}                       [ipx::current_core]
set_property supported_families     ${ip_families}                          [ipx::current_core]
set_property taxonomy               ${ip_taxonomy}                          [ipx::current_core]

update_ip_catalog -rebuild 

##########################################################################
# Create Interfaces
##########################################################################

# remove all inferred interfaces/address spaces
ipx::remove_all_address_space [ipx::current_core]
ipx::remove_all_bus_interface [ipx::current_core]

#==========================================================
# Create Interfaces: CLK/RST
#==========================================================

#-------------------------------------------
# Create Interfaces: CLK/RST: refclk_p
#-------------------------------------------

ipx::add_bus_interface refclk_p [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces refclk_p -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces refclk_p -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces refclk_p -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces refclk_p -of_objects [ipx::current_core]]
set_property physical_name refclk_p [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces refclk_p -of_objects [ipx::current_core]]]


#-------------------------------------------
# Create Interfaces: CLK/RST: tx_axis_aresetn
#-------------------------------------------

ipx::add_bus_interface tx_axis_aresetn [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 [ipx::get_bus_interfaces tx_axis_aresetn -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:reset:1.0 [ipx::get_bus_interfaces tx_axis_aresetn -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces tx_axis_aresetn -of_objects [ipx::current_core]]
ipx::add_port_map RST [ipx::get_bus_interfaces tx_axis_aresetn -of_objects [ipx::current_core]]
set_property physical_name tx_axis_aresetn [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces tx_axis_aresetn -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -clock refclk_p -reset tx_axis_aresetn [ipx::current_core]


#==========================================================
# Create Interfaces: AXI
#==========================================================

#-------------------------------------------
# Create Interfaces: AXI Stream: m_axis_rx
#-------------------------------------------

ipx::add_bus_interface                  m_axis_rx                           [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0        [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0                    [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
set_property interface_mode master                                          [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
set_property display_name               m_axis_rx                           [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif    m_axis_rx           -clock refclk_p [ipx::current_core]

ipx::add_port_map TDATA                                                     [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
ipx::add_port_map TKEEP                                                     [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
ipx::add_port_map TUSER                                                     [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
ipx::add_port_map TLAST                                                     [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
ipx::add_port_map TVALID                                                    [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]
ipx::add_port_map TREADY                                                    [ipx::get_bus_interfaces m_axis_rx  -of_objects [ipx::current_core]]

set_property physical_name m_axis_rx_tdata      [ipx::get_port_maps TDATA       -of_objects [ipx::get_bus_interfaces m_axis_rx      -of_objects [ipx::current_core]]]
set_property physical_name m_axis_rx_tkeep      [ipx::get_port_maps TKEEP       -of_objects [ipx::get_bus_interfaces m_axis_rx      -of_objects [ipx::current_core]]]
set_property physical_name m_axis_rx_tuser      [ipx::get_port_maps TUSER       -of_objects [ipx::get_bus_interfaces m_axis_rx      -of_objects [ipx::current_core]]]
set_property physical_name m_axis_rx_tlast      [ipx::get_port_maps TLAST       -of_objects [ipx::get_bus_interfaces m_axis_rx      -of_objects [ipx::current_core]]]
set_property physical_name m_axis_rx_tvalid     [ipx::get_port_maps TVALID      -of_objects [ipx::get_bus_interfaces m_axis_rx      -of_objects [ipx::current_core]]]
set_property physical_name m_axis_rx_tready     [ipx::get_port_maps TREADY      -of_objects [ipx::get_bus_interfaces m_axis_rx      -of_objects [ipx::current_core]]]


#-------------------------------------------
# Create Interfaces: AXI Stream: s_axis_tx 
#-------------------------------------------
#
ipx::add_bus_interface                  s_axis_tx                           [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0        [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0                    [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
set_property interface_mode slave                                           [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
set_property display_name               s_axis_tx                           [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif    s_axis_tx           -clock refclk_p [ipx::current_core]

ipx::add_port_map TDATA                                                     [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
ipx::add_port_map TKEEP                                                     [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
ipx::add_port_map TUSER                                                     [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
ipx::add_port_map TLAST                                                     [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
ipx::add_port_map TVALID                                                    [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]
ipx::add_port_map TREADY                                                    [ipx::get_bus_interfaces s_axis_tx  -of_objects [ipx::current_core]]

set_property physical_name s_axis_tx_tdata      [ipx::get_port_maps TDATA       -of_objects [ipx::get_bus_interfaces s_axis_tx      -of_objects [ipx::current_core]]]
set_property physical_name s_axis_tx_tkeep      [ipx::get_port_maps TKEEP       -of_objects [ipx::get_bus_interfaces s_axis_tx      -of_objects [ipx::current_core]]]
set_property physical_name s_axis_tx_tuser      [ipx::get_port_maps TUSER       -of_objects [ipx::get_bus_interfaces s_axis_tx      -of_objects [ipx::current_core]]]
set_property physical_name s_axis_tx_tlast      [ipx::get_port_maps TLAST       -of_objects [ipx::get_bus_interfaces s_axis_tx      -of_objects [ipx::current_core]]]
set_property physical_name s_axis_tx_tvalid     [ipx::get_port_maps TVALID      -of_objects [ipx::get_bus_interfaces s_axis_tx      -of_objects [ipx::current_core]]]
set_property physical_name s_axis_tx_tready     [ipx::get_port_maps TREADY      -of_objects [ipx::get_bus_interfaces s_axis_tx      -of_objects [ipx::current_core]]]


#-------------------------------------------
# Create Interfaces: AXI Stream: s_axis_pause
#-------------------------------------------
#
ipx::add_bus_interface                  s_axis_pause                        [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:axis_rtl:1.0        [ipx::get_bus_interfaces s_axis_pause  -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:axis:1.0                    [ipx::get_bus_interfaces s_axis_pause  -of_objects [ipx::current_core]]
set_property interface_mode slave                                           [ipx::get_bus_interfaces s_axis_pause  -of_objects [ipx::current_core]]
set_property display_name               s_axis_pause                        [ipx::get_bus_interfaces s_axis_pause  -of_objects [ipx::current_core]]
ipx::associate_bus_interfaces -busif    s_axis_pause      -clock refclk_p [ipx::current_core]

ipx::add_port_map TDATA                                                     [ipx::get_bus_interfaces s_axis_pause  -of_objects [ipx::current_core]]
ipx::add_port_map TVALID                                                    [ipx::get_bus_interfaces s_axis_pause  -of_objects [ipx::current_core]]

set_property physical_name s_axis_pause_tdata      [ipx::get_port_maps TDATA       -of_objects [ipx::get_bus_interfaces s_axis_pause      -of_objects [ipx::current_core]]]
set_property physical_name s_axis_pause_tvalid     [ipx::get_port_maps TVALID      -of_objects [ipx::get_bus_interfaces s_axis_pause      -of_objects [ipx::current_core]]]


set_property enablement_value false [ipx::get_user_parameters KEEPW -of_objects [ipx::current_core]]
set_property value_tcl_expr {expr $DATAW/8} [ipx::get_user_parameters KEEPW -of_objects [ipx::current_core]]


##########################################################################
# Save IP
##########################################################################

ipx::check_integrity [ipx::current_core]
ipx::update_source_project_archive -component [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksum [ipx::current_core]
ipx::save_core [ipx::current_core]
update_ip_catalog
close_project


