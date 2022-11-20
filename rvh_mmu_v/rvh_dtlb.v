module rvh_dtlb (
	priv_lvl_i,
	mstatus_mprv,
	mstatus_mpp,
	mstatus_mxr,
	mstatus_sum,
	satp_mode_i,
	satp_asid_i,
	translate_req_vld_i,
	translate_req_access_type_i,
	translate_req_vpn_i,
	translate_req_rdy_o,
	translate_resp_vld_o,
	translate_resp_ppn_o,
	translate_resp_excp_vld_o,
	translate_resp_excp_cause_o,
	translate_resp_miss_o,
	translate_resp_hit_o,
	next_lvl_req_vld_o,
	next_lvl_req_trans_id_o,
	next_lvl_req_asid_o,
	next_lvl_req_vpn_o,
	next_lvl_req_access_type_o,
	next_lvl_req_rdy_i,
	next_lvl_resp_vld_i,
	next_lvl_resp_trans_id_i,
	next_lvl_resp_asid_i,
	next_lvl_resp_pte_i,
	next_lvl_resp_page_lvl_i,
	next_lvl_resp_vpn_i,
	next_lvl_resp_access_type_i,
	next_lvl_resp_access_fault_i,
	next_lvl_resp_page_fault_i,
	tlb_flush_vld_i,
	tlb_flush_use_asid_i,
	tlb_flush_use_vpn_i,
	tlb_flush_vpn_i,
	tlb_flush_asid_i,
	tlb_flush_grant_o,
	clk,
	rstn
);
	parameter TRANSLATE_WIDTH = 1;
	parameter ENTRY_COUNT = 32;
	parameter MSHR_COUNT = 4;
	parameter TRANS_ID_WIDTH = 3;
	parameter PADDR_WIDTH = 56;
	parameter EXCP_CAUSE_WIDTH = 64;
	parameter VPN_WIDTH = 27;
	parameter ASID_WIDTH = 16;
	localparam PTE_WIDTH = 64;
	localparam PAGE_LVL_WIDTH = $clog2(VPN_WIDTH / 9);
	localparam PPN_WIDTH = PADDR_WIDTH - 12;
	localparam MODE_WIDTH = 4;
	input [1:0] priv_lvl_i;
	input mstatus_mprv;
	input [1:0] mstatus_mpp;
	input mstatus_mxr;
	input mstatus_sum;
	input [3:0] satp_mode_i;
	input [ASID_WIDTH - 1:0] satp_asid_i;
	input [TRANSLATE_WIDTH - 1:0] translate_req_vld_i;
	input [(TRANSLATE_WIDTH * 2) - 1:0] translate_req_access_type_i;
	input [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] translate_req_vpn_i;
	output [TRANSLATE_WIDTH - 1:0] translate_req_rdy_o;
	output [TRANSLATE_WIDTH - 1:0] translate_resp_vld_o;
	output [(TRANSLATE_WIDTH * PPN_WIDTH) - 1:0] translate_resp_ppn_o;
	output [TRANSLATE_WIDTH - 1:0] translate_resp_excp_vld_o;
	output [(TRANSLATE_WIDTH * EXCP_CAUSE_WIDTH) - 1:0] translate_resp_excp_cause_o;
	output [TRANSLATE_WIDTH - 1:0] translate_resp_miss_o;
	output [TRANSLATE_WIDTH - 1:0] translate_resp_hit_o;
	output next_lvl_req_vld_o;
	output [TRANS_ID_WIDTH - 1:0] next_lvl_req_trans_id_o;
	output [ASID_WIDTH - 1:0] next_lvl_req_asid_o;
	output [VPN_WIDTH - 1:0] next_lvl_req_vpn_o;
	output [1:0] next_lvl_req_access_type_o;
	input next_lvl_req_rdy_i;
	input next_lvl_resp_vld_i;
	input [TRANS_ID_WIDTH - 1:0] next_lvl_resp_trans_id_i;
	input [ASID_WIDTH - 1:0] next_lvl_resp_asid_i;
	input [63:0] next_lvl_resp_pte_i;
	input [PAGE_LVL_WIDTH - 1:0] next_lvl_resp_page_lvl_i;
	input [VPN_WIDTH - 1:0] next_lvl_resp_vpn_i;
	input [1:0] next_lvl_resp_access_type_i;
	input next_lvl_resp_access_fault_i;
	input next_lvl_resp_page_fault_i;
	input tlb_flush_vld_i;
	input tlb_flush_use_asid_i;
	input tlb_flush_use_vpn_i;
	input [VPN_WIDTH - 1:0] tlb_flush_vpn_i;
	input [ASID_WIDTH - 1:0] tlb_flush_asid_i;
	output reg tlb_flush_grant_o;
	input clk;
	input rstn;
	genvar lane;
	genvar macro;
	localparam HIGHEST_PAGE_LVL = VPN_WIDTH / 9;
	localparam MODE_BARE = 0;
	localparam MODE_SV39 = 8;
	localparam MODE_SV48 = 9;
	localparam MODE_SV57 = 10;
	localparam SV39_LEVELS = 3;
	localparam SV48_LEVELS = 4;
	localparam SV57_LEVELS = 5;
	localparam SV39_LEVELS_DIFF = HIGHEST_PAGE_LVL - SV39_LEVELS;
	localparam SV48_LEVELS_DIFF = (HIGHEST_PAGE_LVL >= SV48_LEVELS ? HIGHEST_PAGE_LVL - SV48_LEVELS : 0);
	localparam SV57_LEVELS_DIFF = (HIGHEST_PAGE_LVL >= SV57_LEVELS ? HIGHEST_PAGE_LVL - SV48_LEVELS : 0);
	localparam PRIV_LVL_M = 3;
	localparam PRIV_LVL_S = 1;
	localparam PRIV_LVL_U = 0;
	localparam LD_ACCESS_FAULT = 5;
	localparam ST_ACCESS_FAULT = 7;
	localparam LD_PAGE_FAULT = 13;
	localparam ST_PAGE_FAULT = 15;
	localparam PMP_ACCESS_TYPE_R = 0;
	localparam PMP_ACCESS_TYPE_W = 1;
	localparam PMP_ACCESS_TYPE_X = 2;
	function automatic [VPN_WIDTH - 1:0] gen_page_vpn_mask;
		input [3:0] satp_mode_i;
		input [PAGE_LVL_WIDTH - 1:0] page_lvl_i;
		integer i;
		reg [HIGHEST_PAGE_LVL - 1:0] satp_mode_mask;
		reg [HIGHEST_PAGE_LVL - 1:0] vpn_segment_en_mask;
		begin
			case (satp_mode_i)
				MODE_SV39: satp_mode_mask = {{SV39_LEVELS_DIFF {1'b0}}, {SV39_LEVELS {1'b1}}};
				MODE_SV48: satp_mode_mask = {{SV48_LEVELS_DIFF {1'b0}}, {SV48_LEVELS {1'b1}}};
				MODE_SV57: satp_mode_mask = {{SV57_LEVELS_DIFF {1'b0}}, {SV57_LEVELS {1'b1}}};
				default: satp_mode_mask = {HIGHEST_PAGE_LVL {1'b0}};
			endcase
			vpn_segment_en_mask = ~({{HIGHEST_PAGE_LVL - 1 {1'b0}}, 1'b1} - 1'b1) & satp_mode_mask;
			for (i = 0; i < HIGHEST_PAGE_LVL; i = i + 1)
				gen_page_vpn_mask[i * 9+:9] = {9 {vpn_segment_en_mask[i]}};
		end
	endfunction
	function automatic [PPN_WIDTH - 1:0] gen_page_alignment_mask;
		input [PAGE_LVL_WIDTH - 1:0] page_lvl_i;
		reg [HIGHEST_PAGE_LVL - 1:0] ppn_segment_en_mask;
		reg [PPN_WIDTH - 1:0] mask;
		integer i;
		begin
			mask = {PPN_WIDTH {1'b0}};
			ppn_segment_en_mask = ({{HIGHEST_PAGE_LVL - 1 {1'b0}}, 1'b1} << page_lvl_i) - 1'b1;
			for (i = 0; i < HIGHEST_PAGE_LVL; i = i + 1)
				mask[i * 9+:9] = {9 {ppn_segment_en_mask[i]}};
			gen_page_alignment_mask = mask;
		end
	endfunction
	wire [1:0] effective_priv_lvl;
	wire skip_translation;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_fire;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_payload_clk_en;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_vld_d;
	wire [(TRANSLATE_WIDTH * ASID_WIDTH) - 1:0] translate_req_asid_d;
	wire [TRANSLATE_WIDTH - 1:0] translate_req_is_st_d;
	wire [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] translate_req_vpn_d;
	reg [TRANSLATE_WIDTH - 1:0] translate_req_vld_q;
	reg [(TRANSLATE_WIDTH * ASID_WIDTH) - 1:0] translate_req_asid_q;
	reg [TRANSLATE_WIDTH - 1:0] translate_req_is_st_q;
	reg [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] translate_req_vpn_q;
	wire refill_exception_entry;
	wire dtlb_excp_entry_vld_set;
	wire dtlb_excp_entry_vld_clean;
	wire dtlb_excp_entry_vld_clk_en;
	wire dtlb_excp_entry_payload_clk_en;
	wire [VPN_WIDTH - 1:0] dtlb_excp_entry_vpn_d;
	wire [ASID_WIDTH - 1:0] dtlb_excp_entry_asid_d;
	wire [PAGE_LVL_WIDTH - 1:0] dtlb_excp_entry_page_lvl_d;
	wire dtlb_excp_entry_is_st_d;
	wire dtlb_excp_entry_access_fault_d;
	wire dtlb_excp_entry_page_fault_d;
	wire dtlb_excp_entry_V_d;
	reg [VPN_WIDTH - 1:0] dtlb_excp_entry_vpn_q;
	reg [ASID_WIDTH - 1:0] dtlb_excp_entry_asid_q;
	reg [PAGE_LVL_WIDTH - 1:0] dtlb_excp_entry_page_lvl_q;
	reg dtlb_excp_entry_is_st_q;
	reg dtlb_excp_entry_access_fault_q;
	reg dtlb_excp_entry_page_fault_q;
	reg dtlb_excp_entry_V_q;
	wire refill_entry;
	wire exist_invld_entry;
	wire [ENTRY_COUNT - 1:0] refill_invld_oh_mask;
	wire [ENTRY_COUNT - 1:0] refill_evict_oh_mask;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_vld_clk_en;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_vld_set;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_vld_clean;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_payload_clk_en;
	wire [(ENTRY_COUNT * ASID_WIDTH) - 1:0] dtlb_entry_asid_d;
	wire [(ENTRY_COUNT * VPN_WIDTH) - 1:0] dtlb_entry_vpn_d;
	wire [(ENTRY_COUNT * PAGE_LVL_WIDTH) - 1:0] dtlb_entry_page_lvl_d;
	reg [(ENTRY_COUNT * ASID_WIDTH) - 1:0] dtlb_entry_asid_q;
	reg [(ENTRY_COUNT * VPN_WIDTH) - 1:0] dtlb_entry_vpn_q;
	reg [(ENTRY_COUNT * PAGE_LVL_WIDTH) - 1:0] dtlb_entry_page_lvl_q;
	wire [(ENTRY_COUNT * PPN_WIDTH) - 1:0] dtlb_entry_PPN_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_D_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_A_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_G_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_U_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_X_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_W_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_R_d;
	wire [ENTRY_COUNT - 1:0] dtlb_entry_V_d;
	reg [(ENTRY_COUNT * PPN_WIDTH) - 1:0] dtlb_entry_PPN_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_D_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_A_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_G_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_U_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_X_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_W_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_R_q;
	reg [ENTRY_COUNT - 1:0] dtlb_entry_V_q;
	wire [VPN_WIDTH - 1:0] dtlb_excp_entry_vpn_mask;
	wire [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] dtlb_excp_entry_vpn_equal_bit;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_excp_entry_hit;
	wire [(ENTRY_COUNT * VPN_WIDTH) - 1:0] dtlb_entry_vpn_mask;
	wire [((TRANSLATE_WIDTH * ENTRY_COUNT) * VPN_WIDTH) - 1:0] dtlb_entry_vpn_equal_bit;
	wire [(TRANSLATE_WIDTH * ENTRY_COUNT) - 1:0] dtlb_entry_hit;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit;
	wire [(((PPN_WIDTH + PAGE_LVL_WIDTH) + 6) >= 0 ? (ENTRY_COUNT * ((PPN_WIDTH + PAGE_LVL_WIDTH) + 7)) - 1 : (ENTRY_COUNT * (1 - ((PPN_WIDTH + PAGE_LVL_WIDTH) + 6))) + ((PPN_WIDTH + PAGE_LVL_WIDTH) + 5)):(((PPN_WIDTH + PAGE_LVL_WIDTH) + 6) >= 0 ? 0 : (PPN_WIDTH + PAGE_LVL_WIDTH) + 6)] dtlb_hit_entry_mux_in;
	wire [(TRANSLATE_WIDTH * PAGE_LVL_WIDTH) - 1:0] dtlb_hit_entry_mux_out_page_lvl;
	wire [(TRANSLATE_WIDTH * PPN_WIDTH) - 1:0] dtlb_hit_entry_mux_out_PPN;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_D;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_A;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_G;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_U;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_X;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_W;
	wire [TRANSLATE_WIDTH - 1:0] dtlb_hit_entry_mux_out_R;
	wire [(ENTRY_COUNT * TRANSLATE_WIDTH) - 1:0] dtlb_lane_hit_mask_trans;
	wire [ENTRY_COUNT - 1:0] dtlb_plru_access_mask;
	wire [(TRANSLATE_WIDTH * PPN_WIDTH) - 1:0] pte_superpage_alignment_mask;
	wire [TRANSLATE_WIDTH - 1:0] pte_superpage_alignment_check_fail;
	wire [TRANSLATE_WIDTH - 1:0] pte_access_permission_check_fail;
	wire [TRANSLATE_WIDTH - 1:0] pte_superpage_alignment_check_pass;
	wire [TRANSLATE_WIDTH - 1:0] pte_access_permission_check_pass;
	wire [TRANSLATE_WIDTH - 1:0] pte_check_pass;
	wire [TRANSLATE_WIDTH - 1:0] pte_check_fail;
	wire [TRANSLATE_WIDTH - 1:0] tlb_miss_req_vld;
	wire [(TRANSLATE_WIDTH * 2) - 1:0] tlb_miss_req_access_type;
	wire [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] tlb_miss_req_vpn;
	wire [(TRANSLATE_WIDTH * ASID_WIDTH) - 1:0] tlb_miss_req_asid;
	wire next_lvl_resp_payload_clk_en;
	wire next_lvl_resp_vld_d;
	wire [TRANS_ID_WIDTH - 1:0] next_lvl_resp_trans_id_d;
	wire [ASID_WIDTH - 1:0] next_lvl_resp_asid_d;
	wire [63:0] next_lvl_resp_pte_d;
	wire [PAGE_LVL_WIDTH - 1:0] next_lvl_resp_page_lvl_d;
	wire [VPN_WIDTH - 1:0] next_lvl_resp_vpn_d;
	wire next_lvl_resp_excp_vld_d;
	wire tlb_refill_entry_is_evicted_d;
	wire [ENTRY_COUNT - 1:0] tlb_refill_entry_mask_d;
	reg next_lvl_resp_vld_q;
	reg [TRANS_ID_WIDTH - 1:0] next_lvl_resp_trans_id_q;
	reg [ASID_WIDTH - 1:0] next_lvl_resp_asid_q;
	reg [63:0] next_lvl_resp_pte_q;
	reg [PAGE_LVL_WIDTH - 1:0] next_lvl_resp_page_lvl_q;
	reg [VPN_WIDTH - 1:0] next_lvl_resp_vpn_q;
	reg next_lvl_resp_excp_vld_q;
	reg tlb_refill_entry_is_evicted_q;
	reg [ENTRY_COUNT - 1:0] tlb_refill_entry_mask_q;
	wire [(((((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 6) >= 0 ? (ENTRY_COUNT * ((((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 7)) - 1 : (ENTRY_COUNT * (1 - ((((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 6))) + ((((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 5)):(((((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 6) >= 0 ? 0 : (((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 6)] evict_dtlb_entry_mux_in;
	wire [ASID_WIDTH - 1:0] evict_dtlb_entry_asid;
	wire [VPN_WIDTH - 1:0] evict_dtlb_entry_vpn;
	wire [PAGE_LVL_WIDTH - 1:0] evict_dtlb_entry_page_lvl;
	wire [PPN_WIDTH - 1:0] evict_dtlb_entry_PPN;
	wire evict_dtlb_entry_D;
	wire evict_dtlb_entry_A;
	wire evict_dtlb_entry_G;
	wire evict_dtlb_entry_U;
	wire evict_dtlb_entry_X;
	wire evict_dtlb_entry_W;
	wire evict_dtlb_entry_R;
	assign effective_priv_lvl = (mstatus_mprv ? mstatus_mpp : priv_lvl_i);
	assign skip_translation = (effective_priv_lvl == PRIV_LVL_M) | (satp_mode_i == MODE_BARE);
	generate
		assign dtlb_excp_entry_vpn_mask = gen_page_vpn_mask(satp_mode_i, dtlb_excp_entry_page_lvl_q);
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_dtlb_entry_vpn_mask
			assign dtlb_entry_vpn_mask[macro * VPN_WIDTH+:VPN_WIDTH] = gen_page_vpn_mask(satp_mode_i, dtlb_entry_page_lvl_q[macro * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH]);
		end
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_dtlb_hit_entry_mux_in
			assign dtlb_hit_entry_mux_in[(((PPN_WIDTH + PAGE_LVL_WIDTH) + 6) >= 0 ? 0 : (PPN_WIDTH + PAGE_LVL_WIDTH) + 6) + (macro * (((PPN_WIDTH + PAGE_LVL_WIDTH) + 6) >= 0 ? (PPN_WIDTH + PAGE_LVL_WIDTH) + 7 : 1 - ((PPN_WIDTH + PAGE_LVL_WIDTH) + 6)))+:(((PPN_WIDTH + PAGE_LVL_WIDTH) + 6) >= 0 ? (PPN_WIDTH + PAGE_LVL_WIDTH) + 7 : 1 - ((PPN_WIDTH + PAGE_LVL_WIDTH) + 6))] = {dtlb_entry_page_lvl_q[macro * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH], dtlb_entry_PPN_q[macro * PPN_WIDTH+:PPN_WIDTH], dtlb_entry_D_q[macro], dtlb_entry_A_q[macro], dtlb_entry_G_q[macro], dtlb_entry_U_q[macro], dtlb_entry_X_q[macro], dtlb_entry_W_q[macro], dtlb_entry_R_q[macro]};
		end
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_plru_access_mask
			assign dtlb_plru_access_mask[macro] = |dtlb_lane_hit_mask_trans[macro * TRANSLATE_WIDTH+:TRANSLATE_WIDTH];
		end
		for (lane = 0; lane < TRANSLATE_WIDTH; lane = lane + 1) begin : gen_lane
			assign translate_req_rdy_o[lane] = 1'b1;
			assign translate_req_fire[lane] = translate_req_rdy_o[lane] & translate_req_vld_i[lane];
			assign translate_req_payload_clk_en[lane] = translate_req_fire[lane];
			assign translate_req_is_st_d[lane] = translate_req_access_type_i[lane * 2+:2] == PMP_ACCESS_TYPE_W;
			assign translate_req_vld_d[lane] = translate_req_fire[lane];
			assign translate_req_vpn_d[lane * VPN_WIDTH+:VPN_WIDTH] = translate_req_vpn_i[lane * VPN_WIDTH+:VPN_WIDTH];
			assign translate_req_asid_d[lane * ASID_WIDTH+:ASID_WIDTH] = satp_asid_i;
			assign dtlb_excp_entry_vpn_equal_bit[lane * VPN_WIDTH+:VPN_WIDTH] = ~(translate_req_vpn_q[lane * VPN_WIDTH+:VPN_WIDTH] ^ dtlb_excp_entry_vpn_q);
			assign dtlb_excp_entry_hit[lane] = (((translate_req_vld_q[lane] & dtlb_excp_entry_V_q) & (translate_req_is_st_q[lane] == dtlb_excp_entry_is_st_q)) & (translate_req_asid_q[lane * ASID_WIDTH+:ASID_WIDTH] == dtlb_excp_entry_asid_q)) & &(dtlb_excp_entry_vpn_equal_bit[lane * VPN_WIDTH+:VPN_WIDTH] | ~dtlb_excp_entry_vpn_mask);
			for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_dtlb_entry_hit_logic
				assign dtlb_entry_vpn_equal_bit[((lane * ENTRY_COUNT) + macro) * VPN_WIDTH+:VPN_WIDTH] = ~(translate_req_vpn_q[lane * VPN_WIDTH+:VPN_WIDTH] ^ dtlb_entry_vpn_q[macro * VPN_WIDTH+:VPN_WIDTH]);
				assign dtlb_entry_hit[(lane * ENTRY_COUNT) + macro] = ((translate_req_vld_q[lane] & dtlb_entry_V_q[macro]) & ((translate_req_asid_q[lane * ASID_WIDTH+:ASID_WIDTH] == dtlb_entry_asid_q[macro * ASID_WIDTH+:ASID_WIDTH]) | dtlb_entry_G_q[macro])) & &(dtlb_entry_vpn_equal_bit[((lane * ENTRY_COUNT) + macro) * VPN_WIDTH+:VPN_WIDTH] | ~dtlb_entry_vpn_mask[macro * VPN_WIDTH+:VPN_WIDTH]);
			end
			assign dtlb_hit[lane] = |dtlb_entry_hit[lane * ENTRY_COUNT+:ENTRY_COUNT];
			for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_plru_access_mask
				assign dtlb_lane_hit_mask_trans[(macro * TRANSLATE_WIDTH) + lane] = dtlb_entry_hit[(lane * ENTRY_COUNT) + macro];
			end
			assign pte_superpage_alignment_mask[lane * PPN_WIDTH+:PPN_WIDTH] = gen_page_alignment_mask(dtlb_hit_entry_mux_out_page_lvl[lane * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH]);
			assign pte_superpage_alignment_check_pass[lane] = (dtlb_hit_entry_mux_out_PPN[lane * PPN_WIDTH+:PPN_WIDTH] & pte_superpage_alignment_mask[lane * PPN_WIDTH+:PPN_WIDTH]) == 0;
			assign pte_superpage_alignment_check_fail[lane] = ~pte_superpage_alignment_check_pass[lane];
			assign pte_access_permission_check_fail[lane] = ((~dtlb_hit_entry_mux_out_A[lane] | (~dtlb_hit_entry_mux_out_D[lane] & translate_req_is_st_q[lane])) | ~dtlb_hit_entry_mux_out_X[lane]) | ((dtlb_hit_entry_mux_out_U[lane] & ~(effective_priv_lvl == PRIV_LVL_U)) & ~((effective_priv_lvl == PRIV_LVL_S) & mstatus_sum));
			assign pte_access_permission_check_pass[lane] = ~pte_access_permission_check_fail[lane];
			assign pte_check_pass[lane] = pte_superpage_alignment_check_pass[lane] & pte_access_permission_check_pass[lane];
			assign pte_check_fail[lane] = pte_superpage_alignment_check_fail[lane] | pte_access_permission_check_fail[lane];
			assign translate_resp_vld_o[lane] = translate_req_vld_q[lane];
			assign translate_resp_ppn_o[lane * PPN_WIDTH+:PPN_WIDTH] = (skip_translation ? {{PPN_WIDTH - VPN_WIDTH {1'b0}}, translate_req_vpn_q[lane * VPN_WIDTH+:VPN_WIDTH]} : (dtlb_hit[lane] ? (dtlb_hit_entry_mux_out_PPN[lane * PPN_WIDTH+:PPN_WIDTH] & ~pte_superpage_alignment_mask[lane * PPN_WIDTH+:PPN_WIDTH]) | ({{PPN_WIDTH - VPN_WIDTH {1'b0}}, translate_req_vpn_q[lane * VPN_WIDTH+:VPN_WIDTH]} & pte_superpage_alignment_mask[lane * PPN_WIDTH+:PPN_WIDTH]) : {PPN_WIDTH {1'b0}}));
			assign translate_resp_excp_vld_o[lane] = ~skip_translation & (dtlb_excp_entry_hit[lane] | (dtlb_hit[lane] & pte_check_fail[lane]));
			function automatic signed [EXCP_CAUSE_WIDTH - 1:0] sv2v_cast_83E65_signed;
				input reg signed [EXCP_CAUSE_WIDTH - 1:0] inp;
				sv2v_cast_83E65_signed = inp;
			endfunction
			assign translate_resp_excp_cause_o[lane * EXCP_CAUSE_WIDTH+:EXCP_CAUSE_WIDTH] = ({EXCP_CAUSE_WIDTH {~skip_translation}} & ({EXCP_CAUSE_WIDTH {dtlb_excp_entry_hit[lane] & dtlb_excp_entry_access_fault_q}} & (translate_req_is_st_q ? sv2v_cast_83E65_signed(ST_ACCESS_FAULT) : sv2v_cast_83E65_signed(LD_ACCESS_FAULT)))) | ({EXCP_CAUSE_WIDTH {(dtlb_excp_entry_hit[lane] & dtlb_excp_entry_page_fault_q) | (dtlb_hit[lane] & pte_check_fail[lane])}} & (translate_req_is_st_q ? sv2v_cast_83E65_signed(ST_PAGE_FAULT) : sv2v_cast_83E65_signed(LD_PAGE_FAULT)));
			assign translate_resp_miss_o[lane] = ~translate_resp_hit_o[lane];
			assign translate_resp_hit_o[lane] = (dtlb_excp_entry_hit[lane] | dtlb_hit[lane]) | skip_translation;
			assign tlb_miss_req_vld[lane] = translate_resp_vld_o[lane] & translate_resp_miss_o[lane];
			assign tlb_miss_req_access_type[lane * 2+:2] = (translate_req_is_st_q ? PMP_ACCESS_TYPE_W : PMP_ACCESS_TYPE_R);
			assign tlb_miss_req_vpn[lane * VPN_WIDTH+:VPN_WIDTH] = translate_req_vpn_q[lane * VPN_WIDTH+:VPN_WIDTH];
			assign tlb_miss_req_asid[lane * ASID_WIDTH+:ASID_WIDTH] = translate_req_asid_q[lane * ASID_WIDTH+:ASID_WIDTH];
			MuxOH #(
				.InputWidth(ENTRY_COUNT),
				.DataWidth((PPN_WIDTH + PAGE_LVL_WIDTH) + 7)
			) u_dtlb_hit_entry_MuxOH(
				.sel_i(dtlb_entry_hit[lane * ENTRY_COUNT+:ENTRY_COUNT]),
				.data_i(dtlb_hit_entry_mux_in),
				.data_o({dtlb_hit_entry_mux_out_page_lvl[lane * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH], dtlb_hit_entry_mux_out_PPN[lane * PPN_WIDTH+:PPN_WIDTH], dtlb_hit_entry_mux_out_D[lane], dtlb_hit_entry_mux_out_A[lane], dtlb_hit_entry_mux_out_G[lane], dtlb_hit_entry_mux_out_U[lane], dtlb_hit_entry_mux_out_X[lane], dtlb_hit_entry_mux_out_W[lane], dtlb_hit_entry_mux_out_R[lane]})
			);
			DFFR #(.Width(1)) u_translate_req_vld_DFFR(
				.CLK(clk),
				.RSTN(rstn),
				.DRST(1'b0),
				.D(translate_req_vld_d[lane]),
				.Q(translate_req_vld_q[lane])
			);
			DFFE #(.Width((VPN_WIDTH + 1) + ASID_WIDTH)) u_translate_req_payload_DFFR(
				.CLK(clk),
				.EN(translate_req_payload_clk_en[lane]),
				.D({translate_req_vpn_d[lane * VPN_WIDTH+:VPN_WIDTH], translate_req_is_st_d[lane], translate_req_asid_d[lane * ASID_WIDTH+:ASID_WIDTH]}),
				.Q({translate_req_vpn_q[lane * VPN_WIDTH+:VPN_WIDTH], translate_req_is_st_q[lane], translate_req_asid_q[lane * ASID_WIDTH+:ASID_WIDTH]})
			);
		end
	endgenerate
	assign refill_exception_entry = next_lvl_resp_vld_i & (next_lvl_resp_access_fault_i | next_lvl_resp_page_fault_i);
	assign dtlb_excp_entry_vld_set = refill_exception_entry;
	assign dtlb_excp_entry_vld_clean = tlb_flush_vld_i;
	assign dtlb_excp_entry_vld_clk_en = dtlb_excp_entry_vld_set | dtlb_excp_entry_vld_clean;
	assign dtlb_excp_entry_payload_clk_en = refill_exception_entry;
	assign dtlb_excp_entry_V_d = dtlb_excp_entry_vld_set & ~dtlb_excp_entry_vld_clean;
	assign dtlb_excp_entry_vpn_d = next_lvl_resp_vpn_i;
	assign dtlb_excp_entry_asid_d = next_lvl_resp_asid_i;
	assign dtlb_excp_entry_page_lvl_d = next_lvl_resp_page_lvl_i;
	assign dtlb_excp_entry_is_st_d = next_lvl_resp_access_type_i == PMP_ACCESS_TYPE_W;
	assign dtlb_excp_entry_access_fault_d = next_lvl_resp_access_fault_i;
	assign dtlb_excp_entry_page_fault_d = next_lvl_resp_page_fault_i;
	assign refill_entry = next_lvl_resp_vld_q & ~next_lvl_resp_excp_vld_q;
	assign next_lvl_resp_payload_clk_en = next_lvl_resp_vld_i;
	assign next_lvl_resp_vld_d = next_lvl_resp_vld_i;
	assign next_lvl_resp_trans_id_d = next_lvl_resp_trans_id_i;
	assign next_lvl_resp_asid_d = next_lvl_resp_asid_i;
	assign next_lvl_resp_pte_d = next_lvl_resp_pte_i;
	assign next_lvl_resp_page_lvl_d = next_lvl_resp_page_lvl_i;
	assign next_lvl_resp_vpn_d = next_lvl_resp_vpn_i;
	assign next_lvl_resp_excp_vld_d = refill_exception_entry;
	assign exist_invld_entry = |(~dtlb_entry_V_q);
	assign refill_invld_oh_mask = ~dtlb_entry_V_q & ~(~dtlb_entry_V_q - 1'b1);
	assign tlb_refill_entry_is_evicted_d = ~exist_invld_entry;
	assign tlb_refill_entry_mask_d = (exist_invld_entry ? refill_invld_oh_mask : refill_evict_oh_mask);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_dtlb_entry_update_logic
			assign dtlb_entry_payload_clk_en[macro] = dtlb_entry_vld_set[macro];
			assign dtlb_entry_vld_set[macro] = refill_entry & tlb_refill_entry_mask_q[macro];
			assign dtlb_entry_vld_clean[macro] = tlb_flush_vld_i & ((~dtlb_entry_G_q[macro] & (((((tlb_flush_use_asid_i & tlb_flush_use_vpn_i) & (dtlb_entry_asid_q[macro * ASID_WIDTH+:ASID_WIDTH] == tlb_flush_asid_i)) & &(~(dtlb_entry_vpn_q[macro * VPN_WIDTH+:VPN_WIDTH] ^ tlb_flush_vpn_i) | ~dtlb_entry_vpn_mask[macro * VPN_WIDTH+:VPN_WIDTH])) | ((tlb_flush_use_asid_i & ~tlb_flush_use_vpn_i) & (dtlb_entry_asid_q[macro * ASID_WIDTH+:ASID_WIDTH] == tlb_flush_asid_i))) | ((~tlb_flush_use_asid_i & tlb_flush_use_vpn_i) & &(~(dtlb_entry_vpn_q[macro * VPN_WIDTH+:VPN_WIDTH] ^ tlb_flush_vpn_i) | ~dtlb_entry_vpn_mask[macro * VPN_WIDTH+:VPN_WIDTH])))) | ((~tlb_flush_use_asid_i & ~tlb_flush_use_vpn_i) & 1'b1));
			assign dtlb_entry_V_d[macro] = dtlb_entry_vld_set[macro] & ~dtlb_entry_vld_clean[macro];
			assign dtlb_entry_vld_clk_en[macro] = dtlb_entry_vld_set[macro] | dtlb_entry_vld_clean[macro];
			assign dtlb_entry_asid_d[macro * ASID_WIDTH+:ASID_WIDTH] = next_lvl_resp_asid_q;
			assign dtlb_entry_vpn_d[macro * VPN_WIDTH+:VPN_WIDTH] = next_lvl_resp_vpn_q;
			assign dtlb_entry_page_lvl_d[macro * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH] = next_lvl_resp_page_lvl_q;
			assign dtlb_entry_PPN_d[macro * PPN_WIDTH+:PPN_WIDTH] = next_lvl_resp_pte_q[53:10];
			assign dtlb_entry_D_d[macro] = next_lvl_resp_pte_q[7];
			assign dtlb_entry_A_d[macro] = next_lvl_resp_pte_q[6];
			assign dtlb_entry_G_d[macro] = next_lvl_resp_pte_q[5];
			assign dtlb_entry_U_d[macro] = next_lvl_resp_pte_q[4];
			assign dtlb_entry_X_d[macro] = next_lvl_resp_pte_q[3];
			assign dtlb_entry_W_d[macro] = next_lvl_resp_pte_q[2];
			assign dtlb_entry_R_d[macro] = next_lvl_resp_pte_q[1];
		end
	endgenerate
	DFFR #(.Width(1)) u_next_lvl_resp_vld_DFFR(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(1'b0),
		.D(next_lvl_resp_vld_d),
		.Q(next_lvl_resp_vld_q)
	);
	DFFE #(.Width((((((TRANS_ID_WIDTH + ASID_WIDTH) + 64) + PAGE_LVL_WIDTH) + VPN_WIDTH) + 2) + ENTRY_COUNT)) u_next_lvl_resp_payload_DFFE(
		.CLK(clk),
		.EN(next_lvl_resp_payload_clk_en),
		.D({next_lvl_resp_trans_id_d, next_lvl_resp_asid_d, next_lvl_resp_pte_d, next_lvl_resp_page_lvl_d, next_lvl_resp_vpn_d, next_lvl_resp_excp_vld_d, tlb_refill_entry_is_evicted_d, tlb_refill_entry_mask_d}),
		.Q({next_lvl_resp_trans_id_q, next_lvl_resp_asid_q, next_lvl_resp_pte_q, next_lvl_resp_page_lvl_q, next_lvl_resp_vpn_q, next_lvl_resp_excp_vld_q, tlb_refill_entry_is_evicted_q, tlb_refill_entry_mask_q})
	);
	PLRU #(.ENTRY_COUNT(ENTRY_COUNT)) u_PLRU(
		.access_mask_i(dtlb_plru_access_mask),
		.least_used_mask_o(refill_evict_oh_mask),
		.clk(clk),
		.rstn(rstn)
	);
	rvh_mmu_mshr #(
		.ALLOC_WIDTH(TRANSLATE_WIDTH),
		.ENTRY_COUNT(MSHR_COUNT),
		.VPN_WIDTH(VPN_WIDTH),
		.TRANS_ID_WIDTH(TRANS_ID_WIDTH)
	) u_rvh_mmu_mshr(
		.tlb_miss_req_vld_i(tlb_miss_req_vld),
		.tlb_miss_req_access_type_i(tlb_miss_req_access_type),
		.tlb_miss_req_vpn_i(tlb_miss_req_vpn),
		.tlb_miss_req_asid_i(tlb_miss_req_asid),
		.tlb_miss_req_grant_vld_o(next_lvl_req_vld_o),
		.tlb_miss_req_grant_trans_id_o(next_lvl_req_trans_id_o),
		.tlb_miss_req_grant_asid_o(next_lvl_req_asid_o),
		.tlb_miss_req_grant_vpn_o(next_lvl_req_vpn_o),
		.tlb_miss_req_grant_access_type_o(next_lvl_req_access_type_o),
		.tlb_miss_req_grant_rdy_i(next_lvl_req_rdy_i),
		.tlb_miss_response_vld_i(next_lvl_resp_vld_q),
		.tlb_miss_respone_trans_id_i(next_lvl_resp_trans_id_q),
		.exist_inflight_req_o(),
		.clk(clk),
		.rstn(rstn)
	);
	DFFR #(.Width(1)) u_dtlb_flush_grant_DFFR(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(1'b0),
		.D(tlb_flush_vld_i),
		.Q(tlb_flush_grant_o)
	);
	DFFRE #(.Width(1)) u_dtlb_excp_entry_vld_DFFRE(
		.CLK(clk),
		.RSTN(rstn),
		.DRST(1'b0),
		.EN(dtlb_excp_entry_vld_clk_en),
		.D(dtlb_excp_entry_V_d),
		.Q(dtlb_excp_entry_V_q)
	);
	DFFE #(.Width(((VPN_WIDTH + ASID_WIDTH) + PAGE_LVL_WIDTH) + 3)) u_dtlb_excp_entry_payload_DFFR(
		.CLK(clk),
		.EN(dtlb_excp_entry_payload_clk_en),
		.D({dtlb_excp_entry_vpn_d, dtlb_excp_entry_asid_d, dtlb_excp_entry_page_lvl_d, dtlb_excp_entry_is_st_d, dtlb_excp_entry_access_fault_d, dtlb_excp_entry_page_fault_d}),
		.Q({dtlb_excp_entry_vpn_q, dtlb_excp_entry_asid_q, dtlb_excp_entry_page_lvl_q, dtlb_excp_entry_is_st_q, dtlb_excp_entry_access_fault_q, dtlb_excp_entry_page_fault_q})
	);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_dtlb_entry
			DFFRE #(.Width(1)) u_dtlb_entry_vld_DFFR(
				.CLK(clk),
				.RSTN(rstn),
				.DRST(1'b0),
				.EN(dtlb_entry_vld_clk_en[macro]),
				.D(dtlb_entry_V_d[macro]),
				.Q(dtlb_entry_V_q[macro])
			);
			DFFE #(.Width((((ASID_WIDTH + VPN_WIDTH) + PAGE_LVL_WIDTH) + PPN_WIDTH) + 7)) u_dtlb_entry_payload_DFFR(
				.CLK(clk),
				.EN(dtlb_entry_payload_clk_en[macro]),
				.D({dtlb_entry_asid_d[macro * ASID_WIDTH+:ASID_WIDTH], dtlb_entry_vpn_d[macro * VPN_WIDTH+:VPN_WIDTH], dtlb_entry_page_lvl_d[macro * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH], dtlb_entry_PPN_d[macro * PPN_WIDTH+:PPN_WIDTH], dtlb_entry_D_d[macro], dtlb_entry_A_d[macro], dtlb_entry_G_d[macro], dtlb_entry_U_d[macro], dtlb_entry_X_d[macro], dtlb_entry_W_d[macro], dtlb_entry_R_d[macro]}),
				.Q({dtlb_entry_asid_q[macro * ASID_WIDTH+:ASID_WIDTH], dtlb_entry_vpn_q[macro * VPN_WIDTH+:VPN_WIDTH], dtlb_entry_page_lvl_q[macro * PAGE_LVL_WIDTH+:PAGE_LVL_WIDTH], dtlb_entry_PPN_q[macro * PPN_WIDTH+:PPN_WIDTH], dtlb_entry_D_q[macro], dtlb_entry_A_q[macro], dtlb_entry_G_q[macro], dtlb_entry_U_q[macro], dtlb_entry_X_q[macro], dtlb_entry_W_q[macro], dtlb_entry_R_q[macro]})
			);
		end
	endgenerate
endmodule
