module axilite_s_w
# (
    parameter   ADRW            = 32
,               DATW            = 32
)
(
    input                       i_clk
,   input                       i_rst_n

,   input  [          ADRW-1:0] i_s_awaddr
,   input                       i_s_awvalid
,   output                      o_s_awready

,   input  [          DATW-1:0] i_s_wdata
,   input  [        DATW/8-1:0] i_s_wstrb
,   input                       i_s_wvalid
,   output                      o_s_wready

,   output [             2-1:0] o_s_bresp
,   output reg                  o_s_bvalid
,   input                       i_s_bready

,   input  [          ADRW-1:0] i_stat
,   output reg [      ADRW-1:0] o_stat
,   input  [          ADRW-1:0] i_rx_fifo
,   output reg [      ADRW-1:0] o_rx_fifo

);
    import "DPI-C" function void C_uart_poll(output int data_available);
    import "DPI-C" function void C_uart_tx(input int data);
    
    //---------------------------------------------------------------------
    // Constant Declarations
    //---------------------------------------------------------------------

    localparam AXI_RESP_OK     = 2'b00;
    localparam AXI_RESP_SLVERR = 2'b10;
    
    localparam WRITE_IDLE     = 0;
    localparam WRITE_DATA     = 1;
    localparam WRITE_RESPONSE = 2;
    
    
    localparam RX_FIFO  = 4'h0; 
    localparam TX_FIFO  = 4'h4;
    localparam STAT_REG = 4'h8; 
    localparam CTRL_REG = 4'hC;
    
    //---------------------------------------------------------------------
    // Reg/Wire
    //---------------------------------------------------------------------
    
    reg       r_s_bvalid , s_bvalid ;
    reg       r_s_wready , s_wready ;
    reg       r_s_awready, s_awready;
    reg [3:0] r_s_awaddr , s_awaddr ;
    reg [1:0] r_state    , state    ;
    logic print;
    byte data;
    byte data_available;
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
    begin: COMBO_WRITE
    
        s_bvalid   = r_s_bvalid;
        s_wready   = r_s_wready;
        s_awready  = 1;
        s_awaddr   = r_s_awaddr;
        state      = r_state;
               
        o_rx_fifo  = i_rx_fifo;
        // Always ready to recieve data             
        o_stat     = i_stat | 4;
        print = 0;
        data = i_s_wdata;
        
        C_uart_poll(data_available);
        if(data_available) begin
            o_stat |= 1;
        end
        
        case ( r_state )
            WRITE_IDLE: begin
                if ( i_s_awvalid & r_s_awready ) begin
                    s_awready = 0;
                    s_awaddr = i_s_awaddr;
                    s_wready = 1;
                    state = WRITE_DATA;
                end
            end

            WRITE_DATA: begin
                s_awready = 0;
                if ( i_s_wvalid & r_s_wready ) begin
                    if (r_s_awaddr[3:0] == CTRL_REG) begin
                        if ( i_s_wdata & 1 ) begin
                            data = 0;
                        end
                        if ( i_s_wdata & 2 ) begin
                            // TODO: clear rx fifo
                            o_rx_fifo = 0;
                        end
                        if ( i_s_wdata & 16 ) begin
                            o_stat |= 16;
                        end else begin
                            o_stat &= ~(16);
                        end
                    end else if (r_s_awaddr[3:0] == TX_FIFO) begin
                        print = 1; 
                    end
                    s_wready = 0;
                    s_bvalid = 1;
                    state = WRITE_RESPONSE;
                end
            end
        
            WRITE_RESPONSE: begin
                s_awready = 0;
                if ( i_s_bready & r_s_bvalid ) begin
                    s_bvalid = 0;
                    s_awready = 1;
                    state = WRITE_IDLE;
                end
            end
        
            default: begin
                s_awready = 0;
            end
        endcase  
    end // COMBO_WRITE


    //------------------------------------------------------
    // FF
    //------------------------------------------------------

    always@(posedge i_clk)
    begin: C_req
        if (print) begin
            //$write("%c", data);
            C_uart_tx(data);
        end
    end

    always@(posedge i_clk)
    begin: FF
        r_s_bvalid  <= (~i_rst_n) ? 0 : s_bvalid ;
        r_s_wready  <= (~i_rst_n) ? 0 : s_wready ;
        r_s_awready <= (~i_rst_n) ? 0 : s_awready;
        r_s_awaddr  <= (~i_rst_n) ? 0 : s_awaddr;
        r_state     <= (~i_rst_n) ? 0 : state;
    end


    //---------------------------------------------------------------------
    // Primary oUtput Assignment
    //---------------------------------------------------------------------

    // Combo Out
    // Const Out
    assign  o_s_bresp           = AXI_RESP_OK;
    // Reg   Out
    assign  o_s_awready         = r_s_awready;
    assign  o_s_wready          = r_s_wready ;
    assign  o_s_bvalid          = r_s_bvalid ;

endmodule
