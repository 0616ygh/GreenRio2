module MuxOH (
	sel_i,
	data_i,
	data_o
);
	parameter InputWidth = 8;
	parameter DataWidth = 8;
	input wire [InputWidth - 1:0] sel_i;
	input wire [(InputWidth * DataWidth) - 1:0] data_i;
	output wire [DataWidth - 1:0] data_o;
	wire [(DataWidth * InputWidth) - 1:0] dataT;
	genvar i;
	generate
		for (i = 0; i < DataWidth; i = i + 1) begin : gen_row
			genvar j;
			for (j = 0; j < InputWidth; j = j + 1) begin : gen_col
				assign dataT[(i * InputWidth) + j] = data_i[(j * DataWidth) + i];
			end
			assign data_o[i] = |(dataT[i * InputWidth+:InputWidth] & sel_i);
		end
	endgenerate
endmodule
