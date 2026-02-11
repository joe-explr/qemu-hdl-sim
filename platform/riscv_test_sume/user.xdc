
set_false_path -from [get_clocks SFP_CLK_P] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_pll_i] -to [get_clocks SFP_CLK_P]
#set_false_path -from [get_clocks SFP_CLK_P] -to [get_clocks clk_out1_top_clk_wiz_0_0]
#set_false_path -from [get_clocks SFP_CLK_P] -to [get_clocks clk_out1_top_clk_wiz_0_0_1]
#set_false_path -from [get_clocks SFP_CLK_P] -to [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt]

set_false_path -from [get_clocks sfp_clk_pin] -to [get_clocks clk_pll_i]
set_false_path -from [get_clocks clk_pll_i] -to [get_clocks sfp_clk_pin]
#set_false_path -from [get_clocks sfp_clk_pin] -to [get_clocks clk_out1_top_clk_wiz_0_0]
#set_false_path -from [get_clocks sfp_clk_pin] -to [get_clocks clk_out1_top_clk_wiz_0_0_1]
#set_false_path -from [get_clocks sfp_clk_pin] -to [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt]

#set_false_path -from [get_clocks userclk2] -to [get_clocks SFP_CLK_P]
#set_false_path -from [get_clocks userclk2] -to [get_clocks sfp_clk_pin]
set_false_path -from [get_clocks userclk2] -to [get_clocks clk_out1_top_clk_wiz_core_0]
#set_false_path -from [get_clocks userclk2] -to [get_clocks clk_out1_top_clk_wiz_0_0_1]

set_false_path -from [get_clocks clk_pll_i] -to [get_clocks userclk2]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0_1] -to [get_clocks userclk2]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0_1] -to [get_clocks clk_out1_top_clk_wiz_0_0]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0_1] -to [get_clocks SFP_CLK_P]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0_1] -to [get_clocks sfp_clk_pin]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0_1] -to [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt]

#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0] -to [get_clocks userclk2]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0] -to [get_clocks SFP_CLK_P]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0] -to [get_clocks sfp_clk_pin]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0] -to [get_clocks clk_out1_top_clk_wiz_0_0_1]
#set_false_path -from [get_clocks clk_out1_top_clk_wiz_0_0] -to [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt]

#set_false_path -from [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt] -to [get_clocks clk_out1_top_clk_wiz_0_0]
#set_false_path -from [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt] -to [get_clocks clk_out1_top_clk_wiz_0_0_1]
#set_false_path -from [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt] -to [get_clocks sfp_clk_pin]
#set_false_path -from [get_clocks axi_10g_ethernet_share/inst/xpcs/inst/ten_gig_eth_pcs_pma_block_i/gt0_gtwizard_10gbaser_multi_gt_i/gt0_gtwizard_gt] -to [get_clocks SFP_CLK_P]


