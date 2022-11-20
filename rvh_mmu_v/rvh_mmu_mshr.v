module rvh_mmu_mshr (
	tlb_miss_req_vld_i,
	tlb_miss_req_access_type_i,
	tlb_miss_req_asid_i,
	tlb_miss_req_vpn_i,
	tlb_miss_req_grant_vld_o,
	tlb_miss_req_grant_trans_id_o,
	tlb_miss_req_grant_asid_o,
	tlb_miss_req_grant_vpn_o,
	tlb_miss_req_grant_access_type_o,
	tlb_miss_req_grant_rdy_i,
	tlb_miss_response_vld_i,
	tlb_miss_respone_trans_id_i,
	exist_inflight_req_o,
	clk,
	rstn
);
	parameter ALLOC_WIDTH = 1;
	parameter ENTRY_COUNT = 1;
	parameter VPN_WIDTH = 27;
	parameter TRANS_ID_WIDTH = 3;
	parameter ASID_WIDTH = 16;
	input [ALLOC_WIDTH - 1:0] tlb_miss_req_vld_i;
	input [(ALLOC_WIDTH * 2) - 1:0] tlb_miss_req_access_type_i;
	input [(ALLOC_WIDTH * ASID_WIDTH) - 1:0] tlb_miss_req_asid_i;
	input [(ALLOC_WIDTH * VPN_WIDTH) - 1:0] tlb_miss_req_vpn_i;
	output tlb_miss_req_grant_vld_o;
	output [TRANS_ID_WIDTH - 1:0] tlb_miss_req_grant_trans_id_o;
	output [ASID_WIDTH - 1:0] tlb_miss_req_grant_asid_o;
	output [VPN_WIDTH - 1:0] tlb_miss_req_grant_vpn_o;
	output [1:0] tlb_miss_req_grant_access_type_o;
	input tlb_miss_req_grant_rdy_i;
	input tlb_miss_response_vld_i;
	input [TRANS_ID_WIDTH - 1:0] tlb_miss_respone_trans_id_i;
	output exist_inflight_req_o;
	input clk;
	input rstn;
	localparam MSHR_ENTRY_ID_WIDTH = (ENTRY_COUNT > 1 ? $clog2(ENTRY_COUNT) : 1);
	genvar macro;
	wire mshr_entry_vld_clk_en;
	wire [ENTRY_COUNT - 1:0] mshr_entry_payload_clk_en;
	wire [ENTRY_COUNT - 1:0] mshr_entry_vld_d;
	wire [(ENTRY_COUNT * VPN_WIDTH) - 1:0] mshr_entry_vpn_d;
	reg [ENTRY_COUNT - 1:0] mshr_entry_vld_q;
	reg [(ENTRY_COUNT * VPN_WIDTH) - 1:0] mshr_entry_vpn_q;
	wire [(((VPN_WIDTH + ASID_WIDTH) + 1) >= 0 ? (ALLOC_WIDTH * ((VPN_WIDTH + ASID_WIDTH) + 2)) - 1 : (ALLOC_WIDTH * (1 - ((VPN_WIDTH + ASID_WIDTH) + 1))) + (VPN_WIDTH + ASID_WIDTH)):(((VPN_WIDTH + ASID_WIDTH) + 1) >= 0 ? 0 : (VPN_WIDTH + ASID_WIDTH) + 1)] tlb_miss_req_enq_payload;
	wire tlb_miss_req_grant_vld;
	wire [1:0] tlb_miss_req_grant_access_type;
	wire [VPN_WIDTH - 1:0] tlb_miss_req_grant_vpn;
	wire [ASID_WIDTH - 1:0] tlb_miss_req_grant_asid;
	wire tlb_miss_requset_waived;
	wire [ENTRY_COUNT - 1:0] tlb_miss_request_waive_mask;
	wire mshr_rdy;
	wire [ENTRY_COUNT - 1:0] mshr_alloc_mask;
	wire [MSHR_ENTRY_ID_WIDTH - 1:0] mshr_alloc_trans_id;
	wire tlb_miss_req_grant_fire;
	wire [ENTRY_COUNT - 1:0] mshr_dealloc_mask;
	assign exist_inflight_req_o = (|tlb_miss_req_vld_i | |mshr_entry_vld_q) | tlb_miss_req_grant_vld;
	generate
		for (macro = 0; macro < ALLOC_WIDTH; macro = macro + 1) begin : gen_tlb_miss_request_enq_payload
			assign tlb_miss_req_enq_payload[(((VPN_WIDTH + ASID_WIDTH) + 1) >= 0 ? 0 : (VPN_WIDTH + ASID_WIDTH) + 1) + (macro * (((VPN_WIDTH + ASID_WIDTH) + 1) >= 0 ? (VPN_WIDTH + ASID_WIDTH) + 2 : 1 - ((VPN_WIDTH + ASID_WIDTH) + 1)))+:(((VPN_WIDTH + ASID_WIDTH) + 1) >= 0 ? (VPN_WIDTH + ASID_WIDTH) + 2 : 1 - ((VPN_WIDTH + ASID_WIDTH) + 1))] = {tlb_miss_req_access_type_i[macro * 2+:2], tlb_miss_req_vpn_i[macro * VPN_WIDTH+:VPN_WIDTH], tlb_miss_req_asid_i[macro * ASID_WIDTH+:ASID_WIDTH]};
		end
	endgenerate
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_request_waiver
			assign tlb_miss_request_waive_mask[macro] = mshr_entry_vld_q[macro] & (mshr_entry_vpn_q[macro * VPN_WIDTH+:VPN_WIDTH] == tlb_miss_req_grant_vpn);
		end
	endgenerate
	assign tlb_miss_requset_waived = |tlb_miss_request_waive_mask;
	assign tlb_miss_req_grant_vld_o = (tlb_miss_req_grant_vld & mshr_rdy) & ~tlb_miss_requset_waived;
	assign tlb_miss_req_grant_trans_id_o = {{TRANS_ID_WIDTH - MSHR_ENTRY_ID_WIDTH {1'b0}}, mshr_alloc_trans_id};
	assign tlb_miss_req_grant_asid_o = tlb_miss_req_grant_asid;
	assign tlb_miss_req_grant_access_type_o = tlb_miss_req_grant_access_type;
	assign tlb_miss_req_grant_vpn_o = tlb_miss_req_grant_vpn;
	assign mshr_rdy = |(~mshr_entry_vld_q);
	assign mshr_alloc_mask = ~mshr_entry_vld_q & ~(~mshr_entry_vld_q - 1'b1);
	assign tlb_miss_req_grant_fire = tlb_miss_req_grant_vld_o & tlb_miss_req_grant_rdy_i;
	assign mshr_dealloc_mask = 1'sb1 << tlb_miss_respone_trans_id_i[MSHR_ENTRY_ID_WIDTH - 1:0];
	assign mshr_entry_payload_clk_en = {ENTRY_COUNT {tlb_miss_req_grant_fire}} & mshr_alloc_mask;
	assign mshr_entry_vld_clk_en = tlb_miss_req_grant_fire | tlb_miss_response_vld_i;
	assign mshr_entry_vld_d = (~mshr_entry_vld_q & ({ENTRY_COUNT {tlb_miss_req_grant_fire}} & mshr_alloc_mask)) | (mshr_entry_vld_q & ~({ENTRY_COUNT {tlb_miss_response_vld_i}} & mshr_dealloc_mask));
	assign mshr_entry_vpn_d = tlb_miss_req_grant_vpn;
	MultiPortStreamFIFO #(
		.Depth(ALLOC_WIDTH * 2),
		.DataWidth((2 + VPN_WIDTH) + ASID_WIDTH),
		.EnqWidth(ALLOC_WIDTH),
		.DeqWidth(1),
		.TakenAll(0)
	) u_tlb_miss_grant_buffer(
		.enq_vld_i(tlb_miss_req_vld_i),
		.enq_payload_i(tlb_miss_req_enq_payload),
		.enq_rdy_o(),
		.deq_vld_o(tlb_miss_req_grant_vld),
		.deq_payload_o({tlb_miss_req_grant_access_type, tlb_miss_req_grant_vpn, tlb_miss_req_grant_asid}),
		.deq_rdy_i(tlb_miss_req_grant_fire | tlb_miss_requset_waived),
		.flush_i(1'b0),
		.clk(clk),
		.rstn(rstn)
	);
	OH2UInt #(.InputWidth(ENTRY_COUNT)) u_OH2UInt(
		.oh_i(mshr_alloc_mask),
		.result_o(mshr_alloc_trans_id)
	);
	DFFRE #(.Width(ENTRY_COUNT)) u_mshr_entry_vld_DFFRE(
		.CLK(clk),
		.RSTN(rstn),
		.EN(mshr_entry_vld_clk_en),
		.DRST({ENTRY_COUNT {1'b0}}),
		.D(mshr_entry_vld_d),
		.Q(mshr_entry_vld_q)
	);
	generate
		for (macro = 0; macro < ENTRY_COUNT; macro = macro + 1) begin : gen_mshr_entry_payload
			DFFE #(.Width(VPN_WIDTH)) u_mshr_entry_payload_DFFE(
				.CLK(clk),
				.EN(mshr_entry_payload_clk_en[macro]),
				.D(mshr_entry_vpn_d[macro * VPN_WIDTH+:VPN_WIDTH]),
				.Q(mshr_entry_vpn_q[macro * VPN_WIDTH+:VPN_WIDTH])
			);
		end
	endgenerate
endmodule
