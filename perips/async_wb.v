module async_wb (
	wbm_rst_n,
	wbm_clk_i,
	wbm_cyc_i,
	wbm_stb_i,
	wbm_adr_i,
	wbm_we_i,
	wbm_dat_i,
	wbm_sel_i,
	wbm_dat_o,
	wbm_ack_o,
	wbm_err_o,
	wbs_rst_n,
	wbs_clk_i,
	wbs_cyc_o,
	wbs_stb_o,
	wbs_adr_o,
	wbs_we_o,
	wbs_dat_o,
	wbs_sel_o,
	wbs_dat_i,
	wbs_ack_i,
	wbs_err_i
);
	parameter AW = 32;
	parameter BW = 4;
	parameter DW = 32;
	input wire wbm_rst_n;
	input wire wbm_clk_i;
	input wire wbm_cyc_i;
	input wire wbm_stb_i;
	input wire [AW - 1:0] wbm_adr_i;
	input wire wbm_we_i;
	input wire [DW - 1:0] wbm_dat_i;
	input wire [BW - 1:0] wbm_sel_i;
	output wire [DW - 1:0] wbm_dat_o;
	output wire wbm_ack_o;
	output wire wbm_err_o;
	input wire wbs_rst_n;
	input wire wbs_clk_i;
	output wire wbs_cyc_o;
	output wire wbs_stb_o;
	output wire [AW - 1:0] wbs_adr_o;
	output wire wbs_we_o;
	output wire [DW - 1:0] wbs_dat_o;
	output wire [BW - 1:0] wbs_sel_o;
	input wire [DW - 1:0] wbs_dat_i;
	input wire wbs_ack_i;
	input wire wbs_err_i;
	parameter CFW = ((AW + DW) + BW) + 1;
	reg PendingRd;
	wire m_cmd_wr_en;
	wire [CFW - 1:0] m_cmd_wr_data;
	wire m_cmd_wr_full;
	wire m_cmd_wr_afull;
	wire m_resp_rd_empty;
	wire m_resp_rd_aempty;
	wire m_resp_rd_en;
	wire [DW:0] m_resp_rd_data;
	assign m_cmd_wr_en = ((!PendingRd && wbm_stb_i) && !m_cmd_wr_full) && !m_cmd_wr_afull;
	assign m_cmd_wr_data = {wbm_adr_i, wbm_we_i, wbm_dat_i, wbm_sel_i};
	always @(negedge wbm_rst_n or posedge wbm_clk_i)
		if (wbm_rst_n == 0)
			PendingRd <= 1'b0;
		else if (((!PendingRd && wbm_stb_i) && !wbm_we_i) && m_cmd_wr_en)
			PendingRd <= 1'b1;
		else if (((PendingRd && wbm_stb_i) && !wbm_we_i) && wbm_ack_o)
			PendingRd <= 1'b0;
	assign wbm_ack_o = (wbm_stb_i && wbm_we_i ? m_cmd_wr_en : (wbm_stb_i && !wbm_we_i ? !m_resp_rd_empty : 1'b0));
	assign m_resp_rd_en = !m_resp_rd_empty;
	assign wbm_dat_o = m_resp_rd_data[DW - 1:0];
	assign wbm_err_o = m_resp_rd_data[DW];
	wire [CFW - 1:0] s_cmd_rd_data;
	wire s_cmd_rd_empty;
	wire s_cmd_rd_aempty;
	wire s_cmd_rd_en;
	wire s_resp_wr_en;
	wire [DW:0] s_resp_wr_data;
	wire s_resp_wr_full;
	wire s_resp_wr_afull;
	reg wbs_ack_f;
	always @(negedge wbs_rst_n or posedge wbs_clk_i)
		if (wbs_rst_n == 0)
			wbs_ack_f <= 1'b0;
		else
			wbs_ack_f <= wbs_ack_i;
	assign {wbs_adr_o, wbs_we_o, wbs_dat_o, wbs_sel_o} = (s_cmd_rd_empty ? {(((0 + AW) + 1) + DW) + BW {1'sb0}} : s_cmd_rd_data);
	assign wbs_stb_o = (wbs_ack_f ? 1'b0 : (s_cmd_rd_empty ? 1'b0 : 1'b1));
	assign wbs_cyc_o = (wbs_ack_f ? 1'b0 : (s_cmd_rd_empty ? 1'b0 : 1'b1));
	assign s_cmd_rd_en = wbs_ack_i;
	assign s_resp_wr_en = ((wbs_stb_o & !wbs_we_o) & wbs_ack_i) & !s_resp_wr_full;
	assign s_resp_wr_data = {wbs_err_i, wbs_dat_i};
	async_fifo #(
		.W(CFW),
		.DP(4),
		.WR_FAST(1),
		.RD_FAST(1)
	) u_cmd_if(
		.wr_clk(wbm_clk_i),
		.wr_reset_n(wbm_rst_n),
		.wr_en(m_cmd_wr_en),
		.wr_data(m_cmd_wr_data),
		.full(m_cmd_wr_full),
		.afull(m_cmd_wr_afull),
		.rd_clk(wbs_clk_i),
		.rd_reset_n(wbs_rst_n),
		.rd_en(s_cmd_rd_en),
		.empty(s_cmd_rd_empty),
		.aempty(s_cmd_rd_aempty),
		.rd_data(s_cmd_rd_data)
	);
	async_fifo #(
		.W(DW + 1),
		.DP(2),
		.WR_FAST(1),
		.RD_FAST(1)
	) u_resp_if(
		.wr_clk(wbs_clk_i),
		.wr_reset_n(wbs_rst_n),
		.wr_en(s_resp_wr_en),
		.wr_data(s_resp_wr_data),
		.full(s_resp_wr_full),
		.afull(s_resp_wr_afull),
		.rd_clk(wbm_clk_i),
		.rd_reset_n(wbm_rst_n),
		.rd_en(m_resp_rd_en),
		.empty(m_resp_rd_empty),
		.aempty(m_resp_rd_aempty),
		.rd_data(m_resp_rd_data)
	);
endmodule
