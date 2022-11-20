module rvh_tlb_arbiter (
	dtlb_miss_req_vld_i,
	itlb_miss_req_vld_i,
	dtlb_miss_req_vld_o,
	itlb_miss_req_vld_o
);
	parameter DTLB_PRIOR = 1;
	input dtlb_miss_req_vld_i;
	input itlb_miss_req_vld_i;
	output dtlb_miss_req_vld_o;
	output itlb_miss_req_vld_o;
	assign dtlb_miss_req_vld_o = (DTLB_PRIOR ? dtlb_miss_req_vld_i : dtlb_miss_req_vld_i & ~itlb_miss_req_vld_i);
	assign itlb_miss_req_vld_o = (DTLB_PRIOR ? itlb_miss_req_vld_i & ~dtlb_miss_req_vld_i : itlb_miss_req_vld_i);
endmodule
