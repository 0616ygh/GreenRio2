module rct_testio_wb (
	clk_i,
	rstn_i,
	wb_stb_i,
	wb_addr_i,
	wb_we_i,
	wb_data_i,
	wb_sel_i,
	wb_cyc_i,
	wb_ack_o,
	wb_err_o,
	wb_data_o,
	ti_mod_i,
	ti_clk_div_i,
	ti_dat_i,
	ti_clk_o,
	ti_clk_oen,
	ti_dat_o,
	ti_dat_oen,
	ti_int_o
);
	parameter BUS_WIDTH = 32;
	parameter BUS_MASK = 4;
	parameter TESTIO_WIDTH = 1;
	input clk_i;
	input rstn_i;
	input wb_stb_i;
	input [BUS_WIDTH - 1:0] wb_addr_i;
	input wb_we_i;
	input [BUS_WIDTH - 1:0] wb_data_i;
	input [BUS_MASK - 1:0] wb_sel_i;
	input wb_cyc_i;
	output wire wb_ack_o;
	output wire wb_err_o;
	output wire [BUS_WIDTH - 1:0] wb_data_o;
	input [1:0] ti_mod_i;
	input [8:0] ti_clk_div_i;
	input [TESTIO_WIDTH - 1:0] ti_dat_i;
	output wire ti_clk_o;
	output wire ti_clk_oen;
	output wire [TESTIO_WIDTH - 1:0] ti_dat_o;
	output wire [TESTIO_WIDTH - 1:0] ti_dat_oen;
	output wire ti_int_o;
	wire wbm_clk_i;
	wire wbs_clk_i;
	wire wbm_rst_n;
	wire wbs_rst_n;
	wire ti_clk_div;
	wire ti_clk_mux;
	wire ti_clk;
	wire ti_clk_src_sel;
	wire [7:0] ti_clk_div_ratio;
	wire [1:0] ti_mod_o;
	wire wbs_stb_o;
	wire [BUS_WIDTH - 1:0] wbs_adr_o;
	wire wbs_we_o;
	wire [BUS_WIDTH - 1:0] wbs_dat_o;
	wire [BUS_MASK - 1:0] wbs_sel_o;
	wire wbs_cyc_o;
	wire wbs_ack_i;
	wire wbs_err_i;
	wire [BUS_WIDTH - 1:0] wbs_dat_i;
	wire ti_mem_if_req_valid;
	wire ti_mem_if_req_ready;
	localparam rct_cfg_RCT_MEM_ADDR_W = 32;
	localparam rct_cfg_RCT_MEM_DATA_W = 32;
	localparam rct_cfg_RCT_MEM_MASK_W = 4;
	localparam rct_cfg_CPUNOC_TID_RID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_SRCID_SIZE = 4;
	localparam rct_cfg_CPUNOC_TID_TID_SIZE = 8;
	wire [86:0] ti_mem_if_req;
	wire ti_mem_if_resp_valid;
	wire ti_mem_if_resp_ready;
	wire [50:0] ti_mem_if_resp;
	rct_w2m_bridge w2m_bridge_ti_u(
		.clk_i(clk_i),
		.rstn_i(rstn_i),
		.wb_stb_i(wb_stb_i),
		.wb_addr_i(wb_addr_i),
		.wb_we_i(wb_we_i),
		.wb_data_i(wb_data_i),
		.wb_sel_i(wb_sel_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_ack_o(wb_ack_o),
		.wb_err_o(wb_err_o),
		.wb_data_o(wb_data_o),
		.mem_if_req_valid(ti_mem_if_req_valid),
		.mem_if_req_ready(ti_mem_if_req_ready),
		.mem_if_req(ti_mem_if_req),
		.mem_if_resp_valid(ti_mem_if_resp_valid),
		.mem_if_resp_ready(ti_mem_if_resp_ready),
		.mem_if_resp(ti_mem_if_resp)
	);
	rct_testio rct_testio_u(
		.mem_if_req_valid(ti_mem_if_req_valid),
		.mem_if_req_ready(ti_mem_if_req_ready),
		.mem_if_req(ti_mem_if_req),
		.mem_if_resp_valid(ti_mem_if_resp_valid),
		.mem_if_resp_ready(ti_mem_if_resp_ready),
		.mem_if_resp(ti_mem_if_resp),
		.ti_clk_i(clk_i),
		.ti_rstn_i(rstn_i),
		.ti_mod_i(ti_mod_i),
		.ti_dat_i(ti_dat_i),
		.ti_clk_o(ti_clk_o),
		.ti_clk_oen(ti_clk_oen),
		.ti_dat_o(ti_dat_o),
		.ti_dat_oen(ti_dat_oen),
		.ti_int_o(ti_int_o)
	);
endmodule
