module rvh_l1d_lst (
	clk,
	rstn,
	lst_mesi_wr_en_s0_req,
	lst_mesi_wr_set_idx_s0_req,
	lst_mesi_wr_way_idx_s0_req,
	lst_mesi_wr_dat_s0_req,
	lst_mesi_wr_en_snp,
	lst_mesi_wr_set_idx_snp,
	lst_mesi_wr_way_idx_snp,
	lst_mesi_wr_dat_snp,
	lst_rd_idx_s0_req,
	lst_rd_dat_s0_req,
	lst_rd_idx_mlfb_peek,
	lst_rd_dat_mlfb_peek,
	lst_avail_way_rd_dat_mlfb_peek,
	lst_check_set_idx,
	lst_check_way_idx,
	lst_check_valid,
	lst_check_ready
);
	parameter entry_num = 32;
	parameter entry_idx = 5;
	parameter way_num = 4;
	parameter way_idx = 2;
	input wire clk;
	input wire rstn;
	input wire lst_mesi_wr_en_s0_req;
	localparam rvh_l1d_pkg_L1D_BANK_SET_INDEX_WIDTH = 1;
	input wire [0:0] lst_mesi_wr_set_idx_s0_req;
	localparam rvh_l1d_pkg_L1D_BANK_WAY_INDEX_WIDTH = 2;
	input wire [1:0] lst_mesi_wr_way_idx_s0_req;
	input wire [1:0] lst_mesi_wr_dat_s0_req;
	input wire lst_mesi_wr_en_snp;
	input wire [0:0] lst_mesi_wr_set_idx_snp;
	input wire [1:0] lst_mesi_wr_way_idx_snp;
	input wire [1:0] lst_mesi_wr_dat_snp;
	input wire [0:0] lst_rd_idx_s0_req;
	localparam rvh_l1d_pkg_L1D_BANK_WAY_NUM = 4;
	output wire [7:0] lst_rd_dat_s0_req;
	input wire [0:0] lst_rd_idx_mlfb_peek;
	output wire [7:0] lst_rd_dat_mlfb_peek;
	output reg [way_idx - 1:0] lst_avail_way_rd_dat_mlfb_peek;
	input wire [0:0] lst_check_set_idx;
	input wire [1:0] lst_check_way_idx;
	input wire lst_check_valid;
	output wire lst_check_ready;
	wire [(entry_num * 8) - 1:0] lst_entry;
	wire [((entry_num * 4) * 2) - 1:0] lst_entry_mesi_way;
	wire [(entry_num * 4) - 1:0] mesi_wr_set_en;
	wire [((entry_num * 4) * 2) - 1:0] mesi_wr_dat;
	wire [(entry_num * 4) - 1:0] lr_lock_wr_set_en;
	wire [(entry_num * 4) - 1:0] sc_rl_wr_set_en;
	wire [(entry_num * 4) - 1:0] lrsc_wr_set_en;
	wire [(entry_num * 4) - 1:0] lrsc_wr_dat;
	wire [(entry_num * 4) - 1:0] lst_check_reserved_bit_set;
	wire [(entry_num * 4) - 1:0] lst_check_reserved_bit_clr;
	wire [(entry_num * 4) - 1:0] lst_check_reserved_bit_ena;
	wire [(entry_num * 4) - 1:0] lst_check_reserved_bit_nxt;
	wire [(entry_num * 4) - 1:0] lst_check_reserved_bit;
	wire [way_num - 1:0] set_avail_bit_list_mlfb_peek;
	wire clk_lst;
	wire clk_lst_en;
	assign clk_lst_en = (lst_mesi_wr_en_s0_req | lst_mesi_wr_en_snp) | lst_check_valid;
	rrv64_cell_clkgate U_ICG_LST(
		.clk_i(clk),
		.clk_enable_i(clk_lst_en),
		.clk_senable_i(1'sb0),
		.clk_gated_o(clk_lst)
	);
	genvar ii;
	genvar jj;
	generate
		for (ii = 0; ii < entry_num; ii = ii + 1) begin : GEN_RRV64_L1D_LST_SET
			for (jj = 0; jj < rvh_l1d_pkg_L1D_BANK_WAY_NUM; jj = jj + 1) begin : GEN_RRV64_L1D_LST_WAY
				assign mesi_wr_set_en[(ii * 4) + jj] = ((lst_mesi_wr_en_s0_req & (lst_mesi_wr_set_idx_s0_req == ii)) & (lst_mesi_wr_way_idx_s0_req == jj)) | ((lst_mesi_wr_en_snp & (lst_mesi_wr_set_idx_snp == ii)) & (lst_mesi_wr_way_idx_snp == jj));
				assign mesi_wr_dat[((ii * 4) + jj) * 2+:2] = (lst_mesi_wr_en_s0_req ? lst_mesi_wr_dat_s0_req : lst_mesi_wr_dat_snp);
				std_dffre #(.WIDTH(2)) U_RRV64_L1D_LST_MESI_WAY(
					.clk(clk_lst),
					.rstn(rstn),
					.en(mesi_wr_set_en[(ii * 4) + jj]),
					.d(mesi_wr_dat[((ii * 4) + jj) * 2+:2]),
					.q(lst_entry_mesi_way[((ii * 4) + jj) * 2+:2])
				);
				assign lst_entry[(ii * 8) + (0 + (jj * 2))+:2] = {lst_entry_mesi_way[((ii * 4) + jj) * 2+:2]};
				assign lst_check_reserved_bit_set[(ii * 4) + jj] = ((lst_check_valid & ~lst_check_reserved_bit[(ii * 4) + jj]) & (lst_check_set_idx == ii)) & (lst_check_way_idx == jj);
				assign lst_check_reserved_bit_clr[(ii * 4) + jj] = ((lst_mesi_wr_en_s0_req & (mesi_wr_dat[((ii * 4) + jj) * 2+:2] != 2'd0)) & (lst_mesi_wr_set_idx_s0_req == ii)) & (lst_mesi_wr_way_idx_s0_req == jj);
				assign lst_check_reserved_bit_ena[(ii * 4) + jj] = lst_check_reserved_bit_set[(ii * 4) + jj] | lst_check_reserved_bit_clr[(ii * 4) + jj];
				assign lst_check_reserved_bit_nxt[(ii * 4) + jj] = lst_check_reserved_bit_set[(ii * 4) + jj] & ~lst_check_reserved_bit_clr[(ii * 4) + jj];
				std_dffre #(.WIDTH(1)) U_RRV64_L1D_LST_RESERVE_BIT(
					.clk(clk_lst),
					.rstn(rstn),
					.en(lst_check_reserved_bit_ena[(ii * 4) + jj]),
					.d(lst_check_reserved_bit_nxt[(ii * 4) + jj]),
					.q(lst_check_reserved_bit[(ii * 4) + jj])
				);
			end
		end
	endgenerate
	assign lst_check_ready = ~lst_check_reserved_bit[(lst_check_set_idx * 4) + lst_check_way_idx];
	assign lst_rd_dat_s0_req = lst_entry[lst_rd_idx_s0_req * 8+:8];
	assign lst_rd_dat_mlfb_peek = lst_entry[lst_rd_idx_mlfb_peek * 8+:8];
	genvar kk;
	generate
		for (kk = 0; kk < way_num; kk = kk + 1) begin : GEN_VALID_BIT
			assign set_avail_bit_list_mlfb_peek[kk] = lst_entry[(lst_rd_idx_mlfb_peek * 8) + (0 + (kk * 2))+:2] == 2'd0;
		end
	endgenerate
	always @(*) begin
		lst_avail_way_rd_dat_mlfb_peek = 1'sb0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 0; i < way_num; i = i + 1)
				if (set_avail_bit_list_mlfb_peek[i] == 1'b1)
					lst_avail_way_rd_dat_mlfb_peek = i[way_idx - 1:0];
		end
	end
endmodule
