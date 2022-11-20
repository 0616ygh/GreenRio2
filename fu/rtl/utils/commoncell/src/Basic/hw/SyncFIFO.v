module SyncFIFO (
	push_i,
	push_payload_i,
	pop_i,
	pop_payload_o,
	full_o,
	empty_o,
	flush_i,
	clk,
	rstn
);
	parameter Depth = 8;
	parameter WordWidth = 64;
	input wire push_i;
	input wire [WordWidth - 1:0] push_payload_i;
	input wire pop_i;
	output wire [WordWidth - 1:0] pop_payload_o;
	output wire full_o;
	output wire empty_o;
	input wire flush_i;
	input wire clk;
	input wire rstn;
	localparam PtrWidth = $clog2(Depth);
	wire [Depth - 1:0] payload_ram_clk_en;
	wire [(Depth * WordWidth) - 1:0] payload_ram_d;
	wire [(Depth * WordWidth) - 1:0] payload_ram_q;
	wire head_clk_en;
	reg head_flag_d;
	reg head_flag_q;
	reg [PtrWidth - 1:0] head_ptr_d;
	reg [PtrWidth - 1:0] head_ptr_q;
	wire tail_clk_en;
	reg tail_flag_d;
	reg tail_flag_q;
	reg [PtrWidth - 1:0] tail_ptr_d;
	reg [PtrWidth - 1:0] tail_ptr_q;
	wire ptr_equal;
	wire flag_equal;
	assign head_clk_en = pop_i | flush_i;
	assign tail_clk_en = push_i | flush_i;
	genvar i;
	generate
		for (i = 0; i < Depth; i = i + 1) begin : gen_payload_update_logic
			assign payload_ram_clk_en[i] = (push_i & ~flush_i) & (tail_ptr_q == i);
			assign payload_ram_d[i * WordWidth+:WordWidth] = (payload_ram_clk_en[i] ? push_payload_i : payload_ram_q[i * WordWidth+:WordWidth]);
		end
	endgenerate
	always @(*) begin : tail_update_logic
		{tail_flag_d, tail_ptr_d} = {tail_flag_q, tail_ptr_q};
		if (push_i)
			if (tail_ptr_q == (Depth - 1))
				{tail_flag_d, tail_ptr_d} = {~tail_flag_q, {PtrWidth {1'b0}}};
			else
				tail_ptr_d = tail_ptr_q + 1'b1;
		if (flush_i)
			{tail_flag_d, tail_ptr_d} = {PtrWidth + 1 {1'b0}};
	end
	always @(*) begin : head_update_logic
		{head_flag_d, head_ptr_d} = {head_flag_q, head_ptr_q};
		if (pop_i)
			if (head_ptr_q == (Depth - 1))
				{head_flag_d, head_ptr_d} = {~head_flag_q, {PtrWidth {1'b0}}};
			else
				head_ptr_d = head_ptr_q + 1'b1;
		if (flush_i)
			{head_flag_d, head_ptr_d} = {PtrWidth + 1 {1'b0}};
	end
	assign flag_equal = head_flag_q == tail_flag_q;
	assign ptr_equal = head_ptr_q == tail_ptr_q;
	assign full_o = (~flag_equal & ptr_equal) & ~pop_i;
	assign empty_o = flag_equal & ptr_equal;
	assign pop_payload_o = payload_ram_q[head_ptr_q * WordWidth+:WordWidth];
	wire [1 + PtrWidth:1] sv2v_tmp_u_head_dff_Q;
	always @(*) {head_flag_q, head_ptr_q} = sv2v_tmp_u_head_dff_Q;
	DFFRE #(.Width(PtrWidth + 1)) u_head_dff(
		.CLK(clk),
		.RSTN(rstn),
		.EN(head_clk_en),
		.DRST({PtrWidth + 1 {1'b0}}),
		.D({head_flag_d, head_ptr_d}),
		.Q(sv2v_tmp_u_head_dff_Q)
	);
	wire [1 + PtrWidth:1] sv2v_tmp_u_tail_dff_Q;
	always @(*) {tail_flag_q, tail_ptr_q} = sv2v_tmp_u_tail_dff_Q;
	DFFRE #(.Width(PtrWidth + 1)) u_tail_dff(
		.CLK(clk),
		.RSTN(rstn),
		.EN(tail_clk_en),
		.DRST({PtrWidth + 1 {1'b0}}),
		.D({tail_flag_d, tail_ptr_d}),
		.Q(sv2v_tmp_u_tail_dff_Q)
	);
	generate
		for (i = 0; i < Depth; i = i + 1) begin : gen_payload_dff
			DFFE #(.Width(WordWidth)) u_payload_dff(
				.CLK(clk),
				.EN(payload_ram_clk_en[i]),
				.D(payload_ram_d[i * WordWidth+:WordWidth]),
				.Q(payload_ram_q[i * WordWidth+:WordWidth])
			);
		end
	endgenerate
endmodule
