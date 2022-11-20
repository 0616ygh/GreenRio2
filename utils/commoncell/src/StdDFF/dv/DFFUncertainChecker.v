module DFFUncertainChecker (
	CLK,
	EN,
	Q
);
	parameter Width = 8;
	input wire CLK;
	input wire EN;
	input reg [Width - 1:0] Q;
endmodule
