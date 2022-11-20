// `ifndef SYNTHESIS
module generic_spram
#(
    parameter int unsigned w = 8, // data width
    parameter int unsigned p = 8, // word partition size (data bits per write enable)
    parameter int unsigned d = 8, // data depth
    parameter int unsigned log2d = 3, // address width
    parameter int unsigned id = 0, // unique value per instance

    parameter RAM_LATENCY = 1,
    parameter RESET       = 0,
    parameter RESET_HIGH  = 0
)
(
    clk     ,
    ce      ,
    we      ,
    biten   ,
    addr    ,
    din     ,
    dout    
);


localparam ADDR_BITS = log2d;
localparam DATA_BITS = w;
localparam MASK_BITS = w/p;


input                               clk;
input                               ce;
input                               we;
input [MASK_BITS-1 :0]              biten;
input [ADDR_BITS-1 :0]              addr;
input [DATA_BITS-1 :0]              din;
output[DATA_BITS-1 :0]              dout;

wire   [MASK_BITS-1:0]    sim_biten;
wire   [DATA_BITS-1:0]    sim_real_biten; // bit enable
genvar i;
generate
    for(i = 0; i < MASK_BITS; i++) begin
        assign sim_real_biten[i*p+:p] = {p{sim_biten[i]}};
    end
endgenerate

assign sim_biten = we ? biten : 'b0;

rrv64_generic_ram #(
    .ADDR_BITS          (ADDR_BITS),
    .DATA_BITS          (DATA_BITS),
    .RAM_LATENCY        (RAM_LATENCY),
    // .WE_SIZE            (MASK_BITS),
    .RESET              (RESET    ),
    .RESET_HIGH         (RESET_HIGH)
)
generic_ram_u(
    .clk                (clk      ),
    .addr_i             (addr     ),
    .rd_o               (dout     ),
    .wd_i               (din      ),
    .cs_i               (ce       ),
    .we_i               (sim_real_biten)
);

//sky130_sram_1kbyte_1rw1r_32x256_8

endmodule

// `endif