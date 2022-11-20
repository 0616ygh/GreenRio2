module rrv2rvh_ruby_ldmask_trans (
	ld_offset_i,
	ld_opcode_i,
	ls_pipe_l1d_ld_req_data_byte_mask_o
);
	localparam [31:0] rvh_pkg_L1D_LINE_SIZE = 64;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	input wire [5:0] ld_offset_i;
	localparam [31:0] uop_encoding_pkg_LDU_OP_WIDTH = 3;
	input wire [2:0] ld_opcode_i;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	output wire [63:0] ls_pipe_l1d_ld_req_data_byte_mask_o;
	wire [14:0] ld_opcode_dec;
	wire [63:0] ls_pipe_l1d_ld_req_data_byte_mask_mid;
	localparam [31:0] sv2v_uu_l1dc_dec_ruby_rvh_trans_u_uop_encoding_pkg_STU_OP_WIDTH = 5;
	localparam [4:0] sv2v_uu_l1dc_dec_ruby_rvh_trans_u_ext_ls_pipe_l1d_st_req_opcode_i_0 = 1'sb0;
	rvh_l1d_dec l1dc_dec_ruby_rvh_trans_u(
		.is_ld_req_vld_i(1'b1),
		.is_st_req_vld_i(1'b0),
		.ls_pipe_l1d_ld_req_opcode_i(ld_opcode_i),
		.ls_pipe_l1d_st_req_opcode_i(sv2v_uu_l1dc_dec_ruby_rvh_trans_u_ext_ls_pipe_l1d_st_req_opcode_i_0),
		.req_type_dec_o(ld_opcode_dec)
	);
	assign ls_pipe_l1d_ld_req_data_byte_mask_mid = (ld_opcode_dec[4] ? {{63 {1'b0}}, 1'b1} : (ld_opcode_dec[3] ? {{62 {1'b0}}, 2'b11} : (ld_opcode_dec[2] ? {{60 {1'b0}}, 4'b1111} : (ld_opcode_dec[1] ? {{56 {1'b0}}, 8'b11111111} : {64 {1'sb0}}))));
	assign ls_pipe_l1d_ld_req_data_byte_mask_o = ls_pipe_l1d_ld_req_data_byte_mask_mid << ld_offset_i;
endmodule
