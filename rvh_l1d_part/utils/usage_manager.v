module usage_manager (
	enq_fire_i,
	deq_fire_i,
	head_o,
	tail_o,
	avail_cnt_o,
	flush_i,
	clk,
	rst
);
	parameter [31:0] ENTRY_COUNT = 8;
	parameter [31:0] ENQ_WIDTH = 2;
	parameter [31:0] DEQ_WIDTH = 2;
	parameter [31:0] FLAG_EN = 0;
	parameter [31:0] INIT_IS_FULL = 0;
	parameter [31:0] COMB_ENQ_EN = 0;
	parameter [31:0] COMB_DEQ_EN = 0;
	localparam [31:0] ENTRY_PTR_WIDTH = $clog2(ENTRY_COUNT);
	localparam [31:0] ENTRY_TAG_WIDTH = ENTRY_PTR_WIDTH + FLAG_EN;
	localparam [31:0] USAGE_CNT_WIDTH = $clog2(ENTRY_COUNT + 1);
	input wire [ENQ_WIDTH - 1:0] enq_fire_i;
	input wire [DEQ_WIDTH - 1:0] deq_fire_i;
	output reg [(DEQ_WIDTH * ENTRY_TAG_WIDTH) - 1:0] head_o;
	output reg [(ENQ_WIDTH * ENTRY_TAG_WIDTH) - 1:0] tail_o;
	output wire [USAGE_CNT_WIDTH - 1:0] avail_cnt_o;
	input wire flush_i;
	input clk;
	input rst;
	localparam [31:0] ENQ_CNT_WIDTH = $clog2(ENQ_WIDTH + 1);
	localparam [31:0] DEQ_CNT_WIDTH = $clog2(DEQ_WIDTH + 1);
	localparam [31:0] IS_2N = (2 ** ENTRY_PTR_WIDTH) == ENTRY_COUNT;
	function automatic [ENTRY_TAG_WIDTH - 1:0] head_ptr_plus;
		input reg [ENTRY_TAG_WIDTH - 1:0] head_ptr_i;
		input reg [DEQ_CNT_WIDTH - 1:0] plus_cnt_i;
		reg flag;
		reg [ENTRY_PTR_WIDTH - 1:0] index;
		reg [ENTRY_PTR_WIDTH:0] sum;
		reg [ENTRY_PTR_WIDTH:0] reverse_sum;
		if (IS_2N)
			head_ptr_plus = head_ptr_i + plus_cnt_i;
		else begin
			index = head_ptr_i[ENTRY_PTR_WIDTH - 1:0];
			flag = head_ptr_i[ENTRY_TAG_WIDTH - 1];
			sum = index + plus_cnt_i;
			reverse_sum = sum - ENTRY_COUNT;
			if (FLAG_EN) begin
				if (~reverse_sum[ENTRY_PTR_WIDTH])
					head_ptr_plus = {~flag, reverse_sum[ENTRY_PTR_WIDTH - 1:0]};
				else
					head_ptr_plus = {flag, sum[ENTRY_PTR_WIDTH - 1:0]};
			end
			else if (~reverse_sum[ENTRY_PTR_WIDTH])
				head_ptr_plus = reverse_sum[ENTRY_PTR_WIDTH - 1:0];
			else
				head_ptr_plus = sum[ENTRY_PTR_WIDTH - 1:0];
		end
	endfunction
	function automatic [ENTRY_TAG_WIDTH - 1:0] ptr_plus_one;
		input reg [ENTRY_TAG_WIDTH - 1:0] ptr_i;
		reg flag;
		reg [ENTRY_PTR_WIDTH - 1:0] index;
		reg reverse_flag;
		if (IS_2N)
			ptr_plus_one = ptr_i + 1'b1;
		else begin
			index = ptr_i[ENTRY_PTR_WIDTH - 1:0];
			flag = ptr_i[ENTRY_TAG_WIDTH - 1];
			if (index == (ENTRY_COUNT - 1)) begin
				index = {ENTRY_PTR_WIDTH {1'b0}};
				reverse_flag = ~flag;
			end
			else begin
				index = ptr_i + 1'b1;
				reverse_flag = flag;
			end
			if (FLAG_EN)
				ptr_plus_one = {reverse_flag, index};
			else
				ptr_plus_one = index;
		end
	endfunction
	function automatic [ENTRY_TAG_WIDTH - 1:0] tail_ptr_plus;
		input reg [ENTRY_TAG_WIDTH - 1:0] tail_ptr_i;
		input reg [ENQ_CNT_WIDTH - 1:0] plus_cnt_i;
		reg flag;
		reg [ENTRY_PTR_WIDTH - 1:0] index;
		reg [ENTRY_PTR_WIDTH:0] sum;
		reg [ENTRY_PTR_WIDTH:0] reverse_sum;
		if (IS_2N)
			tail_ptr_plus = tail_ptr_i + plus_cnt_i;
		else begin
			index = tail_ptr_i[ENTRY_PTR_WIDTH - 1:0];
			flag = tail_ptr_i[ENTRY_TAG_WIDTH - 1];
			sum = index + plus_cnt_i;
			reverse_sum = sum - ENTRY_COUNT;
			if (FLAG_EN) begin
				if (~reverse_sum[ENTRY_PTR_WIDTH])
					tail_ptr_plus = {~flag, reverse_sum[ENTRY_PTR_WIDTH - 1:0]};
				else
					tail_ptr_plus = {flag, sum[ENTRY_PTR_WIDTH - 1:0]};
			end
			else if (~reverse_sum[ENTRY_PTR_WIDTH])
				tail_ptr_plus = reverse_sum[ENTRY_PTR_WIDTH - 1:0];
			else
				tail_ptr_plus = sum[ENTRY_PTR_WIDTH - 1:0];
		end
	endfunction
	wire enq_clk_en;
	wire deq_clk_en;
	wire [ENQ_CNT_WIDTH - 1:0] enq_cnt;
	wire [DEQ_CNT_WIDTH - 1:0] deq_cnt;
	reg [ENTRY_TAG_WIDTH - 1:0] head_ptr_d;
	reg [ENTRY_TAG_WIDTH - 1:0] head_ptr_q;
	reg [ENTRY_TAG_WIDTH - 1:0] tail_ptr_d;
	reg [ENTRY_TAG_WIDTH - 1:0] tail_ptr_q;
	reg [USAGE_CNT_WIDTH - 1:0] avail_cnt_d;
	reg [USAGE_CNT_WIDTH - 1:0] avail_cnt_q;
	assign enq_clk_en = |enq_fire_i;
	assign deq_clk_en = |deq_fire_i;
	always @(*) begin : gen_head
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < DEQ_WIDTH; i = i + 1)
				if (i == 0)
					head_o[i * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH] = head_ptr_q;
				else if (COMB_DEQ_EN)
					head_o[i * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH] = (deq_fire_i[i - 1] ? ptr_plus_one(head_o[(i - 1) * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH]) : head_o[(i - 1) * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH]);
				else
					head_o[i * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH] = ptr_plus_one(head_o[(i - 1) * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH]);
		end
	end
	always @(*) begin : gen_tail
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < ENQ_WIDTH; i = i + 1)
				if (i == 0)
					tail_o[i * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH] = tail_ptr_q;
				else if (COMB_ENQ_EN)
					tail_o[i * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH] = (enq_fire_i[i - 1] ? ptr_plus_one(tail_o[(i - 1) * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH]) : tail_o[(i - 1) * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH]);
				else
					tail_o[i * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH] = ptr_plus_one(tail_o[(i - 1) * ENTRY_TAG_WIDTH+:ENTRY_TAG_WIDTH]);
		end
	end
	assign avail_cnt_o = avail_cnt_q;
	always @(*) begin : head_ptr_update
		head_ptr_d = head_ptr_q;
		if (deq_clk_en)
			head_ptr_d = head_ptr_plus(head_ptr_q, deq_cnt);
		if (flush_i)
			head_ptr_d = head_ptr_q;
	end
	always @(*) begin : tail_ptr_update
		tail_ptr_d = tail_ptr_q;
		if (enq_clk_en)
			tail_ptr_d = tail_ptr_plus(tail_ptr_q, enq_cnt);
		if (flush_i)
			if ((INIT_IS_FULL == 1) && (FLAG_EN == 1))
				tail_ptr_d = {~head_ptr_q[ENTRY_TAG_WIDTH - 1], head_ptr_q[ENTRY_PTR_WIDTH - 1:0]};
			else
				tail_ptr_d = head_ptr_q;
	end
	always @(*) begin : avail_cnt_update
		avail_cnt_d = avail_cnt_q;
		if (enq_clk_en)
			avail_cnt_d = avail_cnt_q - enq_cnt;
		if (deq_clk_en)
			avail_cnt_d = avail_cnt_q + deq_cnt;
		if (enq_clk_en & deq_clk_en)
			avail_cnt_d = (avail_cnt_q + deq_cnt) - enq_cnt;
		if (flush_i)
			if (INIT_IS_FULL)
				avail_cnt_d = {USAGE_CNT_WIDTH {1'b0}};
			else
				avail_cnt_d = ENTRY_COUNT[USAGE_CNT_WIDTH - 1:0];
	end
	always @(posedge clk) begin : head_ptr_dff
		if (rst)
			head_ptr_q <= {ENTRY_TAG_WIDTH {1'b0}};
		else if (deq_clk_en | flush_i)
			head_ptr_q <= head_ptr_d;
	end
	always @(posedge clk) begin : tail_ptr_dff
		if (rst) begin
			if (INIT_IS_FULL & FLAG_EN)
				tail_ptr_q <= {1'b1, {ENTRY_PTR_WIDTH {1'b0}}};
			else
				tail_ptr_q <= {ENTRY_TAG_WIDTH {1'b0}};
		end
		else if (enq_clk_en | flush_i)
			tail_ptr_q <= tail_ptr_d;
	end
	always @(posedge clk) begin : avail_cnt_dff
		if (rst) begin
			if (INIT_IS_FULL)
				avail_cnt_q <= {USAGE_CNT_WIDTH {1'b0}};
			else
				avail_cnt_q <= ENTRY_COUNT[USAGE_CNT_WIDTH - 1:0];
		end
		else if ((enq_clk_en | deq_clk_en) | flush_i)
			avail_cnt_q <= avail_cnt_d;
	end
	one_counter #(.DATA_WIDTH(ENQ_WIDTH)) u_enq_one_counter(
		.data_i(enq_fire_i),
		.cnt_o(enq_cnt)
	);
	one_counter #(.DATA_WIDTH(DEQ_WIDTH)) u_deq_one_counter(
		.data_i(deq_fire_i),
		.cnt_o(deq_cnt)
	);
endmodule
