module rvh_l1d_bank (
	ls_pipe_l1d_ld_req_vld_i,
	ls_pipe_l1d_ld_req_rob_tag_i,
	ls_pipe_l1d_ld_req_prd_i,
	ls_pipe_l1d_ld_req_opcode_i,
	ls_pipe_l1d_ld_req_idx_i,
	ls_pipe_l1d_ld_req_offset_i,
	ls_pipe_l1d_ld_req_vtag_i,
	stb_l1d_ld_rdy_i,
	ls_pipe_l1d_ld_req_rdy_o,
	ls_pipe_l1d_ld_kill_i,
	ls_pipe_l1d_ld_rar_fail_i,
	ls_pipe_l1d_st_req_vld_i,
	ls_pipe_l1d_st_req_io_region_i,
	ls_pipe_l1d_st_req_rob_tag_i,
	ls_pipe_l1d_st_req_prd_i,
	ls_pipe_l1d_st_req_opcode_i,
	ls_pipe_l1d_st_req_paddr_i,
	ls_pipe_l1d_st_req_data_i,
	ls_pipe_l1d_st_req_data_byte_mask_i,
	ls_pipe_l1d_st_req_sc_rt_check_succ_i,
	ls_pipe_l1d_st_req_sc_amo_offset_i,
	ls_pipe_l1d_st_req_rdy_o,
	ls_pipe_l1d_ld_raw_fail_i,
	dtlb_l1d_resp_vld_i,
	dtlb_l1d_resp_excp_vld_i,
	dtlb_l1d_resp_hit_i,
	dtlb_l1d_resp_ppn_i,
	dtlb_l1d_resp_rdy_o,
	stb_l1d_bank_ld_bypass_valid_i,
	stb_l1d_bank_ld_bypass_data_i,
	lsu_l1d_s2_kill_valid_i,
	l1d_ls_pipe_replay_vld_o,
	l1d_ls_pipe_mshr_full_o,
	l1d_rob_wb_vld_o,
	l1d_rob_wb_rob_tag_o,
	l1d_int_prf_wb_vld_o,
	l1d_int_prf_wb_tag_o,
	l1d_int_prf_wb_data_o,
	l1d_int_prf_wb_vld_from_mlfb_o,
	l1d_int_prf_wb_rdy_from_mlfb_i,
	ptw_walk_req_vld_i,
	ptw_walk_req_id_i,
	ptw_walk_req_addr_i,
	stb_l1d_ptw_walk_req_rdy_i,
	ptw_walk_req_rdy_o,
	ptw_walk_resp_vld_o,
	ptw_walk_resp_id_o,
	ptw_walk_resp_pte_o,
	ptw_walk_resp_rdy_i,
	snp_l1d_bank_snp_s0_req_vld_i,
	snp_l1d_bank_snp_s0_req_hsk_i,
	snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i,
	snp_l1d_bank_snp_s0_req_rdy_o,
	snp_l1d_bank_snp_s1_req_vld_i,
	snp_l1d_bank_snp_s1_req_hsk_i,
	snp_l1d_bank_snp_s1_req_rdy_o,
	snp_l1d_bank_snp_s2_req_vld_i,
	snp_l1d_bank_snp_s2_req_hsk_i,
	snp_l1d_bank_snp_s2_req_new_line_state_i,
	snp_l1d_bank_snp_s2_req_way_id_i,
	snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i,
	snp_l1d_bank_snp_s2_req_rdy_o,
	snp_l1d_bank_snp_s3_req_vld_i,
	snp_l1d_bank_snp_s3_tag_compare_match_id_i,
	l2_req_if_arvalid,
	l2_req_if_arready,
	l2_req_if_ar,
	l2_req_if_awvalid,
	l2_req_if_awready,
	l2_req_if_aw,
	l2_req_if_wvalid,
	l2_req_if_wready,
	l2_req_if_w,
	l2_resp_if_bvalid,
	l2_resp_if_bready,
	l2_resp_if_b,
	l2_resp_if_rvalid,
	l2_resp_if_rready,
	l2_resp_if_r,
	l1d_lsu_invld_vld_o,
	l1d_lsu_invld_tag_o,
	rob_flush_i,
	fencei_flush_vld_i,
	fencei_flush_grant_o,
	clk,
	rst
);
	parameter BANK_ID = 0;
	input wire ls_pipe_l1d_ld_req_vld_i;
	localparam [31:0] rvh_l1d_pkg_ROB_INDEX_WIDTH = 4;
	localparam [31:0] rvh_l1d_pkg_ROB_TAG_WIDTH = rvh_l1d_pkg_ROB_INDEX_WIDTH;
	input wire [3:0] ls_pipe_l1d_ld_req_rob_tag_i;
	localparam [31:0] rvh_l1d_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_l1d_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_l1d_pkg_PREG_TAG_WIDTH = rvh_l1d_pkg_INT_PREG_TAG_WIDTH;
	input wire [5:0] ls_pipe_l1d_ld_req_prd_i;
	localparam [31:0] rvh_l1d_pkg_LDU_OP_WIDTH = 3;
	input wire [2:0] ls_pipe_l1d_ld_req_opcode_i;
	localparam rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH = 1;
	input wire [0:0] ls_pipe_l1d_ld_req_idx_i;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	localparam rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH = rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	input wire [5:0] ls_pipe_l1d_ld_req_offset_i;
	localparam rvh_l1d_pkg_L1D_INDEX_WIDTH = 1;
	localparam rvh_l1d_pkg_L1D_TAG_WIDTH = 49;
	localparam rvh_l1d_pkg_L1D_BANK_TAG_WIDTH = rvh_l1d_pkg_L1D_TAG_WIDTH;
	input wire [48:0] ls_pipe_l1d_ld_req_vtag_i;
	input wire stb_l1d_ld_rdy_i;
	output wire ls_pipe_l1d_ld_req_rdy_o;
	input wire ls_pipe_l1d_ld_kill_i;
	input wire ls_pipe_l1d_ld_rar_fail_i;
	input wire ls_pipe_l1d_st_req_vld_i;
	input wire ls_pipe_l1d_st_req_io_region_i;
	input wire [3:0] ls_pipe_l1d_st_req_rob_tag_i;
	input wire [5:0] ls_pipe_l1d_st_req_prd_i;
	localparam [31:0] rvh_l1d_pkg_STU_OP_WIDTH = 5;
	input wire [4:0] ls_pipe_l1d_st_req_opcode_i;
	localparam [31:0] rvh_l1d_pkg_PADDR_WIDTH = 56;
	input wire [55:0] ls_pipe_l1d_st_req_paddr_i;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	input wire [511:0] ls_pipe_l1d_st_req_data_i;
	input wire [63:0] ls_pipe_l1d_st_req_data_byte_mask_i;
	input wire ls_pipe_l1d_st_req_sc_rt_check_succ_i;
	input wire [5:0] ls_pipe_l1d_st_req_sc_amo_offset_i;
	output wire ls_pipe_l1d_st_req_rdy_o;
	input wire ls_pipe_l1d_ld_raw_fail_i;
	input wire dtlb_l1d_resp_vld_i;
	input wire dtlb_l1d_resp_excp_vld_i;
	input wire dtlb_l1d_resp_hit_i;
	localparam rvh_l1d_pkg_PPN_WIDTH = 48;
	input wire [47:0] dtlb_l1d_resp_ppn_i;
	output wire dtlb_l1d_resp_rdy_o;
	input wire stb_l1d_bank_ld_bypass_valid_i;
	localparam [31:0] rvh_l1d_pkg_XLEN = 64;
	input wire [63:0] stb_l1d_bank_ld_bypass_data_i;
	input wire lsu_l1d_s2_kill_valid_i;
	output wire l1d_ls_pipe_replay_vld_o;
	output wire l1d_ls_pipe_mshr_full_o;
	output wire l1d_rob_wb_vld_o;
	output wire [3:0] l1d_rob_wb_rob_tag_o;
	output wire l1d_int_prf_wb_vld_o;
	output wire [5:0] l1d_int_prf_wb_tag_o;
	output wire [63:0] l1d_int_prf_wb_data_o;
	output wire l1d_int_prf_wb_vld_from_mlfb_o;
	input wire l1d_int_prf_wb_rdy_from_mlfb_i;
	input wire ptw_walk_req_vld_i;
	localparam [31:0] rvh_l1d_pkg_PTW_ID_WIDTH = 1;
	input wire [0:0] ptw_walk_req_id_i;
	input wire [55:0] ptw_walk_req_addr_i;
	input wire stb_l1d_ptw_walk_req_rdy_i;
	output wire ptw_walk_req_rdy_o;
	output wire ptw_walk_resp_vld_o;
	output wire [0:0] ptw_walk_resp_id_o;
	localparam rvh_l1d_pkg_PTE_WIDTH = 64;
	output wire [63:0] ptw_walk_resp_pte_o;
	input wire ptw_walk_resp_rdy_i;
	input wire snp_l1d_bank_snp_s0_req_vld_i;
	input wire snp_l1d_bank_snp_s0_req_hsk_i;
	input wire snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i;
	output wire snp_l1d_bank_snp_s0_req_rdy_o;
	input wire snp_l1d_bank_snp_s1_req_vld_i;
	input wire snp_l1d_bank_snp_s1_req_hsk_i;
	output wire snp_l1d_bank_snp_s1_req_rdy_o;
	input wire snp_l1d_bank_snp_s2_req_vld_i;
	input wire snp_l1d_bank_snp_s2_req_hsk_i;
	input wire [1:0] snp_l1d_bank_snp_s2_req_new_line_state_i;
	localparam rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH = 2;
	input wire [1:0] snp_l1d_bank_snp_s2_req_way_id_i;
	input wire snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i;
	output wire snp_l1d_bank_snp_s2_req_rdy_o;
	input wire snp_l1d_bank_snp_s3_req_vld_i;
	input wire [1:0] snp_l1d_bank_snp_s3_tag_compare_match_id_i;
	output wire l2_req_if_arvalid;
	input wire l2_req_if_arready;
	localparam rvh_l1d_pkg_MEMNOC_TID_MASTERID_SIZE = 4;
	localparam rvh_l1d_pkg_MEMNOC_TID_TID_SIZE = 4;
	output wire [76:0] l2_req_if_ar;
	output wire l2_req_if_awvalid;
	input wire l2_req_if_awready;
	output wire [76:0] l2_req_if_aw;
	output wire l2_req_if_wvalid;
	input wire l2_req_if_wready;
	localparam rvh_l1d_pkg_MEM_DATA_WIDTH = 64;
	output wire [72:0] l2_req_if_w;
	input wire l2_resp_if_bvalid;
	output wire l2_resp_if_bready;
	input wire [9:0] l2_resp_if_b;
	input wire l2_resp_if_rvalid;
	output wire l2_resp_if_rready;
	input wire [77:0] l2_resp_if_r;
	output wire l1d_lsu_invld_vld_o;
	output wire [55:0] l1d_lsu_invld_tag_o;
	input wire rob_flush_i;
	input wire fencei_flush_vld_i;
	output wire fencei_flush_grant_o;
	input wire clk;
	input wire rst;
	localparam rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH = 0;
	localparam rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH = 49;
	localparam rvh_l1d_pkg_L1D_BANK_WAY_NUM = 4;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	wire [1456:0] cur;
	wire [1456:0] nxt;
	wire s1_valid;
	wire s2_valid;
	wire s1_nxt_ena;
	wire s2_nxt_ena;
	wire s1_valid_nxt;
	wire s2_valid_nxt;
	wire s1_stall;
	wire s2_stall;
	wire [14:0] req_type_dec;
	wire cache_rd_valid_tram;
	wire cache_wr_valid_tram;
	wire [3:0] cache_rd_tram_way_en;
	wire [3:0] cache_wr_tram_way_en;
	wire [0:0] cache_idx_tram;
	wire [3:0] tram_cs;
	wire [3:0] tram_wen;
	wire [3:0] tram_addr;
	localparam rvh_l1d_pkg_L1D_BANK_TAG_RAM_WORD_WIDTH = rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH;
	wire [48:0] cache_wr_dat_tram;
	wire [195:0] tram_wdat;
	wire [195:0] tram_rdat;
	wire cache_rd_valid_dram;
	wire cache_wr_valid_dram;
	wire [0:0] cache_idx_dram;
	wire [5:0] cache_offset_dram;
	wire [1:0] cache_way_idx_dram;
	wire [1:0] cache_way_idx_dram_s1;
	wire [5:0] cache_offset_dram_s1;
	wire [3:0] cache_way_en_dram_raw;
	wire [3:0] cache_way_en_dram;
	wire [3:0] cache_way_en_dram_seg;
	wire [63:0] cache_way_byte_en_dram_seg;
	wire [63:0] cache_wr_dat_dram;
	wire [3:0] dram_cs;
	wire [63:0] dram_wen_biten;
	wire [15:0] dram_wen_biten_tmp;
	wire [7:0] st_dat_biten;
	wire [3:0] dram_wen;
	wire [3:0] dram_wen_way;
	wire [0:0] dram_addr;
	wire [11:0] dram_addr_ram;
	wire [11:0] dram_addr_by_way;
	wire [2:0] dram_addr_by_offset;
	wire [511:0] dram_wdat;
	wire [511:0] dram_wdat_tmp;
	wire [511:0] dram_wdat_way;
	wire [511:0] dram_rdat;
	wire [511:0] dram_rdat_all;
	wire [511:0] dram_rdat_all_way0;
	wire [511:0] dram_rdat_all_way1;
	wire [511:0] dram_rdat_all_way2;
	wire [511:0] dram_rdat_all_way3;
	wire [511:0] dram_rdat_all_way_seg_realigned;
	wire [511:0] dram_rdat_all_way_selected;
	wire [511:0] dram_rdat_all_way_seg_realigned_offset0;
	wire [511:0] dram_rdat_all_way_seg_realigned_offset1;
	wire [511:0] dram_rdat_all_way_seg_realigned_offset2;
	wire [511:0] dram_rdat_all_way_seg_realigned_offset3;
	wire [511:0] dram_wdat_ram;
	wire [0:0] ls_pipe_l1d_st_req_idx;
	wire [5:0] ls_pipe_l1d_st_req_offset;
	wire [48:0] ls_pipe_l1d_st_req_tag;
	wire plru_rd_en_mlfb_peek;
	wire [0:0] plru_rd_idx_mlfb_peek;
	wire [1:0] plru_rd_dat_mlfb_peek;
	wire [0:0] lst_rd_idx_mlfb_peek;
	wire [0:0] lst_rd_idx_peek;
	wire [1:0] lst_rd_avail_way_mlfb_peek;
	wire [7:0] lst_rd_dat_mlfb_peek;
	wire [0:0] lst_rd_idx_s0_req;
	wire [7:0] lst_rd_dat_s0_req;
	wire mlfb_evict_valid;
	wire mlfb_evict_ready;
	wire mlfb_evict_hsk;
	wire [4:0] mlfb_evict_req;
	wire refill_valid;
	wire refill_ready;
	wire refill_bank_internal_ready;
	wire refill_hsk;
	wire refill_bank_internal_hsk;
	wire [665:0] refill_req;
	wire [0:0] lst_check_set_idx;
	wire [1:0] lst_check_way_idx;
	wire lst_check_valid;
	wire lst_check_ready;
	wire mlfb_mshr_dealloc_valid;
	wire mlfb_mshr_dealloc_ready;
	localparam rvh_l1d_pkg_N_MSHR_W = 1;
	wire [0:0] mlfb_mshr_dealloc_idx;
	wire [0:0] mlfb_mshr_head_rd_idx;
	wire [(((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN) - 1:0] mlfb_mshr_head_rd_mshr_entry;
	wire mlfb_mshr_head_rd_mshr_entry_no_resp;
	wire [0:0] mlfb_mshr_head_pending_rd_idx;
	wire [(((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN) - 1:0] mlfb_mshr_head_pending_rd_mshr_entry;
	wire [48:0] tag_used_to_compare;
	wire [3:0] s1_tag_compare_result_per_way;
	wire [3:0] s1_tag_compare_hit_per_way;
	wire s1_tag_compare_hit;
	wire mshr_we;
	localparam rvh_l1d_pkg_N_MSHR = 2;
	wire [(2 * (((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN)) - 1:0] mshr_bank;
	wire [1:0] mshr_bank_valid;
	wire [1:0] mshr_bank_no_resp;
	wire [1:0] mshr_bank_sent;
	wire [(((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN) - 1:0] new_mshr;
	wire new_mshr_valid;
	wire [0:0] new_mshr_id;
	wire has_free_mshr;
	wire [rvh_l1d_pkg_N_MSHR_W:0] free_mshr_num;
	wire l1d_ewrq_new_ewrq_valid;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_ADDR_SIZE = 50;
	wire [49:0] l1d_ewrq_new_ewrq_addr;
	wire [511:0] l1d_ewrq_new_ewrq_dat;
	wire l1d_ewrq_new_ewrq_ready;
	localparam rvh_l1d_pkg_N_EWRQ = rvh_l1d_pkg_N_MSHR;
	wire [99:0] ewrq_addr;
	wire [1:0] ewrq_vld;
	wire lst_mesi_wr_en_s0_req_vld;
	wire [0:0] lst_mesi_wr_set_idx_s0_req;
	wire [1:0] lst_mesi_wr_way_idx_s0_req;
	wire [1:0] lst_mesi_wr_dat_s0_req;
	reg [1:0] s2_tag_compare_hit_way_idx;
	wire l1d_lsu_resp_valid;
	wire l1d_lsu_resp_is_refill;
	wire [511:0] l1d_lsu_resp_dat;
	wire [14:0] l1d_lsu_ld_req_type_dec;
	wire [5:0] l1d_lsu_resp_offset;
	wire [3:0] l1d_lsu_resp_rob_tag;
	wire [5:0] l1d_lsu_resp_prd;
	wire ls_pipe_l1d_ld_req_hsk;
	wire ls_pipe_l1d_st_req_hsk;
	wire ls_pipe_l1d_lr_req_hsk;
	wire ls_pipe_l1d_sc_req_hsk;
	wire ls_pipe_l1d_amo_req_hsk;
	wire ptw_l1d_walk_req_hsk;
	wire dtlb_l1d_resp_hsk;
	wire s1_st_req_tag_hit;
	wire s2_st_req_tag_hit;
	wire s2_amo_req_tag_hit;
	wire s1_ld_req_tag_hit;
	wire s1_ptw_req_tag_hit;
	wire s1_lr_req_tag_hit;
	wire s1_sc_req_tag_hit;
	wire s1_amo_req_tag_hit;
	wire s1_st_req_tag_miss;
	wire s2_st_req_tag_miss;
	wire s1_ld_req_tag_miss;
	wire s1_ptw_req_tag_miss;
	wire s1_lr_req_tag_miss;
	wire s1_sc_req_tag_miss;
	wire s1_amo_req_tag_miss;
	wire s1_req_tag_miss;
	wire s2_req_tag_miss;
	wire s1_data_ram_st_hit_wr_ready;
	wire s2_sc_req_hit;
	wire fencei_flush_hsk;
	wire fencei_flush_rdy_internal;
	reg [2:0] l1d_bank_fencei_flush_state_d;
	wire [2:0] l1d_bank_fencei_flush_state_q;
	reg l1d_bank_fencei_flush_state_d_ena;
	wire [1:0] l1d_bank_fencei_flush_way_idx_ptr_d;
	wire [1:0] l1d_bank_fencei_flush_way_idx_ptr_q;
	wire l1d_bank_fencei_flush_way_idx_ptr_d_ena;
	wire [0:0] l1d_bank_fencei_flush_set_idx_ptr_d;
	wire [0:0] l1d_bank_fencei_flush_set_idx_ptr_q;
	wire l1d_bank_fencei_flush_set_idx_ptr_d_ena;
	wire in_fencei_flush;
	wire in_fencei_flush_pending;
	wire in_fencei_flush_s1;
	wire in_fencei_flush_s2;
	wire in_fencei_flush_s3;
	wire in_fencei_flush_wait_ewrq_clean;
	wire in_fencei_finish_flush;
	reg next_way_idx_ptr_en;
	reg next_set_idx_ptr_en;
	wire amo_alu_data_vld;
	wire [2:0] amo_type;
	localparam [31:0] rvh_l1d_pkg_ALU_OP_WIDTH = 4;
	reg [3:0] amo_alu_op;
	wire amo_alu_op_w;
	wire amo_alu_op_u;
	wire [63:0] amo_operand0;
	wire [63:0] amo_operand1_src_data;
	wire [63:0] amo_operand1;
	wire [63:0] amo_alu_result;
	reg [63:0] amo_result;
	wire [5:0] amo_req_offset;
	reg [511:0] amo_refill_data;
	wire in_snoop_trans_stall_core_s0_req;
	wire in_snoop_trans_stall_refill;
	wire [48:0] snp_addr_tag;
	wire [0:0] snp_addr_idx;
	assign snp_addr_tag = 0;
	assign snp_addr_idx = 0;
	assign in_snoop_trans_stall_core_s0_req = (((snp_l1d_bank_snp_s0_req_vld_i & snp_l1d_bank_snp_s0_req_rdy_o) | (snp_l1d_bank_snp_s1_req_vld_i & snp_l1d_bank_snp_s1_req_rdy_o)) | (snp_l1d_bank_snp_s2_req_vld_i & snp_l1d_bank_snp_s2_req_rdy_o)) | snp_l1d_bank_snp_s3_req_vld_i;
	assign in_snoop_trans_stall_refill = (snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i | snp_l1d_bank_snp_s1_req_vld_i) | snp_l1d_bank_snp_s2_req_vld_i;
	assign snp_l1d_bank_snp_s0_req_rdy_o = 1'b1;
	assign snp_l1d_bank_snp_s1_req_rdy_o = 1'b1;
	assign snp_l1d_bank_snp_s2_req_rdy_o = 1'b1;
	genvar waynum;
	generate
		for (waynum = 0; waynum < rvh_l1d_pkg_L1D_BANK_WAY_NUM; waynum = waynum + 1) begin : gen_tag_ram_ctrl_signal
			assign tram_cs[waynum] = cache_rd_tram_way_en[waynum] | cache_wr_tram_way_en[waynum];
			assign tram_wen[waynum] = cache_wr_tram_way_en[waynum];
			assign tram_addr[waynum+:1] = cache_idx_tram;
			assign tram_wdat[waynum * 49+:49] = cache_wr_dat_tram;
		end
	endgenerate
	localparam rvh_l1d_pkg_L1D_BANK_SET_NUM = 2;
	generate
		for (waynum = 0; waynum < rvh_l1d_pkg_L1D_BANK_WAY_NUM; waynum = waynum + 1) begin : gen_tag_ram
			generic_spram #(
				.w(rvh_l1d_pkg_L1D_BANK_TAG_RAM_WORD_WIDTH),
				.p(rvh_l1d_pkg_L1D_BANK_TAG_RAM_WORD_WIDTH),
				.d(rvh_l1d_pkg_L1D_BANK_SET_NUM),
				.log2d(6),
				.id(1),
				.RAM_LATENCY(1),
				.RESET(1),
				.RESET_HIGH(0)
			) U_TAG_RAM(
				.clk(clk),
				.ce(tram_cs[waynum]),
				.we(tram_wen[waynum]),
				.addr(tram_addr[waynum+:1]),
				.din(tram_wdat[waynum * 49+:49]),
				.dout(tram_rdat[waynum * 49+:49]),
				.biten(1'sb1)
			);
		end
	endgenerate
	reg [63:0] ls_pipe_l1d_st_req_data_byte_mask_per_seg;
	localparam rvh_l1d_pkg_L1D_OFFSET_BIT_DIFF_STB_SEG = 1;
	generate
		if (1) begin : genblk3
			wire [0:0] offset_bit_diff_stb_seg;
			reg [63:0] ls_pipe_l1d_st_req_data_byte_mask_whole_line;
			assign offset_bit_diff_stb_seg = cur[78-:rvh_l1d_pkg_L1D_OFFSET_BIT_DIFF_STB_SEG];
			always @(*) begin : ls_pipe_l1d_st_req_data_byte_mask_whole_line_gen
				ls_pipe_l1d_st_req_data_byte_mask_whole_line = 1'sb0;
				ls_pipe_l1d_st_req_data_byte_mask_whole_line[offset_bit_diff_stb_seg * 64+:64] = cur[72-:64];
				begin : sv2v_autoblock_1
					reg signed [31:0] i;
					for (i = 0; i < rvh_l1d_pkg_L1D_BANK_WAY_NUM; i = i + 1)
						ls_pipe_l1d_st_req_data_byte_mask_per_seg[i * 16+:16] = ls_pipe_l1d_st_req_data_byte_mask_whole_line[i * 16+:16];
				end
			end
		end
	endgenerate
	assign dram_cs = (cache_way_en_dram & {rvh_l1d_pkg_L1D_BANK_WAY_NUM {cache_wr_valid_dram}}) | {rvh_l1d_pkg_L1D_BANK_WAY_NUM {cache_rd_valid_dram}};
	assign dram_wen = dram_wen_way;
	assign dram_addr = cache_idx_dram;
	assign dram_addr_by_offset = {dram_addr, cache_offset_dram[5:4]};
	assign dram_wdat = (amo_alu_data_vld ? amo_refill_data : (refill_hsk ? refill_req[616-:512] : cur[720-:512]));
	assign st_dat_biten = cur[72-:64];
	assign dram_wen_biten_tmp = (refill_hsk ? {16 {1'sb1}} : st_dat_biten << cur[1443:1440]);
	genvar jj;
	generate
		for (jj = 0; jj < rvh_l1d_pkg_L1D_BANK_WAY_NUM; jj = jj + 1) begin : DATA_RAM_SIGNAL_GEN
			assign cache_way_en_dram[jj] = (refill_hsk ? 1'b1 : cache_way_en_dram_seg[jj]);
			assign dram_wen_way[jj] = cache_wr_valid_dram & cache_way_en_dram[jj];
			assign dram_wen_biten[jj * 16+:16] = (refill_hsk ? {16 {1'sb1}} : cache_way_byte_en_dram_seg[jj * 16+:16]);
			if (jj == 0) begin : genblk1
				assign cache_way_byte_en_dram_seg[jj * 16+:16] = ((({16 {cache_way_idx_dram == 2'b00}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[0+:16]) | ({16 {cache_way_idx_dram == 2'b11}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[16+:16])) | ({16 {cache_way_idx_dram == 2'b10}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[32+:16])) | ({16 {cache_way_idx_dram == 2'b01}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[48+:16]);
				assign dram_wdat_way[jj * 128+:128] = (cache_way_idx_dram == 2'b00 ? dram_wdat[0+:128] : (cache_way_idx_dram == 2'b01 ? dram_wdat[384+:128] : (cache_way_idx_dram == 2'b10 ? dram_wdat[256+:128] : dram_wdat[128+:128])));
				assign dram_addr_by_way[jj * 3+:3] = ((({3 {cache_way_idx_dram == 2'b00}} & {dram_addr, 2'b00}) | ({3 {cache_way_idx_dram == 2'b01}} & {dram_addr, 2'b11})) | ({3 {cache_way_idx_dram == 2'b10}} & {dram_addr, 2'b10})) | ({3 {cache_way_idx_dram == 2'b11}} & {dram_addr, 2'b01});
			end
			if (jj == 1) begin : genblk2
				assign cache_way_byte_en_dram_seg[jj * 16+:16] = ((({16 {cache_way_idx_dram == 2'b00}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[16+:16]) | ({16 {cache_way_idx_dram == 2'b11}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[32+:16])) | ({16 {cache_way_idx_dram == 2'b10}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[48+:16])) | ({16 {cache_way_idx_dram == 2'b01}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[0+:16]);
				assign dram_wdat_way[jj * 128+:128] = (cache_way_idx_dram == 2'b00 ? dram_wdat[128+:128] : (cache_way_idx_dram == 2'b01 ? dram_wdat[0+:128] : (cache_way_idx_dram == 2'b10 ? dram_wdat[384+:128] : dram_wdat[256+:128])));
				assign dram_addr_by_way[jj * 3+:3] = ((({3 {cache_way_idx_dram == 2'b00}} & {dram_addr, 2'b01}) | ({3 {cache_way_idx_dram == 2'b01}} & {dram_addr, 2'b00})) | ({3 {cache_way_idx_dram == 2'b10}} & {dram_addr, 2'b11})) | ({3 {cache_way_idx_dram == 2'b11}} & {dram_addr, 2'b10});
			end
			if (jj == 2) begin : genblk3
				assign cache_way_byte_en_dram_seg[jj * 16+:16] = ((({16 {cache_way_idx_dram == 2'b00}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[32+:16]) | ({16 {cache_way_idx_dram == 2'b11}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[48+:16])) | ({16 {cache_way_idx_dram == 2'b10}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[0+:16])) | ({16 {cache_way_idx_dram == 2'b01}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[16+:16]);
				assign dram_wdat_way[jj * 128+:128] = (cache_way_idx_dram == 2'b00 ? dram_wdat[256+:128] : (cache_way_idx_dram == 2'b01 ? dram_wdat[128+:128] : (cache_way_idx_dram == 2'b10 ? dram_wdat[0+:128] : dram_wdat[384+:128])));
				assign dram_addr_by_way[jj * 3+:3] = ((({3 {cache_way_idx_dram == 2'b00}} & {dram_addr, 2'b10}) | ({3 {cache_way_idx_dram == 2'b01}} & {dram_addr, 2'b01})) | ({3 {cache_way_idx_dram == 2'b10}} & {dram_addr, 2'b00})) | ({3 {cache_way_idx_dram == 2'b11}} & {dram_addr, 2'b11});
			end
			if (jj == 3) begin : genblk4
				assign cache_way_byte_en_dram_seg[jj * 16+:16] = ((({16 {cache_way_idx_dram == 2'b00}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[48+:16]) | ({16 {cache_way_idx_dram == 2'b11}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[0+:16])) | ({16 {cache_way_idx_dram == 2'b10}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[16+:16])) | ({16 {cache_way_idx_dram == 2'b01}} & ls_pipe_l1d_st_req_data_byte_mask_per_seg[32+:16]);
				assign dram_wdat_way[jj * 128+:128] = (cache_way_idx_dram == 2'b00 ? dram_wdat[384+:128] : (cache_way_idx_dram == 2'b01 ? dram_wdat[256+:128] : (cache_way_idx_dram == 2'b10 ? dram_wdat[128+:128] : dram_wdat[0+:128])));
				assign dram_addr_by_way[jj * 3+:3] = ((({3 {cache_way_idx_dram == 2'b00}} & {dram_addr, 2'b11}) | ({3 {cache_way_idx_dram == 2'b01}} & {dram_addr, 2'b10})) | ({3 {cache_way_idx_dram == 2'b10}} & {dram_addr, 2'b01})) | ({3 {cache_way_idx_dram == 2'b11}} & {dram_addr, 2'b00});
			end
			assign dram_addr_ram[jj * 3+:3] = (((cache_rd_valid_dram & ~mlfb_evict_hsk) & ~in_fencei_flush_s2) & ~snp_l1d_bank_snp_s2_req_hsk_i ? dram_addr_by_offset : dram_addr_by_way[jj * 3+:3]);
			assign dram_wdat_ram[jj * 128+:128] = dram_wdat_way[jj * 128+:128];
			assign cache_way_en_dram_seg[jj] = |cache_way_byte_en_dram_seg[jj * 16+:16];
			if (jj == 0) begin : genblk5
				assign dram_rdat_all_way0[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way1[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way2[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way3[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset0[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset1[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset2[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset3[128+:128] = dram_rdat[jj * 128+:128];
			end
			if (jj == 1) begin : genblk6
				assign dram_rdat_all_way0[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way1[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way2[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way3[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset0[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset1[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset2[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset3[256+:128] = dram_rdat[jj * 128+:128];
			end
			if (jj == 2) begin : genblk7
				assign dram_rdat_all_way0[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way1[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way2[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way3[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset0[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset1[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset2[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset3[384+:128] = dram_rdat[jj * 128+:128];
			end
			if (jj == 3) begin : genblk8
				assign dram_rdat_all_way0[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way1[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way2[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way3[0+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset0[384+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset1[256+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset2[128+:128] = dram_rdat[jj * 128+:128];
				assign dram_rdat_all_way_seg_realigned_offset3[0+:128] = dram_rdat[jj * 128+:128];
			end
		end
		for (waynum = 0; waynum < rvh_l1d_pkg_L1D_BANK_WAY_NUM; waynum = waynum + 1) begin : DATA_RAM_GEN
			generic_spram #(
				.w(128),
				.p(8),
				.d(8),
				.log2d(8),
				.id(0),
				.RAM_LATENCY(1),
				.RESET(1),
				.RESET_HIGH(0)
			) U_DATA_RAM(
				.clk(clk),
				.ce(dram_cs[waynum]),
				.we(dram_wen[waynum]),
				.addr(dram_addr_ram[waynum * 3+:3]),
				.din(dram_wdat_ram[waynum * 128+:128]),
				.dout(dram_rdat[waynum * 128+:128]),
				.biten(dram_wen_biten[waynum * 16+:16])
			);
		end
	endgenerate
	rvh_l1d_dec l1dc_dec_u(
		.is_ld_req_vld_i((~ls_pipe_l1d_st_req_vld_i & ~ptw_walk_req_vld_i) & ls_pipe_l1d_ld_req_vld_i),
		.is_st_req_vld_i(ls_pipe_l1d_st_req_vld_i),
		.is_ptw_req_vld_i(~ls_pipe_l1d_st_req_vld_i & ptw_walk_req_vld_i),
		.ls_pipe_l1d_ld_req_opcode_i(ls_pipe_l1d_ld_req_opcode_i),
		.ls_pipe_l1d_st_req_opcode_i(ls_pipe_l1d_st_req_opcode_i),
		.req_type_dec_o(req_type_dec)
	);
	wire [0:0] ls_pipe_l1d_req_idx;
	wire [1:0] ls_pipe_l1d_req_idx_haz_in_mshr_per_entry;
	wire [1:0] ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry;
	wire ls_pipe_l1d_req_idx_haz_in_mshr;
	wire ls_pipe_l1d_req_idx_haz_in_ewrq;
	wire ls_pipe_l1d_req_idx_haz_in_pipe;
	assign ls_pipe_l1d_req_idx = (ls_pipe_l1d_st_req_vld_i ? ls_pipe_l1d_st_req_paddr_i[6:6] : (ptw_walk_req_vld_i ? ptw_walk_req_addr_i[6:6] : ls_pipe_l1d_ld_req_idx_i));
	assign ls_pipe_l1d_req_idx_haz_in_pipe = ((ls_pipe_l1d_ld_req_vld_i | ls_pipe_l1d_st_req_vld_i) | ptw_walk_req_vld_i) & ((((s1_ld_req_tag_miss | s1_ptw_req_tag_miss) | ((s1_valid & cur[755]) & ~cur[742])) & (ls_pipe_l1d_req_idx == cur[1446])) | (s2_req_tag_miss & (ls_pipe_l1d_req_idx == cur[79])));
	genvar i;
	generate
		for (i = 0; i < rvh_l1d_pkg_N_MSHR; i = i + 1) begin : gen_ls_pipe_l1d_req_idx_haz_in_mshr_per_entry
			assign ls_pipe_l1d_req_idx_haz_in_mshr_per_entry[i] = mshr_bank_valid[i] & (ls_pipe_l1d_req_idx == mshr_bank[(i * (((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN)) + 665-:1]);
		end
		for (i = 0; i < rvh_l1d_pkg_N_EWRQ; i = i + 1) begin : gen_ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry
			assign ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry[i] = ewrq_vld[i] & (ls_pipe_l1d_req_idx == ewrq_addr[i * 50-:1]);
		end
	endgenerate
	assign ls_pipe_l1d_req_idx_haz_in_mshr = |ls_pipe_l1d_req_idx_haz_in_mshr_per_entry & (ls_pipe_l1d_ld_req_vld_i | ls_pipe_l1d_st_req_vld_i);
	assign ls_pipe_l1d_req_idx_haz_in_ewrq = |ls_pipe_l1d_req_idx_haz_in_ewrq_per_entry & (ls_pipe_l1d_ld_req_vld_i | ls_pipe_l1d_st_req_vld_i);
	assign ls_pipe_l1d_ld_req_rdy_o = ((((((((((((~s1_stall & ~ls_pipe_l1d_st_req_vld_i) & ~ptw_walk_req_vld_i) & ~s2_st_req_tag_hit) & ~s2_amo_req_tag_hit) & ~s2_sc_req_hit) & ~mlfb_evict_hsk) & ~refill_valid) & ~ls_pipe_l1d_req_idx_haz_in_pipe) & ~ls_pipe_l1d_req_idx_haz_in_mshr) & ~ls_pipe_l1d_req_idx_haz_in_ewrq) & ~rob_flush_i) & ~in_fencei_flush) & ~in_snoop_trans_stall_core_s0_req;
	assign ls_pipe_l1d_ld_req_hsk = (ls_pipe_l1d_ld_req_vld_i & ls_pipe_l1d_ld_req_rdy_o) & stb_l1d_ld_rdy_i;
	assign ls_pipe_l1d_st_req_rdy_o = (((((((~s1_stall & ~mlfb_evict_hsk) & ~refill_valid) & ~ls_pipe_l1d_req_idx_haz_in_pipe) & ~ls_pipe_l1d_req_idx_haz_in_mshr) & ~ls_pipe_l1d_req_idx_haz_in_ewrq) & ~((~has_free_mshr | ((free_mshr_num == 1) & (s1_req_tag_miss | s2_req_tag_miss))) | ((free_mshr_num == 2) & (s1_req_tag_miss & s2_req_tag_miss)))) & ~in_fencei_flush) & ~in_snoop_trans_stall_core_s0_req;
	assign ls_pipe_l1d_st_req_hsk = ls_pipe_l1d_st_req_vld_i & ls_pipe_l1d_st_req_rdy_o;
	assign ls_pipe_l1d_lr_req_hsk = ls_pipe_l1d_st_req_hsk & req_type_dec[6];
	assign ls_pipe_l1d_sc_req_hsk = ls_pipe_l1d_st_req_hsk & req_type_dec[5];
	assign ls_pipe_l1d_amo_req_hsk = ls_pipe_l1d_st_req_hsk & req_type_dec[11];
	assign ptw_walk_req_rdy_o = (((((((((((~s1_stall & ~ls_pipe_l1d_st_req_vld_i) & ~s2_st_req_tag_hit) & ~s2_amo_req_tag_hit) & ~s2_sc_req_hit) & ~mlfb_evict_hsk) & ~refill_valid) & ~ls_pipe_l1d_req_idx_haz_in_pipe) & ~ls_pipe_l1d_req_idx_haz_in_mshr) & ~ls_pipe_l1d_req_idx_haz_in_ewrq) & ~((~has_free_mshr | ((free_mshr_num == 1) & (s1_req_tag_miss | s2_req_tag_miss))) | ((free_mshr_num == 2) & (s1_req_tag_miss & s2_req_tag_miss)))) & ~in_fencei_flush) & ~in_snoop_trans_stall_core_s0_req;
	assign ptw_l1d_walk_req_hsk = (ptw_walk_req_vld_i & ptw_walk_req_rdy_o) & stb_l1d_ptw_walk_req_rdy_i;
	assign mlfb_evict_ready = ~s1_stall & ~((((((s1_valid & cur[742]) | s2_st_req_tag_hit) | s2_amo_req_tag_hit) | s2_sc_req_hit) | refill_hsk) | ~l1d_ewrq_new_ewrq_ready);
	assign mlfb_evict_hsk = mlfb_evict_valid & mlfb_evict_ready;
	assign refill_bank_internal_ready = ((((~((s2_valid & (cur[144] | cur[143])) & cur[726]) & ~stb_l1d_bank_ld_bypass_valid_i) & ~lsu_l1d_s2_kill_valid_i) & ~s2_st_req_tag_hit) & ~s2_amo_req_tag_hit) & ~s2_sc_req_hit;
	assign refill_ready = (refill_bank_internal_ready & ~(((refill_valid & refill_req[96]) & ~refill_req[64]) & ~l1d_int_prf_wb_rdy_from_mlfb_i)) & ~((refill_valid & refill_req[78]) & ~ptw_walk_resp_rdy_i);
	assign refill_bank_internal_hsk = refill_valid & refill_bank_internal_ready;
	assign refill_hsk = refill_valid & refill_ready;
	assign fencei_flush_rdy_internal = (~s1_valid & ~s2_valid) & ~(|mshr_bank_valid);
	assign fencei_flush_hsk = (fencei_flush_vld_i | in_fencei_flush_pending) & fencei_flush_rdy_internal;
	assign lst_rd_idx_s0_req = cache_idx_tram;
	assign cache_rd_valid_tram = (((mlfb_evict_hsk | ls_pipe_l1d_ld_req_hsk) | ls_pipe_l1d_st_req_hsk) | ptw_l1d_walk_req_hsk) | in_fencei_flush_s2;
	assign ls_pipe_l1d_st_req_idx = ls_pipe_l1d_st_req_paddr_i[6:6];
	assign ls_pipe_l1d_st_req_offset = (req_type_dec[6] | req_type_dec[11] ? ls_pipe_l1d_st_req_sc_amo_offset_i : ls_pipe_l1d_st_req_paddr_i[5:0]);
	assign ls_pipe_l1d_st_req_tag = ls_pipe_l1d_st_req_paddr_i[55:7];
	assign cache_idx_tram = (refill_hsk ? refill_req[104-:1] : (mlfb_evict_hsk ? mlfb_evict_req[4-:1] : (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_idx_i : (ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[6:6] : (in_fencei_flush_s2 ? l1d_bank_fencei_flush_set_idx_ptr_q : (snp_l1d_bank_snp_s1_req_hsk_i ? snp_addr_idx : ls_pipe_l1d_st_req_idx))))));
	generate
		for (waynum = 0; waynum < rvh_l1d_pkg_L1D_BANK_WAY_NUM; waynum = waynum + 1) begin : genblk8
			assign cache_rd_tram_way_en[waynum] = (mlfb_evict_hsk ? waynum == mlfb_evict_req[3-:rvh_l1d_pkg_L1D_BANK_WAY_NUM] : (ls_pipe_l1d_ld_req_hsk ? 1'b1 : (ls_pipe_l1d_st_req_hsk ? 1'b1 : (ptw_l1d_walk_req_hsk ? 1'b1 : (in_fencei_flush_s2 ? waynum == l1d_bank_fencei_flush_way_idx_ptr_q : (snp_l1d_bank_snp_s1_req_hsk_i ? 1'b1 : 1'b0))))));
		end
	endgenerate
	assign cache_wr_valid_tram = refill_hsk;
	generate
		for (waynum = 0; waynum < rvh_l1d_pkg_L1D_BANK_WAY_NUM; waynum = waynum + 1) begin : genblk9
			assign cache_wr_tram_way_en[waynum] = (refill_hsk ? waynum == refill_req[103-:4] : 1'b0);
		end
	endgenerate
	assign cache_wr_dat_tram = refill_req[665-:49];
	assign cache_rd_valid_dram = (((((mlfb_evict_hsk | ls_pipe_l1d_ld_req_hsk) | ptw_l1d_walk_req_hsk) | in_fencei_flush_s2) | ls_pipe_l1d_lr_req_hsk) | ls_pipe_l1d_amo_req_hsk) | (snp_l1d_bank_snp_s2_req_hsk_i & snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i);
	assign cache_wr_valid_dram = ((refill_hsk | s2_st_req_tag_hit) | s2_amo_req_tag_hit) | s2_sc_req_hit;
	assign cache_idx_dram = (refill_hsk ? refill_req[104-:1] : (mlfb_evict_hsk ? mlfb_evict_req[4-:1] : (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_idx_i : (ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[6:6] : (in_fencei_flush_s2 ? l1d_bank_fencei_flush_set_idx_ptr_q : (ls_pipe_l1d_lr_req_hsk | ls_pipe_l1d_amo_req_hsk ? ls_pipe_l1d_st_req_idx : (snp_l1d_bank_snp_s2_req_hsk_i ? snp_addr_idx : cur[79])))))));
	assign cache_offset_dram = (refill_hsk ? {6 {1'sb0}} : (mlfb_evict_hsk ? {6 {1'sb0}} : (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_offset_i : (ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[5:0] : (in_fencei_flush_s2 ? {6 {1'sb0}} : (ls_pipe_l1d_lr_req_hsk | ls_pipe_l1d_amo_req_hsk ? ls_pipe_l1d_st_req_offset : (snp_l1d_bank_snp_s2_req_hsk_i ? {6 {1'sb0}} : cur[78-:6])))))));
	assign cache_way_idx_dram = (refill_hsk ? refill_req[103-:4] : (mlfb_evict_hsk ? mlfb_evict_req[3-:rvh_l1d_pkg_L1D_BANK_WAY_NUM] : (in_fencei_flush_s2 ? l1d_bank_fencei_flush_way_idx_ptr_q : (snp_l1d_bank_snp_s2_req_hsk_i ? snp_l1d_bank_snp_s2_req_way_id_i : s2_tag_compare_hit_way_idx))));
	wire ld_tlb_hit;
	wire [48:0] paddr_tag_from_tlb;
	assign dtlb_l1d_resp_rdy_o = 1'sb1;
	assign dtlb_l1d_resp_hsk = dtlb_l1d_resp_vld_i & dtlb_l1d_resp_rdy_o;
	generate
		if (1) begin : genblk10
			assign paddr_tag_from_tlb = {dtlb_l1d_resp_ppn_i, cur[1396:1391]};
		end
	endgenerate
	assign ld_tlb_hit = (dtlb_l1d_resp_hsk & dtlb_l1d_resp_hit_i) & ~dtlb_l1d_resp_excp_vld_i;
	assign tag_used_to_compare = (in_snoop_trans_stall_core_s0_req ? snp_addr_tag : (cur[757] ? paddr_tag_from_tlb : cur[1390-:49]));
	generate
		for (waynum = 0; waynum < rvh_l1d_pkg_L1D_BANK_WAY_NUM; waynum = waynum + 1) begin : gen_s1_tag_compare_hit_per_way
			assign s1_tag_compare_result_per_way[waynum] = tram_rdat[waynum * 49+:49] == tag_used_to_compare;
			assign s1_tag_compare_hit_per_way[waynum] = s1_tag_compare_result_per_way[waynum] && ((cur[758 + (waynum * 2)+:2] == 2'd2) || (cur[758 + (waynum * 2)+:2] == 2'd3));
		end
	endgenerate
	assign s1_tag_compare_hit = (cur[757] ? ld_tlb_hit : 1'b1) && |s1_tag_compare_hit_per_way;
	assign s1_ld_req_tag_hit = ((s1_valid & cur[757]) & ~cur[742]) & s1_tag_compare_hit;
	assign s1_ptw_req_tag_hit = ((s1_valid & cur[756]) & ~cur[742]) & s1_tag_compare_hit;
	assign s1_st_req_tag_hit = ((s1_valid & cur[755]) & ~cur[742]) & s1_tag_compare_hit;
	assign s1_lr_req_tag_hit = ((s1_valid & cur[749]) & ~cur[742]) & s1_tag_compare_hit;
	assign s1_sc_req_tag_hit = ((s1_valid & cur[748]) & ~cur[742]) & s1_tag_compare_hit;
	assign s1_amo_req_tag_hit = ((s1_valid & cur[754]) & ~cur[742]) & s1_tag_compare_hit;
	assign s1_ld_req_tag_miss = ((s1_valid & cur[757]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s1_ptw_req_tag_miss = ((s1_valid & cur[756]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s1_st_req_tag_miss = ((s1_valid & cur[755]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s1_lr_req_tag_miss = ((s1_valid & cur[749]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s1_sc_req_tag_miss = ((s1_valid & cur[748]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s1_amo_req_tag_miss = ((s1_valid & cur[754]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s1_req_tag_miss = ((s1_valid & ~cur[748]) & ~cur[742]) & ~s1_tag_compare_hit;
	assign s2_req_tag_miss = ((s2_valid & ~cur[135]) & ~cur[129]) & ~cur[726];
	assign s1_data_ram_st_hit_wr_ready = 1'sb1;
	assign s2_amo_req_tag_hit = ((s2_valid & cur[141]) & ~cur[129]) & cur[726];
	assign s2_st_req_tag_hit = ((s2_valid & cur[142]) & ~cur[129]) & cur[726];
	assign s2_st_req_tag_miss = ((s2_valid & cur[142]) & ~cur[129]) & ~cur[726];
	assign cache_way_idx_dram_s1 = (in_fencei_flush_s3 ? l1d_bank_fencei_flush_way_idx_ptr_q : (snp_l1d_bank_snp_s3_req_vld_i ? snp_l1d_bank_snp_s3_tag_compare_match_id_i : cur[741-:4]));
	assign cache_offset_dram_s1 = cur[1445-:6];
	assign dram_rdat_all_way_selected = ((({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_way_idx_dram_s1 == 2'b00}} & dram_rdat_all_way0) | ({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_way_idx_dram_s1 == 2'b01}} & dram_rdat_all_way1)) | ({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_way_idx_dram_s1 == 2'b10}} & dram_rdat_all_way2)) | ({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_way_idx_dram_s1 == 2'b11}} & dram_rdat_all_way3);
	assign dram_rdat_all_way_seg_realigned = ((({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_offset_dram_s1[5:4] == 2'b00}} & dram_rdat_all_way_seg_realigned_offset0) | ({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_offset_dram_s1[5:4] == 2'b01}} & dram_rdat_all_way_seg_realigned_offset1)) | ({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_offset_dram_s1[5:4] == 2'b10}} & dram_rdat_all_way_seg_realigned_offset2)) | ({rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE {cache_offset_dram_s1[5:4] == 2'b11}} & dram_rdat_all_way_seg_realigned_offset3);
	assign dram_rdat_all = dram_rdat_all_way_seg_realigned;
	wire s2_is_sc_valid;
	wire [511:0] s2_sc_resp_dat;
	assign s2_is_sc_valid = s2_valid & cur[135];
	assign s2_sc_req_hit = (s2_is_sc_valid & cur[0]) & cur[726];
	assign s2_sc_resp_dat = (s2_sc_req_hit ? {512 {1'sb0}} : {{511 {1'b0}}, 1'b1});
	assign l1d_lsu_resp_valid = (((((((stb_l1d_bank_ld_bypass_valid_i | ((s2_valid & cur[726]) & (cur[144] | cur[143]))) | ((s2_valid & cur[726]) & (cur[141] | cur[136]))) | ((refill_bank_internal_hsk & refill_req[96]) & ~refill_req[64])) & ~lsu_l1d_s2_kill_valid_i) & ~(rob_flush_i & cur[144])) | (refill_bank_internal_hsk & refill_req[78])) | (refill_bank_internal_hsk & (refill_req[76] | refill_req[71]))) | (s2_valid & cur[135]);
	assign l1d_lsu_resp_is_refill = refill_bank_internal_hsk;
	assign l1d_lsu_resp_dat = (refill_bank_internal_hsk ? refill_req[616-:512] : (s2_is_sc_valid ? s2_sc_resp_dat : cur[720-:512]));
	assign l1d_lsu_ld_req_type_dec = (refill_bank_internal_hsk ? refill_req[79-:15] : cur[144-:15]);
	assign l1d_lsu_resp_offset = (refill_bank_internal_hsk ? refill_req[95-:6] : cur[78-:6]);
	assign l1d_lsu_resp_rob_tag = (refill_bank_internal_hsk ? refill_req[89-:4] : cur[736-:4]);
	assign l1d_lsu_resp_prd = (refill_bank_internal_hsk ? refill_req[85-:6] : cur[732-:6]);
	wire [63:0] unsign_ext_dat;
	rvh_l1d_lsu_hit_resp rvh1_l1d_lsu_hit_resp_u(
		.resp_valid_i(l1d_lsu_resp_valid),
		.refill_valid_i(l1d_lsu_resp_is_refill),
		.tag_compare_hit_per_way_i(cur[725-:4]),
		.ld_tlb_hit_i(cur[721]),
		.lsu_ld_dat_i(l1d_lsu_resp_dat),
		.lsu_ld_req_type_dec_i(l1d_lsu_ld_req_type_dec),
		.ls_pipe_l1d_ld_req_rob_tag_i(l1d_lsu_resp_rob_tag),
		.ls_pipe_l1d_ld_req_prd_i(l1d_lsu_resp_prd),
		.ls_pipe_l1d_ld_req_offset_i(l1d_lsu_resp_offset),
		.l1d_rob_wb_vld_o(l1d_rob_wb_vld_o),
		.l1d_rob_wb_rob_tag_o(l1d_rob_wb_rob_tag_o),
		.stb_l1d_bank_ld_bypass_valid_i(stb_l1d_bank_ld_bypass_valid_i),
		.stb_l1d_bank_ld_bypass_data_i(stb_l1d_bank_ld_bypass_data_i),
		.l1d_int_prf_wb_vld_o(l1d_int_prf_wb_vld_o),
		.l1d_int_prf_wb_tag_o(l1d_int_prf_wb_tag_o),
		.l1d_int_prf_wb_data_o(l1d_int_prf_wb_data_o),
		.l1d_int_prf_wb_vld_from_mlfb_o(l1d_int_prf_wb_vld_from_mlfb_o),
		.l1d_ptw_walk_vld_o(ptw_walk_resp_vld_o),
		.l1d_ptw_walk_id_o(ptw_walk_resp_id_o),
		.l1d_ptw_walk_pte_o(ptw_walk_resp_pte_o),
		.unsign_ext_dat_o(unsign_ext_dat)
	);
	assign amo_alu_data_vld = (s2_valid & cur[141]) | (refill_hsk & refill_req[76]);
	assign amo_alu_op_w = (refill_hsk ? refill_req[67] : cur[132]);
	assign amo_alu_op_u = (refill_hsk ? refill_req[75] : cur[140]);
	assign amo_type = (refill_hsk ? refill_req[74-:3] : cur[139-:3]);
	assign amo_req_offset = (refill_hsk ? refill_req[95-:6] : cur[78-:6]);
	function automatic [3:0] sv2v_cast_8BE11;
		input reg [3:0] inp;
		sv2v_cast_8BE11 = inp;
	endfunction
	always @(*) begin
		amo_alu_op = 1'sb0;
		amo_result = amo_alu_result;
		case (amo_type)
			3'd0: begin
				amo_alu_op = sv2v_cast_8BE11(0);
				amo_result = amo_operand1;
			end
			3'd1: amo_alu_op = sv2v_cast_8BE11(0);
			3'd2: amo_alu_op = sv2v_cast_8BE11(9);
			3'd3: amo_alu_op = sv2v_cast_8BE11(8);
			3'd4: amo_alu_op = sv2v_cast_8BE11(5);
			3'd5: begin
				amo_alu_op = (amo_alu_op_u ? sv2v_cast_8BE11(4) : sv2v_cast_8BE11(3));
				amo_result = (amo_alu_result[0] ? amo_operand1 : amo_operand0);
			end
			3'd6: begin
				amo_alu_op = (amo_alu_op_u ? sv2v_cast_8BE11(4) : sv2v_cast_8BE11(3));
				amo_result = (amo_alu_result[0] ? amo_operand0 : amo_operand1);
			end
			default:
				;
		endcase
	end
	assign amo_operand0 = (cur[139-:3] == 3'd0 ? {64 {1'sb0}} : (amo_alu_op_w ? {{32 {~amo_alu_op_u & unsign_ext_dat[31]}}, unsign_ext_dat[31:0]} : unsign_ext_dat));
	assign amo_operand1_src_data = (refill_hsk ? refill_req[63-:rvh_l1d_pkg_XLEN] : cur[208-:64]);
	assign amo_operand1 = (amo_alu_op_w ? {{32 {~amo_alu_op_u & amo_operand1_src_data[31]}}, amo_operand1_src_data[31:0]} : amo_operand1_src_data);
	rvh_l1d_alu rvh_l1d_alu_u(
		.issue_opcode_i(amo_alu_op),
		.issue_op_w_i(amo_alu_op_w),
		.issue_operand0_i(amo_operand0),
		.issue_operand1_i(amo_operand1),
		.wb_data_o(amo_alu_result)
	);
	always @(*) begin
		amo_refill_data = (s2_valid ? {512 {1'sb0}} : refill_req[616-:512]);
		if (amo_alu_op_w)
			amo_refill_data[amo_req_offset * 8+:32] = amo_result[31:0];
		else
			amo_refill_data[amo_req_offset * 8+:64] = amo_result[63:0];
	end
	assign mshr_we = ((s2_req_tag_miss & ~stb_l1d_bank_ld_bypass_valid_i) & ~(rob_flush_i & cur[144])) & ~cur[135];
	assign new_mshr_valid = (mshr_we & has_free_mshr) & ~lsu_l1d_s2_kill_valid_i;
	assign new_mshr[727-:4] = cur[736-:4];
	assign new_mshr[723-:6] = cur[732-:6];
	assign new_mshr[717] = ~cur[144] & ~cur[143];
	assign new_mshr[716] = 1'sb0;
	assign new_mshr[715] = 1'sb0;
	assign new_mshr[714-:49] = cur[128-:49];
	assign new_mshr[665-:1] = cur[79];
	assign new_mshr[664-:6] = cur[78-:6];
	assign new_mshr[658-:2] = 1'sb0;
	assign new_mshr[656-:512] = cur[720-:512];
	assign new_mshr[144-:64] = cur[72-:64];
	assign new_mshr[80-:15] = cur[144-:15];
	assign new_mshr[65-:2] = cur[1 + (s2_tag_compare_hit_way_idx * 2)+:2];
	assign new_mshr[63-:rvh_l1d_pkg_XLEN] = cur[208-:64];
	rvh_l1d_mshr_alloc #(.INPUT_NUM(rvh_l1d_pkg_N_MSHR)) rvh_l1d_mshr_alloc_u(
		.mshr_bank_valid_i(mshr_bank_valid),
		.mshr_id_o(new_mshr_id),
		.has_free_mshr_o(has_free_mshr),
		.free_mshr_num_o(free_mshr_num)
	);
	assign l1d_ls_pipe_replay_vld_o = mshr_we & ~has_free_mshr;
	assign l1d_ls_pipe_mshr_full_o = ~has_free_mshr;
	localparam [0:0] sv2v_uu_MSHR_ext_dirty_0 = 1'sb0;
	rvh_l1d_mshr #(.BANK_ID(BANK_ID)) MSHR(
		.new_mshr_valid_i(new_mshr_valid),
		.new_mshr_i(new_mshr),
		.new_mshr_id_i(new_mshr_id),
		.dirty(sv2v_uu_MSHR_ext_dirty_0),
		.mshr_bank_o(mshr_bank),
		.mshr_bank_valid_o(mshr_bank_valid),
		.mshr_bank_no_resp_o(mshr_bank_no_resp),
		.mshr_bank_sent_o(mshr_bank_sent),
		.mlfb_mshr_dealloc_valid_i(mlfb_mshr_dealloc_valid),
		.mlfb_mshr_dealloc_idx_i(mlfb_mshr_dealloc_idx),
		.mlfb_mshr_dealloc_ready_o(mlfb_mshr_dealloc_ready),
		.l2_req_if_arvalid(l2_req_if_arvalid),
		.l2_req_if_arready(l2_req_if_arready),
		.l2_req_if_ar(l2_req_if_ar),
		.rob_flush_i(rob_flush_i),
		.clk(clk),
		.rst(rst)
	);
	wire [55:0] s1_paddr;
	wire [55:0] s2_paddr;
	assign s1_paddr = {paddr_tag_from_tlb, cur[1446], cur[1445-:6]};
	assign s2_paddr = {cur[128-:49], cur[79], cur[78-:6]};
	assign mlfb_mshr_head_rd_mshr_entry = mshr_bank[mlfb_mshr_head_rd_idx * (((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN)+:((((((((rvh_l1d_pkg_ROB_TAG_WIDTH + rvh_l1d_pkg_PREG_TAG_WIDTH) + 3) + rvh_l1d_pkg_L1D_BANK_PADDR_TAG_WIDTH) + rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH) + rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH) + rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH) + rvh_l1d_pkg_L1D_STB_DATA_WIDTH) + 81) + rvh_l1d_pkg_XLEN];
	assign mlfb_mshr_head_rd_mshr_entry_no_resp = mshr_bank_no_resp[mlfb_mshr_head_rd_idx];
	localparam rvh_l1d_pkg_N_MLFB = rvh_l1d_pkg_N_MSHR;
	rvh_l1d_mlfb #(
		.ENTRY_NUM(rvh_l1d_pkg_N_MLFB),
		.BANK_ID(BANK_ID)
	) U_RRV64_L1D_MLFB(
		.clk(clk),
		.rstn(rst),
		.rob_flush_i(rob_flush_i),
		.l1d_l2_rd_resp_valid(l2_resp_if_rvalid),
		.l1d_l2_rd_resp_ready(l2_resp_if_rready),
		.l1d_l2_rd_resp(l2_resp_if_r),
		.mlfb_mshr_dealloc_valid(mlfb_mshr_dealloc_valid),
		.mlfb_mshr_dealloc_ready(mlfb_mshr_dealloc_ready),
		.mlfb_mshr_dealloc_idx(mlfb_mshr_dealloc_idx),
		.mlfb_mshr_head_rd_idx(mlfb_mshr_head_rd_idx),
		.mlfb_mshr_head_rd_mshr_entry(mlfb_mshr_head_rd_mshr_entry),
		.mlfb_mshr_head_rd_mshr_entry_no_resp(mlfb_mshr_head_rd_mshr_entry_no_resp),
		.mlfb_lru_peek_valid(plru_rd_en_mlfb_peek),
		.mlfb_lru_peek_set_idx(plru_rd_idx_mlfb_peek),
		.mlfb_lru_peek_dat(plru_rd_dat_mlfb_peek),
		.mlfb_lst_peek_set_idx(lst_rd_idx_mlfb_peek),
		.mlfb_lst_peek_dat(lst_rd_dat_mlfb_peek),
		.mlfb_lst_peek_avail_way_idx(lst_rd_avail_way_mlfb_peek),
		.mlfb_lst_check_set_idx(lst_check_set_idx),
		.mlfb_lst_check_way_idx(lst_check_way_idx),
		.mlfb_lst_check_valid(lst_check_valid),
		.mlfb_lst_check_ready(lst_check_ready),
		.mlfb_cache_evict_req_valid(mlfb_evict_valid),
		.mlfb_cache_evict_req_ready(mlfb_evict_ready),
		.mlfb_cache_evict_req(mlfb_evict_req),
		.mlfb_cache_refill_req_valid(refill_valid),
		.mlfb_cache_refill_req_ready(refill_ready),
		.mlfb_cache_refill_req(refill_req),
		.s1_valid(s1_valid),
		.s1_paddr(s1_paddr),
		.s2_valid(s2_valid),
		.s2_paddr(s2_paddr),
		.snoop_stall_refill_i(in_snoop_trans_stall_refill)
	);
	assign l1d_ewrq_new_ewrq_valid = (s1_valid & cur[742]) | in_fencei_flush_s3;
	assign l1d_ewrq_new_ewrq_addr = (in_fencei_flush_s3 ? {tram_rdat[l1d_bank_fencei_flush_way_idx_ptr_q * 49+:49], l1d_bank_fencei_flush_set_idx_ptr_q} : {tram_rdat[cur[741-:4] * 49+:49], cur[1446]});
	assign l1d_ewrq_new_ewrq_dat = dram_rdat_all_way_selected;
	rvh_l1d_ewrq #(.BANK_ID(BANK_ID)) EWRQ(
		.l1d_ewrq_new_ewrq_valid_i(l1d_ewrq_new_ewrq_valid),
		.l1d_ewrq_new_ewrq_addr_i(l1d_ewrq_new_ewrq_addr),
		.l1d_ewrq_new_ewrq_dat_i(l1d_ewrq_new_ewrq_dat),
		.l1d_ewrq_new_ewrq_ready_o(l1d_ewrq_new_ewrq_ready),
		.ewrq_addr_o(ewrq_addr),
		.ewrq_vld_o(ewrq_vld),
		.l2_req_if_awvalid(l2_req_if_awvalid),
		.l2_req_if_awready(l2_req_if_awready),
		.l2_req_if_aw(l2_req_if_aw),
		.l2_req_if_wvalid(l2_req_if_wvalid),
		.l2_req_if_wready(l2_req_if_wready),
		.l2_req_if_w(l2_req_if_w),
		.l2_resp_if_bvalid(l2_resp_if_bvalid),
		.l2_resp_if_bready(l2_resp_if_bready),
		.l2_resp_if_b(l2_resp_if_b),
		.clk(clk),
		.rst(rst)
	);
	always @(*) begin
		s2_tag_compare_hit_way_idx = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_L1D_BANK_WAY_NUM; i = i + 1)
				if (cur[722 + i] == 1'b1)
					s2_tag_compare_hit_way_idx = i;
		end
	end
	assign lst_mesi_wr_en_s0_req_vld = ((((refill_hsk | s2_st_req_tag_hit) | s2_amo_req_tag_hit) | s2_sc_req_hit) | in_fencei_flush_s2) | snp_l1d_bank_snp_s2_req_hsk_i;
	assign lst_mesi_wr_set_idx_s0_req = (refill_hsk ? refill_req[104-:1] : (in_fencei_flush_s2 ? l1d_bank_fencei_flush_set_idx_ptr_q : (snp_l1d_bank_snp_s2_req_hsk_i ? snp_addr_idx : cur[79])));
	assign lst_mesi_wr_way_idx_s0_req = (refill_hsk ? refill_req[103-:4] : (in_fencei_flush_s2 ? l1d_bank_fencei_flush_way_idx_ptr_q : (snp_l1d_bank_snp_s2_req_hsk_i ? snp_l1d_bank_snp_s2_req_way_id_i : s2_tag_compare_hit_way_idx)));
	assign lst_mesi_wr_dat_s0_req = (refill_hsk ? refill_req[99-:2] : (in_fencei_flush_s2 ? 2'd2 : (snp_l1d_bank_snp_s2_req_hsk_i ? snp_l1d_bank_snp_s2_req_new_line_state_i : 2'd3)));
	assign lst_rd_idx_peek = (in_fencei_flush_s1 ? l1d_bank_fencei_flush_set_idx_ptr_q : lst_rd_idx_mlfb_peek);
	localparam [0:0] sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_en_snp_0 = 1'sb0;
	localparam [0:0] sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_set_idx_snp_0 = 1'sb0;
	localparam [1:0] sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_way_idx_snp_0 = 1'sb0;
	localparam [1:0] sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_dat_snp_0 = 1'sb0;
	rvh_l1d_lst #(
		.entry_num(rvh_l1d_pkg_L1D_BANK_SET_NUM),
		.entry_idx(6),
		.way_num(rvh_l1d_pkg_L1D_BANK_WAY_NUM),
		.way_idx(2)
	) U_L1D_LST(
		.clk(clk),
		.rstn(rst),
		.lst_mesi_wr_en_s0_req(lst_mesi_wr_en_s0_req_vld),
		.lst_mesi_wr_set_idx_s0_req(lst_mesi_wr_set_idx_s0_req),
		.lst_mesi_wr_way_idx_s0_req(lst_mesi_wr_way_idx_s0_req),
		.lst_mesi_wr_dat_s0_req(lst_mesi_wr_dat_s0_req),
		.lst_mesi_wr_en_snp(sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_en_snp_0),
		.lst_mesi_wr_set_idx_snp(sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_set_idx_snp_0),
		.lst_mesi_wr_way_idx_snp(sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_way_idx_snp_0),
		.lst_mesi_wr_dat_snp(sv2v_uu_U_L1D_LST_ext_lst_mesi_wr_dat_snp_0),
		.lst_rd_idx_s0_req(lst_rd_idx_s0_req),
		.lst_rd_dat_s0_req(lst_rd_dat_s0_req),
		.lst_rd_idx_mlfb_peek(lst_rd_idx_peek),
		.lst_rd_dat_mlfb_peek(lst_rd_dat_mlfb_peek),
		.lst_avail_way_rd_dat_mlfb_peek(lst_rd_avail_way_mlfb_peek),
		.lst_check_set_idx(lst_check_set_idx),
		.lst_check_way_idx(lst_check_way_idx),
		.lst_check_valid(lst_check_valid),
		.lst_check_ready(lst_check_ready)
	);
	wire plru_upd_en_s1_cache_hit;
	wire [0:0] plru_set_idx_s1_cache_hit;
	wire [1:0] plru_way_idx_s1_cache_hit;
	assign plru_upd_en_s1_cache_hit = (s1_valid & ~s1_stall) & (s1_ld_req_tag_hit | s1_st_req_tag_hit);
	assign plru_set_idx_s1_cache_hit = cur[1446];
	assign plru_way_idx_s1_cache_hit = s2_tag_compare_hit_way_idx;
	rvh_l1d_plru #(
		.entry_num(rvh_l1d_pkg_L1D_BANK_SET_NUM),
		.way_num(rvh_l1d_pkg_L1D_BANK_WAY_NUM)
	) U_RRV64_L1D_PLRU(
		.clk(clk),
		.rstn(rst),
		.upd_en_hit(plru_upd_en_s1_cache_hit),
		.upd_set_idx_hit(plru_set_idx_s1_cache_hit),
		.upd_way_idx_hit(plru_way_idx_s1_cache_hit),
		.rd_en_refill(plru_rd_en_mlfb_peek),
		.rd_idx_refill(plru_rd_idx_mlfb_peek),
		.rd_dat_refill(plru_rd_dat_mlfb_peek)
	);
	always @(*) begin : case_l1d_bank_fencei_flush_state_d
		l1d_bank_fencei_flush_state_d = 3'd0;
		l1d_bank_fencei_flush_state_d_ena = 1'b0;
		next_way_idx_ptr_en = 1'b0;
		next_set_idx_ptr_en = 1'b0;
		case (l1d_bank_fencei_flush_state_q)
			3'd0:
				if (fencei_flush_hsk) begin
					l1d_bank_fencei_flush_state_d = 3'd2;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
				else if (fencei_flush_vld_i) begin
					l1d_bank_fencei_flush_state_d = 3'd1;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
			3'd1:
				if (fencei_flush_hsk) begin
					l1d_bank_fencei_flush_state_d = 3'd2;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
				else begin
					l1d_bank_fencei_flush_state_d = 3'd1;
					l1d_bank_fencei_flush_state_d_ena = 1'b0;
				end
			3'd2:
				if (lst_rd_dat_mlfb_peek[0 + (l1d_bank_fencei_flush_way_idx_ptr_q * 2)+:2] == 2'd3) begin
					l1d_bank_fencei_flush_state_d = 3'd3;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
				else if ((l1d_bank_fencei_flush_set_idx_ptr_q == 1) && (l1d_bank_fencei_flush_way_idx_ptr_q == 3)) begin
					l1d_bank_fencei_flush_state_d = 3'd5;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
				else begin
					l1d_bank_fencei_flush_state_d = 3'd2;
					l1d_bank_fencei_flush_state_d_ena = 1'b0;
					next_way_idx_ptr_en = 1'b1;
					next_set_idx_ptr_en = l1d_bank_fencei_flush_way_idx_ptr_q == {2 {1'sb1}};
				end
			3'd3: begin
				l1d_bank_fencei_flush_state_d = 3'd4;
				l1d_bank_fencei_flush_state_d_ena = 1'b1;
			end
			3'd4:
				if (l1d_ewrq_new_ewrq_ready == 1'b1) begin
					if ((l1d_bank_fencei_flush_set_idx_ptr_q == 1) && (l1d_bank_fencei_flush_way_idx_ptr_q == 3)) begin
						l1d_bank_fencei_flush_state_d = 3'd5;
						l1d_bank_fencei_flush_state_d_ena = 1'b1;
					end
					else begin
						l1d_bank_fencei_flush_state_d = 3'd2;
						l1d_bank_fencei_flush_state_d_ena = 1'b1;
						next_way_idx_ptr_en = 1'b1;
						next_set_idx_ptr_en = l1d_bank_fencei_flush_set_idx_ptr_q == 1'b1;
					end
				end
				else begin
					l1d_bank_fencei_flush_state_d = 3'd3;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
			3'd5:
				if (|ewrq_vld == 1'b0) begin
					l1d_bank_fencei_flush_state_d = 3'd6;
					l1d_bank_fencei_flush_state_d_ena = 1'b1;
				end
				else begin
					l1d_bank_fencei_flush_state_d = 3'd5;
					l1d_bank_fencei_flush_state_d_ena = 1'b0;
				end
			3'd6: begin
				l1d_bank_fencei_flush_state_d = 3'd0;
				l1d_bank_fencei_flush_state_d_ena = 1'b1;
				next_way_idx_ptr_en = 1'b1;
				next_set_idx_ptr_en = 1'b1;
			end
			default: begin
				l1d_bank_fencei_flush_state_d = 3'd0;
				l1d_bank_fencei_flush_state_d_ena = 1'b1;
				next_way_idx_ptr_en = 1'b0;
				next_set_idx_ptr_en = 1'b0;
			end
		endcase
	end
	assign in_fencei_flush_pending = l1d_bank_fencei_flush_state_q == 3'd1;
	assign in_fencei_flush_s1 = l1d_bank_fencei_flush_state_q == 3'd2;
	assign in_fencei_flush_s2 = l1d_bank_fencei_flush_state_q == 3'd3;
	assign in_fencei_flush_s3 = l1d_bank_fencei_flush_state_q == 3'd4;
	assign in_fencei_flush_wait_ewrq_clean = l1d_bank_fencei_flush_state_q == 3'd5;
	assign in_fencei_flush = ((((in_fencei_flush_pending | in_fencei_flush_s1) | in_fencei_flush_s2) | in_fencei_flush_s3) | in_fencei_flush_wait_ewrq_clean) | in_fencei_finish_flush;
	assign in_fencei_finish_flush = l1d_bank_fencei_flush_state_q == 3'd6;
	assign l1d_bank_fencei_flush_way_idx_ptr_d = (in_fencei_finish_flush ? {2 {1'sb0}} : l1d_bank_fencei_flush_way_idx_ptr_q + 1);
	assign l1d_bank_fencei_flush_set_idx_ptr_d = (in_fencei_finish_flush ? 1'b0 : l1d_bank_fencei_flush_set_idx_ptr_q + 1);
	assign l1d_bank_fencei_flush_way_idx_ptr_d_ena = in_fencei_finish_flush | next_way_idx_ptr_en;
	assign l1d_bank_fencei_flush_set_idx_ptr_d_ena = in_fencei_finish_flush | next_set_idx_ptr_en;
	assign fencei_flush_grant_o = in_fencei_finish_flush;
	std_dffrve #(.WIDTH(3)) U_L1D_BANK_FENCEI_STATE_REG(
		.clk(clk),
		.rstn(rst),
		.rst_val(3'd0),
		.en(l1d_bank_fencei_flush_state_d_ena),
		.d(l1d_bank_fencei_flush_state_d),
		.q(l1d_bank_fencei_flush_state_q)
	);
	std_dffre #(.WIDTH(rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH)) U_L1D_BANK_FENCEI_WAY_IDX_REG(
		.clk(clk),
		.rstn(rst),
		.en(l1d_bank_fencei_flush_way_idx_ptr_d_ena),
		.d(l1d_bank_fencei_flush_way_idx_ptr_d),
		.q(l1d_bank_fencei_flush_way_idx_ptr_q)
	);
	std_dffre #(.WIDTH(rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH)) U_L1D_BANK_FENCEI_SET_IDX_REG(
		.clk(clk),
		.rstn(rst),
		.en(l1d_bank_fencei_flush_set_idx_ptr_d_ena),
		.d(l1d_bank_fencei_flush_set_idx_ptr_d),
		.q(l1d_bank_fencei_flush_set_idx_ptr_q)
	);
	assign s1_stall = s1_valid & (((cur[757] & s1_tag_compare_hit) & s2_stall) | (cur[742] & ~l1d_ewrq_new_ewrq_ready));
	assign s1_valid_nxt = ((ls_pipe_l1d_ld_req_hsk | ls_pipe_l1d_st_req_hsk) | mlfb_evict_hsk) | ptw_l1d_walk_req_hsk;
	assign s1_nxt_ena = s1_valid_nxt & ~s1_stall;
	assign nxt[1456-:4] = (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_rob_tag_i : (ptw_l1d_walk_req_hsk ? ptw_walk_req_id_i : ls_pipe_l1d_st_req_rob_tag_i));
	assign nxt[1452-:6] = (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_prd_i : ls_pipe_l1d_st_req_prd_i);
	assign nxt[1446] = (mlfb_evict_hsk ? mlfb_evict_req[4-:1] : (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_idx_i : (ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[6:6] : ls_pipe_l1d_st_req_idx)));
	assign nxt[1445-:6] = (ls_pipe_l1d_ld_req_hsk ? ls_pipe_l1d_ld_req_offset_i : (ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[5:0] : ls_pipe_l1d_st_req_offset));
	assign nxt[1439-:49] = ls_pipe_l1d_ld_req_vtag_i;
	assign nxt[1390-:49] = (ptw_l1d_walk_req_hsk ? ptw_walk_req_addr_i[55:7] : ls_pipe_l1d_st_req_tag);
	assign nxt[1341-:512] = ls_pipe_l1d_st_req_data_i;
	assign nxt[829-:64] = ls_pipe_l1d_st_req_data_byte_mask_i;
	assign nxt[765-:8] = lst_rd_dat_s0_req;
	assign nxt[757-:15] = req_type_dec;
	assign nxt[742] = mlfb_evict_hsk;
	assign nxt[741-:4] = mlfb_evict_req[3-:rvh_l1d_pkg_L1D_BANK_WAY_NUM];
	assign nxt[737] = ls_pipe_l1d_st_req_sc_rt_check_succ_i;
	std_dffr #(.WIDTH(1)) U_STG_VALID_REG_S1(
		.clk(clk),
		.rstn(rst),
		.d(s1_valid_nxt),
		.q(s1_valid)
	);
	std_dffe #(.WIDTH(720)) U_STG_DAT_REG_S1(
		.clk(clk),
		.en(s1_nxt_ena),
		.d(nxt[1456-:720]),
		.q(cur[1456-:720])
	);
	assign s2_stall = 1'b0;
	assign s2_valid_nxt = ((((((((s1_ld_req_tag_hit | s1_ld_req_tag_miss) & ld_tlb_hit) & ~rob_flush_i) | (s1_ptw_req_tag_hit | s1_ptw_req_tag_miss)) | (s1_st_req_tag_hit | s1_st_req_tag_miss)) | (s1_lr_req_tag_hit | s1_lr_req_tag_miss)) | (s1_sc_req_tag_hit | s1_sc_req_tag_miss)) | (s1_amo_req_tag_hit | s1_amo_req_tag_miss)) & ~cur[742];
	assign s2_nxt_ena = s2_valid_nxt & ~s2_stall;
	assign nxt[726] = s1_tag_compare_hit;
	assign nxt[725-:4] = s1_tag_compare_hit_per_way;
	assign nxt[721] = ld_tlb_hit;
	assign nxt[720-:512] = (((cur[757] | cur[756]) | cur[754]) | cur[749] ? dram_rdat_all : cur[1341-:512]);
	assign nxt[208-:64] = cur[830 + (cur[1445-:6] * 8)+:rvh_l1d_pkg_XLEN];
	assign nxt[736-:4] = cur[1456-:4];
	assign nxt[732-:6] = cur[1452-:6];
	assign nxt[144-:15] = cur[757-:15];
	assign nxt[129] = cur[742];
	assign nxt[128-:49] = (cur[757] ? paddr_tag_from_tlb : cur[1390-:49]);
	assign nxt[79] = cur[1446];
	assign nxt[78-:6] = cur[1445-:6];
	assign nxt[72-:64] = cur[829-:64];
	assign nxt[8-:8] = cur[765-:8];
	assign nxt[0] = cur[737];
	std_dffr #(.WIDTH(1)) U_STG_VALID_REG_S2(
		.clk(clk),
		.rstn(rst),
		.d(s2_valid_nxt),
		.q(s2_valid)
	);
	std_dffe #(.WIDTH(737)) U_STG_DAT_REG_S2(
		.clk(clk),
		.en(s2_nxt_ena),
		.d(nxt[736-:737]),
		.q(cur[736-:737])
	);
endmodule
