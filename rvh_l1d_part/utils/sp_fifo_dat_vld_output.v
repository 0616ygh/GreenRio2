module sp_fifo_dat_vld_output (
	enqueue_vld_i,
	enqueue_payload_i,
	enqueue_rdy_o,
	dequeue_vld_o,
	dequeue_payload_o,
	dequeue_rdy_i,
	payload_dff,
	payload_vld_dff,
	flush_i,
	clk,
	rst
);
	parameter signed [31:0] PAYLOAD_WIDTH = 3;
	parameter [31:0] DEPTH = 16;
	parameter [31:0] MUST_TAKEN_ALL = 1;
	input wire [0:0] enqueue_vld_i;
	input wire [PAYLOAD_WIDTH - 1:0] enqueue_payload_i;
	output wire [0:0] enqueue_rdy_o;
	output wire [0:0] dequeue_vld_o;
	output wire [PAYLOAD_WIDTH - 1:0] dequeue_payload_o;
	input wire [0:0] dequeue_rdy_i;
	output reg [(PAYLOAD_WIDTH * DEPTH) - 1:0] payload_dff;
	output reg [DEPTH - 1:0] payload_vld_dff;
	input wire flush_i;
	input clk;
	input rst;
	localparam [31:0] ENTRY_PTR_WIDTH = $clog2(DEPTH);
	localparam [31:0] ENTRY_CNT_WIDTH = $clog2(DEPTH + 1);
	wire [ENTRY_PTR_WIDTH - 1:0] enq_ptr;
	wire [ENTRY_PTR_WIDTH - 1:0] deq_ptr;
	wire [ENTRY_CNT_WIDTH - 1:0] avail_cnt;
	wire [0:0] enq_fire;
	wire [0:0] deq_fire;
	assign enq_fire = enqueue_vld_i & enqueue_rdy_o;
	assign deq_fire = dequeue_vld_o & dequeue_rdy_i;
	genvar i;
	generate
		for (i = 0; i < 1; i = i + 1) begin : genblk1
			assign dequeue_payload_o[i+:1] = payload_dff[deq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH] * DEPTH+:DEPTH];
			assign dequeue_vld_o[i] = (DEPTH - avail_cnt) > i;
		end
		if (MUST_TAKEN_ALL) begin : genblk2
			assign enqueue_rdy_o = {avail_cnt >= 32'sd1};
		end
		else begin : genblk2
			genvar i;
			for (i = 0; i < 1; i = i + 1) begin : genblk1
				assign enqueue_rdy_o[i] = avail_cnt > i;
			end
		end
	endgenerate
	always @(posedge clk) begin : payload_dff_update
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < 1; i = i + 1)
				if (enq_fire[i])
					payload_dff[enq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH] * DEPTH+:DEPTH] <= enqueue_payload_i[i+:1];
		end
	end
	always @(posedge clk) begin : payload_vld_dff_update
		if (rst)
			payload_vld_dff <= 1'sb0;
		else begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 1; i = i + 1)
				begin
					if (enq_fire[i])
						payload_vld_dff[enq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH]] <= 1'b1;
					if (deq_fire[i])
						payload_vld_dff[deq_ptr[i * ENTRY_PTR_WIDTH+:ENTRY_PTR_WIDTH]] <= 1'b0;
				end
		end
	end
	usage_manager #(
		.ENTRY_COUNT(DEPTH),
		.ENQ_WIDTH(1),
		.DEQ_WIDTH(1),
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
