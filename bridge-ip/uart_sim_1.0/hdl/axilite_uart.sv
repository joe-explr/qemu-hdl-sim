module axilite_uart
#(
    parameter   ADRW            = 32
,               DATW            = 32
)
(
    input                       i_clk
,   input                       i_rst_n

,   input           [ ADRW-1:0] i_s_araddr
,   input                       i_s_arvalid
,   output                      o_s_arready

,   output reg      [ DATW-1:0] o_s_rdata
,   output          [    2-1:0] o_s_rresp
,   output reg                  o_s_rvalid
,   input                       i_s_rready

,   input           [ ADRW-1:0] i_s_awaddr
,   output                      o_s_awready
,   input                       i_s_awvalid

,   input  [          DATW-1:0] i_s_wdata
,   input  [        DATW/8-1:0] i_s_wstrb
,   input                       i_s_wvalid
,   output                      o_s_wready

,   output [             2-1:0] o_s_bresp
,   output reg                  o_s_bvalid
,   input                       i_s_bready
);

import "DPI-C" function void C_setup_uart_connection();

logic [ADRW-1:0] stat_r, ctrl_r, tx_fifo_r, rx_fifo_r;
logic [ADRW-1:0] stat, ctrl, tx_fifo, rx_fifo;

axilite_s_r axilite_s_r 
(
.i_clk(i_clk),
.i_rst_n(i_rst_n),
.i_s_araddr(i_s_araddr),
.i_s_arvalid(i_s_arvalid),
.o_s_arready(o_s_arready),
.o_s_rdata(o_s_rdata),
.o_s_rresp(o_s_rresp),
.o_s_rvalid(o_s_rvalid),
.i_s_rready(i_s_rready),
.i_stat(stat_r)
);

axilite_s_w axilite_s_w (
.i_clk(i_clk),
.i_rst_n(i_rst_n),
.i_s_awaddr(i_s_awaddr),
.i_s_awvalid(i_s_awvalid),
.o_s_awready(o_s_awready),
.i_s_wdata(i_s_wdata),
.i_s_wstrb(i_s_wstrb),
.i_s_wvalid(i_s_wvalid),
.o_s_wready(o_s_wready),
.o_s_bresp(o_s_bresp),
.o_s_bvalid(o_s_bvalid),
.i_s_bready(i_s_bready),
.i_stat(stat_r),
.o_stat(stat),
.i_rx_fifo(rx_fifo_r),
.o_rx_fifo(rx_fifo)
);

always_ff @(posedge i_clk) begin
    if (~i_rst_n) begin
        stat_r <= 0;
        ctrl_r <= 0;
        tx_fifo_r  <= 0;
        rx_fifo_r  <= 0;
    end else begin
        stat_r <= stat;
        ctrl_r <= ctrl;
        tx_fifo_r <= tx_fifo;
        rx_fifo_r <= rx_fifo;
    end
end

initial begin
    C_setup_uart_connection();
end

endmodule
