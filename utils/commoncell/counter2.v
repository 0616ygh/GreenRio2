module counter2 (
	clk,
	rst,
	cnt_add_flag_i,
	cnt_rst_vector_i,
	cnt_set_flag_i,
	cnt_set_vector_i,
	cnt_o,
	cnt_end_o
);
	parameter CNT_SIZE = 40;
	parameter CNT_SIZE_WIDTH = 6;
	input clk;
	input rst;
	input cnt_add_flag_i;
	input [CNT_SIZE_WIDTH - 1:0] cnt_rst_vector_i;
	input cnt_set_flag_i;
	input [CNT_SIZE_WIDTH - 1:0] cnt_set_vector_i;
	output wire [CNT_SIZE_WIDTH - 1:0] cnt_o;
	output wire cnt_end_o;
	wire cnt_start;
	reg [CNT_SIZE_WIDTH - 1:0] cnt_r;
	assign cnt_o = cnt_r;
	always @(posedge clk)
		if (rst)
			cnt_r <= cnt_rst_vector_i;
		else if (cnt_set_flag_i)
			cnt_r <= cnt_set_vector_i;
		else if (cnt_add_flag_i)
			if (cnt_end_o)
				cnt_r <= 0;
			else
				cnt_r <= cnt_r + 1;
	assign cnt_end_o = cnt_o == (CNT_SIZE - 1);
	assign cnt_start = cnt_o == 0;
endmodule
