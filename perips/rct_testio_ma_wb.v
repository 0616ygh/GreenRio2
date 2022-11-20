module rct_testio_ma_wb (
	clk_i,
	rstn_i,
	test_intr,
	test_clk,
	test_din,
	test_dout,
	test_doen,
	wb_stb_o,
	wb_addr_o,
	wb_we_o,
	wb_data_o,
	wb_sel_o,
	wb_cyc_o,
	wb_ack_i,
	wb_err_i,
	wb_data_i
);
	parameter BUS_WIDTH = 32;
	parameter BUS_MASK = 4;
	input wire clk_i;
	input wire rstn_i;
	output wire test_intr;
	input wire test_clk;
	input wire test_din;
	output wire test_dout;
	output wire test_doen;
	output wire wb_stb_o;
	output wire [BUS_WIDTH - 1:0] wb_addr_o;
	output wire wb_we_o;
	output wire [BUS_WIDTH - 1:0] wb_data_o;
	output wire [BUS_MASK - 1:0] wb_sel_o;
	output wire wb_cyc_o;
	input wb_ack_i;
	input wb_err_i;
	input [BUS_WIDTH - 1:0] wb_data_i;
	wire wbm_clk_i;
	wire wbs_clk_i;
	wire wbm_rst_n;
	wire wbs_rst_n;
	wire wbm_stb_o;
	wire [BUS_WIDTH - 1:0] wbm_adr_o;
	wire wbm_we_o;
	// wire [BUS_WIDTH - 1:0] wbm_dat_o;
	wire [BUS_MASK - 1:0] wbm_sel_o;
	wire wbm_cyc_o;
	wire wbm_ack_i;
	wire wbm_err_i;
	wire [BUS_WIDTH - 1:0] wbm_dat_i;
	wire ti_ma_mem_if_req_valid;
	wire ti_ma_mem_if_req_ready;
	localparam rct_cfg_RCT_MEM_ADDR_W = 32;
	localparam rct_cfg_RCT_MEM_DATA_W = 32;
	localparam rct_cfg_RCT_MEM_MASK_W = 4;
	localparam rct_cfg_CPUNOC_TID_RID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_SRCID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_TID_SIZE = 8;
	wire [86:0] ti_ma_mem_if_req;
	wire ti_ma_mem_if_resp_valid;
	wire ti_ma_mem_if_resp_ready;
	wire [50:0] ti_ma_mem_if_resp;
	assign wbm_clk_i = test_clk;
	assign wbs_clk_i = clk_i;
	// reset_sync wbm_rstn_u(
	// 	.scan_mode(1'b0),
	// 	.dclk(wbm_clk_i),
	// 	.arst_n(rstn_i),
	// 	.srst_n(wbm_rst_n)
	// );
	// reset_sync wbs_rstn_u(
	// 	.scan_mode(1'b0),
	// 	.dclk(wbs_clk_i),
	// 	.arst_n(rstn_i),
	// 	.srst_n(wbs_rst_n)
	// );
	assign wbm_rst_n = rstn_i;
	assign wbs_rst_n = rstn_i;
	rct_testio_ma testio_ma(
		.rstn_i(wbm_rst_n),
		.test_intr(test_intr),
		.test_clk(test_clk),
		.test_din(test_din),
		.test_dout(test_dout),
		.test_doen(test_doen),
		.mem_if_req_valid(ti_ma_mem_if_req_valid),
		.mem_if_req_ready(ti_ma_mem_if_req_ready),
		.mem_if_req(ti_ma_mem_if_req),
		.mem_if_resp_valid(ti_ma_mem_if_resp_valid),
		.mem_if_resp_ready(ti_ma_mem_if_resp_ready),
		.mem_if_resp(ti_ma_mem_if_resp)
	);
	wire [BUS_WIDTH - 1:0] wbm_addr_o;
	wire [BUS_WIDTH - 1:0] wbm_data_o;
	wire [BUS_WIDTH - 1:0] wbm_data_i;
	rct_m2w_bridge m2w_bridge_ti_ma_u(
		.clk_i(wbm_clk_i),
		.rstn_i(wbm_rst_n),
		.mem_if_req_valid(ti_ma_mem_if_req_valid),
		.mem_if_req_ready(ti_ma_mem_if_req_ready),
		.mem_if_req(ti_ma_mem_if_req),
		.mem_if_resp_valid(ti_ma_mem_if_resp_valid),
		.mem_if_resp_ready(ti_ma_mem_if_resp_ready),
		.mem_if_resp(ti_ma_mem_if_resp),
		.wb_stb_o(wbm_stb_o),
		.wb_addr_o(wbm_addr_o),
		.wb_we_o(wbm_we_o),
		.wb_data_o(wbm_data_o),
		.wb_sel_o(wbm_sel_o),
		.wb_cyc_o(wbm_cyc_o),
		.wb_ack_i(wbm_ack_i),
		.wb_err_i(wbm_err_i),
		.wb_data_i(wbm_data_i)
	);
	async_wb async_wb_u(
		.wbm_rst_n(wbm_rst_n),
		.wbm_clk_i(wbm_clk_i),
		.wbm_cyc_i(wbm_cyc_o),
		.wbm_stb_i(wbm_stb_o),
		.wbm_adr_i(wbm_addr_o),
		.wbm_we_i(wbm_we_o),
		.wbm_dat_i(wbm_data_o),
		.wbm_sel_i(wbm_sel_o),
		.wbm_dat_o(wbm_data_i),
		.wbm_ack_o(wbm_ack_i),
		.wbm_err_o(wbm_err_i),
		.wbs_rst_n(wbs_rst_n),
		.wbs_clk_i(wbs_clk_i),
		.wbs_cyc_o(wb_cyc_o),
		.wbs_stb_o(wb_stb_o),
		.wbs_adr_o(wb_addr_o),
		.wbs_we_o(wb_we_o),
		.wbs_dat_o(wb_data_o),
		.wbs_sel_o(wb_sel_o),
		.wbs_dat_i(wb_data_i),
		.wbs_ack_i(wb_ack_i),
		.wbs_err_i(wb_err_i)
	);
endmodule
