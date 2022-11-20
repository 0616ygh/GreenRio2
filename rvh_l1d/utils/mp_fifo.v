module mp_fifo_727EB (
	enqueue_vld_i,
	enqueue_payload_i,
	enqueue_rdy_o,
	dequeue_vld_o,
	dequeue_payload_o,
	dequeue_rdy_i,
	flush_i,
	clk,
	rst
);
	parameter [31:0] ENQUEUE_WIDTH = 4;
	parameter [31:0] DEQUEUE_WIDTH = 4;
	parameter [31:0] DEPTH = 16;
	parameter [31:0] MUST_TAKEN_ALL = 1;
	input wire [ENQUEUE_WIDTH - 1:0] enqueue_vld_i;
	input wire [(ENQUEUE_WIDTH * 2) - 1:0] enqueue_payload_i;
	output wire [ENQUEUE_WIDTH - 1:0] enqueue_rdy_o;
	output wire [DEQUEUE_WIDTH - 1:0] dequeue_vld_o;
	output wire [(DEQUEUE_WIDTH * 2) - 1:0] dequeue_payload_o;
	input wire [DEQUEUE_WIDTH - 1:0] dequeue_rdy_i;
	input wire flush_i;
	input clk;
	input rst;
	localparam [31:0] ENTRY_PTR_WIDTH = $clog2(DEPTH);
	localparam [31:0] ENTRY_CNT_WIDTH = $clog2(DEPTH + 1);
	wire [(ENQUEUE_WIDTH * ENTRY_PTR_WIDTH) - 1:0] enq_ptr;
	wire [(DEQUEUE_WIDTH * ENTRY_PTR_WIDTH) - 1:0] deq_ptr;
	wire [ENTRY_CNT_WIDTH - 1:0] avail_cnt;
	reg [(DEPTH * 2) - 1:0] payload_dff;
	wire [ENQUEUE_WIDTH - 1:0] enq_fire;
	wire [DEQUEUE_WIDTH - 1:0] deq_fire;
	assign enq_fire = enqueue_vld_i & enqueue_rdy_o;
	assign deq_fire = dequeue_vld_o & dequeue_rdy_i;
	genvar i;
	generate
		for (i = 0; i < DEQUEUE_WIDTH; i = i + 1) begin : genblk1
			assign dequeue_payload_o[i * 2+:2] = payload_dff[deq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH] * 2+:2];
			assign dequeue_vld_o[i] = (DEPTH - avail_cnt) > i;
		end
		if (MUST_TAKEN_ALL) begin : genblk2
			assign enqueue_rdy_o = {ENQUEUE_WIDTH {avail_cnt >= ENQUEUE_WIDTH}};
		end
		else begin : genblk2
			genvar i;
			for (i = 0; i < ENQUEUE_WIDTH; i = i + 1) begin : genblk1
				assign enqueue_rdy_o[i] = avail_cnt > i;
			end
		end
	endgenerate
	always @(posedge clk) begin : payload_dff_update
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < ENQUEUE_WIDTH; i = i + 1)
				if (enq_fire[i])
					payload_dff[enq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH] * 2+:2] <= enqueue_payload_i[i * 2+:2];
		end
	end
	usage_manager #(
		.ENTRY_COUNT(DEPTH),
		.ENQ_WIDTH(ENQUEUE_WIDTH),
		.DEQ_WIDTH(DEQUEUE_WIDTH),
		.FLAG_EN(0),
		.INIT_IS_FULL(0),
		.COMB_DEQ_EN(0),
		.COMB_ENQ_EN(1)
	) u_usage_manager(
		.enq_fire_i(enq_fire),
		.deq_fire_i(deq_fire),
		.head_o(deq_ptr),
		.tail_o(enq_ptr),
		.avail_cnt_o(avail_cnt),
		.flush_i(flush_i),
		.clk(clk),
		.rst(rst)
	);
endmodule
module mp_fifo_F7963_2BE7D (
	enqueue_vld_i,
	enqueue_payload_i,
	enqueue_rdy_o,
	dequeue_vld_o,
	dequeue_payload_o,
	dequeue_rdy_i,
	flush_i,
	clk,
	rst
);
	parameter signed [31:0] payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE = 0;
	parameter [31:0] ENQUEUE_WIDTH = 4;
	parameter [31:0] DEQUEUE_WIDTH = 4;
	parameter [31:0] DEPTH = 16;
	parameter [31:0] MUST_TAKEN_ALL = 1;
	input wire [ENQUEUE_WIDTH - 1:0] enqueue_vld_i;
	input wire [(ENQUEUE_WIDTH * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE) - 1:0] enqueue_payload_i;
	output wire [ENQUEUE_WIDTH - 1:0] enqueue_rdy_o;
	output wire [DEQUEUE_WIDTH - 1:0] dequeue_vld_o;
	output wire [(DEQUEUE_WIDTH * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE) - 1:0] dequeue_payload_o;
	input wire [DEQUEUE_WIDTH - 1:0] dequeue_rdy_i;
	input wire flush_i;
	input clk;
	input rst;
	localparam [31:0] ENTRY_PTR_WIDTH = $clog2(DEPTH);
	localparam [31:0] ENTRY_CNT_WIDTH = $clog2(DEPTH + 1);
	wire [(ENQUEUE_WIDTH * ENTRY_PTR_WIDTH) - 1:0] enq_ptr;
	wire [(DEQUEUE_WIDTH * ENTRY_PTR_WIDTH) - 1:0] deq_ptr;
	wire [ENTRY_CNT_WIDTH - 1:0] avail_cnt;
	reg [(DEPTH * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE) - 1:0] payload_dff;
	wire [ENQUEUE_WIDTH - 1:0] enq_fire;
	wire [DEQUEUE_WIDTH - 1:0] deq_fire;
	assign enq_fire = enqueue_vld_i & enqueue_rdy_o;
	assign deq_fire = dequeue_vld_o & dequeue_rdy_i;
	genvar i;
	generate
		for (i = 0; i < DEQUEUE_WIDTH; i = i + 1) begin : genblk1
			assign dequeue_payload_o[i * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE+:payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE] = payload_dff[deq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH] * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE+:payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE];
			assign dequeue_vld_o[i] = (DEPTH - avail_cnt) > i;
		end
		if (MUST_TAKEN_ALL) begin : genblk2
			assign enqueue_rdy_o = {ENQUEUE_WIDTH {avail_cnt >= ENQUEUE_WIDTH}};
		end
		else begin : genblk2
			genvar i;
			for (i = 0; i < ENQUEUE_WIDTH; i = i + 1) begin : genblk1
				assign enqueue_rdy_o[i] = avail_cnt > i;
			end
		end
	endgenerate
	always @(posedge clk) begin : payload_dff_update
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < ENQUEUE_WIDTH; i = i + 1)
				if (enq_fire[i])
					payload_dff[enq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH] * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE+:payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE] <= enqueue_payload_i[i * payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE+:payload_t_rvh_l1d_pkg_L1D_BANK_LINE_DATA_SIZE];
		end
	end
	usage_manager #(
		.ENTRY_COUNT(DEPTH),
		.ENQ_WIDTH(ENQUEUE_WIDTH),
		.DEQ_WIDTH(DEQUEUE_WIDTH),
		.FLAG_EN(0),
		.INIT_IS_FULL(0),
		.COMB_DEQ_EN(0),
		.COMB_ENQ_EN(1)
	) u_usage_manager(
		.enq_fire_i(enq_fire),
		.deq_fire_i(deq_fire),
		.head_o(deq_ptr),
		.tail_o(enq_ptr),
		.avail_cnt_o(avail_cnt),
		.flush_i(flush_i),
		.clk(clk),
		.rst(rst)
	);
endmodule
