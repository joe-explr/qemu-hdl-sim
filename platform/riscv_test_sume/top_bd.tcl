# Proc to create BD top
proc cr_bd_top { parentCell } {

  # CHANGE DESIGN NAME HERE
  set design_name top

  common::send_msg_id "BD_TCL-003" "INFO" "Currently there is no design <$design_name> in project, so creating one..."

  create_bd_design $design_name

  set bCheckIPsPassed 1
  ##################################################################
  # CHECK IPs
  ##################################################################
  set bCheckIPs 1
  if { $bCheckIPs == 1 } {
     set list_check_ips "\ 
  xilinx.com:ip:axi_timer:*\
  COMPAS:COMPAS:bsv_riscv_flute_ADFIMU:*\
  xilinx.com:ip:util_ds_buf:*\
  xilinx.com:ip:clk_wiz:*\
  xilinx.com:ip:util_vector_logic:*\
  xilinx.com:ip:mdm:*\
  xilinx.com:ip:axi_dma:*\
  xilinx.com:ip:proc_sys_reset:*\
  COMPAS:COMPAS:soft_reset_v2:*\
  xilinx.com:ip:axi_data_fifo:*\
  xilinx.com:ip:axi_protocol_converter:*\
  xilinx.com:ip:axis_data_fifo:*\
  xilinx.com:ip:axi_bram_ctrl:*\
  xilinx.com:ip:blk_mem_gen:*\
  xilinx.com:ip:util_reduced_logic:*\
  xilinx.com:ip:xlconcat:*\
  "

   set list_ips_missing ""
   common::send_msg_id "BD_TCL-006" "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_msg_id "BD_TCL-115" "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

  }

  if { $bCheckIPsPassed != 1 } {
    common::send_msg_id "BD_TCL-1003" "WARNING" "Will not continue with creation of design due to the error(s) above."
    return 3
  }

  
# Hierarchical cell: pcie
proc create_hier_cell_pcie { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_pcie() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 msix_table_bram_portb

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_msix_tablele


  # Create pins
  create_bd_pin -dir I -type clk clk_pcie
  create_bd_pin -dir O intx_msi_req
  create_bd_pin -dir I -from 0 -to 0 irq_in_00
  create_bd_pin -dir I -from 0 -to 0 irq_in_01
  create_bd_pin -dir I -from 0 -to 0 irq_in_02
  create_bd_pin -dir I -from 0 -to 0 irq_in_03
  create_bd_pin -dir I -type intr irq_in_04
  create_bd_pin -dir I -type intr irq_in_05
  create_bd_pin -dir O -from 5 -to 0 msix_irq
  create_bd_pin -dir I -from 0 -to 0 -type clk pcie_link_clk_n
  create_bd_pin -dir I -from 0 -to 0 -type clk pcie_link_clk_p
  create_bd_pin -dir O -from 0 -to 0 -type clk pcie_refclk_out
  create_bd_pin -dir O -from 0 -to 0 -type clk pcie_refclk_out_div2
  create_bd_pin -dir I -type rst pcie_rst_n
  create_bd_pin -dir O -from 0 -to 0 -type rst pcie_rst_n_out_peripheral
  create_bd_pin -dir I -type rst soft_rst_n

  # Create instance: axi_bram_ctrl_msix_table, and set properties
  set axi_bram_ctrl_msix_table [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl_msix_table ]
  set_property -dict [ list \
   CONFIG.SINGLE_PORT_BRAM {1} \
 ] $axi_bram_ctrl_msix_table

  # Create instance: blk_mem_gen_msix_table, and set properties
  set blk_mem_gen_msix_table [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen_msix_table ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen_msix_table

  # Create instance: pcie_clk_reset, and set properties
  set pcie_clk_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset pcie_clk_reset ]

  # Create instance: pcie_refclk_buf, and set properties
  set pcie_refclk_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf pcie_refclk_buf ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {IBUFDSGTE} \
 ] $pcie_refclk_buf

  # Create instance: util_reduced_logic_0, and set properties
  set util_reduced_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_reduced_logic util_reduced_logic_0 ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {or} \
   CONFIG.C_SIZE {2} \
   CONFIG.LOGO_FILE {data/sym_orgate.png} \
 ] $util_reduced_logic_0

  # Create instance: xlconcat_0, and set properties
  set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_0 ]

  # Create instance: xlconcat_intc_pcie_0, and set properties
  set xlconcat_intc_pcie_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat xlconcat_intc_pcie_0 ]
  set_property -dict [ list \
   CONFIG.NUM_PORTS {6} \
 ] $xlconcat_intc_pcie_0

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_msix_table_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_msix_table/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_msix_table/BRAM_PORTA]
  connect_bd_intf_net -intf_net blk_mem_gen_msix_table_BRAM_PORTB [get_bd_intf_pins msix_table_bram_portb] [get_bd_intf_pins blk_mem_gen_msix_table/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins s_axi_msix_tablele] [get_bd_intf_pins axi_bram_ctrl_msix_table/S_AXI]

  # Create port connections
  connect_bd_net -net AppCore_o_msi_1 [get_bd_pins irq_in_03] [get_bd_pins xlconcat_intc_pcie_0/In3]
  connect_bd_net -net In4_1 [get_bd_pins irq_in_04] [get_bd_pins xlconcat_intc_pcie_0/In4]
  connect_bd_net -net In5_1 [get_bd_pins irq_in_05] [get_bd_pins xlconcat_intc_pcie_0/In5]
  connect_bd_net -net PCIE_CLK_N_1 [get_bd_pins pcie_link_clk_n] [get_bd_pins pcie_refclk_buf/IBUF_DS_N]
  connect_bd_net -net PCIE_CLK_P_1 [get_bd_pins pcie_link_clk_p] [get_bd_pins pcie_refclk_buf/IBUF_DS_P]
  connect_bd_net -net axi_dma_0_mm2s_introut [get_bd_pins irq_in_02] [get_bd_pins xlconcat_0/In0] [get_bd_pins xlconcat_intc_pcie_0/In2]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins irq_in_01] [get_bd_pins xlconcat_0/In1] [get_bd_pins xlconcat_intc_pcie_0/In1]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_pins clk_pcie] [get_bd_pins axi_bram_ctrl_msix_table/s_axi_aclk] [get_bd_pins pcie_clk_reset/slowest_sync_clk]
  connect_bd_net -net pcie_clk_reset_peripheral_aresetn [get_bd_pins pcie_rst_n_out_peripheral] [get_bd_pins axi_bram_ctrl_msix_table/s_axi_aresetn] [get_bd_pins pcie_clk_reset/peripheral_aresetn]
  connect_bd_net -net pcie_rst_n_1 [get_bd_pins pcie_rst_n] [get_bd_pins pcie_clk_reset/ext_reset_in]
  connect_bd_net -net soft_rst_n_1 [get_bd_pins soft_rst_n] [get_bd_pins pcie_clk_reset/aux_reset_in]
  connect_bd_net -net util_ds_buf_0_IBUF_DS_ODIV2 [get_bd_pins pcie_refclk_out_div2] [get_bd_pins pcie_refclk_buf/IBUF_DS_ODIV2]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_pins pcie_refclk_out] [get_bd_pins pcie_refclk_buf/IBUF_OUT]
  connect_bd_net -net util_reduced_logic_0_Res [get_bd_pins intx_msi_req] [get_bd_pins util_reduced_logic_0/Res]
  connect_bd_net -net util_reduced_logic_1_Res [get_bd_pins irq_in_00] [get_bd_pins xlconcat_intc_pcie_0/In0]
  connect_bd_net -net xlconcat_0_dout [get_bd_pins util_reduced_logic_0/Op1] [get_bd_pins xlconcat_0/dout]
  connect_bd_net -net xlconcat_intc_pcie_0_dout [get_bd_pins msix_irq] [get_bd_pins xlconcat_intc_pcie_0/dout]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: bram_hw_table
proc create_hier_cell_bram_hw_table { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_bram_hw_table() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axi_bram_ctrl, and set properties
  set axi_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl ]

  # Create instance: blk_mem_gen, and set properties
  set blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {true} \
   CONFIG.Coe_File {../../../../../../hw_table_generator/hwtab.coe} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Load_Init_File {true} \
   CONFIG.Memory_Type {Dual_Port_ROM} \
   CONFIG.Port_A_Write_Rate {0} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {0} \
   CONFIG.Use_Byte_Write_Enable {false} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_hw_info_table_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_hw_info_table_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_main_M00_AXI [get_bd_intf_pins s_axi] [get_bd_intf_pins axi_bram_ctrl/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins rst_n] [get_bd_pins axi_bram_ctrl/s_axi_aresetn]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_pins clk] [get_bd_pins axi_bram_ctrl/s_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: bram_bootrom
proc create_hier_cell_bram_bootrom { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_bram_bootrom() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axi_bram_ctrl, and set properties
  set axi_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl

  # Create instance: blk_mem_gen, and set properties
  set blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {false} \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Fill_Remaining_Memory_Locations {false} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {true} \
   CONFIG.Use_RSTB_Pin {true} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $blk_mem_gen

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins s_axi] [get_bd_intf_pins axi_bram_ctrl/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins rst_n] [get_bd_pins axi_bram_ctrl/s_axi_aresetn]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_pins clk] [get_bd_pins axi_bram_ctrl/s_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: bram_2
proc create_hier_cell_bram_2 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_bram_2() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axi_bram_ctrl, and set properties
  set axi_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl

  # Create instance: blk_mem_gen, and set properties
  set blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_2_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_main_M13_AXI [get_bd_intf_pins s_axi] [get_bd_intf_pins axi_bram_ctrl/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins rst_n] [get_bd_pins axi_bram_ctrl/s_axi_aresetn]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_pins clk] [get_bd_pins axi_bram_ctrl/s_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: bram_1
proc create_hier_cell_bram_1 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_bram_1() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axi_bram_ctrl, and set properties
  set axi_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl

  # Create instance: blk_mem_gen, and set properties
  set blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen ]
  set_property -dict [ list \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Use_RSTB_Pin {true} \
 ] $blk_mem_gen

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net axi_interconnect_main_M12_AXI [get_bd_intf_pins s_axi] [get_bd_intf_pins axi_bram_ctrl/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins rst_n] [get_bd_pins axi_bram_ctrl/s_axi_aresetn]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_pins clk] [get_bd_pins axi_bram_ctrl/s_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: bram_0
proc create_hier_cell_bram_0 { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_bram_0() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axi_bram_ctrl, and set properties
  set axi_bram_ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl axi_bram_ctrl ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.ECC_TYPE {0} \
 ] $axi_bram_ctrl

  # Create instance: blk_mem_gen, and set properties
  set blk_mem_gen [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen blk_mem_gen ]
  set_property -dict [ list \
   CONFIG.Assume_Synchronous_Clk {false} \
   CONFIG.Byte_Size {8} \
   CONFIG.EN_SAFETY_CKT {false} \
   CONFIG.Enable_32bit_Address {true} \
   CONFIG.Enable_B {Use_ENB_Pin} \
   CONFIG.Fill_Remaining_Memory_Locations {false} \
   CONFIG.Memory_Type {True_Dual_Port_RAM} \
   CONFIG.Port_B_Clock {100} \
   CONFIG.Port_B_Enable_Rate {100} \
   CONFIG.Port_B_Write_Rate {50} \
   CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
   CONFIG.Register_PortB_Output_of_Memory_Primitives {false} \
   CONFIG.Use_Byte_Write_Enable {true} \
   CONFIG.Use_RSTA_Pin {true} \
   CONFIG.Use_RSTB_Pin {true} \
   CONFIG.use_bram_block {BRAM_Controller} \
 ] $blk_mem_gen

  # Create interface connections
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen/BRAM_PORTA]
  connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTB [get_bd_intf_pins axi_bram_ctrl/BRAM_PORTB] [get_bd_intf_pins blk_mem_gen/BRAM_PORTB]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins s_axi] [get_bd_intf_pins axi_bram_ctrl/S_AXI]

  # Create port connections
  connect_bd_net -net S00_ARESETN_1 [get_bd_pins rst_n] [get_bd_pins axi_bram_ctrl/s_axi_aresetn]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_pins clk] [get_bd_pins axi_bram_ctrl/s_axi_aclk]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  
# Hierarchical cell: axi_dma_mm2mm
proc create_hier_cell_axi_dma_mm2mm { parentCell nameHier } {

  variable script_folder

  if { $parentCell eq "" || $nameHier eq "" } {
     catch {common::send_msg_id "BD_TCL-102" "ERROR" "create_hier_cell_axi_dma_mm2mm() - Empty argument(s)!"}
     return
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj

  # Create cell and set as current instance
  set hier_obj [create_bd_cell -type hier $nameHier]
  current_bd_instance $hier_obj

  # Create interface pins
  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dma_mm2s

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dma_s2mm

  create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 m_axi_dma_sg

  create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 s_axi_dma_ctrl


  # Create pins
  create_bd_pin -dir I -type clk clk
  create_bd_pin -dir O -type intr irq_out_mm2s
  create_bd_pin -dir O -type intr irq_out_s2mm
  create_bd_pin -dir I -type rst rst_n

  # Create instance: axi_data_fifo_0, and set properties
  set axi_data_fifo_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_data_fifo axi_data_fifo_0 ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {32} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.READ_FIFO_DEPTH {512} \
   CONFIG.WRITE_FIFO_DEPTH {512} \
 ] $axi_data_fifo_0

  # Create instance: axi_dma, and set properties
  set axi_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma axi_dma ]
  set_property -dict [ list \
   CONFIG.c_addr_width {42} \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_include_sg {1} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axis_mm2s_tdata_width {512} \
   CONFIG.c_mm2s_burst_size {16} \
   CONFIG.c_sg_include_stscntrl_strm {0} \
   CONFIG.c_sg_length_width {26} \
 ] $axi_dma

  # Create instance: axi_protocol_convert_0, and set properties
  set axi_protocol_convert_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_protocol_converter axi_protocol_convert_0 ]
  set_property -dict [ list \
   CONFIG.DATA_WIDTH {32} \
 ] $axi_protocol_convert_0

  # Create instance: axis_dma_fifo, and set properties
  set axis_dma_fifo [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo axis_dma_fifo ]
  set_property -dict [ list \
   CONFIG.FIFO_DEPTH {1024} \
   CONFIG.HAS_RD_DATA_COUNT {1} \
   CONFIG.HAS_WR_DATA_COUNT {1} \
   CONFIG.SYNCHRONIZATION_STAGES {3} \
 ] $axis_dma_fifo

  # Create interface connections
  connect_bd_intf_net -intf_net Conn1 [get_bd_intf_pins m_axi_dma_sg] [get_bd_intf_pins axi_dma/M_AXI_SG]
  connect_bd_intf_net -intf_net axi_data_fifo_0_M_AXI [get_bd_intf_pins axi_data_fifo_0/M_AXI] [get_bd_intf_pins axi_protocol_convert_0/S_AXI]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXIS_MM2S [get_bd_intf_pins axi_dma/M_AXIS_MM2S] [get_bd_intf_pins axis_dma_fifo/S_AXIS]
  connect_bd_intf_net -intf_net axi_protocol_convert_0_M_AXI [get_bd_intf_pins axi_dma/S_AXI_LITE] [get_bd_intf_pins axi_protocol_convert_0/M_AXI]
  connect_bd_intf_net -intf_net axi_simple_dma_M_AXI_MM2S [get_bd_intf_pins m_axi_dma_mm2s] [get_bd_intf_pins axi_dma/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_simple_dma_M_AXI_S2MM [get_bd_intf_pins m_axi_dma_s2mm] [get_bd_intf_pins axi_dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net axis_data_fifo_0_M_AXIS [get_bd_intf_pins axi_dma/S_AXIS_S2MM] [get_bd_intf_pins axis_dma_fifo/M_AXIS]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M14_AXI [get_bd_intf_pins s_axi_dma_ctrl] [get_bd_intf_pins axi_data_fifo_0/S_AXI]

  # Create port connections
  connect_bd_net -net axi_simple_dma_mm2s_introut [get_bd_pins irq_out_mm2s] [get_bd_pins axi_dma/mm2s_introut]
  connect_bd_net -net axi_simple_dma_s2mm_introut [get_bd_pins irq_out_s2mm] [get_bd_pins axi_dma/s2mm_introut]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_pins clk] [get_bd_pins axi_data_fifo_0/aclk] [get_bd_pins axi_dma/m_axi_mm2s_aclk] [get_bd_pins axi_dma/m_axi_s2mm_aclk] [get_bd_pins axi_dma/m_axi_sg_aclk] [get_bd_pins axi_dma/s_axi_lite_aclk] [get_bd_pins axi_protocol_convert_0/aclk] [get_bd_pins axis_dma_fifo/s_axis_aclk]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins rst_n] [get_bd_pins axi_data_fifo_0/aresetn] [get_bd_pins axi_dma/axi_resetn] [get_bd_pins axi_protocol_convert_0/aresetn] [get_bd_pins axis_dma_fifo/s_axis_aresetn]

  # Restore current instance
  current_bd_instance $oldCurInst
}
  variable script_folder

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_msg_id "BD_TCL-100" "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_msg_id "BD_TCL-101" "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set DDR_AXI_S [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 DDR_AXI_S ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.DATA_WIDTH {512} \
   CONFIG.FREQ_HZ {200000000} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $DDR_AXI_S

  set MSIX_TABLE_BRAM_PORTB [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:bram_rtl:1.0 MSIX_TABLE_BRAM_PORTB ]
  set_property -dict [ list \
   CONFIG.MASTER_TYPE {BRAM_CTRL} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   ] $MSIX_TABLE_BRAM_PORTB

  set PCIE_AXI_M [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 PCIE_AXI_M ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {3} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {1} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {1} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $PCIE_AXI_M

  set PCIE_AXI_S [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 PCIE_AXI_S ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.DATA_WIDTH {256} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.PROTOCOL {AXI4} \
   ] $PCIE_AXI_S

  set PCIE_AXI_S_CTL [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 PCIE_AXI_S_CTL ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {41} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.PROTOCOL {AXI4} \
   ] $PCIE_AXI_S_CTL

  set UART_AXI_S [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 UART_AXI_S ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {41} \
   CONFIG.DATA_WIDTH {32} \
   CONFIG.FREQ_HZ {250000000} \
   CONFIG.PROTOCOL {AXI4LITE} \
   ] $UART_AXI_S

  set ariane_axi [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 ariane_axi ]
  set_property -dict [ list \
   CONFIG.ADDR_WIDTH {64} \
   CONFIG.ARUSER_WIDTH {0} \
   CONFIG.AWUSER_WIDTH {0} \
   CONFIG.BUSER_WIDTH {0} \
   CONFIG.DATA_WIDTH {64} \
   CONFIG.HAS_BRESP {1} \
   CONFIG.HAS_BURST {1} \
   CONFIG.HAS_CACHE {1} \
   CONFIG.HAS_LOCK {1} \
   CONFIG.HAS_PROT {1} \
   CONFIG.HAS_QOS {1} \
   CONFIG.HAS_REGION {1} \
   CONFIG.HAS_RRESP {1} \
   CONFIG.HAS_WSTRB {1} \
   CONFIG.ID_WIDTH {4} \
   CONFIG.MAX_BURST_LENGTH {256} \
   CONFIG.NUM_READ_OUTSTANDING {2} \
   CONFIG.NUM_READ_THREADS {1} \
   CONFIG.NUM_WRITE_OUTSTANDING {2} \
   CONFIG.NUM_WRITE_THREADS {1} \
   CONFIG.PROTOCOL {AXI4} \
   CONFIG.READ_WRITE_MODE {READ_WRITE} \
   CONFIG.RUSER_BITS_PER_BYTE {0} \
   CONFIG.RUSER_WIDTH {0} \
   CONFIG.SUPPORTS_NARROW_BURST {1} \
   CONFIG.WUSER_BITS_PER_BYTE {0} \
   CONFIG.WUSER_WIDTH {0} \
   ] $ariane_axi

  set axi_dma_nic_0_M_AXIS_MM2S [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_nic_0_M_AXIS_MM2S ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $axi_dma_nic_0_M_AXIS_MM2S

  set axi_dma_nic_0_S_AXIS_S2MM [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 axi_dma_nic_0_S_AXIS_S2MM ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   CONFIG.HAS_TKEEP {1} \
   CONFIG.HAS_TLAST {1} \
   CONFIG.HAS_TREADY {1} \
   CONFIG.HAS_TSTRB {0} \
   CONFIG.LAYERED_METADATA {undef} \
   CONFIG.TDATA_NUM_BYTES {8} \
   CONFIG.TDEST_WIDTH {0} \
   CONFIG.TID_WIDTH {0} \
   CONFIG.TUSER_WIDTH {0} \
   ] $axi_dma_nic_0_S_AXIS_S2MM


  # Create ports
  set ARIANE_CLK [ create_bd_port -dir O -from 0 -to 0 -type clk ARIANE_CLK ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {ariane_axi} \
 ] $ARIANE_CLK
  set ARIANE_RST_N [ create_bd_port -dir O -from 0 -to 0 ARIANE_RST_N ]
  set FPGA_SYSCLK [ create_bd_port -dir I -type clk FPGA_SYSCLK ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {DDR_AXI_S} \
   CONFIG.ASSOCIATED_RESET {SYSCLK_RSTN_PERIPHERAL} \
   CONFIG.FREQ_HZ {200000000} \
 ] $FPGA_SYSCLK
  set LOCK [ create_bd_port -dir I LOCK ]
  set MSIX_IRQ [ create_bd_port -dir O -from 5 -to 0 MSIX_IRQ ]
  set NIC_0_ACLK [ create_bd_port -dir I -type clk NIC_0_ACLK ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_RESET {NIC_0_ARESETN} \
   CONFIG.FREQ_HZ {156250000} \
 ] $NIC_0_ACLK
  set NIC_0_ARESETN [ create_bd_port -dir I -type rst NIC_0_ARESETN ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_LOW} \
 ] $NIC_0_ARESETN
  set PCIE_ACLK_IN [ create_bd_port -dir I -type clk PCIE_ACLK_IN ]
  set_property -dict [ list \
   CONFIG.ASSOCIATED_BUSIF {PCIE_AXI_M:PCIE_AXI_S_CTL:PCIE_AXI_S:UART_AXI_S} \
   CONFIG.ASSOCIATED_RESET {PCIE_ARESETN_IN:PERSTN} \
   CONFIG.FREQ_HZ {250000000} \
 ] $PCIE_ACLK_IN
  set PCIE_ARESETN_IN [ create_bd_port -dir I -type rst PCIE_ARESETN_IN ]
  set PCIE_CLK_N [ create_bd_port -dir I -type clk PCIE_CLK_N ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
 ] $PCIE_CLK_N
  set PCIE_CLK_P [ create_bd_port -dir I -type clk PCIE_CLK_P ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {100000000} \
 ] $PCIE_CLK_P
  set PCIE_INTX_MSI_REQUEST [ create_bd_port -dir O PCIE_INTX_MSI_REQUEST ]
  set PCIE_MSI_ENABLE [ create_bd_port -dir I PCIE_MSI_ENABLE ]
  set PCIE_MSI_VECTOR_NUM [ create_bd_port -dir O -from 4 -to 0 PCIE_MSI_VECTOR_NUM ]
  set PCIE_REFCLK_OUT [ create_bd_port -dir O -from 0 -to 0 -type clk PCIE_REFCLK_OUT ]
  set PCIE_REFCLK_OUT_DIV2 [ create_bd_port -dir O -from 0 -to 0 -type clk PCIE_REFCLK_OUT_DIV2 ]
  set PERSTN [ create_bd_port -dir I -type rst PERSTN ]
  set SYSCLK_RSTN_PERIPHERAL [ create_bd_port -dir O -from 0 -to 0 -type rst SYSCLK_RSTN_PERIPHERAL ]
  set UART_ARESETN_OUT [ create_bd_port -dir O -from 0 -to 0 -type rst UART_ARESETN_OUT ]

  # Create instance: axi_dma_mm2mm
  create_hier_cell_axi_dma_mm2mm [current_bd_instance .] axi_dma_mm2mm

  # Create instance: axi_interconnect_main, and set properties
  set axi_interconnect_main [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_main ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.ENABLE_PROTOCOL_CHECKERS {0} \
   CONFIG.M00_HAS_DATA_FIFO {0} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M01_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {0} \
   CONFIG.M03_HAS_REGSLICE {4} \
   CONFIG.M04_HAS_REGSLICE {0} \
   CONFIG.M05_HAS_REGSLICE {4} \
   CONFIG.M06_HAS_REGSLICE {4} \
   CONFIG.M07_HAS_REGSLICE {4} \
   CONFIG.M08_HAS_REGSLICE {4} \
   CONFIG.M09_HAS_REGSLICE {4} \
   CONFIG.M10_HAS_REGSLICE {4} \
   CONFIG.M11_HAS_REGSLICE {0} \
   CONFIG.M12_HAS_REGSLICE {0} \
   CONFIG.M14_HAS_DATA_FIFO {0} \
   CONFIG.M14_HAS_REGSLICE {0} \
   CONFIG.NUM_MI {15} \
   CONFIG.NUM_SI {9} \
   CONFIG.S00_HAS_DATA_FIFO {2} \
   CONFIG.S00_HAS_REGSLICE {3} \
   CONFIG.S01_HAS_DATA_FIFO {2} \
   CONFIG.S01_HAS_REGSLICE {3} \
   CONFIG.S02_HAS_DATA_FIFO {2} \
   CONFIG.S02_HAS_REGSLICE {3} \
   CONFIG.S03_HAS_DATA_FIFO {2} \
   CONFIG.S03_HAS_REGSLICE {3} \
   CONFIG.S04_HAS_DATA_FIFO {2} \
   CONFIG.S04_HAS_REGSLICE {3} \
   CONFIG.S05_HAS_DATA_FIFO {0} \
   CONFIG.S05_HAS_REGSLICE {0} \
   CONFIG.S06_HAS_DATA_FIFO {0} \
   CONFIG.S06_HAS_REGSLICE {4} \
   CONFIG.S07_HAS_DATA_FIFO {2} \
   CONFIG.S07_HAS_REGSLICE {3} \
   CONFIG.S08_HAS_DATA_FIFO {2} \
   CONFIG.S08_HAS_REGSLICE {3} \
   CONFIG.STRATEGY {0} \
   CONFIG.SYNCHRONIZATION_STAGES {2} \
   CONFIG.XBAR_DATA_WIDTH {64} \
 ] $axi_interconnect_main

  # Create instance: axi_interconnect_mem, and set properties
  set axi_interconnect_mem [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect axi_interconnect_mem ]
  set_property -dict [ list \
   CONFIG.ENABLE_ADVANCED_OPTIONS {1} \
   CONFIG.M00_HAS_REGSLICE {4} \
   CONFIG.M02_HAS_REGSLICE {4} \
   CONFIG.NUM_MI {3} \
   CONFIG.NUM_SI {8} \
   CONFIG.S00_HAS_REGSLICE {0} \
   CONFIG.S03_HAS_REGSLICE {4} \
   CONFIG.XBAR_DATA_WIDTH {512} \
 ] $axi_interconnect_mem

  # Create instance: axi_timer_0, and set properties
  set axi_timer_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_timer axi_timer_0 ]

  # Create instance: bram_0
  create_hier_cell_bram_0 [current_bd_instance .] bram_0

  # Create instance: bram_1
  create_hier_cell_bram_1 [current_bd_instance .] bram_1

  # Create instance: bram_2
  create_hier_cell_bram_2 [current_bd_instance .] bram_2

  # Create instance: bram_bootrom
  create_hier_cell_bram_bootrom [current_bd_instance .] bram_bootrom

  # Create instance: bram_hw_table
  create_hier_cell_bram_hw_table [current_bd_instance .] bram_hw_table

  # Create instance: bsv_riscv_flute, and set properties
  set bsv_riscv_flute [ create_bd_cell -type ip -vlnv COMPAS:COMPAS:bsv_riscv_flute_ADFIMU bsv_riscv_flute ]

  # Create instance: clk_buf_core, and set properties
  set clk_buf_core [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf clk_buf_core ]
  set_property -dict [ list \
   CONFIG.C_BUF_TYPE {BUFG} \
 ] $clk_buf_core

  # Create instance: clk_wiz_core, and set properties
  set clk_wiz_core [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz clk_wiz_core ]
  set_property -dict [ list \
   CONFIG.CLKOUT1_JITTER {129.198} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {50.000} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {20.000} \
   CONFIG.USE_RESET {false} \
 ] $clk_wiz_core

  # Create instance: core_0_rst_n, and set properties
  set core_0_rst_n [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic core_0_rst_n ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $core_0_rst_n

  # Create instance: core_1_rst_n, and set properties
  set core_1_rst_n [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic core_1_rst_n ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $core_1_rst_n

  # Create instance: core_2_rst_n, and set properties
  set core_2_rst_n [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic core_2_rst_n ]
  set_property -dict [ list \
   CONFIG.C_OPERATION {and} \
   CONFIG.C_SIZE {1} \
   CONFIG.LOGO_FILE {data/sym_andgate.png} \
 ] $core_2_rst_n

  # Create instance: mdm_0, and set properties
  set mdm_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:mdm mdm_0 ]
  set_property -dict [ list \
   CONFIG.C_ADDR_SIZE {32} \
   CONFIG.C_MB_DBG_PORTS {1} \
   CONFIG.C_M_AXI_ADDR_WIDTH {32} \
 ] $mdm_0

  # Create instance: nic_axi_dma, and set properties
  set nic_axi_dma [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dma nic_axi_dma ]
  set_property -dict [ list \
   CONFIG.c_addr_width {42} \
   CONFIG.c_include_mm2s_dre {1} \
   CONFIG.c_include_s2mm_dre {1} \
   CONFIG.c_m_axi_mm2s_data_width {512} \
   CONFIG.c_m_axi_s2mm_data_width {512} \
   CONFIG.c_m_axis_mm2s_tdata_width {64} \
   CONFIG.c_mm2s_burst_size {64} \
   CONFIG.c_s2mm_burst_size {64} \
   CONFIG.c_sg_include_stscntrl_strm {0} \
   CONFIG.c_sg_length_width {26} \
 ] $nic_axi_dma

  # Create instance: nic_reset, and set properties
  set nic_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset nic_reset ]

  # Create instance: pcie
  create_hier_cell_pcie [current_bd_instance .] pcie

  # Create instance: proc_sys_reset_core, and set properties
  set proc_sys_reset_core [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset proc_sys_reset_core ]

  # Create instance: soft_reset, and set properties
  set soft_reset [ create_bd_cell -type ip -vlnv COMPAS:COMPAS:soft_reset_v2 soft_reset ]

  # Create instance: sys_clk_reset, and set properties
  set sys_clk_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset sys_clk_reset ]

  # Create interface connections
  connect_bd_intf_net -intf_net PCIE_AXI_M_1 [get_bd_intf_ports PCIE_AXI_M] [get_bd_intf_pins axi_interconnect_main/S02_AXI]
  connect_bd_intf_net -intf_net S00_AXI_1 [get_bd_intf_pins axi_interconnect_main/M04_AXI] [get_bd_intf_pins axi_interconnect_mem/S00_AXI]
  connect_bd_intf_net -intf_net S01_AXI_1 [get_bd_intf_pins axi_interconnect_mem/S01_AXI] [get_bd_intf_pins nic_axi_dma/M_AXI_MM2S]
  connect_bd_intf_net -intf_net S02_AXI_1 [get_bd_intf_pins axi_interconnect_mem/S02_AXI] [get_bd_intf_pins nic_axi_dma/M_AXI_S2MM]
  connect_bd_intf_net -intf_net S03_AXI_1 [get_bd_intf_pins axi_dma_mm2mm/m_axi_dma_sg] [get_bd_intf_pins axi_interconnect_mem/S03_AXI]
  connect_bd_intf_net -intf_net S08_AXI_0_1 [get_bd_intf_ports ariane_axi] [get_bd_intf_pins axi_interconnect_main/S08_AXI]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets S08_AXI_0_1]
  connect_bd_intf_net -intf_net axi_dma_0_M_AXI_SG [get_bd_intf_pins axi_interconnect_main/S03_AXI] [get_bd_intf_pins nic_axi_dma/M_AXI_SG]
  connect_bd_intf_net -intf_net axi_dma_mm2mm_m_axi_dma_mm2s [get_bd_intf_pins axi_dma_mm2mm/m_axi_dma_mm2s] [get_bd_intf_pins axi_interconnect_mem/S04_AXI]
  connect_bd_intf_net -intf_net axi_dma_mm2mm_m_axi_dma_s2mm [get_bd_intf_pins axi_dma_mm2mm/m_axi_dma_s2mm] [get_bd_intf_pins axi_interconnect_mem/S05_AXI]
  connect_bd_intf_net -intf_net axi_dma_nic_0_M_AXIS_MM2S1 [get_bd_intf_ports axi_dma_nic_0_M_AXIS_MM2S] [get_bd_intf_pins nic_axi_dma/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_dma_nic_0_S_AXIS_S2MM_1 [get_bd_intf_ports axi_dma_nic_0_S_AXIS_S2MM] [get_bd_intf_pins nic_axi_dma/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net axi_interconnect_0_M00_AXI [get_bd_intf_ports PCIE_AXI_S] [get_bd_intf_pins axi_interconnect_mem/M00_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_0_M01_AXI [get_bd_intf_ports DDR_AXI_S] [get_bd_intf_pins axi_interconnect_mem/M01_AXI]
  connect_bd_intf_net -intf_net axi_interconnect_main_M00_AXI [get_bd_intf_pins axi_interconnect_main/M00_AXI] [get_bd_intf_pins bram_hw_table/s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_main_M10_AXI [get_bd_intf_pins axi_interconnect_main/M10_AXI] [get_bd_intf_pins soft_reset/axis_soft_reset_reg]
  connect_bd_intf_net -intf_net axi_interconnect_main_M12_AXI [get_bd_intf_pins axi_interconnect_main/M12_AXI] [get_bd_intf_pins bram_1/s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_main_M13_AXI [get_bd_intf_pins axi_interconnect_main/M13_AXI] [get_bd_intf_pins bram_2/s_axi]
  connect_bd_intf_net -intf_net axi_interconnect_mem_M02_AXI [get_bd_intf_pins axi_interconnect_mem/M02_AXI] [get_bd_intf_pins bram_bootrom/s_axi]
  connect_bd_intf_net -intf_net blk_mem_gen_msix_table_BRAM_PORTB [get_bd_intf_ports MSIX_TABLE_BRAM_PORTB] [get_bd_intf_pins pcie/msix_table_bram_portb]
  connect_bd_intf_net -intf_net bsv_riscv_flute_ADFI_0_M_AXI_DMEM [get_bd_intf_pins axi_interconnect_main/S07_AXI] [get_bd_intf_pins bsv_riscv_flute/M_AXI_DMEM]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets bsv_riscv_flute_ADFI_0_M_AXI_DMEM]
  connect_bd_intf_net -intf_net bsv_riscv_flute_ADFI_0_M_AXI_IMEM [get_bd_intf_pins axi_interconnect_main/S06_AXI] [get_bd_intf_pins bsv_riscv_flute/M_AXI_IMEM]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_intf_nets bsv_riscv_flute_ADFI_0_M_AXI_IMEM]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M01_AXI [get_bd_intf_ports UART_AXI_S] [get_bd_intf_pins axi_interconnect_main/M01_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M02_AXI [get_bd_intf_pins axi_interconnect_main/M02_AXI] [get_bd_intf_pins bram_0/s_axi]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M03_AXI [get_bd_intf_ports PCIE_AXI_S_CTL] [get_bd_intf_pins axi_interconnect_main/M03_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M05_AXI [get_bd_intf_pins axi_interconnect_main/M05_AXI] [get_bd_intf_pins nic_axi_dma/S_AXI_LITE]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M06_AXI [get_bd_intf_pins axi_interconnect_main/M06_AXI] [get_bd_intf_pins axi_timer_0/S_AXI]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M08_AXI [get_bd_intf_pins axi_interconnect_main/M08_AXI] [get_bd_intf_pins pcie/s_axi_msix_tablele]
  connect_bd_intf_net -intf_net microblaze_0_axi_periph_M14_AXI [get_bd_intf_pins axi_dma_mm2mm/s_axi_dma_ctrl] [get_bd_intf_pins axi_interconnect_main/M14_AXI]

  # Create port connections
  connect_bd_net -net NIC_0_ACLK_1 [get_bd_ports NIC_0_ACLK] [get_bd_pins axi_interconnect_main/M05_ACLK] [get_bd_pins axi_interconnect_main/S03_ACLK] [get_bd_pins axi_interconnect_mem/S01_ACLK] [get_bd_pins axi_interconnect_mem/S02_ACLK] [get_bd_pins nic_axi_dma/m_axi_mm2s_aclk] [get_bd_pins nic_axi_dma/m_axi_s2mm_aclk] [get_bd_pins nic_axi_dma/m_axi_sg_aclk] [get_bd_pins nic_axi_dma/s_axi_lite_aclk] [get_bd_pins nic_reset/slowest_sync_clk]
  connect_bd_net -net NIC_0_ARESETN_1 [get_bd_pins axi_interconnect_main/M05_ARESETN] [get_bd_pins axi_interconnect_main/S03_ARESETN] [get_bd_pins axi_interconnect_mem/S01_ARESETN] [get_bd_pins axi_interconnect_mem/S02_ARESETN] [get_bd_pins nic_axi_dma/axi_resetn] [get_bd_pins nic_reset/peripheral_aresetn]
  connect_bd_net -net NIC_0_ARESETN_2 [get_bd_ports NIC_0_ARESETN] [get_bd_pins nic_reset/ext_reset_in]
  connect_bd_net -net PCIE_CLK_N_1 [get_bd_ports PCIE_CLK_N] [get_bd_pins pcie/pcie_link_clk_n]
  connect_bd_net -net PCIE_CLK_P_1 [get_bd_ports PCIE_CLK_P] [get_bd_pins pcie/pcie_link_clk_p]
  connect_bd_net -net PERSTN_1 [get_bd_ports PERSTN] [get_bd_pins proc_sys_reset_core/ext_reset_in] [get_bd_pins soft_reset/i_rst_n] [get_bd_pins sys_clk_reset/ext_reset_in]
  connect_bd_net -net S00_ARESETN_1 [get_bd_ports SYSCLK_RSTN_PERIPHERAL] [get_bd_pins axi_interconnect_main/M00_ARESETN] [get_bd_pins axi_interconnect_main/M02_ARESETN] [get_bd_pins axi_interconnect_main/M04_ARESETN] [get_bd_pins axi_interconnect_main/M06_ARESETN] [get_bd_pins axi_interconnect_main/M09_ARESETN] [get_bd_pins axi_interconnect_main/M11_ARESETN] [get_bd_pins axi_interconnect_main/M12_ARESETN] [get_bd_pins axi_interconnect_main/M13_ARESETN] [get_bd_pins axi_interconnect_main/M14_ARESETN] [get_bd_pins axi_interconnect_mem/ARESETN] [get_bd_pins axi_interconnect_mem/M01_ARESETN] [get_bd_pins axi_interconnect_mem/M02_ARESETN] [get_bd_pins axi_interconnect_mem/S00_ARESETN] [get_bd_pins axi_interconnect_mem/S03_ARESETN] [get_bd_pins axi_interconnect_mem/S04_ARESETN] [get_bd_pins axi_interconnect_mem/S05_ARESETN] [get_bd_pins axi_timer_0/s_axi_aresetn] [get_bd_pins bram_0/rst_n] [get_bd_pins bram_1/rst_n] [get_bd_pins bram_2/rst_n] [get_bd_pins bram_bootrom/rst_n] [get_bd_pins bram_hw_table/rst_n] [get_bd_pins sys_clk_reset/peripheral_aresetn]
  connect_bd_net -net axi_dma_0_mm2s_introut [get_bd_pins nic_axi_dma/mm2s_introut] [get_bd_pins pcie/irq_in_02]
  connect_bd_net -net axi_dma_0_s2mm_introut [get_bd_pins nic_axi_dma/s2mm_introut] [get_bd_pins pcie/irq_in_01]
  connect_bd_net -net axi_pcie3_0_axi_aclk [get_bd_ports PCIE_ACLK_IN] [get_bd_pins axi_interconnect_main/M01_ACLK] [get_bd_pins axi_interconnect_main/M03_ACLK] [get_bd_pins axi_interconnect_main/M08_ACLK] [get_bd_pins axi_interconnect_main/M10_ACLK] [get_bd_pins axi_interconnect_main/S02_ACLK] [get_bd_pins axi_interconnect_mem/M00_ACLK] [get_bd_pins pcie/clk_pcie] [get_bd_pins soft_reset/i_clk]
  connect_bd_net -net axi_pcie3_0_axi_aresetn [get_bd_ports UART_ARESETN_OUT] [get_bd_pins axi_interconnect_main/M01_ARESETN] [get_bd_pins axi_interconnect_main/M03_ARESETN] [get_bd_pins axi_interconnect_main/M08_ARESETN] [get_bd_pins axi_interconnect_main/M10_ARESETN] [get_bd_pins axi_interconnect_main/S02_ARESETN] [get_bd_pins axi_interconnect_mem/M00_ARESETN] [get_bd_pins pcie/pcie_rst_n_out_peripheral]
  connect_bd_net -net axi_simple_dma_mm2mm_mm2s_introut [get_bd_pins axi_dma_mm2mm/irq_out_mm2s] [get_bd_pins pcie/irq_in_04]
  connect_bd_net -net axi_simple_dma_mm2mm_s2mm_introut [get_bd_pins axi_dma_mm2mm/irq_out_s2mm] [get_bd_pins pcie/irq_in_05]
  connect_bd_net -net clk_buf_fpga_sysclk_out [get_bd_ports FPGA_SYSCLK] [get_bd_pins axi_dma_mm2mm/clk] [get_bd_pins axi_interconnect_main/ACLK] [get_bd_pins axi_interconnect_main/M00_ACLK] [get_bd_pins axi_interconnect_main/M02_ACLK] [get_bd_pins axi_interconnect_main/M04_ACLK] [get_bd_pins axi_interconnect_main/M06_ACLK] [get_bd_pins axi_interconnect_main/M07_ACLK] [get_bd_pins axi_interconnect_main/M09_ACLK] [get_bd_pins axi_interconnect_main/M11_ACLK] [get_bd_pins axi_interconnect_main/M12_ACLK] [get_bd_pins axi_interconnect_main/M13_ACLK] [get_bd_pins axi_interconnect_main/M14_ACLK] [get_bd_pins axi_interconnect_mem/ACLK] [get_bd_pins axi_interconnect_mem/M01_ACLK] [get_bd_pins axi_interconnect_mem/M02_ACLK] [get_bd_pins axi_interconnect_mem/S00_ACLK] [get_bd_pins axi_interconnect_mem/S03_ACLK] [get_bd_pins axi_interconnect_mem/S04_ACLK] [get_bd_pins axi_interconnect_mem/S05_ACLK] [get_bd_pins axi_timer_0/s_axi_aclk] [get_bd_pins bram_0/clk] [get_bd_pins bram_1/clk] [get_bd_pins bram_2/clk] [get_bd_pins bram_bootrom/clk] [get_bd_pins bram_hw_table/clk] [get_bd_pins clk_wiz_core/clk_in1] [get_bd_pins sys_clk_reset/slowest_sync_clk]
  connect_bd_net -net clk_wiz_0_clk_out1 [get_bd_pins clk_buf_core/BUFG_I] [get_bd_pins clk_wiz_core/clk_out1]
  connect_bd_net -net clk_wiz_0_locked [get_bd_pins clk_wiz_core/locked] [get_bd_pins proc_sys_reset_core/dcm_locked]
  connect_bd_net -net core_0_rst_n_Res [get_bd_pins bsv_riscv_flute/RST_N] [get_bd_pins core_0_rst_n/Res]
  connect_bd_net -net core_1_rst_n_Res [get_bd_ports ARIANE_RST_N] [get_bd_pins core_1_rst_n/Res]
  set_property HDL_ATTRIBUTE.DEBUG {true} [get_bd_nets core_1_rst_n_Res]
  connect_bd_net -net dcm_locked_0_1 [get_bd_ports LOCK] [get_bd_pins nic_reset/dcm_locked] [get_bd_pins sys_clk_reset/dcm_locked]
  connect_bd_net -net mdm_0_Debug_SYS_Rst [get_bd_pins mdm_0/Debug_SYS_Rst] [get_bd_pins sys_clk_reset/mb_debug_sys_rst]
  connect_bd_net -net pcie_aresetn [get_bd_ports PCIE_ARESETN_IN] [get_bd_pins pcie/pcie_rst_n]
  connect_bd_net -net pcie_dout_0 [get_bd_ports MSIX_IRQ] [get_bd_pins pcie/msix_irq]
  connect_bd_net -net proc_sys_reset_core_peripheral_aresetn [get_bd_pins axi_interconnect_main/S00_ARESETN] [get_bd_pins axi_interconnect_main/S01_ARESETN] [get_bd_pins axi_interconnect_main/S04_ARESETN] [get_bd_pins axi_interconnect_main/S05_ARESETN] [get_bd_pins axi_interconnect_main/S06_ARESETN] [get_bd_pins axi_interconnect_main/S07_ARESETN] [get_bd_pins axi_interconnect_main/S08_ARESETN] [get_bd_pins axi_interconnect_mem/S06_ARESETN] [get_bd_pins axi_interconnect_mem/S07_ARESETN] [get_bd_pins core_0_rst_n/Op1] [get_bd_pins core_1_rst_n/Op1] [get_bd_pins core_2_rst_n/Op1] [get_bd_pins proc_sys_reset_core/peripheral_aresetn]
  connect_bd_net -net rst_clk_wiz_1_100M_interconnect_aresetn [get_bd_pins axi_dma_mm2mm/rst_n] [get_bd_pins axi_interconnect_main/ARESETN] [get_bd_pins axi_interconnect_main/M07_ARESETN] [get_bd_pins sys_clk_reset/interconnect_aresetn]
  connect_bd_net -net soft_reset_o_rstn_core_0 [get_bd_pins core_0_rst_n/Op2] [get_bd_pins soft_reset/o_rstn_core_0]
  connect_bd_net -net soft_reset_o_rstn_core_1 [get_bd_pins core_1_rst_n/Op2] [get_bd_pins soft_reset/o_rstn_core_1]
  connect_bd_net -net soft_reset_o_rstn_core_2 [get_bd_pins core_2_rst_n/Op2] [get_bd_pins soft_reset/o_rstn_core_2]
  connect_bd_net -net soft_rst_n [get_bd_pins nic_reset/aux_reset_in] [get_bd_pins pcie/soft_rst_n] [get_bd_pins proc_sys_reset_core/aux_reset_in] [get_bd_pins soft_reset/o_resetn] [get_bd_pins sys_clk_reset/aux_reset_in]
  connect_bd_net -net util_ds_buf_0_BUFG_O [get_bd_ports ARIANE_CLK] [get_bd_pins axi_interconnect_main/S00_ACLK] [get_bd_pins axi_interconnect_main/S01_ACLK] [get_bd_pins axi_interconnect_main/S04_ACLK] [get_bd_pins axi_interconnect_main/S05_ACLK] [get_bd_pins axi_interconnect_main/S06_ACLK] [get_bd_pins axi_interconnect_main/S07_ACLK] [get_bd_pins axi_interconnect_main/S08_ACLK] [get_bd_pins axi_interconnect_mem/S06_ACLK] [get_bd_pins axi_interconnect_mem/S07_ACLK] [get_bd_pins bsv_riscv_flute/CLK] [get_bd_pins clk_buf_core/BUFG_O] [get_bd_pins proc_sys_reset_core/slowest_sync_clk]
  connect_bd_net -net util_ds_buf_0_IBUF_DS_ODIV2 [get_bd_ports PCIE_REFCLK_OUT_DIV2] [get_bd_pins pcie/pcie_refclk_out_div2]
  connect_bd_net -net util_ds_buf_0_IBUF_OUT [get_bd_ports PCIE_REFCLK_OUT] [get_bd_pins pcie/pcie_refclk_out]
  connect_bd_net -net util_reduced_logic_0_Res [get_bd_ports PCIE_INTX_MSI_REQUEST] [get_bd_pins pcie/intx_msi_req]

  # Create address segments
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000002000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs PCIE_AXI_S_CTL/Reg] SEG_PCIE_AXI_S_CTL_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000002000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs PCIE_AXI_S_CTL/Reg] SEG_PCIE_AXI_S_CTL_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000008000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs UART_AXI_S/Reg] SEG_UART_AXI_S_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000008000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs UART_AXI_S/Reg] SEG_UART_AXI_S_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x010000200000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs bram_0/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00008000 -offset 0x010000200000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs bram_0/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x010000210000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs bram_1/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem01
  create_bd_addr_seg -range 0x00010000 -offset 0x010000220000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs bram_2/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem02
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem03
  create_bd_addr_seg -range 0x00010000 -offset 0x010000210000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs bram_1/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem03
  create_bd_addr_seg -range 0x00001000 -offset 0x010000000000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs bram_hw_table/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem04
  create_bd_addr_seg -range 0x00010000 -offset 0x010000220000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs bram_2/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem04
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem05
  create_bd_addr_seg -range 0x00001000 -offset 0x010000000000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs bram_hw_table/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem06
  create_bd_addr_seg -range 0x00001000 -offset 0x010000003000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs pcie/axi_bram_ctrl_msix_table/S_AXI/Mem0] SEG_axi_bram_ctrl_msix_table_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x010000003000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs pcie/axi_bram_ctrl_msix_table/S_AXI/Mem0] SEG_axi_bram_ctrl_msix_table_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x010000009000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs axi_dma_mm2mm/axi_dma/S_AXI_LITE/Reg] SEG_axi_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000009000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs axi_dma_mm2mm/axi_dma/S_AXI_LITE/Reg] SEG_axi_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000005000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000005000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000004000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs nic_axi_dma/S_AXI_LITE/Reg] SEG_nic_axi_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000004000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs nic_axi_dma/S_AXI_LITE/Reg] SEG_nic_axi_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000001000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_IMEM] [get_bd_addr_segs soft_reset/axis_soft_reset_reg/reg] SEG_soft_reset_reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000001000 [get_bd_addr_spaces bsv_riscv_flute/M_AXI_DMEM] [get_bd_addr_segs soft_reset/axis_soft_reset_reg/reg] SEG_soft_reset_reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces nic_axi_dma/Data_MM2S] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces nic_axi_dma/Data_S2MM] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces nic_axi_dma/Data_MM2S] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces nic_axi_dma/Data_S2MM] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces nic_axi_dma/Data_MM2S] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces nic_axi_dma/Data_S2MM] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_SG] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_MM2S] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_S2MM] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_SG] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_MM2S] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_S2MM] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_SG] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_MM2S] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces axi_dma_mm2mm/axi_dma/Data_S2MM] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x000100000000 -offset 0x020000000000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs DDR_AXI_S/Reg] SEG_DDR_AXI_S_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000002000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs PCIE_AXI_S_CTL/Reg] SEG_PCIE_AXI_S_CTL_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000002000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs PCIE_AXI_S_CTL/Reg] SEG_PCIE_AXI_S_CTL_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x010000000000 -offset 0x00000000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs PCIE_AXI_S/Reg] SEG_PCIE_AXI_S_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000008000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs UART_AXI_S/Reg] SEG_UART_AXI_S_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000008000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs UART_AXI_S/Reg] SEG_UART_AXI_S_Reg
  create_bd_addr_seg -range 0x00008000 -offset 0x010000200000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs bram_0/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x010000210000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs bram_1/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x010000220000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs bram_2/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00008000 -offset 0x010000200000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs bram_0/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem0
  create_bd_addr_seg -range 0x00010000 -offset 0x010000210000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs bram_1/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem01
  create_bd_addr_seg -range 0x00010000 -offset 0x010000220000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs bram_2/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem02
  create_bd_addr_seg -range 0x00040000 -offset 0x010000100000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs bram_bootrom/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem03
  create_bd_addr_seg -range 0x00001000 -offset 0x010000000000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs bram_hw_table/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_Mem04
  create_bd_addr_seg -range 0x00001000 -offset 0x010000000000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs bram_hw_table/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_hw_info_table_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x010000003000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs pcie/axi_bram_ctrl_msix_table/S_AXI/Mem0] SEG_axi_bram_ctrl_msix_table_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x010000003000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs pcie/axi_bram_ctrl_msix_table/S_AXI/Mem0] SEG_axi_bram_ctrl_msix_table_Mem0
  create_bd_addr_seg -range 0x00001000 -offset 0x010000004000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs nic_axi_dma/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000009000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs axi_dma_mm2mm/axi_dma/S_AXI_LITE/Reg] SEG_axi_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000009000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs axi_dma_mm2mm/axi_dma/S_AXI_LITE/Reg] SEG_axi_simple_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000005000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000005000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000004000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs nic_axi_dma/S_AXI_LITE/Reg] SEG_nic_axi_dma_Reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000001000 [get_bd_addr_spaces ariane_axi] [get_bd_addr_segs soft_reset/axis_soft_reset_reg/reg] SEG_soft_reset_reg
  create_bd_addr_seg -range 0x00001000 -offset 0x010000001000 [get_bd_addr_spaces PCIE_AXI_M] [get_bd_addr_segs soft_reset/axis_soft_reset_reg/reg] SEG_soft_reset_reg1

  # Exclude Address Segments
  create_bd_addr_seg -range 0x00008000 -offset 0x010000200000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs bram_0/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_0_Mem0
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_bram_ctrl_0_Mem0]

  create_bd_addr_seg -range 0x00010000 -offset 0x010000210000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs bram_1/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_1_Mem0
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_bram_ctrl_1_Mem0]

  create_bd_addr_seg -range 0x00010000 -offset 0x010000220000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs bram_2/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_2_Mem0
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_bram_ctrl_2_Mem0]

  create_bd_addr_seg -range 0x00001000 -offset 0x010000000000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs bram_hw_table/axi_bram_ctrl/S_AXI/Mem0] SEG_axi_bram_ctrl_hw_info_table_Mem0
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_bram_ctrl_hw_info_table_Mem0]

  create_bd_addr_seg -range 0x00001000 -offset 0x010000003000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs pcie/axi_bram_ctrl_msix_table/S_AXI/Mem0] SEG_axi_bram_ctrl_msix_table_Mem0
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_bram_ctrl_msix_table_Mem0]

  create_bd_addr_seg -range 0x00001000 -offset 0x010000004000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs nic_axi_dma/S_AXI_LITE/Reg] SEG_axi_dma_0_Reg
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_dma_0_Reg]

  create_bd_addr_seg -range 0x00001000 -offset 0x010000009000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs axi_dma_mm2mm/axi_dma/S_AXI_LITE/Reg] SEG_axi_simple_dma_Reg
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_simple_dma_Reg]

  create_bd_addr_seg -range 0x00001000 -offset 0x010000005000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs axi_timer_0/S_AXI/Reg] SEG_axi_timer_0_Reg
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_axi_timer_0_Reg]

  create_bd_addr_seg -range 0x00001000 -offset 0x010000001000 [get_bd_addr_spaces nic_axi_dma/Data_SG] [get_bd_addr_segs soft_reset/axis_soft_reset_reg/reg] SEG_soft_reset_reg7
  exclude_bd_addr_seg [get_bd_addr_segs nic_axi_dma/Data_SG/SEG_soft_reset_reg7]



  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
  close_bd_design $design_name 
}
# End of cr_bd_top()