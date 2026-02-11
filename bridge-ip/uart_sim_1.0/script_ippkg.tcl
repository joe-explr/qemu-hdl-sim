
##########################################################################
# User Setting
##########################################################################

set proj_dir                ./ip_proj

set ip_design               uart_sim
set ip_top                  axilite_uart
set ip_vender               COMPAS
set ip_url                  {http://www.compas.cs.stonybrook.edu}
set ip_description          {UART Simulation}
set ip_version              1.0
set ip_lib                  COMPAS
set ip_families             {{Production}}
set ip_taxonomy             {{/COMPAS/IP}}

set adrw 32
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


read_verilog ./hdl/axilite_s_r.sv
read_verilog ./hdl/axilite_s_w.sv
read_verilog ./hdl/axilite_uart.sv
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
# Create Interfaces: CLK/RST: i_clk
#-------------------------------------------

ipx::add_bus_interface i_clk [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:clock_rtl:1.0 [ipx::get_bus_interfaces i_clk -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:clock:1.0 [ipx::get_bus_interfaces i_clk -of_objects [ipx::current_core]]
#set_property interface_mode slave [ipx::get_bus_interfaces i_clk -of_objects [ipx::current_core]]
ipx::add_port_map CLK [ipx::get_bus_interfaces i_clk -of_objects [ipx::current_core]]
set_property physical_name i_clk [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces i_clk -of_objects [ipx::current_core]]]

#-------------------------------------------
# Create Interfaces: CLK/RST: i_rst_n
#-------------------------------------------

ipx::add_bus_interface i_rst_n [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:signal:reset_rtl:1.0 [ipx::get_bus_interfaces i_rst_n -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:signal:reset:1.0 [ipx::get_bus_interfaces i_rst_n -of_objects [ipx::current_core]]
#set_property interface_mode slave [ipx::get_bus_interfaces i_rst_n -of_objects [ipx::current_core]]
ipx::add_port_map RST [ipx::get_bus_interfaces i_rst_n -of_objects [ipx::current_core]]
set_property physical_name i_rst_n [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces i_rst_n -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -clock i_clk -reset i_rst_n [ipx::current_core]


#==========================================================
# Create Interfaces: AXI
#==========================================================

#-------------------------------------------
# Create Interfaces: AXI: S_AXI
#-------------------------------------------

#-------------------------------------------
# Create Interfaces: AXI: S_AXI
#-------------------------------------------

ipx::add_bus_interface S_AXI [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:aximm_rtl:1.0 [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:aximm:1.0 [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]

ipx::add_port_map ARADDR    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map ARVALID   [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map ARREADY   [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]

ipx::add_port_map RDATA     [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map RRESP     [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map RVALID    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map RREADY    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]

ipx::add_port_map AWADDR    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map AWVALID   [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map AWREADY   [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]

ipx::add_port_map WDATA     [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map WSTRB     [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map WVALID    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map WREADY    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]

ipx::add_port_map BRESP     [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map BVALID    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
ipx::add_port_map BREADY    [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]


set_property physical_name i_s_araddr   [ipx::get_port_maps ARADDR  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name i_s_arvalid  [ipx::get_port_maps ARVALID -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name o_s_arready  [ipx::get_port_maps ARREADY -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]

set_property physical_name o_s_rdata    [ipx::get_port_maps RDATA   -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name o_s_rresp    [ipx::get_port_maps RRESP   -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name o_s_rvalid   [ipx::get_port_maps RVALID  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name i_s_rready   [ipx::get_port_maps RREADY  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]

set_property physical_name i_s_awaddr   [ipx::get_port_maps AWADDR  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name i_s_awvalid  [ipx::get_port_maps AWVALID -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name o_s_awready  [ipx::get_port_maps AWREADY -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]

set_property physical_name i_s_wdata    [ipx::get_port_maps WDATA   -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name i_s_wstrb    [ipx::get_port_maps WSTRB   -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name i_s_wvalid   [ipx::get_port_maps WVALID  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name o_s_wready   [ipx::get_port_maps WREADY  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]

set_property physical_name o_s_bresp    [ipx::get_port_maps BRESP   -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name o_s_bvalid   [ipx::get_port_maps BVALID  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]
set_property physical_name i_s_bready   [ipx::get_port_maps BREADY  -of_objects [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]]

ipx::associate_bus_interfaces -busif S_AXI -clock i_clk [ipx::current_core]

ipx::add_memory_map                     S_AXI                                                                [ipx::current_core]
set_property slave_memory_map_ref       S_AXI                     [ipx::get_bus_interfaces S_AXI -of_objects [ipx::current_core]]
set_property display_name               S_AXI                     [ipx::get_memory_maps    S_AXI -of_objects [ipx::current_core]]
ipx::add_address_block                  regs                      [ipx::get_memory_maps    S_AXI -of_objects [ipx::current_core]]
set_property range 4096 [ipx::get_address_blocks regs -of_objects [ipx::get_memory_maps    S_AXI -of_objects [ipx::current_core]]]


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


