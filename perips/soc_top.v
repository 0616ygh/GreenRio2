`default_nettype wire
`include "perips_cfg.vh"

module soc_top (
    `ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
    `endif

    input clk, //global clk
    input rst, // global reset 
    input testio_clk,
    input                               core_soc_cyc_i,
    input                               core_soc_stb_i,
    input                               core_soc_we_i,
    input       [`WB_AD_WIDTH-1:0]      core_soc_addr_i,
    input       [`WB_DAT_WIDTH-1:0]     core_soc_wdata_i,
    input     [`WB_DAT_WIDTH/8-1:0]     core_soc_sel_i,
    output      [`WB_DAT_WIDTH-1:0]     core_soc_rdata_o,
    output                              core_soc_ack_o,

    input                               caravel_soc_cyc_i,
    input                               caravel_soc_stb_i,
    input                               caravel_soc_we_i,
    input       [`WB_AD_WIDTH-1:0]      caravel_soc_addr_i,
    input       [`WB_DAT_WIDTH-1:0]     caravel_soc_wdata_i,
    input      [`WB_DAT_WIDTH/8-1:0]    caravel_soc_sel_i,
    output      [`WB_DAT_WIDTH-1:0]     caravel_soc_rdata_o,
    output                              caravel_soc_ack_o,

    input                               ti_i,
    output                              ti_o,
    output                              ti_oen,
    input                               uart_rx_i,
    output                              uart_tx_o,
    // input       [`GPIO_SIZE-1:0]        gpio_in_i,
    // output      [`GPIO_SIZE-1:0]        gpio_out_o,
    // output      [`GPIO_SIZE-1:0]        gpio_out_enable_o,
    output                              soc_core_ei_o,
    output                              soc_core_mtmri_o,
    output                              soc_core_stmri_o,
    output                              soc_core_msoft_o,
    output                              soc_core_ssoft_o,
    output                              domain4_clk_o,  // for ebi
    output                              domain4_rst_o
    
);

wire                        clint_cyc;
wire                        clint_stb;
wire  [`WB_AD_WIDTH-1:0]    clint_addr;
wire  [`WB_DAT_WIDTH-1:0]   clint_wdata;
wire                        clint_we;
wire  [`WB_DAT_WIDTH-1:0]   clint_rdata;
wire                        clint_ack;

wire                        plic_cyc;
wire                        plic_stb;
wire  [`WB_AD_WIDTH-1:0]    plic_addr;
wire  [`WB_DAT_WIDTH-1:0]   plic_wdata;
wire                        plic_we;
wire  [`WB_DAT_WIDTH-1:0]   plic_rdata;
wire                        plic_ack;

wire                        gpio_cyc;
wire                        gpio_stb;
wire  [`WB_AD_WIDTH-1:0]    gpio_addr;
wire  [`WB_DAT_WIDTH-1:0]   gpio_wdata;
wire                        gpio_we;
wire  [`WB_DAT_WIDTH-1:0]   gpio_rdata;
wire                        gpio_ack;
wire                        gpio_irq;

wire                        uart_cyc;
wire                        uart_stb;
wire  [`WB_AD_WIDTH-1:0]    uart_addr;
wire  [`WB_DAT_WIDTH-1:0]   uart_wdata;
wire                        uart_we;
wire  [`WB_DAT_WIDTH-1:0]   uart_rdata;
wire                        uart_ack;
wire                        uart_irq;

wire                        crg_cyc;
wire                        crg_stb;
wire  [`WB_AD_WIDTH-1:0]    crg_addr;
wire  [`WB_DAT_WIDTH-1:0]   crg_wdata;
wire                        crg_we;
wire  [`WB_DAT_WIDTH-1:0]   crg_rdata;
wire                        crg_ack;

wire [`WB_AD_WIDTH-1:0]     ti_soc_addr;
wire [`WB_DAT_WIDTH-1:0]    ti_soc_wdata;
wire [`WB_DAT_WIDTH/8-1:0]  ti_soc_strb;
wire [`WB_DAT_WIDTH-1:0]    ti_soc_rdata;

// testio_slave_top #(  
//     .TI_W(1),
//     .BUS_WIDTH(32)
// ) testio_slave_top_u (
//     .rst(rst),   
//     .clk(clk),
//     .test_din(ti_i),
//     .test_dout(ti_o),
//     .test_doen(ti_oen),
//     //mem_if i
//     .testio_wbs_stb_o(ti_soc_cyc),
//     .testio_wbs_cyc_o(ti_soc_stb),
//     .testio_wbs_we_o(ti_soc_we),
//     .testio_wbs_addr_o(ti_soc_addr),
//     .testio_wbs_wdata_o(ti_soc_wdata),
//     .testio_wbs_strb_o(ti_soc_strb),
//     .wbs_testio_ack_i(ti_soc_ack),
//     .wbs_testio_rdata_i(ti_soc_rdata)
// );

rct_testio_ma_wb rct_testio_ma_wb(
	.clk_i(clk),    //perips clk
 	.rstn_i(rst),   //caravel reset 
	.test_intr(),   //testio doesn't trigger test
 	.test_clk(testio_clk),
	.test_din(ti_i),
	.test_dout(ti_o),
	.test_doen(ti_oen),
	.wb_stb_o(ti_soc_stb),
	.wb_addr_o(ti_soc_addr),
	.wb_we_o(ti_soc_we),
	.wb_data_o(ti_soc_wdata),
	.wb_sel_o(ti_soc_strb),
	.wb_cyc_o(ti_soc_cyc),
	.wb_ack_i(ti_soc_ack),
	.wb_err_i(1'b0),
	.wb_data_i(ti_soc_rdata)
);

wbinterconnect wbinterconnect_u(
    .clk(clk),
    .rst(rst),

    .core_wbs_cyc_i(core_soc_cyc_i),
    .core_wbs_stb_i(core_soc_stb_i),
    .core_wbs_we_i(core_soc_we_i),
    .core_wbs_addr_i(core_soc_addr_i),
    .core_wbs_wdata_i(core_soc_wdata_i),
    .core_wbs_sel_i(core_soc_sel_i),
    .wbs_core_rdata_o(core_soc_rdata_o),
    .wbs_core_ack_o(core_soc_ack_o),

    .caravel_wbs_cyc_i(caravel_soc_cyc_i),
    .caravel_wbs_stb_i(caravel_soc_stb_i),
    .caravel_wbs_we_i(caravel_soc_we_i),
    .caravel_wbs_addr_i(caravel_soc_addr_i),
    .caravel_wbs_wdata_i(caravel_soc_wdata_i),
    .caravel_wbs_sel_i(caravel_soc_sel_i),
    .wbs_caravel_rdata_o(caravel_soc_rdata_o),
    .wbs_caravel_ack_o(caravel_soc_ack_o),

    .testio_wbs_cyc_i(ti_soc_cyc),
    .testio_wbs_stb_i(ti_soc_stb),
    .testio_wbs_we_i(ti_soc_we),
    .testio_wbs_addr_i(ti_soc_addr),
    .testio_wbs_wdata_i(ti_soc_wdata),
    .testio_wbs_sel_i(ti_soc_strb),
    .wbs_testio_rdata_o(ti_soc_rdata),
    .wbs_testio_ack_o(ti_soc_ack),

    .wbm_clint_cyc_o(clint_cyc),
    .wbm_clint_stb_o(clint_stb),
    .wbm_clint_addr_o(clint_addr),
    .wbm_clint_wdata_o(clint_wdata),
    .wbm_clint_sel_o(),
    .wbm_clint_we_o(clint_we),
    .clint_wbm_rdata_i(clint_rdata),
    .clint_wbm_ack_i(clint_ack),

    .wbm_plic_cyc_o(plic_cyc),
    .wbm_plic_stb_o(plic_stb),
    .wbm_plic_addr_o(plic_addr),
    .wbm_plic_wdata_o(plic_wdata),
    .wbm_plic_sel_o(),
    .wbm_plic_we_o(plic_we),
    .plic_wbm_rdata_i(plic_rdata),
    .plic_wbm_ack_i(plic_ack),

    // .wbm_gpio_cyc_o(gpio_cyc),
    // .wbm_gpio_stb_o(gpio_stb),
    // .wbm_gpio_addr_o(gpio_addr),
    // .wbm_gpio_wdata_o(gpio_wdata),
    // .wbm_gpio_sel_o(),
    // .wbm_gpio_we_o(gpio_we),
    // .gpio_wbm_rdata_i(gpio_rdata),
    // .gpio_wbm_ack_i(gpio_ack),

    .wbm_uart_cyc_o(uart_cyc),
    .wbm_uart_stb_o(uart_stb),
    .wbm_uart_addr_o(uart_addr),
    .wbm_uart_wdata_o(uart_wdata),
    .wbm_uart_sel_o(),
    .wbm_uart_we_o(uart_we),
    .uart_wbm_rdata_i(uart_rdata),
    .uart_wbm_ack_i(uart_ack),

    .wbm_crg_cyc_o(crg_cyc),
    .wbm_crg_stb_o(crg_stb),
    .wbm_crg_addr_o(crg_addr),
    .wbm_crg_wdata_o(crg_wdata),
    .wbm_crg_sel_o(),
    .wbm_crg_we_o(crg_we),
    .crg_wbm_rdata_i(crg_rdata),
    .crg_wbm_ack_i(crg_ack)
);

uart uart_u(
    .clk(domain2_clk),
    .rst(domain2_rst), 
    .uart_rx_i(uart_rx_i),
    .uart_tx_o(uart_tx_o),
    .uart_plic_irq_o(uart_irq),
    .wbm_uart_cyc_i(uart_cyc),
    .wbm_uart_stb_i(uart_stb),
    .wbm_uart_addr_i(uart_addr),
    .wbm_uart_wdata_i(uart_wdata),
    .wbm_uart_sel_i(4'hf),
    .wbm_uart_we_i(uart_we),
    .uart_wbm_rdata_o(uart_rdata),
    .uart_wbm_ack_o(uart_ack)
);

crg crg_u(
    .global_clk(clk),
    .global_rst(rst),
    .wbm_crg_cyc_i(crg_cyc),
    .wbm_crg_stb_i(crg_stb),
    .wbm_crg_addr_i(crg_addr),
    .wbm_crg_wdata_i(crg_wdata),
    .wbm_crg_sel_i(4'hf),
    .wbm_crg_we_i(crg_we),
    .crg_wbm_rdata_o(crg_rdata),
    .crg_wbm_ack_o(crg_ack),
    // hehe, cache, clint, plic
    .domain1_clk_o(domain1_clk),
    .domain1_rst_o(domain1_rst),
    //uart
    .domain2_clk_o(domain2_clk),
    .domain2_rst_o(domain2_rst),
    //gpio
    .domain3_clk_o(domain3_clk),
    .domain3_rst_o(domain3_rst),
    //ebi
    .domain4_clk_o(domain4_clk_o),
    .domain4_rst_o(domain4_rst_o)
);

// gpio gpio_u(
//     .clk(domain3_clk),
//     .rst(domain3_rst),
//     .gpio_in_i(gpio_in_i),
//     .gpio_out_o(gpio_out_o),
//     .gpio_out_enable_o(gpio_out_enable_o),
//     .gpio_plic_irq_o(gpio_irq),
//     .wbm_gpio_cyc_i(gpio_cyc),
//     .wbm_gpio_stb_i(gpio_stb),
//     .wbm_gpio_addr_i(gpio_addr),
//     .wbm_gpio_wdata_i(gpio_wdata),
//     .wbm_gpio_sel_i(4'hf),
//     .wbm_gpio_we_i(gpio_we),
//     .gpio_wbm_rdata_o(gpio_rdata),
//     .gpio_wbm_ack_o(gpio_ack)
// );


plic plic_u(
    .clk(domain1_clk),
    .rst(domain1_rst),
    .plic_core_ext_irq_o(soc_core_ei_o),
    .gpio_plic_irq_i(1'b0),
    .uart_plic_irq_i(uart_irq),
    .wbm_plic_cyc_i(plic_cyc),
    .wbm_plic_stb_i(plic_stb),
    .wbm_plic_addr_i(plic_addr),
    .wbm_plic_wdata_i(plic_wdata),
    .wbm_plic_sel_i(4'hf),
    .wbm_plic_we_i(plic_we),
    .plic_wbm_rdata_o(plic_rdata),
    .plic_wbm_ack_o(plic_ack)
);

clint clint_u(
    .clk(domain1_clk),
    .rst(domain1_rst),
    .clint_core_mtmr_irq_o(soc_core_mtmri_o),
    .clint_core_stmr_irq_o(soc_core_stmri_o),
    .clint_core_msoft_irq_o(soc_core_msoft_o),
    .clint_core_ssoft_irq_o(soc_core_ssoft_o),
    .wbm_clint_cyc_i(clint_cyc),
    .wbm_clint_stb_i(clint_stb),
    .wbm_clint_addr_i(clint_addr),
    .wbm_clint_wdata_i(clint_wdata),
    .wbm_clint_sel_i(4'hf),
    .wbm_clint_we_i(clint_we),
    .clint_wbm_rdata_o(clint_rdata),
    .clint_wbm_ack_o(clint_ack)
);

endmodule