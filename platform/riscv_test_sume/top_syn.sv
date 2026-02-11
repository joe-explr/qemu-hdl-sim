

module top_syn 
   (
	input FPGA_SYSCLK_P,
	input FPGA_SYSCLK_N,
	input DDR_CLK_P,
	input DDR_CLK_N,
	input PCIE_CLK_N,
    input PCIE_CLK_P,
    input  [8-1:0] PCIE_RX_N,
    input  [8-1:0] PCIE_RX_P,
    output [8-1:0] PCIE_TX_N,
    output [8-1:0] PCIE_TX_P,
    input PERSTN,
    input RESET,
    output UART_RXD_OUT,
    input  UART_TXD_IN
	
,	output [ 15:0] DDR3_addr
,	output [  2:0] DDR3_ba
,	output         DDR3_cas_n
,	output [  0:0] DDR3_ck_n
,	output [  0:0] DDR3_ck_p
,	output [  0:0] DDR3_cke
,	output [  0:0] DDR3_cs_n
,	output [  7:0] DDR3_dm
,	inout [ 63:0] DDR3_dq
,	inout [  7:0] DDR3_dqs_n
,	inout [  7:0] DDR3_dqs_p
,	output [  0:0] DDR3_odt
,	output         DDR3_ras_n
,	output         DDR3_reset_n
,	output         DDR3_we_n

,   output  ETH1_TX_P
,   output  ETH1_TX_N
,   input   ETH1_RX_P
,   input   ETH1_RX_N

,   input   SFP_CLK_P
,   input   SFP_CLK_N

,   output  ETH1_TX_LED
,   output  ETH1_RX_LED
,   input   ETH1_MOD_DETECT
,   output  ETH1_TX_DISABLE
,   input   ETH1_TX_FAULT
);

wire [  0:0] FPGA_SYSCLK;
wire [  0:0] LOCK;

wire         ARIANE_CLK;
wire         ARIANE_RST_N;

wire         SYSCLK_RSTN_PERIPHERAL;

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

wire         NIC_0_ACLK;
wire         NIC_0_ARESET;
wire         NIC_0_ARESETN = ~NIC_0_ARESET;
wire         NIC_0_RESETDONE;
wire         NIC_0_SIGNAL_DETECT = ~ETH1_MOD_DETECT;
assign       ETH1_TX_LED = NIC_0_RESETDONE;
assign       ETH1_RX_LED = NIC_0_RESETDONE;
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
,   .*
);

axi_pcie3_0 axi_pcie3_inst (
    .refclk             (PCIE_REFCLK_OUT        )   // input wire refclk
,   .axi_aclk           (PCIE_ACLK_IN           )   // output wire axi_aclk
,   .axi_aresetn        (PCIE_ARESETN_IN        )   // output wire axi_aresetn
,   .axi_ctl_aresetn    (                       )   // output wire axi_ctl_aresetn
,   .sys_rst_n          (PERSTN                 )   // input wire sys_rst_n

,   .m_axi_arid         (PCIE_AXI_M_arid        )   // output wire [2 : 0] m_axi_arid
,   .m_axi_araddr       (PCIE_AXI_M_araddr      )   // output wire [63 : 0] m_axi_araddr
,   .m_axi_arlen        (PCIE_AXI_M_arlen       )   // output wire [7 : 0] m_axi_arlen
,   .m_axi_arsize       (PCIE_AXI_M_arsize      )   // output wire [2 : 0] m_axi_arsize
,   .m_axi_arburst      (PCIE_AXI_M_arburst     )   // output wire [1 : 0] m_axi_arburst
,   .m_axi_arlock       (PCIE_AXI_M_arlock      )   // output wire m_axi_arlock
,   .m_axi_arcache      (PCIE_AXI_M_arcache     )   // output wire [3 : 0] m_axi_arcache
,   .m_axi_arprot       (PCIE_AXI_M_arprot      )   // output wire [2 : 0] m_axi_arprot
,   .m_axi_arvalid      (PCIE_AXI_M_arvalid     )   // output wire m_axi_arvalid
,   .m_axi_arready      (PCIE_AXI_M_arready     )   // input wire m_axi_arready
,   .m_axi_rid          (PCIE_AXI_M_rid         )   // input wire [2 : 0] m_axi_rid
,   .m_axi_rdata        (PCIE_AXI_M_rdata       )   // input wire [255 : 0] m_axi_rdata
,   .m_axi_rresp        (PCIE_AXI_M_rresp       )   // input wire [1 : 0] m_axi_rresp
,   .m_axi_rlast        (PCIE_AXI_M_rlast       )   // input wire m_axi_rlast
,   .m_axi_rvalid       (PCIE_AXI_M_rvalid      )   // input wire m_axi_rvalid
,   .m_axi_rready       (PCIE_AXI_M_rready      )   // output wire m_axi_rready
,   .m_axi_awid         (PCIE_AXI_M_awid        )   // output wire [2 : 0] m_axi_awid
,   .m_axi_awaddr       (PCIE_AXI_M_awaddr      )   // output wire [63 : 0] m_axi_awaddr
,   .m_axi_awlen        (PCIE_AXI_M_awlen       )   // output wire [7 : 0] m_axi_awlen
,   .m_axi_awsize       (PCIE_AXI_M_awsize      )   // output wire [2 : 0] m_axi_awsize
,   .m_axi_awburst      (PCIE_AXI_M_awburst     )   // output wire [1 : 0] m_axi_awburst
,   .m_axi_awlock       (PCIE_AXI_M_awlock      )   // output wire m_axi_awlock
,   .m_axi_awcache      (PCIE_AXI_M_awcache     )   // output wire [3 : 0] m_axi_awcache
,   .m_axi_awprot       (PCIE_AXI_M_awprot      )   // output wire [2 : 0] m_axi_awprot
,   .m_axi_awvalid      (PCIE_AXI_M_awvalid     )   // output wire m_axi_awvalid
,   .m_axi_awready      (PCIE_AXI_M_awready     )   // input wire m_axi_awready
,   .m_axi_wdata        (PCIE_AXI_M_wdata       )   // output wire [255 : 0] m_axi_wdata
,   .m_axi_wlast        (PCIE_AXI_M_wlast       )   // output wire m_axi_wlast
,   .m_axi_wstrb        (PCIE_AXI_M_wstrb       )   // output wire [31 : 0] m_axi_wstrb
,   .m_axi_wvalid       (PCIE_AXI_M_wvalid      )   // output wire m_axi_wvalid
,   .m_axi_wready       (PCIE_AXI_M_wready      )   // input wire m_axi_wready
,   .m_axi_bid          (PCIE_AXI_M_bid         )   // input wire [2 : 0] m_axi_bid
,   .m_axi_bresp        (PCIE_AXI_M_bresp       )   // input wire [1 : 0] m_axi_bresp
,   .m_axi_bvalid       (PCIE_AXI_M_bvalid      )   // input wire m_axi_bvalid
,   .m_axi_bready       (PCIE_AXI_M_bready      )   // output wire m_axi_bready

,   .m_axi_ruser        (0                      )   // input wire [31 : 0] m_axi_ruser
,   .m_axi_wuser        (                       )   // output wire [31 : 0] m_axi_wuser

,   .s_axi_arid         (PCIE_AXI_S_arid        )   // input wire [3 : 0] s_axi_arid
,   .s_axi_araddr       (PCIE_AXI_S_araddr      )   // input wire [63 : 0] s_axi_araddr
,   .s_axi_arlen        (PCIE_AXI_S_arlen       )   // input wire [7 : 0] s_axi_arlen
,   .s_axi_arsize       (PCIE_AXI_S_arsize      )   // input wire [2 : 0] s_axi_arsize
,   .s_axi_arburst      (PCIE_AXI_S_arburst     )   // input wire [1 : 0] s_axi_arburst
,   .s_axi_arregion     (PCIE_AXI_S_arregion    )   // input wire [3 : 0] s_axi_arregion
,   .s_axi_arvalid      (PCIE_AXI_S_arvalid     )   // input wire s_axi_arvalid
,   .s_axi_arready      (PCIE_AXI_S_arready     )   // output wire s_axi_arready
,   .s_axi_rid          (PCIE_AXI_S_rid         )   // output wire [3 : 0] s_axi_rid
,   .s_axi_rdata        (PCIE_AXI_S_rdata       )   // output wire [255 : 0] s_axi_rdata
,   .s_axi_rresp        (PCIE_AXI_S_rresp       )   // output wire [1 : 0] s_axi_rresp
,   .s_axi_rlast        (PCIE_AXI_S_rlast       )   // output wire s_axi_rlast
,   .s_axi_rvalid       (PCIE_AXI_S_rvalid      )   // output wire s_axi_rvalid
,   .s_axi_rready       (PCIE_AXI_S_rready      )   // input wire s_axi_rready
,   .s_axi_awid         (PCIE_AXI_S_awid        )   // input wire [3 : 0] s_axi_awid
,   .s_axi_awaddr       (PCIE_AXI_S_awaddr      )   // input wire [63 : 0] s_axi_awaddr
,   .s_axi_awlen        (PCIE_AXI_S_awlen       )   // input wire [7 : 0] s_axi_awlen
,   .s_axi_awsize       (PCIE_AXI_S_awsize      )   // input wire [2 : 0] s_axi_awsize
,   .s_axi_awburst      (PCIE_AXI_S_awburst     )   // input wire [1 : 0] s_axi_awburst
,   .s_axi_awregion     (PCIE_AXI_S_awregion    )   // input wire [3 : 0] s_axi_awregion
,   .s_axi_awvalid      (PCIE_AXI_S_awvalid     )   // input wire s_axi_awvalid
,   .s_axi_awready      (PCIE_AXI_S_awready     )   // output wire s_axi_awready
,   .s_axi_wdata        (PCIE_AXI_S_wdata       )   // input wire [255 : 0] s_axi_wdata
,   .s_axi_wlast        (PCIE_AXI_S_wlast       )   // input wire s_axi_wlast
,   .s_axi_wstrb        (PCIE_AXI_S_wstrb       )   // input wire [31 : 0] s_axi_wstrb
,   .s_axi_wvalid       (PCIE_AXI_S_wvalid      )   // input wire s_axi_wvalid
,   .s_axi_wready       (PCIE_AXI_S_wready      )   // output wire s_axi_wready
,   .s_axi_bid          (PCIE_AXI_S_bid         )   // output wire [3 : 0] s_axi_bid
,   .s_axi_bresp        (PCIE_AXI_S_bresp       )   // output wire [1 : 0] s_axi_bresp
,   .s_axi_bvalid       (PCIE_AXI_S_bvalid      )   // output wire s_axi_bvalid
,   .s_axi_bready       (PCIE_AXI_S_bready      )   // input wire s_axi_bready

,   .s_axi_ruser        (                       )   // output wire [31 : 0] s_axi_ruser
,   .s_axi_wuser        (0                      )   // input wire [31 : 0] s_axi_wuser

,   .s_axi_ctl_araddr   (PCIE_AXI_S_CTL_araddr  )   // input wire [11 : 0] s_axi_ctl_araddr
,   .s_axi_ctl_arvalid  (PCIE_AXI_S_CTL_arvalid )   // input wire s_axi_ctl_arvalid
,   .s_axi_ctl_arready  (PCIE_AXI_S_CTL_arready )   // output wire s_axi_ctl_arready
,   .s_axi_ctl_rdata    (PCIE_AXI_S_CTL_rdata   )   // output wire [31 : 0] s_axi_ctl_rdata
,   .s_axi_ctl_rresp    (PCIE_AXI_S_CTL_rresp   )   // output wire [1 : 0] s_axi_ctl_rresp
,   .s_axi_ctl_rvalid   (PCIE_AXI_S_CTL_rvalid  )   // output wire s_axi_ctl_rvalid
,   .s_axi_ctl_rready   (PCIE_AXI_S_CTL_rready  )   // input wire s_axi_ctl_rready
,   .s_axi_ctl_awaddr   (PCIE_AXI_S_CTL_awaddr  )   // input wire [11 : 0] s_axi_ctl_awaddr
,   .s_axi_ctl_awvalid  (PCIE_AXI_S_CTL_awvalid )   // input wire s_axi_ctl_awvalid
,   .s_axi_ctl_awready  (PCIE_AXI_S_CTL_awready )   // output wire s_axi_ctl_awready
,   .s_axi_ctl_wdata    (PCIE_AXI_S_CTL_wdata   )   // input wire [31 : 0] s_axi_ctl_wdata
,   .s_axi_ctl_wstrb    (PCIE_AXI_S_CTL_wstrb   )   // input wire [3 : 0] s_axi_ctl_wstrb
,   .s_axi_ctl_wvalid   (PCIE_AXI_S_CTL_wvalid  )   // input wire s_axi_ctl_wvalid
,   .s_axi_ctl_wready   (PCIE_AXI_S_CTL_wready  )   // output wire s_axi_ctl_wready
,   .s_axi_ctl_bresp    (PCIE_AXI_S_CTL_bresp   )   // output wire [1 : 0] s_axi_ctl_bresp
,   .s_axi_ctl_bvalid   (PCIE_AXI_S_CTL_bvalid  )   // output wire s_axi_ctl_bvalid
,   .s_axi_ctl_bready   (PCIE_AXI_S_CTL_bready  )   // input wire s_axi_ctl_bready

,   .pci_exp_rxn        (PCIE_RX_N              )   // input wire [7 : 0] pci_exp_rxn
,   .pci_exp_rxp        (PCIE_RX_P              )   // input wire [7 : 0] pci_exp_rxp
,   .pci_exp_txn        (PCIE_TX_N              )   // output wire [7 : 0] pci_exp_txn
,   .pci_exp_txp        (PCIE_TX_P              )   // output wire [7 : 0] pci_exp_txp

,   .interrupt_out      (                       )   // output wire interrupt_out
,   .intx_msi_request   (0/*PCIE_INTX_MSI_REQUEST*/)// input wire intx_msi_request
,   .intx_msi_grant     (                       )   // output wire intx_msi_grant

,   .cfg_ltssm_state    (                       )   // output wire [5 : 0] cfg_ltssm_state
,   .user_link_up       (                       )   // output wire user_link_up

//, .msi_vector_num     (0                      )   // input wire [4 : 0] msi_vector_num
//, .msi_enable         (                       )   // output wire msi_enable
//, .msi_vector_width   (                       )   // output wire [2 : 0] msi_vector_width

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

 mig_7series_0 ddr_inst (
    // Memory interface ports
     .ddr3_addr                      (DDR3_addr             )  // output [15:0]		ddr3_addr
,    .ddr3_ba                        (DDR3_ba               )  // output [2:0]		ddr3_ba
,    .ddr3_cas_n                     (DDR3_cas_n            )  // output			ddr3_cas_n
,    .ddr3_ck_n                      (DDR3_ck_n             )  // output [0:0]		ddr3_ck_n
,    .ddr3_ck_p                      (DDR3_ck_p             )  // output [0:0]		ddr3_ck_p
,    .ddr3_cke                       (DDR3_cke              )  // output [0:0]		ddr3_cke
,    .ddr3_ras_n                     (DDR3_ras_n            )  // output			ddr3_ras_n
,    .ddr3_reset_n                   (DDR3_reset_n          )  // output			ddr3_reset_n
,    .ddr3_we_n                      (DDR3_we_n             )  // output			ddr3_we_n
,    .ddr3_dq                        (DDR3_dq               )  // inout [63:0]		ddr3_dq
,    .ddr3_dqs_n                     (DDR3_dqs_n            )  // inout [7:0]		ddr3_dqs_n
,    .ddr3_dqs_p                     (DDR3_dqs_p            )  // inout [7:0]		ddr3_dqs_p
,    .init_calib_complete            (                      )  // output			init_calib_complete
,	 .ddr3_cs_n                      (DDR3_cs_n             )  // output [0:0]		ddr3_cs_n
,    .ddr3_dm                        (DDR3_dm               )  // output [7:0]		ddr3_dm
,    .ddr3_odt                       (DDR3_odt              )  // output [0:0]		ddr3_odt
     // Application interface ports
,    .ui_clk                         (FPGA_SYSCLK           )  // output			ui_clk
,    .ui_clk_sync_rst                (                      )  // output			ui_clk_sync_rst
,    .mmcm_locked                    (LOCK                  )  // output			mmcm_locked
,    .aresetn                        (SYSCLK_RSTN_PERIPHERAL)  // input			    aresetn
,    .app_sr_req                     (0                     )  // input			    app_sr_req
,    .app_ref_req                    (0                     )  // input			    app_ref_req
,    .app_zq_req                     (0                     )  // input			    app_zq_req
,    .app_sr_active                  (                      )  // output			app_sr_active
,    .app_ref_ack                    (                      )  // output			app_ref_ack
,    .app_zq_ack                     (                      )  // output			app_zq_ack
     // Slave Interface Write Address Ports
,    .s_axi_awid                     (DDR_AXI_S_awid        )  // input [1:0]		s_axi_awid
,    .s_axi_awaddr                   (DDR_AXI_S_awaddr      )  // input [31:0]		s_axi_awaddr
,    .s_axi_awlen                    (DDR_AXI_S_awlen       )  // input [7:0]		s_axi_awlen
,    .s_axi_awsize                   (DDR_AXI_S_awsize      )  // input [2:0]		s_axi_awsize
,    .s_axi_awburst                  (DDR_AXI_S_awburst     )  // input [1:0]		s_axi_awburst
,    .s_axi_awlock                   (DDR_AXI_S_awlock      )  // input [0:0]		s_axi_awlock
,    .s_axi_awcache                  (DDR_AXI_S_awcache     )  // input [3:0]		s_axi_awcache
,    .s_axi_awprot                   (DDR_AXI_S_awprot      )  // input [2:0]		s_axi_awprot
,    .s_axi_awqos                    (DDR_AXI_S_awqos       )  // input [3:0]		s_axi_awqos
,    .s_axi_awvalid                  (DDR_AXI_S_awvalid     )  // input				s_axi_awvalid
,    .s_axi_awready                  (DDR_AXI_S_awready     )  // output			s_axi_awready
     // Slave Interface Write Data Ports
,    .s_axi_wdata                    (DDR_AXI_S_wdata       )  // input [511:0]		s_axi_wdata
,    .s_axi_wstrb                    (DDR_AXI_S_wstrb       )  // input [63:0]		s_axi_wstrb
,    .s_axi_wlast                    (DDR_AXI_S_wlast       )  // input				s_axi_wlast
,    .s_axi_wvalid                   (DDR_AXI_S_wvalid      )  // input				s_axi_wvalid
,    .s_axi_wready                   (DDR_AXI_S_wready      )  // output			s_axi_wready
     // Slave Interface Write Response Ports
,    .s_axi_bid                      (DDR_AXI_S_bid         )  // output [1:0]		s_axi_bid
,    .s_axi_bresp                    (DDR_AXI_S_bresp       )  // output [1:0]		s_axi_bresp
,    .s_axi_bvalid                   (DDR_AXI_S_bvalid      )  // output			s_axi_bvalid
,    .s_axi_bready                   (DDR_AXI_S_bready      )  // input				s_axi_bready
     // Slave Interface Read Address Ports
,    .s_axi_arid                     (DDR_AXI_S_arid        )  // input [1:0]		s_axi_arid
,    .s_axi_araddr                   (DDR_AXI_S_araddr      )  // input [31:0]		s_axi_araddr
,    .s_axi_arlen                    (DDR_AXI_S_arlen       )  // input [7:0]		s_axi_arlen
,    .s_axi_arsize                   (DDR_AXI_S_arsize      )  // input [2:0]		s_axi_arsize
,    .s_axi_arburst                  (DDR_AXI_S_arburst     )  // input [1:0]		s_axi_arburst
,    .s_axi_arlock                   (DDR_AXI_S_arlock      )  // input [0:0]		s_axi_arlock
,    .s_axi_arcache                  (DDR_AXI_S_arcache     )  // input [3:0]		s_axi_arcache
,    .s_axi_arprot                   (DDR_AXI_S_arprot      )  // input [2:0]		s_axi_arprot
,    .s_axi_arqos                    (DDR_AXI_S_arqos       )  // input [3:0]		s_axi_arqos
,    .s_axi_arvalid                  (DDR_AXI_S_arvalid     )  // input				s_axi_arvalid
,    .s_axi_arready                  (DDR_AXI_S_arready     )  // output			s_axi_arready
     // Slave Interface Read Data Ports
,    .s_axi_rid                      (DDR_AXI_S_rid         )  // output [1:0]		s_axi_rid
,    .s_axi_rdata                    (DDR_AXI_S_rdata       )  // output [511:0]	s_axi_rdata
,    .s_axi_rresp                    (DDR_AXI_S_rresp       )  // output [1:0]		s_axi_rresp
,    .s_axi_rlast                    (DDR_AXI_S_rlast       )  // output			s_axi_rlast
,    .s_axi_rvalid                   (DDR_AXI_S_rvalid      )  // output			s_axi_rvalid
,    .s_axi_rready                   (DDR_AXI_S_rready      )  // input				s_axi_rready
     // System Clock Ports
,    .sys_clk_p                      (DDR_CLK_P             )  // input				sys_clk_p
,    .sys_clk_n                      (DDR_CLK_N             )  // input				sys_clk_n
     // Reference Clock Ports
,    .clk_ref_p                      (FPGA_SYSCLK_P         )  // input				clk_ref_p
,    .clk_ref_n                      (FPGA_SYSCLK_N         )  // input				clk_ref_n
,    .sys_rst                        (RESET                 )  // input sys_rst
);

MsixController_syn MsixController_inst (
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

axi_uartlite_0 axi_uartlite_0_1
(
    .s_axi_aclk         (PCIE_ACLK_IN           )
,   .s_axi_aresetn      (UART_ARESETN_OUT       )
,   .s_axi_awaddr       (UART_AXI_S_awaddr      )
,   .s_axi_awvalid      (UART_AXI_S_awvalid     )
,   .s_axi_awready      (UART_AXI_S_awready     )
,   .s_axi_wdata        (UART_AXI_S_wdata       )
,   .s_axi_wstrb        (UART_AXI_S_wstrb       )
,   .s_axi_wvalid       (UART_AXI_S_wvalid      )
,   .s_axi_wready       (UART_AXI_S_wready      )
,   .s_axi_bresp        (UART_AXI_S_bresp       )
,   .s_axi_bvalid       (UART_AXI_S_bvalid      )
,   .s_axi_bready       (UART_AXI_S_bready      )
,   .s_axi_araddr       (UART_AXI_S_araddr      )
,   .s_axi_arvalid      (UART_AXI_S_arvalid     )
,   .s_axi_arready      (UART_AXI_S_arready     )
,   .s_axi_rdata        (UART_AXI_S_rdata       )
,   .s_axi_rresp        (UART_AXI_S_rresp       )
,   .s_axi_rvalid       (UART_AXI_S_rvalid      )
,   .s_axi_rready       (UART_AXI_S_rready      )
,   .interrupt          (                       )
,   .rx                 (UART_TXD_IN            )
,   .tx                 (UART_RXD_OUT           )
);


axi_10g_ethernet_0
axi_10g_ethernet_share (
    .tx_axis_aresetn		        (NIC_0_ARESETN                      ) // I invert of areset_datapathclk_out
,   .rx_axis_aresetn		        (NIC_0_ARESETN                      ) // I invert of areset_datapathclk_out
,   .tx_ifg_delay			        (0                                  ) // I 8'b0
,   .dclk			                (NIC_0_ACLK                         ) // I connect to coreclk_out
,   .txp				            (ETH1_TX_P                          ) // O pin:
,   .txn				            (ETH1_TX_N                          ) // O pin:
,   .rxp				            (ETH1_RX_P                          ) // I pin:
,   .rxn				            (ETH1_RX_N                          ) // I pin:
,   .signal_detect			        (NIC_0_SIGNAL_DETECT                ) // I pin tx_abs -> inverter -> signal_detect
,   .tx_fault			            (ETH1_TX_FAULT                      ) // I pin: tx_fault
,   .tx_disable			            (ETH1_TX_DISABLE                    ) // O pin: tx_disable

,   .sim_speedup_control		    (0                                  ) // I 1'b0 (maybe useful in simulation)

,   .mac_tx_configuration_vector	('d2                                ) // I 'd2  
,   .mac_rx_configuration_vector	('d2                                ) // I 'd2
,   .pcs_pma_configuration_vector	('d0                                ) // I 'd0

,   .pcspma_status			        (                                   ) // O can be NC?
,   .mac_status_vector		        (                                   ) // O can be NC?
,   .pcs_pma_status_vector		    (                                   ) // O can be NC?

,   .txusrclk_out			        (                                   ) // O //\\ share
,   .txusrclk2_out			        (                                   ) // O //\\ share
,   .gttxreset_out			        (                                   ) // O //\\ share
,   .gtrxreset_out			        (                                   ) // O //\\ share
,   .txuserrdy_out			        (                                   ) // O //\\ share

,   .coreclk_out			        (NIC_0_ACLK                         ) // O main clk //\\ share		// Ports Changed in v3.0, clk156_out -> coreclk_out
,   .areset_datapathclk_out		    (NIC_0_ARESET                       ) // O	//\\ share Ports Changed in v3.0, areset_clk156_out -> areset_datapathclk_out
,   .resetdone_out			        (NIC_0_RESETDONE                    ) // O pin: tx_led & rx_led		// Ports Changed in v3.0, resetdone -> resetdone_out
,   .reset_counter_done_out		    (                                   ) // O //\\ share
,   .qplllock_out			        (                                   ) // O //\\ share
,   .qplloutclk_out			        (                                   ) // O //\\ share
,   .qplloutrefclk_out		        (                                   ) // O //\\ share
,   .refclk_p			            (SFP_CLK_P                          ) // I pin:spf_refclk_p
,   .refclk_n			            (SFP_CLK_N                          ) // I pin:spf_refclk_n
,   .reset				            (RESET                              ) // I pin:reset

,   .s_axis_tx_tdata		        (axi_dma_nic_0_M_AXIS_MM2S_tdata    )
,   .s_axis_tx_tkeep		        (axi_dma_nic_0_M_AXIS_MM2S_tkeep    )
,   .s_axis_tx_tlast		        (axi_dma_nic_0_M_AXIS_MM2S_tlast    )
,   .s_axis_tx_tready		        (axi_dma_nic_0_M_AXIS_MM2S_tready   )
,   .s_axis_tx_tuser		        (0                                  )  // I 'b0
,   .s_axis_tx_tvalid		        (axi_dma_nic_0_M_AXIS_MM2S_tvalid   )

,   .s_axis_pause_tdata		        (0                                  ) // I 16'b0
,   .s_axis_pause_tvalid		    (0                                  ) // I 1'b0

,   .m_axis_rx_tdata		        (axi_dma_nic_0_S_AXIS_S2MM_tdata    )
,   .m_axis_rx_tkeep		        (axi_dma_nic_0_S_AXIS_S2MM_tkeep    )
,   .m_axis_rx_tlast		        (axi_dma_nic_0_S_AXIS_S2MM_tlast    )
,   .m_axis_rx_tuser		        (                                   ) // O NC?
,   .m_axis_rx_tvalid		        (axi_dma_nic_0_S_AXIS_S2MM_tvalid   )

,   .tx_statistics_valid		    (                                   ) // O NC
,   .tx_statistics_vector		    (                                   ) // O NC
,   .rx_statistics_valid		    (                                   ) // O NC
,   .rx_statistics_vector		    (                                   ) // O NC                  
);

// ---------------
// Core
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


endmodule
