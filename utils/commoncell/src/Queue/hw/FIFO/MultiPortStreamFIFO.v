module MultiPortStreamFIFO (
	enq_vld_i,
	enq_payload_i,
	enq_rdy_o,
	deq_vld_o,
	deq_payload_o,
	deq_rdy_i,
	flush_i,
	clk,
	rstn
);
	parameter Depth = 8;
	parameter DataWidth = 32;
	parameter EnqWidth = 2;
	parameter DeqWidth = 2;
	parameter TakenAll = 0;
	input wire [EnqWidth - 1:0] enq_vld_i;
	input wire [(EnqWidth * DataWidth) - 1:0] enq_payload_i;
	output wire [EnqWidth - 1:0] enq_rdy_o;
	output wire [DeqWidth - 1:0] deq_vld_o;
	output wire [(DeqWidth * DataWidth) - 1:0] deq_payload_o;
	input wire [DeqWidth - 1:0] deq_rdy_i;
	input wire flush_i;
	input wire clk;
	input wire rstn;
	localparam PtrWidth = $clog2(Depth);
	reg [Depth - 1:0] payload_clk_en;
	reg [Depth - 1:0] vld_dff_d;
	reg [Depth - 1:0] vld_dff_q;
	reg [(Depth * DataWidth) - 1:0] payload_dff_d;
	reg [(Depth * DataWidth) - 1:0] payload_dff_q;
	wire [(EnqWidth * PtrWidth) - 1:0] enq_ptr;
	wire [(DeqWidth * PtrWidth) - 1:0] deq_ptr;
	wire [EnqWidth - 1:0] enq_rdy;
	wire [EnqWidth - 1:0] enq_fire;
	wire [DeqWidth - 1:0] deq_fire;
	assign enq_fire = enq_vld_i & enq_rdy_o;
	assign deq_fire = deq_vld_o & deq_rdy_i;
	always @(*) begin : vld_dff_update_logic
		vld_dff_d = vld_dff_q;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < EnqWidth; i = i + 1)
				if (enq_fire[i])
					vld_dff_d[enq_ptr[i * PtrWidth+:PtrWidth]] = 1'b1;
		end
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < DeqWidth; i = i + 1)
				if (deq_fire[i])
					vld_dff_d[deq_ptr[i * PtrWidth+:PtrWidth]] = 1'b0;
		end
		if (flush_i)
			vld_dff_d = {Depth {1'b0}};
	end
	always @(*) begin : payload_update_logic
		begin : sv2v_autoblock_3
			reg signed [31:0] i;
			for (i = 0; i < Depth; i = i + 1)
				begin : payload_init
					payload_clk_en[i] = 1'b0;
					payload_dff_d[i * DataWidth+:DataWidth] = payload_dff_q[i * DataWidth+:DataWidth];
				end
		end
		begin : sv2v_autoblock_4
			reg signed [31:0] i;
			for (i = 0; i < EnqWidth; i = i + 1)
				begin : enq_update
					if (enq_fire[i] & ~flush_i) begin
						payload_clk_en[enq_ptr[i * PtrWidth+:PtrWidth]] = 1'b1;
						payload_dff_d[enq_ptr[i * PtrWidth+:PtrWidth] * DataWidth+:DataWidth] = enq_payload_i[i * DataWidth+:DataWidth];
					end
				end
		end
	end
	generate
		if (TakenAll != 0) begin : gen_rdy_if_need_taken_all
			assign enq_rdy_o = {EnqWidth {&enq_rdy}};
		end
		else begin : gen_normal_rdy
			assign enq_rdy_o = enq_rdy;
		end
	endgenerate
	genvar i;
	generate
		for (i = 0; i < EnqWidth; i = i + 1) begin : gen_enq_rdy_logic
			assign enq_rdy[i] = ~vld_dff_q[enq_ptr[i * PtrWidth+:PtrWidth]];
		end
		for (i = 0; i < DeqWidth; i = i + 1) begin : gen_deq_logic
			assign deq_vld_o[i] = vld_dff_q[deq_ptr[i * PtrWidth+:PtrWidth]];
			assign deq_payload_o[i * DataWidth+:DataWidth] = payload_dff_q[deq_ptr[i * PtrWidth+:PtrWidth] * DataWidth+:DataWidth];
		end
	endgenerate
	wire [Depth:1] sv2v_tmp_u_vld_dff_Q;
	always @(*) vld_dff_q = sv2v_tmp_u_vld_dff_Q;
	DFFR #(.Width(Depth)) u_vld_dff(
		.CLK(clk),
		.RSTN(rstn),
		.DRST({Depth {1'b0}}),
		.D(vld_dff_d),
		.Q(sv2v_tmp_u_vld_dff_Q)
	);
	generate
		for (i = 0; i < Depth; i = i + 1) begin : gen_payload_dff
			wire [DataWidth * 1:1] sv2v_tmp_u_payload_dff_Q;
			always @(*) payload_dff_q[i * DataWidth+:DataWidth] = sv2v_tmp_u_payload_dff_Q;
			DFFE #(.Width(DataWidth)) u_payload_dff(
				.CLK(clk),
				.EN(payload_clk_en[i]),
				.D(payload_dff_d[i * DataWidth+:DataWidth]),
				.Q(sv2v_tmp_u_payload_dff_Q)
			);
		end
	endgenerate
	QueueManager #(
		.Depth(Depth),
		.EnqWidth(EnqWidth),
		.DeqWidth(DeqWidth),
		.FlagEnable(0),
		.EnqCollapse(1),
		.DeqCollapse(0),
		.InitFull(0)
	) u_QueueManager(
		.enq_fire_i(enq_fire),
		.enq_eval_i(enq_vld_i),
		.enq_tag_o(enq_ptr),
		.deq_fire_i(deq_fire),
		.deq_eval_i(deq_vld_o),
		.deq_tag_o(deq_ptr),
		.flush_i(flush_i),
		.clk(clk),
		.rstn(rstn)
	);
endmodule
