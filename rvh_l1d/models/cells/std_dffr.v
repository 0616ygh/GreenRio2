module std_dffr (
	clk,
	rstn,
	d,
	q
);
	parameter WIDTH = 8;
	input clk;
	input rstn;
	input [WIDTH - 1:0] d;
	output wire [WIDTH - 1:0] q;
	reg [WIDTH - 1:0] dff_q;
	always @(posedge clk or negedge rstn)
		if (~rstn)
			dff_q <= {WIDTH {1'b0}};
		else
			dff_q <= d;
	assign q = dff_q;
endmodule
