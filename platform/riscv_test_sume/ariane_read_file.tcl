
set_property include_dirs { \
"./ip_repo/ariane/src/axi_sd_bridge/include" \
"./ip_repo/ariane/src/common_cells/include" \
"./ip_repo/ariane/src/util"\
} [current_fileset]

set_property include_dirs { \
"./ip_repo/ariane/src/axi_sd_bridge/include" \
"./ip_repo/ariane/src/common_cells/include" \
"./ip_repo/ariane/src/util"\
} [get_filesets sim_1]

add_files -norecurse ./ip_repo/ariane/fpga/src/vc707.svh
set_property is_global_include true [get_files ./ip_repo/ariane/fpga/src/vc707.svh]

read_verilog -sv {\
./ip_repo/ariane/include/riscv_pkg.sv \
./ip_repo/ariane/src/riscv-dbg/src/dm_pkg.sv \
./ip_repo/ariane/include/ariane_pkg.sv \
./ip_repo/ariane/include/std_cache_pkg.sv \
./ip_repo/ariane/include/wt_cache_pkg.sv \
./ip_repo/ariane/src/axi/src/axi_pkg.sv \
./ip_repo/ariane/src/register_interface/src/reg_intf.sv \
./ip_repo/ariane/src/register_interface/src/reg_intf_pkg.sv \
./ip_repo/ariane/include/axi_intf.sv \
./ip_repo/ariane/tb/ariane_soc_pkg.sv \
./ip_repo/ariane/include/ariane_axi_pkg.sv \
./ip_repo/ariane/src/fpu/src/fpnew_pkg.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/defs_div_sqrt_mvp.sv\
}

read_verilog -sv {\
./ip_repo/ariane/src/tech_cells_generic/src/cluster_clock_gating.sv \
./ip_repo/ariane/tb/common/mock_uart.sv \
./ip_repo/ariane/src/util/sram.sv\
}

read_verilog -sv {\
./ip_repo/ariane/src/serdiv.sv \
./ip_repo/ariane/src/ariane_regfile_ff.sv \
./ip_repo/ariane/src/issue_stage.sv \
./ip_repo/ariane/src/branch_unit.sv \
./ip_repo/ariane/src/mmu.sv \
./ip_repo/ariane/src/controller.sv \
./ip_repo/ariane/src/re_name.sv \
./ip_repo/ariane/src/mult.sv \
./ip_repo/ariane/src/csr_buffer.sv \
./ip_repo/ariane/src/tlb.sv \
./ip_repo/ariane/src/decoder.sv \
./ip_repo/ariane/src/ex_stage.sv \
./ip_repo/ariane/src/scoreboard.sv \
./ip_repo/ariane/src/store_unit.sv \
./ip_repo/ariane/src/ariane.sv \
./ip_repo/ariane/src/axi_adapter.sv \
./ip_repo/ariane/src/fpu_wrap.sv \
./ip_repo/ariane/src/commit_stage.sv \
./ip_repo/ariane/src/load_store_unit.sv \
./ip_repo/ariane/src/ptw.sv \
./ip_repo/ariane/src/amo_buffer.sv \
./ip_repo/ariane/src/multiplier.sv \
./ip_repo/ariane/src/store_buffer.sv \
./ip_repo/ariane/src/compressed_decoder.sv \
./ip_repo/ariane/src/axi_shim.sv \
./ip_repo/ariane/src/alu.sv \
./ip_repo/ariane/src/instr_realign.sv \
./ip_repo/ariane/src/perf_counters.sv \
./ip_repo/ariane/src/id_stage.sv \
./ip_repo/ariane/src/csr_regfile.sv \
./ip_repo/ariane/src/load_unit.sv \
./ip_repo/ariane/src/issue_read_operands.sv \
./ip_repo/ariane/src/fpu/src/fpnew_fma.sv \
./ip_repo/ariane/src/fpu/src/fpnew_opgroup_fmt_slice.sv \
./ip_repo/ariane/src/fpu/src/fpnew_divsqrt_multi.sv \
./ip_repo/ariane/src/fpu/src/fpnew_fma_multi.sv \
./ip_repo/ariane/src/fpu/src/fpnew_opgroup_multifmt_slice.sv \
./ip_repo/ariane/src/fpu/src/fpnew_classifier.sv \
./ip_repo/ariane/src/fpu/src/fpnew_top.sv \
./ip_repo/ariane/src/fpu/src/fpnew_noncomp.sv \
./ip_repo/ariane/src/fpu/src/fpnew_cast_multi.sv \
./ip_repo/ariane/src/fpu/src/fpnew_opgroup_block.sv \
./ip_repo/ariane/src/fpu/src/fpnew_rounding.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/iteration_div_sqrt_mvp.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/nrbd_nrsc_mvp.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_top_mvp.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/preprocess_mvp.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/control_mvp.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/norm_div_sqrt_mvp.sv \
./ip_repo/ariane/src/fpu/src/fpu_div_sqrt_mvp/hdl/div_sqrt_mvp_wrapper.sv \
./ip_repo/ariane/src/frontend/frontend.sv \
./ip_repo/ariane/src/frontend/instr_scan.sv \
./ip_repo/ariane/src/frontend/instr_queue.sv \
./ip_repo/ariane/src/frontend/bht.sv \
./ip_repo/ariane/src/frontend/btb.sv \
./ip_repo/ariane/src/frontend/ras.sv \
./ip_repo/ariane/src/cache_subsystem/wt_dcache.sv \
./ip_repo/ariane/src/cache_subsystem/tag_cmp.sv \
./ip_repo/ariane/src/cache_subsystem/cache_ctrl.sv \
./ip_repo/ariane/src/cache_subsystem/amo_alu.sv \
./ip_repo/ariane/src/cache_subsystem/wt_axi_adapter.sv \
./ip_repo/ariane/src/cache_subsystem/std_nbdcache.sv \
./ip_repo/ariane/src/cache_subsystem/wt_dcache_ctrl.sv \
./ip_repo/ariane/src/cache_subsystem/miss_handler.sv \
./ip_repo/ariane/src/cache_subsystem/std_cache_subsystem.sv \
./ip_repo/ariane/src/cache_subsystem/wt_dcache_missunit.sv \
./ip_repo/ariane/src/cache_subsystem/std_icache.sv \
./ip_repo/ariane/src/cache_subsystem/wt_icache.sv \
./ip_repo/ariane/src/cache_subsystem/wt_dcache_wbuffer.sv \
./ip_repo/ariane/src/cache_subsystem/wt_l15_adapter.sv \
./ip_repo/ariane/src/cache_subsystem/wt_dcache_mem.sv \
./ip_repo/ariane/src/cache_subsystem/wt_cache_subsystem.sv \
./ip_repo/ariane/src/clint/axi_lite_interface.sv \
./ip_repo/ariane/src/clint/clint.sv \
./ip_repo/ariane/fpga/src/axi2apb/src/axi2apb_wrap.sv \
./ip_repo/ariane/fpga/src/axi2apb/src/axi2apb.sv \
./ip_repo/ariane/fpga/src/axi2apb/src/axi2apb_64_32.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_w_buffer.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_b_buffer.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_slice_wrap.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_slice.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_single_slice.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_ar_buffer.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_r_buffer.sv \
./ip_repo/ariane/fpga/src/axi_slice/src/axi_aw_buffer.sv \
./ip_repo/ariane/src/axi_node/src/axi_regs_top.sv \
./ip_repo/ariane/src/axi_node/src/axi_BR_allocator.sv \
./ip_repo/ariane/src/axi_node/src/axi_BW_allocator.sv \
./ip_repo/ariane/src/axi_node/src/axi_address_decoder_BR.sv \
./ip_repo/ariane/src/axi_node/src/axi_DW_allocator.sv \
./ip_repo/ariane/src/axi_node/src/axi_address_decoder_BW.sv \
./ip_repo/ariane/src/axi_node/src/axi_address_decoder_DW.sv \
./ip_repo/ariane/src/axi_node/src/axi_node_arbiter.sv \
./ip_repo/ariane/src/axi_node/src/axi_response_block.sv \
./ip_repo/ariane/src/axi_node/src/axi_request_block.sv \
./ip_repo/ariane/src/axi_node/src/axi_AR_allocator.sv \
./ip_repo/ariane/src/axi_node/src/axi_AW_allocator.sv \
./ip_repo/ariane/src/axi_node/src/axi_address_decoder_AR.sv \
./ip_repo/ariane/src/axi_node/src/axi_address_decoder_AW.sv \
./ip_repo/ariane/src/axi_node/src/apb_regs_top.sv \
./ip_repo/ariane/src/axi_node/src/axi_node_intf_wrap.sv \
./ip_repo/ariane/src/axi_node/src/axi_node.sv \
./ip_repo/ariane/src/axi_node/src/axi_node_wrap_with_slices.sv \
./ip_repo/ariane/src/axi_node/src/axi_multiplexer.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_riscv_amos.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_riscv_atomics.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_res_tbl.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_riscv_lrsc_wrap.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_riscv_amos_alu.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_riscv_lrsc.sv \
./ip_repo/ariane/src/axi_riscv_atomics/src/axi_riscv_atomics_wrap.sv \
./ip_repo/ariane/src/axi_mem_if/src/axi2mem.sv \
./ip_repo/ariane/src/rv_plic/rtl/rv_plic_target.sv \
./ip_repo/ariane/src/rv_plic/rtl/rv_plic_gateway.sv \
./ip_repo/ariane/src/rv_plic/rtl/plic_regmap.sv \
./ip_repo/ariane/src/rv_plic/rtl/plic_top.sv \
./ip_repo/ariane/src/riscv-dbg/src/dmi_cdc.sv \
./ip_repo/ariane/src/riscv-dbg/src/dmi_jtag.sv \
./ip_repo/ariane/src/riscv-dbg/src/dmi_jtag_tap.sv \
./ip_repo/ariane/src/riscv-dbg/src/dm_csrs.sv \
./ip_repo/ariane/src/riscv-dbg/src/dm_mem.sv \
./ip_repo/ariane/src/riscv-dbg/src/dm_sba.sv \
./ip_repo/ariane/src/riscv-dbg/src/dm_top.sv \
./ip_repo/ariane/src/riscv-dbg/debug_rom/debug_rom.sv \
./ip_repo/ariane/src/register_interface/src/apb_to_reg.sv \
./ip_repo/ariane/src/axi/src/axi_multicut.sv \
./ip_repo/ariane/src/common_cells/src/deprecated/generic_fifo.sv \
./ip_repo/ariane/src/common_cells/src/deprecated/pulp_sync.sv \
./ip_repo/ariane/src/common_cells/src/deprecated/find_first_one.sv \
./ip_repo/ariane/src/common_cells/src/rstgen_bypass.sv \
./ip_repo/ariane/src/common_cells/src/rstgen.sv \
./ip_repo/ariane/src/common_cells/src/stream_mux.sv \
./ip_repo/ariane/src/common_cells/src/stream_demux.sv \
./ip_repo/ariane/src/common_cells/src/exp_backoff.sv \
./ip_repo/ariane/src/util/axi_master_connect.sv \
./ip_repo/ariane/src/util/axi_slave_connect.sv \
./ip_repo/ariane/src/util/axi_master_connect_rev.sv \
./ip_repo/ariane/src/util/axi_slave_connect_rev.sv \
./ip_repo/ariane/src/axi/src/axi_cut.sv \
./ip_repo/ariane/src/axi/src/axi_join.sv \
./ip_repo/ariane/src/axi/src/axi_delayer.sv \
./ip_repo/ariane/src/axi/src/axi_to_axi_lite.sv \
./ip_repo/ariane/src/fpga-support/rtl/SyncSpRamBeNx64.sv \
./ip_repo/ariane/src/common_cells/src/unread.sv \
./ip_repo/ariane/src/common_cells/src/sync.sv \
./ip_repo/ariane/src/common_cells/src/cdc_2phase.sv \
./ip_repo/ariane/src/common_cells/src/spill_register.sv \
./ip_repo/ariane/src/common_cells/src/sync_wedge.sv \
./ip_repo/ariane/src/common_cells/src/edge_detect.sv \
./ip_repo/ariane/src/common_cells/src/stream_arbiter.sv \
./ip_repo/ariane/src/common_cells/src/stream_arbiter_flushable.sv \
./ip_repo/ariane/src/common_cells/src/deprecated/fifo_v1.sv \
./ip_repo/ariane/src/common_cells/src/deprecated/fifo_v2.sv \
./ip_repo/ariane/src/common_cells/src/fifo_v3.sv \
./ip_repo/ariane/src/common_cells/src/lzc.sv \
./ip_repo/ariane/src/common_cells/src/popcount.sv \
./ip_repo/ariane/src/common_cells/src/rr_arb_tree.sv \
./ip_repo/ariane/src/common_cells/src/deprecated/rrarbiter.sv \
./ip_repo/ariane/src/common_cells/src/stream_delay.sv \
./ip_repo/ariane/src/common_cells/src/lfsr_8bit.sv \
./ip_repo/ariane/src/common_cells/src/lfsr_16bit.sv \
./ip_repo/ariane/src/common_cells/src/counter.sv \
./ip_repo/ariane/src/common_cells/src/shift_reg.sv \
./ip_repo/ariane/src/tech_cells_generic/src/pulp_clock_gating.sv \
./ip_repo/ariane/src/tech_cells_generic/src/cluster_clock_inverter.sv \
./ip_repo/ariane/src/tech_cells_generic/src/pulp_clock_mux2.sv \
./ip_repo/ariane/tb/ariane_testharness.sv \
./ip_repo/ariane/tb/ariane_peripherals.sv \
./ip_repo/ariane/tb/common/uart.sv \
./ip_repo/ariane/tb/common/SimDTM.sv \
./ip_repo/ariane/tb/common/SimJTAG.sv\
}

read_verilog -sv {\
./ip_repo/ariane/fpga/src/ariane_peripherals_xilinx.sv \
./ip_repo/ariane/fpga/src/fan_ctrl.sv \
./ip_repo/ariane/fpga/src/ariane_xilinx.sv \
./ip_repo/ariane/fpga/src/bootrom/bootrom.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/ssio_ddr_in.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/rgmii_soc.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/eth_mac_1g_rgmii.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/axis_gmii_rx.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/oddr.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/axis_gmii_tx.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/dualmem_widen8.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/rgmii_phy_if.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/dualmem_widen.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/rgmii_lfsr.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/rgmii_core.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/eth_mac_1g.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/eth_mac_1g_rgmii_fifo.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/iddr.sv \
./ip_repo/ariane/fpga/src/ariane-ethernet/framing_top.sv\
}

read_verilog -sv {\
./ip_repo/ariane/src/util/instr_tracer.sv \
./ip_repo/ariane/src/util/instr_tracer_if.sv\
}

