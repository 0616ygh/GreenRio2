module rvh_l1d_mlfb (
	clk,
	rstn,
	rob_flush_i,
	l1d_l2_rd_resp_valid,
	l1d_l2_rd_resp_ready,
	l1d_l2_rd_resp,
	mlfb_mshr_dealloc_valid,
	mlfb_mshr_dealloc_ready,
	mlfb_mshr_dealloc_idx,
	mlfb_mshr_head_rd_idx,
	mlfb_mshr_head_rd_mshr_entry,
	mlfb_mshr_head_rd_mshr_entry_no_resp,
	mlfb_lru_peek_valid,
	mlfb_lru_peek_set_idx,
	mlfb_lru_peek_dat,
	mlfb_lst_peek_set_idx,
	mlfb_lst_peek_dat,
	mlfb_lst_peek_avail_way_idx,
	mlfb_lst_check_valid,
	mlfb_lst_check_set_idx,
	mlfb_lst_check_way_idx,
	mlfb_lst_check_ready,
	mlfb_cache_evict_req_valid,
	mlfb_cache_evict_req_ready,
	mlfb_cache_evict_req,
	mlfb_cache_refill_req_valid,
	mlfb_cache_refill_req_ready,
	mlfb_cache_refill_req,
	s1_valid,
	s1_paddr,
	s2_valid,
	s2_paddr,
	snoop_stall_refill_i
);
	parameter ENTRY_NUM = 8;
	parameter ENTRY_IDX = $clog2(ENTRY_NUM);
	parameter BANK_ID = 0;
	input wire clk;
	input wire rstn;
	input wire rob_flush_i;
	input wire l1d_l2_rd_resp_valid;
	output wire l1d_l2_rd_resp_ready;
	localparam rvh_l1d_pkg_MEM_DATA_WIDTH = 64;
	localparam rvh_l1d_pkg_MEMNOC_TID_MASTERID_SIZE = 4;
	localparam rvh_l1d_pkg_MEMNOC_TID_TID_SIZE = 4;
	input wire [77:0] l1d_l2_rd_resp;
	output wire mlfb_mshr_dealloc_valid;
	input wire mlfb_mshr_dealloc_ready;
	localparam rvh_l1d_pkg_N_MSHR = 4;
	localparam rvh_l1d_pkg_N_MSHR_W = 2;
	output wire [1:0] mlfb_mshr_dealloc_idx;
	output wire [1:0] mlfb_mshr_head_rd_idx;
	localparam [31:0] rvh_pkg_L1D_LINE_SIZE = 64;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	localparam rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH = rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	localparam [31:0] rvh_pkg_L1D_BANK_COUNT = 1;
	localparam rvh_l1d_pkg_L1D_BANK_ID_NUM = rvh_pkg_L1D_BANK_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH = 0;
	localparam [31:0] rvh_pkg_L1D_SIZE = 16384;
	localparam [31:0] rvh_pkg_L1D_WAY_COUNT = 4;
	localparam [31:0] rvh_pkg_L1D_SET_COUNT = rvh_pkg_L1D_SIZE / (rvh_pkg_L1D_LINE_SIZE * rvh_pkg_L1D_WAY_COUNT);
	localparam [31:0] rvh_pkg_L1D_BANK_SET_COUNT = rvh_pkg_L1D_SET_COUNT / rvh_pkg_L1D_BANK_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_SET_NUM = rvh_pkg_L1D_BANK_SET_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH = $clog2(rvh_l1d_pkg_L1D_BANK_SET_NUM);
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	localparam rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH = ((rvh_pkg_PADDR_WIDTH - rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) - rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH) - rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH;
	localparam rvh_l1d_pkg_L1D_BANK_WAY_NUM = rvh_pkg_L1D_WAY_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH = 2;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	localparam [31:0] rvh_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_pkg_PREG_TAG_WIDTH = rvh_pkg_INT_PREG_TAG_WIDTH;
	localparam [31:0] rvh_pkg_ROB_BLOCK_PER_ENTRY = 1;
	localparam [31:0] rvh_pkg_ROB_SIZE = 16;
	localparam [31:0] rvh_pkg_ROB_ENTRY_COUNT = rvh_pkg_ROB_SIZE / rvh_pkg_ROB_BLOCK_PER_ENTRY;
	localparam [31:0] rvh_pkg_ROB_INDEX_WIDTH = $clog2(rvh_pkg_ROB_ENTRY_COUNT);
	localparam [31:0] rvh_pkg_ROB_TAG_WIDTH = rvh_pkg_ROB_INDEX_WIDTH;
	localparam [31:0] rvh_pkg_XLEN = 64;
	input wire [(((((((((rvh_pkg_ROB_TAG_WIDTH + rvh_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_pkg_XLEN) - 1:0] mlfb_mshr_head_rd_mshr_entry;
	input wire mlfb_mshr_head_rd_mshr_entry_no_resp;
	output wire mlfb_lru_peek_valid;
	output wire [rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH - 1:0] mlfb_lru_peek_set_idx;
	input [1:0] mlfb_lru_peek_dat;
	output wire [rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH - 1:0] mlfb_lst_peek_set_idx;
	input wire [7:0] mlfb_lst_peek_dat;
	input [1:0] mlfb_lst_peek_avail_way_idx;
	output wire mlfb_lst_check_valid;
	output wire [rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH - 1:0] mlfb_lst_check_set_idx;
	output wire [1:0] mlfb_lst_check_way_idx;
	input mlfb_lst_check_ready;
	output wire mlfb_cache_evict_req_valid;
	input wire mlfb_cache_evict_req_ready;
	output wire [(rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + rvh_l1d_pkg_L1D_BANK_WAY_NUM) - 1:0] mlfb_cache_evict_req;
	output wire mlfb_cache_refill_req_valid;
	input wire mlfb_cache_refill_req_ready;
	output wire [(((((((((rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_NUM) + 4) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_pkg_ROB_TAG_WIDTH) + rvh_pkg_PREG_TAG_WIDTH) + 16) + rvh_pkg_XLEN) - 1:0] mlfb_cache_refill_req;
	input wire s1_valid;
	input wire [55:0] s1_paddr;
	input wire s2_valid;
	input wire [55:0] s2_paddr;
	input wire snoop_stall_refill_i;
	localparam rvh_l1d_pkg_BURST_SIZE = 8;
	wire [2:0] line_seg_wr_cnt;
	wire [2:0] line_seg_wr_cnt_nxt;
	wire line_seg_wr_cnt_ena;
	wire [7:0] line_seg_wr_ena;
	wire [ENTRY_NUM - 1:0] mlfb_mshr_info_set;
	wire [(ENTRY_NUM * 2) - 1:0] mlfb_mshr_idx_nxt;
	wire [(ENTRY_NUM * 2) - 1:0] mlfb_mshr_idx;
	wire [ENTRY_NUM - 1:0] mlfb_err_nxt;
	wire [ENTRY_NUM - 1:0] mlfb_err;
	wire [(ENTRY_NUM * 2) - 1:0] mlfb_mesi_sta_nxt;
	wire [(ENTRY_NUM * 2) - 1:0] mlfb_mesi_sta;
	wire [7:0] fifo_head_valid;
	wire [511:0] head_seg_dat;
	wire [511:0] head_full_dat;
	wire [(ENTRY_NUM * 5) - 1:0] mlfb_fifo;
	wire [(rvh_l1d_pkg_BURST_SIZE * ENTRY_IDX) - 1:0] tail_idx;
	wire [(rvh_l1d_pkg_BURST_SIZE * ENTRY_IDX) - 1:0] head_idx;
	wire [((((((((((62 + rvh_pkg_ROB_TAG_WIDTH) + rvh_pkg_PREG_TAG_WIDTH) + 4) + rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 79) + rvh_l1d_pkg_L1D_BANK_WAY_NUM) + rvh_l1d_pkg_L1D_BANK_WAY_NUM) + 3) + rvh_pkg_XLEN) - 1:0] head_buf;
	wire head_buf_valid_set;
	wire head_buf_valid_clr;
	wire head_buf_valid_ena;
	wire head_buf_valid_nxt;
	wire head_buf_valid;
	wire head_buf_peek_done_set;
	wire head_buf_peek_done_clr;
	wire head_buf_peek_done_ena;
	wire head_buf_peek_done_nxt;
	wire head_buf_peek_done;
	wire head_buf_evict_done_set;
	wire head_buf_evict_done_clr;
	wire head_buf_evict_done_ena;
	wire head_buf_evict_done_nxt;
	wire head_buf_evict_done;
	wire head_buf_check_done_set;
	wire head_buf_check_done_clr;
	wire head_buf_check_done_ena;
	wire head_buf_check_done_nxt;
	wire head_buf_check_done;
	wire head_buf_refill_done_set;
	wire head_buf_refill_done_clr;
	wire head_buf_refill_done_ena;
	wire head_buf_refill_done_nxt;
	wire head_buf_refill_done;
	wire [511:0] mlfb_refill_dat_tmp;
	wire [511:0] mlfb_refill_dat_tmp_bit_mask;
	wire head_buf_lsu_resp_done_set;
	wire head_buf_lsu_resp_done_clr;
	wire head_buf_lsu_resp_done_ena;
	wire head_buf_lsu_resp_done_nxt;
	wire head_buf_lsu_resp_done;
	wire head_buf_stb_dat_done_set;
	wire head_buf_stb_dat_done_clr;
	wire head_buf_stb_dat_done_ena;
	wire head_buf_stb_dat_done_nxt;
	wire head_buf_stb_dat_done;
	wire [511:0] head_buf_line_dat_nxt;
	wire [1:0] head_buf_mshr_idx_nxt;
	wire head_buf_err_nxt;
	wire [1:0] head_buf_mesi_sta_nxt;
	wire [14:0] head_buf_lsu_req_type_dec_nxt;
	wire head_buf_l2_hit_nxt;
	wire [55:0] head_buf_paddr_nxt;
	wire [rvh_pkg_ROB_TAG_WIDTH - 1:0] head_buf_rob_tag_nxt;
	wire [5:0] head_buf_prd_nxt;
	wire [511:0] head_buf_st_dat_nxt;
	wire [63:0] head_buf_st_data_byte_mask_nxt;
	wire [14:0] head_buf_req_type_dec_nxt;
	wire head_buf_no_resp_nxt;
	wire [63:0] head_buf_amo_st_data_nxt;
	wire head_buf_stb_alloc_nxt;
	wire [1:0] head_buf_victim_way_idx_nxt;
	wire [1:0] head_buf_victim_way_idx;
	wire head_buf_victim_set_full_nxt;
	wire head_buf_victim_set_full;
	wire head_buf_victim_way_clean_nxt;
	wire head_buf_victim_way_clean;
	wire [1:0] head_buf_avail_way_idx_nxt;
	wire [1:0] head_buf_avail_way_idx;
	wire [3:0] lst_peek_valid_way;
	wire mlfb_cache_peek_valid;
	wire mlfb_cache_check_valid;
	wire mlfb_cache_evict_valid;
	wire mlfb_cache_evict_bypass;
	wire mlfb_cache_refill_valid;
	wire mlfb_cache_peek_req_hsk;
	wire mlfb_cache_evict_req_hsk;
	wire mlfb_cache_refill_req_hsk;
	wire mlfb_cache_lsu_resp_hsk;
	wire op_b;
	wire op_hw;
	wire op_w;
	wire op_dw;
	wire ld_u;
	wire [5:0] line_offset;
	wire mlfb_pipe_same_addr_haz;
	wire clk_mlfb;
	wire clk_mlfb_en;
	assign clk_mlfb_en = l1d_l2_rd_resp_valid | head_buf_valid_set;
	rrv64_cell_clkgate U_ICG_MLFB(
		.clk_i(clk),
		.clk_enable_i(clk_mlfb_en),
		.clk_senable_i(1'sb0),
		.clk_gated_o(clk_mlfb)
	);
	wire [49:0] head_buf_paddr_lineaddr;
	wire [rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH - 1:0] head_buf_paddr_idx;
	wire [rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH - 1:0] head_buf_paddr_tag;
	wire [5:0] head_buf_paddr_offset;
	assign head_buf_paddr_lineaddr = head_buf[rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187):(rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) - 49];
	assign head_buf_paddr_idx = head_buf[(rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) - (56 - ((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH)):(rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) - 49];
	assign head_buf_paddr_tag = head_buf[rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)-:rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH];
	assign head_buf_paddr_offset = head_buf[(rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) - 50:(rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) - 55];
	assign line_seg_wr_cnt_ena = l1d_l2_rd_resp_valid;
	assign line_seg_wr_cnt_nxt = line_seg_wr_cnt + 1'b1;
	std_dffre #(.WIDTH(3)) U_STA_REG_LINE_SEG_RECEIVED(
		.clk(clk),
		.rstn(rstn),
		.en(line_seg_wr_cnt_ena),
		.d(line_seg_wr_cnt_nxt),
		.q(line_seg_wr_cnt)
	);
	genvar ii;
	generate
		for (ii = 0; ii < rvh_l1d_pkg_BURST_SIZE; ii = ii + 1) begin : GEN_MLFB_DATA_SEG
			assign line_seg_wr_ena[ii] = l1d_l2_rd_resp_valid & (line_seg_wr_cnt == ii);
			mp_fifo_ptr_output_0F819_B1314 #(
				.payload_t_rvh_l1d_pkg_MEM_DATA_WIDTH(rvh_l1d_pkg_MEM_DATA_WIDTH),
				.ENQUEUE_WIDTH(1),
				.DEQUEUE_WIDTH(1),
				.DEPTH(ENTRY_NUM),
				.MUST_TAKEN_ALL(1)
			) U_RRV64_L1D_MLFB_DATA_SEG_FIFO(
				.enqueue_vld_i(line_seg_wr_ena[ii]),
				.enqueue_payload_i(l1d_l2_rd_resp[69-:64]),
				.dequeue_vld_o(fifo_head_valid[ii]),
				.dequeue_payload_o(head_seg_dat[ii * 64+:64]),
				.dequeue_rdy_i(head_buf_valid_set),
				.enq_ptr_o(tail_idx[ii * ENTRY_IDX+:ENTRY_IDX]),
				.deq_ptr_o(head_idx[ii * ENTRY_IDX+:ENTRY_IDX]),
				.flush_i(1'b0),
				.clk(clk_mlfb),
				.rst(~rstn)
			);
			assign head_full_dat[rvh_l1d_pkg_MEM_DATA_WIDTH * ii+:rvh_l1d_pkg_MEM_DATA_WIDTH] = head_seg_dat[ii * 64+:64];
		end
	endgenerate
	genvar jj;
	generate
		for (jj = 0; jj < ENTRY_NUM; jj = jj + 1) begin : GEN_MLFB_ENTRY
			assign mlfb_mshr_info_set[jj] = line_seg_wr_ena[0] & (jj == tail_idx[0+:ENTRY_IDX]);
			assign mlfb_mshr_idx_nxt[jj * 2+:2] = l1d_l2_rd_resp[73-:rvh_l1d_pkg_MEMNOC_TID_TID_SIZE];
			assign mlfb_err_nxt[jj] = l1d_l2_rd_resp[5];
			assign mlfb_mesi_sta_nxt[jj * 2+:2] = l1d_l2_rd_resp[4-:2];
			std_dffe #(.WIDTH(rvh_l1d_pkg_N_MSHR_W)) U_DAT_REG_MSHR_IDX(
				.clk(clk),
				.en(mlfb_mshr_info_set[jj]),
				.d(mlfb_mshr_idx_nxt[jj * 2+:2]),
				.q(mlfb_mshr_idx[jj * 2+:2])
			);
			std_dffe #(.WIDTH(1)) U_DAT_REG_ERR(
				.clk(clk),
				.en(mlfb_mshr_info_set[jj]),
				.d(mlfb_err_nxt[jj]),
				.q(mlfb_err[jj])
			);
			std_dffe #(.WIDTH(2)) U_DAT_REG_MESI_STA(
				.clk(clk),
				.en(mlfb_mshr_info_set[jj]),
				.d(mlfb_mesi_sta_nxt[jj * 2+:2]),
				.q(mlfb_mesi_sta[jj * 2+:2])
			);
			assign mlfb_fifo[(jj * 5) + 4-:2] = mlfb_mshr_idx[jj * 2+:2];
			assign mlfb_fifo[(jj * 5) + 2] = mlfb_err[jj];
			assign mlfb_fifo[(jj * 5) + 1-:2] = mlfb_mesi_sta[jj * 2+:2];
		end
	endgenerate
	assign head_buf_valid_set = (&fifo_head_valid & (~head_buf_valid | head_buf_valid_clr)) & ~rob_flush_i;
	assign head_buf_valid_clr = (head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] & head_buf[1178]) & mlfb_mshr_dealloc_ready;
	assign head_buf_valid_ena = head_buf_valid_set | head_buf_valid_clr;
	assign head_buf_valid_nxt = (head_buf_valid_set ? 1'b1 : ~head_buf_valid_clr);
	std_dffre #(.WIDTH(1)) U_STA_REG_HEAD_BUF_VALID(
		.clk(clk),
		.rstn(rstn),
		.en(head_buf_valid_ena),
		.d(head_buf_valid_nxt),
		.q(head_buf_valid)
	);
	assign head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] = head_buf_valid;
	assign head_buf_line_dat_nxt = head_full_dat;
	assign head_buf_mshr_idx_nxt = mlfb_fifo[(head_idx[0+:ENTRY_IDX] * 5) + 4-:2];
	assign head_buf_err_nxt = mlfb_fifo[(head_idx[0+:ENTRY_IDX] * 5) + 2];
	assign head_buf_mesi_sta_nxt = mlfb_fifo[(head_idx[0+:ENTRY_IDX] * 5) + 1-:2];
	assign head_buf_paddr_nxt = {mlfb_mshr_head_rd_mshr_entry[rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)-:((rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)) >= (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665) ? ((rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)) - (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665)) + 1 : ((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665) - (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664))) + 1)], mlfb_mshr_head_rd_mshr_entry[rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664-:((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664) >= 665 ? rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH : 666 - (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664))], mlfb_mshr_head_rd_mshr_entry[664-:6]};
	assign head_buf_rob_tag_nxt = mlfb_mshr_head_rd_mshr_entry[rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664))))-:((rvh_pkg_ROB_TAG_WIDTH + (9 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)))) >= (9 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665))) ? ((rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664))))) - (rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665))))) + 1 : ((rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665)))) - (rvh_pkg_ROB_TAG_WIDTH + (rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)))))) + 1)];
	assign head_buf_prd_nxt = mlfb_mshr_head_rd_mshr_entry[rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)))-:((9 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664))) >= (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665))) ? ((rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664)))) - (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665)))) + 1 : ((3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 665))) - (rvh_pkg_PREG_TAG_WIDTH + (3 + (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 664))))) + 1)];
	assign head_buf_st_dat_nxt = mlfb_mshr_head_rd_mshr_entry[656-:512];
	assign head_buf_st_data_byte_mask_nxt = mlfb_mshr_head_rd_mshr_entry[144-:64];
	assign head_buf_req_type_dec_nxt = mlfb_mshr_head_rd_mshr_entry[80-:15];
	assign head_buf_no_resp_nxt = mlfb_mshr_head_rd_mshr_entry_no_resp | rob_flush_i;
	assign head_buf_amo_st_data_nxt = mlfb_mshr_head_rd_mshr_entry[63-:rvh_pkg_XLEN];
	generate
		for (ii = 0; ii < 64; ii = ii + 1) begin : genblk3
			assign mlfb_refill_dat_tmp_bit_mask[ii * 8+:8] = {8 {head_buf[90 + ii]}};
		end
	endgenerate
	assign mlfb_refill_dat_tmp = (head_buf[87] ? (head_buf[1177-:512] & ~mlfb_refill_dat_tmp_bit_mask) | (head_buf[665-:512] & mlfb_refill_dat_tmp_bit_mask) : head_buf[1177-:512]);
	std_dffe #(.WIDTH(rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE)) U_DAT_REG_HEAD_BUF_LINE_DAT(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_line_dat_nxt),
		.q(head_buf[1177-:512])
	);
	std_dffe #(.WIDTH(rvh_l1d_pkg_N_MSHR_W)) U_DAT_REG_HEAD_BUF_MSHR_IDX(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_mshr_idx_nxt),
		.q(head_buf[rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)))-:((61 + (rvh_pkg_ROB_TAG_WIDTH + 1187)) >= (59 + (rvh_pkg_ROB_TAG_WIDTH + 1188)) ? ((rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)))) - (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188)))) + 1 : ((3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188))) - (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))) + 1)])
	);
	std_dffe #(.WIDTH(1)) U_DAT_REG_HEAD_BUF_LINE_ERR(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_err_nxt),
		.q(head_buf[3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))])
	);
	std_dffe #(.WIDTH(2)) U_DAT_REG_MESI_STA(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_mesi_sta_nxt),
		.q(head_buf[2 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))-:((58 + (rvh_pkg_ROB_TAG_WIDTH + 1187)) >= (32'd56 + (rvh_pkg_ROB_TAG_WIDTH + 1188)) ? ((2 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))) - (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188))) + 1 : ((rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188)) - (2 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)))) + 1)])
	);
	std_dffe #(.WIDTH(rvh_pkg_PADDR_WIDTH)) U_DAT_REG_HEAD_BUF_PADDR(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_paddr_nxt),
		.q(head_buf[rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)-:((rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) >= (rvh_pkg_ROB_TAG_WIDTH + 1188) ? ((rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)) - (rvh_pkg_ROB_TAG_WIDTH + 1188)) + 1 : ((rvh_pkg_ROB_TAG_WIDTH + 1188) - (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))) + 1)])
	);
	std_dffe #(.WIDTH(rvh_pkg_ROB_TAG_WIDTH)) U_DAT_REG_HEAD_BUF_ROB_TAG(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_rob_tag_nxt),
		.q(head_buf[rvh_pkg_ROB_TAG_WIDTH + 1187-:((rvh_pkg_ROB_TAG_WIDTH + 1187) >= 1188 ? rvh_pkg_ROB_TAG_WIDTH : 1189 - (rvh_pkg_ROB_TAG_WIDTH + 1187))])
	);
	std_dffe #(.WIDTH(rvh_pkg_PREG_TAG_WIDTH)) U_DAT_REG_HEAD_BUF_PRD(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_prd_nxt),
		.q(head_buf[1187-:6])
	);
	std_dffe #(.WIDTH(rvh_l1d_pkg_L1D_STB_DATA_WIDTH)) U_DAT_REG_HEAD_BUF_ST_DATA(
		.clk(clk),
		.en(head_buf_valid_set & head_buf_req_type_dec_nxt[12]),
		.d(head_buf_st_dat_nxt),
		.q(head_buf[665-:512])
	);
	std_dffe #(.WIDTH(64)) U_DAT_REG_HEAD_BUF_ST_DATA_BYTE_MASK(
		.clk(clk),
		.en(head_buf_valid_set & head_buf_req_type_dec_nxt[12]),
		.d(head_buf_st_data_byte_mask_nxt),
		.q(head_buf[153-:64])
	);
	std_dffe #(.WIDTH(15)) U_DAT_REG_HEAD_BUF_REQ_TYPE(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_req_type_dec_nxt),
		.q(head_buf[89-:15])
	);
	std_dffe #(.WIDTH(1)) U_DAT_REG_HEAD_BUF_NO_RESP(
		.clk(clk),
		.en(head_buf_valid_set | rob_flush_i),
		.d(head_buf_no_resp_nxt),
		.q(head_buf[64])
	);
	std_dffe #(.WIDTH(1)) U_DAT_REG_HEAD_BUF_AMO_ST_DATA(
		.clk(clk),
		.en(head_buf_valid_set),
		.d(head_buf_amo_st_data_nxt),
		.q(head_buf[63-:rvh_pkg_XLEN])
	);
	assign mlfb_pipe_same_addr_haz = (s1_valid & (s1_paddr[55:rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH] == head_buf_paddr_lineaddr)) | (s2_valid & (s2_paddr[55:rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH] == head_buf_paddr_lineaddr));
	assign head_buf_peek_done_set = mlfb_cache_peek_valid;
	assign head_buf_peek_done_clr = head_buf_valid_clr;
	assign head_buf_peek_done_ena = head_buf_peek_done_set | head_buf_peek_done_clr;
	assign head_buf_peek_done_nxt = head_buf_peek_done_set & ~head_buf_peek_done_clr;
	std_dffre #(.WIDTH(1)) U_STA_REG_PEEK_DONE(
		.clk(clk),
		.rstn(rstn),
		.en(head_buf_peek_done_ena),
		.d(head_buf_peek_done_nxt),
		.q(head_buf_peek_done)
	);
	assign head_buf[1181] = head_buf_peek_done;
	genvar kk;
	generate
		for (kk = 0; kk < rvh_l1d_pkg_L1D_BANK_WAY_NUM; kk = kk + 1) begin : GEN_MLFB_LST_PEEK_STA
			assign lst_peek_valid_way[kk] = mlfb_lst_peek_dat[0 + (kk * 2)+:2] != 2'd0;
		end
	endgenerate
	assign head_buf_avail_way_idx_nxt = mlfb_lst_peek_avail_way_idx;
	assign head_buf_victim_way_idx_nxt = mlfb_lru_peek_dat;
	assign head_buf_victim_set_full_nxt = &lst_peek_valid_way;
	assign head_buf_victim_way_clean_nxt = mlfb_lst_peek_dat[0 + (mlfb_lru_peek_dat * 2)+:2] != 2'd3;
	std_dffe #(.WIDTH(rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH)) U_STA_REG_PEEK_AVAIL(
		.clk(clk),
		.en(head_buf_peek_done_set),
		.d(head_buf_avail_way_idx_nxt),
		.q(head_buf_avail_way_idx)
	);
	std_dffe #(.WIDTH(rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH)) U_STA_REG_PEEK_VICTIM(
		.clk(clk),
		.en(head_buf_peek_done_set),
		.d(head_buf_victim_way_idx_nxt),
		.q(head_buf_victim_way_idx)
	);
	std_dffe #(.WIDTH(1)) U_STA_REG_PEEK_SET_FULL(
		.clk(clk),
		.en(head_buf_peek_done_set),
		.d(head_buf_victim_set_full_nxt),
		.q(head_buf_victim_set_full)
	);
	std_dffe #(.WIDTH(1)) U_STA_REG_PEEK_WAY_CLEAN(
		.clk(clk),
		.en(head_buf_peek_done_set),
		.d(head_buf_victim_way_clean_nxt),
		.q(head_buf_victim_way_clean)
	);
	assign head_buf[66] = head_buf_victim_set_full;
	assign head_buf[70-:4] = head_buf_victim_way_idx;
	assign head_buf[74-:4] = head_buf_avail_way_idx;
	assign head_buf[65] = head_buf_victim_way_clean;
	assign head_buf_check_done_set = mlfb_cache_check_valid & |mlfb_lst_check_ready;
	assign head_buf_check_done_clr = head_buf_valid_clr;
	assign head_buf_check_done_ena = head_buf_check_done_set | head_buf_check_done_clr;
	assign head_buf_check_done_nxt = head_buf_check_done_set & ~head_buf_check_done_clr;
	std_dffre #(.WIDTH(1)) U_STA_REG_CHECK_DONE(
		.clk(clk),
		.rstn(rstn),
		.en(head_buf_check_done_ena),
		.d(head_buf_check_done_nxt),
		.q(head_buf_check_done)
	);
	assign head_buf[1180] = head_buf_check_done;
	assign head_buf_evict_done_set = mlfb_cache_evict_req_hsk | mlfb_cache_evict_bypass;
	assign head_buf_evict_done_clr = head_buf_valid_clr;
	assign head_buf_evict_done_ena = head_buf_evict_done_set | head_buf_evict_done_clr;
	assign head_buf_evict_done_nxt = head_buf_evict_done_set & ~head_buf_evict_done_clr;
	std_dffre #(.WIDTH(1)) U_STA_REG_EVICT_DONE(
		.clk(clk),
		.rstn(rstn),
		.en(head_buf_evict_done_ena),
		.d(head_buf_evict_done_nxt),
		.q(head_buf_evict_done)
	);
	assign head_buf[1179] = head_buf_evict_done;
	assign head_buf_refill_done_set = mlfb_cache_refill_req_hsk;
	assign head_buf_refill_done_clr = head_buf_valid_clr;
	assign head_buf_refill_done_ena = head_buf_refill_done_set | head_buf_refill_done_clr;
	assign head_buf_refill_done_nxt = head_buf_refill_done_set & ~head_buf_refill_done_clr;
	std_dffre #(.WIDTH(1)) U_STA_REG_REFILL_DONE(
		.clk(clk),
		.rstn(rstn),
		.en(head_buf_refill_done_ena),
		.d(head_buf_refill_done_nxt),
		.q(head_buf_refill_done)
	);
	assign head_buf[1178] = head_buf_refill_done;
	assign mlfb_mshr_dealloc_valid = head_buf_valid_clr;
	assign mlfb_mshr_dealloc_idx = head_buf[rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)))-:((61 + (rvh_pkg_ROB_TAG_WIDTH + 1187)) >= (59 + (rvh_pkg_ROB_TAG_WIDTH + 1188)) ? ((rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)))) - (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188)))) + 1 : ((3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188))) - (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))) + 1)];
	assign mlfb_mshr_head_rd_idx = mlfb_fifo[(head_idx[0+:ENTRY_IDX] * 5) + 4-:2];
	assign mlfb_cache_peek_valid = (head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] & ~snoop_stall_refill_i) & ~head_buf[1181];
	assign mlfb_cache_check_valid = ((head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] & ~snoop_stall_refill_i) & head_buf[1181]) & ~head_buf[1180];
	assign mlfb_cache_evict_valid = ((((head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] & ~snoop_stall_refill_i) & head_buf[1180]) & ~head_buf[1179]) & head_buf[66]) & ~head_buf[65];
	assign mlfb_cache_evict_bypass = (((head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] & ~snoop_stall_refill_i) & head_buf[1180]) & ~head_buf[1179]) & (~head_buf[66] | head_buf[65]);
	assign mlfb_cache_refill_valid = (((head_buf[1 + (rvh_l1d_pkg_N_MSHR_W + (3 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))))] & ~snoop_stall_refill_i) & head_buf[1179]) & ~head_buf[1178]) & ~mlfb_pipe_same_addr_haz;
	assign mlfb_lru_peek_set_idx = head_buf_paddr_idx;
	assign mlfb_lst_peek_set_idx = head_buf_paddr_idx;
	assign mlfb_lst_check_set_idx = head_buf_paddr_idx;
	assign mlfb_lst_check_way_idx = (head_buf[66] ? head_buf[70-:4] : head_buf[74-:4]);
	assign mlfb_cache_evict_req_hsk = mlfb_cache_evict_req_valid & mlfb_cache_evict_req_ready;
	assign mlfb_cache_evict_req[rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 3-:((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 3) >= 4 ? rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH : 5 - (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + 3))] = head_buf_paddr_idx;
	assign mlfb_cache_evict_req[3-:rvh_l1d_pkg_L1D_BANK_WAY_NUM] = head_buf[70-:4];
	assign mlfb_cache_refill_req_hsk = mlfb_cache_refill_req_valid & mlfb_cache_refill_req_ready;
	assign mlfb_cache_refill_req[rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))))-:((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (14 + (rvh_pkg_ROB_TAG_WIDTH + 85))) >= (14 + (rvh_pkg_ROB_TAG_WIDTH + 86)) ? ((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))))) - (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86))))) + 1 : ((rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86)))) - (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))))) + 1)] = head_buf_paddr_idx;
	assign mlfb_cache_refill_req[rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))-:((14 + (rvh_pkg_ROB_TAG_WIDTH + 85)) >= (10 + (rvh_pkg_ROB_TAG_WIDTH + 86)) ? ((rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))) - (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86)))) + 1 : ((4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86))) - (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))))) + 1)] = (head_buf[66] ? head_buf[70-:4] : head_buf[74-:4]);
	assign mlfb_cache_refill_req[rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))))))-:((rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (512 + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (14 + (rvh_pkg_ROB_TAG_WIDTH + 85))))) >= (512 + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (14 + (rvh_pkg_ROB_TAG_WIDTH + 86)))) ? ((rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))))))) - (rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86))))))) + 1 : ((rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86)))))) - (rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH + (rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))))))) + 1)] = head_buf_paddr_tag;
	assign mlfb_cache_refill_req[rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))))-:((512 + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (14 + (rvh_pkg_ROB_TAG_WIDTH + 85)))) >= (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (14 + (rvh_pkg_ROB_TAG_WIDTH + 86))) ? ((rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))))) - (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86)))))) + 1 : ((rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86))))) - (rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE + (rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH + (rvh_l1d_pkg_L1D_BANK_WAY_NUM + (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))))))) + 1)] = mlfb_refill_dat_tmp;
	assign mlfb_cache_refill_req[4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))-:((10 + (rvh_pkg_ROB_TAG_WIDTH + 85)) >= (8 + (rvh_pkg_ROB_TAG_WIDTH + 86)) ? ((4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))) - (2 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86)))) + 1 : ((2 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 86))) - (4 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)))) + 1)] = (head_buf[87] ? 2'd3 : head_buf[2 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))-:((58 + (rvh_pkg_ROB_TAG_WIDTH + 1187)) >= (32'd56 + (rvh_pkg_ROB_TAG_WIDTH + 1188)) ? ((2 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187))) - (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188))) + 1 : ((rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1188)) - (2 + (rvh_pkg_PADDR_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 1187)))) + 1)]);
	assign mlfb_cache_refill_req[2 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))] = head_buf[81];
	assign mlfb_cache_refill_req[1 + (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))] = head_buf[89];
	assign mlfb_cache_refill_req[rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)-:((rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)) >= (rvh_pkg_ROB_TAG_WIDTH + 86) ? ((rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85)) - (rvh_pkg_ROB_TAG_WIDTH + 86)) + 1 : ((rvh_pkg_ROB_TAG_WIDTH + 86) - (rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH + (rvh_pkg_ROB_TAG_WIDTH + 85))) + 1)] = head_buf_paddr_offset;
	assign mlfb_cache_refill_req[rvh_pkg_ROB_TAG_WIDTH + 85-:((rvh_pkg_ROB_TAG_WIDTH + 85) >= 86 ? rvh_pkg_ROB_TAG_WIDTH : 87 - (rvh_pkg_ROB_TAG_WIDTH + 85))] = head_buf[rvh_pkg_ROB_TAG_WIDTH + 1187-:((rvh_pkg_ROB_TAG_WIDTH + 1187) >= 1188 ? rvh_pkg_ROB_TAG_WIDTH : 1189 - (rvh_pkg_ROB_TAG_WIDTH + 1187))];
	assign mlfb_cache_refill_req[85-:6] = head_buf[1187-:6];
	assign mlfb_cache_refill_req[79-:15] = head_buf[89-:15];
	assign mlfb_cache_refill_req[64] = head_buf[64];
	assign mlfb_cache_refill_req[63-:rvh_pkg_XLEN] = head_buf[63-:rvh_pkg_XLEN];
	assign mlfb_lru_peek_valid = mlfb_cache_peek_valid;
	assign mlfb_lst_check_valid = mlfb_cache_check_valid;
	assign mlfb_cache_evict_req_valid = mlfb_cache_evict_valid;
	assign mlfb_cache_refill_req_valid = mlfb_cache_refill_valid;
	assign l1d_l2_rd_resp_ready = 1'b1;
endmodule
