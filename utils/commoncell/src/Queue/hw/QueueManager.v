module QueueManager (
	enq_fire_i,
	enq_eval_i,
	enq_tag_o,
	deq_fire_i,
	deq_eval_i,
	deq_tag_o,
	flush_i,
	clk,
	rstn
);
	parameter Depth = 8;
	parameter EnqWidth = 2;
	parameter DeqWidth = 2;
	parameter [0:0] FlagEnable = 0;
	parameter [0:0] EnqCollapse = 0;
	parameter [0:0] DeqCollapse = 0;
	parameter [0:0] InitFull = 0;
	localparam PtrWidth = $clog2(Depth);
	localparam CntWidth = $clog2(Depth + 1);
	localparam TagWidth = PtrWidth + (FlagEnable ? 1 : 0);
	input wire [EnqWidth - 1:0] enq_fire_i;
	input wire [EnqWidth - 1:0] enq_eval_i;
	output wire [(EnqWidth * TagWidth) - 1:0] enq_tag_o;
	input wire [DeqWidth - 1:0] deq_fire_i;
	input wire [DeqWidth - 1:0] deq_eval_i;
	output wire [(DeqWidth * TagWidth) - 1:0] deq_tag_o;
	input wire flush_i;
	input wire clk;
	input wire rstn;
	localparam EnqCountWidth = $clog2(EnqWidth + 1);
	localparam DeqCountWidth = $clog2(DeqWidth + 1);
	function automatic [TagWidth - 1:0] tagPlusOne;
		input [TagWidth - 1:0] originalTag;
		if (FlagEnable) begin
			if (originalTag[PtrWidth - 1:0] == (Depth - 1))
				tagPlusOne = {~originalTag[TagWidth - 1], {PtrWidth {1'b0}}};
			else
				tagPlusOne = originalTag + 1'b1;
		end
		else if (originalTag[PtrWidth - 1:0] == (Depth - 1))
			tagPlusOne = {PtrWidth {1'b0}};
		else
			tagPlusOne = originalTag + 1'b1;
	endfunction
	function automatic [TagWidth - 1:0] tagPlus;
		input [TagWidth - 1:0] originalTag;
		input [PtrWidth - 1:0] delta;
		reg [PtrWidth:0] sum;
		reg [PtrWidth:0] reverse_sum;
		if ((2 ** $clog2(Depth)) == Depth)
			tagPlus = originalTag + delta;
		else begin
			sum = $unsigned({1'b0, originalTag[PtrWidth - 1:0]}) + $unsigned({1'b0, delta});
			reverse_sum = $signed(sum) - $unsigned(Depth);
			if ($signed(reverse_sum) >= 0) begin
				if (FlagEnable)
					tagPlus = {~originalTag[TagWidth - 1], reverse_sum[PtrWidth - 1:0]};
				else
					tagPlus = reverse_sum[PtrWidth - 1:0];
			end
			else if (FlagEnable)
				tagPlus = {originalTag[TagWidth - 1], sum[PtrWidth - 1:0]};
			else
				tagPlus = sum[PtrWidth - 1:0];
		end
	endfunction
	wire enq_tag_clk_en;
	wire [EnqWidth - 1:0] enq_rdy_mask;
	wire [EnqWidth - 1:0] enq_collapse_rdy_mask;
	wire [EnqCountWidth - 1:0] enq_cnt;
	wire [PtrWidth - 1:0] enq_delta;
	reg [TagWidth - 1:0] enq_tag_d;
	reg [TagWidth - 1:0] enq_tag_q;
	wire deq_tag_clk_en;
	wire [DeqCountWidth - 1:0] deq_cnt;
	wire [PtrWidth - 1:0] deq_delta;
	reg [TagWidth - 1:0] deq_tag_d;
	reg [TagWidth - 1:0] deq_tag_q;
	assign enq_tag_clk_en = |enq_fire_i;
	assign deq_tag_clk_en = |deq_fire_i;
	assign enq_delta = {{PtrWidth - EnqCountWidth {1'b0}}, enq_cnt};
	assign deq_delta = {{PtrWidth - DeqCountWidth {1'b0}}, deq_cnt};
	genvar i;
	generate
		for (i = 0; i < EnqWidth; i = i + 1) begin : gen_enq_ptr
			if (i == 0) begin : gen_first_enq_ptr
				assign enq_tag_o[i * TagWidth+:TagWidth] = enq_tag_q;
			end
			else begin : gen_next_enq_ptr
				assign enq_tag_o[i * TagWidth+:TagWidth] = (EnqCollapse & ~enq_eval_i[i - 1] ? enq_tag_o[(i - 1) * TagWidth+:TagWidth] : tagPlusOne(enq_tag_o[(i - 1) * TagWidth+:TagWidth]));
			end
		end
		for (i = 0; i < DeqWidth; i = i + 1) begin : gen_deq_ptr
			if (i == 0) begin : gen_first_deq_ptr
				assign deq_tag_o[i * TagWidth+:TagWidth] = deq_tag_q;
			end
			else begin : gen_next_deq_ptr
				assign deq_tag_o[i * TagWidth+:TagWidth] = (DeqCollapse & ~deq_eval_i[i - 1] ? deq_tag_o[(i - 1) * TagWidth+:TagWidth] : tagPlusOne(deq_tag_o[(i - 1) * TagWidth+:TagWidth]));
			end
		end
	endgenerate
	always @(*) begin : enq_tag_update_logic
		enq_tag_d = enq_tag_q;
		if (enq_tag_clk_en)
			enq_tag_d = tagPlus(enq_tag_q, enq_delta);
		if (flush_i)
			if (InitFull & FlagEnable)
				enq_tag_d = {~deq_tag_q[TagWidth - 1], deq_tag_q[PtrWidth - 1:0]};
			else
				enq_tag_d = deq_tag_q;
	end
	always @(*) begin : deq_tag_update_logic
		deq_tag_d = deq_tag_q;
		if (deq_tag_clk_en)
			deq_tag_d = tagPlus(deq_tag_q, deq_delta);
		if (flush_i)
			deq_tag_d = deq_tag_q;
	end
	CountOne #(.InputWidth(EnqWidth)) u_enqCounter(
		.bits_i(enq_fire_i),
		.cnt_o(enq_cnt)
	);
	CountOne #(.InputWidth(DeqWidth)) u_deqCounter(
		.bits_i(deq_fire_i),
		.cnt_o(deq_cnt)
	);
	wire [TagWidth:1] sv2v_tmp_u_enq_tag_dff_Q;
	always @(*) enq_tag_q = sv2v_tmp_u_enq_tag_dff_Q;
	DFFRE #(.Width(TagWidth)) u_enq_tag_dff(
		.CLK(clk),
		.RSTN(rstn),
		.EN(enq_tag_clk_en | flush_i),
		.DRST({InitFull & FlagEnable, {TagWidth - 1 {1'b0}}}),
		.D(enq_tag_d),
		.Q(sv2v_tmp_u_enq_tag_dff_Q)
	);
	wire [TagWidth:1] sv2v_tmp_u_deq_tag_dff_Q;
	always @(*) deq_tag_q = sv2v_tmp_u_deq_tag_dff_Q;
	DFFRE #(.Width(TagWidth)) u_deq_tag_dff(
		.CLK(clk),
		.RSTN(rstn),
		.EN(deq_tag_clk_en | flush_i),
		.DRST({TagWidth {1'b0}}),
		.D(deq_tag_d),
		.Q(sv2v_tmp_u_deq_tag_dff_Q)
	);
endmodule
