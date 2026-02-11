module axis_m
#( parameter
    DATAW =  64
,   KEEPW = (DATAW/8)   // always refer to DATAW
,   DTMP  =  4096 
)
(
    input                       S_AXI_ACLK
,   input                       S_AXI_ARESETN
,   output reg                  busy
    // AXI Stream Master:  m_axis
,   output reg [     DATAW-1:0] m_axis_tdata
,   output reg [     KEEPW-1:0] m_axis_tkeep
,   output reg                  m_axis_tlast
,   output reg                  m_axis_tvalid
,   input                       m_axis_tready
,   input byte                  i_req
,   input byte                  i_data[0:DTMP-1]
,   input int                   i_len
,   input int                   i_last_keep

    //==================================
    // Unused Signals
    //==================================
);

    //---------------------------------------------------------------------
    // Constant Declarations
    //---------------------------------------------------------------------

    localparam IDLE = 0;
    localparam DATA = 1;

    //---------------------------------------------------------------------
    // Reg/Wire
    //---------------------------------------------------------------------

    reg        [           1:0] r_state                 , n_state                   ;
    integer                     r_len                   , n_len                     ;
    integer                     r_count                 , n_count                   ;
    byte                        r_data [0:DTMP-1]       , n_data [0:DTMP-1]         ;
    reg                         r_tvalid                , n_tvalid                  ;
    reg        [     DATAW-1:0] r_tdata                 , n_tdata                   ;
    reg        [     KEEPW-1:0] r_tkeep                 , n_tkeep                   ;
    reg        [     KEEPW-1:0] r_last_keep             , n_last_keep               ;
    reg                         r_tlast                 , n_tlast                   ;

    //---------------------------------------------------------------------
    // Instance
    //---------------------------------------------------------------------

    //---------------------------------------------------------------------
    // Main
    //---------------------------------------------------------------------

    //------------------------------------------------------
    // Combo
    //------------------------------------------------------


    always@(*) 
    begin: COMBO_RECV
        automatic integer i = 0;
        automatic integer j = 0;
        busy = 0;
        n_state  = r_state;
        n_tlast  = r_tlast;
        n_tkeep  = r_tkeep; 
        n_tdata  = r_tdata;
        n_tvalid = r_tvalid;
        case(r_state)
            IDLE: begin
                if (i_req) begin
                    busy = 1;
                    n_last_keep = i_last_keep;
                    n_len = i_len;
                    n_data = i_data;  
                    n_count = 1;

                    // All packets should be more than 8 bytes
                    for (i = 0; i < KEEPW; i++) begin
                        n_tdata[i*8+:8] = i_data[(0*KEEPW)+i];
                    end
                    n_tlast = 0;
                    n_tkeep = ~64'h0;
                    n_tvalid = 1;

                    n_state = DATA;   
                end
            end // (r_state == IDLE)
            DATA: begin
                busy = 1;
                if ( r_tvalid /*m_axis_tready*/ ) begin

                    for (j = 0; j < KEEPW; j++) begin
                        n_tdata[j*8+:8] = r_data[(r_count*KEEPW)+j];
                    end

                    if          (r_count==r_len+1) begin
                        busy = 0;
                        n_tvalid = 0;
                        n_state = IDLE;
                    end else if (r_count==r_len) begin
                        n_tvalid = 1;    
                        n_tlast  = 1;
                        n_tkeep  = r_last_keep;
                        n_count = r_count + 1;
                    end else begin
                        n_tvalid = 1;
                        n_tlast  = 0;
                        n_tkeep  = ~64'h0;
                        n_count = r_count + 1;
                    end

                end
            end // (r_state == DATA)
        endcase // r_state
    end
    
    //------------------------------------------------------
    // FF
    //------------------------------------------------------
    int j;
    always@(posedge S_AXI_ACLK)
    begin: FF_SEND
        if (~S_AXI_ARESETN) begin
            for (j = 0; j < DTMP; j++)
                r_data[j] <= 0;
        end else begin
            r_data <= n_data;
        end
        r_state  <= (~S_AXI_ARESETN) ? IDLE : n_state  ;
        r_len    <= (~S_AXI_ARESETN) ? 0 : n_len    ;
        r_count  <= (~S_AXI_ARESETN) ? 0 : n_count  ;
        r_tvalid <= (~S_AXI_ARESETN) ? 0 : n_tvalid ;
        r_tdata  <= (~S_AXI_ARESETN) ? 0 : n_tdata  ;
        r_tkeep  <= (~S_AXI_ARESETN) ? 0 : n_tkeep  ;
        r_tlast  <= (~S_AXI_ARESETN) ? 0 : n_tlast  ;
        r_last_keep <= (~S_AXI_ARESETN) ? 0 : n_last_keep;
    end // FF_SEND
    
    //---------------------------------------------------------------------
    // Primary Output Assignment
    //---------------------------------------------------------------------

    // Combo Out
    // Const Out
    // Reg   Out
    assign m_axis_tvalid = r_tvalid;
    assign m_axis_tdata  = r_tdata;
    assign m_axis_tkeep  = r_tkeep;
    assign m_axis_tlast  = r_tlast;

    initial begin
        r_state  <= 0; 
        r_len    <= 0;
        r_count  <= 0; 
        r_tvalid <= 0; 
        r_tdata  <= 0; 
        r_tkeep  <= 0; 
        r_tlast  <= 0; 
        r_last_keep <= 0;
        n_len    = 0;
        n_count  = 0; 
        n_tvalid = 0; 
        n_tdata  = 0; 
        n_tkeep  = 0; 
        n_tlast  = 0; 
        n_last_keep = 0;
    end
endmodule
