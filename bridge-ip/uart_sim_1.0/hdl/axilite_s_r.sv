`timescale 1ns/100ps
module axilite_s_r
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

,   input  [          ADRW-1:0] i_stat
);
    
    import "DPI-C" function void C_uart_rx(output int c);
    
    //---------------------------------------------------------------------
    // SLAVE READ
    //---------------------------------------------------------------------
    localparam AXI_RESP_OK = 2'b00;
    
    localparam READ_IDLE     = 0;
    localparam READ_DATA     = 1;
    localparam READ_RESPONSE = 2;

    localparam RX_FIFO  = 4'h0; 
    localparam TX_FIFO  = 4'h4;
    localparam STAT_REG = 4'h8; 
    localparam CTRL_REG = 4'hC;
    
    //------------------------------------------------------
    // Reg/Wire
    //------------------------------------------------------

    reg [DATW-1:0] r_s_rdata,  s_rdata = 0;
    reg            r_s_rvalid, s_rvalid;

    //------------------------------------------------------
    // Instance
    //------------------------------------------------------

    //------------------------------------------------------
    // Main
    //------------------------------------------------------

    //------------------------------------------------------
    // Combo
    //------------------------------------------------------

    always@(*)
    begin: COMBO_READ
        
        s_rvalid = r_s_rvalid;
        
        if ( i_s_rready ) begin
            s_rvalid = 0;
        end
        
        if ( i_s_arvalid ) begin
            s_rvalid = 1;
            case ( i_s_araddr[3:0] ) 
            TX_FIFO:  s_rdata = 32'hDEADBEEF;
            CTRL_REG: s_rdata = 32'hABADCAFE;
            STAT_REG: s_rdata = i_stat;
            RX_FIFO:  begin 
                C_uart_rx(s_rdata);
            end
            default:  s_rvalid = 0;
            endcase
        end
    end // COMBO_READ
    
    //------------------------------------------------------
    // FF
    //------------------------------------------------------
    always@(posedge i_clk)
    begin: FF
        if(~i_rst_n) begin
            r_s_rvalid <= 0;
            r_s_rdata  <= 0;
        end
        else begin
            r_s_rvalid <= s_rvalid;
            r_s_rdata  <= s_rdata;
        end
    end
    
    //------------------------------------------------------
    // Output Assignment
    //------------------------------------------------------
    
    // Combo Out
    // Const Out
    assign  o_s_rresp   = AXI_RESP_OK;
    // Reg   Out
    assign  o_s_arready = 1;
    assign  o_s_rvalid  = r_s_rvalid;
    assign  o_s_rdata   = r_s_rdata;
    
endmodule // axi4_s_r
