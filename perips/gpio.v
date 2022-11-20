`include "perips_cfg.vh"

module gpio(
    `ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
    `endif
    input clk,
    input rst, 
    input [`GPIO_SIZE-1:0] gpio_in_i,
    output reg [`GPIO_SIZE-1:0] gpio_out_o,
    output reg [`GPIO_SIZE-1:0] gpio_out_enable_o,
    output gpio_plic_irq_o,
    input wbm_gpio_cyc_i,
    input wbm_gpio_stb_i,
    input [`WB_AD_WIDTH-1:0] wbm_gpio_addr_i,
    input [`WB_DAT_WIDTH-1:0] wbm_gpio_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0]wbm_gpio_sel_i,
    input wbm_gpio_we_i,
    output reg [`WB_DAT_WIDTH-1:0] gpio_wbm_rdata_o,
    output gpio_wbm_ack_o
);
reg [`GPIO_SIZE-1:0] gpio_in_ff;
reg ack_ff;
reg gpio_in_ie;

always @(posedge clk) begin
    if (rst) begin
        gpio_out_enable_o <= 1'b0;
        gpio_in_ie <= 1'b1;  //defualt interrupt is allowed 
        ack_ff <= 1'b0;
    end else if (wbm_gpio_cyc_i && wbm_gpio_stb_i) begin
        case(wbm_gpio_addr_i)
            `GPIO_VALUE_ADDR: begin
                ack_ff <= 1'b1;
                if(!wbm_gpio_we_i) begin //read only
                    ack_ff <= 1'b1;
                    gpio_wbm_rdata_o <= {{(`WB_DAT_WIDTH - `GPIO_SIZE){1'b0}}, gpio_in_ff};
                end
            end
            `GPIO_INPUT_EN_ADDR: begin
                ack_ff <= 1'b1;
                if(wbm_gpio_we_i) begin
                    gpio_out_enable_o <= wbm_gpio_wdata_i[0]; // input enable  -> oen==1
                    gpio_in_ie <= wbm_gpio_wdata_i[1]; 
                end else begin
                    gpio_wbm_rdata_o <= {{30{1'b0}}, gpio_in_ie, gpio_out_enable_o};
                end
            end
            `GPIO_PORT_ADDR: begin
                if(wbm_gpio_we_i) begin //read only
                    ack_ff <= 1'b1;
                    gpio_out_o <= wbm_gpio_wdata_i[0 +: `GPIO_SIZE];
                end
            end
        endcase
    end
end

reg [`GPIO_SIZE-1:0] gpio_in_double_ff;
// interrupt logic
always @(posedge clk) begin
    if (rst) begin
        gpio_in_ff <= {`GPIO_SIZE{1'b0}};
        gpio_in_double_ff <= {`GPIO_SIZE{1'b0}};
    end else if(!gpio_plic_irq_o)begin
        gpio_in_ff <= gpio_in_i; 
        gpio_in_double_ff <= gpio_in_ff;
    end
end

wire [`GPIO_SIZE-1:0] gpio_in_xor = gpio_in_double_ff ^ gpio_in_ff;
assign gpio_plic_irq_o = gpio_in_ie? (|gpio_in_xor) : 1'b0;
assign gpio_wbm_ack_o = ack_ff && wbm_gpio_cyc_i;
endmodule