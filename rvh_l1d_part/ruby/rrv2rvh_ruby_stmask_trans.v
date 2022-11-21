module rrv2rvh_ruby_stmask_trans (
	st_dat_i,
	st_offset_i,
	st_opcode_i,
	ls_pipe_l1d_st_req_data_o,
	ls_pipe_l1d_st_req_data_byte_mask_o
);
	localparam rrv64_core_param_pkg_RRV64_INT_REG_DATA_W = 64;
	input wire [63:0] st_dat_i;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	input wire [5:0] st_offset_i;
	localparam [31:0] rvh_l1d_pkg_STU_OP_WIDTH = 5;
	input wire [4:0] st_opcode_i;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	output wire [511:0] ls_pipe_l1d_st_req_data_o;
	output wire [63:0] ls_pipe_l1d_st_req_data_byte_mask_o;
	wire [14:0] st_opcode_dec;
	wire [511:0] ls_pipe_l1d_st_req_data_mid;
	wire [63:0] ls_pipe_l1d_st_req_data_byte_mask_mid;
	localparam [31:0] sv2v_uu_l1dc_dec_ruby_rvh_trans_u_rvh_l1d_pkg_LDU_OP_WIDTH = 3;
	localparam [2:0] sv2v_uu_l1dc_dec_ruby_rvh_trans_u_ext_ls_pipe_l1d_ld_req_opcode_i_0 = 1'sb0;
	rvh_l1d_dec l1dc_dec_ruby_rvh_trans_u(
		.is_ld_req_vld_i(1'b0),
		.is_st_req_vld_i(1'b1),
		.ls_pipe_l1d_ld_req_opcode_i(sv2v_uu_l1dc_dec_ruby_rvh_trans_u_ext_ls_pipe_l1d_ld_req_opcode_i_0),
		.ls_pipe_l1d_st_req_opcode_i(st_opcode_i),
		.req_type_dec_o(st_opcode_dec)
	);
	assign ls_pipe_l1d_st_req_data_mid = {{448 {1'b1}}, st_dat_i};
	assign ls_pipe_l1d_st_req_data_o = ls_pipe_l1d_st_req_data_mid << (st_offset_i * 8);
	assign ls_pipe_l1d_st_req_data_byte_mask_mid = (st_opcode_dec[4] ? {{63 {1'b0}}, 1'b1} : (st_opcode_dec[3] ? {{62 {1'b0}}, 2'b11} : (st_opcode_dec[2] ? {{60 {1'b0}}, 4'b1111} : (st_opcode_dec[1] ? {{56 {1'b0}}, 8'b11111111} : {64 {1'sb0}}))));
	assign ls_pipe_l1d_st_req_data_byte_mask_o = ls_pipe_l1d_st_req_data_byte_mask_mid << st_offset_i;
endmodule
