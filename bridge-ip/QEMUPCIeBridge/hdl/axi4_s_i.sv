
`timescale 1ns/100ps
module axi4_s_i
#(
    parameter   TAGW            = 3
,               ADRW            = 64
,               DATW            = 512
,               SIZE            = 3'b010        // always refer to DATW
,               STBW            = (DATW/8)
,               DTMP            = 4096
)
(
    input                       i_clk
,   input                       i_rst_n

//INTERRUPT (MSI: not used)
,   input                       intx_msi_request
,   output                      interrupt_out
,   output                      intx_msi_grant

//INTERRUPT 
// (MSI-X: for QEMU, get one-hot IRQ# from msix_data, send out binary as vector)
,   input  [           64 -1:0] cfg_interrupt_msix_address
,   input  [           32 -1:0] cfg_interrupt_msix_data     // one hot of IRQ#
,   output [            4 -1:0] cfg_interrupt_msix_enable
,   output                      cfg_interrupt_msix_fail
,   input                       cfg_interrupt_msix_int      // must be a pulse
,   output [            4 -1:0] cfg_interrupt_msix_mask
,   output                      cfg_interrupt_msix_sent
,   output [            8 -1:0] cfg_interrupt_msix_vf_enable
,   output [            8 -1:0] cfg_interrupt_msix_vf_mask
);

    reg    [           32 -1:0] vector;
    reg                         irq_d1t, irq_d2t ;

    logic  [           32 -1:0] cfg_interrupt_msix_data;  // one hot of IRQ#

    always@(*)
    begin
        case(cfg_interrupt_msix_data)
            32'h00000001: vector    = 32'd00;
            32'h00000002: vector    = 32'd01;
            32'h00000004: vector    = 32'd02;
            32'h00000008: vector    = 32'd03;
            32'h00000010: vector    = 32'd04;
            32'h00000020: vector    = 32'd05;
            32'h00000040: vector    = 32'd06;
            32'h00000080: vector    = 32'd07;
            32'h00000100: vector    = 32'd08;
            32'h00000200: vector    = 32'd09;
            32'h00000400: vector    = 32'd10;
            32'h00000800: vector    = 32'd11;
            32'h00001000: vector    = 32'd12;
            32'h00002000: vector    = 32'd13;
            32'h00004000: vector    = 32'd14;
            32'h00008000: vector    = 32'd15;
            32'h00010000: vector    = 32'd16;
            32'h00020000: vector    = 32'd17;
            32'h00040000: vector    = 32'd18;
            32'h00080000: vector    = 32'd19;
            32'h00100000: vector    = 32'd20;
            32'h00200000: vector    = 32'd21;
            32'h00400000: vector    = 32'd22;
            32'h00800000: vector    = 32'd23;
            32'h01000000: vector    = 32'd24;
            32'h02000000: vector    = 32'd25;
            32'h04000000: vector    = 32'd26;
            32'h08000000: vector    = 32'd27;
            32'h10000000: vector    = 32'd28;
            32'h20000000: vector    = 32'd29;
            32'h40000000: vector    = 32'd30;
            32'h80000000: vector    = 32'd31;
            default     : vector    = 32'hFFFFFFFF;
        endcase // cfg_interrupt_msix_data
    end

    import "DPI-C" function void     C_req_interrupt(input int vector);
    
    always@(posedge cfg_interrupt_msix_int)
    begin: INTR
        if ( i_rst_n ) begin
            C_req_interrupt(vector);
        end
    end

    always@(posedge i_clk or negedge i_rst_n)
    begin
        irq_d1t     <= (~i_rst_n)   ? 0 : cfg_interrupt_msix_int;
        irq_d2t     <= (~i_rst_n)   ? 0 : irq_d1t;
    end

    assign  interrupt_out                   = 0;
    assign  intx_msi_grant                  = 1;

    assign  cfg_interrupt_msix_enable       = 1;
    assign  cfg_interrupt_msix_fail         = 0;
    assign  cfg_interrupt_msix_mask         = 0;
    assign  cfg_interrupt_msix_sent         = irq_d2t;
    assign  cfg_interrupt_msix_vf_enable    = 0;
    assign  cfg_interrupt_msix_vf_mask      = 0;

endmodule
