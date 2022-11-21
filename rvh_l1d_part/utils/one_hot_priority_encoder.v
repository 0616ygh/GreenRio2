module one_hot_priority_encoder (
	sel_i,
	sel_o
);
	parameter [31:0] SEL_WIDTH = 8;
	input wire [SEL_WIDTH - 1:0] sel_i;
	output wire [SEL_WIDTH - 1:0] sel_o;
	localparam [31:0] SEL_ID_WIDHT = $clog2(SEL_WIDTH);
	wire [SEL_WIDTH - 1:0] sel_mask;
	assign sel_mask = (~sel_i + 1'b1) & sel_i;
	assign sel_o = sel_mask;
endmodule
