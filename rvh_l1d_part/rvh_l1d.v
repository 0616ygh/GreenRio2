module rvh_l1d (
	ls_pipe_l1d_ld_req_vld_i,
	ls_pipe_l1d_ld_req_io_i,
	ls_pipe_l1d_ld_req_rob_tag_i,
	ls_pipe_l1d_ld_req_prd_i,
	ls_pipe_l1d_ld_req_opcode_i,
	ls_pipe_l1d_ld_req_index_i,
	ls_pipe_l1d_ld_req_offset_i,
	ls_pipe_l1d_ld_req_vtag_i,
	ls_pipe_l1d_ld_req_rdy_o,
	ls_pipe_l1d_dtlb_resp_vld_i,
	ls_pipe_l1d_dtlb_resp_ppn_i,
	ls_pipe_l1d_dtlb_resp_excp_vld_i,
	ls_pipe_l1d_dtlb_resp_hit_i,
	ls_pipe_l1d_dtlb_resp_miss_i,
	ls_pipe_l1d_st_req_vld_i,
	ls_pipe_l1d_st_req_io_i,
	ls_pipe_l1d_st_req_is_fence_i,
	ls_pipe_l1d_st_req_rob_tag_i,
	ls_pipe_l1d_st_req_prd_i,
	ls_pipe_l1d_st_req_opcode_i,
	ls_pipe_l1d_st_req_paddr_i,
	ls_pipe_l1d_st_req_data_i,
	ls_pipe_l1d_st_req_rdy_o,
	l1d_ls_pipe_ld_replay_valid_o,
	ls_pipe_l1d_kill_resp_i,
	l1d_rob_wb_vld_o,
	l1d_rob_wb_rob_tag_o,
	l1d_int_prf_wb_vld_o,
	l1d_int_prf_wb_tag_o,
	l1d_int_prf_wb_data_o,
	ptw_walk_req_vld_i,
	ptw_walk_req_id_i,
	ptw_walk_req_addr_i,
	ptw_walk_req_rdy_o,
	ptw_walk_resp_vld_o,
	ptw_walk_resp_id_o,
	ptw_walk_resp_pte_o,
	ptw_walk_resp_rdy_i,
	l1d_l2_req_arvalid_o,
	l1d_l2_req_arready_i,
	l1d_l2_req_ar_o,
	l1d_l2_req_awvalid_o,
	l1d_l2_req_awready_i,
	l1d_l2_req_aw_o,
	l1d_l2_req_wvalid_o,
	l1d_l2_req_wready_i,
	l1d_l2_req_w_o,
	l2_l1d_resp_bvalid_i,
	l2_l1d_resp_bready_o,
	l2_l1d_resp_b_i,
	l2_l1d_resp_rvalid_i,
	l2_l1d_resp_rready_o,
	l2_l1d_resp_r_i,
	rob_flush_i,
	fencei_flush_vld_i,
	fencei_flush_grant_o,
	clk,
	rst
);
	localparam [31:0] rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT = 2;
	input wire [1:0] ls_pipe_l1d_ld_req_vld_i;
	input wire [1:0] ls_pipe_l1d_ld_req_io_i;
	localparam [31:0] rvh_l1d_pkg_ROB_INDEX_WIDTH = 4;
	localparam [31:0] rvh_l1d_pkg_ROB_TAG_WIDTH = rvh_l1d_pkg_ROB_INDEX_WIDTH;
	input wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_l1d_ld_req_rob_tag_i;
	localparam [31:0] rvh_l1d_pkg_INT_PREG_COUNT = 48;
	localparam [31:0] rvh_l1d_pkg_INT_PREG_TAG_WIDTH = 6;
	localparam [31:0] rvh_l1d_pkg_PREG_TAG_WIDTH = rvh_l1d_pkg_INT_PREG_TAG_WIDTH;
	input wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_l1d_ld_req_prd_i;
	localparam [31:0] rvh_l1d_pkg_LDU_OP_WIDTH = 3;
	input wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_LDU_OP_WIDTH) - 1:0] ls_pipe_l1d_ld_req_opcode_i;
	localparam rvh_l1d_pkg_L1D_INDEX_WIDTH = 1;
	input wire [1:0] ls_pipe_l1d_ld_req_index_i;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	input wire [11:0] ls_pipe_l1d_ld_req_offset_i;
	localparam rvh_l1d_pkg_L1D_TAG_WIDTH = 49;
	input wire [97:0] ls_pipe_l1d_ld_req_vtag_i;
	output wire [1:0] ls_pipe_l1d_ld_req_rdy_o;
	input wire [1:0] ls_pipe_l1d_dtlb_resp_vld_i;
	localparam rvh_l1d_pkg_PPN_WIDTH = 48;
	input wire [95:0] ls_pipe_l1d_dtlb_resp_ppn_i;
	input wire [1:0] ls_pipe_l1d_dtlb_resp_excp_vld_i;
	input wire [1:0] ls_pipe_l1d_dtlb_resp_hit_i;
	input wire [1:0] ls_pipe_l1d_dtlb_resp_miss_i;
	localparam [31:0] rvh_l1d_pkg_LSU_DATA_PIPE_COUNT = 2;
	input wire [1:0] ls_pipe_l1d_st_req_vld_i;
	input wire [1:0] ls_pipe_l1d_st_req_io_i;
	input wire [1:0] ls_pipe_l1d_st_req_is_fence_i;
	input wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_ROB_TAG_WIDTH) - 1:0] ls_pipe_l1d_st_req_rob_tag_i;
	input wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_PREG_TAG_WIDTH) - 1:0] ls_pipe_l1d_st_req_prd_i;
	localparam [31:0] rvh_l1d_pkg_STU_OP_WIDTH = 5;
	input wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_STU_OP_WIDTH) - 1:0] ls_pipe_l1d_st_req_opcode_i;
	localparam [31:0] rvh_l1d_pkg_PADDR_WIDTH = 56;
	input wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_PADDR_WIDTH) - 1:0] ls_pipe_l1d_st_req_paddr_i;
	localparam [31:0] rvh_l1d_pkg_XLEN = 64;
	input wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_XLEN) - 1:0] ls_pipe_l1d_st_req_data_i;
	output wire [1:0] ls_pipe_l1d_st_req_rdy_o;
	output wire [1:0] l1d_ls_pipe_ld_replay_valid_o;
	input wire [1:0] ls_pipe_l1d_kill_resp_i;
	output wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT + rvh_l1d_pkg_LSU_DATA_PIPE_COUNT) - 1:0] l1d_rob_wb_vld_o;
	output wire [((rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT + rvh_l1d_pkg_LSU_DATA_PIPE_COUNT) * rvh_l1d_pkg_ROB_TAG_WIDTH) - 1:0] l1d_rob_wb_rob_tag_o;
	output wire [1:0] l1d_int_prf_wb_vld_o;
	output wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_INT_PREG_TAG_WIDTH) - 1:0] l1d_int_prf_wb_tag_o;
	output wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_XLEN) - 1:0] l1d_int_prf_wb_data_o;
	input wire ptw_walk_req_vld_i;
	localparam [31:0] rvh_l1d_pkg_PTW_ID_WIDTH = 1;
	input wire [0:0] ptw_walk_req_id_i;
	input wire [55:0] ptw_walk_req_addr_i;
	output wire ptw_walk_req_rdy_o;
	output reg ptw_walk_resp_vld_o;
	output reg [0:0] ptw_walk_resp_id_o;
	localparam rvh_l1d_pkg_PTE_WIDTH = 64;
	output reg [63:0] ptw_walk_resp_pte_o;
	input wire ptw_walk_resp_rdy_i;
	output wire l1d_l2_req_arvalid_o;
	input wire l1d_l2_req_arready_i;
	localparam rvh_l1d_pkg_MEMNOC_TID_MASTERID_SIZE = 4;
	localparam rvh_l1d_pkg_MEMNOC_TID_TID_SIZE = 4;
	output wire [76:0] l1d_l2_req_ar_o;
	output wire l1d_l2_req_awvalid_o;
	input wire l1d_l2_req_awready_i;
	output wire [76:0] l1d_l2_req_aw_o;
	output wire l1d_l2_req_wvalid_o;
	input wire l1d_l2_req_wready_i;
	localparam rvh_l1d_pkg_MEM_DATA_WIDTH = 64;
	output wire [72:0] l1d_l2_req_w_o;
	input wire l2_l1d_resp_bvalid_i;
	output wire l2_l1d_resp_bready_o;
	input wire [9:0] l2_l1d_resp_b_i;
	input wire l2_l1d_resp_rvalid_i;
	output wire l2_l1d_resp_rready_o;
	input wire [77:0] l2_l1d_resp_r_i;
	input wire rob_flush_i;
	input wire fencei_flush_vld_i;
	output reg fencei_flush_grant_o;
	input clk;
	input rst;
	genvar i;
	genvar j;
	genvar k;
	wire in_amo_state;
	reg [2:0] l1d_fencei_state_d;
	wire [2:0] l1d_fencei_state_q;
	reg l1d_fencei_state_d_ena;
	localparam rvh_l1d_pkg_L1D_BANK_ID_NUM = 1;
	wire [0:0] fencei_flush_grant_per_bank_out;
	reg [0:0] fencei_flush_grant_per_bank_d;
	wire [0:0] fencei_flush_grant_per_bank_q;
	reg [0:0] fencei_flush_grant_per_bank_d_ena;
	wire in_fencei_flush;
	reg fencei_flush_stb_vld;
	wire fencei_flush_stb_rdy;
	wire fencei_flush_stb_done;
	reg fencei_flush_bank_vld;
	wire [1:0] ls_pipe_l1d_ld_req_vld_masked;
	wire [1:0] ls_pipe_l1d_ld_req_rdy_unmasked;
	wire [1:0] ls_pipe_l1d_st_req_vld_masked;
	wire [1:0] ls_pipe_l1d_st_req_rdy_unmasked;
	wire ptw_walk_req_vld_masked;
	reg ptw_walk_req_rdy_unmasked;
	assign ls_pipe_l1d_ld_req_vld_masked = (ls_pipe_l1d_ld_req_vld_i & ~{rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT {in_fencei_flush}}) & ~{rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT {in_amo_state}};
	assign ls_pipe_l1d_ld_req_rdy_o = (ls_pipe_l1d_ld_req_rdy_unmasked & ~{rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT {in_fencei_flush}}) & ~{rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT {in_amo_state}};
	assign ls_pipe_l1d_st_req_vld_masked = ls_pipe_l1d_st_req_vld_i & ~{rvh_l1d_pkg_LSU_DATA_PIPE_COUNT {in_fencei_flush}};
	assign ls_pipe_l1d_st_req_rdy_o = ls_pipe_l1d_st_req_rdy_unmasked & ~{rvh_l1d_pkg_LSU_DATA_PIPE_COUNT {in_fencei_flush}};
	assign ptw_walk_req_vld_masked = ptw_walk_req_vld_i & ~in_fencei_flush;
	assign ptw_walk_req_rdy_o = ptw_walk_req_rdy_unmasked & ~in_fencei_flush;
	always @(*) begin : case_l1d_fencei_state_d
		l1d_fencei_state_d = 3'd0;
		l1d_fencei_state_d_ena = 1'b0;
		fencei_flush_stb_vld = 1'sb0;
		fencei_flush_bank_vld = 1'sb0;
		fencei_flush_grant_per_bank_d_ena = 1'sb0;
		fencei_flush_grant_per_bank_d = fencei_flush_grant_per_bank_out;
		fencei_flush_grant_o = 1'sb0;
		case (l1d_fencei_state_q)
			3'd0: begin
				fencei_flush_stb_vld = fencei_flush_vld_i;
				if (fencei_flush_vld_i & fencei_flush_stb_rdy) begin
					l1d_fencei_state_d = 3'd2;
					l1d_fencei_state_d_ena = 1'b1;
				end
				else if (fencei_flush_vld_i) begin
					l1d_fencei_state_d = 3'd1;
					l1d_fencei_state_d_ena = 1'b1;
				end
			end
			3'd1: begin
				fencei_flush_stb_vld = 1'b1;
				if (fencei_flush_stb_rdy) begin
					l1d_fencei_state_d = 3'd2;
					l1d_fencei_state_d_ena = 1'b1;
				end
				else begin
					l1d_fencei_state_d = 3'd1;
					l1d_fencei_state_d_ena = 1'b0;
				end
			end
			3'd2:
				if (fencei_flush_stb_done) begin
					l1d_fencei_state_d = 3'd3;
					l1d_fencei_state_d_ena = 1'b1;
				end
				else begin
					l1d_fencei_state_d = 3'd2;
					l1d_fencei_state_d_ena = 1'b0;
				end
			3'd3: begin
				fencei_flush_bank_vld = 1'b1;
				l1d_fencei_state_d = 3'd4;
				l1d_fencei_state_d_ena = 1'b1;
			end
			3'd4: begin
				fencei_flush_grant_per_bank_d_ena = ~fencei_flush_grant_per_bank_q & fencei_flush_grant_per_bank_d;
				if (&fencei_flush_grant_per_bank_q == 1'b1) begin
					l1d_fencei_state_d = 3'd5;
					l1d_fencei_state_d_ena = 1'b1;
				end
			end
			3'd5: begin
				fencei_flush_grant_o = 1'b1;
				fencei_flush_grant_per_bank_d = 1'sb0;
				fencei_flush_grant_per_bank_d_ena = 1'sb1;
				l1d_fencei_state_d = 3'd0;
				l1d_fencei_state_d_ena = 1'b1;
			end
			default: begin
				l1d_fencei_state_d = 3'd0;
				l1d_fencei_state_d_ena = 1'b1;
			end
		endcase
	end
	assign in_fencei_flush = l1d_fencei_state_q != 3'd0;
	std_dffrve #(.WIDTH(3)) U_FENCEI_STATE_REG(
		.clk(clk),
		.rstn(rst),
		.rst_val(3'd0),
		.en(l1d_fencei_state_d_ena),
		.d(l1d_fencei_state_d),
		.q(l1d_fencei_state_q)
	);
	generate
		for (i = 0; i < rvh_l1d_pkg_L1D_BANK_ID_NUM; i = i + 1) begin : gen_fencei_flush_grant_per_bank_q
			std_dffre #(.WIDTH(1)) U_FENCEI_FLUSH_GRANT_PER_BANK_REG(
				.clk(clk),
				.rstn(rst),
				.en(fencei_flush_grant_per_bank_d_ena[i]),
				.d(fencei_flush_grant_per_bank_d[i]),
				.q(fencei_flush_grant_per_bank_q[i])
			);
		end
	endgenerate
	wire [0:0] l1d_arb_bank_ld_req_vld;
	wire [3:0] l1d_arb_bank_ld_req_rob_tag;
	wire [5:0] l1d_arb_bank_ld_req_prd;
	wire [2:0] l1d_arb_bank_ld_req_opcode;
	localparam rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH = 1;
	wire [0:0] l1d_arb_bank_ld_req_idx;
	localparam rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH = rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	wire [5:0] l1d_arb_bank_ld_req_offset;
	localparam rvh_l1d_pkg_L1D_BANK_TAG_WIDTH = rvh_l1d_pkg_L1D_TAG_WIDTH;
	wire [48:0] l1d_arb_bank_ld_req_vtag;
	wire [0:0] l1d_arb_bank_stb_ld_req_rdy;
	wire [0:0] l1d_arb_bank_ld_req_rdy;
	wire [0:0] l1d_arb_bank_dtlb_resp_vld;
	wire [0:0] l1d_arb_bank_dtlb_resp_excp_vld;
	wire [0:0] l1d_arb_bank_dtlb_resp_hit;
	wire [47:0] l1d_arb_bank_dtlb_resp_ppn;
	wire [0:0] l1d_arb_bank_dtlb_resp_rdy;
	reg [0:0] l1d_arb_bank_st_req_vld;
	reg [0:0] l1d_arb_bank_st_req_io_region;
	reg [3:0] l1d_arb_bank_st_req_rob_tag;
	reg [5:0] l1d_arb_bank_st_req_prd;
	reg [4:0] l1d_arb_bank_st_req_opcode;
	reg [55:0] l1d_arb_bank_st_req_paddr;
	localparam rvh_l1d_pkg_L1D_STB_DATA_WIDTH = 512;
	reg [511:0] l1d_arb_bank_st_req_data;
	reg [63:0] l1d_arb_bank_st_req_data_byte_mask;
	reg [0:0] l1d_arb_bank_st_req_sc_rt_check_succ;
	reg [5:0] l1d_arb_bank_st_req_sc_amo_offset;
	wire [0:0] l1d_arb_bank_st_req_rdy;
	wire [0:0] bank_l1d_replay_vld;
	wire [0:0] bank_l1d_mshr_full;
	reg [0:0] l1d_arb_bank_ptw_walk_req_vld;
	reg [0:0] l1d_arb_bank_ptw_walk_req_id;
	reg [55:0] l1d_arb_bank_ptw_walk_req_paddr;
	wire [0:0] l1d_arb_bank_ptw_walk_req_rdy;
	wire l1d_arb_stb_ptw_walk_req_rdy;
	wire ptw_replay_bank_ptw_walk_req_vld;
	wire [0:0] ptw_replay_bank_ptw_walk_req_id;
	wire [55:0] ptw_replay_bank_ptw_walk_req_paddr;
	reg ptw_replay_bank_ptw_walk_req_rdy;
	wire [0:0] band_l1d_arb_ptw_walk_resp_vld;
	wire [0:0] band_l1d_arb_ptw_walk_resp_id;
	wire [63:0] band_l1d_arb_ptw_walk_resp_pte;
	wire [0:0] l1d_bank_axi_arb_arvalid;
	wire [0:0] l1d_bank_axi_arb_arready;
	wire [76:0] l1d_bank_axi_arb_ar;
	wire [0:0] l1d_bank_axi_arb_awvalid;
	wire [0:0] l1d_bank_axi_arb_awready;
	wire [76:0] l1d_bank_axi_arb_aw;
	wire [0:0] l1d_bank_axi_arb_wvalid;
	wire [0:0] l1d_bank_axi_arb_wready;
	wire [72:0] l1d_bank_axi_arb_w;
	wire [0:0] l1d_bank_axi_arb_bvalid;
	wire [0:0] l1d_bank_axi_arb_bready;
	wire [9:0] l1d_bank_axi_arb_b;
	wire [0:0] l1d_bank_axi_arb_rvalid;
	wire [0:0] l1d_bank_axi_arb_rready;
	wire [77:0] l1d_bank_axi_arb_r;
	wire [0:0] l1d_rob_wb_vld;
	wire [3:0] l1d_rob_wb_rob_tag;
	wire [0:0] l1d_bank_l1d_wb_vld;
	wire [5:0] l1d_bank_l1d_wb_tag;
	wire [63:0] l1d_bank_l1d_wb_data;
	wire [0:0] l1d_bank_l1d_wb_vld_from_mlfb;
	reg [0:0] l1d_bank_l1d_wb_rdy_from_mlfb;
	wire [1:0] ls_pipe_stb_ld_req_rdy;
	wire [1:0] ls_pipe_l1d_bank_ld_req_rdy;
	assign ls_pipe_l1d_bank_ld_req_rdy[1] = 0;
	generate
		for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1) begin : gen_ls_pipe_l1d_ld_req_rdy_o
			assign ls_pipe_l1d_ld_req_rdy_unmasked[i] = ls_pipe_stb_ld_req_rdy[i] & ls_pipe_l1d_bank_ld_req_rdy[i];
		end
	endgenerate
	wire stb_l1d_arb_st_req_vld;
	wire [3:0] stb_l1d_arb_st_req_rob_tag;
	wire [5:0] stb_l1d_arb_st_req_prd;
	wire [4:0] stb_l1d_arb_st_req_opcode;
	wire [55:0] stb_l1d_arb_st_req_paddr;
	wire [511:0] stb_l1d_arb_st_req_data;
	wire [63:0] stb_l1d_arb_st_req_data_byte_mask;
	wire stb_l1d_arb_st_req_sc_rt_check_succ;
	wire [5:0] stb_l1d_arb_st_req_amo_offset;
	reg stb_l1d_arb_st_req_rdy;
	wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT + rvh_l1d_pkg_LSU_DATA_PIPE_COUNT) - 1:0] stb_rob_wb_vld;
	wire [((rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT + rvh_l1d_pkg_LSU_DATA_PIPE_COUNT) * rvh_l1d_pkg_ROB_TAG_WIDTH) - 1:0] stb_rob_wb_rob_tag;
	wire [1:0] stb_int_prf_wb_vld;
	wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_INT_PREG_TAG_WIDTH) - 1:0] stb_int_prf_wb_tag;
	wire [(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT * rvh_l1d_pkg_XLEN) - 1:0] stb_int_prf_wb_data;
	wire [1:0] stb_l1d_arb_bank_id;
	reg [1:0] stb_l1d_arb_bank_id_mask;
	wire [1:0] stb_l1d_bank_ld_bypass_valid_per_ld_pipe;
	wire [127:0] stb_l1d_bank_ld_bypass_data_per_ld_pipe;
	wire [0:0] stb_l1d_bank_ld_bypass_valid;
	wire [63:0] stb_l1d_bank_ld_bypass_data;
	always @(*) begin : comb_stb_l1d_arb_bank_id_mask
		stb_l1d_arb_bank_id_mask = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1)
				if (stb_l1d_arb_bank_id[i+:1] == 0)
					stb_l1d_arb_bank_id_mask[i] = 1'b1;
		end
	end
	generate
		for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1) begin : gen_stb_l1d_bank_ld_bypass_valid_per_bank
			assign stb_l1d_bank_ld_bypass_valid_per_ld_pipe[i] = stb_l1d_arb_bank_id_mask[i] & stb_int_prf_wb_vld[i];
		end
		for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1) begin : gen_stb_l1d_bank_ld_bypass_data_per_bank
			for (k = 0; k < rvh_l1d_pkg_XLEN; k = k + 1) begin : genblk1
				assign stb_l1d_bank_ld_bypass_data_per_ld_pipe[(i * 64) + k] = (stb_l1d_arb_bank_id_mask[i] & stb_int_prf_wb_data[(i * rvh_l1d_pkg_XLEN) + k]) & stb_int_prf_wb_vld[i];
			end
		end
	endgenerate
	assign stb_l1d_bank_ld_bypass_valid = stb_l1d_bank_ld_bypass_valid_per_ld_pipe[0+:1] | stb_l1d_bank_ld_bypass_valid_per_ld_pipe[1+:1];
	assign stb_l1d_bank_ld_bypass_data = stb_l1d_bank_ld_bypass_data_per_ld_pipe[0+:64] | stb_l1d_bank_ld_bypass_data_per_ld_pipe[64+:64];
	always @(*) begin
		l1d_arb_bank_st_req_vld = 1'sb0;
		stb_l1d_arb_st_req_rdy = 1'sb1;
		l1d_arb_bank_st_req_io_region = 1'sb0;
		l1d_arb_bank_st_req_rob_tag = 1'sb0;
		l1d_arb_bank_st_req_prd = 1'sb0;
		l1d_arb_bank_st_req_opcode = 1'sb0;
		l1d_arb_bank_st_req_paddr = 1'sb0;
		l1d_arb_bank_st_req_data = 1'sb0;
		l1d_arb_bank_st_req_data_byte_mask = 1'sb0;
		l1d_arb_bank_st_req_sc_rt_check_succ = 1'sb0;
		l1d_arb_bank_st_req_sc_amo_offset = 1'sb0;
		l1d_arb_bank_st_req_vld[0] = stb_l1d_arb_st_req_vld;
		l1d_arb_bank_st_req_io_region[0] = 1'b0;
		l1d_arb_bank_st_req_rob_tag[0+:rvh_l1d_pkg_ROB_TAG_WIDTH] = stb_l1d_arb_st_req_rob_tag;
		l1d_arb_bank_st_req_prd[0+:rvh_l1d_pkg_PREG_TAG_WIDTH] = stb_l1d_arb_st_req_prd;
		l1d_arb_bank_st_req_opcode[0+:rvh_l1d_pkg_STU_OP_WIDTH] = stb_l1d_arb_st_req_opcode;
		l1d_arb_bank_st_req_paddr[0+:rvh_l1d_pkg_PADDR_WIDTH] = stb_l1d_arb_st_req_paddr;
		l1d_arb_bank_st_req_data[0+:512] = stb_l1d_arb_st_req_data;
		l1d_arb_bank_st_req_data_byte_mask[0+:64] = stb_l1d_arb_st_req_data_byte_mask;
		l1d_arb_bank_st_req_sc_rt_check_succ[0] = stb_l1d_arb_st_req_sc_rt_check_succ;
		l1d_arb_bank_st_req_sc_amo_offset[0+:6] = stb_l1d_arb_st_req_amo_offset;
		stb_l1d_arb_st_req_rdy = l1d_arb_bank_st_req_rdy[0];
	end
	always @(*) begin
		l1d_arb_bank_ptw_walk_req_vld = 1'sb0;
		ptw_walk_req_rdy_unmasked = 1'sb1;
		ptw_replay_bank_ptw_walk_req_rdy = 1'sb1;
		l1d_arb_bank_ptw_walk_req_id = 1'sb0;
		l1d_arb_bank_ptw_walk_req_paddr = 1'sb0;
		if (ptw_replay_bank_ptw_walk_req_vld) begin
			l1d_arb_bank_ptw_walk_req_vld[0] = 1'b1;
			l1d_arb_bank_ptw_walk_req_id[0+:rvh_l1d_pkg_PTW_ID_WIDTH] = ptw_replay_bank_ptw_walk_req_id;
			l1d_arb_bank_ptw_walk_req_paddr[0+:rvh_l1d_pkg_PADDR_WIDTH] = ptw_replay_bank_ptw_walk_req_paddr;
			ptw_walk_req_rdy_unmasked = 1'b0;
			ptw_replay_bank_ptw_walk_req_rdy = l1d_arb_stb_ptw_walk_req_rdy & l1d_arb_bank_ptw_walk_req_rdy[0];
		end
		else begin
			l1d_arb_bank_ptw_walk_req_vld[0] = ptw_walk_req_vld_masked;
			l1d_arb_bank_ptw_walk_req_id[0+:rvh_l1d_pkg_PTW_ID_WIDTH] = ptw_walk_req_id_i;
			l1d_arb_bank_ptw_walk_req_paddr[0+:rvh_l1d_pkg_PADDR_WIDTH] = ptw_walk_req_addr_i;
			ptw_walk_req_rdy_unmasked = l1d_arb_stb_ptw_walk_req_rdy & l1d_arb_bank_ptw_walk_req_rdy[0];
			ptw_replay_bank_ptw_walk_req_rdy = 1'b0;
		end
	end
	always @(*) begin
		ptw_walk_resp_vld_o = 1'sb0;
		ptw_walk_resp_id_o = 1'sb0;
		ptw_walk_resp_pte_o = 1'sb0;
		if (band_l1d_arb_ptw_walk_resp_vld[0] == 1'b1) begin
			ptw_walk_resp_vld_o = 1'b1;
			ptw_walk_resp_id_o = band_l1d_arb_ptw_walk_resp_id[0+:rvh_l1d_pkg_PTW_ID_WIDTH];
			ptw_walk_resp_pte_o = band_l1d_arb_ptw_walk_resp_pte[0+:64];
		end
	end
	wire [1:0] ls_pipe_l1d_ld_req_hit_bank_id;
	assign ls_pipe_l1d_ld_req_hit_bank_id = 2'b00;
	wire [0:0] l1d_bank_l1d_wb_vld_from_cache_hit;
	wire [1:0] l1d_wb_from_cache_hit_port_id;
	wire [1:0] l1d_wb_from_cache_hit_port_id_vld;
	wire [0:0] l1d_wb_from_mlfb_port_id;
	wire l1d_wb_from_mlfb_port_id_vld;
	wire [1:0] l1d_int_prf_wb_vld_from_cache_hit_selected;
	wire l1d_int_prf_wb_vld_from_mlfb_selected;
	wire l1d_wb_port_full_from_cache_hit;
	assign l1d_bank_l1d_wb_vld_from_cache_hit = l1d_bank_l1d_wb_vld & ~l1d_bank_l1d_wb_vld_from_mlfb;
	select_two_from_n_valid #(.SEL_WIDTH(rvh_l1d_pkg_L1D_BANK_ID_NUM)) get_wb_bank_id_u(
		.sel_i(l1d_bank_l1d_wb_vld_from_cache_hit),
		.first_id_needed_vld_i(1'b1),
		.second_id_needed_vld_i(1'b1),
		.first_id_vld_o(l1d_wb_from_cache_hit_port_id_vld[0]),
		.second_id_vld_o(l1d_wb_from_cache_hit_port_id_vld[1]),
		.first_id_o(l1d_wb_from_cache_hit_port_id[0+:1]),
		.second_id_o(l1d_wb_from_cache_hit_port_id[1+:1])
	);
	priority_encoder #(.SEL_WIDTH(rvh_l1d_pkg_L1D_BANK_ID_NUM)) mlfb_wb_vld_sel(
		.sel_i(l1d_bank_l1d_wb_vld_from_mlfb),
		.id_vld_o(l1d_wb_from_mlfb_port_id_vld),
		.id_o(l1d_wb_from_mlfb_port_id)
	);
	assign l1d_int_prf_wb_vld_from_cache_hit_selected[0] = l1d_wb_from_cache_hit_port_id_vld[0];
	assign l1d_int_prf_wb_vld_from_cache_hit_selected[1] = l1d_wb_from_cache_hit_port_id_vld[1];
	assign l1d_int_prf_wb_vld_from_mlfb_selected = l1d_wb_from_mlfb_port_id_vld & ~(&l1d_int_prf_wb_vld_from_cache_hit_selected);
	assign l1d_int_prf_wb_vld_o[0] = l1d_int_prf_wb_vld_from_cache_hit_selected[0] | l1d_int_prf_wb_vld_from_mlfb_selected;
	assign l1d_int_prf_wb_vld_o[1] = l1d_int_prf_wb_vld_from_cache_hit_selected[1] | (l1d_int_prf_wb_vld_from_cache_hit_selected[0] & l1d_int_prf_wb_vld_from_mlfb_selected);
	assign l1d_int_prf_wb_tag_o[0+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH] = (l1d_int_prf_wb_vld_from_cache_hit_selected[0] ? l1d_bank_l1d_wb_tag[l1d_wb_from_cache_hit_port_id[0+:1] * rvh_l1d_pkg_INT_PREG_TAG_WIDTH+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH] : l1d_bank_l1d_wb_tag[l1d_wb_from_mlfb_port_id * rvh_l1d_pkg_INT_PREG_TAG_WIDTH+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH]);
	assign l1d_int_prf_wb_tag_o[rvh_l1d_pkg_INT_PREG_TAG_WIDTH+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH] = (l1d_int_prf_wb_vld_from_cache_hit_selected[1] ? l1d_bank_l1d_wb_tag[l1d_wb_from_cache_hit_port_id[1+:1] * rvh_l1d_pkg_INT_PREG_TAG_WIDTH+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH] : l1d_bank_l1d_wb_tag[l1d_wb_from_mlfb_port_id * rvh_l1d_pkg_INT_PREG_TAG_WIDTH+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH]);
	assign l1d_int_prf_wb_data_o[0+:rvh_l1d_pkg_XLEN] = (l1d_int_prf_wb_vld_from_cache_hit_selected[0] ? l1d_bank_l1d_wb_data[l1d_wb_from_cache_hit_port_id[0+:1] * rvh_l1d_pkg_XLEN+:rvh_l1d_pkg_XLEN] : l1d_bank_l1d_wb_data[l1d_wb_from_mlfb_port_id * rvh_l1d_pkg_XLEN+:rvh_l1d_pkg_XLEN]);
	assign l1d_int_prf_wb_data_o[rvh_l1d_pkg_XLEN+:rvh_l1d_pkg_XLEN] = (l1d_int_prf_wb_vld_from_cache_hit_selected[1] ? l1d_bank_l1d_wb_data[l1d_wb_from_cache_hit_port_id[1+:1] * rvh_l1d_pkg_XLEN+:rvh_l1d_pkg_XLEN] : l1d_bank_l1d_wb_data[l1d_wb_from_mlfb_port_id * rvh_l1d_pkg_XLEN+:rvh_l1d_pkg_XLEN]);
	generate
		for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1) begin : genblk5
			assign l1d_rob_wb_vld_o[i] = l1d_int_prf_wb_vld_o[i];
			assign l1d_rob_wb_rob_tag_o[i * rvh_l1d_pkg_ROB_TAG_WIDTH+:rvh_l1d_pkg_ROB_TAG_WIDTH] = (l1d_int_prf_wb_vld_from_cache_hit_selected[i] ? l1d_rob_wb_rob_tag[l1d_wb_from_cache_hit_port_id[i+:1] * rvh_l1d_pkg_ROB_TAG_WIDTH+:rvh_l1d_pkg_ROB_TAG_WIDTH] : l1d_rob_wb_rob_tag[l1d_wb_from_mlfb_port_id * rvh_l1d_pkg_ROB_TAG_WIDTH+:rvh_l1d_pkg_ROB_TAG_WIDTH]);
		end
		for (i = rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i < (rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT + rvh_l1d_pkg_LSU_DATA_PIPE_COUNT); i = i + 1) begin : genblk6
			assign l1d_rob_wb_vld_o[i] = ((ls_pipe_l1d_st_req_vld_masked[i - rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT] & ls_pipe_l1d_st_req_rdy_unmasked[i - rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT]) & ~ls_pipe_l1d_st_req_is_fence_i[i - rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT]) | stb_rob_wb_vld[i];
			assign l1d_rob_wb_rob_tag_o[i * rvh_l1d_pkg_ROB_TAG_WIDTH+:rvh_l1d_pkg_ROB_TAG_WIDTH] = (stb_rob_wb_vld[i] ? stb_rob_wb_rob_tag[i * rvh_l1d_pkg_ROB_TAG_WIDTH+:rvh_l1d_pkg_ROB_TAG_WIDTH] : ls_pipe_l1d_st_req_rob_tag_i[(i - rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT) * rvh_l1d_pkg_ROB_TAG_WIDTH+:rvh_l1d_pkg_ROB_TAG_WIDTH]);
		end
	endgenerate
	assign l1d_wb_port_full_from_cache_hit = &l1d_int_prf_wb_vld_from_cache_hit_selected;
	always @(*) l1d_bank_l1d_wb_rdy_from_mlfb[0] = ~l1d_wb_port_full_from_cache_hit;
	wire [1:0] stb_l1d_ld_replay_vld;
	wire stb_l1d_ptw_replay_vld;
	wire [1:0] s1_ld_bank_id;
	wire [1:0] s2_ld_bank_id;
	reg [1:0] l1d_ls_pipe_ld_replay_valid_mid;
	always @(*) begin
		l1d_ls_pipe_ld_replay_valid_mid = 1'sb0;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1)
				if (s2_ld_bank_id[i+:1] == 0)
					l1d_ls_pipe_ld_replay_valid_mid[i] = bank_l1d_replay_vld[0];
		end
	end
	assign l1d_ls_pipe_ld_replay_valid_o = l1d_ls_pipe_ld_replay_valid_mid | stb_l1d_ld_replay_vld;
	wire [1:0] lsu_pipe_ld_req_hsk;
	reg [1:0] l1d_arb_bank_ld_kill_resp_mid;
	wire [0:0] l1d_arb_bank_ld_kill_resp;
	generate
		for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1) begin : gen_stage_ld_bank_id
			assign lsu_pipe_ld_req_hsk[i] = ls_pipe_l1d_ld_req_vld_masked[i] & ls_pipe_l1d_bank_ld_req_rdy[i];
			std_dffre #(.WIDTH(1)) U_IN_PIPE_BANK_ID_S1(
				.clk(clk),
				.rstn(rst),
				.en(lsu_pipe_ld_req_hsk[i]),
				.d(ls_pipe_l1d_ld_req_hit_bank_id[i+:1]),
				.q(s1_ld_bank_id[i+:1])
			);
			std_dffr #(.WIDTH(1)) U_IN_PIPE_BANK_ID_S2(
				.clk(clk),
				.rstn(rst),
				.d(s1_ld_bank_id[i+:1]),
				.q(s2_ld_bank_id[i+:1])
			);
		end
	endgenerate
	always @(*) begin : comb_l1d_arb_bank_ld_kill_resp_mid
		l1d_arb_bank_ld_kill_resp_mid = 1'sb0;
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT; i = i + 1)
				if (s2_ld_bank_id[i+:1] == 0)
					l1d_arb_bank_ld_kill_resp_mid[0 + i] = ls_pipe_l1d_kill_resp_i[i] | stb_l1d_ld_replay_vld[i];
		end
	end
	assign l1d_arb_bank_ld_kill_resp[0] = |l1d_arb_bank_ld_kill_resp_mid[0+:rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT];
	wire [1:0] amo_ctrl_stb_st_req_vld;
	wire [1:0] amo_ctrl_stb_st_req_is_fence;
	wire amo_ctrl_stb_st_req_no_fence_wb_resp;
	wire amo_ctrl_stb_st_req_sc_rt_check_succ;
	wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_ROB_TAG_WIDTH) - 1:0] amo_ctrl_stb_st_req_rob_tag;
	wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_PREG_TAG_WIDTH) - 1:0] amo_ctrl_stb_st_req_prd;
	wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_STU_OP_WIDTH) - 1:0] amo_ctrl_stb_st_req_opcode;
	wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_PADDR_WIDTH) - 1:0] amo_ctrl_stb_st_req_paddr;
	wire [(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT * rvh_l1d_pkg_XLEN) - 1:0] amo_ctrl_stb_st_req_data;
	wire [1:0] amo_ctrl_stb_st_req_rdy;
	rvh_l1d_amo_ctrl #(.N_STB_ST_IN_PORT(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT)) AMO_CTRL_U(
		.ls_pipe_amo_ctrl_st_req_vld_i(ls_pipe_l1d_st_req_vld_masked),
		.ls_pipe_amo_ctrl_st_req_is_fence_i(ls_pipe_l1d_st_req_is_fence_i),
		.ls_pipe_amo_ctrl_st_req_rob_tag_i(ls_pipe_l1d_st_req_rob_tag_i),
		.ls_pipe_amo_ctrl_st_req_prd_i(ls_pipe_l1d_st_req_prd_i),
		.ls_pipe_amo_ctrl_st_req_opcode_i(ls_pipe_l1d_st_req_opcode_i),
		.ls_pipe_amo_ctrl_st_req_paddr_i(ls_pipe_l1d_st_req_paddr_i),
		.ls_pipe_amo_ctrl_st_req_data_i(ls_pipe_l1d_st_req_data_i),
		.ls_pipe_amo_ctrl_st_req_rdy_o(ls_pipe_l1d_st_req_rdy_unmasked),
		.amo_ctrl_stb_st_req_vld_o(amo_ctrl_stb_st_req_vld),
		.amo_ctrl_stb_st_req_is_fence_o(amo_ctrl_stb_st_req_is_fence),
		.amo_ctrl_stb_st_req_no_fence_wb_resp_o(amo_ctrl_stb_st_req_no_fence_wb_resp),
		.amo_ctrl_stb_st_req_sc_rt_check_succ_o(amo_ctrl_stb_st_req_sc_rt_check_succ),
		.amo_ctrl_stb_st_req_rob_tag_o(amo_ctrl_stb_st_req_rob_tag),
		.amo_ctrl_stb_st_req_prd_o(amo_ctrl_stb_st_req_prd),
		.amo_ctrl_stb_st_req_opcode_o(amo_ctrl_stb_st_req_opcode),
		.amo_ctrl_stb_st_req_paddr_o(amo_ctrl_stb_st_req_paddr),
		.amo_ctrl_stb_st_req_data_o(amo_ctrl_stb_st_req_data),
		.amo_ctrl_stb_st_req_rdy_i(amo_ctrl_stb_st_req_rdy),
		.l1d_rob_wb_vld_i(l1d_rob_wb_vld_o),
		.l1d_rob_wb_rob_tag_i(l1d_rob_wb_rob_tag_o),
		.in_amo_state_o(in_amo_state),
		.clk(clk),
		.rst(rst)
	);
	localparam rvh_l1d_pkg_L1D_STB_ENTRY_NUM = 8;
	rvh_l1d_stb #(
		.N_STB(rvh_l1d_pkg_L1D_STB_ENTRY_NUM),
		.N_STB_ST_IN_PORT(rvh_l1d_pkg_LSU_DATA_PIPE_COUNT),
		.N_STB_LD_IN_PORT(rvh_l1d_pkg_LSU_ADDR_PIPE_COUNT)
	) STB_U(
		.ls_pipe_stb_st_req_vld_i(amo_ctrl_stb_st_req_vld),
		.ls_pipe_l1d_st_req_is_fence_i(amo_ctrl_stb_st_req_is_fence),
		.ls_pipe_l1d_st_req_no_fence_wb_resp_i(amo_ctrl_stb_st_req_no_fence_wb_resp),
		.ls_pipe_l1d_st_req_sc_rt_check_succ_i(amo_ctrl_stb_st_req_sc_rt_check_succ),
		.ls_pipe_stb_st_req_rob_tag_i(amo_ctrl_stb_st_req_rob_tag),
		.ls_pipe_stb_st_req_prd_i(amo_ctrl_stb_st_req_prd),
		.ls_pipe_stb_st_req_opcode_i(amo_ctrl_stb_st_req_opcode),
		.ls_pipe_stb_st_req_paddr_i(amo_ctrl_stb_st_req_paddr),
		.ls_pipe_stb_st_req_data_i(amo_ctrl_stb_st_req_data),
		.ls_pipe_stb_st_req_rdy_o(amo_ctrl_stb_st_req_rdy),
		.ls_pipe_stb_ld_req_vld_i(ls_pipe_l1d_ld_req_vld_masked & ls_pipe_l1d_bank_ld_req_rdy),
		.ls_pipe_stb_ld_req_rob_tag_i(ls_pipe_l1d_ld_req_rob_tag_i),
		.ls_pipe_stb_ld_req_prd_i(ls_pipe_l1d_ld_req_prd_i),
		.ls_pipe_stb_ld_req_opcode_i(ls_pipe_l1d_ld_req_opcode_i),
		.ls_pipe_stb_ld_req_idx_i(ls_pipe_l1d_ld_req_index_i),
		.ls_pipe_stb_ld_req_offset_i(ls_pipe_l1d_ld_req_offset_i),
		.ls_pipe_stb_ld_req_vtag_i(ls_pipe_l1d_ld_req_vtag_i),
		.l1d_stb_st_req_rdy_i(ls_pipe_l1d_ld_req_rdy_unmasked),
		.ls_pipe_stb_ld_req_rdy_o(ls_pipe_stb_ld_req_rdy),
		.kill_ld_req_i(rob_flush_i),
		.ls_pipe_stb_dtlb_resp_vld_i(ls_pipe_l1d_dtlb_resp_vld_i),
		.ls_pipe_stb_dtlb_resp_ppn_i(ls_pipe_l1d_dtlb_resp_ppn_i),
		.ls_pipe_stb_dtlb_resp_excp_vld_i(ls_pipe_l1d_dtlb_resp_excp_vld_i),
		.ls_pipe_stb_dtlb_resp_hit_i(ls_pipe_l1d_dtlb_resp_hit_i),
		.ls_pipe_stb_dtlb_resp_miss_i(ls_pipe_l1d_dtlb_resp_miss_i),
		.stb_rob_wb_vld_o(stb_rob_wb_vld),
		.stb_rob_wb_rob_tag_o(stb_rob_wb_rob_tag),
		.stb_int_prf_wb_vld_o(stb_int_prf_wb_vld),
		.stb_int_prf_wb_tag_o(stb_int_prf_wb_tag),
		.stb_int_prf_wb_data_o(stb_int_prf_wb_data),
		.stb_l1d_arb_bank_id_o(stb_l1d_arb_bank_id),
		.stb_l1d_st_req_vld_o(stb_l1d_arb_st_req_vld),
		.stb_l1d_st_req_rob_tag_o(stb_l1d_arb_st_req_rob_tag),
		.stb_l1d_st_req_prd_o(stb_l1d_arb_st_req_prd),
		.stb_l1d_st_req_opcode_o(stb_l1d_arb_st_req_opcode),
		.stb_l1d_st_req_paddr_o(stb_l1d_arb_st_req_paddr),
		.stb_l1d_st_req_data_o(stb_l1d_arb_st_req_data),
		.stb_l1d_st_req_data_byte_mask_o(stb_l1d_arb_st_req_data_byte_mask),
		.stb_l1d_st_req_sc_rt_check_succ_o(stb_l1d_arb_st_req_sc_rt_check_succ),
		.stb_l1d_st_req_amo_offset_o(stb_l1d_arb_st_req_amo_offset),
		.stb_l1d_st_req_rdy_i(stb_l1d_arb_st_req_rdy),
		.ptw_walk_req_vld_i(ptw_walk_req_vld_masked),
		.ptw_walk_req_id_i(ptw_walk_req_id_i),
		.ptw_walk_req_addr_i(ptw_walk_req_addr_i),
		.ptw_walk_l1d_req_rdy_i(ptw_walk_req_rdy_unmasked),
		.ptw_walk_req_rdy_o(l1d_arb_stb_ptw_walk_req_rdy),
		.stb_l1d_ld_partial_hit_replay_o(stb_l1d_ld_replay_vld),
		.stb_l1d_ptw_partial_hit_replay_o(stb_l1d_ptw_replay_vld),
		.fencei_flush_vld_i(fencei_flush_stb_vld),
		.fencei_flush_rdy_o(fencei_flush_stb_rdy),
		.fencei_flush_done_o(fencei_flush_stb_done),
		.clk(clk),
		.rst(rst)
	);
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s0_req_vld_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s0_req_hsk_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s1_req_vld_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s1_req_hsk_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_vld_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_hsk_i_0 = 1'sb0;
	localparam [1:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_new_line_state_i_0 = 1'sb0;
	localparam [1:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_way_id_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s3_req_vld_i_0 = 1'sb0;
	localparam [1:0] sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s3_tag_compare_match_id_i_0 = 1'sb0;
	rvh_l1d_bank #(.BANK_ID(0)) L1D_CACHE_BANK_U(
		.ls_pipe_l1d_ld_req_vld_i(ls_pipe_l1d_ld_req_vld_i[0]),
		.ls_pipe_l1d_ld_req_rob_tag_i(ls_pipe_l1d_ld_req_rob_tag_i[0+:rvh_l1d_pkg_ROB_TAG_WIDTH]),
		.ls_pipe_l1d_ld_req_prd_i(ls_pipe_l1d_ld_req_prd_i[0+:rvh_l1d_pkg_PREG_TAG_WIDTH]),
		.ls_pipe_l1d_ld_req_opcode_i(ls_pipe_l1d_ld_req_opcode_i[0+:rvh_l1d_pkg_LDU_OP_WIDTH]),
		.ls_pipe_l1d_ld_req_idx_i(ls_pipe_l1d_ld_req_index_i[0+:1]),
		.ls_pipe_l1d_ld_req_offset_i(ls_pipe_l1d_ld_req_offset_i[0+:6]),
		.ls_pipe_l1d_ld_req_vtag_i(ls_pipe_l1d_ld_req_vtag_i[0+:49]),
		.stb_l1d_ld_rdy_i(ls_pipe_stb_ld_req_rdy),
		.ls_pipe_l1d_ld_req_rdy_o(ls_pipe_l1d_bank_ld_req_rdy[0]),
		.ls_pipe_l1d_ld_kill_i(1'b0),
		.ls_pipe_l1d_ld_rar_fail_i(1'b0),
		.ls_pipe_l1d_st_req_vld_i(l1d_arb_bank_st_req_vld[0]),
		.ls_pipe_l1d_st_req_io_region_i(l1d_arb_bank_st_req_io_region[0]),
		.ls_pipe_l1d_st_req_rob_tag_i(l1d_arb_bank_st_req_rob_tag[0+:rvh_l1d_pkg_ROB_TAG_WIDTH]),
		.ls_pipe_l1d_st_req_prd_i(l1d_arb_bank_st_req_prd[0+:rvh_l1d_pkg_PREG_TAG_WIDTH]),
		.ls_pipe_l1d_st_req_opcode_i(l1d_arb_bank_st_req_opcode[0+:rvh_l1d_pkg_STU_OP_WIDTH]),
		.ls_pipe_l1d_st_req_paddr_i(l1d_arb_bank_st_req_paddr[0+:rvh_l1d_pkg_PADDR_WIDTH]),
		.ls_pipe_l1d_st_req_data_i(l1d_arb_bank_st_req_data[0+:512]),
		.ls_pipe_l1d_st_req_data_byte_mask_i(l1d_arb_bank_st_req_data_byte_mask[0+:64]),
		.ls_pipe_l1d_st_req_sc_rt_check_succ_i(l1d_arb_bank_st_req_sc_rt_check_succ[0]),
		.ls_pipe_l1d_st_req_sc_amo_offset_i(l1d_arb_bank_st_req_sc_amo_offset[0+:6]),
		.ls_pipe_l1d_st_req_rdy_o(l1d_arb_bank_st_req_rdy[0]),
		.ls_pipe_l1d_ld_raw_fail_i(1'b0),
		.dtlb_l1d_resp_vld_i(ls_pipe_l1d_dtlb_resp_vld_i),
		.dtlb_l1d_resp_excp_vld_i(ls_pipe_l1d_dtlb_resp_excp_vld_i),
		.dtlb_l1d_resp_hit_i(ls_pipe_l1d_dtlb_resp_hit_i),
		.dtlb_l1d_resp_ppn_i(ls_pipe_l1d_dtlb_resp_ppn_i),
		.stb_l1d_bank_ld_bypass_valid_i(stb_l1d_bank_ld_bypass_valid[0]),
		.stb_l1d_bank_ld_bypass_data_i(stb_l1d_bank_ld_bypass_data[0+:rvh_l1d_pkg_XLEN]),
		.lsu_l1d_s2_kill_valid_i(l1d_arb_bank_ld_kill_resp[0]),
		.l1d_ls_pipe_replay_vld_o(bank_l1d_replay_vld[0]),
		.l1d_ls_pipe_mshr_full_o(bank_l1d_mshr_full[0]),
		.l1d_rob_wb_vld_o(l1d_rob_wb_vld[0]),
		.l1d_rob_wb_rob_tag_o(l1d_rob_wb_rob_tag[0+:rvh_l1d_pkg_ROB_TAG_WIDTH]),
		.l1d_int_prf_wb_vld_o(l1d_bank_l1d_wb_vld[0]),
		.l1d_int_prf_wb_tag_o(l1d_bank_l1d_wb_tag[0+:rvh_l1d_pkg_INT_PREG_TAG_WIDTH]),
		.l1d_int_prf_wb_data_o(l1d_bank_l1d_wb_data[0+:rvh_l1d_pkg_XLEN]),
		.l1d_int_prf_wb_vld_from_mlfb_o(l1d_bank_l1d_wb_vld_from_mlfb[0]),
		.l1d_int_prf_wb_rdy_from_mlfb_i(l1d_bank_l1d_wb_rdy_from_mlfb[0]),
		.ptw_walk_req_vld_i(l1d_arb_bank_ptw_walk_req_vld[0]),
		.ptw_walk_req_id_i(l1d_arb_bank_ptw_walk_req_id[0+:rvh_l1d_pkg_PTW_ID_WIDTH]),
		.ptw_walk_req_addr_i(l1d_arb_bank_ptw_walk_req_paddr[0+:rvh_l1d_pkg_PADDR_WIDTH]),
		.stb_l1d_ptw_walk_req_rdy_i(l1d_arb_stb_ptw_walk_req_rdy),
		.ptw_walk_req_rdy_o(l1d_arb_bank_ptw_walk_req_rdy[0]),
		.ptw_walk_resp_vld_o(band_l1d_arb_ptw_walk_resp_vld[0]),
		.ptw_walk_resp_id_o(band_l1d_arb_ptw_walk_resp_id[0+:rvh_l1d_pkg_PTW_ID_WIDTH]),
		.ptw_walk_resp_pte_o(band_l1d_arb_ptw_walk_resp_pte[0+:64]),
		.ptw_walk_resp_rdy_i(ptw_walk_resp_rdy_i),
		.snp_l1d_bank_snp_s0_req_vld_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s0_req_vld_i_0),
		.snp_l1d_bank_snp_s0_req_hsk_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s0_req_hsk_i_0),
		.snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_i_0),
		.snp_l1d_bank_snp_s1_req_vld_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s1_req_vld_i_0),
		.snp_l1d_bank_snp_s1_req_hsk_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s1_req_hsk_i_0),
		.snp_l1d_bank_snp_s2_req_vld_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_vld_i_0),
		.snp_l1d_bank_snp_s2_req_hsk_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_hsk_i_0),
		.snp_l1d_bank_snp_s2_req_new_line_state_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_new_line_state_i_0),
		.snp_l1d_bank_snp_s2_req_way_id_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_way_id_i_0),
		.snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s2_req_data_ram_rd_vld_i_0),
		.snp_l1d_bank_snp_s3_req_vld_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s3_req_vld_i_0),
		.snp_l1d_bank_snp_s3_tag_compare_match_id_i(sv2v_uu_L1D_CACHE_BANK_U_ext_snp_l1d_bank_snp_s3_tag_compare_match_id_i_0),
		.l2_req_if_arvalid(l1d_l2_req_arvalid_o),
		.l2_req_if_arready(l1d_l2_req_arready_i),
		.l2_req_if_ar(l1d_l2_req_ar_o),
		.l2_req_if_awvalid(l1d_l2_req_awvalid_o),
		.l2_req_if_awready(l1d_l2_req_awready_i),
		.l2_req_if_aw(l1d_l2_req_aw_o),
		.l2_req_if_wvalid(l1d_l2_req_wvalid_o),
		.l2_req_if_wready(l1d_l2_req_wready_i),
		.l2_req_if_w(l1d_l2_req_w_o),
		.l2_resp_if_bvalid(l2_l1d_resp_bvalid_i),
		.l2_resp_if_bready(l2_l1d_resp_bready_o),
		.l2_resp_if_b(l2_l1d_resp_b_i),
		.l2_resp_if_rvalid(l2_l1d_resp_rvalid_i),
		.l2_resp_if_rready(l2_l1d_resp_rready_o),
		.l2_resp_if_r(l2_l1d_resp_r_i),
		.rob_flush_i(rob_flush_i),
		.fencei_flush_vld_i(fencei_flush_bank_vld),
		.fencei_flush_grant_o(fencei_flush_grant_per_bank_out[0]),
		.clk(clk),
		.rst(rst)
	);
	rvh_l1d_ptw_replay_buffer #(.REPLAY_LATENCY(4)) L1D_PTW_REPLAY_BUFFER_U(
		.ptw_walk_req_vld_i(ptw_walk_req_vld_masked),
		.ptw_walk_req_id_i(ptw_walk_req_id_i),
		.ptw_walk_req_addr_i(ptw_walk_req_addr_i),
		.ptw_walk_resp_vld_i(ptw_walk_resp_vld_o),
		.ptw_walk_resp_rdy_i(ptw_walk_resp_rdy_i),
		.stb_l1d_ptw_replay_vld_i(stb_l1d_ptw_replay_vld),
		.ptw_walk_replay_req_vld_o(ptw_replay_bank_ptw_walk_req_vld),
		.ptw_walk_replay_req_id_o(ptw_replay_bank_ptw_walk_req_id),
		.ptw_walk_replay_req_paddr_o(ptw_replay_bank_ptw_walk_req_paddr),
		.ptw_walk_replay_req_rdy_i(ptw_replay_bank_ptw_walk_req_rdy),
		.clk(clk),
		.rst(rst)
	);
endmodule
