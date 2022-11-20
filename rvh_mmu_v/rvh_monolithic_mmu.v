module rvh_monolithic_mmu (
	priv_lvl_i,
	satp_mode_i,
	satp_asid_i,
	satp_ppn_i,
	misc_mstatus_i,
	pmp_cfg_set_vld_i,
	pmp_cfg_set_addr_i,
	pmp_cfg_set_payload_i,
	pmp_cfg_origin_payload_o,
	pmp_addr_set_vld_i,
	pmp_addr_set_addr_i,
	pmp_addr_set_payload_i,
	pmp_addr_origin_payload_o,
	dtlb_translate_req_vld_i,
	dtlb_translate_req_access_type_i,
	dtlb_translate_req_vpn_i,
	dtlb_translate_req_rdy_o,
	dtlb_translate_resp_vld_o,
	dtlb_translate_resp_ppn_o,
	dtlb_translate_resp_excp_vld_o,
	dtlb_translate_resp_excp_cause_o,
	dtlb_translate_resp_miss_o,
	dtlb_translate_resp_hit_o,
	itlb_translate_req_vld_i,
	itlb_translate_req_vpn_i,
	itlb_translate_req_rdy_o,
	itlb_translate_resp_vld_o,
	itlb_translate_resp_ppn_o,
	itlb_translate_resp_excp_vld_o,
	itlb_translate_resp_excp_cause_o,
	itlb_translate_resp_miss_o,
	itlb_translate_resp_hit_o,
	dtlb_flush_vld_i,
	dtlb_flush_use_asid_i,
	dtlb_flush_use_vpn_i,
	dtlb_flush_vpn_i,
	dtlb_flush_asid_i,
	dtlb_flush_grant_o,
	itlb_flush_vld_i,
	itlb_flush_use_asid_i,
	itlb_flush_use_vpn_i,
	itlb_flush_vpn_i,
	itlb_flush_asid_i,
	itlb_flush_grant_o,
	tlb_flush_grant_o,
	ptw_walk_req_vld_o,
	ptw_walk_req_id_o,
	ptw_walk_req_addr_o,
	ptw_walk_req_rdy_i,
	ptw_walk_resp_vld_i,
	ptw_walk_resp_pte_i,
	ptw_walk_resp_rdy_o,
	clk,
	rstn
);
	parameter XLEN = 64;
	parameter PTW_ID_WIDTH = 1;
	parameter TRANS_ID_WIDTH = 3;
	parameter PADDR_WIDTH = 56;
	parameter EXCP_CAUSE_WIDTH = 64;
	parameter VPN_WIDTH = 27;
	parameter PMP_ENTRY_COUNT = 8;
	localparam PMPCFG_ENTRY_COUNT = PMP_ENTRY_COUNT / 8;
	localparam PMPADDR_ID_WIDTH = $clog2(PMP_ENTRY_COUNT);
	localparam PMPCFG_ID_WIDTH = (PMPCFG_ENTRY_COUNT > 1 ? $clog2(PMPCFG_ENTRY_COUNT) : 1);
	localparam PAGE_LVL_WIDTH = $clog2(VPN_WIDTH / 9);
	localparam PPN_WIDTH = 44;
	localparam PTE_WIDTH = 64;
	localparam ASID_WIDTH = 16;
	localparam MODE_WIDTH = 4;
	parameter TRANSLATE_WIDTH = 1;
	parameter DTLB_TRANSLATE_WIDTH = 1;
	parameter DTLB_ENTRY_COUNT = 32;
	parameter DTLB_MSHR_COUNT = 4;
	parameter DTLB_TRANS_ID_WIDTH = 3;
	parameter ITLB_TRANSLATE_WIDTH = 1;
	parameter ITLB_ENTRY_COUNT = 32;
	parameter ITLB_TRANS_ID_WIDTH = 3;
	input [1:0] priv_lvl_i;
	input [3:0] satp_mode_i;
	input [15:0] satp_asid_i;
	input [43:0] satp_ppn_i;
	input [XLEN - 1:0] misc_mstatus_i;
	input pmp_cfg_set_vld_i;
	input [PMPCFG_ID_WIDTH - 1:0] pmp_cfg_set_addr_i;
	input [63:0] pmp_cfg_set_payload_i;
	output [63:0] pmp_cfg_origin_payload_o;
	input pmp_addr_set_vld_i;
	input [PMPADDR_ID_WIDTH - 1:0] pmp_addr_set_addr_i;
	input [63:0] pmp_addr_set_payload_i;
	output [63:0] pmp_addr_origin_payload_o;
	input [TRANSLATE_WIDTH - 1:0] dtlb_translate_req_vld_i;
	input [(TRANSLATE_WIDTH * 2) - 1:0] dtlb_translate_req_access_type_i;
	input [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] dtlb_translate_req_vpn_i;
	output [TRANSLATE_WIDTH - 1:0] dtlb_translate_req_rdy_o;
	output [TRANSLATE_WIDTH - 1:0] dtlb_translate_resp_vld_o;
	output [(TRANSLATE_WIDTH * 44) - 1:0] dtlb_translate_resp_ppn_o;
	output [TRANSLATE_WIDTH - 1:0] dtlb_translate_resp_excp_vld_o;
	output [(TRANSLATE_WIDTH * EXCP_CAUSE_WIDTH) - 1:0] dtlb_translate_resp_excp_cause_o;
	output [TRANSLATE_WIDTH - 1:0] dtlb_translate_resp_miss_o;
	output [TRANSLATE_WIDTH - 1:0] dtlb_translate_resp_hit_o;
	input [TRANSLATE_WIDTH - 1:0] itlb_translate_req_vld_i;
	input [(TRANSLATE_WIDTH * VPN_WIDTH) - 1:0] itlb_translate_req_vpn_i;
	output [TRANSLATE_WIDTH - 1:0] itlb_translate_req_rdy_o;
	output [TRANSLATE_WIDTH - 1:0] itlb_translate_resp_vld_o;
	output [(TRANSLATE_WIDTH * 44) - 1:0] itlb_translate_resp_ppn_o;
	output [TRANSLATE_WIDTH - 1:0] itlb_translate_resp_excp_vld_o;
	output [(TRANSLATE_WIDTH * EXCP_CAUSE_WIDTH) - 1:0] itlb_translate_resp_excp_cause_o;
	output [TRANSLATE_WIDTH - 1:0] itlb_translate_resp_miss_o;
	output [TRANSLATE_WIDTH - 1:0] itlb_translate_resp_hit_o;
	input dtlb_flush_vld_i;
	input dtlb_flush_use_asid_i;
	input dtlb_flush_use_vpn_i;
	input [VPN_WIDTH - 1:0] dtlb_flush_vpn_i;
	input [15:0] dtlb_flush_asid_i;
	output dtlb_flush_grant_o;
	input itlb_flush_vld_i;
	input itlb_flush_use_asid_i;
	input itlb_flush_use_vpn_i;
	input [VPN_WIDTH - 1:0] itlb_flush_vpn_i;
	input [15:0] itlb_flush_asid_i;
	output itlb_flush_grant_o;
	output tlb_flush_grant_o;
	output ptw_walk_req_vld_o;
	output [PTW_ID_WIDTH - 1:0] ptw_walk_req_id_o;
	output [PADDR_WIDTH - 1:0] ptw_walk_req_addr_o;
	input ptw_walk_req_rdy_i;
	input ptw_walk_resp_vld_i;
	input [63:0] ptw_walk_resp_pte_i;
	output ptw_walk_resp_rdy_o;
	input clk;
	input rstn;
	wire arbitated_dtlb_miss_req_vld;
	wire arbitated_itlb_miss_req_vld;
	wire dtlb_miss_req_vld;
	wire [TRANS_ID_WIDTH - 1:0] dtlb_miss_req_trans_id;
	wire [15:0] dtlb_miss_req_asid;
	wire [VPN_WIDTH - 1:0] dtlb_miss_req_vpn;
	wire [1:0] dtlb_miss_req_access_type;
	wire dtlb_miss_req_rdy;
	wire dtlb_miss_resp_vld;
	wire [TRANS_ID_WIDTH - 1:0] dtlb_miss_resp_trans_id;
	wire [15:0] dtlb_miss_resp_asid;
	wire [63:0] dtlb_miss_resp_pte;
	wire [PAGE_LVL_WIDTH - 1:0] dtlb_miss_resp_page_lvl;
	wire [VPN_WIDTH - 1:0] dtlb_miss_resp_vpn;
	wire [1:0] dtlb_miss_resp_access_type;
	wire dtlb_miss_resp_access_fault;
	wire dtlb_miss_resp_page_fault;
	wire itlb_miss_req_vld;
	wire [TRANS_ID_WIDTH - 1:0] itlb_miss_req_trans_id;
	wire [15:0] itlb_miss_req_asid;
	wire [VPN_WIDTH - 1:0] itlb_miss_req_vpn;
	wire [1:0] itlb_miss_req_access_type;
	wire itlb_miss_req_rdy;
	wire itlb_miss_resp_vld;
	wire [TRANS_ID_WIDTH - 1:0] itlb_miss_resp_trans_id;
	wire [15:0] itlb_miss_resp_asid;
	wire [63:0] itlb_miss_resp_pte;
	wire [PAGE_LVL_WIDTH - 1:0] itlb_miss_resp_page_lvl;
	wire [VPN_WIDTH - 1:0] itlb_miss_resp_vpn;
	wire [1:0] itlb_miss_resp_access_type;
	wire itlb_miss_resp_access_fault;
	wire itlb_miss_resp_page_fault;
	rvh_mmu #(
		.TRANS_ID_WIDTH(TRANS_ID_WIDTH),
		.PADDR_WIDTH(PADDR_WIDTH),
		.EXCP_CAUSE_WIDTH(EXCP_CAUSE_WIDTH),
		.VPN_WIDTH(VPN_WIDTH),
		.PMP_ENTRY_COUNT(PMP_ENTRY_COUNT)
	) u_rvh_mmu(
		.priv_lvl_i(priv_lvl_i),
		.pmp_cfg_set_vld_i(pmp_cfg_set_vld_i),
		.pmp_cfg_set_addr_i(pmp_cfg_set_addr_i),
		.pmp_cfg_set_payload_i(pmp_cfg_set_payload_i),
		.pmp_cfg_origin_payload_o(pmp_cfg_origin_payload_o),
		.pmp_addr_set_vld_i(pmp_addr_set_vld_i),
		.pmp_addr_set_addr_i(pmp_addr_set_addr_i),
		.pmp_addr_set_payload_i(pmp_addr_set_payload_i),
		.pmp_addr_origin_payload_o(pmp_addr_origin_payload_o),
		.satp_mode_i(satp_mode_i),
		.satp_ppn_i(satp_ppn_i),
		.dtlb_miss_req_vld_i(arbitated_dtlb_miss_req_vld),
		.dtlb_miss_req_trans_id_i(dtlb_miss_req_trans_id),
		.dtlb_miss_req_asid_i(dtlb_miss_req_asid),
		.dtlb_miss_req_vpn_i(dtlb_miss_req_vpn),
		.dtlb_miss_req_access_type_i(dtlb_miss_req_access_type),
		.dtlb_miss_req_rdy_o(dtlb_miss_req_rdy),
		.dtlb_miss_resp_vld_o(dtlb_miss_resp_vld),
		.dtlb_miss_resp_trans_id_o(dtlb_miss_resp_trans_id),
		.dtlb_miss_resp_asid_o(dtlb_miss_resp_asid),
		.dtlb_miss_resp_pte_o(dtlb_miss_resp_pte),
		.dtlb_miss_resp_page_lvl_o(dtlb_miss_resp_page_lvl),
		.dtlb_miss_resp_vpn_o(dtlb_miss_resp_vpn),
		.dtlb_miss_resp_access_type_o(dtlb_miss_resp_access_type),
		.dtlb_miss_resp_access_fault_o(dtlb_miss_resp_access_fault),
		.dtlb_miss_resp_page_fault_o(dtlb_miss_resp_page_fault),
		.itlb_miss_req_vld_i(arbitated_itlb_miss_req_vld),
		.itlb_miss_req_trans_id_i(itlb_miss_req_trans_id),
		.itlb_miss_req_asid_i(itlb_miss_req_asid),
		.itlb_miss_req_vpn_i(itlb_miss_req_vpn),
		.itlb_miss_req_access_type_i(itlb_miss_req_access_type),
		.itlb_miss_req_rdy_o(itlb_miss_req_rdy),
		.itlb_miss_resp_vld_o(itlb_miss_resp_vld),
		.itlb_miss_resp_trans_id_o(itlb_miss_resp_trans_id),
		.itlb_miss_resp_asid_o(itlb_miss_resp_asid),
		.itlb_miss_resp_pte_o(itlb_miss_resp_pte),
		.itlb_miss_resp_page_lvl_o(itlb_miss_resp_page_lvl),
		.itlb_miss_resp_vpn_o(itlb_miss_resp_vpn),
		.itlb_miss_resp_access_type_o(itlb_miss_resp_access_type),
		.itlb_miss_resp_access_fault_o(itlb_miss_resp_access_fault),
		.itlb_miss_resp_page_fault_o(itlb_miss_resp_page_fault),
		.ptw_walk_req_vld_o(ptw_walk_req_vld_o),
		.ptw_walk_req_id_o(ptw_walk_req_id_o),
		.ptw_walk_req_addr_o(ptw_walk_req_addr_o),
		.ptw_walk_req_rdy_i(ptw_walk_req_rdy_i),
		.ptw_walk_resp_vld_i(ptw_walk_resp_vld_i),
		.ptw_walk_resp_pte_i(ptw_walk_resp_pte_i),
		.ptw_walk_resp_rdy_o(ptw_walk_resp_rdy_o),
		.tlb_flush_vld_i(dtlb_flush_vld_i),
		.tlb_flush_use_asid_i(dtlb_flush_use_asid_i | itlb_flush_use_asid_i),
		.tlb_flush_use_vpn_i(dtlb_flush_use_vpn_i | itlb_flush_use_vpn_i),
		.tlb_flush_vpn_i(dtlb_flush_vpn_i | itlb_flush_vpn_i),
		.tlb_flush_asid_i(dtlb_flush_asid_i | itlb_flush_asid_i),
		.tlb_flush_grant_o(tlb_flush_grant_o),
		.clk(clk),
		.rstn(rstn)
	);
	rvh_tlb_arbiter #(.DTLB_PRIOR(1)) u_rvh_tlb_arbiter(
		.dtlb_miss_req_vld_i(dtlb_miss_req_vld),
		.itlb_miss_req_vld_i(itlb_miss_req_vld),
		.dtlb_miss_req_vld_o(arbitated_dtlb_miss_req_vld),
		.itlb_miss_req_vld_o(arbitated_itlb_miss_req_vld)
	);
	rvh_dtlb #(
		.TRANSLATE_WIDTH(DTLB_TRANSLATE_WIDTH),
		.ENTRY_COUNT(DTLB_ENTRY_COUNT),
		.MSHR_COUNT(DTLB_MSHR_COUNT),
		.TRANS_ID_WIDTH(DTLB_TRANS_ID_WIDTH),
		.PADDR_WIDTH(PADDR_WIDTH),
		.EXCP_CAUSE_WIDTH(EXCP_CAUSE_WIDTH),
		.VPN_WIDTH(VPN_WIDTH),
		.ASID_WIDTH(ASID_WIDTH)
	) u_rvh_dtlb(
		.priv_lvl_i(priv_lvl_i),
		.mstatus_mprv(misc_mstatus_i[17]),
		.mstatus_mpp(misc_mstatus_i[12:11]),
		.mstatus_mxr(misc_mstatus_i[19]),
		.mstatus_sum(misc_mstatus_i[18]),
		.satp_mode_i(satp_mode_i),
		.satp_asid_i(satp_asid_i),
		.translate_req_vld_i(dtlb_translate_req_vld_i),
		.translate_req_access_type_i(dtlb_translate_req_access_type_i),
		.translate_req_vpn_i(dtlb_translate_req_vpn_i),
		.translate_req_rdy_o(dtlb_translate_req_rdy_o),
		.translate_resp_vld_o(dtlb_translate_resp_vld_o),
		.translate_resp_ppn_o(dtlb_translate_resp_ppn_o),
		.translate_resp_excp_vld_o(dtlb_translate_resp_excp_vld_o),
		.translate_resp_excp_cause_o(dtlb_translate_resp_excp_cause_o),
		.translate_resp_miss_o(dtlb_translate_resp_miss_o),
		.translate_resp_hit_o(dtlb_translate_resp_hit_o),
		.next_lvl_req_vld_o(dtlb_miss_req_vld),
		.next_lvl_req_trans_id_o(dtlb_miss_req_trans_id),
		.next_lvl_req_asid_o(dtlb_miss_req_asid),
		.next_lvl_req_vpn_o(dtlb_miss_req_vpn),
		.next_lvl_req_access_type_o(dtlb_miss_req_access_type),
		.next_lvl_req_rdy_i(dtlb_miss_req_rdy),
		.next_lvl_resp_vld_i(dtlb_miss_resp_vld),
		.next_lvl_resp_trans_id_i(dtlb_miss_resp_trans_id),
		.next_lvl_resp_asid_i(dtlb_miss_resp_asid),
		.next_lvl_resp_pte_i(dtlb_miss_resp_pte),
		.next_lvl_resp_page_lvl_i(dtlb_miss_resp_page_lvl),
		.next_lvl_resp_vpn_i(dtlb_miss_resp_vpn),
		.next_lvl_resp_access_type_i(dtlb_miss_resp_access_type),
		.next_lvl_resp_access_fault_i(dtlb_miss_resp_access_fault),
		.next_lvl_resp_page_fault_i(dtlb_miss_resp_page_fault),
		.tlb_flush_vld_i(dtlb_flush_vld_i),
		.tlb_flush_use_asid_i(dtlb_flush_use_asid_i),
		.tlb_flush_use_vpn_i(dtlb_flush_use_vpn_i),
		.tlb_flush_vpn_i(dtlb_flush_vpn_i),
		.tlb_flush_asid_i(dtlb_flush_asid_i),
		.tlb_flush_grant_o(dtlb_flush_grant_o),
		.clk(clk),
		.rstn(rstn)
	);
	rvh_itlb #(
		.TRANSLATE_WIDTH(ITLB_TRANSLATE_WIDTH),
		.ENTRY_COUNT(ITLB_ENTRY_COUNT),
		.TRANS_ID_WIDTH(ITLB_TRANS_ID_WIDTH),
		.PADDR_WIDTH(PADDR_WIDTH),
		.EXCP_CAUSE_WIDTH(EXCP_CAUSE_WIDTH),
		.VPN_WIDTH(VPN_WIDTH),
		.ASID_WIDTH(ASID_WIDTH)
	) u_rvh_itlb(
		.priv_lvl_i(priv_lvl_i),
		.mstatus_mxr(misc_mstatus_i[19]),
		.mstatus_sum(misc_mstatus_i[18]),
		.satp_mode_i(satp_mode_i),
		.satp_asid_i(satp_asid_i),
		.translate_req_vld_i(itlb_translate_req_vld_i),
		.translate_req_vpn_i(itlb_translate_req_vpn_i),
		.translate_req_rdy_o(itlb_translate_req_rdy_o),
		.translate_resp_vld_o(itlb_translate_resp_vld_o),
		.translate_resp_ppn_o(itlb_translate_resp_ppn_o),
		.translate_resp_excp_vld_o(itlb_translate_resp_excp_vld_o),
		.translate_resp_excp_cause_o(itlb_translate_resp_excp_cause_o),
		.translate_resp_miss_o(itlb_translate_resp_miss_o),
		.translate_resp_hit_o(itlb_translate_resp_hit_o),
		.next_lvl_req_vld_o(itlb_miss_req_vld),
		.next_lvl_req_trans_id_o(itlb_miss_req_trans_id),
		.next_lvl_req_asid_o(itlb_miss_req_asid),
		.next_lvl_req_vpn_o(itlb_miss_req_vpn),
		.next_lvl_req_access_type_o(itlb_miss_req_access_type),
		.next_lvl_req_rdy_i(itlb_miss_req_rdy),
		.next_lvl_resp_vld_i(itlb_miss_resp_vld),
		.next_lvl_resp_trans_id_i(itlb_miss_resp_trans_id),
		.next_lvl_resp_asid_i(itlb_miss_resp_asid),
		.next_lvl_resp_pte_i(itlb_miss_resp_pte),
		.next_lvl_resp_page_lvl_i(itlb_miss_resp_page_lvl),
		.next_lvl_resp_vpn_i(itlb_miss_resp_vpn),
		.next_lvl_resp_access_type_i(itlb_miss_resp_access_type),
		.next_lvl_resp_access_fault_i(itlb_miss_resp_access_fault),
		.next_lvl_resp_page_fault_i(itlb_miss_resp_page_fault),
		.tlb_flush_vld_i(itlb_flush_vld_i),
		.tlb_flush_use_asid_i(itlb_flush_use_asid_i),
		.tlb_flush_use_vpn_i(itlb_flush_use_vpn_i),
		.tlb_flush_vpn_i(itlb_flush_vpn_i),
		.tlb_flush_asid_i(itlb_flush_asid_i),
		.tlb_flush_grant_o(itlb_flush_grant_o),
		.clk(clk),
		.rstn(rstn)
	);
endmodule
