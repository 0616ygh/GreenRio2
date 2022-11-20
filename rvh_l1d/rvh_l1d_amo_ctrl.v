module rvh_l1d_amo_ctrl (
	ls_pipe_amo_ctrl_st_req_vld_i,
	ls_pipe_amo_ctrl_st_req_is_fence_i,
	ls_pipe_amo_ctrl_st_req_rob_tag_i,
	ls_pipe_amo_ctrl_st_req_prd_i,
	ls_pipe_amo_ctrl_st_req_opcode_i,
	ls_pipe_amo_ctrl_st_req_paddr_i,
	ls_pipe_amo_ctrl_st_req_data_i,
	ls_pipe_amo_ctrl_st_req_rdy_o,
	amo_ctrl_stb_st_req_vld_o,
	amo_ctrl_stb_st_req_is_fence_o,
	amo_ctrl_stb_st_req_no_fence_wb_resp_o,
	amo_ctrl_stb_st_req_sc_rt_check_succ_o,
	amo_ctrl_stb_st_req_rob_tag_o,
	amo_ctrl_stb_st_req_prd_o,
	amo_ctrl_stb_st_req_opcode_o,
	amo_ctrl_stb_st_req_paddr_o,
	amo_ctrl_stb_st_req_data_o,
	amo_ctrl_stb_st_req_rdy_i,
	l1d_rob_wb_vld_i,
	l1d_rob_wb_rob_tag_i,
	in_amo_state_o,
	clk,
	rst
);
	parameter [31:0] N_STB_ST_IN_PORT = 2;
	input wire [N_STB_ST_IN_PORT - 1:0] ls_pipe_amo_ctrl_st_req_vld_i;
	input wire [N_STB_ST_IN_PORT - 1:0] ls_pipe_amo_ctrl_st_req_is_fence_i;
	localparam [31:0] rvh_pkg_ROB_BLOCK_PER_ENTRY = 1;
	localparam [31:0] rvh_pkg_ROB_SIZE = 16;
	localparam [31:0] rvh_pkg_ROB_ENTRY_COUNT = rvh_pkg_ROB_SIZE / rvh_pkg_ROB_BLOCK_PER_ENTRY;
	localparam [31:0] rvh_pkg_ROB_INDEX_WIDTH = $clog2(rvh_pkg_ROB_ENTRY_COUNT);
	localparam [31:0] rvh_pkg_ROB_TAG_WIDTH = rvh_pkg_ROB_INDEX_WIDTH;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_amo_ctrl_st_req_rob_tag_i;
	localparam [31:0] rvh_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_pkg_PREG_TAG_WIDTH = rvh_pkg_INT_PREG_TAG_WIDTH;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_amo_ctrl_st_req_prd_i;
	localparam [31:0] uop_encoding_pkg_STU_OP_WIDTH = 5;
	input wire [(N_STB_ST_IN_PORT * uop_encoding_pkg_STU_OP_WIDTH) - 1:0] ls_pipe_amo_ctrl_st_req_opcode_i;
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_PADDR_WIDTH) - 1:0] ls_pipe_amo_ctrl_st_req_paddr_i;
	localparam [31:0] rvh_pkg_XLEN = 64;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_XLEN) - 1:0] ls_pipe_amo_ctrl_st_req_data_i;
	output wire [N_STB_ST_IN_PORT - 1:0] ls_pipe_amo_ctrl_st_req_rdy_o;
	output wire [N_STB_ST_IN_PORT - 1:0] amo_ctrl_stb_st_req_vld_o;
	output wire [N_STB_ST_IN_PORT - 1:0] amo_ctrl_stb_st_req_is_fence_o;
	output wire amo_ctrl_stb_st_req_no_fence_wb_resp_o;
	output wire amo_ctrl_stb_st_req_sc_rt_check_succ_o;
	output wire [(N_STB_ST_IN_PORT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] amo_ctrl_stb_st_req_rob_tag_o;
	output wire [(N_STB_ST_IN_PORT * rvh_pkg_PREG_TAG_WIDTH) - 1:0] amo_ctrl_stb_st_req_prd_o;
	output wire [(N_STB_ST_IN_PORT * uop_encoding_pkg_STU_OP_WIDTH) - 1:0] amo_ctrl_stb_st_req_opcode_o;
	output wire [(N_STB_ST_IN_PORT * rvh_pkg_PADDR_WIDTH) - 1:0] amo_ctrl_stb_st_req_paddr_o;
	output wire [(N_STB_ST_IN_PORT * rvh_pkg_XLEN) - 1:0] amo_ctrl_stb_st_req_data_o;
	input wire [N_STB_ST_IN_PORT - 1:0] amo_ctrl_stb_st_req_rdy_i;
	localparam [31:0] rvh_pkg_LSU_DATA_PIPE_COUNT = 2;
	input wire [1:0] l1d_rob_wb_vld_i;
	input wire [(rvh_pkg_LSU_DATA_PIPE_COUNT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] l1d_rob_wb_rob_tag_i;
	output reg in_amo_state_o;
	input wire clk;
	input wire rst;
	genvar i;
	wire [N_STB_ST_IN_PORT - 1:0] st_req_is_amo_req;
	wire receive_amo_req_hsk;
	wire send_stb_req_hsk;
	wire bank_amo_resp_vld;
	reg send_stb_flush_req_vld;
	reg send_amo_req_vld;
	reg waiting_for_amo_resp;
	reg [2:0] amo_ctrl_fsm_state_d;
	wire [2:0] amo_ctrl_fsm_state_q;
	reg amo_ctrl_fsm_state_ena;
	wire [((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1:0] amo_req_d;
	wire [((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1:0] amo_req_q;
	reg amo_req_ena;
	wire reservation_table_valid_d;
	wire reservation_table_valid_q;
	wire reservation_table_valid_clr;
	wire reservation_table_valid_set;
	wire reservation_table_valid_ena;
	wire [55:0] reservation_table_d;
	wire [55:0] reservation_table_q;
	wire reservation_table_ena;
	function automatic [4:0] sv2v_cast_038DB;
		input reg [4:0] inp;
		sv2v_cast_038DB = inp;
	endfunction
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_is_amo_req
			assign st_req_is_amo_req[i] = (((((((((((((((((((((ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(7)) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(8))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(9))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(10))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(11))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(12))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(13))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(14))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(15))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(16))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(17))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(18))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(19))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(20))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(21))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(22))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(23))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(24))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(25))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(26))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(27))) | (ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(28));
		end
	endgenerate
	assign amo_ctrl_stb_st_req_no_fence_wb_resp_o = in_amo_state_o;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_amo_ctrl_stb_st_req
			if (i == 0) begin : gen_is_amo_req_first_port
				assign amo_ctrl_stb_st_req_is_fence_o[i] = (in_amo_state_o ? send_stb_flush_req_vld : ls_pipe_amo_ctrl_st_req_is_fence_i[i]);
				assign amo_ctrl_stb_st_req_rob_tag_o[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = (in_amo_state_o ? amo_req_q[rvh_pkg_ROB_TAG_WIDTH + 132-:((rvh_pkg_ROB_TAG_WIDTH + 132) >= 133 ? rvh_pkg_ROB_TAG_WIDTH : 134 - (rvh_pkg_ROB_TAG_WIDTH + 132))] : ls_pipe_amo_ctrl_st_req_rob_tag_i[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH]);
				assign amo_ctrl_stb_st_req_prd_o[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH] = (in_amo_state_o ? amo_req_q[132-:32'd6] : ls_pipe_amo_ctrl_st_req_prd_i[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH]);
				assign amo_ctrl_stb_st_req_opcode_o[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] = (in_amo_state_o ? amo_req_q[126-:5] : ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH]);
				assign amo_ctrl_stb_st_req_paddr_o[i * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH] = (in_amo_state_o ? amo_req_q[121-:56] : ls_pipe_amo_ctrl_st_req_paddr_i[i * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH]);
				assign amo_ctrl_stb_st_req_data_o[i * rvh_pkg_XLEN+:rvh_pkg_XLEN] = (in_amo_state_o ? amo_req_q[65-:64] : ls_pipe_amo_ctrl_st_req_data_i[i * rvh_pkg_XLEN+:rvh_pkg_XLEN]);
			end
			else begin : gen_is_amo_req_other_port
				assign amo_ctrl_stb_st_req_is_fence_o[i] = ls_pipe_amo_ctrl_st_req_is_fence_i[i];
				assign amo_ctrl_stb_st_req_rob_tag_o[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = ls_pipe_amo_ctrl_st_req_rob_tag_i[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
				assign amo_ctrl_stb_st_req_prd_o[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH] = ls_pipe_amo_ctrl_st_req_prd_i[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
				assign amo_ctrl_stb_st_req_opcode_o[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH] = ls_pipe_amo_ctrl_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH];
				assign amo_ctrl_stb_st_req_paddr_o[i * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH] = ls_pipe_amo_ctrl_st_req_paddr_i[i * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH];
				assign amo_ctrl_stb_st_req_data_o[i * rvh_pkg_XLEN+:rvh_pkg_XLEN] = ls_pipe_amo_ctrl_st_req_data_i[i * rvh_pkg_XLEN+:rvh_pkg_XLEN];
			end
		end
	endgenerate
	assign amo_ctrl_stb_st_req_vld_o[0] = (((ls_pipe_amo_ctrl_st_req_vld_i[0] & ~st_req_is_amo_req[0]) & ~in_amo_state_o) | send_stb_flush_req_vld) | send_amo_req_vld;
	assign amo_ctrl_stb_st_req_vld_o[1] = ((ls_pipe_amo_ctrl_st_req_vld_i[1] & ~st_req_is_amo_req[0]) & ~st_req_is_amo_req[1]) & ~in_amo_state_o;
	assign ls_pipe_amo_ctrl_st_req_rdy_o[0] = ~in_amo_state_o & ((((ls_pipe_amo_ctrl_st_req_vld_i[0] & amo_ctrl_stb_st_req_rdy_i[0]) & ~st_req_is_amo_req[0]) | st_req_is_amo_req[0]) | ~ls_pipe_amo_ctrl_st_req_vld_i[0]);
	assign ls_pipe_amo_ctrl_st_req_rdy_o[1] = ~in_amo_state_o & ((((ls_pipe_amo_ctrl_st_req_vld_i[1] & amo_ctrl_stb_st_req_rdy_i[1]) & ~st_req_is_amo_req[0]) & ~st_req_is_amo_req[1]) | ~ls_pipe_amo_ctrl_st_req_vld_i[1]);
	assign receive_amo_req_hsk = (ls_pipe_amo_ctrl_st_req_vld_i[0] & st_req_is_amo_req[0]) & ls_pipe_amo_ctrl_st_req_rdy_o[0];
	assign send_stb_req_hsk = amo_ctrl_stb_st_req_vld_o[0] & amo_ctrl_stb_st_req_rdy_i[0];
	assign bank_amo_resp_vld = l1d_rob_wb_vld_i[0] & (l1d_rob_wb_rob_tag_i[0+:rvh_pkg_ROB_TAG_WIDTH] == amo_req_q[rvh_pkg_ROB_TAG_WIDTH + 132-:((rvh_pkg_ROB_TAG_WIDTH + 132) >= 133 ? rvh_pkg_ROB_TAG_WIDTH : 134 - (rvh_pkg_ROB_TAG_WIDTH + 132))]);
	always @(*) begin
		amo_ctrl_fsm_state_d = amo_ctrl_fsm_state_q;
		amo_ctrl_fsm_state_ena = 1'b0;
		amo_req_ena = 1'b0;
		in_amo_state_o = 1'b1;
		send_stb_flush_req_vld = 1'b0;
		send_amo_req_vld = 1'b0;
		waiting_for_amo_resp = 1'b0;
		case (amo_ctrl_fsm_state_q)
			3'd0: begin
				in_amo_state_o = 1'b0;
				if (receive_amo_req_hsk) begin
					amo_ctrl_fsm_state_d = 3'd1;
					amo_ctrl_fsm_state_ena = 1'b1;
					amo_req_ena = 1'b1;
				end
			end
			3'd1: begin
				send_stb_flush_req_vld = 1'b1;
				if (send_stb_req_hsk) begin
					amo_ctrl_fsm_state_d = 3'd2;
					amo_ctrl_fsm_state_ena = 1'b1;
				end
			end
			3'd2: begin
				send_amo_req_vld = 1'b1;
				if (send_stb_req_hsk) begin
					amo_ctrl_fsm_state_d = 3'd3;
					amo_ctrl_fsm_state_ena = 1'b1;
				end
			end
			3'd3: begin
				send_stb_flush_req_vld = 1'b1;
				if (send_stb_req_hsk) begin
					amo_ctrl_fsm_state_d = 3'd4;
					amo_ctrl_fsm_state_ena = 1'b1;
				end
			end
			3'd4: begin
				waiting_for_amo_resp = 1'b1;
				if (bank_amo_resp_vld) begin
					amo_ctrl_fsm_state_d = 3'd0;
					amo_ctrl_fsm_state_ena = 1'b1;
				end
			end
			default: begin
				amo_ctrl_fsm_state_d = 3'd0;
				amo_ctrl_fsm_state_ena = 1'b1;
			end
		endcase
	end
	assign amo_req_d[rvh_pkg_ROB_TAG_WIDTH + 132-:((rvh_pkg_ROB_TAG_WIDTH + 132) >= 133 ? rvh_pkg_ROB_TAG_WIDTH : 134 - (rvh_pkg_ROB_TAG_WIDTH + 132))] = ls_pipe_amo_ctrl_st_req_rob_tag_i[0+:rvh_pkg_ROB_TAG_WIDTH];
	assign amo_req_d[132-:32'd6] = ls_pipe_amo_ctrl_st_req_prd_i[0+:rvh_pkg_PREG_TAG_WIDTH];
	assign amo_req_d[126-:5] = ls_pipe_amo_ctrl_st_req_opcode_i[0+:uop_encoding_pkg_STU_OP_WIDTH];
	assign amo_req_d[121-:56] = ls_pipe_amo_ctrl_st_req_paddr_i[0+:rvh_pkg_PADDR_WIDTH];
	assign amo_req_d[65-:64] = ls_pipe_amo_ctrl_st_req_data_i[0+:rvh_pkg_XLEN];
	assign amo_req_d[1] = (ls_pipe_amo_ctrl_st_req_opcode_i[0+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(7)) | (ls_pipe_amo_ctrl_st_req_opcode_i[0+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(8));
	assign amo_req_d[0] = (ls_pipe_amo_ctrl_st_req_opcode_i[0+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(9)) | (ls_pipe_amo_ctrl_st_req_opcode_i[0+:uop_encoding_pkg_STU_OP_WIDTH] == sv2v_cast_038DB(10));
	std_dffrve #(.WIDTH(3)) U_STA_L1D_AMO_CTRL_STATE_REG(
		.clk(clk),
		.rstn(rst),
		.rst_val(3'd0),
		.en(amo_ctrl_fsm_state_ena),
		.d(amo_ctrl_fsm_state_d),
		.q(amo_ctrl_fsm_state_q)
	);
	std_dffe #(.WIDTH(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 65) >= 0 ? ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 2 : 1 - (((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1)))) U_DAT_L1D_AMO_CTRL_REQ_REG(
		.clk(clk),
		.en(amo_req_ena),
		.d(amo_req_d),
		.q(amo_req_q)
	);
	wire [N_STB_ST_IN_PORT - 1:0] st_req_hit_rt;
	wire lr_fail_by_st;
	wire lr_fail_by_snp;
	wire lr_fail_by_evict;
	wire lr_clr_by_sc;
	localparam [31:0] rvh_pkg_L1D_LINE_SIZE = 64;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	localparam rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE = 50;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : genblk3
			assign st_req_hit_rt[i] = (ls_pipe_amo_ctrl_st_req_vld_i[i] & ~ls_pipe_amo_ctrl_st_req_is_fence_i[i]) & (ls_pipe_amo_ctrl_st_req_paddr_i[(i * rvh_pkg_PADDR_WIDTH) + 55-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == reservation_table_q[55-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE]);
		end
	endgenerate
	assign lr_fail_by_st = reservation_table_valid_q & ((st_req_hit_rt[0] & ~amo_req_d[1]) | st_req_hit_rt[1]);
	assign lr_fail_by_snp = 1'b0;
	assign lr_fail_by_evict = 1'b0;
	assign lr_clr_by_sc = ((reservation_table_valid_q & amo_req_q[0]) & waiting_for_amo_resp) & bank_amo_resp_vld;
	assign reservation_table_valid_set = (amo_req_q[1] & waiting_for_amo_resp) & bank_amo_resp_vld;
	assign reservation_table_valid_clr = ((lr_fail_by_st | lr_fail_by_snp) | lr_fail_by_evict) | lr_clr_by_sc;
	assign reservation_table_valid_d = reservation_table_valid_set & ~reservation_table_valid_clr;
	assign reservation_table_valid_ena = reservation_table_valid_set | reservation_table_valid_clr;
	assign reservation_table_d[55-:rvh_pkg_PADDR_WIDTH] = amo_req_q[121-:56];
	assign reservation_table_ena = reservation_table_valid_set;
	std_dffre #(.WIDTH(1)) U_STA_L1D_AMO_CTRL_RT_VALID_REG(
		.clk(clk),
		.rstn(rst),
		.en(reservation_table_valid_ena),
		.d(reservation_table_valid_d),
		.q(reservation_table_valid_q)
	);
	std_dffe #(.WIDTH(rvh_pkg_PADDR_WIDTH)) U_DAT_L1D_AMO_CTRL_RT_REG(
		.clk(clk),
		.en(reservation_table_ena),
		.d(reservation_table_d),
		.q(reservation_table_q)
	);
	assign amo_ctrl_stb_st_req_sc_rt_check_succ_o = reservation_table_valid_q & (amo_req_q[121-:56] == reservation_table_q[55-:rvh_pkg_PADDR_WIDTH]);
endmodule
