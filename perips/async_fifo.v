module async_fifo (
	wr_clk,
	wr_reset_n,
	wr_en,
	wr_data,
	full,
	afull,
	rd_clk,
	rd_reset_n,
	rd_en,
	empty,
	aempty,
	rd_data
);
	parameter W = 4'd8;
	parameter DP = 3'd4;
	parameter WR_FAST = 1'b1;
	parameter RD_FAST = 1'b1;
	parameter FULL_DP = DP;
	parameter EMPTY_DP = 1'b0;
	parameter AW = (DP == 2 ? 1 : (DP == 4 ? 2 : (DP == 8 ? 3 : (DP == 16 ? 4 : (DP == 32 ? 5 : (DP == 64 ? 6 : (DP == 128 ? 7 : (DP == 256 ? 8 : 0))))))));
	output wire [W - 1:0] rd_data;
	input [W - 1:0] wr_data;
	input wr_clk;
	input wr_reset_n;
	input wr_en;
	input rd_clk;
	input rd_reset_n;
	input rd_en;
	output wire full;
	output wire empty;
	output wire afull;
	output wire aempty;
	// initial if (AW == 0)
	// 	$display("%m : ERROR!!! Fifo depth %d not in range 2 to 256", DP);
	reg [W - 1:0] mem [DP - 1:0];
	reg [AW:0] sync_rd_ptr_0;
	reg [AW:0] sync_rd_ptr_1;
	wire [AW:0] sync_rd_ptr;
	reg [AW:0] wr_ptr;
	reg [AW:0] grey_wr_ptr;
	reg [AW:0] grey_rd_ptr;
	reg full_q;
	wire full_c;
	wire afull_c;
	wire [AW:0] wr_ptr_inc = wr_ptr + 1'b1;
	function [AW:0] get_cnt;
		input [AW:0] wr_ptr;
		input [AW:0] rd_ptr;
		if (wr_ptr >= rd_ptr)
			get_cnt = wr_ptr - rd_ptr;
		else
			get_cnt = (DP * 2) - (rd_ptr - wr_ptr);
	endfunction
	wire [AW:0] wr_cnt = get_cnt(wr_ptr, sync_rd_ptr);
	assign full_c = (wr_cnt == FULL_DP ? 1'b1 : 1'b0);
	assign afull_c = (wr_cnt == (FULL_DP - 1) ? 1'b1 : 1'b0);
	function [1:0] do_grey;
		input [2:0] bin;
		if (bin[2])
			case (bin[1:0])
				2'b00: do_grey = 2'b10;
				2'b01: do_grey = 2'b11;
				2'b10: do_grey = 2'b01;
				2'b11: do_grey = 2'b00;
			endcase
		else
			case (bin[1:0])
				2'b00: do_grey = 2'b00;
				2'b01: do_grey = 2'b01;
				2'b10: do_grey = 2'b11;
				2'b11: do_grey = 2'b10;
			endcase
	endfunction
	function [AW:0] bin2grey;
		input [AW:0] bin;
		reg [8:0] bin_8;
		reg [8:0] grey_8;
		begin
			bin_8 = bin;
			grey_8[1:0] = do_grey(bin_8[2:0]);
			grey_8[3:2] = do_grey(bin_8[4:2]);
			grey_8[5:4] = do_grey(bin_8[6:4]);
			grey_8[7:6] = do_grey(bin_8[8:6]);
			grey_8[8] = bin_8[8];
			bin2grey = grey_8[AW:0];
		end
	endfunction
	always @(posedge wr_clk or negedge wr_reset_n)
		if (!wr_reset_n) begin
			wr_ptr <= 0;
			grey_wr_ptr <= 0;
			full_q <= 0;
		end
		else if (wr_en) begin
			wr_ptr <= wr_ptr_inc;
			grey_wr_ptr <= bin2grey(wr_ptr_inc);
			if (wr_cnt == (FULL_DP - 1))
				full_q <= 1'b1;
		end
		else if (full_q && (wr_cnt < FULL_DP))
			full_q <= 1'b0;
	assign full = (WR_FAST == 1 ? full_c : full_q);
	assign afull = afull_c;
	always @(posedge wr_clk)
		if (wr_en)
			mem[wr_ptr[AW - 1:0]] <= wr_data;
	wire [AW:0] grey_rd_ptr_dly;
	// assign #(1) grey_rd_ptr_dly = grey_rd_ptr;
	assign grey_rd_ptr_dly = grey_rd_ptr;
	always @(posedge wr_clk or negedge wr_reset_n)
		if (!wr_reset_n) begin
			sync_rd_ptr_0 <= 0;
			sync_rd_ptr_1 <= 0;
		end
		else begin
			sync_rd_ptr_0 <= grey_rd_ptr_dly;
			sync_rd_ptr_1 <= sync_rd_ptr_0;
		end
	function [1:0] do_bin;
		input [2:0] grey;
		if (grey[2])
			case (grey[1:0])
				2'b10: do_bin = 2'b00;
				2'b11: do_bin = 2'b01;
				2'b01: do_bin = 2'b10;
				2'b00: do_bin = 2'b11;
			endcase
		else
			case (grey[1:0])
				2'b00: do_bin = 2'b00;
				2'b01: do_bin = 2'b01;
				2'b11: do_bin = 2'b10;
				2'b10: do_bin = 2'b11;
			endcase
	endfunction
	function [AW:0] grey2bin;
		input [AW:0] grey;
		reg [8:0] grey_8;
		reg [8:0] bin_8;
		begin
			grey_8 = grey;
			bin_8[8] = grey_8[8];
			bin_8[7:6] = do_bin({bin_8[8], grey_8[7:6]});
			bin_8[5:4] = do_bin({bin_8[6], grey_8[5:4]});
			bin_8[3:2] = do_bin({bin_8[4], grey_8[3:2]});
			bin_8[1:0] = do_bin({bin_8[2], grey_8[1:0]});
			grey2bin = bin_8[AW:0];
		end
	endfunction
	assign sync_rd_ptr = grey2bin(sync_rd_ptr_1);
	reg [AW:0] sync_wr_ptr_0;
	reg [AW:0] sync_wr_ptr_1;
	wire [AW:0] sync_wr_ptr;
	reg [AW:0] rd_ptr;
	reg empty_q;
	wire empty_c;
	wire aempty_c;
	wire [AW:0] rd_ptr_inc = rd_ptr + 1'b1;
	wire [AW:0] sync_wr_ptr_dec = sync_wr_ptr - 1'b1;
	wire [AW:0] rd_cnt = get_cnt(sync_wr_ptr, rd_ptr);
	assign empty_c = (rd_cnt == 0 ? 1'b1 : 1'b0);
	assign aempty_c = (rd_cnt == 1 ? 1'b1 : 1'b0);
	always @(posedge rd_clk or negedge rd_reset_n)
		if (!rd_reset_n) begin
			rd_ptr <= 0;
			grey_rd_ptr <= 0;
			empty_q <= 1'b1;
		end
		else if (rd_en) begin
			rd_ptr <= rd_ptr_inc;
			grey_rd_ptr <= bin2grey(rd_ptr_inc);
			if (rd_cnt == (EMPTY_DP + 1))
				empty_q <= 1'b1;
		end
		else if (empty_q && (rd_cnt != EMPTY_DP))
			empty_q <= 1'b0;
	assign empty = (RD_FAST == 1 ? empty_c : empty_q);
	assign aempty = aempty_c;
	reg [W - 1:0] rd_data_q;
	wire [W - 1:0] rd_data_c = mem[rd_ptr[AW - 1:0]];
	always @(posedge rd_clk) rd_data_q <= rd_data_c;
	assign rd_data = (RD_FAST == 1 ? rd_data_c : rd_data_q);
	wire [AW:0] grey_wr_ptr_dly;
	// assign #(1) grey_wr_ptr_dly = grey_wr_ptr;
	assign grey_wr_ptr_dly = grey_wr_ptr;
	always @(posedge rd_clk or negedge rd_reset_n)
		if (!rd_reset_n) begin
			sync_wr_ptr_0 <= 0;
			sync_wr_ptr_1 <= 0;
		end
		else begin
			sync_wr_ptr_0 <= grey_wr_ptr_dly;
			sync_wr_ptr_1 <= sync_wr_ptr_0;
		end
	assign sync_wr_ptr = grey2bin(sync_wr_ptr_1);
	// always @(posedge wr_clk)
	// 	if (wr_en && full) begin
	// 		$display($time, "%m Error! afifo overflow!");
	// 		$stop;
	// 	end
	// always @(posedge rd_clk)
	// 	if (rd_en && empty) begin
	// 		$display($time, "%m error! afifo underflow!");
	// 		$stop;
	// 	end
endmodule
