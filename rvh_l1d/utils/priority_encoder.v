module priority_encoder (
	sel_i,
	id_vld_o,
	id_o
);
	parameter [31:0] SEL_WIDTH = 8;
	localparam [31:0] SEL_ID_WIDHT = (SEL_WIDTH > 1 ? $clog2(SEL_WIDTH) : 1);
	input wire [SEL_WIDTH - 1:0] sel_i;
	output wire id_vld_o;
	output wire [SEL_ID_WIDHT - 1:0] id_o;
	generate
		if (SEL_WIDTH == 1) begin : genblk1
			assign id_vld_o = sel_i;
			assign id_o = 1'b0;
		end
		else begin : genblk1
			wire [SEL_WIDTH - 1:0] sel_mask;
			wire [SEL_ID_WIDHT + 0:0] sel_result;
			assign sel_mask = ((~sel_i + 1'b1) & sel_i) - 1'b1;
			one_counter #(.DATA_WIDTH(SEL_WIDTH)) one_counter_u(
				.data_i(sel_mask),
				.cnt_o(sel_result)
			);
			assign id_o = sel_result[SEL_ID_WIDHT - 1:0];
			assign id_vld_o = |sel_i;
		end
	endgenerate
endmodule
