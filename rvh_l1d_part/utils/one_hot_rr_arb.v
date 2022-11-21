module one_hot_rr_arb (
	req_i,
	update_i,
	grt_o,
	grt_idx_o,
	rstn,
	clk
);
	parameter N_INPUT = 2;
	localparam [31:0] N_INPUT_WIDTH = (N_INPUT > 1 ? $clog2(N_INPUT) : 1);
	localparam [31:0] IS_LOG2 = (2 ** N_INPUT_WIDTH) == N_INPUT;
	input wire [N_INPUT - 1:0] req_i;
	input wire update_i;
	output wire [N_INPUT - 1:0] grt_o;
	output wire [N_INPUT_WIDTH - 1:0] grt_idx_o;
	input wire rstn;
	input wire clk;
	wire req_vld;
	wire [(N_INPUT * 2) - 1:0] req_pre_shift;
	wire [(N_INPUT * 2) - 1:0] req_shift;
	wire [(N_INPUT * 2) - 1:0] reversed_dereordered_selected_req_pre_shift;
	wire [(N_INPUT * 2) - 1:0] reversed_dereordered_selected_req_shift;
	reg [N_INPUT - 1:0] reodered_req;
	wire [N_INPUT - 1:0] reordered_selected_req;
	reg [N_INPUT - 1:0] dereordered_selected_req;
	reg [N_INPUT - 1:0] reversed_reordered_selected_req;
	reg [N_INPUT - 1:0] reversed_dereordered_selected_req;
	reg [N_INPUT_WIDTH - 1:0] round_ptr_q;
	wire [N_INPUT_WIDTH - 1:0] round_ptr_d;
	wire [N_INPUT_WIDTH - 1:0] selected_req_idx;
	assign req_vld = update_i;
	always @(posedge clk)
		if (~rstn)
			round_ptr_q <= 1'sb0;
		else if (req_vld)
			round_ptr_q <= round_ptr_d;
	assign req_pre_shift = {{N_INPUT {1'b0}}, req_i};
	assign req_shift = req_pre_shift << round_ptr_q;
	always @(*) begin : reorder_req_for_sel
		if (round_ptr_q == {N_INPUT_WIDTH {1'sb0}})
			reodered_req = req_i;
		else
			reodered_req = req_shift[N_INPUT - 1:0] | req_shift[(N_INPUT * 2) - 1:N_INPUT];
	end
	always @(*) begin : reverse_reordered_selected_req
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < N_INPUT; i = i + 1)
				reversed_reordered_selected_req[i] = reordered_selected_req[(N_INPUT - 1) - i];
		end
	end
	assign reversed_dereordered_selected_req_pre_shift = {{N_INPUT {1'b0}}, reversed_reordered_selected_req};
	assign reversed_dereordered_selected_req_shift = reversed_dereordered_selected_req_pre_shift << round_ptr_q;
	always @(*) begin : dereorder_sel_for_output
		if (round_ptr_q == {N_INPUT_WIDTH {1'sb0}})
			reversed_dereordered_selected_req = reversed_reordered_selected_req;
		else
			reversed_dereordered_selected_req = reversed_dereordered_selected_req_shift[N_INPUT - 1:0] | reversed_dereordered_selected_req_shift[(N_INPUT * 2) - 1:N_INPUT];
	end
	always @(*) begin : reverse_reversed_dereordered_selected_req
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < N_INPUT; i = i + 1)
				dereordered_selected_req[i] = reversed_dereordered_selected_req[(N_INPUT - 1) - i];
		end
	end
	one_hot_priority_encoder #(.SEL_WIDTH(N_INPUT)) biased_one_hot_priority_encoder_u(
		.sel_i(reodered_req),
		.sel_o(reordered_selected_req)
	);
	wire [N_INPUT - 1:0] dereordered_selected_req_oh_to_all_one;
	assign dereordered_selected_req_oh_to_all_one = dereordered_selected_req - 1;
	one_counter #(.DATA_WIDTH(N_INPUT - 1)) oh_to_idx_u(
		.data_i(dereordered_selected_req_oh_to_all_one[N_INPUT - 2:0]),
		.cnt_o(selected_req_idx)
	);
	assign round_ptr_d = (selected_req_idx == (N_INPUT - 1) ? {N_INPUT_WIDTH {1'sb0}} : selected_req_idx + 1);
	assign grt_o = dereordered_selected_req;
	assign grt_idx_o = selected_req_idx;
endmodule
