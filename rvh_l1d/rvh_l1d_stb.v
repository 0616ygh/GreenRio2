module rvh_l1d_stb (
	ls_pipe_stb_st_req_vld_i,
	ls_pipe_l1d_st_req_is_fence_i,
	ls_pipe_l1d_st_req_no_fence_wb_resp_i,
	ls_pipe_l1d_st_req_sc_rt_check_succ_i,
	ls_pipe_stb_st_req_rob_tag_i,
	ls_pipe_stb_st_req_prd_i,
	ls_pipe_stb_st_req_opcode_i,
	ls_pipe_stb_st_req_paddr_i,
	ls_pipe_stb_st_req_data_i,
	ls_pipe_stb_st_req_rdy_o,
	ls_pipe_stb_ld_req_vld_i,
	ls_pipe_stb_ld_req_rob_tag_i,
	ls_pipe_stb_ld_req_prd_i,
	ls_pipe_stb_ld_req_opcode_i,
	ls_pipe_stb_ld_req_idx_i,
	ls_pipe_stb_ld_req_offset_i,
	ls_pipe_stb_ld_req_vtag_i,
	l1d_stb_st_req_rdy_i,
	ls_pipe_stb_ld_req_rdy_o,
	kill_ld_req_i,
	ls_pipe_stb_dtlb_resp_vld_i,
	ls_pipe_stb_dtlb_resp_ppn_i,
	ls_pipe_stb_dtlb_resp_excp_vld_i,
	ls_pipe_stb_dtlb_resp_hit_i,
	ls_pipe_stb_dtlb_resp_miss_i,
	stb_rob_wb_vld_o,
	stb_rob_wb_rob_tag_o,
	stb_int_prf_wb_vld_o,
	stb_int_prf_wb_tag_o,
	stb_int_prf_wb_data_o,
	stb_l1d_arb_bank_id_o,
	stb_l1d_st_req_vld_o,
	stb_l1d_st_req_rob_tag_o,
	stb_l1d_st_req_prd_o,
	stb_l1d_st_req_opcode_o,
	stb_l1d_st_req_paddr_o,
	stb_l1d_st_req_data_o,
	stb_l1d_st_req_data_byte_mask_o,
	stb_l1d_st_req_sc_rt_check_succ_o,
	stb_l1d_st_req_amo_offset_o,
	stb_l1d_st_req_rdy_i,
	ptw_walk_req_vld_i,
	ptw_walk_req_id_i,
	ptw_walk_req_addr_i,
	ptw_walk_l1d_req_rdy_i,
	ptw_walk_req_rdy_o,
	stb_l1d_in_fence_busy_o,
	stb_l1d_ld_partial_hit_replay_o,
	stb_l1d_ptw_partial_hit_replay_o,
	fencei_flush_vld_i,
	fencei_flush_rdy_o,
	fencei_flush_done_o,
	clk,
	rst
);
	parameter [31:0] N_STB = 8;
	parameter [31:0] N_STB_ST_IN_PORT = 2;
	parameter [31:0] N_STB_LD_IN_PORT = 2;
	localparam [31:0] STB_ID_WIDHT = (N_STB > 1 ? $clog2(N_STB) : 1);
	input wire [N_STB_ST_IN_PORT - 1:0] ls_pipe_stb_st_req_vld_i;
	input wire [N_STB_ST_IN_PORT - 1:0] ls_pipe_l1d_st_req_is_fence_i;
	input wire ls_pipe_l1d_st_req_no_fence_wb_resp_i;
	input wire ls_pipe_l1d_st_req_sc_rt_check_succ_i;
	localparam [31:0] rvh_pkg_ROB_BLOCK_PER_ENTRY = 1;
	localparam [31:0] rvh_pkg_ROB_SIZE = 16;
	localparam [31:0] rvh_pkg_ROB_ENTRY_COUNT = rvh_pkg_ROB_SIZE / rvh_pkg_ROB_BLOCK_PER_ENTRY;
	localparam [31:0] rvh_pkg_ROB_INDEX_WIDTH = $clog2(rvh_pkg_ROB_ENTRY_COUNT);
	localparam [31:0] rvh_pkg_ROB_TAG_WIDTH = rvh_pkg_ROB_INDEX_WIDTH;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_stb_st_req_rob_tag_i;
	localparam [31:0] rvh_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_pkg_PREG_TAG_WIDTH = rvh_pkg_INT_PREG_TAG_WIDTH;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_stb_st_req_prd_i;
	localparam [31:0] uop_encoding_pkg_STU_OP_WIDTH = 5;
	input wire [(N_STB_ST_IN_PORT * uop_encoding_pkg_STU_OP_WIDTH) - 1:0] ls_pipe_stb_st_req_opcode_i;
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_PADDR_WIDTH) - 1:0] ls_pipe_stb_st_req_paddr_i;
	localparam [31:0] rvh_pkg_XLEN = 64;
	input wire [(N_STB_ST_IN_PORT * rvh_pkg_XLEN) - 1:0] ls_pipe_stb_st_req_data_i;
	output wire [N_STB_ST_IN_PORT - 1:0] ls_pipe_stb_st_req_rdy_o;
	input wire [N_STB_LD_IN_PORT - 1:0] ls_pipe_stb_ld_req_vld_i;
	input wire [(N_STB_LD_IN_PORT * rvh_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_stb_ld_req_rob_tag_i;
	input wire [(N_STB_LD_IN_PORT * rvh_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_stb_ld_req_prd_i;
	localparam [31:0] uop_encoding_pkg_LDU_OP_WIDTH = 3;
	input wire [(N_STB_LD_IN_PORT * uop_encoding_pkg_LDU_OP_WIDTH) - 1:0] ls_pipe_stb_ld_req_opcode_i;
	localparam [31:0] rvh_pkg_L1D_BANK_COUNT = 1;
	localparam rvh_l1d_pkg_L1D_BANK_ID_NUM = rvh_pkg_L1D_BANK_COUNT;
	localparam [31:0] rvh_pkg_L1D_LINE_SIZE = 64;
	localparam [31:0] rvh_pkg_L1D_SIZE = 16384;
	localparam [31:0] rvh_pkg_L1D_WAY_COUNT = 4;
	localparam [31:0] rvh_pkg_L1D_SET_COUNT = rvh_pkg_L1D_SIZE / (rvh_pkg_L1D_LINE_SIZE * rvh_pkg_L1D_WAY_COUNT);
	localparam [31:0] rvh_pkg_L1D_BANK_SET_COUNT = rvh_pkg_L1D_SET_COUNT / rvh_pkg_L1D_BANK_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_SET_NUM = rvh_pkg_L1D_BANK_SET_COUNT;
	localparam rvh_l1d_pkg_L1D_INDEX_WIDTH = $clog2(rvh_l1d_pkg_L1D_BANK_SET_NUM * 32'd1);
	input wire [(N_STB_LD_IN_PORT * rvh_l1d_pkg_L1D_INDEX_WIDTH) - 1:0] ls_pipe_stb_ld_req_idx_i;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	input wire [(N_STB_LD_IN_PORT * rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1:0] ls_pipe_stb_ld_req_offset_i;
	localparam rvh_l1d_pkg_L1D_TAG_WIDTH = (rvh_pkg_PADDR_WIDTH - rvh_l1d_pkg_L1D_INDEX_WIDTH) - rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	input wire [(N_STB_LD_IN_PORT * rvh_l1d_pkg_L1D_TAG_WIDTH) - 1:0] ls_pipe_stb_ld_req_vtag_i;
	input wire [N_STB_LD_IN_PORT - 1:0] l1d_stb_st_req_rdy_i;
	output wire [N_STB_LD_IN_PORT - 1:0] ls_pipe_stb_ld_req_rdy_o;
	input wire kill_ld_req_i;
	input wire [N_STB_LD_IN_PORT - 1:0] ls_pipe_stb_dtlb_resp_vld_i;
	localparam riscv_pkg_PAGE_OFFSET_WIDTH = 12;
	localparam riscv_pkg_PPN_WIDTH = 44;
	input wire [(N_STB_LD_IN_PORT * riscv_pkg_PPN_WIDTH) - 1:0] ls_pipe_stb_dtlb_resp_ppn_i;
	input wire [N_STB_LD_IN_PORT - 1:0] ls_pipe_stb_dtlb_resp_excp_vld_i;
	input wire [N_STB_LD_IN_PORT - 1:0] ls_pipe_stb_dtlb_resp_hit_i;
	input wire [N_STB_LD_IN_PORT - 1:0] ls_pipe_stb_dtlb_resp_miss_i;
	output wire [(N_STB_LD_IN_PORT + N_STB_ST_IN_PORT) - 1:0] stb_rob_wb_vld_o;
	output wire [((N_STB_LD_IN_PORT + N_STB_ST_IN_PORT) * rvh_pkg_ROB_TAG_WIDTH) - 1:0] stb_rob_wb_rob_tag_o;
	output wire [N_STB_LD_IN_PORT - 1:0] stb_int_prf_wb_vld_o;
	output wire [(N_STB_LD_IN_PORT * rvh_pkg_INT_PREG_TAG_WIDTH) - 1:0] stb_int_prf_wb_tag_o;
	output wire [(N_STB_LD_IN_PORT * rvh_pkg_XLEN) - 1:0] stb_int_prf_wb_data_o;
	output wire [N_STB_LD_IN_PORT - 1:0] stb_l1d_arb_bank_id_o;
	output reg stb_l1d_st_req_vld_o;
	output reg [rvh_pkg_ROB_TAG_WIDTH - 1:0] stb_l1d_st_req_rob_tag_o;
	output reg [5:0] stb_l1d_st_req_prd_o;
	output reg [4:0] stb_l1d_st_req_opcode_o;
	output reg [55:0] stb_l1d_st_req_paddr_o;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	output reg [511:0] stb_l1d_st_req_data_o;
	output reg [63:0] stb_l1d_st_req_data_byte_mask_o;
	output reg stb_l1d_st_req_sc_rt_check_succ_o;
	output reg [5:0] stb_l1d_st_req_amo_offset_o;
	input wire stb_l1d_st_req_rdy_i;
	input wire ptw_walk_req_vld_i;
	localparam [31:0] rvh_pkg_PTW_COUNT = 1;
	localparam [31:0] rvh_pkg_PTW_ID_WIDTH = 1;
	input wire [0:0] ptw_walk_req_id_i;
	input wire [55:0] ptw_walk_req_addr_i;
	input wire ptw_walk_l1d_req_rdy_i;
	output wire ptw_walk_req_rdy_o;
	output wire stb_l1d_in_fence_busy_o;
	output wire [N_STB_LD_IN_PORT - 1:0] stb_l1d_ld_partial_hit_replay_o;
	output wire stb_l1d_ptw_partial_hit_replay_o;
	input wire fencei_flush_vld_i;
	output wire fencei_flush_rdy_o;
	output wire fencei_flush_done_o;
	input clk;
	input rst;
	genvar i;
	genvar j;
	genvar k;
	wire [N_STB - 1:0] stb_entry_valid;
	wire [N_STB - 1:0] stb_entry_valid_nxt;
	wire [N_STB - 1:0] stb_entry_valid_ena;
	wire [N_STB - 1:0] stb_entry_evict_at_once;
	wire [N_STB - 1:0] stb_entry_evict_at_once_nxt;
	wire [N_STB - 1:0] stb_entry_evict_at_once_ena;
	localparam rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE = 50;
	wire [(N_STB * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) - 1:0] stb_entry;
	wire [(N_STB * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) - 1:0] stb_entry_nxt;
	wire [(N_STB * N_STB_ST_IN_PORT) - 1:0] stb_entry_nxt_new_ena_per_input;
	wire [(N_STB * N_STB_ST_IN_PORT) - 1:0] stb_entry_nxt_upd_ena_per_input;
	wire [(N_STB_ST_IN_PORT * N_STB) - 1:0] stb_entry_nxt_new_ena_per_input_trans;
	wire [(N_STB_ST_IN_PORT * N_STB) - 1:0] stb_entry_nxt_upd_ena_per_input_trans;
	wire [N_STB - 1:0] stb_entry_nxt_new_ena_per_stb_entry;
	wire [N_STB - 1:0] stb_entry_nxt_upd_ena_per_stb_entry;
	wire [N_STB - 1:0] stb_entry_nxt_set_ena;
	reg [N_STB - 1:0] stb_entry_nxt_clr_ena_selected_evict;
	reg [N_STB - 1:0] stb_entry_nxt_clr_ena_in_age_evict;
	wire [N_STB - 1:0] stb_entry_nxt_clr_ena;
	wire [STB_ID_WIDHT:0] free_stb_entry_num;
	localparam rvh_l1d_pkg_L1D_STB_ENTRY_NUM = 8;
	wire [(N_STB_ST_IN_PORT * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) - 1:0] st_cur;
	wire [(N_STB_ST_IN_PORT * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) - 1:0] st_nxt;
	wire [N_STB_ST_IN_PORT - 1:0] st_s1_valid;
	wire [N_STB_ST_IN_PORT - 1:0] st_s1_nxt_ena;
	wire [N_STB_ST_IN_PORT - 1:0] st_s1_valid_nxt;
	wire [(N_STB_LD_IN_PORT * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) - 1:0] ld_cur;
	wire [(N_STB_LD_IN_PORT * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) - 1:0] ld_nxt;
	wire [N_STB_LD_IN_PORT - 1:0] ld_s1_valid;
	wire [N_STB_LD_IN_PORT - 1:0] ld_s2_valid;
	wire [N_STB_LD_IN_PORT - 1:0] ld_s1_nxt_ena;
	wire [N_STB_LD_IN_PORT - 1:0] ld_s2_nxt_ena;
	wire [N_STB_LD_IN_PORT - 1:0] ld_s1_valid_nxt;
	wire [N_STB_LD_IN_PORT - 1:0] ld_s2_valid_nxt;
	wire [(N_STB_ST_IN_PORT * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) - 1:0] new_stb_entry;
	wire [(N_STB_ST_IN_PORT * STB_ID_WIDHT) - 1:0] new_stb_entry_idx;
	wire [N_STB_ST_IN_PORT - 1:0] new_stb_entry_idx_vld;
	wire [(N_STB_ST_IN_PORT * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) - 1:0] upd_stb_entry_old;
	wire [(N_STB_ST_IN_PORT * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) - 1:0] upd_stb_entry_new;
	reg [(N_STB_ST_IN_PORT * STB_ID_WIDHT) - 1:0] upd_stb_entry_idx;
	wire [N_STB_ST_IN_PORT - 1:0] upd_stb_entry_idx_vld;
	reg out_selected_stb_entry_valid;
	wire out_selected_stb_entry_hited_at_ld_s1;
	wire out_selected_stb_entry_hited_at_st_s1;
	reg [((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1:0] out_selected_stb_entry;
	reg out_in_age_stb_entry_valid;
	wire out_in_age_stb_entry_hited_at_ld_s1;
	wire out_in_age_stb_entry_hited_at_st_s1;
	reg [((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1:0] out_in_age_stb_entry;
	wire stb_l1d_st_req_hsk;
	reg [(N_STB_LD_IN_PORT * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) - 1:0] bps_stb_entry;
	wire [N_STB_LD_IN_PORT - 1:0] stb_ld_bypass_full_hit;
	wire [N_STB_LD_IN_PORT - 1:0] stb_ld_bypass_partial_hit;
	wire [N_STB_LD_IN_PORT - 1:0] stb_ld_bypass_miss;
	reg [1:0] stb_evict_state_d;
	wire [1:0] stb_evict_state_q;
	reg is_in_flush_stb_evict_state;
	reg is_in_selected_evict_stb_evict_state;
	reg is_in_in_age_evict_stb_evict_state;
	reg stb_evict_state_d_ena;
	wire have_stb_entry_to_flush;
	wire have_stb_entry_to_evict_at_once;
	wire have_stb_entry_to_evict_in_age;
	wire [rvh_pkg_ROB_TAG_WIDTH - 1:0] flush_req_rob_tag;
	reg [rvh_pkg_ROB_TAG_WIDTH - 1:0] flush_req_rob_tag_nxt;
	reg flush_req_rob_tag_ena;
	wire [N_STB - 1:0] common_evict_mask;
	wire [N_STB - 1:0] at_once_evict_mask;
	wire [N_STB_ST_IN_PORT - 1:0] st_req_has_free_stb_entry;
	wire [N_STB_ST_IN_PORT - 1:0] st_req_rdy;
	wire [N_STB_ST_IN_PORT - 1:0] st_req_hak;
	wire [N_STB_LD_IN_PORT - 1:0] ld_req_rdy;
	wire [N_STB_LD_IN_PORT - 1:0] ld_req_hak;
	wire ptw_req_rdy;
	wire ptw_req_hak;
	wire fencei_flush_hsk;
	assign fencei_flush_rdy_o = (~st_s1_valid & ~ld_s1_valid) & ~ld_s2_valid;
	assign fencei_flush_hsk = fencei_flush_vld_i & fencei_flush_rdy_o;
	assign fencei_flush_done_o = ~(|stb_entry_valid);
	assign stb_l1d_in_fence_busy_o = is_in_flush_stb_evict_state;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_stb_l1d_ld_partial_hit_replay
			assign stb_l1d_ld_partial_hit_replay_o[i] = (ld_s2_valid[i] & ~ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 16))]) & stb_ld_bypass_partial_hit[i];
		end
	endgenerate
	assign stb_l1d_ptw_partial_hit_replay_o = (ld_s2_valid[0] & ld_cur[0 + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 16))]) & stb_ld_bypass_partial_hit[0];
	wire st_req_hit_the_same_cache_line;
	assign st_req_hit_the_same_cache_line = &ls_pipe_stb_st_req_vld_i & (ls_pipe_stb_st_req_paddr_i[55-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == ls_pipe_stb_st_req_paddr_i[111-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE]);
	wire [(N_STB_ST_IN_PORT * N_STB) - 1:0] st_req_hit_stb_per_entry;
	wire [(N_STB_ST_IN_PORT * N_STB_ST_IN_PORT) - 1:0] st_req_hit_st_pipe_s1_per_entry;
	wire [((N_STB_ST_IN_PORT * N_STB) * N_STB_ST_IN_PORT) - 1:0] st_req_hit_st_pipe_s1_per_entry_trans_mid;
	wire [(N_STB_ST_IN_PORT * N_STB) - 1:0] st_req_hit_st_pipe_s1_per_entry_trans;
	wire [N_STB_ST_IN_PORT - 1:0] st_req_hit_stb;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_st_req_hit_stb_per_entry
			for (j = 0; j < N_STB; j = j + 1) begin : genblk1
				assign st_req_hit_stb_per_entry[(i * N_STB) + j] = ((((stb_entry_valid[j] & (ls_pipe_stb_st_req_paddr_i[(i * rvh_pkg_PADDR_WIDTH) + 55-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == stb_entry[(j * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 632-:50])) | st_req_hit_st_pipe_s1_per_entry_trans[(i * N_STB) + j]) & ~((is_in_selected_evict_stb_evict_state & stb_l1d_st_req_hsk) & at_once_evict_mask[j])) & ~((is_in_in_age_evict_stb_evict_state & stb_l1d_st_req_hsk) & common_evict_mask[j])) & ~((is_in_flush_stb_evict_state & stb_l1d_st_req_hsk) & common_evict_mask[j]);
			end
			assign st_req_hit_stb[i] = |st_req_hit_stb_per_entry[i * N_STB+:N_STB];
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_st_req_hit_st_pipe_s1_per_entry_trans
			for (j = 0; j < N_STB; j = j + 1) begin : genblk1
				for (k = 0; k < N_STB_ST_IN_PORT; k = k + 1) begin : genblk1
					assign st_req_hit_st_pipe_s1_per_entry_trans_mid[(((i * N_STB) + j) * N_STB_ST_IN_PORT) + k] = (stb_entry_nxt_new_ena_per_input[(j * N_STB_ST_IN_PORT) + k] | stb_entry_nxt_upd_ena_per_input[(j * N_STB_ST_IN_PORT) + k]) & st_req_hit_st_pipe_s1_per_entry[(i * N_STB_ST_IN_PORT) + k];
				end
				assign st_req_hit_st_pipe_s1_per_entry_trans[(i * N_STB) + j] = |st_req_hit_st_pipe_s1_per_entry_trans_mid[((i * N_STB) + j) * N_STB_ST_IN_PORT+:N_STB_ST_IN_PORT];
			end
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_st_req_hit_st_pipe_s1_per_entry
			for (j = 0; j < N_STB_ST_IN_PORT; j = j + 1) begin : genblk1
				if (j == 0) begin : gen_st_req_hit_st_pipe_s1_per_entry_from_first_st_pipe
					assign st_req_hit_st_pipe_s1_per_entry[(i * N_STB_ST_IN_PORT) + j] = (st_s1_valid[j] & (ls_pipe_stb_st_req_paddr_i[(i * rvh_pkg_PADDR_WIDTH) + 55-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 129) : rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE - 131)-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE])) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
				end
				else begin : gen_st_req_hit_st_pipe_s1_per_entry_from_other_st_pipe
					assign st_req_hit_st_pipe_s1_per_entry[(i * N_STB_ST_IN_PORT) + j] = ((st_s1_valid[j] & (ls_pipe_stb_st_req_paddr_i[(i * rvh_pkg_PADDR_WIDTH) + 55-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 129) : rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE - 131)-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE])) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)]) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)];
				end
			end
		end
	endgenerate
	one_counter #(.DATA_WIDTH(N_STB)) free_stb_entry_num_counter_u(
		.data_i(~stb_entry_valid),
		.cnt_o(free_stb_entry_num)
	);
	wire free_stb_entry_num_more_or_equal_one;
	wire free_stb_entry_num_more_or_equal_two;
	wire free_stb_entry_num_more_or_equal_three;
	wire free_stb_entry_num_more_or_equal_four;
	wire s1_st_req_valid_num_equal_one;
	wire s1_st_req_valid_num_equal_two;
	wire [2:0] higher_priority_than_s0_1_st_req_in_pipeline_num;
	wire s1_first_id_needed_vld;
	wire s1_second_id_needed_vld;
	assign s1_first_id_needed_vld = st_s1_valid[0] & ~st_cur[0 + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
	assign s1_second_id_needed_vld = (st_s1_valid[1] & ~st_cur[((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)]) & ~st_cur[((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)];
	assign free_stb_entry_num_more_or_equal_one = free_stb_entry_num >= 1;
	assign free_stb_entry_num_more_or_equal_two = free_stb_entry_num >= 2;
	assign free_stb_entry_num_more_or_equal_three = free_stb_entry_num >= 3;
	assign free_stb_entry_num_more_or_equal_four = free_stb_entry_num >= 4;
	assign s1_st_req_valid_num_equal_one = st_s1_valid[0] ^ st_s1_valid[1];
	assign s1_st_req_valid_num_equal_two = st_s1_valid[0] & st_s1_valid[1];
	one_counter #(.DATA_WIDTH(3)) higher_priority_than_s0_1_st_req_in_pipeline_num_counter_u(
		.data_i({st_s1_valid[0], st_s1_valid[1], ls_pipe_stb_st_req_vld_i[0]}),
		.cnt_o(higher_priority_than_s0_1_st_req_in_pipeline_num)
	);
	assign st_req_has_free_stb_entry[0] = (((free_stb_entry_num_more_or_equal_one & ~s1_st_req_valid_num_equal_one) & ~s1_st_req_valid_num_equal_two) | (free_stb_entry_num_more_or_equal_two & ~s1_st_req_valid_num_equal_two)) | free_stb_entry_num_more_or_equal_three;
	assign st_req_has_free_stb_entry[1] = (((free_stb_entry_num_more_or_equal_one & (higher_priority_than_s0_1_st_req_in_pipeline_num == 0)) | (free_stb_entry_num_more_or_equal_two & (higher_priority_than_s0_1_st_req_in_pipeline_num <= 1))) | (free_stb_entry_num_more_or_equal_three & (higher_priority_than_s0_1_st_req_in_pipeline_num <= 2))) | free_stb_entry_num_more_or_equal_four;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s0_st_req_rdy
			if (i == 0) begin : gen_st_req_rdy_for_first_port
				assign st_req_rdy[i] = (st_req_hit_stb[i] | st_req_has_free_stb_entry[i]) & ~is_in_flush_stb_evict_state;
			end
			else begin : gen_st_req_rdy_for_other_port
				assign st_req_rdy[i] = ((((st_req_hit_stb[i] | st_req_has_free_stb_entry[i]) & ~is_in_flush_stb_evict_state) & ~(|(ls_pipe_stb_st_req_vld_i[i - 1:0] & ls_pipe_l1d_st_req_is_fence_i[i - 1:0]))) & ~ls_pipe_l1d_st_req_is_fence_i[i]) & &(ls_pipe_stb_st_req_vld_i[i - 1:0] & st_req_rdy[i - 1:0]);
			end
			assign ls_pipe_stb_st_req_rdy_o[i] = st_req_rdy[i];
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s0_st_req_hsk
			assign st_req_hak[i] = ls_pipe_stb_st_req_vld_i[i] & st_req_rdy[i];
		end
	endgenerate
	wire [(N_STB_ST_IN_PORT * 512) - 1:0] s1_st_req_data_transed;
	wire [(N_STB_ST_IN_PORT * 64) - 1:0] s1_st_req_data_byte_mask_transed;
	wire [(N_STB_ST_IN_PORT * 64) - 1:0] s1_st_req_data_byte_mask_transed_mid;
	wire [(N_STB_ST_IN_PORT * 512) - 1:0] s1_st_req_data_bit_mask_transed;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_st_xlen_stb_length_trans
			rrv2rvh_ruby_stmask_trans stb_stmask_trans_st_req_u(
				.st_dat_i(st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 73) : -11)-:64]),
				.st_offset_i(st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 70) : -80) >= ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 65) : -75) ? ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) : (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) + (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 70) : -80) >= ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 65) : -75) ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75)) + 1 : (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80)) + 1)) - 1)-:(((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 70) : -80) >= ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 65) : -75) ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75)) + 1 : (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80)) + 1)]),
				.st_opcode_i(st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 134) : -131)-:5]),
				.ls_pipe_l1d_st_req_data_o(s1_st_req_data_transed[i * 512+:512]),
				.ls_pipe_l1d_st_req_data_byte_mask_o(s1_st_req_data_byte_mask_transed[i * 64+:64])
			);
			assign s1_st_req_data_byte_mask_transed_mid[i * 64+:64] = s1_st_req_data_byte_mask_transed[i * 64+:64] & {64 {st_s1_valid[i]}};
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_st_req_data_bit_mask_transed
			for (j = 0; j < rvh_l1d_pkg_L1D_STB_DATA_WIDTH; j = j + 1) begin : genblk1
				assign s1_st_req_data_bit_mask_transed[(i * 512) + j] = s1_st_req_data_byte_mask_transed_mid[(i * 64) + (j / 8)];
			end
		end
	endgenerate
	wire [511:0] s1_st_req_data_merged;
	wire [511:0] s1_st_req_data_bit_mask_merged;
	wire [63:0] s1_st_req_data_byte_mask_merged;
	wire [511:0] s1_st_req_data_bit_mask_interleaved;
	assign s1_st_req_data_bit_mask_interleaved = s1_st_req_data_bit_mask_transed[0+:512] & s1_st_req_data_bit_mask_transed[512+:512];
	assign s1_st_req_data_bit_mask_merged = s1_st_req_data_bit_mask_transed[0+:512] | s1_st_req_data_bit_mask_transed[512+:512];
	assign s1_st_req_data_byte_mask_merged = s1_st_req_data_byte_mask_transed_mid[0+:64] | s1_st_req_data_byte_mask_transed_mid[64+:64];
	assign s1_st_req_data_merged = (((s1_st_req_data_transed[0+:512] & s1_st_req_data_bit_mask_transed[0+:512]) | (s1_st_req_data_transed[512+:512] & s1_st_req_data_bit_mask_transed[512+:512])) & ~s1_st_req_data_bit_mask_interleaved) | (s1_st_req_data_transed[512+:512] & s1_st_req_data_bit_mask_interleaved);
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_new_stb_entry
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + (rvh_pkg_ROB_TAG_WIDTH + 643)-:((rvh_pkg_ROB_TAG_WIDTH + 643) >= 644 ? rvh_pkg_ROB_TAG_WIDTH : 645 - (rvh_pkg_ROB_TAG_WIDTH + 643))] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1) - (rvh_pkg_ROB_TAG_WIDTH + 141)) : (((rvh_pkg_ROB_TAG_WIDTH + 141) >= 142 ? rvh_pkg_ROB_TAG_WIDTH : 143 - (rvh_pkg_ROB_TAG_WIDTH + 141)) - (rvh_pkg_ROB_TAG_WIDTH + 141)) - 1)-:((rvh_pkg_ROB_TAG_WIDTH + 141) >= 142 ? rvh_pkg_ROB_TAG_WIDTH : 143 - (rvh_pkg_ROB_TAG_WIDTH + 141))];
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 643-:32'd6] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 140) : -136)-:32'd6];
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 637-:5] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 134) : -131)-:5];
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 632-:50] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 129) : rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE - 131)-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE];
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 582-:512] = (st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + 32'd6) + (32'd5 + 32'd56)) + 74) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 9) : -1)] ? s1_st_req_data_merged : s1_st_req_data_transed[i * 512+:512]);
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 70-:64] = (st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + 32'd6) + (32'd5 + 32'd56)) + 74) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 9) : -1)] ? s1_st_req_data_byte_mask_merged : s1_st_req_data_byte_mask_transed_mid[i * 64+:64]);
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 6] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1) : 0)];
			assign new_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 5-:rvh_l1d_pkg_L1D_OFFSET_WIDTH] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 70) : -80) >= ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 65) : -75) ? ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) : (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) + (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 70) : -80) >= ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 65) : -75) ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75)) + 1 : (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80)) + 1)) - 1)-:(((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 70) : -80) >= ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) - 65) : -75) ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75)) + 1 : (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 74) : -75) - ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 79) : -80)) + 1)];
		end
	endgenerate
	select_two_from_n_valid #(.SEL_WIDTH(N_STB)) select_new_stb_entry_idx_u(
		.sel_i(~stb_entry_valid),
		.first_id_needed_vld_i(s1_first_id_needed_vld),
		.second_id_needed_vld_i(s1_second_id_needed_vld),
		.first_id_vld_o(new_stb_entry_idx_vld[0]),
		.second_id_vld_o(new_stb_entry_idx_vld[1]),
		.first_id_o(new_stb_entry_idx[0+:STB_ID_WIDHT]),
		.second_id_o(new_stb_entry_idx[STB_ID_WIDHT+:STB_ID_WIDHT])
	);
	always @(*) begin : comb_s1_upd_stb_entry_select
		upd_stb_entry_idx = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1)
				begin : sv2v_autoblock_2
					reg signed [31:0] j;
					for (j = 0; j < N_STB; j = j + 1)
						if (st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1) - (2 + j)) : (7 - j) - 9)] == 1'b1)
							upd_stb_entry_idx[i * STB_ID_WIDHT+:STB_ID_WIDHT] = j[STB_ID_WIDHT - 1:0];
				end
		end
	end
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_upd_stb_entry_old
			assign upd_stb_entry_idx_vld[i] = st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
			assign upd_stb_entry_old[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH] = stb_entry[upd_stb_entry_idx[i * STB_ID_WIDHT+:STB_ID_WIDHT] * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH];
		end
	endgenerate
	wire [(N_STB_ST_IN_PORT * 64) - 1:0] s1_st_req_upd_old_byte_mask_interleaved;
	wire [(N_STB_ST_IN_PORT * 512) - 1:0] s1_st_req_upd_old_bit_mask_interleaved;
	wire [(N_STB_ST_IN_PORT * 512) - 1:0] s1_st_req_data_selected;
	wire [(N_STB_ST_IN_PORT * 64) - 1:0] s1_st_req_data_byte_mask_selected;
	wire [(N_STB_ST_IN_PORT * 512) - 1:0] s1_st_req_data_bit_mask_selected;
	wire [(N_STB_ST_IN_PORT * 512) - 1:0] s1_upd_stb_entry_old_write_bit_mask;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_st_req_data_bit_mask
			for (j = 0; j < rvh_l1d_pkg_L1D_STB_DATA_WIDTH; j = j + 1) begin : genblk1
				assign s1_st_req_upd_old_bit_mask_interleaved[(i * 512) + j] = s1_st_req_upd_old_byte_mask_interleaved[(i * 64) + (j / 8)];
				assign s1_st_req_data_bit_mask_selected[(i * 512) + j] = s1_st_req_data_byte_mask_selected[(i * 64) + (j / 8)];
				assign s1_upd_stb_entry_old_write_bit_mask[(i * 512) + j] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + (7 + (j / 8))];
			end
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_st_req_data_selected
			assign s1_st_req_data_selected[i * 512+:512] = (st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + 32'd6) + (32'd5 + 32'd56)) + 74) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 9) : -1)] ? s1_st_req_data_merged : s1_st_req_data_transed[i * 512+:512]);
			assign s1_st_req_data_byte_mask_selected[i * 64+:64] = (st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + 32'd6) + (32'd5 + 32'd56)) + 74) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 11 : 1 - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10)) - 1) - (((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 9) : -1)] ? s1_st_req_data_byte_mask_merged : s1_st_req_data_byte_mask_transed_mid[i * 64+:64]);
			assign s1_st_req_upd_old_byte_mask_interleaved[i * 64+:64] = s1_st_req_data_byte_mask_selected[i * 64+:64] & upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 70-:64];
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s1_upd_stb_entry_new
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + (rvh_pkg_ROB_TAG_WIDTH + 643)-:((rvh_pkg_ROB_TAG_WIDTH + 643) >= 644 ? rvh_pkg_ROB_TAG_WIDTH : 645 - (rvh_pkg_ROB_TAG_WIDTH + 643))] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + (rvh_pkg_ROB_TAG_WIDTH + 643)-:((rvh_pkg_ROB_TAG_WIDTH + 643) >= 644 ? rvh_pkg_ROB_TAG_WIDTH : 645 - (rvh_pkg_ROB_TAG_WIDTH + 643))];
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 643-:32'd6] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 643-:32'd6];
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 637-:5] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 637-:5];
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 632-:50] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 632-:50];
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 70-:64] = s1_st_req_data_byte_mask_selected[i * 64+:64] | upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 70-:64];
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 582-:512] = (((s1_st_req_data_selected[i * 512+:512] & s1_st_req_data_bit_mask_selected[i * 512+:512]) | (upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 582-:512] & s1_upd_stb_entry_old_write_bit_mask[i * 512+:512])) & ~s1_st_req_upd_old_bit_mask_interleaved[i * 512+:512]) | (s1_st_req_data_selected[i * 512+:512] & s1_st_req_upd_old_bit_mask_interleaved[i * 512+:512]);
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 6] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 6];
			assign upd_stb_entry_new[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 5-:rvh_l1d_pkg_L1D_OFFSET_WIDTH] = upd_stb_entry_old[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 5-:rvh_l1d_pkg_L1D_OFFSET_WIDTH];
		end
		for (i = 0; i < N_STB; i = i + 1) begin : gen_stb_entry_nxt_ena
			for (j = 0; j < N_STB_ST_IN_PORT; j = j + 1) begin : gen_stb_entry_nxt_ena_per_input
				if (j == 0) begin : gen_stb_entry_nxt_new_ena_for_first_pipe
					assign stb_entry_nxt_new_ena_per_input[(i * N_STB_ST_IN_PORT) + j] = (((i[STB_ID_WIDHT - 1:0] == new_stb_entry_idx[j * STB_ID_WIDHT+:STB_ID_WIDHT]) & new_stb_entry_idx_vld[j]) & st_s1_valid[j]) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
					assign stb_entry_nxt_upd_ena_per_input[(i * N_STB_ST_IN_PORT) + j] = (((i[STB_ID_WIDHT - 1:0] == upd_stb_entry_idx[j * STB_ID_WIDHT+:STB_ID_WIDHT]) & upd_stb_entry_idx_vld[j]) & st_s1_valid[j]) & st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
				end
				else begin : gen_stb_entry_nxt_new_ena_for_other_pipe
					assign stb_entry_nxt_new_ena_per_input[(i * N_STB_ST_IN_PORT) + j] = ((((i[STB_ID_WIDHT - 1:0] == new_stb_entry_idx[j * STB_ID_WIDHT+:STB_ID_WIDHT]) & new_stb_entry_idx_vld[j]) & st_s1_valid[j]) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)]) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)];
					assign stb_entry_nxt_upd_ena_per_input[(i * N_STB_ST_IN_PORT) + j] = ((((i[STB_ID_WIDHT - 1:0] == upd_stb_entry_idx[j * STB_ID_WIDHT+:STB_ID_WIDHT]) & upd_stb_entry_idx_vld[j]) & st_s1_valid[j]) & st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)]) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)];
				end
			end
			assign stb_entry_nxt_new_ena_per_stb_entry[i] = |stb_entry_nxt_new_ena_per_input[i * N_STB_ST_IN_PORT+:N_STB_ST_IN_PORT];
			assign stb_entry_nxt_upd_ena_per_stb_entry[i] = |stb_entry_nxt_upd_ena_per_input[i * N_STB_ST_IN_PORT+:N_STB_ST_IN_PORT];
			assign stb_entry_nxt_set_ena[i] = stb_entry_nxt_new_ena_per_stb_entry[i] | stb_entry_nxt_upd_ena_per_stb_entry[i];
		end
	endgenerate
	assign stb_entry_nxt_clr_ena = stb_entry_nxt_clr_ena_selected_evict | stb_entry_nxt_clr_ena_in_age_evict;
	always @(*) begin : comb_stb_entry_nxt_clr_ena
		stb_entry_nxt_clr_ena_selected_evict = 1'sb0;
		stb_entry_nxt_clr_ena_in_age_evict = 1'sb0;
		if (stb_l1d_st_req_hsk)
			if (is_in_selected_evict_stb_evict_state)
				stb_entry_nxt_clr_ena_selected_evict = at_once_evict_mask;
			else if (is_in_in_age_evict_stb_evict_state | is_in_flush_stb_evict_state)
				stb_entry_nxt_clr_ena_in_age_evict = common_evict_mask;
	end
	reg [(N_STB * $clog2(N_STB_ST_IN_PORT)) - 1:0] stb_input_port_idx_per_new_stb_entry;
	reg [(N_STB * $clog2(N_STB_ST_IN_PORT)) - 1:0] stb_input_port_idx_per_upd_stb_entry;
	always @(*) begin : comb_stb_input_port_idx_per_new_stb_entry
		stb_input_port_idx_per_new_stb_entry = 1'sb0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < N_STB; i = i + 1)
				begin : sv2v_autoblock_4
					reg signed [31:0] j;
					for (j = 0; j < N_STB_ST_IN_PORT; j = j + 1)
						if (stb_entry_nxt_new_ena_per_input[(i * N_STB_ST_IN_PORT) + j])
							stb_input_port_idx_per_new_stb_entry[i * $clog2(N_STB_ST_IN_PORT)+:$clog2(N_STB_ST_IN_PORT)] = j[$clog2(N_STB_ST_IN_PORT) - 1:0];
				end
		end
	end
	always @(*) begin : comb_stb_input_port_idx_per_upd_stb_entry
		stb_input_port_idx_per_upd_stb_entry = 1'sb0;
		begin : sv2v_autoblock_5
			reg signed [31:0] i;
			for (i = 0; i < N_STB; i = i + 1)
				begin : sv2v_autoblock_6
					reg signed [31:0] j;
					for (j = 0; j < N_STB_ST_IN_PORT; j = j + 1)
						if (stb_entry_nxt_upd_ena_per_input[(i * N_STB_ST_IN_PORT) + j])
							stb_input_port_idx_per_upd_stb_entry[i * $clog2(N_STB_ST_IN_PORT)+:$clog2(N_STB_ST_IN_PORT)] = j[$clog2(N_STB_ST_IN_PORT) - 1:0];
				end
		end
	end
	generate
		for (i = 0; i < N_STB; i = i + 1) begin : gen_stb_entry_nxt
			assign stb_entry_nxt[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH] = (stb_entry_nxt_new_ena_per_stb_entry[i] ? new_stb_entry[stb_input_port_idx_per_new_stb_entry[i * $clog2(N_STB_ST_IN_PORT)+:$clog2(N_STB_ST_IN_PORT)] * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH] : upd_stb_entry_new[stb_input_port_idx_per_upd_stb_entry[i * $clog2(N_STB_ST_IN_PORT)+:$clog2(N_STB_ST_IN_PORT)] * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH]);
		end
		for (i = 0; i < N_STB; i = i + 1) begin : gen_update_stb
			std_dffre #(.WIDTH((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) U_L1D_STB_ENTRY(
				.clk(clk),
				.rstn(rst),
				.en(stb_entry_nxt_set_ena[i]),
				.d(stb_entry_nxt[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH]),
				.q(stb_entry[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH])
			);
		end
		for (i = 0; i < N_STB; i = i + 1) begin : gen_stb_entry_valid_nxt
			assign stb_entry_valid_nxt[i] = (stb_entry_nxt_set_ena[i] | stb_entry_valid[i]) & ~stb_entry_nxt_clr_ena[i];
		end
	endgenerate
	wire [N_STB - 1:0] stb_entry_valid_set_ena;
	wire [N_STB - 1:0] stb_entry_valid_clr_ena;
	assign stb_entry_valid_set_ena = stb_entry_nxt_set_ena;
	assign stb_entry_valid_clr_ena = stb_entry_nxt_clr_ena;
	assign stb_entry_valid_ena = stb_entry_nxt_set_ena | stb_entry_nxt_clr_ena;
	generate
		for (i = 0; i < N_STB; i = i + 1) begin : gen_update_stb_entry_valid
			std_dffre #(.WIDTH(1)) U_STB_ENTRY_VALID(
				.clk(clk),
				.rstn(rst),
				.en(stb_entry_valid_ena[i]),
				.d(stb_entry_valid_nxt[i]),
				.q(stb_entry_valid[i])
			);
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s0_ld_req_rdy
			assign ld_req_rdy[i] = (~is_in_flush_stb_evict_state & ~have_stb_entry_to_flush) & ~ptw_walk_req_vld_i;
			assign ls_pipe_stb_ld_req_rdy_o[i] = ld_req_rdy[i];
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s0_ld_req_hsk
			assign ld_req_hak[i] = (ls_pipe_stb_ld_req_vld_i[i] & ld_req_rdy[i]) & l1d_stb_st_req_rdy_i[i];
		end
	endgenerate
	assign ptw_req_rdy = ~is_in_flush_stb_evict_state & ~have_stb_entry_to_flush;
	assign ptw_walk_req_rdy_o = ptw_req_rdy;
	assign ptw_req_hak = (ptw_walk_req_vld_i & ptw_req_rdy) & ptw_walk_l1d_req_rdy_i;
	localparam rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH = 0;
	localparam rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH = rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	localparam rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH = $clog2(rvh_l1d_pkg_L1D_BANK_SET_NUM);
	localparam rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH = ((rvh_pkg_PADDR_WIDTH - rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) - rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH) - rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH;
	wire [(N_STB_LD_IN_PORT * rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) - 1:0] s1_ld_req_paddr_tag_from_tlb;
	wire [(N_STB_LD_IN_PORT * rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) - 1:0] s1_ld_req_line_paddr;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s1_ld_req_paddr_tag_from_tlb
			if ((rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH) >= 12) begin : gen_ptag_from_part_of_ppn
				assign s1_ld_req_paddr_tag_from_tlb[i * rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH+:rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH] = ls_pipe_stb_dtlb_resp_ppn_i[(i * riscv_pkg_PPN_WIDTH) + (43 >= (rvh_l1d_pkg_L1D_INDEX_WIDTH - 6) ? 43 : (43 + (43 >= (rvh_l1d_pkg_L1D_INDEX_WIDTH - 6) ? 56 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH) : (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 54)) - 1)-:(43 >= (rvh_l1d_pkg_L1D_INDEX_WIDTH - 6) ? 56 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH) : (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 54)];
			end
			else begin : gen_ptag_from_ppn_plus_part_of_vtag
				assign s1_ld_req_paddr_tag_from_tlb[i * rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH+:rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH] = {ls_pipe_stb_dtlb_resp_ppn_i[i * riscv_pkg_PPN_WIDTH+:riscv_pkg_PPN_WIDTH], ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))))) >= (((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1)))) ? (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH))))) : (((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH)))))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))))) >= (((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1)))) ? (((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH)))))) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1))))) + 1 : (((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1)))) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH))))))) + 1)) - 1)-:((((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))))) >= (((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1)))) ? (((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH)))))) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1))))) + 1 : (((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_TAG_WIDTH - 1)))) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - ((rvh_l1d_pkg_L1D_TAG_WIDTH - 1) - (12 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH))))))) + 1)]};
			end
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s1_ld_req_line_paddr
			assign s1_ld_req_line_paddr[i * rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE+:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] = (ld_cur[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 16))) + (((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) - ((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 5) - (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))] ? {ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))-:((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) >= (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6) ? ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)) + 1 : ((rvh_l1d_pkg_L1D_INDEX_WIDTH + 6) - (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))) + 1)], ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))-:((rvh_l1d_pkg_L1D_INDEX_WIDTH + 5) >= 6 ? rvh_l1d_pkg_L1D_INDEX_WIDTH : 7 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))]} : {s1_ld_req_paddr_tag_from_tlb[i * rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH+:rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH], ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))-:((rvh_l1d_pkg_L1D_INDEX_WIDTH + 5) >= 6 ? rvh_l1d_pkg_L1D_INDEX_WIDTH : 7 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))]});
		end
	endgenerate
	wire [(N_STB_LD_IN_PORT * N_STB) - 1:0] ld_req_hit_stb_per_entry;
	wire [(N_STB_LD_IN_PORT * N_STB_ST_IN_PORT) - 1:0] ld_req_hit_st_pipe_s1_per_entry;
	wire [((N_STB_LD_IN_PORT * N_STB) * N_STB_ST_IN_PORT) - 1:0] ld_req_hit_st_pipe_s1_per_entry_trans_mid;
	wire [(N_STB_LD_IN_PORT * N_STB) - 1:0] ld_req_hit_st_pipe_s1_per_entry_trans;
	wire [N_STB_LD_IN_PORT - 1:0] ld_req_hit_stb;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_ld_req_hit_stb_per_entry
			for (j = 0; j < N_STB; j = j + 1) begin : genblk1
				assign ld_req_hit_stb_per_entry[(i * N_STB) + j] = (stb_entry_valid[j] & (s1_ld_req_line_paddr[i * rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE+:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == stb_entry[(j * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 632-:50])) | ld_req_hit_st_pipe_s1_per_entry_trans[(i * N_STB) + j];
			end
			assign ld_req_hit_stb[i] = |ld_req_hit_stb_per_entry[i * N_STB+:N_STB];
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_ld_req_hit_st_pipe_s1_per_entry_trans
			for (j = 0; j < N_STB; j = j + 1) begin : genblk1
				for (k = 0; k < N_STB_ST_IN_PORT; k = k + 1) begin : genblk1
					assign ld_req_hit_st_pipe_s1_per_entry_trans_mid[(((i * N_STB) + j) * N_STB_ST_IN_PORT) + k] = (stb_entry_nxt_new_ena_per_input[(j * N_STB_ST_IN_PORT) + k] | stb_entry_nxt_upd_ena_per_input[(j * N_STB_ST_IN_PORT) + k]) & ld_req_hit_st_pipe_s1_per_entry[(i * N_STB_ST_IN_PORT) + k];
				end
				assign ld_req_hit_st_pipe_s1_per_entry_trans[(i * N_STB) + j] = |ld_req_hit_st_pipe_s1_per_entry_trans_mid[((i * N_STB) + j) * N_STB_ST_IN_PORT+:N_STB_ST_IN_PORT];
			end
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_ld_req_hit_st_pipe_s1_per_entry
			for (j = 0; j < N_STB_ST_IN_PORT; j = j + 1) begin : genblk1
				if (j == 0) begin : gen_ld_req_hit_st_pipe_s1_per_entry_from_first_st_pipe
					assign ld_req_hit_st_pipe_s1_per_entry[(i * N_STB_ST_IN_PORT) + j] = (st_s1_valid[j] & (s1_ld_req_line_paddr[i * rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE+:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 129) : rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE - 131)-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE])) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
				end
				else begin : gen_ld_req_hit_st_pipe_s1_per_entry_from_other_st_pipe
					assign ld_req_hit_st_pipe_s1_per_entry[(i * N_STB_ST_IN_PORT) + j] = ((st_s1_valid[j] & (s1_ld_req_line_paddr[i * rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE+:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE] == st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 129) : rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE - 131)-:rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE])) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)]) & ~st_cur[(j * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)];
				end
			end
		end
	endgenerate
	wire [(N_STB_LD_IN_PORT * 64) - 1:0] s2_ld_req_data_byte_mask_transed;
	wire [(N_STB_LD_IN_PORT * 512) - 1:0] s2_ld_req_data_bit_mask_transed;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s2_ld_xlen_stb_length_trans
			rrv2rvh_ruby_ldmask_trans stb_ldmask_trans_ld_req_u(
				.ld_offset_i(ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 15))-:6]),
				.ld_opcode_i(ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 19))-:3]),
				.ls_pipe_l1d_ld_req_data_byte_mask_o(s2_ld_req_data_byte_mask_transed[i * 64+:64])
			);
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s2_ld_req_data_bit_mask_transed
			for (j = 0; j < rvh_l1d_pkg_L1D_STB_DATA_WIDTH; j = j + 1) begin : genblk1
				assign s2_ld_req_data_bit_mask_transed[(i * 512) + j] = s2_ld_req_data_byte_mask_transed[(i * 64) + (j / 8)];
			end
		end
	endgenerate
	always @(*) begin : sv2v_autoblock_7
		reg signed [31:0] i;
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1)
			begin
				bps_stb_entry[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH] = 1'sb0;
				begin : sv2v_autoblock_8
					reg signed [31:0] j;
					for (j = 0; j < N_STB; j = j + 1)
						if (ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (0 + j)))])
							bps_stb_entry[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH] = stb_entry[j * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH];
				end
			end
	end
	wire [(N_STB_LD_IN_PORT * 64) - 1:0] s2_ld_req_data_byte_mask_interleaved;
	wire [N_STB_LD_IN_PORT - 1:0] s2_ld_req_data_byte_mask_interleaved_equal;
	wire [N_STB_LD_IN_PORT - 1:0] s2_ld_req_data_byte_mask_interleaved_valid;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s2_ld_req_data_byte_mask_interleaved
			assign s2_ld_req_data_byte_mask_interleaved[i * 64+:64] = s2_ld_req_data_byte_mask_transed[i * 64+:64] & bps_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 70-:64];
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_stb_ld_bypass_hit
			assign s2_ld_req_data_byte_mask_interleaved_equal[i] = s2_ld_req_data_byte_mask_interleaved[i * 64+:64] == s2_ld_req_data_byte_mask_transed[i * 64+:64];
			assign s2_ld_req_data_byte_mask_interleaved_valid[i] = |s2_ld_req_data_byte_mask_interleaved[i * 64+:64];
			assign stb_ld_bypass_full_hit[i] = s2_ld_req_data_byte_mask_interleaved_equal[i];
			assign stb_ld_bypass_partial_hit[i] = ~s2_ld_req_data_byte_mask_interleaved_equal[i] & s2_ld_req_data_byte_mask_interleaved_valid[i];
			assign stb_ld_bypass_miss[i] = ~s2_ld_req_data_byte_mask_interleaved_valid[i];
		end
	endgenerate
	wire [(N_STB_LD_IN_PORT * 512) - 1:0] full_hit_line_data_mid;
	wire [(N_STB_LD_IN_PORT * 512) - 1:0] full_hit_xlen_data;
	localparam rvh_l1d_pkg_L1D_BIT_OFFSET_WIDTH = 9;
	wire [(N_STB_LD_IN_PORT * rvh_l1d_pkg_L1D_BIT_OFFSET_WIDTH) - 1:0] ld_cur_s2_bit_offset;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_full_hit_line_data
			assign ld_cur_s2_bit_offset[i * rvh_l1d_pkg_L1D_BIT_OFFSET_WIDTH+:rvh_l1d_pkg_L1D_BIT_OFFSET_WIDTH] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 15))-:6] << 3;
			assign full_hit_line_data_mid[i * 512+:512] = (s2_ld_req_data_bit_mask_transed[i * 512+:512] & bps_stb_entry[(i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) + 582-:512]) >> ld_cur_s2_bit_offset[i * rvh_l1d_pkg_L1D_BIT_OFFSET_WIDTH+:rvh_l1d_pkg_L1D_BIT_OFFSET_WIDTH];
			assign full_hit_xlen_data[i * 512+:512] = full_hit_line_data_mid[(i * 512) + 63-:rvh_pkg_XLEN];
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_wb_vld_for_load_bypass_o
			assign stb_rob_wb_vld_o[i] = (ld_s2_valid[i] & stb_ld_bypass_full_hit[i]) & (~kill_ld_req_i | ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 16))]);
			assign stb_int_prf_wb_vld_o[i] = stb_rob_wb_vld_o[i];
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_wb_dat_o
			assign stb_rob_wb_rob_tag_o[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (rvh_pkg_ROB_TAG_WIDTH + 24)))-:((rvh_pkg_ROB_TAG_WIDTH + 24) >= 25 ? rvh_pkg_ROB_TAG_WIDTH : 26 - (rvh_pkg_ROB_TAG_WIDTH + 24))];
			assign stb_int_prf_wb_tag_o[i * rvh_pkg_INT_PREG_TAG_WIDTH+:rvh_pkg_INT_PREG_TAG_WIDTH] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 25))-:32'd6];
			assign stb_int_prf_wb_data_o[i * rvh_pkg_XLEN+:rvh_pkg_XLEN] = full_hit_xlen_data[i * 512+:512];
			assign stb_l1d_arb_bank_id_o[i+:1] = 0;
		end
	endgenerate
	reg [(N_STB_LD_IN_PORT * N_STB) - 1:0] stb_entry_evict_at_once_nxt_mid;
	wire [(N_STB * N_STB_LD_IN_PORT) - 1:0] stb_entry_evict_at_once_nxt_mid_trans;
	always @(*) begin : comb_stb_entry_evict_at_once_nxt_mid
		begin : sv2v_autoblock_9
			reg signed [31:0] i;
			for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1)
				begin
					stb_entry_evict_at_once_nxt_mid[i * N_STB+:N_STB] = stb_entry_evict_at_once;
					if (stb_l1d_ld_partial_hit_replay_o[i])
						stb_entry_evict_at_once_nxt_mid[i * N_STB+:N_STB] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8))-:rvh_l1d_pkg_L1D_STB_ENTRY_NUM] | stb_entry_evict_at_once;
				end
		end
	end
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_stb_entry_evict_at_once_nxt_mid_trans
			for (j = 0; j < N_STB; j = j + 1) begin : genblk1
				assign stb_entry_evict_at_once_nxt_mid_trans[(j * N_STB_LD_IN_PORT) + i] = stb_entry_evict_at_once_nxt_mid[(i * N_STB) + j];
			end
		end
		for (i = 0; i < N_STB; i = i + 1) begin : gen_stb_entry_evict_at_once_nxt
			assign stb_entry_evict_at_once_nxt[i] = |stb_entry_evict_at_once_nxt_mid_trans[i * N_STB_LD_IN_PORT+:N_STB_LD_IN_PORT] & ~stb_entry_nxt_new_ena_per_stb_entry[i];
		end
	endgenerate
	wire [N_STB - 1:0] stb_entry_evict_at_once_set_ena;
	wire [N_STB - 1:0] stb_entry_evict_at_once_clr_ena;
	assign stb_entry_evict_at_once_set_ena = {N_STB {{|stb_l1d_ld_partial_hit_replay_o}}};
	assign stb_entry_evict_at_once_clr_ena = stb_entry_valid_set_ena;
	assign stb_entry_evict_at_once_ena = stb_entry_evict_at_once_set_ena | stb_entry_evict_at_once_clr_ena;
	generate
		for (i = 0; i < N_STB; i = i + 1) begin : gen_stb_entry_evict_at_once
			std_dffre #(.WIDTH(1)) U_STB_ENTRY_EVICT_AT_ONCE(
				.clk(clk),
				.rstn(rst),
				.en(stb_entry_evict_at_once_ena[i]),
				.d(stb_entry_evict_at_once_nxt[i]),
				.q(stb_entry_evict_at_once[i])
			);
		end
	endgenerate
	wire [N_STB_ST_IN_PORT - 1:0] s1_st_req_in_valid;
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : genblk36
			if (i == 0) begin : gen_s1_st_req_in_valid_for_first_pipe
				assign s1_st_req_in_valid[i] = st_s1_valid[i] & ~st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)];
			end
			else begin : gen_s1_st_req_in_valid_for_other_pipe
				assign s1_st_req_in_valid[i] = (st_s1_valid[i] & ~st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)]) & ~st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)];
			end
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_stb_entry_nxt_ena_per_input_trans
			for (j = 0; j < N_STB; j = j + 1) begin : genblk1
				assign stb_entry_nxt_new_ena_per_input_trans[(i * N_STB) + j] = stb_entry_nxt_new_ena_per_input[(j * N_STB_ST_IN_PORT) + i];
				assign stb_entry_nxt_upd_ena_per_input_trans[(i * N_STB) + j] = stb_entry_nxt_upd_ena_per_input[(j * N_STB_ST_IN_PORT) + i];
			end
		end
	endgenerate
	AgeMatrixSelector #(
		.EntryCount(N_STB),
		.EnqWidth(N_STB_ST_IN_PORT),
		.SelWidth(1)
	) stb_entry_age_matrix_for_at_once_evict_u(
		.enq_fire_i(s1_st_req_in_valid),
		.enq_mask_i(stb_entry_nxt_new_ena_per_input_trans),
		.deq_fire_i(|stb_entry_valid_clr_ena),
		.deq_mask_i(stb_entry_nxt_clr_ena),
		.sel_mask_i(stb_entry_evict_at_once & stb_entry_valid),
		.result_mask_o(at_once_evict_mask),
		.entry_vld_i(stb_entry_valid),
		.clk(clk),
		.rstn(rst)
	);
	AgeMatrixSelector #(
		.EntryCount(N_STB),
		.EnqWidth(N_STB_ST_IN_PORT),
		.SelWidth(1)
	) stb_entry_age_matrix_for_common_evict_u(
		.enq_fire_i(s1_st_req_in_valid),
		.enq_mask_i(stb_entry_nxt_new_ena_per_input_trans),
		.deq_fire_i(|stb_entry_valid_clr_ena),
		.deq_mask_i(stb_entry_nxt_clr_ena),
		.sel_mask_i(stb_entry_valid),
		.result_mask_o(common_evict_mask),
		.entry_vld_i(stb_entry_valid),
		.clk(clk),
		.rstn(rst)
	);
	assign stb_l1d_st_req_hsk = stb_l1d_st_req_vld_o & stb_l1d_st_req_rdy_i;
	assign have_stb_entry_to_flush = |(ls_pipe_stb_st_req_vld_i & ls_pipe_l1d_st_req_is_fence_i) | fencei_flush_hsk;
	assign have_stb_entry_to_evict_at_once = |(at_once_evict_mask | stb_entry_evict_at_once_set_ena);
	assign have_stb_entry_to_evict_in_age = |common_evict_mask & ~free_stb_entry_num_more_or_equal_two;
	always @(*) begin : case_stb_evict_state_d
		stb_evict_state_d = 2'd0;
		stb_evict_state_d_ena = 1'b0;
		case (stb_evict_state_q)
			2'd0:
				if (have_stb_entry_to_flush) begin
					stb_evict_state_d = 2'd3;
					stb_evict_state_d_ena = 1'b1;
				end
				else if (have_stb_entry_to_evict_at_once) begin
					stb_evict_state_d = 2'd2;
					stb_evict_state_d_ena = 1'b1;
				end
				else if (have_stb_entry_to_evict_in_age) begin
					stb_evict_state_d = 2'd1;
					stb_evict_state_d_ena = 1'b1;
				end
			2'd2:
				if (have_stb_entry_to_flush) begin
					stb_evict_state_d = 2'd3;
					stb_evict_state_d_ena = 1'b1;
				end
				else if (stb_l1d_st_req_hsk | ~have_stb_entry_to_evict_at_once) begin
					if (have_stb_entry_to_evict_at_once) begin
						stb_evict_state_d = 2'd2;
						stb_evict_state_d_ena = 1'b0;
					end
					else if (have_stb_entry_to_evict_in_age) begin
						stb_evict_state_d = 2'd1;
						stb_evict_state_d_ena = 1'b1;
					end
					else begin
						stb_evict_state_d = 2'd0;
						stb_evict_state_d_ena = 1'b1;
					end
				end
				else begin
					stb_evict_state_d = 2'd2;
					stb_evict_state_d_ena = 1'b0;
				end
			2'd1:
				if (have_stb_entry_to_flush) begin
					stb_evict_state_d = 2'd3;
					stb_evict_state_d_ena = 1'b1;
				end
				else if (stb_l1d_st_req_hsk | ~have_stb_entry_to_evict_in_age) begin
					if (have_stb_entry_to_evict_at_once) begin
						stb_evict_state_d = 2'd2;
						stb_evict_state_d_ena = 1'b1;
					end
					else if (have_stb_entry_to_evict_in_age) begin
						stb_evict_state_d = 2'd1;
						stb_evict_state_d_ena = 1'b0;
					end
					else begin
						stb_evict_state_d = 2'd0;
						stb_evict_state_d_ena = 1'b1;
					end
				end
				else begin
					stb_evict_state_d = 2'd1;
					stb_evict_state_d_ena = 1'b0;
				end
			2'd3:
				if (|stb_entry_valid == 1'b1) begin
					stb_evict_state_d = 2'd3;
					stb_evict_state_d_ena = 1'b0;
				end
				else begin
					stb_evict_state_d = 2'd0;
					stb_evict_state_d_ena = 1'b1;
				end
			default: begin
				stb_evict_state_d = 2'd0;
				stb_evict_state_d_ena = 1'b1;
			end
		endcase
	end
	always @(*) begin : comb_select_out_selected_stb_entry
		out_selected_stb_entry_valid = 1'b0;
		out_selected_stb_entry = 1'sb0;
		begin : sv2v_autoblock_10
			reg signed [31:0] i;
			for (i = 0; i < N_STB; i = i + 1)
				if (at_once_evict_mask[i]) begin
					out_selected_stb_entry_valid = stb_entry_valid[i];
					out_selected_stb_entry = stb_entry[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH];
				end
		end
	end
	always @(*) begin : comb_select_out_in_age_stb_entry
		out_in_age_stb_entry_valid = 1'b0;
		out_in_age_stb_entry = 1'sb0;
		begin : sv2v_autoblock_11
			reg signed [31:0] i;
			for (i = 0; i < N_STB; i = i + 1)
				if (common_evict_mask[i]) begin
					out_in_age_stb_entry_valid = stb_entry_valid[i];
					out_in_age_stb_entry = stb_entry[i * ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)+:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_l1d_pkg_L1D_STB_LINE_ADDR_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 65) + rvh_l1d_pkg_L1D_OFFSET_WIDTH];
				end
		end
	end
	wire [N_STB_LD_IN_PORT - 1:0] out_selected_stb_entry_hited_at_ld_s1_per_input;
	wire [N_STB_LD_IN_PORT - 1:0] out_in_age_stb_entry_hited_at_ld_s1_per_input;
	wire [N_STB_ST_IN_PORT - 1:0] out_selected_stb_entry_hited_at_st_s1_per_input;
	wire [N_STB_ST_IN_PORT - 1:0] out_in_age_stb_entry_hited_at_st_s1_per_input;
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_out_stb_entry_hited_at_ld_s1_per_input
			assign out_selected_stb_entry_hited_at_ld_s1_per_input[i] = ld_s1_valid[i] & |(ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8))-:rvh_l1d_pkg_L1D_STB_ENTRY_NUM] & at_once_evict_mask);
			assign out_in_age_stb_entry_hited_at_ld_s1_per_input[i] = ld_s1_valid[i] & |(ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8))-:rvh_l1d_pkg_L1D_STB_ENTRY_NUM] & common_evict_mask);
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_out_stb_entry_hited_at_st_s0_per_input
			assign out_selected_stb_entry_hited_at_st_s1_per_input[i] = st_s1_valid[i] & |(st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8) : -2)-:8] & at_once_evict_mask);
			assign out_in_age_stb_entry_hited_at_st_s1_per_input[i] = st_s1_valid[i] & |(st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8) : -2)-:8] & common_evict_mask);
		end
	endgenerate
	assign out_selected_stb_entry_hited_at_ld_s1 = |out_selected_stb_entry_hited_at_ld_s1_per_input;
	assign out_in_age_stb_entry_hited_at_ld_s1 = |out_in_age_stb_entry_hited_at_ld_s1_per_input;
	assign out_selected_stb_entry_hited_at_st_s1 = |out_selected_stb_entry_hited_at_st_s1_per_input;
	assign out_in_age_stb_entry_hited_at_st_s1 = |out_in_age_stb_entry_hited_at_st_s1_per_input;
	always @(*) begin : comb_stb_evict_state_fsm_output
		stb_l1d_st_req_vld_o = 1'sb0;
		stb_l1d_st_req_rob_tag_o = 1'sb0;
		stb_l1d_st_req_prd_o = 1'sb0;
		stb_l1d_st_req_opcode_o = 1'sb0;
		stb_l1d_st_req_paddr_o = 1'sb0;
		stb_l1d_st_req_data_o = 1'sb0;
		stb_l1d_st_req_data_byte_mask_o = 1'sb0;
		stb_l1d_st_req_sc_rt_check_succ_o = 1'sb0;
		stb_l1d_st_req_amo_offset_o = 1'sb0;
		is_in_flush_stb_evict_state = 1'sb0;
		is_in_selected_evict_stb_evict_state = 1'sb0;
		is_in_in_age_evict_stb_evict_state = 1'sb0;
		begin : sv2v_autoblock_12
			reg signed [31:0] i;
			for (i = N_STB_LD_IN_PORT; i < (N_STB_LD_IN_PORT + N_STB_ST_IN_PORT); i = i + 1)
				;
		end
		case (stb_evict_state_q)
			2'd0:
				;
			2'd2:
				if (|at_once_evict_mask) begin
					stb_l1d_st_req_vld_o = (out_selected_stb_entry_valid & ~out_selected_stb_entry_hited_at_ld_s1) & ~out_selected_stb_entry_hited_at_st_s1;
					stb_l1d_st_req_rob_tag_o = out_selected_stb_entry[rvh_pkg_ROB_TAG_WIDTH + 643-:((rvh_pkg_ROB_TAG_WIDTH + 643) >= 644 ? rvh_pkg_ROB_TAG_WIDTH : 645 - (rvh_pkg_ROB_TAG_WIDTH + 643))];
					stb_l1d_st_req_prd_o = out_selected_stb_entry[643-:32'd6];
					stb_l1d_st_req_opcode_o = out_selected_stb_entry[637-:5];
					stb_l1d_st_req_paddr_o = {out_selected_stb_entry[632-:50], {rvh_l1d_pkg_L1D_OFFSET_WIDTH {1'b0}}};
					stb_l1d_st_req_data_o = out_selected_stb_entry[582-:512];
					stb_l1d_st_req_data_byte_mask_o = out_selected_stb_entry[70-:64];
					stb_l1d_st_req_sc_rt_check_succ_o = out_selected_stb_entry[6];
					stb_l1d_st_req_amo_offset_o = out_selected_stb_entry[5-:rvh_l1d_pkg_L1D_OFFSET_WIDTH];
					is_in_selected_evict_stb_evict_state = 1'b1;
				end
			2'd1:
				if (|common_evict_mask) begin
					stb_l1d_st_req_vld_o = (out_in_age_stb_entry_valid & ~out_in_age_stb_entry_hited_at_ld_s1) & ~out_in_age_stb_entry_hited_at_st_s1;
					stb_l1d_st_req_rob_tag_o = out_in_age_stb_entry[rvh_pkg_ROB_TAG_WIDTH + 643-:((rvh_pkg_ROB_TAG_WIDTH + 643) >= 644 ? rvh_pkg_ROB_TAG_WIDTH : 645 - (rvh_pkg_ROB_TAG_WIDTH + 643))];
					stb_l1d_st_req_prd_o = out_in_age_stb_entry[643-:32'd6];
					stb_l1d_st_req_opcode_o = out_in_age_stb_entry[637-:5];
					stb_l1d_st_req_paddr_o = {out_in_age_stb_entry[632-:50], {rvh_l1d_pkg_L1D_OFFSET_WIDTH {1'b0}}};
					stb_l1d_st_req_data_o = out_in_age_stb_entry[582-:512];
					stb_l1d_st_req_data_byte_mask_o = out_in_age_stb_entry[70-:64];
					stb_l1d_st_req_sc_rt_check_succ_o = out_in_age_stb_entry[6];
					stb_l1d_st_req_amo_offset_o = out_in_age_stb_entry[5-:rvh_l1d_pkg_L1D_OFFSET_WIDTH];
					is_in_in_age_evict_stb_evict_state = 1'b1;
				end
			2'd3: begin
				is_in_flush_stb_evict_state = 1'b1;
				if (|common_evict_mask) begin
					stb_l1d_st_req_vld_o = (out_in_age_stb_entry_valid & ~out_in_age_stb_entry_hited_at_ld_s1) & ~out_in_age_stb_entry_hited_at_st_s1;
					stb_l1d_st_req_rob_tag_o = out_in_age_stb_entry[rvh_pkg_ROB_TAG_WIDTH + 643-:((rvh_pkg_ROB_TAG_WIDTH + 643) >= 644 ? rvh_pkg_ROB_TAG_WIDTH : 645 - (rvh_pkg_ROB_TAG_WIDTH + 643))];
					stb_l1d_st_req_prd_o = out_in_age_stb_entry[643-:32'd6];
					stb_l1d_st_req_opcode_o = out_in_age_stb_entry[637-:5];
					stb_l1d_st_req_paddr_o = {out_in_age_stb_entry[632-:50], {rvh_l1d_pkg_L1D_OFFSET_WIDTH {1'b0}}};
					stb_l1d_st_req_data_o = out_in_age_stb_entry[582-:512];
					stb_l1d_st_req_data_byte_mask_o = out_in_age_stb_entry[70-:64];
					stb_l1d_st_req_sc_rt_check_succ_o = out_in_age_stb_entry[6];
					stb_l1d_st_req_amo_offset_o = out_in_age_stb_entry[5-:rvh_l1d_pkg_L1D_OFFSET_WIDTH];
				end
			end
			default:
				;
		endcase
	end
	assign stb_rob_wb_vld_o[(N_STB_LD_IN_PORT + N_STB_ST_IN_PORT) - 1:N_STB_LD_IN_PORT + 1] = 1'sb0;
	assign stb_rob_wb_vld_o[N_STB_LD_IN_PORT] = |((ls_pipe_stb_st_req_vld_i & ls_pipe_l1d_st_req_is_fence_i) & ls_pipe_stb_st_req_rdy_o) & ~ls_pipe_l1d_st_req_no_fence_wb_resp_i;
	assign stb_rob_wb_rob_tag_o[N_STB_LD_IN_PORT * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] = flush_req_rob_tag_nxt;
	always @(*) begin
		flush_req_rob_tag_ena = 1'b0;
		flush_req_rob_tag_nxt = 1'sb0;
		begin : sv2v_autoblock_13
			reg signed [31:0] i;
			for (i = N_STB_ST_IN_PORT - 1; i >= 0; i = i - 1)
				if (ls_pipe_stb_st_req_vld_i[i] & ls_pipe_l1d_st_req_is_fence_i[i]) begin
					flush_req_rob_tag_nxt = ls_pipe_stb_st_req_rob_tag_i[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
					flush_req_rob_tag_ena = 1'b1;
				end
		end
	end
	std_dffre #(.WIDTH(rvh_pkg_ROB_TAG_WIDTH)) U_FLUSH_REQ_ROB_TAG_REG(
		.clk(clk),
		.rstn(rst),
		.en(flush_req_rob_tag_ena),
		.d(flush_req_rob_tag_nxt),
		.q(flush_req_rob_tag)
	);
	std_dffrve #(.WIDTH(2)) U_ST_EVICT_STATE_REG(
		.clk(clk),
		.rstn(rst),
		.rst_val(2'd0),
		.en(stb_evict_state_d_ena),
		.d(stb_evict_state_d),
		.q(stb_evict_state_q)
	);
	generate
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s0_st_nxt_s1
			assign st_s1_valid_nxt[i] = st_req_hak[i] & ~ls_pipe_l1d_st_req_is_fence_i[i];
			assign st_s1_nxt_ena[i] = st_s1_valid_nxt[i];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1) - (rvh_pkg_ROB_TAG_WIDTH + 141)) : (((rvh_pkg_ROB_TAG_WIDTH + 141) >= 142 ? rvh_pkg_ROB_TAG_WIDTH : 143 - (rvh_pkg_ROB_TAG_WIDTH + 141)) - (rvh_pkg_ROB_TAG_WIDTH + 141)) - 1)-:((rvh_pkg_ROB_TAG_WIDTH + 141) >= 142 ? rvh_pkg_ROB_TAG_WIDTH : 143 - (rvh_pkg_ROB_TAG_WIDTH + 141))] = ls_pipe_stb_st_req_rob_tag_i[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 140) : -136)-:32'd6] = ls_pipe_stb_st_req_prd_i[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 134) : -131)-:5] = ls_pipe_stb_st_req_opcode_i[i * uop_encoding_pkg_STU_OP_WIDTH+:uop_encoding_pkg_STU_OP_WIDTH];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 129) : -75)-:56] = ls_pipe_stb_st_req_paddr_i[i * rvh_pkg_PADDR_WIDTH+:rvh_pkg_PADDR_WIDTH];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 73) : -11)-:64] = ls_pipe_stb_st_req_data_i[i * rvh_pkg_XLEN+:rvh_pkg_XLEN];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9) : -10)] = st_req_hit_stb[i];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8) : -2)-:8] = st_req_hit_stb_per_entry[i * N_STB+:N_STB];
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) : -1)] = st_req_hit_the_same_cache_line;
			assign st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + ((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1) : 0)] = ls_pipe_l1d_st_req_sc_rt_check_succ_i;
		end
		for (i = 0; i < N_STB_ST_IN_PORT; i = i + 1) begin : gen_s0_st_cur_s1
			std_dffr #(.WIDTH(1)) U_ST_STG_VALID_REG_S1(
				.clk(clk),
				.rstn(rst),
				.d(st_s1_valid_nxt[i]),
				.q(st_s1_valid[i])
			);
			std_dffe #(.WIDTH(((((rvh_pkg_ROB_TAG_WIDTH + 32'd6) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)))) U_ST_STG_DAT_REG_S1(
				.clk(clk),
				.en(st_s1_nxt_ena[i]),
				.d(st_nxt[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1)-:((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))]),
				.q(st_cur[(i * ((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + (32'd5 + 32'd56)) + 74) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))) + (((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1)) - 1)-:((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd5)) + (32'd56 + 32'd64)) + 10) >= 0 ? ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 2 : 1 - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_STU_OP_WIDTH) + rvh_pkg_PADDR_WIDTH) + rvh_pkg_XLEN) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 1))])
			);
		end
	endgenerate
	function automatic [2:0] sv2v_cast_11527;
		input reg [2:0] inp;
		sv2v_cast_11527 = inp;
	endfunction
	generate
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s0_ld_nxt_s1
			if (i == 0) begin : gen_first_ld_req_with_ptw
				assign ld_s1_valid_nxt[i] = ((ld_req_hak[i] | ptw_req_hak) & ~have_stb_entry_to_flush) & (~kill_ld_req_i | ptw_req_hak);
			end
			else begin : gen_other_ld_req_without_ptw
				assign ld_s1_valid_nxt[i] = (ld_req_hak[i] & ~have_stb_entry_to_flush) & ~kill_ld_req_i;
			end
			assign ld_s1_nxt_ena[i] = ld_s1_valid_nxt[i];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))))))-:((rvh_pkg_ROB_TAG_WIDTH + (10 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))) >= (10 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) ? ((rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))) - (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))))) + 1 : ((rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))))) - (rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))))) + 1)] = (ld_req_hak[i] ? ls_pipe_stb_ld_req_rob_tag_i[i * rvh_pkg_ROB_TAG_WIDTH+:rvh_pkg_ROB_TAG_WIDTH] : ptw_walk_req_id_i);
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))))-:((10 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))) >= (4 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) ? ((rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))) - (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))))) + 1 : ((uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))) - (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))) + 1)] = ls_pipe_stb_ld_req_prd_i[i * rvh_pkg_PREG_TAG_WIDTH+:rvh_pkg_PREG_TAG_WIDTH];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))))-:((4 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))) >= (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) ? ((uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))) - (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))) + 1 : ((1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) - (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))) + 1)] = (ld_req_hak[i] ? ls_pipe_stb_ld_req_opcode_i[i * uop_encoding_pkg_LDU_OP_WIDTH+:uop_encoding_pkg_LDU_OP_WIDTH] : sv2v_cast_11527(6));
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))] = ptw_req_hak;
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))-:((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) >= (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6) ? ((rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)) - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)) + 1 : ((rvh_l1d_pkg_L1D_INDEX_WIDTH + 6) - (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))) + 1)] = (ld_req_hak[i] ? ls_pipe_stb_ld_req_vtag_i[i * rvh_l1d_pkg_L1D_TAG_WIDTH+:rvh_l1d_pkg_L1D_TAG_WIDTH] : ptw_walk_req_addr_i[55-:rvh_l1d_pkg_L1D_TAG_WIDTH]);
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))-:((rvh_l1d_pkg_L1D_INDEX_WIDTH + 5) >= 6 ? rvh_l1d_pkg_L1D_INDEX_WIDTH : 7 - (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))] = (ld_req_hak[i] ? ls_pipe_stb_ld_req_idx_i[i * rvh_l1d_pkg_L1D_INDEX_WIDTH+:rvh_l1d_pkg_L1D_INDEX_WIDTH] : ptw_walk_req_addr_i[(rvh_l1d_pkg_L1D_INDEX_WIDTH + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1:rvh_l1d_pkg_L1D_OFFSET_WIDTH]);
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 6))-:rvh_l1d_pkg_L1D_OFFSET_WIDTH] = (ld_req_hak[i] ? ls_pipe_stb_ld_req_offset_i[i * rvh_l1d_pkg_L1D_OFFSET_WIDTH+:rvh_l1d_pkg_L1D_OFFSET_WIDTH] : ptw_walk_req_addr_i[5:0]);
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s0_ld_cur_s1
			std_dffr #(.WIDTH(1)) U_LD_STG_VALID_REG_S1(
				.clk(clk),
				.rstn(rst),
				.d(ld_s1_valid_nxt[i]),
				.q(ld_s1_valid[i])
			);
			std_dffe #(.WIDTH((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH)) U_LD_STG_DAT_REG_S1(
				.clk(clk),
				.en(ld_s1_nxt_ena[i]),
				.d(ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1))-:(((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) >= ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 16) ? ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0)) + 1 : ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1))) + 1)]),
				.q(ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1))-:(((((((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + 6) + ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 15)) >= ((rvh_pkg_ROB_TAG_WIDTH + (32'd6 + 32'd3)) + 16) ? ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0)) + 1 : ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) + 0) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1))) + 1)])
			);
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s1_ld_nxt_s2
			assign ld_s2_valid_nxt[i] = ld_s1_valid[i] & (((ls_pipe_stb_dtlb_resp_vld_i[i] & ls_pipe_stb_dtlb_resp_hit_i[i]) & ~kill_ld_req_i) | ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))]);
			assign ld_s2_nxt_ena[i] = ld_s2_valid_nxt[i];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (rvh_pkg_ROB_TAG_WIDTH + 24)))-:((rvh_pkg_ROB_TAG_WIDTH + 24) >= 25 ? rvh_pkg_ROB_TAG_WIDTH : 26 - (rvh_pkg_ROB_TAG_WIDTH + 24))] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))))))-:((rvh_pkg_ROB_TAG_WIDTH + (10 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))) >= (10 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) ? ((rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))) - (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))))) + 1 : ((rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))))) - (rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))))) + 1)];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 25))-:32'd6] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))))-:((10 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))) >= (4 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) ? ((rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))) - (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))))) + 1 : ((uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))) - (rvh_pkg_PREG_TAG_WIDTH + (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))) + 1)];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 19))-:3] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))))-:((4 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))) >= (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) ? ((uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))) - (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6)))) + 1 : ((1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 6))) - (uop_encoding_pkg_LDU_OP_WIDTH + (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5))))) + 1)];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 16))] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 1) - (1 + (rvh_l1d_pkg_L1D_TAG_WIDTH + (rvh_l1d_pkg_L1D_INDEX_WIDTH + 5)))))];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 15))-:6] = ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) - 6))-:rvh_l1d_pkg_L1D_OFFSET_WIDTH];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 9))] = ld_req_hit_stb[i];
			assign ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + ((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1) - (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 8))-:rvh_l1d_pkg_L1D_STB_ENTRY_NUM] = ld_req_hit_stb_per_entry[i * N_STB+:N_STB];
		end
		for (i = 0; i < N_STB_LD_IN_PORT; i = i + 1) begin : gen_s0_ld_cur_s2
			std_dffr #(.WIDTH(1)) U_LD_STG_VALID_REG_S2(
				.clk(clk),
				.rstn(rst),
				.d(ld_s2_valid_nxt[i]),
				.q(ld_s2_valid[i])
			);
			std_dffe #(.WIDTH((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM)) U_LD_STG_DAT_REG_S2(
				.clk(clk),
				.en(ld_s2_nxt_ena[i]),
				.d(ld_nxt[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)-:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM]),
				.q(ld_cur[(i * (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_TAG_WIDTH) + rvh_l1d_pkg_L1D_INDEX_WIDTH) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + ((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM))) + (((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM) - 1)-:(((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + uop_encoding_pkg_LDU_OP_WIDTH) + 1) + rvh_l1d_pkg_L1D_OFFSET_WIDTH) + 1) + rvh_l1d_pkg_L1D_STB_ENTRY_NUM])
			);
		end
	endgenerate
endmodule
