module qemu_nic_bridge
#( parameter
    DATAW =  64        // data width in bits
,   DTMP  =  4096 
,   KEEPW = (DATAW/8)   // bit-to-byte map (always refer to DATAW)
)
(
    input                       refclk_p        // this is used as main clock of the bridge
,   input                       refclk_n        // not used

,   input                       tx_axis_aresetn // used as main reset of the bridge
,   input                       rx_axis_aresetn // not used

//    input                       S_AXI_ACLK
//,   input                       S_AXI_ARESETN

    // AXI Stream Slave : s_axis
,   input  [         DATAW-1:0] s_axis_tx_tdata
,   input  [         KEEPW-1:0] s_axis_tx_tkeep
,   input                       s_axis_tx_tlast
,   input                       s_axis_tx_tuser  // not used
,   input                       s_axis_tx_tvalid
,   output reg                  s_axis_tx_tready

    // AXI Stream Master:  m_axis
,   output reg [     DATAW-1:0] m_axis_rx_tdata
,   output reg [     KEEPW-1:0] m_axis_rx_tkeep
,   output reg                  m_axis_rx_tlast
,   output                      m_axis_rx_tuser  // not used
,   output reg                  m_axis_rx_tvalid
,   input                       m_axis_rx_tready // Not in real hardware

    // Not Used in Simulation Bridge: Input
,   input      [        16-1:0] s_axis_pause_tdata
,   input                       s_axis_pause_tvalid

,   input      [         8-1:0] tx_ifg_delay

,   input                       dclk

,   input                       rxp
,   input                       rxn

,   input                       signal_detect
,   input                       tx_fault
,   input                       sim_speedup_control
,   input      [        80-1:0] mac_tx_configuration_vector
,   input      [        80-1:0] mac_rx_configuration_vector
,   input      [       536-1:0] pcs_pma_configuration_vector

,   input                       reset

    // Not Used in Simulation Bridge: Output
,   output                      tx_statistics_valid
,   output      [       26-1:0] tx_statistics_vector

,   output                      rx_statistics_valid
,   output      [       30-1:0] rx_statistics_vector

,   output                      txp
,   output                      txn

,   output                      tx_disable
,   output      [        8-1:0] pcspma_status 
,   output                      rxrecclk_out
,   output      [        3-1:0] mac_status_vector
,   output      [      448-1:0] pcs_pma_status_vector

,   output                      areset_datapathclk_out
,   output                      txusrclk_out
,   output                      txusrclk2_out
,   output                      gttxreset_out
,   output                      gtrxreset_out
,   output                      txuserrdy_out
,   output                      coreclk_out
,   output                      resetdone_out
,   output                      reset_counter_done_out
,   output                      qplllock_out
,   output                      qplloutclk_out
,   output                      qplloutrefclk_out


    //==================================
    // Unused Signals
    //==================================
);


    import "DPI-C" function void    C_nic_poll(output byte req, output int len, output longint strobe, output byte data[0:DTMP-1]);
    import "DPI-C" function void    C_setup_nic_connection(input int bus_width);
    
    byte m_i_req;
    byte m_i_data[0:DTMP-1];
    int m_i_len, m_i_last_keep;
    int i;
    logic busy;

    assign tx_statistics_valid      = 0;
    assign tx_statistics_vector     = 0;
    assign rx_statistics_valid      = 0;
    assign rx_statistics_vector     = 0;
    assign txp                      = 0;
    assign txn                      = 0;
    assign tx_disable               = 0;
    assign pcspma_status            = 0;
    assign rxrecclk_out             = 0;
    assign mac_status_vector        = 0;
    assign pcs_pma_status_vector    = 0;
    assign areset_datapathclk_out   = 0;
    assign txusrclk_out             = 0;
    assign txusrclk2_out            = 0;
    assign gttxreset_out            = 0;
    assign gtrxreset_out            = 0;
    assign txuserrdy_out            = 0;
    assign coreclk_out              = refclk_p;
    assign resetdone_out            = 0;
    assign reset_counter_done_out   = 0;
    assign qplllock_out             = 0;
    assign qplloutclk_out           = 0;
    assign qplloutrefclk_out        = 0;

    wire S_AXI_ACLK    = refclk_p;
    wire S_AXI_ARESETN = tx_axis_aresetn;

    always@(posedge S_AXI_ACLK) begin
        if (busy == 0) begin
            C_nic_poll(m_i_req, m_i_len, m_i_last_keep, m_i_data);
        end
    end


    //---------------------------------------------------------------------
    // Instance
    //---------------------------------------------------------------------

    axis_m #(
        DATAW,
        KEEPW,
        DTMP
    )
    axis_m_inst (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .busy(busy),
        .m_axis_tdata (m_axis_rx_tdata ), 
        .m_axis_tkeep (m_axis_rx_tkeep ), 
        .m_axis_tlast (m_axis_rx_tlast ), 
        .m_axis_tvalid(m_axis_rx_tvalid),
        .m_axis_tready(m_axis_rx_tready),
        .i_req(m_i_req),
        .i_data(m_i_data),
        .i_len(m_i_len),
        .i_last_keep(m_i_last_keep)
    );

    axis_s #(
        DATAW,
        KEEPW,
        DTMP
    )
    axis_s_inst (
        .S_AXI_ACLK(S_AXI_ACLK),
        .S_AXI_ARESETN(S_AXI_ARESETN),
        .s_axis_tdata (s_axis_tx_tdata ), 
        .s_axis_tkeep (s_axis_tx_tkeep ), 
        .s_axis_tlast (s_axis_tx_tlast ), 
        .s_axis_tvalid(s_axis_tx_tvalid),
        .s_axis_tready(s_axis_tx_tready) 
    );

    initial begin
        C_setup_nic_connection(KEEPW);
        for (i = 0; i < DTMP; i++) begin
            m_i_data[i] = 0;
        end
    end
endmodule
