module physical_regfile #(
    parameter REG_SIZE = 64,
    parameter REG_SIZE_WIDTH = 6
)
(
    input clk,
    // from rcu (read ports)
    input [REG_SIZE_WIDTH-1:0] prs1_address_first_i,
    input [REG_SIZE_WIDTH-1:0] prs2_address_first_i,
    input [REG_SIZE_WIDTH-1:0] prs1_address_second_i,
    input [REG_SIZE_WIDTH-1:0] prs2_address_second_i,
    // to rcu (read ports)
    output reg [63:0] prs1_data_first_o,
    output reg [63:0] prs2_data_first_o,
    output reg [63:0] prs1_data_second_o,
    output reg [63:0] prs2_data_second_o,
    // Quadruple write port
    input [REG_SIZE_WIDTH-1:0] alu1_wrb_address_i,
    input [REG_SIZE_WIDTH-1:0] alu2_wrb_address_i,
    input [REG_SIZE_WIDTH-1:0] lsu_wrb_address_i,
    input [REG_SIZE_WIDTH-1:0] md_wrb_address_i,
    input [63:0] alu1_wrb_data_i,
    input [63:0] alu2_wrb_data_i,
    input [63:0] lsu_wrb_data_i,
    input [63:0] md_wrb_data_i,
    input alu1_rcu_resp_valid_i,
    input alu2_rcu_resp_valid_i,
    input lsu_rcu_resp_valid_i,
    input md_rcu_resp_valid_i
);

    reg [63:0] registers [0:REG_SIZE-1];
    integer i;
    //P0 is always 0 and its finish bit is 1

    //reg read
    always @(*) begin
        prs1_data_first_o = registers[prs1_address_first_i];
        prs2_data_first_o = registers[prs2_address_first_i];
        prs1_data_second_o = registers[prs1_address_second_i];
        prs2_data_second_o = registers[prs2_address_second_i];
    end

    //reg write
    always @(posedge clk) begin
            if (alu1_rcu_resp_valid_i) begin
                registers[alu1_wrb_address_i] <= (alu1_wrb_address_i == '0)? 64'b0 : alu1_wrb_data_i;
            end
            if (alu2_rcu_resp_valid_i) begin
                registers[alu2_wrb_address_i] <= (alu2_wrb_address_i == '0)? 64'b0 : alu2_wrb_data_i;
            end
            if (lsu_rcu_resp_valid_i) begin
                registers[lsu_wrb_address_i] <= (lsu_wrb_address_i == '0)? 64'b0 : lsu_wrb_data_i;
            end
            if (md_rcu_resp_valid_i) begin
                registers[md_wrb_address_i] <= (md_wrb_address_i == '0)? 64'b0 : md_wrb_data_i;
            end
    end
 
endmodule : physical_regfile
