module rvh_l1d_ewrq (
	l1d_ewrq_new_ewrq_valid_i,
	l1d_ewrq_new_ewrq_addr_i,
	l1d_ewrq_new_ewrq_dat_i,
	l1d_ewrq_new_ewrq_ready_o,
	ewrq_addr_o,
	ewrq_vld_o,
	l2_req_if_awvalid,
	l2_req_if_awready,
	l2_req_if_aw,
	l2_req_if_wvalid,
	l2_req_if_wready,
	l2_req_if_w,
	l2_resp_if_bvalid,
	l2_resp_if_bready,
	l2_resp_if_b,
	rst,
	clk
);
	parameter signed [31:0] BANK_ID = 0;
	input wire l1d_ewrq_new_ewrq_valid_i;
	localparam [31:0] rvh_pkg_L1D_BANK_COUNT = 1;
	localparam rvh_l1d_pkg_L1D_BANK_ID_NUM = rvh_pkg_L1D_BANK_COUNT;
	localparam rvh_l1d_pkg_L1D_BANK_ID_INDEX_WIDTH = 0;
	localparam [31:0] rvh_pkg_L1D_LINE_SIZE = 64;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 512;
	localparam rvh_l1d_pkg_L1D_OFFSET_WIDTH = 6;
	localparam [31:0] rvh_pkg_PADDR_WIDTH = 56;
	localparam rvh_l1d_pkg_L1D_BANK_LINE_ADDR_SIZE = 50;
	input wire [49:0] l1d_ewrq_new_ewrq_addr_i;
	input wire [511:0] l1d_ewrq_new_ewrq_dat_i;
	output wire l1d_ewrq_new_ewrq_ready_o;
	localparam rvh_l1d_pkg_N_MSHR = 4;
	localparam rvh_l1d_pkg_N_EWRQ = rvh_l1d_pkg_N_MSHR;
	output wire [199:0] ewrq_addr_o;
	output wire [3:0] ewrq_vld_o;
	output wire l2_req_if_awvalid;
	input wire l2_req_if_awready;
	localparam rvh_l1d_pkg_MEMNOC_TID_MASTERID_SIZE = 4;
	localparam rvh_l1d_pkg_MEMNOC_TID_TID_SIZE = 4;
	output wire [76:0] l2_req_if_aw;
	output wire l2_req_if_wvalid;
	input wire l2_req_if_wready;
	localparam rvh_l1d_pkg_MEM_DATA_WIDTH = 64;
	output wire [72:0] l2_req_if_w;
	input wire l2_resp_if_bvalid;
	output wire l2_resp_if_bready;
	input wire [9:0] l2_resp_if_b;
	input wire rst;
	input wire clk;
	localparam rvh_l1d_pkg_BURST_SIZE = 8;
	reg [3:0] mem_req_ff;
	reg [3:0] mem_req_nxt;
	reg wlast_ff;
	wire resp_ram_ready;
	wire req_ram_ready;
	wire is_mshr_word;
	wire aw_fifo_re;
	wire aw_fifo_we;
	wire aw_fifo_empty;
	wire w_fifo_re;
	wire w_fifo_we;
	wire w_fifo_empty;
	reg aw_fifo_re_ff;
	reg w_fifo_re_ff;
	wire [49:0] aw_fifo_din;
	wire [49:0] aw_fifo_dout;
	wire [511:0] w_fifo_din;
	wire [511:0] w_fifo_dout;
	wire aw_fifo_not_empty;
	wire w_fifo_not_empty;
	wire aw_fifo_enqueue_rdy;
	wire w_fifo_enqueue_rdy;
	assign aw_fifo_empty = ~aw_fifo_not_empty;
	assign w_fifo_empty = ~w_fifo_not_empty;
	assign l1d_ewrq_new_ewrq_ready_o = aw_fifo_enqueue_rdy & w_fifo_enqueue_rdy;
	sp_fifo_dat_vld_output_E40AD_DF976 #(
		.payload_t_rvh_l1d_pkg_L1D_BANK_LINE_ADDR_SIZE(rvh_l1d_pkg_L1D_BANK_LINE_ADDR_SIZE),
		.DEPTH(rvh_l1d_pkg_N_EWRQ),
		.MUST_TAKEN_ALL(1)
	) AW_FIFO_U(
		.enqueue_vld_i(aw_fifo_we),
		.enqueue_payload_i(aw_fifo_din),
		.enqueue_rdy_o(aw_fifo_enqueue_rdy),
		.dequeue_vld_o(aw_fifo_not_empty),
		.dequeue_payload_o(aw_fifo_dout),
		.dequeue_rdy_i(aw_fifo_re),
		.payload_dff(ewrq_addr_o),
		.payload_vld_dff(ewrq_vld_o),
		.flush_i(1'b0),
		.clk(clk),
		.rst(~rst)
	);
	mp_fifo_F7963_2BE7D #(
		.payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE(rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE),
		.ENQUEUE_WIDTH(1),
		.DEQUEUE_WIDTH(1),
		.DEPTH(rvh_l1d_pkg_N_EWRQ),
		.MUST_TAKEN_ALL(1)
	) W_FIFO_U(
		.enqueue_vld_i(w_fifo_we),
		.enqueue_payload_i(w_fifo_din),
		.enqueue_rdy_o(w_fifo_enqueue_rdy),
		.dequeue_vld_o(w_fifo_not_empty),
		.dequeue_payload_o(w_fifo_dout),
		.dequeue_rdy_i(w_fifo_re),
		.flush_i(1'b0),
		.clk(clk),
		.rst(~rst)
	);
	assign aw_fifo_we = l1d_ewrq_new_ewrq_valid_i & w_fifo_enqueue_rdy;
	assign aw_fifo_din = l1d_ewrq_new_ewrq_addr_i;
	assign aw_fifo_re = l2_req_if_awvalid & l2_req_if_awready;
	assign w_fifo_we = l1d_ewrq_new_ewrq_valid_i & aw_fifo_enqueue_rdy;
	assign w_fifo_din = l1d_ewrq_new_ewrq_dat_i;
	assign w_fifo_re = ((~mem_req_ff[3] | l2_req_if_w[8]) & l2_req_if_wvalid) & l2_req_if_wready;
	wire [49:0] ewrq_aw;
	assign ewrq_aw = aw_fifo_dout;
	assign l2_req_if_awvalid = ~aw_fifo_empty & ~aw_fifo_re_ff;
	assign l2_req_if_aw[72-:rvh_l1d_pkg_MEMNOC_TID_TID_SIZE] = 1'sb0;
	assign l2_req_if_aw[76-:4] = {1'b0, BANK_ID[2:0]};
	localparam rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH = rvh_l1d_pkg_L1D_OFFSET_WIDTH;
	assign l2_req_if_aw[68-:56] = {aw_fifo_dout, {rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH {1'b0}}};
	assign l2_req_if_aw[12-:8] = 7;
	localparam rvh_l1d_pkg_AXI_SIZE = 3;
	assign l2_req_if_aw[4-:3] = rvh_l1d_pkg_AXI_SIZE;
	assign l2_req_if_aw[1-:2] = 2'b01;
	wire [511:0] data_ram_dout_ff;
	wire [511:0] data_ram_dout;
	wire [511:0] mshr_w;
	assign mshr_w = w_fifo_dout;
	assign l2_req_if_wvalid = (mem_req_ff[3] & mem_req_nxt[3]) & ~w_fifo_re_ff;
	assign l2_req_if_w[3-:rvh_l1d_pkg_MEMNOC_TID_TID_SIZE] = 1'sb1;
	assign l2_req_if_w[7-:4] = {1'b0, BANK_ID[2:0]};
	assign l2_req_if_w[72-:64] = mshr_w[rvh_l1d_pkg_MEM_DATA_WIDTH * mem_req_ff[2-:3]+:rvh_l1d_pkg_MEM_DATA_WIDTH];
	assign l2_req_if_w[8] = &mem_req_ff[2-:3];
	assign l2_resp_if_bready = 1'sb1;
	always @(*) mem_req_nxt[3] = (w_fifo_empty ? 1'b0 : ((~mem_req_ff[3] | wlast_ff) & ~w_fifo_empty ? 1'b1 : mem_req_ff[3]));
	always @(*) mem_req_nxt[2-:3] = ((~mem_req_ff[3] | l2_req_if_w[8]) & l2_req_if_wready ? {rvh_l1d_pkg_L1D_BANK_OFFSET_WIDTH {1'b0}} : ((l2_req_if_wready & mem_req_ff[3]) & ~w_fifo_re_ff ? mem_req_ff[2-:3] + 1 : mem_req_ff[2-:3]));
	always @(posedge clk) wlast_ff <= (l2_req_if_wvalid & l2_req_if_w[8]) & l2_req_if_wready;
	always @(posedge clk) begin
		if (~rst) begin
			mem_req_ff[3] <= 1'sb0;
			mem_req_ff[2-:3] <= 1'sb0;
		end
		else
			mem_req_ff <= mem_req_nxt;
		aw_fifo_re_ff <= aw_fifo_re;
		w_fifo_re_ff <= w_fifo_re;
	end
endmodule
