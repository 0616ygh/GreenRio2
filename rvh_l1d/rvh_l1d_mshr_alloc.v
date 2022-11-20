module rvh_l1d_mshr_alloc (
	mshr_bank_valid_i,
	mshr_id_o,
	has_free_mshr_o,
	free_mshr_num_o
);
	parameter [31:0] INPUT_NUM = 4;
	parameter [31:0] INPUT_NUM_W = (INPUT_NUM > 1 ? $clog2(INPUT_NUM) : 1);
	input wire [INPUT_NUM - 1:0] mshr_bank_valid_i;
	output wire [INPUT_NUM_W - 1:0] mshr_id_o;
	output wire has_free_mshr_o;
	output wire [INPUT_NUM_W:0] free_mshr_num_o;
	wire [INPUT_NUM - 1:0] mshr_bank_invalid;
	assign mshr_bank_invalid = ~mshr_bank_valid_i;
	priority_encoder #(.SEL_WIDTH(INPUT_NUM)) new_mshr_id_sel(
		.sel_i(mshr_bank_invalid),
		.id_vld_o(has_free_mshr_o),
		.id_o(mshr_id_o)
	);
	one_counter #(.DATA_WIDTH(INPUT_NUM)) free_mshr_counter_u(
		.data_i(mshr_bank_invalid),
		.cnt_o(free_mshr_num_o)
	);
endmodule
