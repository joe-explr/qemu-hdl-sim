`timescale 1ns / 1ps
import axi_vip_pkg::*;
import axi_vip_0_pkg::*;

module top_sim ();

reg          FPGA_SYSCLK_P;
reg          FPGA_SYSCLK_N;

reg          PCIE_CLK_N;
reg          PCIE_CLK_P;
wire [  7:0] PCIE_RX_N;
wire [  7:0] PCIE_RX_P;
wire [  7:0] PCIE_TX_N;
wire [  7:0] PCIE_TX_P;
reg          PERSTN;
reg          RESET;

wire [  0:0] FPGA_SYSCLK;
reg [  0:0]  LOCK;

wire         ARIANE_CLK;
wire         ARIANE_RST_N;

wire         SYSCLK_RSTN_PERIPHERAL;

wire [ 15:0] DDR3_addr;
wire [  2:0] DDR3_ba;
wire         DDR3_cas_n;
wire [  0:0] DDR3_ck_n;
wire [  0:0] DDR3_ck_p;
wire [  0:0] DDR3_cke;
wire [  0:0] DDR3_cs_n;
wire [  7:0] DDR3_dm;
wire [ 63:0] DDR3_dq;
wire [  7:0] DDR3_dqs_n;
wire [  7:0] DDR3_dqs_p;
wire [  0:0] DDR3_odt;
wire         DDR3_ras_n;
wire         DDR3_reset_n;
wire         DDR3_we_n;

wire [  0:0] PCIE_REFCLK_OUT;
wire [  0:0] PCIE_REFCLK_OUT_DIV2;
wire         PCIE_ACLK_IN;
wire         PCIE_ARESETN_IN;
wire         PCIE_INTX_MSI_GRANT;
wire         PCIE_INTX_MSI_REQUEST;
wire         PCIE_MSI_ENABLE;
wire [  4:0] PCIE_MSI_VECTOR_NUM;
wire [  2:0] PCIE_MSI_VECTOR_WIDTH;
wire [	5:0] MSIX_IRQ;
wire         MSIX_TABLE_BRAM_PORTB_clk;
wire         MSIX_TABLE_BRAM_PORTB_rst;
wire [ 31:0] MSIX_TABLE_BRAM_PORTB_addr;
wire [ 31:0] MSIX_TABLE_BRAM_PORTB_din;
wire [ 31:0] MSIX_TABLE_BRAM_PORTB_dout;
wire         MSIX_TABLE_BRAM_PORTB_en;
wire [  3:0] MSIX_TABLE_BRAM_PORTB_we;

wire [ 63:0] msix_ctrl_address;
wire [ 31:0] msix_ctrl_data;
wire [  3:0] msix_ctrl_enable;
wire         msix_ctrl_fail;
wire         msix_ctrl_int_vector;
wire [  3:0] msix_ctrl_mask;
wire         msix_ctrl_sent;
wire [  7:0] msix_ctrl_vf_enable;
wire [  7:0] msix_ctrl_vf_mask;

wire [ 31:0] PCIE_AXI_M_arid;
wire [ 31:0] PCIE_AXI_M_rid;
wire [ 31:0] PCIE_AXI_M_awid;
wire [ 31:0] PCIE_AXI_M_bid;
wire [ 63:0] PCIE_AXI_M_araddr;
wire [  1:0] PCIE_AXI_M_arburst;
wire [  3:0] PCIE_AXI_M_arcache;
wire [  7:0] PCIE_AXI_M_arlen;
wire [  0:0] PCIE_AXI_M_arlock;
wire [  2:0] PCIE_AXI_M_arprot;
wire [  3:0] PCIE_AXI_M_arqos;
wire         PCIE_AXI_M_arready;
wire [  3:0] PCIE_AXI_M_arregion;
wire [  2:0] PCIE_AXI_M_arsize;
wire         PCIE_AXI_M_arvalid;
wire [ 63:0] PCIE_AXI_M_awaddr;
wire [  1:0] PCIE_AXI_M_awburst;
wire [  3:0] PCIE_AXI_M_awcache;
wire [  7:0] PCIE_AXI_M_awlen;
wire [  0:0] PCIE_AXI_M_awlock;
wire [  2:0] PCIE_AXI_M_awprot;
wire [  3:0] PCIE_AXI_M_awqos;
wire         PCIE_AXI_M_awready;
wire [  3:0] PCIE_AXI_M_awregion;
wire [  2:0] PCIE_AXI_M_awsize;
wire         PCIE_AXI_M_awvalid;
wire         PCIE_AXI_M_bready;
wire [  1:0] PCIE_AXI_M_bresp;
wire         PCIE_AXI_M_bvalid;
wire [255:0] PCIE_AXI_M_rdata;
wire         PCIE_AXI_M_rlast;
wire         PCIE_AXI_M_rready;
wire [  1:0] PCIE_AXI_M_rresp;
wire         PCIE_AXI_M_rvalid;
wire [255:0] PCIE_AXI_M_wdata;
wire         PCIE_AXI_M_wlast;
wire         PCIE_AXI_M_wready;
wire [ 31:0] PCIE_AXI_M_wstrb;
wire         PCIE_AXI_M_wvalid;

wire [ 63:0] PCIE_AXI_S_CTL_araddr;
wire [  1:0] PCIE_AXI_S_CTL_arburst;
wire [  3:0] PCIE_AXI_S_CTL_arcache;
wire [ 20:0] PCIE_AXI_S_CTL_arid;
wire [  7:0] PCIE_AXI_S_CTL_arlen;
wire [  0:0] PCIE_AXI_S_CTL_arlock;
wire [  2:0] PCIE_AXI_S_CTL_arprot;
wire [  3:0] PCIE_AXI_S_CTL_arqos;
wire         PCIE_AXI_S_CTL_arready;
wire [  3:0] PCIE_AXI_S_CTL_arregion;
wire [  2:0] PCIE_AXI_S_CTL_arsize;
wire         PCIE_AXI_S_CTL_arvalid;
wire [ 63:0] PCIE_AXI_S_CTL_awaddr;
wire [  1:0] PCIE_AXI_S_CTL_awburst;
wire [  3:0] PCIE_AXI_S_CTL_awcache;
wire [ 20:0] PCIE_AXI_S_CTL_awid;
wire [  7:0] PCIE_AXI_S_CTL_awlen;
wire [  0:0] PCIE_AXI_S_CTL_awlock;
wire [  2:0] PCIE_AXI_S_CTL_awprot;
wire [  3:0] PCIE_AXI_S_CTL_awqos;
wire         PCIE_AXI_S_CTL_awready;
wire [  3:0] PCIE_AXI_S_CTL_awregion;
wire [  2:0] PCIE_AXI_S_CTL_awsize;
wire         PCIE_AXI_S_CTL_awvalid;
wire [ 20:0] PCIE_AXI_S_CTL_bid;
wire         PCIE_AXI_S_CTL_bready;
wire [  1:0] PCIE_AXI_S_CTL_bresp;
wire         PCIE_AXI_S_CTL_bvalid;
wire [ 31:0] PCIE_AXI_S_CTL_rdata;
wire [ 20:0] PCIE_AXI_S_CTL_rid;
wire         PCIE_AXI_S_CTL_rlast;
wire         PCIE_AXI_S_CTL_rready;
wire [  1:0] PCIE_AXI_S_CTL_rresp;
wire         PCIE_AXI_S_CTL_rvalid;
wire [ 31:0] PCIE_AXI_S_CTL_wdata;
wire         PCIE_AXI_S_CTL_wlast;
wire         PCIE_AXI_S_CTL_wready;
wire [  3:0] PCIE_AXI_S_CTL_wstrb;
wire         PCIE_AXI_S_CTL_wvalid;

wire [ 31:0] PCIE_AXI_S_arid = 0;
wire [ 31:0] PCIE_AXI_S_rid;
wire [ 31:0] PCIE_AXI_S_awid = 0;
wire [ 31:0] PCIE_AXI_S_bid;
wire [ 63:0] PCIE_AXI_S_araddr;
wire [  1:0] PCIE_AXI_S_arburst;
wire [  3:0] PCIE_AXI_S_arcache;
wire [  7:0] PCIE_AXI_S_arlen;
wire [  0:0] PCIE_AXI_S_arlock;
wire [  2:0] PCIE_AXI_S_arprot;
wire [  3:0] PCIE_AXI_S_arqos;
wire         PCIE_AXI_S_arready;
wire [  3:0] PCIE_AXI_S_arregion;
wire [  2:0] PCIE_AXI_S_arsize;
wire         PCIE_AXI_S_arvalid;
wire [ 63:0] PCIE_AXI_S_awaddr;
wire [  1:0] PCIE_AXI_S_awburst;
wire [  3:0] PCIE_AXI_S_awcache;
wire [  7:0] PCIE_AXI_S_awlen;
wire [  0:0] PCIE_AXI_S_awlock;
wire [  2:0] PCIE_AXI_S_awprot;
wire [  3:0] PCIE_AXI_S_awqos;
wire         PCIE_AXI_S_awready;
wire [  3:0] PCIE_AXI_S_awregion;
wire [  2:0] PCIE_AXI_S_awsize;
wire         PCIE_AXI_S_awvalid;
wire         PCIE_AXI_S_bready;
wire [  1:0] PCIE_AXI_S_bresp;
wire         PCIE_AXI_S_bvalid;
wire [255:0] PCIE_AXI_S_rdata;
wire         PCIE_AXI_S_rlast;
wire         PCIE_AXI_S_rready;
wire [  1:0] PCIE_AXI_S_rresp;
wire         PCIE_AXI_S_rvalid;
wire [255:0] PCIE_AXI_S_wdata;
wire         PCIE_AXI_S_wlast;
wire         PCIE_AXI_S_wready;
wire [ 31:0] PCIE_AXI_S_wstrb;
wire         PCIE_AXI_S_wvalid;

wire [ 63:0] DDR_AXI_S_araddr;
wire [  1:0] DDR_AXI_S_arburst;
wire [  3:0] DDR_AXI_S_arcache;
wire [  2:0] DDR_AXI_S_arid;
wire [  7:0] DDR_AXI_S_arlen;
wire [  0:0] DDR_AXI_S_arlock;
wire [  2:0] DDR_AXI_S_arprot;
wire [  3:0] DDR_AXI_S_arqos;
wire         DDR_AXI_S_arready;
wire [  3:0] DDR_AXI_S_arregion;
wire [  2:0] DDR_AXI_S_arsize;
wire         DDR_AXI_S_arvalid;
wire [ 63:0] DDR_AXI_S_awaddr;
wire [  1:0] DDR_AXI_S_awburst;
wire [  3:0] DDR_AXI_S_awcache;
wire [  2:0] DDR_AXI_S_awid;
wire [  7:0] DDR_AXI_S_awlen;
wire [  0:0] DDR_AXI_S_awlock;
wire [  2:0] DDR_AXI_S_awprot;
wire [  3:0] DDR_AXI_S_awqos;
wire         DDR_AXI_S_awready;
wire [  3:0] DDR_AXI_S_awregion;
wire [  2:0] DDR_AXI_S_awsize;
wire         DDR_AXI_S_awvalid;
wire [  2:0] DDR_AXI_S_bid;
wire         DDR_AXI_S_bready;
wire [  1:0] DDR_AXI_S_bresp;
wire         DDR_AXI_S_bvalid;
wire [511:0] DDR_AXI_S_rdata;
wire [  2:0] DDR_AXI_S_rid;
wire         DDR_AXI_S_rlast;
wire         DDR_AXI_S_rready;
wire [  1:0] DDR_AXI_S_rresp;
wire         DDR_AXI_S_rvalid;
wire [511:0] DDR_AXI_S_wdata;
wire         DDR_AXI_S_wlast;
wire         DDR_AXI_S_wready;
wire [ 63:0] DDR_AXI_S_wstrb;
wire         DDR_AXI_S_wvalid;

wire         UART_ACLK_OUT;
wire         UART_ARESETN_OUT;
wire         UART_RXD;
wire         UART_TXD;
wire [ 31:0] UART_AXI_S_araddr;
wire [  1:0] UART_AXI_S_arburst;
wire [  3:0] UART_AXI_S_arcache;
wire [  2:0] UART_AXI_S_arid;
wire [  7:0] UART_AXI_S_arlen;
wire [  0:0] UART_AXI_S_arlock;
wire [  2:0] UART_AXI_S_arprot;
wire [  3:0] UART_AXI_S_arqos;
wire [  0:0] UART_AXI_S_arready;
wire [  3:0] UART_AXI_S_arregion;
wire [  2:0] UART_AXI_S_arsize;
wire [  0:0] UART_AXI_S_arvalid;
wire [ 31:0] UART_AXI_S_awaddr;
wire [  1:0] UART_AXI_S_awburst;
wire [  3:0] UART_AXI_S_awcache;
wire [  2:0] UART_AXI_S_awid;
wire [  7:0] UART_AXI_S_awlen;
wire [  0:0] UART_AXI_S_awlock;
wire [  2:0] UART_AXI_S_awprot;
wire [  3:0] UART_AXI_S_awqos;
wire [  0:0] UART_AXI_S_awready;
wire [  3:0] UART_AXI_S_awregion;
wire [  2:0] UART_AXI_S_awsize;
wire [  0:0] UART_AXI_S_awvalid;
wire [  2:0] UART_AXI_S_bid;
wire [  0:0] UART_AXI_S_bready;
wire [  1:0] UART_AXI_S_bresp;
wire [  0:0] UART_AXI_S_bvalid;
wire [ 31:0] UART_AXI_S_rdata;
wire [  2:0] UART_AXI_S_rid;
wire [  0:0] UART_AXI_S_rlast;
wire [  0:0] UART_AXI_S_rready;
wire [  1:0] UART_AXI_S_rresp;
wire [  0:0] UART_AXI_S_rvalid;
wire [ 31:0] UART_AXI_S_wdata;
wire [  0:0] UART_AXI_S_wlast;
wire [  0:0] UART_AXI_S_wready;
wire [  3:0] UART_AXI_S_wstrb;
wire [  0:0] UART_AXI_S_wvalid;

logic        NIC_0_ACLK;
logic        NIC_0_ARESET;
wire         NIC_0_ARESETN = ~NIC_0_ARESET;
wire         NIC_0_RESETDONE = 1;
wire         ETH1_MOD_DETECT = 1;
wire         NIC_0_SIGNAL_DETECT = ~ETH1_MOD_DETECT;
logic        ETH1_TX_LED = NIC_0_RESETDONE;
logic        ETH1_RX_LED = NIC_0_RESETDONE;
wire [ 63:0] axi_dma_nic_0_M_AXIS_MM2S_tdata;
wire [  7:0] axi_dma_nic_0_M_AXIS_MM2S_tkeep;
wire         axi_dma_nic_0_M_AXIS_MM2S_tlast;
wire         axi_dma_nic_0_M_AXIS_MM2S_tready;
wire         axi_dma_nic_0_M_AXIS_MM2S_tvalid;
wire [ 63:0] axi_dma_nic_0_S_AXIS_S2MM_tdata;
wire [  7:0] axi_dma_nic_0_S_AXIS_S2MM_tkeep;
wire         axi_dma_nic_0_S_AXIS_S2MM_tlast;
wire         axi_dma_nic_0_S_AXIS_S2MM_tready;
wire         axi_dma_nic_0_S_AXIS_S2MM_tvalid;

logic          ariane_axi_awvalid;
logic [ 3 : 0] ariane_axi_awid;
logic [63 : 0] ariane_axi_awaddr;
logic [ 7 : 0] ariane_axi_awlen;
logic [ 2 : 0] ariane_axi_awsize;
logic [ 1 : 0] ariane_axi_awburst;
logic          ariane_axi_awlock;
logic [ 3 : 0] ariane_axi_awcache;
logic [ 2 : 0] ariane_axi_awprot;
logic [ 3 : 0] ariane_axi_awqos;
logic [ 3 : 0] ariane_axi_awregion;
logic          ariane_axi_awready;
logic          ariane_axi_wvalid;
logic [ 3 : 0] ariane_axi_wid;
logic [63 : 0] ariane_axi_wdata;
logic [ 7 : 0] ariane_axi_wstrb;
logic          ariane_axi_wlast;
logic          ariane_axi_wready;
logic          ariane_axi_bvalid;
logic [ 3 : 0] ariane_axi_bid;
logic [ 1 : 0] ariane_axi_bresp;
logic          ariane_axi_bready;
logic          ariane_axi_arvalid;
logic [ 3 : 0] ariane_axi_arid;
logic [63 : 0] ariane_axi_araddr;
logic [ 7 : 0] ariane_axi_arlen;
logic [ 2 : 0] ariane_axi_arsize;
logic [ 1 : 0] ariane_axi_arburst;
logic          ariane_axi_arlock;
logic [ 3 : 0] ariane_axi_arcache;
logic [ 2 : 0] ariane_axi_arprot;
logic [ 3 : 0] ariane_axi_arqos;
logic [ 3 : 0] ariane_axi_arregion;
logic          ariane_axi_arready;
logic          ariane_axi_rvalid;
logic [ 3 : 0] ariane_axi_rid;
logic [63 : 0] ariane_axi_rdata;
logic [ 1 : 0] ariane_axi_rresp;
logic          ariane_axi_rlast;
logic          ariane_axi_rready;

top_wrapper DUT (
    .PCIE_AXI_M_arqos   (0)
,   .PCIE_AXI_M_awqos   (0)
//,   .PCIE_AXI_S_CTL_awid    (PCIE_AXI_S_CTL_awid    )
//,   .PCIE_AXI_S_CTL_arid    (PCIE_AXI_S_CTL_arid    )
//,   .PCIE_AXI_S_CTL_bid     (PCIE_AXI_S_CTL_bid     )
//,   .PCIE_AXI_S_CTL_rid     (PCIE_AXI_S_CTL_rid     )
,   .PCIE_AXI_S_CTL_araddr    (PCIE_AXI_S_CTL_araddr     )
,   .PCIE_AXI_S_CTL_awaddr    (PCIE_AXI_S_CTL_awaddr     )
,   .PCIE_AXI_M_araddr  (PCIE_AXI_M_araddr  )
,   .PCIE_AXI_M_awaddr  (PCIE_AXI_M_awaddr  )
,   .PCIE_AXI_M_awid    (PCIE_AXI_M_awid    )
,   .PCIE_AXI_M_arid    (PCIE_AXI_M_arid    )
,   .PCIE_AXI_M_bid     (PCIE_AXI_M_bid     )
,   .PCIE_AXI_M_rid     (PCIE_AXI_M_rid     )
,   .UART_AXI_S_araddr  (UART_AXI_S_araddr  )
,   .UART_AXI_S_awaddr  (UART_AXI_S_awaddr  )
,   .*
);

QEMUPCIeBridge_0 QEMUPCIeBridge_0_1
(
    .i_refclk           (PCIE_REFCLK_OUT        )
,   .o_axi_aclk         (PCIE_ACLK_IN           )
,   .o_axi_aresetn      (PCIE_ARESETN_IN        )
,   .i_axi_ctl_aclk     (PCIE_ACLK_IN           )
,   .i_sys_rst_n        (PERSTN                 )

,   .o_m_arid           (PCIE_AXI_M_arid        )
,   .o_m_araddr         (PCIE_AXI_M_araddr      )
,   .o_m_arlen          (PCIE_AXI_M_arlen       )
,   .o_m_arsize         (PCIE_AXI_M_arsize      )
,   .o_m_arburst        (PCIE_AXI_M_arburst     )
,   .o_m_arlock         (PCIE_AXI_M_arlock      )
,   .o_m_arcache        (PCIE_AXI_M_arcache     )
,   .o_m_arprot         (PCIE_AXI_M_arprot      )
,   .o_m_arregion       (PCIE_AXI_M_arregion    )
,   .o_m_arvalid        (PCIE_AXI_M_arvalid     )
,   .i_m_arready        (PCIE_AXI_M_arready     )
,   .i_m_rid            (PCIE_AXI_M_rid         )
,   .i_m_rdata          (PCIE_AXI_M_rdata       )
,   .i_m_rresp          (PCIE_AXI_M_rresp       )
,   .i_m_rlast          (PCIE_AXI_M_rlast       )
,   .i_m_rvalid         (PCIE_AXI_M_rvalid      )
,   .o_m_rready         (PCIE_AXI_M_rready      )
,   .o_m_awid           (PCIE_AXI_M_awid        )
,   .o_m_awaddr         (PCIE_AXI_M_awaddr      )
,   .o_m_awlen          (PCIE_AXI_M_awlen       )
,   .o_m_awsize         (PCIE_AXI_M_awsize      )
,   .o_m_awburst        (PCIE_AXI_M_awburst     )
,   .o_m_awlock         (PCIE_AXI_M_awlock      )
,   .o_m_awcache        (PCIE_AXI_M_awcache     )
,   .o_m_awprot         (PCIE_AXI_M_awprot      )
,   .o_m_awregion       (PCIE_AXI_M_awregion    )
,   .o_m_awvalid        (PCIE_AXI_M_awvalid     )
,   .i_m_awready        (PCIE_AXI_M_awready     )
,   .o_m_wid            (PCIE_AXI_M_wid         )
,   .o_m_wdata          (PCIE_AXI_M_wdata       )
,   .o_m_wlast          (PCIE_AXI_M_wlast       )
,   .o_m_wstrb          (PCIE_AXI_M_wstrb       )
,   .o_m_wvalid         (PCIE_AXI_M_wvalid      )
,   .i_m_wready         (PCIE_AXI_M_wready      )
,   .i_m_bid            (PCIE_AXI_M_bid         )
,   .i_m_bresp          (PCIE_AXI_M_bresp       )
,   .i_m_bvalid         (PCIE_AXI_M_bvalid      )
,   .o_m_bready         (PCIE_AXI_M_bready      )

,   .i_s_arid           (PCIE_AXI_S_arid        )
,   .i_s_araddr         (PCIE_AXI_S_araddr      )
,   .i_s_arlen          (PCIE_AXI_S_arlen       )
,   .i_s_arsize         (PCIE_AXI_S_arsize      )
,   .i_s_arburst        (PCIE_AXI_S_arburst     )  
,   .i_s_arlock         (PCIE_AXI_S_arlock      )
,   .i_s_arcache        (PCIE_AXI_S_arcache     )
,   .i_s_arprot         (PCIE_AXI_S_arprot      )
,   .i_s_arregion       (PCIE_AXI_S_arregion    )
,   .i_s_arvalid        (PCIE_AXI_S_arvalid     )
,   .o_s_arready        (PCIE_AXI_S_arready     )
,   .o_s_rid            (PCIE_AXI_S_rid         )
,   .o_s_rdata          (PCIE_AXI_S_rdata       )
,   .o_s_rresp          (PCIE_AXI_S_rresp       )
,   .o_s_rlast          (PCIE_AXI_S_rlast       )
,   .o_s_rvalid         (PCIE_AXI_S_rvalid      )
,   .i_s_rready         (PCIE_AXI_S_rready      )
,   .i_s_awid           (PCIE_AXI_S_awid        )
,   .i_s_awaddr         (PCIE_AXI_S_awaddr      )
,   .i_s_awlen          (PCIE_AXI_S_awlen       )
,   .i_s_awsize         (PCIE_AXI_S_awsize      )
,   .i_s_awburst        (PCIE_AXI_S_awburst     )
,   .i_s_awlock         (PCIE_AXI_S_awlock      )
,   .i_s_awcache        (PCIE_AXI_S_awcache     )
,   .i_s_awprot         (PCIE_AXI_S_awprot      )
,   .i_s_awregion       (PCIE_AXI_S_awregion    )
,   .i_s_awvalid        (PCIE_AXI_S_awvalid     )
,   .o_s_awready        (PCIE_AXI_S_awready     )
,   .i_s_wid            (PCIE_AXI_S_wid         )
,   .i_s_wdata          (PCIE_AXI_S_wdata       )
,   .i_s_wlast          (PCIE_AXI_S_wlast       )
,   .i_s_wstrb          (PCIE_AXI_S_wstrb       )
,   .i_s_wvalid         (PCIE_AXI_S_wvalid      )
,   .o_s_wready         (PCIE_AXI_S_wready      )
,   .o_s_bid            (PCIE_AXI_S_bid         )
,   .o_s_bresp          (PCIE_AXI_S_bresp       )
,   .o_s_bvalid         (PCIE_AXI_S_bvalid      )
,   .i_s_bready         (PCIE_AXI_S_bready      )

,   .i_s_ctl_araddr     (PCIE_AXI_S_CTL_araddr  )
,   .i_s_ctl_arvalid    (PCIE_AXI_S_CTL_arvalid )
,   .o_s_ctl_arready    (PCIE_AXI_S_CTL_arready )
,   .o_s_ctl_rdata      (PCIE_AXI_S_CTL_rdata   )
,   .o_s_ctl_rresp      (PCIE_AXI_S_CTL_rresp   )
,   .o_s_ctl_rvalid     (PCIE_AXI_S_CTL_rvalid  )
,   .i_s_ctl_rready     (PCIE_AXI_S_CTL_rready  )
,   .i_s_ctl_awaddr     (PCIE_AXI_S_CTL_awaddr  )
,   .i_s_ctl_awvalid    (PCIE_AXI_S_CTL_awvalid )
,   .o_s_ctl_awready    (PCIE_AXI_S_CTL_awready )
,   .i_s_ctl_wdata      (PCIE_AXI_S_CTL_wdata   )
,   .i_s_ctl_wstrb      (PCIE_AXI_S_CTL_wstrb   )
,   .i_s_ctl_wvalid     (PCIE_AXI_S_CTL_wvalid  )
,   .o_s_ctl_wready     (PCIE_AXI_S_CTL_wready  )
,   .o_s_ctl_bresp      (PCIE_AXI_S_CTL_bresp   )
,   .o_s_ctl_bvalid     (PCIE_AXI_S_CTL_bvalid  )
,   .i_s_ctl_bready     (PCIE_AXI_S_CTL_bready  )

,   .pci_exp_rxn        (PCIE_RX_N              )
,   .pci_exp_rxp        (PCIE_RX_P              )
,   .pci_exp_txn        (PCIE_TX_N              )
,   .pci_exp_txp        (PCIE_TX_P              )

,   .interrupt_out      (                       )
,   .intx_msi_request   (0/*PCIE_INTX_MSI_REQUEST*/)
,   .intx_msi_grant     (PCIE_INTX_MSI_GRANT    )

,   .cfg_interrupt_msix_address     (msix_ctrl_address      )
,   .cfg_interrupt_msix_data        (msix_ctrl_data         )
,   .cfg_interrupt_msix_enable      (msix_ctrl_enable       )
,   .cfg_interrupt_msix_fail        (msix_ctrl_fail         )
,   .cfg_interrupt_msix_int         (msix_ctrl_int_vector   )
,   .cfg_interrupt_msix_mask        (msix_ctrl_mask         )
,   .cfg_interrupt_msix_sent        (msix_ctrl_sent         )
,   .cfg_interrupt_msix_vf_enable   (msix_ctrl_vf_enable    )
,   .cfg_interrupt_msix_vf_mask     (msix_ctrl_vf_mask      )
);

MsixController_sim MsixController_inst (
    .clk                (PCIE_ACLK_IN               )
,   .resetn             (PCIE_ARESETN_IN            )
,   .msixAddress        (msix_ctrl_address          )
,   .msixData           (msix_ctrl_data             )
,   .msixEnable         (msix_ctrl_enable           )
,   .msixFail           (msix_ctrl_fail             )
,   .msixInt            (msix_ctrl_int_vector       )
,   .msixMask           (msix_ctrl_mask             )
,   .msixSent           (msix_ctrl_sent             )
,   .msixVfEnable       (msix_ctrl_vf_enable        )
,   .msixVfMask         (msix_ctrl_vf_mask          )
,   .tableclk           (MSIX_TABLE_BRAM_PORTB_clk  )
,   .tablerst           (MSIX_TABLE_BRAM_PORTB_rst  )
,   .tableAddr          (MSIX_TABLE_BRAM_PORTB_addr )
,   .tableDin           (MSIX_TABLE_BRAM_PORTB_din  )
,   .tableDout          (MSIX_TABLE_BRAM_PORTB_dout )
,   .tableEn            (MSIX_TABLE_BRAM_PORTB_en   )
,   .tableWe            (MSIX_TABLE_BRAM_PORTB_we   )
,   .inputIntrs         (MSIX_IRQ                   )
);

uart_sim_0 axi_uartlite_0_inst
(
    .i_clk                  (PCIE_ACLK_IN           )
,   .i_rst_n                (UART_ARESETN_OUT       )
,   .i_s_awaddr             (UART_AXI_S_awaddr      )
,   .i_s_awvalid            (UART_AXI_S_awvalid     )
,   .o_s_awready            (UART_AXI_S_awready     )
,   .i_s_wdata              (UART_AXI_S_wdata       )
,   .i_s_wstrb              (UART_AXI_S_wstrb       )
,   .i_s_wvalid             (UART_AXI_S_wvalid      )
,   .o_s_wready             (UART_AXI_S_wready      )
,   .o_s_bresp              (UART_AXI_S_bresp       )
,   .o_s_bvalid             (UART_AXI_S_bvalid      )
,   .i_s_bready             (UART_AXI_S_bready      )
,   .i_s_araddr             (UART_AXI_S_araddr      )
,   .i_s_arvalid            (UART_AXI_S_arvalid     )
,   .o_s_arready            (UART_AXI_S_arready     )
,   .o_s_rdata              (UART_AXI_S_rdata       )
,   .o_s_rresp              (UART_AXI_S_rresp       )
,   .o_s_rvalid             (UART_AXI_S_rvalid      )
,   .i_s_rready             (UART_AXI_S_rready      )
//, .interrupt              (                       )
//, .rx                     (UART_RXD_OUT           )
//, .tx                     (UART_TXD_IN            )
);

NICSimBridge_0
NICSimBridge_inst
( 
    .refclk_p               (NIC_0_ACLK                         )
,   .tx_axis_aresetn        (NIC_0_ARESETN                      )

,   .s_axis_tx_tdata        (axi_dma_nic_0_M_AXIS_MM2S_tdata    )
,   .s_axis_tx_tkeep        (axi_dma_nic_0_M_AXIS_MM2S_tkeep    )
,   .s_axis_tx_tlast        (axi_dma_nic_0_M_AXIS_MM2S_tlast    )
,   .s_axis_tx_tuser        ()
,   .s_axis_tx_tvalid       (axi_dma_nic_0_M_AXIS_MM2S_tvalid   )
,   .s_axis_tx_tready       (axi_dma_nic_0_M_AXIS_MM2S_tready   )

,   .m_axis_rx_tdata        (axi_dma_nic_0_S_AXIS_S2MM_tdata    )
,   .m_axis_rx_tkeep        (axi_dma_nic_0_S_AXIS_S2MM_tkeep    )
,   .m_axis_rx_tlast        (axi_dma_nic_0_S_AXIS_S2MM_tlast    )
,   .m_axis_rx_tuser        ()
,   .m_axis_rx_tvalid       (axi_dma_nic_0_S_AXIS_S2MM_tvalid   )
,   .m_axis_rx_tready       (axi_dma_nic_0_S_AXIS_S2MM_tready   )
);

axi_vip_0
DDRSim_inst
(
    .aclk               (FPGA_SYSCLK           )   // output wire axi_aclk
,   .aresetn            (SYSCLK_RSTN_PERIPHERAL)   // output wire axi_aresetn
,   .s_axi_araddr       (DDR_AXI_S_araddr      )   // input wire [63 : 0] s_axi_araddr
,   .s_axi_arlen        (DDR_AXI_S_arlen       )   // input wire [7 : 0] s_axi_arlen
,   .s_axi_arsize       (DDR_AXI_S_arsize      )   // input wire [2 : 0] s_axi_arsize
,   .s_axi_arburst      (DDR_AXI_S_arburst     )   // input wire [1 : 0] s_axi_arburst
//,   .s_axi_arregion     (DDR_AXI_S_arregion    )   // input wire [3 : 0] s_axi_arregion
,   .s_axi_arvalid      (DDR_AXI_S_arvalid     )   // input wire s_axi_arvalid
,   .s_axi_arready      (DDR_AXI_S_arready     )   // output wire s_axi_arready
,   .s_axi_rdata        (DDR_AXI_S_rdata       )   // output wire [255 : 0] s_axi_rdata
,   .s_axi_rresp        (DDR_AXI_S_rresp       )   // output wire [1 : 0] s_axi_rresp
,   .s_axi_rlast        (DDR_AXI_S_rlast       )   // output wire s_axi_rlast
,   .s_axi_rvalid       (DDR_AXI_S_rvalid      )   // output wire s_axi_rvalid
,   .s_axi_rready       (DDR_AXI_S_rready      )   // input wire s_axi_rready
,   .s_axi_awaddr       (DDR_AXI_S_awaddr      )   // input wire [63 : 0] s_axi_awaddr
,   .s_axi_awlen        (DDR_AXI_S_awlen       )   // input wire [7 : 0] s_axi_awlen
,   .s_axi_awsize       (DDR_AXI_S_awsize      )   // input wire [2 : 0] s_axi_awsize
,   .s_axi_awburst      (DDR_AXI_S_awburst     )   // input wire [1 : 0] s_axi_awburst
//,   .s_axi_awregion     (DDR_AXI_S_awregion    )   // input wire [3 : 0] s_axi_awregion
,   .s_axi_awvalid      (DDR_AXI_S_awvalid     )   // input wire s_axi_awvalid
,   .s_axi_awready      (DDR_AXI_S_awready     )   // output wire s_axi_awready
,   .s_axi_wdata        (DDR_AXI_S_wdata       )   // input wire [255 : 0] s_axi_wdata
,   .s_axi_wlast        (DDR_AXI_S_wlast       )   // input wire s_axi_wlast
,   .s_axi_wstrb        (DDR_AXI_S_wstrb       )   // input wire [31 : 0] s_axi_wstrb
,   .s_axi_wvalid       (DDR_AXI_S_wvalid      )   // input wire s_axi_wvalid
,   .s_axi_wready       (DDR_AXI_S_wready      )   // output wire s_axi_wready
,   .s_axi_bresp        (DDR_AXI_S_bresp       )   // output wire [1 : 0] s_axi_bresp
,   .s_axi_bvalid       (DDR_AXI_S_bvalid      )   // output wire s_axi_bvalid
,   .s_axi_bready       (DDR_AXI_S_bready      )   // input wire s_axi_bready

,   .s_axi_arid         (DDR_AXI_S_arid        )
,   .s_axi_awid         (DDR_AXI_S_awid        )
,   .s_axi_rid          (DDR_AXI_S_rid         )
,   .s_axi_bid          (DDR_AXI_S_bid         )
);

	//Set up VIP modules
    axi_vip_0_slv_mem_t slv_mem_agent0;

	axi_ready_gen	wready_gen0;

	initial begin
		bit [511:0] mem_fill_payload;
		bit [511:0] memdata;

		mem_fill_payload = 512'hdeadbeef;

		slv_mem_agent0 = new("slave vip mem agent", top_sim.DDRSim_inst.inst.IF);

		slv_mem_agent0.set_agent_tag("Slave VIP0");

		slv_mem_agent0.set_verbosity(0);

		slv_mem_agent0.start_slave();

		slv_mem_agent0.mem_model.set_memory_fill_policy(XIL_AXI_MEMORY_FILL_FIXED);
		slv_mem_agent0.mem_model.set_default_memory_value(mem_fill_payload);


		wready_gen0 = slv_mem_agent0.wr_driver.create_ready("wready");
		wready_gen0.set_ready_policy(XIL_AXI_READY_GEN_EVENTS);
		wready_gen0.set_low_time(1);
		wready_gen0.set_event_count(4);
		slv_mem_agent0.wr_driver.send_wready(wready_gen0);

		slv_mem_agent0.rd_driver.set_forward_progress_timeout_value(500000);
	end

// ---------------
// Ariane
// ---------------

localparam  HART_ID = 64'b0;
//localparam  BOOT_ADDR = ariane_soc::ROMBase;
localparam  BOOT_ADDR = 64'h0000010000100000;

ariane_axi::req_t    axi_req     ;
ariane_axi::resp_t   axi_rsp     ;


assign  ariane_axi_awvalid      = axi_req.aw_valid      ;
assign  ariane_axi_awid         = axi_req.aw.id         ;
assign  ariane_axi_awaddr       = axi_req.aw.addr       ;
assign  ariane_axi_awlen        = axi_req.aw.len        ;
assign  ariane_axi_awsize       = axi_req.aw.size       ;
assign  ariane_axi_awburst      = axi_req.aw.burst      ;
assign  ariane_axi_awlock       = axi_req.aw.lock       ;
assign  ariane_axi_awcache      = axi_req.aw.cache      ;
assign  ariane_axi_awprot       = axi_req.aw.prot       ;
assign  ariane_axi_awqos        = axi_req.aw.qos        ;
assign  ariane_axi_awregion     = axi_req.aw.region     ;
//assign                        = axi_req.aw.atop       ;
assign  axi_rsp.aw_ready        = ariane_axi_awready    ;

assign  ariane_axi_wvalid       = axi_req.w_valid       ;
assign  ariane_axi_wdata        = axi_req.w.data        ;
assign  ariane_axi_wstrb        = axi_req.w.strb        ;
assign  ariane_axi_wlast        = axi_req.w.last        ;
assign  axi_rsp.w_ready         = ariane_axi_wready     ;

assign  axi_rsp.b_valid         = ariane_axi_bvalid     ;
assign  axi_rsp.b.id            = ariane_axi_bid        ;
assign  axi_rsp.b.resp          = ariane_axi_bresp      ;
assign  ariane_axi_bready       = axi_req.b_ready       ;

assign  ariane_axi_arvalid      = axi_req.ar_valid      ;
assign  ariane_axi_arid         = axi_req.ar.id         ;
assign  ariane_axi_araddr       = axi_req.ar.addr       ;
assign  ariane_axi_arlen        = axi_req.ar.len        ;
assign  ariane_axi_arsize       = axi_req.ar.size       ;
assign  ariane_axi_arburst      = axi_req.ar.burst      ;
assign  ariane_axi_arlock       = axi_req.ar.lock       ;
assign  ariane_axi_arcache      = axi_req.ar.cache      ;
assign  ariane_axi_arprot       = axi_req.ar.prot       ;
assign  ariane_axi_arqos        = axi_req.ar.qos        ;
assign  ariane_axi_arregion     = axi_req.ar.region     ;
assign  axi_rsp.ar_ready        = ariane_axi_arready    ;

assign  axi_rsp.r_valid         = ariane_axi_rvalid     ;
assign  axi_rsp.r.id            = ariane_axi_rid        ;
assign  axi_rsp.r.data          = ariane_axi_rdata      ;
assign  axi_rsp.r.resp          = ariane_axi_rresp      ;
assign  axi_rsp.r.last          = ariane_axi_rlast      ;
assign  ariane_axi_rready       = axi_req.r_ready       ;

ariane #(
    .ArianeCfg ( ariane_soc::ArianeSocCfg )
) i_ariane (
    .clk_i        ( ARIANE_CLK          ),
    .rst_ni       ( ARIANE_RST_N        ),
    .boot_addr_i  ( BOOT_ADDR           ),
    .hart_id_i    ( HART_ID             ),
    .irq_i        ( 0                   ),
    .ipi_i        ( 0                   ),
    .time_irq_i   ( 0                   ),
    .debug_req_i  ( 0                   ),
    .axi_req_o    ( axi_req             ),
    .axi_resp_i   ( axi_rsp             )
);


always
begin
  NIC_0_ACLK = 0;
  #(1000.000/(156.25*2));
  NIC_0_ACLK = 1;
  #(1000.000/(156.25*2));
end

initial
begin
  NIC_0_ARESET = 1;
  #(((1000.000/156.25)*100)+1);
  NIC_0_ARESET = 0;
end

always
begin
  PCIE_CLK_P = 0;
  #5.0;
  PCIE_CLK_P = 1;
  #5.0;
end

always
begin
  PCIE_CLK_N = 1;
  #5.0;
  PCIE_CLK_N = 0;
  #5.0;
end

always
begin
  FPGA_SYSCLK_P = 0;
  #2.5;
  FPGA_SYSCLK_P = 1;
  #2.5;
end

always
begin
  FPGA_SYSCLK_N = 1;
  #2.5;
  FPGA_SYSCLK_N = 0;
  #2.5;
end

assign FPGA_SYSCLK = FPGA_SYSCLK_P;

initial
begin
  LOCK = 0;
  #50;
  LOCK = 1;
end


initial
begin
  RESET = 1;
  #1000;
  RESET = 0;
end

initial
begin
  PERSTN = 0;
  #100;
  PERSTN = 1;
end

//always
//begin
//  CLK_REF_clk_n = 0;
//  #5.0;
//  CLK_REF_clk_n = 1;
//  #5.0;
//end
//always
//begin
//  CLK_REF_clk_p = 1;
//  #5.0;
//  CLK_REF_clk_p = 0;
//  #5.0;
//end
//
//always
//begin
//  DDR3_ck_n = 0;
//  #5.0;
//  DDR3_ck_n = 1;
//  #5.0;
//end
//always
//
//begin
//  DDR3_ck_p = 1;
//  #5.0;
//  DDR3_ck_p = 0;
//  #5.0;
//end
//
//initial
//begin
//  DDR3_reset_n = 0;
//  #100;
//  DDR3_reset_n = 1;
//end

initial begin
    //$fsdbDumpfile("./testbench.fsdb");
    $fsdbDumpvars(0,top_sim,"+fsdbfile+testbench.fsdb");
    //$fsdbDumpvars("+all");
    //$fsdbDumpvars("+mda");
    //$fsdbDumpvars("+struct");
    //$fsdbDumpvars("+vpi");
    //$fsdbDumpvars("+vcsd");
end

endmodule
