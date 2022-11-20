module DFFR (
	CLK,
	RSTN,
	DRST,
	D,
	Q
);
	parameter Width = 8;
	input wire CLK;
	input wire RSTN;
	input wire [Width - 1:0] DRST;
	input wire [Width - 1:0] D;
	output reg [Width - 1:0] Q;
	always @(posedge CLK or negedge RSTN) begin : dff
		if (~RSTN)
			Q <= DRST;
		else
			Q <= D;
	end
endmodule
