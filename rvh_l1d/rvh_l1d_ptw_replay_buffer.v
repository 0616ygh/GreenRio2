module rvh_l1d_ptw_replay_buffer (
	ptw_walk_req_vld_i,
	ptw_walk_req_id_i,
	ptw_walk_req_addr_i,
	ptw_walk_resp_vld_i,
	ptw_walk_resp_rdy_i,
	stb_l1d_ptw_replay_vld_i,
	ptw_walk_replay_req_vld_o,
	ptw_walk_replay_req_id_o,
	ptw_walk_replay_req_paddr_o,
	ptw_walk_replay_req_rdy_i,
	clk,
	rst
);
	parameter [31:0] REPLAY_LATENCY = 4;
	input wire ptw_walk_req_vld_i;
	localparam [31:0] rvh_pkg_PTW_COUNT = 1;
	localparam [31:0] rvh_pkg_PTW_ID_WIDTH = 1;
	input wire [0:0] ptw_walk_req_id_i;
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	input wire [55:0] ptw_walk_req_addr_i;
	input wire ptw_walk_resp_vld_i;
	input wire ptw_walk_resp_rdy_i;
	input wire stb_l1d_ptw_replay_vld_i;
	output wire ptw_walk_replay_req_vld_o;
	output wire [0:0] ptw_walk_replay_req_id_o;
	output wire [55:0] ptw_walk_replay_req_paddr_o;
	input wire ptw_walk_replay_req_rdy_i;
	input wire clk;
	input wire rst;
	wire [(rvh_pkg_PTW_ID_WIDTH + rvh_pkg_PADDR_WIDTH) - 1:0] ptw_req_buffer;
	wire [(rvh_pkg_PTW_ID_WIDTH + rvh_pkg_PADDR_WIDTH) - 1:0] ptw_req_buffer_nxt;
	wire ptw_req_buffer_ena;
	wire ptw_req_buffer_valid;
	wire ptw_req_buffer_valid_nxt;
	wire ptw_req_buffer_valid_set;
	wire ptw_req_buffer_valid_clr;
	wire ptw_req_buffer_valid_ena;
	wire ptw_req_buffer_replay_pending;
	wire ptw_req_buffer_replay_pending_nxt;
	wire ptw_req_buffer_replay_pending_set;
	wire ptw_req_buffer_replay_pending_clr;
	wire ptw_req_buffer_replay_pending_ena;
	wire [$clog2(REPLAY_LATENCY) - 1:0] replay_counter;
	wire [$clog2(REPLAY_LATENCY) - 1:0] replay_counter_nxt;
	wire replay_counter_ena;
	assign ptw_req_buffer_valid_set = ptw_walk_req_vld_i;
	assign ptw_req_buffer_valid_clr = ptw_walk_resp_vld_i & ptw_walk_resp_rdy_i;
	assign ptw_req_buffer_valid_ena = ptw_req_buffer_valid_set | ptw_req_buffer_valid_clr;
	assign ptw_req_buffer_valid_nxt = (ptw_req_buffer_valid_clr ? 1'b0 : (ptw_req_buffer_valid_set ? 1'b1 : ptw_req_buffer_valid));
	std_dffre #(.WIDTH(1)) U_PTW_REQ_BUFFER_VALID(
		.clk(clk),
		.rstn(rst),
		.en(ptw_req_buffer_valid_ena),
		.d(ptw_req_buffer_valid_nxt),
		.q(ptw_req_buffer_valid)
	);
	assign ptw_req_buffer_replay_pending_set = stb_l1d_ptw_replay_vld_i;
	assign ptw_req_buffer_replay_pending_clr = (ptw_walk_replay_req_vld_o & ptw_walk_replay_req_rdy_i) | ptw_req_buffer_valid_clr;
	assign ptw_req_buffer_replay_pending_ena = ptw_req_buffer_replay_pending_set | ptw_req_buffer_replay_pending_clr;
	assign ptw_req_buffer_replay_pending_nxt = (ptw_req_buffer_replay_pending_set ? 1'b1 : (ptw_req_buffer_replay_pending_clr ? 1'b0 : ptw_req_buffer_replay_pending));
	std_dffre #(.WIDTH(1)) U_PTW_REQ_BUFFER_REPLAY_PENDING(
		.clk(clk),
		.rstn(rst),
		.en(ptw_req_buffer_replay_pending_ena),
		.d(ptw_req_buffer_replay_pending_nxt),
		.q(ptw_req_buffer_replay_pending)
	);
	assign ptw_req_buffer_nxt[56-:1] = ptw_walk_req_id_i;
	assign ptw_req_buffer_nxt[55-:rvh_pkg_PADDR_WIDTH] = ptw_walk_req_addr_i;
	assign ptw_req_buffer_ena = ptw_req_buffer_valid_set;
	localparam rvh_l1d_pkg_L1D_STB_ENTRY_NUM = 8;
	localparam [31:0] rvh_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_pkg_PREG_TAG_WIDTH = rvh_pkg_INT_PREG_TAG_WIDTH;
	localparam [31:0] rvh_pkg_ROB_BLOCK_PER_ENTRY = 1;
	localparam [31:0] rvh_pkg_ROB_SIZE = 16;
	localparam [31:0] rvh_pkg_ROB_ENTRY_COUNT = rvh_pkg_ROB_SIZE / rvh_pkg_ROB_BLOCK_PER_ENTRY;
	localparam [31:0] rvh_pkg_ROB_INDEX_WIDTH = $clog2(rvh_pkg_ROB_ENTRY_COUNT);
	localparam [31:0] rvh_pkg_ROB_TAG_WIDTH = rvh_pkg_ROB_INDEX_WIDTH;
	localparam [31:0] rvh_pkg_XLEN = 64;
	localparam [31:0] uop_encoding_pkg_STU_OP_WIDTH = 5;
	std_dffe #(.WIDTH(((((rvh_pkg_ROB_TAG_WIDTH + 32'd6) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)))) U_PTW_REQ_BUFFER(
		.clk(clk),
		.en(ptw_req_buffer_ena),
		.d(ptw_req_buffer_nxt),
		.q(ptw_req_buffer)
	);
	assign replay_counter_nxt = replay_counter + 1;
	assign replay_counter_ena = ptw_req_buffer_valid & ptw_req_buffer_replay_pending;
	std_dffre #(.WIDTH(1)) U_REPLAY_COUNTER(
		.clk(clk),
		.rstn(rst),
		.en(replay_counter_ena),
		.d(replay_counter_nxt),
		.q(replay_counter)
	);
	assign ptw_walk_replay_req_vld_o = (ptw_req_buffer_valid & ptw_req_buffer_replay_pending) & (replay_counter == (REPLAY_LATENCY - 1));
	assign ptw_walk_replay_req_id_o = ptw_req_buffer[56-:1];
	assign ptw_walk_replay_req_paddr_o = ptw_req_buffer[55-:rvh_pkg_PADDR_WIDTH];
endmodule
