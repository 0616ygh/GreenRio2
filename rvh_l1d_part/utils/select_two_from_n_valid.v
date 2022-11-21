module select_two_from_n_valid (
	sel_i,
	first_id_needed_vld_i,
	second_id_needed_vld_i,
	first_id_vld_o,
	second_id_vld_o,
	first_id_o,
	second_id_o
);
	parameter [31:0] SEL_WIDTH = 8;
	localparam [31:0] SEL_ID_WIDHT = (SEL_WIDTH > 1 ? $clog2(SEL_WIDTH) : 1);
	input wire [SEL_WIDTH - 1:0] sel_i;
	input wire first_id_needed_vld_i;
	input wire second_id_needed_vld_i;
	output wire first_id_vld_o;
	output wire second_id_vld_o;
	output wire [SEL_ID_WIDHT - 1:0] first_id_o;
	output wire [SEL_ID_WIDHT - 1:0] second_id_o;
	genvar i;
	wire [SEL_WIDTH - 1:0] sel_rev;
	wire first_id_vld_mid;
	wire secondid_vld_mid;
	wire [SEL_ID_WIDHT - 1:0] first_id_mid;
	wire [SEL_ID_WIDHT - 1:0] second_id_mid;
	wire [SEL_ID_WIDHT - 1:0] second_id_mid_comp;
	generate
		for (i = 0; i < SEL_WIDTH; i = i + 1) begin : sel_rev_gen
			assign sel_rev[i] = sel_i[(SEL_WIDTH - 1) - i];
		end
	endgenerate
	priority_encoder #(.SEL_WIDTH(SEL_WIDTH)) first_vld_sel_u(
		.sel_i(sel_i),
		.id_vld_o(first_id_vld_mid),
		.id_o(first_id_mid)
	);
	priority_encoder #(.SEL_WIDTH(SEL_WIDTH)) second_vld_sel_u(
		.sel_i(sel_rev),
		.id_vld_o(secondid_vld_mid),
		.id_o(second_id_mid)
	);
	function automatic [SEL_ID_WIDHT - 1:0] sv2v_cast_E21E7;
		input reg [SEL_ID_WIDHT - 1:0] inp;
		sv2v_cast_E21E7 = inp;
	endfunction
	assign second_id_mid_comp = sv2v_cast_E21E7((SEL_WIDTH - 1) - second_id_mid);
	assign first_id_vld_o = first_id_vld_mid & first_id_needed_vld_i;
	assign second_id_vld_o = (secondid_vld_mid & (~(first_id_mid == second_id_mid_comp) | ~first_id_needed_vld_i)) & second_id_needed_vld_i;
	assign first_id_o = first_id_mid;
	assign second_id_o = second_id_mid_comp;
endmodule
