module DFFE (
	CLK,
	EN,
	D,
	Q
);
	parameter Width = 8;
	input wire CLK;
	input wire EN;
	input wire [Width - 1:0] D;
	output reg [Width - 1:0] Q;
	always @(posedge CLK) begin : dff
		if (EN)
			Q <= D;
	end
endmodule
