module CountOne (
	bits_i,
	cnt_o
);
	parameter [31:0] InputWidth = 8;
	localparam CountWidth = $clog2(InputWidth + 1);
	input wire [InputWidth - 1:0] bits_i;
	output wire [CountWidth - 1:0] cnt_o;
	localparam PaddedWidth = 1 << $clog2(InputWidth);
	localparam ChildCountWidth = (PaddedWidth == 1 ? 1 : $clog2(PaddedWidth));
	wire [ChildCountWidth - 1:0] leftChildCount;
	wire [ChildCountWidth - 1:0] rightChildCount;
	generate
		if (InputWidth == 1) begin : gen_single_node
			assign leftChildCount = 1'b0;
			assign rightChildCount = bits_i;
		end
		else if (InputWidth == 2) begin : gen_leaf_node
			assign leftChildCount = bits_i[0];
			assign rightChildCount = bits_i[1];
		end
		else begin : gen_non_leaf_node
			wire [PaddedWidth - 1:0] paddedBits;
			assign paddedBits = {{PaddedWidth - InputWidth {1'b0}}, bits_i};
			CountOne #(.InputWidth(PaddedWidth / 2)) u_leftChild(
				.bits_i(paddedBits[PaddedWidth - 1:PaddedWidth / 2]),
				.cnt_o(leftChildCount)
			);
			CountOne #(.InputWidth(PaddedWidth / 2)) u_rightChild(
				.bits_i(paddedBits[(PaddedWidth / 2) - 1:0]),
				.cnt_o(rightChildCount)
			);
		end
	endgenerate
	assign cnt_o = leftChildCount + rightChildCount;
endmodule
