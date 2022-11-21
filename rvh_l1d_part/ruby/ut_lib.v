module LFSR (
	i_Clk,
	i_Enable,
	i_Seed_DV,
	i_Seed_Data,
	o_LFSR_Data,
	o_LFSR_Done
);
	parameter NUM_BITS = 0;
	input i_Clk;
	input i_Enable;
	input i_Seed_DV;
	input [NUM_BITS - 1:0] i_Seed_Data;
	output wire [NUM_BITS - 1:0] o_LFSR_Data;
	output wire o_LFSR_Done;
	reg [NUM_BITS:1] r_LFSR = 0;
	reg r_XNOR;
	always @(posedge i_Clk or negedge i_Enable)
		if (~i_Enable)
			r_LFSR <= i_Seed_Data;
		else if (i_Seed_DV == 1'b1)
			r_LFSR <= i_Seed_Data;
		else
			r_LFSR <= {r_LFSR[NUM_BITS - 1:1], r_XNOR};
	always @(*)
		case (NUM_BITS)
			2: r_XNOR = r_LFSR[2] ^ ~r_LFSR[1];
			3: r_XNOR = r_LFSR[3] ^ ~r_LFSR[2];
			4: r_XNOR = r_LFSR[4] ^ ~r_LFSR[3];
			5: r_XNOR = r_LFSR[5] ^ ~r_LFSR[3];
			6: r_XNOR = r_LFSR[6] ^ ~r_LFSR[5];
			7: r_XNOR = r_LFSR[7] ^ ~r_LFSR[6];
			8: r_XNOR = ((r_LFSR[8] ^ ~r_LFSR[6]) ^ ~r_LFSR[5]) ^ ~r_LFSR[4];
			9: r_XNOR = r_LFSR[9] ^ ~r_LFSR[5];
			10: r_XNOR = r_LFSR[10] ^ ~r_LFSR[7];
			11: r_XNOR = r_LFSR[11] ^ ~r_LFSR[9];
			12: r_XNOR = ((r_LFSR[12] ^ ~r_LFSR[6]) ^ ~r_LFSR[4]) ^ ~r_LFSR[1];
			13: r_XNOR = ((r_LFSR[13] ^ ~r_LFSR[4]) ^ ~r_LFSR[3]) ^ ~r_LFSR[1];
			14: r_XNOR = ((r_LFSR[14] ^ ~r_LFSR[5]) ^ ~r_LFSR[3]) ^ ~r_LFSR[1];
			15: r_XNOR = r_LFSR[15] ^ ~r_LFSR[14];
			16: r_XNOR = ((r_LFSR[16] ^ ~r_LFSR[15]) ^ ~r_LFSR[13]) ^ ~r_LFSR[4];
			17: r_XNOR = r_LFSR[17] ^ ~r_LFSR[14];
			18: r_XNOR = r_LFSR[18] ^ ~r_LFSR[11];
			19: r_XNOR = ((r_LFSR[19] ^ ~r_LFSR[6]) ^ ~r_LFSR[2]) ^ ~r_LFSR[1];
			20: r_XNOR = r_LFSR[20] ^ ~r_LFSR[17];
			21: r_XNOR = r_LFSR[21] ^ ~r_LFSR[19];
			22: r_XNOR = r_LFSR[22] ^ ~r_LFSR[21];
			23: r_XNOR = r_LFSR[23] ^ ~r_LFSR[18];
			24: r_XNOR = ((r_LFSR[24] ^ ~r_LFSR[23]) ^ ~r_LFSR[22]) ^ ~r_LFSR[17];
			25: r_XNOR = r_LFSR[25] ^ ~r_LFSR[22];
			26: r_XNOR = ((r_LFSR[26] ^ ~r_LFSR[6]) ^ ~r_LFSR[2]) ^ ~r_LFSR[1];
			27: r_XNOR = ((r_LFSR[27] ^ ~r_LFSR[5]) ^ ~r_LFSR[2]) ^ ~r_LFSR[1];
			28: r_XNOR = r_LFSR[28] ^ ~r_LFSR[25];
			29: r_XNOR = r_LFSR[29] ^ ~r_LFSR[27];
			30: r_XNOR = ((r_LFSR[30] ^ ~r_LFSR[6]) ^ ~r_LFSR[4]) ^ ~r_LFSR[1];
			31: r_XNOR = r_LFSR[31] ^ ~r_LFSR[28];
			32: r_XNOR = ((r_LFSR[32] ^ ~r_LFSR[22]) ^ ~r_LFSR[2]) ^ ~r_LFSR[1];
			default: r_XNOR = 1'sb0;
		endcase
	assign o_LFSR_Data = r_LFSR[NUM_BITS:1];
	assign o_LFSR_Done = (r_LFSR[NUM_BITS:1] == i_Seed_Data ? 1'b1 : 1'b0);
endmodule
module id_pool_2w1r (
	clk,
	rst_n,
	c_srdy,
	c_drdy,
	c_data,
	p_srdy,
	p_drdy,
	p_data,
	usage
);
	parameter depth = 8;
	parameter width = 32;
	parameter ptr_sz = $clog2(depth);
	input wire clk;
	input wire rst_n;
	input wire [1:0] c_srdy;
	output wire [1:0] c_drdy;
	input wire [(2 * width) - 1:0] c_data;
	output wire p_srdy;
	input wire p_drdy;
	output wire [width - 1:0] p_data;
	output wire [ptr_sz:0] usage;
	localparam depth_sub_1 = depth - 1;
	localparam depth_sub_2 = depth - 2;
	wire [ptr_sz - 1:0] wr_addr_d;
	wire [ptr_sz - 1:0] rd_addr_d;
	wire [ptr_sz - 1:0] wr_addr_q;
	wire [ptr_sz - 1:0] rd_addr_q;
	wire [(depth * width) - 1:0] array_d;
	wire [(depth * width) - 1:0] array_q;
	reg [ptr_sz:0] occupy_cnt_d;
	wire [ptr_sz:0] occupy_cnt_q;
	wire full;
	wire empty;
	wire wr_2_en;
	wire wr_2_vld;
	wire wr_en;
	wire rd_en;
	wire [ptr_sz - 1:0] wr_addr_p1;
	assign c_drdy = (wr_2_vld ? 2'b11 : (occupy_cnt_q == depth_sub_1 ? (c_srdy == 2'b10 ? 2'b10 : 2'b01) : {2 {1'sb0}}));
	assign p_srdy = ~empty;
	assign p_data = array_q[rd_addr_q * width+:width];
	assign empty = occupy_cnt_q == {(ptr_sz >= 0 ? ptr_sz + 1 : 1 - ptr_sz) {1'sb0}};
	assign full = occupy_cnt_q == depth[ptr_sz:0];
	assign rd_en = p_drdy & ~empty;
	assign wr_en = (c_srdy[0] | c_srdy[1]) & ~full;
	assign wr_2_vld = occupy_cnt_q < depth_sub_1;
	assign wr_2_en = (c_srdy == 2'b11) & wr_2_vld;
	assign rd_addr_d = (rd_en ? (rd_addr_q == depth_sub_1 ? {ptr_sz {1'sb0}} : rd_addr_q + 1) : rd_addr_q);
	assign wr_addr_p1 = (wr_addr_q == depth_sub_1 ? {ptr_sz {1'sb0}} : wr_addr_q + 1);
	function automatic [ptr_sz - 1:0] sv2v_cast_08270;
		input reg [ptr_sz - 1:0] inp;
		sv2v_cast_08270 = inp;
	endfunction
	assign wr_addr_d = (wr_2_en ? (wr_addr_q == depth_sub_1 ? sv2v_cast_08270('d1) : (wr_addr_q == depth_sub_2 ? {ptr_sz {1'sb0}} : wr_addr_q + 2)) : (wr_en ? wr_addr_p1 : wr_addr_q));
	always @(*) begin
		occupy_cnt_d = occupy_cnt_q;
		case ({wr_2_en, wr_en, rd_en})
			3'b110: occupy_cnt_d = occupy_cnt_q + {{ptr_sz - 1 {1'b0}}, 2'd2};
			3'b111: occupy_cnt_d = occupy_cnt_q + {{ptr_sz {1'b0}}, 1'b1};
			3'b010: occupy_cnt_d = occupy_cnt_q + {{ptr_sz {1'b0}}, 1'b1};
			3'b001: occupy_cnt_d = occupy_cnt_q - {{ptr_sz {1'b0}}, 1'b1};
		endcase
	end
	std_dffr #(.WIDTH(ptr_sz)) FF_WR_ADDR(
		.clk(clk),
		.rstn(rst_n),
		.d(wr_addr_d),
		.q(wr_addr_q)
	);
	std_dffr #(.WIDTH(ptr_sz)) FF_RD_ADDR(
		.clk(clk),
		.rstn(rst_n),
		.d(rd_addr_d),
		.q(rd_addr_q)
	);
	std_dffrve #(.WIDTH(ptr_sz + 1)) FF_OCCUPY_CNT(
		.clk(clk),
		.rstn(rst_n),
		.rst_val(depth),
		.en(1'b1),
		.d(occupy_cnt_d),
		.q(occupy_cnt_q)
	);
	genvar ii;
	generate
		for (ii = 0; ii < depth; ii = ii + 1) begin : genblk1
			assign array_d[ii * width+:width] = ((wr_addr_q == ii[ptr_sz - 1:0]) & wr_en ? (c_srdy[0] ? c_data[0+:width] : c_data[width+:width]) : ((wr_addr_p1 == ii[ptr_sz - 1:0]) & wr_2_en ? c_data[width+:width] : array_q[ii * width+:width]));
			std_dffrve #(.WIDTH(width)) FF_ARRAY(
				.clk(clk),
				.rstn(rst_n),
				.rst_val(ii),
				.en(1'b1),
				.d(array_d[ii * width+:width]),
				.q(array_q[ii * width+:width])
			);
		end
	endgenerate
	assign usage = occupy_cnt_q;
endmodule
