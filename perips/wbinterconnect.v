module wbinterconnect(
    input clk,
    input rst,

    input core_wbs_cyc_i,
    input core_wbs_stb_i,
    input core_wbs_we_i,
    input [`WB_AD_WIDTH-1:0] core_wbs_addr_i,
    input [`WB_DAT_WIDTH-1:0] core_wbs_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0] core_wbs_sel_i,
    output [`WB_DAT_WIDTH-1:0] wbs_core_rdata_o,
    output reg wbs_core_ack_o,

    input caravel_wbs_cyc_i,
    input caravel_wbs_stb_i,
    input caravel_wbs_we_i,
    input [`WB_AD_WIDTH-1:0] caravel_wbs_addr_i,
    input [`WB_DAT_WIDTH-1:0] caravel_wbs_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0] caravel_wbs_sel_i,
    output [`WB_DAT_WIDTH-1:0] wbs_caravel_rdata_o,
    output reg wbs_caravel_ack_o,

    input testio_wbs_cyc_i,
    input testio_wbs_stb_i,
    input testio_wbs_we_i,
    input [`WB_AD_WIDTH-1:0] testio_wbs_addr_i,
    input [`WB_DAT_WIDTH-1:0] testio_wbs_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0] testio_wbs_sel_i,
    output [`WB_DAT_WIDTH-1:0] wbs_testio_rdata_o,
    output reg wbs_testio_ack_o,

    output wbm_clint_cyc_o,
    output wbm_clint_stb_o,
    output [`WB_AD_WIDTH-1:0] wbm_clint_addr_o,
    output [`WB_DAT_WIDTH-1:0] wbm_clint_wdata_o,
    output [(`WB_DAT_WIDTH/8)-1:0]wbm_clint_sel_o,
    output wbm_clint_we_o,
    input [`WB_DAT_WIDTH-1:0] clint_wbm_rdata_i,
    input clint_wbm_ack_i,

    output wbm_plic_cyc_o,
    output wbm_plic_stb_o,
    output [`WB_AD_WIDTH-1:0] wbm_plic_addr_o,
    output [`WB_DAT_WIDTH-1:0] wbm_plic_wdata_o,
    output [(`WB_DAT_WIDTH/8)-1:0]wbm_plic_sel_o,
    output wbm_plic_we_o,
    input [`WB_DAT_WIDTH-1:0] plic_wbm_rdata_i,
    input plic_wbm_ack_i,

    // output wbm_gpio_cyc_o,
    // output wbm_gpio_stb_o,
    // output [`WB_AD_WIDTH-1:0] wbm_gpio_addr_o,
    // output [`WB_DAT_WIDTH-1:0] wbm_gpio_wdata_o,
    // output [(`WB_DAT_WIDTH/8)-1:0]wbm_gpio_sel_o,
    // output wbm_gpio_we_o,
    // input [`WB_DAT_WIDTH-1:0] gpio_wbm_rdata_i,
    // input gpio_wbm_ack_i,

    output wbm_uart_cyc_o,
    output wbm_uart_stb_o,
    output [`WB_AD_WIDTH-1:0] wbm_uart_addr_o,
    output [`WB_DAT_WIDTH-1:0] wbm_uart_wdata_o,
    output [(`WB_DAT_WIDTH/8)-1:0]wbm_uart_sel_o,
    output wbm_uart_we_o,
    input [`WB_DAT_WIDTH-1:0] uart_wbm_rdata_i,
    input uart_wbm_ack_i,

    output wbm_crg_cyc_o,
    output wbm_crg_stb_o,
    output [`WB_AD_WIDTH-1:0] wbm_crg_addr_o,
    output [`WB_DAT_WIDTH-1:0] wbm_crg_wdata_o,
    output [(`WB_DAT_WIDTH/8)-1:0]wbm_crg_sel_o,
    output wbm_crg_we_o,
    input [`WB_DAT_WIDTH-1:0] crg_wbm_rdata_i,
    input crg_wbm_ack_i
);

reg current_wbs_cyc;
reg current_wbs_stb;
reg current_wbs_we;
reg [`WB_AD_WIDTH-1:0] current_wbs_addr;
reg [`WB_DAT_WIDTH-1:0] current_wbs_wdata;
reg [(`WB_DAT_WIDTH/8)-1:0] current_wbs_sel;
reg [`WB_DAT_WIDTH-1:0] current_wbs_rdata;
reg current_wbs_ack;


//-----------------------master interface-------------------------
localparam  M1=3'b001,  //testio
	        M2=3'b010,  //core
	        M3=3'b100;  //caravel

reg [2:0] current_master;
reg [2:0] next_master;

always @(*) begin
    case(current_master)
        M1: begin
            next_master = M2;
            current_wbs_cyc = testio_wbs_cyc_i;
            current_wbs_addr = testio_wbs_addr_i;
            current_wbs_sel = testio_wbs_sel_i;
            current_wbs_stb = testio_wbs_stb_i;
            current_wbs_we = testio_wbs_we_i;
            current_wbs_wdata = testio_wbs_wdata_i;
            wbs_testio_ack_o = current_wbs_ack;
            wbs_core_ack_o = 'b0;
            wbs_caravel_ack_o = 'b0;          
        end
        M2: begin
            next_master = M3;
            current_wbs_cyc = core_wbs_cyc_i;
            current_wbs_addr = core_wbs_addr_i;
            current_wbs_sel = core_wbs_sel_i;
            current_wbs_stb = core_wbs_stb_i;
            current_wbs_we = core_wbs_we_i;
            current_wbs_wdata = core_wbs_wdata_i;
            wbs_testio_ack_o = 'b0;
            wbs_core_ack_o = current_wbs_ack;
            wbs_caravel_ack_o = 'b0;    
        end
        M3: begin
            next_master = M1;
            current_wbs_cyc = caravel_wbs_cyc_i;
            current_wbs_addr = caravel_wbs_addr_i;
            current_wbs_sel = caravel_wbs_sel_i;
            current_wbs_stb = caravel_wbs_stb_i;
            current_wbs_we = caravel_wbs_we_i;
            current_wbs_wdata = caravel_wbs_wdata_i;
            wbs_testio_ack_o = 'b0;
            wbs_core_ack_o = 'b0;
            wbs_caravel_ack_o = current_wbs_ack;  
        end
        default: begin
            next_master = M2;
            current_wbs_cyc = testio_wbs_cyc_i;
            current_wbs_addr = testio_wbs_addr_i;
            current_wbs_sel = testio_wbs_sel_i;
            current_wbs_stb = testio_wbs_stb_i;
            current_wbs_we = testio_wbs_we_i;
            current_wbs_wdata = testio_wbs_wdata_i;
            wbs_testio_ack_o = current_wbs_ack;
            wbs_core_ack_o = 'b0;
            wbs_caravel_ack_o = 'b0;   
        end
    endcase
end

always @(posedge clk or negedge rst) begin
    if(!rst) begin
        current_master <= M1;
    end else begin
        if(!current_wbs_cyc) begin
            current_master <= next_master;
        end else begin
            current_master <= current_master;
        end
    end
end

//------------------------slave interface-------------------------

reg [3:0] slave_select;
always @(*) begin
    case (slave_select)
        4'h5: begin
            current_wbs_rdata = clint_wbm_rdata_i;
            current_wbs_ack = clint_wbm_ack_i;
        end
        4'h1: begin
            current_wbs_rdata = plic_wbm_rdata_i;
            current_wbs_ack = plic_wbm_ack_i;
        end
        4'h3: begin
            current_wbs_rdata = uart_wbm_rdata_i;
            current_wbs_ack = uart_wbm_ack_i;
        end
        // 4'h2: begin
        //     current_wbs_rdata = gpio_wbm_rdata_i;
        //     current_wbs_ack = gpio_wbm_ack_i;
        // end
        4'h4: begin
            current_wbs_rdata = crg_wbm_rdata_i;
            current_wbs_ack = crg_wbm_ack_i;
        end
        default: begin
            current_wbs_rdata = 'b0;
            current_wbs_ack = 'b0;
        end
    endcase
end
always @(posedge clk or negedge rst) begin
    if(!rst) begin
        slave_select <= 4'b0;
    end else begin
        slave_select <= current_wbs_addr[11:8];
    end
end

// As the ack is low the data is not essential
assign wbm_crg_cyc_o = current_wbs_cyc;
assign wbm_crg_stb_o = current_wbs_stb;
assign wbm_crg_addr_o = current_wbs_addr;
assign wbm_crg_wdata_o = current_wbs_wdata;
assign wbm_crg_sel_o = current_wbs_sel;
assign wbm_crg_we_o = current_wbs_we;

assign wbm_uart_cyc_o = current_wbs_cyc;
assign wbm_uart_stb_o = current_wbs_stb;
assign wbm_uart_addr_o = current_wbs_addr;
assign wbm_uart_wdata_o = current_wbs_wdata;
assign wbm_uart_sel_o = current_wbs_sel;
assign wbm_uart_we_o = current_wbs_we;

// assign wbm_gpio_cyc_o = current_wbs_cyc;
// assign wbm_gpio_stb_o = current_wbs_stb;
// assign wbm_gpio_addr_o = current_wbs_addr;
// assign wbm_gpio_wdata_o = current_wbs_wdata;
// assign wbm_gpio_sel_o = current_wbs_sel;
// assign wbm_gpio_we_o = current_wbs_we;

assign wbm_clint_cyc_o = current_wbs_cyc;
assign wbm_clint_stb_o = current_wbs_stb;
assign wbm_clint_addr_o = current_wbs_addr;
assign wbm_clint_wdata_o = current_wbs_wdata;
assign wbm_clint_sel_o = current_wbs_sel;
assign wbm_clint_we_o = current_wbs_we;

assign wbm_plic_cyc_o = current_wbs_cyc;
assign wbm_plic_stb_o = current_wbs_stb;
assign wbm_plic_addr_o = current_wbs_addr;
assign wbm_plic_wdata_o = current_wbs_wdata;
assign wbm_plic_sel_o = current_wbs_sel;
assign wbm_plic_we_o = current_wbs_we;

assign wbm_plic_cyc_o = current_wbs_cyc;
assign wbm_plic_stb_o = current_wbs_stb;
assign wbm_plic_addr_o = current_wbs_addr;
assign wbm_plic_wdata_o = current_wbs_wdata;
assign wbm_plic_sel_o = current_wbs_sel;
assign wbm_plic_we_o = current_wbs_we;

assign wbs_core_rdata_o = current_wbs_rdata;
assign wbs_caravel_rdata_o = current_wbs_rdata;
assign wbs_testio_rdata_o = current_wbs_rdata;
endmodule