module std_dffre (
	clk,
	rstn,
	en,
	d,
	q
);
	parameter WIDTH = 8;
	input clk;
	input rstn;
	input en;
	input [WIDTH - 1:0] d;
	output wire [WIDTH - 1:0] q;
	reg [WIDTH - 1:0] dff_q;
	always @(posedge clk or negedge rstn)
		if (~rstn)
			dff_q <= {WIDTH {1'b0}};
		else if (en)
			dff_q <= d;
	assign q = dff_q;
endmodule
