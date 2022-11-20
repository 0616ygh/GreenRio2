module std_dffrve (
	clk,
	rstn,
	rst_val,
	en,
	d,
	q
);
	parameter WIDTH = 8;
	input clk;
	input rstn;
	input [WIDTH - 1:0] rst_val;
	input en;
	input [WIDTH - 1:0] d;
	output wire [WIDTH - 1:0] q;
	reg [WIDTH - 1:0] dff_q;
	always @(posedge clk or negedge rstn)
		if (~rstn)
			dff_q <= rst_val;
		else if (en)
			dff_q <= d;
	assign q = dff_q;
endmodule
