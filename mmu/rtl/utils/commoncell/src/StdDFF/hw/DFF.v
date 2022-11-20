module DFF (
	CLK,
	D,
	Q
);
	parameter Width = 8;
	input wire CLK;
	input wire [Width - 1:0] D;
	output reg [Width - 1:0] Q;
	always @(posedge CLK) begin : dff
		Q <= D;
	end
endmodule
