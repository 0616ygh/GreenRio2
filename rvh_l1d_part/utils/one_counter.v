module one_counter (
	data_i,
	cnt_o
);
	parameter [31:0] DATA_WIDTH = 8;
	localparam [31:0] CNT_WIDTH = $clog2(DATA_WIDTH) + 1;
	input wire [DATA_WIDTH - 1:0] data_i;
	output wire [CNT_WIDTH - 1:0] cnt_o;
	localparam [31:0] PADDED_DATA_WIDTH = 1 << $clog2(DATA_WIDTH);
	reg [PADDED_DATA_WIDTH - 1:0] padded_data;
	always @(*) begin
		padded_data = {PADDED_DATA_WIDTH {1'b0}};
		padded_data[DATA_WIDTH - 1:0] = data_i;
	end
	generate
		if (DATA_WIDTH == 1) begin : genblk1
			assign cnt_o = data_i;
		end
		else begin : genblk1
			wire [CNT_WIDTH - 2:0] res_left;
			wire [CNT_WIDTH - 2:0] res_right;
			assign cnt_o = res_left + res_right;
			one_counter #(.DATA_WIDTH(PADDED_DATA_WIDTH / 2)) one_counter_left_u(
				.data_i(padded_data[PADDED_DATA_WIDTH - 1:PADDED_DATA_WIDTH / 2]),
				.cnt_o(res_left)
			);
			one_counter #(.DATA_WIDTH(PADDED_DATA_WIDTH / 2)) one_counter_right_u(
				.data_i(padded_data[(PADDED_DATA_WIDTH / 2) - 1:0]),
				.cnt_o(res_right)
			);
		end
	endgenerate
endmodule
