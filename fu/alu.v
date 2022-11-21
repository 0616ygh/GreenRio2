`ifdef VERILATOR
`include "params.vh"
`endif
module alu(
input clk,
input rstn,
input wfi,
input trap,

input [XLEN - 1:0] opr1_i,
input [XLEN - 1:0] opr2_i,
input half_i,
input [2:0] alu_function_select_i,  //alu_function_out要
input function_modifier_i,
input [ROB_INDEX_WIDTH - 1:0] rob_index_i,
input [PHY_REG_ADDR_WIDTH - 1 : 0] prd_addr_i,
input rcu_fu_alu_req_valid_i,
// no ready signal, because alu is always ready

// branch
input [XLEN - 1 : 0] cmp_input_a_i,
input [XLEN - 1 : 0] cmp_input_b_i,
input [2:0] cmp_function_select_i,
input is_jump_i,
input is_branch_i,
input [VIRTUAL_ADDR_LEN-1 : 0] pc_i,
input [VIRTUAL_ADDR_LEN - 1 : 0] next_pc_i,  //pc + 4
output reg is_jump_o,           //jump and branch instr
output reg is_branch_o,
output reg [VIRTUAL_ADDR_LEN - 1 : 0] pc_o,
output reg [VIRTUAL_ADDR_LEN - 1 : 0] next_pc_o,


// 1st cycle output
// output [XLEN - 1:0] add_result,
output reg fu_rcu_alu_resp_valid_o,         //done
output reg [PHY_REG_ADDR_WIDTH-1:0] prd_addr_o,
output reg [ROB_INDEX_WIDTH - 1:0] rob_index_o,
// 2nd cycle output
output reg [XLEN - 1:0] alu_result_o, 
output reg cmp_result_o
);


reg quasi_result;
reg negate;
reg usign;
reg less;
reg is_equal;
reg is_less;
reg [XLEN - 1 : 0] alu_result_add_sub_half_w;
reg [XLEN - 1 : 0] alu_result_add_sub_w;
reg [XLEN - 1 : 0] alu_result_sll_half_w;
reg [XLEN - 1 : 0] alu_result_sll_w;
reg [XLEN - 1 : 0] alu_result_slt_w;
reg [XLEN - 1 : 0] alu_result_xor_w;
reg [XLEN - 1 : 0] alu_result_srl_sra_half_w;
reg [XLEN - 1 : 0] alu_result_srl_sra_w;
reg [XLEN - 1 : 0] alu_result_and_clr_w;
reg [XLEN - 1 : 0] alu_result_or_w;
reg branch_w;
reg jump_w;
reg valid_w;
reg cmp_result_w;
reg [64:0] tmp_shifted;
reg [32:0] tmp_shiftedw;
reg [XLEN - 1 : 0] sllw_w;
reg [XLEN - 1 : 0] alu_input_a, alu_input_b;
always @(*) begin
    alu_input_a = opr1_i;
    alu_input_b = opr2_i;
    //control logic wire
    valid_w = !trap & rcu_fu_alu_req_valid_i;
    jump_w = is_jump_i & rcu_fu_alu_req_valid_i;
    branch_w = is_branch_i & rcu_fu_alu_req_valid_i;
    //cmp result(wire)
    less = cmp_function_select_i[2];   // 小于或者大于
    usign = cmp_function_select_i[1];  //unsigned
    negate = cmp_function_select_i[0]; // 语义相反
    is_equal = (cmp_input_a_i == cmp_input_b_i);
    is_less = ($signed({usign ? 1'b0 : cmp_input_a_i[63], cmp_input_a_i}) < $signed({usign ? 1'b0 : cmp_input_b_i[63], cmp_input_b_i}));
    quasi_result = less ? is_less : is_equal;
    cmp_result_w = negate ? !quasi_result : quasi_result;
    //alu result(wire)
    alu_result_add_sub_w = alu_input_a + (function_modifier_i ? -alu_input_b : alu_input_b);
    alu_result_add_sub_half_w = {{32{alu_result_add_sub_w[31]}}, alu_result_add_sub_w[31:0]}; //64 modified

    alu_result_sll_w = alu_input_a << alu_input_b[5:0];
    sllw_w = alu_input_a << alu_input_b[4:0];
    alu_result_sll_half_w = {{32{sllw_w[31]}}, sllw_w[31:0]};
    
    alu_result_slt_w = {
        {63{1'b0}},
        (
            $signed({alu_function_select_i[0] ? 1'b0 : alu_input_a[63], alu_input_a})
            < $signed({alu_function_select_i[0] ? 1'b0 : alu_input_b[63], alu_input_b})
        )
    }; 
    
    tmp_shifted = ($signed({function_modifier_i ? alu_input_a[63] : 1'b0, alu_input_a}) >>> alu_input_b[5:0]);
    tmp_shiftedw = ($signed({function_modifier_i ? alu_input_a[31] : 1'b0, alu_input_a[31:0]}) >>> alu_input_b[4:0]);
    alu_result_srl_sra_w = tmp_shifted[63:0];
    alu_result_srl_sra_half_w = {{32{tmp_shiftedw[31]}}, tmp_shiftedw[31:0]};
    alu_result_xor_w = alu_input_a ^ alu_input_b;
    alu_result_or_w = alu_input_a | alu_input_b;
    alu_result_and_clr_w = (function_modifier_i ? ~alu_input_a : alu_input_a) & alu_input_b;

end

always @(*) begin
        alu_result_o = '0; 

        fu_rcu_alu_resp_valid_o = valid_w;
        prd_addr_o = prd_addr_i;
        is_jump_o = jump_w & valid_w;
        is_branch_o = branch_w & valid_w;
        pc_o = pc_i;
        next_pc_o = next_pc_i;
        rob_index_o = rob_index_i;
        case (alu_function_select_i)
            ALU_ADD_SUB: if(half_i) begin
                alu_result_o = alu_result_add_sub_half_w; //64 modified
            end else begin
                alu_result_o = alu_result_add_sub_w;
            end
            ALU_SLL:     if(half_i) begin
                alu_result_o = alu_result_sll_half_w;
            end else begin 
                alu_result_o = alu_result_sll_w;
            end
            ALU_SLT,
            ALU_SLTU:    alu_result_o = alu_result_slt_w; 
            ALU_XOR:     alu_result_o = alu_result_xor_w;
            ALU_SRL_SRA: if(half_i) begin
                alu_result_o = alu_result_srl_sra_half_w;
            end else begin
                alu_result_o = alu_result_srl_sra_w;
            end
            ALU_OR:      alu_result_o = alu_result_or_w;
            ALU_AND_CLR: alu_result_o = alu_result_and_clr_w;
        endcase
        cmp_result_o = cmp_result_w;
end

endmodule

