module rvh_l1d_alu (
	issue_opcode_i,
	issue_op_w_i,
	issue_operand0_i,
	issue_operand1_i,
	wb_data_o
);
	parameter ALU_OP_WIDTH = 4;
	parameter XLEN = 64;
	input wire [ALU_OP_WIDTH - 1:0] issue_opcode_i;
	input wire issue_op_w_i;
	input wire [XLEN - 1:0] issue_operand0_i;
	input wire [XLEN - 1:0] issue_operand1_i;
	output wire [XLEN - 1:0] wb_data_o;
	wire is_slt_type;
	assign is_slt_type = (issue_opcode_i == 5'd12) | (issue_opcode_i == 5'd13);
	wire is_unsigned;
	wire is_sub;
	wire [XLEN + 1:0] adder_operand0;
	wire [XLEN + 1:0] adder_operand1;
	wire [XLEN:0] adder_operand1_comp;
	wire [XLEN:0] adder_result;
	wire adder_result_is_neg;
	assign is_sub = (((issue_opcode_i == 5'd19) | (issue_opcode_i == 5'd29)) | (issue_opcode_i == 5'd12)) | (issue_opcode_i == 5'd13);
	assign is_unsigned = issue_opcode_i == 5'd13;
	assign adder_operand1_comp = {issue_operand1_i, 1'b0} ^ {XLEN + 1 {is_sub}};
	assign adder_operand0 = {~is_unsigned & issue_operand0_i[XLEN - 1], {issue_operand0_i[XLEN - 1:0]}, 1'b1};
	assign adder_operand1 = {~is_unsigned & issue_operand1_i[XLEN - 1], adder_operand1_comp};
	assign {adder_result_is_neg, adder_result} = adder_operand0 + adder_operand1;
	wire [XLEN - 1:0] add_rslt;
	function automatic [XLEN - 1:0] sv2v_cast_16FF7;
		input reg [XLEN - 1:0] inp;
		sv2v_cast_16FF7 = inp;
	endfunction
	assign add_rslt = (is_slt_type ? {{XLEN - 1 {1'b0}}, ~adder_result_is_neg} : (issue_op_w_i ? sv2v_cast_16FF7({{XLEN {adder_result[32]}}, adder_result[32:1]}) : adder_result[XLEN:1]));
	wire is_logic_shf;
	wire is_inv_shf;
	wire [XLEN - 1:0] rshf_data_inv;
	wire [XLEN:0] rshf_data_inv_fin;
	wire [XLEN:0] rshf_data_no_inv_fin;
	wire [XLEN:0] rshf_data;
	wire [XLEN:0] rshf_rslt;
	wire [XLEN - 1:0] rshf_rslt64_inv;
	wire [31:0] rshf_rslt32_inv;
	wire [7:0] rshf_amt;
	wire [XLEN - 1:0] shf_rslt;
	assign is_logic_shf = (((issue_opcode_i == 5'd17) | (issue_opcode_i == 5'd18)) | (issue_opcode_i == 5'd27)) | (issue_opcode_i == 5'd28);
	assign is_inv_shf = (issue_opcode_i == 5'd17) | (issue_opcode_i == 5'd27);
	genvar i;
	generate
		for (i = 0; i < XLEN; i = i + 1) begin : GEN_RSHF_DATA64_INV
			assign rshf_data_inv[i] = issue_operand0_i[(XLEN - 1) - i];
			assign rshf_rslt64_inv[i] = rshf_rslt[(XLEN - 1) - i];
		end
		for (i = 0; i < 32; i = i + 1) begin : GEN_RSHF_DATA32_INV
			assign rshf_rslt32_inv[i] = rshf_rslt[31 - i];
		end
	endgenerate
	assign rshf_amt = {(issue_op_w_i & is_inv_shf) | (~issue_op_w_i & issue_operand1_i[5]), issue_operand1_i[4:0]};
	assign rshf_data_inv_fin = {1'b0, rshf_data_inv};
	assign rshf_data_no_inv_fin = ((({XLEN + 1 {issue_op_w_i & is_logic_shf}} & {33'h000000000, issue_operand0_i[0+:32]}) | ({XLEN + 1 {issue_op_w_i & ~is_logic_shf}} & {{33 {issue_operand0_i[31]}}, issue_operand0_i[0+:32]})) | ({XLEN + 1 {~issue_op_w_i & is_logic_shf}} & {1'b0, issue_operand0_i})) | ({XLEN + 1 {~issue_op_w_i & ~is_logic_shf}} & {issue_operand0_i[63], issue_operand0_i});
	assign rshf_data = (is_inv_shf ? rshf_data_inv_fin : rshf_data_no_inv_fin);
	assign rshf_rslt = $signed(rshf_data) >>> rshf_amt;
	assign shf_rslt = ((({XLEN {issue_op_w_i & is_inv_shf}} & {{32 {rshf_rslt32_inv[31]}}, rshf_rslt32_inv[0+:32]}) | ({XLEN {issue_op_w_i & ~is_inv_shf}} & {{32 {rshf_rslt[31]}}, rshf_rslt[0+:32]})) | ({XLEN {~issue_op_w_i & is_inv_shf}} & rshf_rslt64_inv)) | ({XLEN {~issue_op_w_i & ~is_inv_shf}} & rshf_rslt[XLEN - 1:0]);
	wire is_or;
	wire is_and;
	wire is_xor;
	wire [XLEN - 1:0] result_xor;
	wire [XLEN - 1:0] result_and;
	wire [XLEN - 1:0] result_or;
	wire [XLEN - 1:0] logic_rslt;
	assign is_or = issue_opcode_i == 5'd15;
	assign is_and = issue_opcode_i == 5'd14;
	assign is_xor = issue_opcode_i == 5'd16;
	assign result_xor = issue_operand0_i ^ issue_operand1_i;
	assign result_and = issue_operand0_i & issue_operand1_i;
	assign result_or = issue_operand0_i | issue_operand1_i;
	assign logic_rslt = ((result_xor & {XLEN {is_xor}}) | (result_or & {XLEN {is_or}})) | (result_and & {XLEN {is_and}});
	wire is_add_type;
	wire is_shf_type;
	wire is_logic_type;
	assign is_logic_type = ((issue_opcode_i == 5'd14) | (issue_opcode_i == 5'd15)) | (issue_opcode_i == 5'd16);
	assign is_shf_type = (is_logic_shf | (issue_opcode_i == 5'd20)) | (issue_opcode_i == 5'd30);
	assign is_add_type = ~(is_logic_type | is_shf_type);
	assign wb_data_o = (is_add_type ? add_rslt : ({XLEN {is_logic_type}} & logic_rslt) | ({XLEN {is_shf_type}} & shf_rslt));
endmodule
