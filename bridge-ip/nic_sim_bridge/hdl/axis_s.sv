module axis_s
#( parameter
    DATAW =  64
,   KEEPW = (DATAW/8)   // always refer to DATAW
,   DTMP  =  4096 
)
(
    input                       S_AXI_ACLK
,   input                       S_AXI_ARESETN

    // AXI Stream Slave : s_axis
,   input  [         DATAW-1:0] s_axis_tdata
,   input  [         KEEPW-1:0] s_axis_tkeep
,   input                       s_axis_tlast
,   input                       s_axis_tvalid
,   output reg                  s_axis_tready

    //==================================
    // Unused Signals
    //==================================
);

    import "DPI-C" function void    C_send_packet(input int id, input int len, input byte data_tmp[DTMP]);
    
    //---------------------------------------------------------------------
    // Constant Declarations
    //---------------------------------------------------------------------

    localparam IDLE = 0;
    localparam DATA = 1;

    //---------------------------------------------------------------------
    // Reg/Wire
    //---------------------------------------------------------------------

    reg        [           1:0] r_state                 , n_state                   ;
    reg        [         8-1:0] r_len                   , n_len                     ;
    byte                        r_data_tmp [0:DTMP-1]   , n_data_tmp [0:DTMP-1]     ;
    integer                     r_size                  , n_size                    ;
    reg        [           1:0] send_pkt;

    //---------------------------------------------------------------------
    // Instance
    //---------------------------------------------------------------------

    //---------------------------------------------------------------------
    // Main
    //---------------------------------------------------------------------

    //------------------------------------------------------
    // Combo
    //------------------------------------------------------

    integer i;

    always@(*)
    begin: COMBO_SEND
        automatic logic [KEEPW-1:0] tkeep = s_axis_tkeep;
        
        n_state    = r_state    ;
        n_len      = r_len      ;
        n_data_tmp = r_data_tmp ;
        n_size     = r_size     ;
        send_pkt   = 2'b0       ;
        
        if (r_state == IDLE) begin
            n_len  = 0;
            n_size = 0;
        end
        
        if(s_axis_tvalid && tkeep) begin
            n_state = DATA;
            for (i = 0; i < KEEPW; i++) begin
                if (tkeep[i]) begin
                    n_data_tmp[n_size] = s_axis_tdata[(i*8)+:8];
                    n_size = n_size + 1;
                end
            end
            if (!s_axis_tlast) begin
                n_len = r_len + 1;
            end else begin
                n_state  = IDLE  ;
                send_pkt = 2'b01 ;
            end
        end
    end // COMBO_SEND
    
    //------------------------------------------------------
    // FF
    //------------------------------------------------------

    always@(posedge S_AXI_ACLK)
    begin: DPI
        if (send_pkt) begin
            C_send_packet(0, n_size, n_data_tmp);
        end
    end // DISPLAY AND DPI

    always@(posedge S_AXI_ACLK)
    begin: FF_SEND
        r_state    <= (~S_AXI_ARESETN) ? IDLE : n_state;
        r_len      <= (~S_AXI_ARESETN) ? 0 : n_len;
        r_size     <= (~S_AXI_ARESETN) ? 0 : n_size;
        
        if(S_AXI_ARESETN) begin
            r_data_tmp <= n_data_tmp ;
        end
    end // FF_SEND
    
    //---------------------------------------------------------------------
    // Primary Output Assignment
    //---------------------------------------------------------------------

    // Combo Out
    // Const Out
    assign s_axis_tready = 1;
    // Reg   Out
endmodule
