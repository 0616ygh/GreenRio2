module rvh_l1d_alu (
	issue_opcode_i,
	issue_op_w_i,
	issue_operand0_i,
	issue_operand1_i,
	wb_data_o
);
	localparam [31:0] uop_encoding_pkg_ALU_OP_WIDTH = 4;
	input wire [3:0] issue_opcode_i;
	input wire issue_op_w_i;
	localparam [31:0] rvh_pkg_XLEN = 64;
	input wire [63:0] issue_operand0_i;
	input wire [63:0] issue_operand1_i;
	output wire [63:0] wb_data_o;
	wire is_slt_type;
	function automatic [3:0] sv2v_cast_8478D;
		input reg [3:0] inp;
		sv2v_cast_8478D = inp;
	endfunction
	assign is_slt_type = (issue_opcode_i == sv2v_cast_8478D(3)) | (issue_opcode_i == sv2v_cast_8478D(4));
	wire is_unsigned;
	wire is_sub;
	wire [65:0] adder_operand0;
	wire [65:0] adder_operand1;
	wire [rvh_pkg_XLEN:0] adder_operand1_comp;
	wire [rvh_pkg_XLEN:0] adder_result;
	wire adder_result_is_neg;
	assign is_sub = (((issue_opcode_i == sv2v_cast_8478D(1)) | (issue_opcode_i == sv2v_cast_8478D(11))) | (issue_opcode_i == sv2v_cast_8478D(3))) | (issue_opcode_i == sv2v_cast_8478D(4));
	assign is_unsigned = issue_opcode_i == sv2v_cast_8478D(4);
	assign adder_operand1_comp = {issue_operand1_i, 1'b0} ^ {65 {is_sub}};
	assign adder_operand0 = {~is_unsigned & issue_operand0_i[63], {issue_operand0_i[63:0]}, 1'b1};
	assign adder_operand1 = {~is_unsigned & issue_operand1_i[63], adder_operand1_comp};
	assign {adder_result_is_neg, adder_result} = adder_operand0 + adder_operand1;
	wire [63:0] add_rslt;
	function automatic [63:0] sv2v_cast_805AD;
		input reg [63:0] inp;
		sv2v_cast_805AD = inp;
	endfunction
	assign add_rslt = (is_slt_type ? {{63 {1'b0}}, ~adder_result_is_neg} : (issue_op_w_i ? sv2v_cast_805AD({{rvh_pkg_XLEN {adder_result[32]}}, adder_result[32:1]}) : adder_result[rvh_pkg_XLEN:1]));
	wire is_logic_shf;
	wire is_inv_shf;
	wire [63:0] rshf_data_inv;
	wire [rvh_pkg_XLEN:0] rshf_data_inv_fin;
	wire [rvh_pkg_XLEN:0] rshf_data_no_inv_fin;
	wire [rvh_pkg_XLEN:0] rshf_data;
	wire [rvh_pkg_XLEN:0] rshf_rslt;
	wire [63:0] rshf_rslt64_inv;
	wire [31:0] rshf_rslt32_inv;
	wire [5:0] rshf_amt;
	wire [63:0] shf_rslt;
	assign is_logic_shf = (((issue_opcode_i == sv2v_cast_8478D(2)) | (issue_opcode_i == sv2v_cast_8478D(6))) | (issue_opcode_i == sv2v_cast_8478D(12))) | (issue_opcode_i == sv2v_cast_8478D(13));
	assign is_inv_shf = (issue_opcode_i == sv2v_cast_8478D(2)) | (issue_opcode_i == sv2v_cast_8478D(12));
	genvar i;
	generate
		for (i = 0; i < rvh_pkg_XLEN; i = i + 1) begin : GEN_RSHF_DATA64_INV
			assign rshf_data_inv[i] = issue_operand0_i[63 - i];
			assign rshf_rslt64_inv[i] = rshf_rslt[63 - i];
		end
		for (i = 0; i < 32; i = i + 1) begin : GEN_RSHF_DATA32_INV
			assign rshf_rslt32_inv[i] = rshf_rslt[31 - i];
		end
	endgenerate
	assign rshf_amt = {(issue_op_w_i & is_inv_shf) | (~issue_op_w_i & issue_operand1_i[5]), issue_operand1_i[4:0]};
	assign rshf_data_inv_fin = {1'b0, rshf_data_inv};
	assign rshf_data_no_inv_fin = ((({65 {issue_op_w_i & is_logic_shf}} & {33'h000000000, issue_operand0_i[0+:32]}) | ({65 {issue_op_w_i & ~is_logic_shf}} & {{33 {issue_operand0_i[31]}}, issue_operand0_i[0+:32]})) | ({65 {~issue_op_w_i & is_logic_shf}} & {1'b0, issue_operand0_i})) | ({65 {~issue_op_w_i & ~is_logic_shf}} & {issue_operand0_i[63], issue_operand0_i});
	assign rshf_data = (is_inv_shf ? rshf_data_inv_fin : rshf_data_no_inv_fin);
	assign rshf_rslt = $signed(rshf_data) >>> rshf_amt;
	assign shf_rslt = ((({rvh_pkg_XLEN {issue_op_w_i & is_inv_shf}} & {{32 {rshf_rslt32_inv[31]}}, rshf_rslt32_inv[0+:32]}) | ({rvh_pkg_XLEN {issue_op_w_i & ~is_inv_shf}} & {{32 {rshf_rslt[31]}}, rshf_rslt[0+:32]})) | ({rvh_pkg_XLEN {~issue_op_w_i & is_inv_shf}} & rshf_rslt64_inv)) | ({rvh_pkg_XLEN {~issue_op_w_i & ~is_inv_shf}} & rshf_rslt[63:0]);
	wire is_or;
	wire is_and;
	wire is_xor;
	wire [63:0] result_xor;
	wire [63:0] result_and;
	wire [63:0] result_or;
	wire [63:0] logic_rslt;
	assign is_or = issue_opcode_i == sv2v_cast_8478D(8);
	assign is_and = issue_opcode_i == sv2v_cast_8478D(9);
	assign is_xor = issue_opcode_i == sv2v_cast_8478D(5);
	assign result_xor = issue_operand0_i ^ issue_operand1_i;
	assign result_and = issue_operand0_i & issue_operand1_i;
	assign result_or = issue_operand0_i | issue_operand1_i;
	assign logic_rslt = ((result_xor & {rvh_pkg_XLEN {is_xor}}) | (result_or & {rvh_pkg_XLEN {is_or}})) | (result_and & {rvh_pkg_XLEN {is_and}});
	wire is_add_type;
	wire is_shf_type;
	wire is_logic_type;
	assign is_logic_type = ((issue_opcode_i == sv2v_cast_8478D(9)) | (issue_opcode_i == sv2v_cast_8478D(8))) | (issue_opcode_i == sv2v_cast_8478D(5));
	assign is_shf_type = (is_logic_shf | (issue_opcode_i == sv2v_cast_8478D(7))) | (issue_opcode_i == sv2v_cast_8478D(14));
	assign is_add_type = ~(is_logic_type | is_shf_type);
	assign wb_data_o = (is_add_type ? add_rslt : ({rvh_pkg_XLEN {is_logic_type}} & logic_rslt) | ({rvh_pkg_XLEN {is_shf_type}} & shf_rslt));
endmodule
