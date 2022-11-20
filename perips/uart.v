`include "perips_cfg.vh"

module uart(
    `ifdef USE_POWER_PINS
    inout vccd1,	// User area 1 1.8V supply
    inout vssd1,	// User area 1 digital ground
    `endif
    input clk,
    input rst, 
    input  uart_rx_i,
    output uart_tx_o,
    output uart_plic_irq_o,
    input wbm_uart_cyc_i,
    input wbm_uart_stb_i,
    input [`WB_AD_WIDTH-1:0] wbm_uart_addr_i,
    input [`WB_DAT_WIDTH-1:0] wbm_uart_wdata_i,
    input [(`WB_DAT_WIDTH/8)-1:0]wbm_uart_sel_i,
    input wbm_uart_we_i,
    output reg [`WB_DAT_WIDTH-1:0] uart_wbm_rdata_o,
    output uart_wbm_ack_o
);

localparam FIFO_DEPTH = 8; // in bytes
localparam LOG_FIFO_DEPTH = $clog2(FIFO_DEPTH);

reg [2:0] in_watermark;
reg in_irq_en;
reg stop_bit_ctrl;
reg out_en;
reg in_en;
reg ack_ff;
reg [7:0] fifo_tx_data;
wire [7:0] tx_data;
wire [7:0] fifo_rx_data;
wire [LOG_FIFO_DEPTH:0] rx_elements;
wire [LOG_FIFO_DEPTH:0] tx_elements;
wire tx_valid;
wire fifo_ready_in;
reg tx_data_ready;
wire fifo_rx_ready = wbm_uart_cyc_i && wbm_uart_cyc_i && (wbm_uart_addr_i == `UART_RX_DATA_ADDR) && !wbm_uart_we_i;
wire fifo_rx_valid;
wire [7:0] rx_data;

assign uart_plic_irq_o = (rx_elements >= {{1'b0}, in_watermark});   //length unmatch is correct

always @(posedge clk) begin
    if(rst) begin
        in_en <= 1'b1;
        out_en <= 1'b1;
        stop_bit_ctrl <= 1'b0;
        in_irq_en <= 1'b1;
        in_watermark <= 3'h1;
        ack_ff <= 1'b0;
    end else begin
        if(wbm_uart_cyc_i && wbm_uart_cyc_i) begin
            case (wbm_uart_addr_i)
                `UART_TX_DATA_ADDR: begin
                    if(wbm_uart_we_i) begin   //当tx_fifo为full时数据不会放入fifo中，会丢失，这种情况一般会被中断打断开启发送并处理
                        // wait until tx_fifo accept this data
                        fifo_tx_data <= wbm_uart_wdata_i[7:0];  
                        ack_ff <= 1'b1;
                    end else begin
                        ack_ff <= 1'b1;
                        uart_wbm_rdata_o <= {{24{1'b0}}, tx_data};
                    end
                end
                `UART_RX_DATA_ADDR: begin
                    if(!wbm_uart_we_i) begin
                        uart_wbm_rdata_o <= {{24{1'b0}}, fifo_rx_valid ? fifo_rx_data : {8{1'b0}}};
                        ack_ff <= 1'b1;
                    end
                end
                `UART_TX_CTRL_ADDR: begin
                    if(wbm_uart_we_i) begin
                        out_en <= wbm_uart_wdata_i[0]; 
                        stop_bit_ctrl <= wbm_uart_wdata_i[1];
                        ack_ff <= 1'b1;
                    end else begin
                        ack_ff <= 1'b1;
                        uart_wbm_rdata_o <= {{30{1'b0}}, stop_bit_ctrl, out_en};
                    end
                end
                `UART_RX_CTRL_ADDR: begin
                    if(wbm_uart_we_i) begin
                        in_en <= wbm_uart_wdata_i[0]; 
                        in_irq_en <= wbm_uart_wdata_i[2];
                        in_watermark <= wbm_uart_wdata_i[31:29];
                        ack_ff <= 1'b1;
                    end else begin
                        ack_ff <= 1'b1;
                        uart_wbm_rdata_o <= {in_watermark, rx_elements, {22{1'b0}}, in_irq_en, {1'b0}, in_en};
                    end
                end
                default: begin
                    ack_ff <= 1'b0;
                end
            endcase
        end else begin
            ack_ff <= 1'b0;
        end
    end
end

// 要避免一个fifo_tx_data送入fifo多次
always @(posedge clk) begin
    if(rst) begin
        tx_data_ready <= 1'b0;
    end else if(fifo_ready_in && tx_data_ready) begin
        tx_data_ready <= 1'b0;
    end else if(wbm_uart_cyc_i && wbm_uart_cyc_i && wbm_uart_we_i && wbm_uart_addr_i == `UART_TX_DATA_ADDR) begin
        tx_data_ready <= 1'b1;
    end 
end

io_generic_fifo #(
    .DATA_WIDTH       (8),
    .BUFFER_DEPTH     (FIFO_DEPTH)
) uart_tx_fifo(
    .clk              ( clk                                    ),
    .rst              ( rst                                    ),
    .clr_i            ( 1'b0                                   ),
    .elements_o       ( tx_elements                            ),
    .data_o           ( tx_data                                ),
    .valid_o          ( tx_valid                               ),
    .ready_i          ( tx_ready                               ),
    .valid_i          ( tx_data_ready                          ),
    .data_i           ( fifo_tx_data                           ),
    .ready_o          ( fifo_ready_in                          )
);

uart_tx uart_tx_u(
    .clk              ( clk                                    ),
    .rst              ( rst                                    ),
    .tx_o             ( uart_tx_o                              ),
    .cfg_en_i         ( out_en                                 ),
    .cfg_stop_bits_i  ( stop_bit_ctrl                          ),
    .tx_data_i        ( tx_data                                ),
    .tx_valid_i       ( tx_valid                               ),
    .tx_ready_o       ( tx_ready                               )
);

io_generic_fifo #(
    .DATA_WIDTH       (8),
    .BUFFER_DEPTH     (FIFO_DEPTH)
) uart_rx_fifo(
    .clk              ( clk                                    ),
    .rst              ( rst                                    ),
    .clr_i            ( 1'b0                                   ),
    .elements_o       ( rx_elements                            ),
    .data_o           ( fifo_rx_data                           ),
    .valid_o          ( fifo_rx_valid                          ),
    .ready_i          ( fifo_rx_ready                          ),
    .valid_i          ( rx_valid                               ),
    .data_i           ( rx_data                                ),
    .ready_o          ( rx_ready                               )
);

uart_rx uart_rx_u(
    .clk              ( clk                                    ),
    .rst              ( rst                                    ),
    .rx_i             ( uart_rx_i                              ),
    .cfg_en_i         ( 1'b1                                   ),
    .rx_data_o        ( rx_data                                ),
    .rx_valid_o       ( rx_valid                               ),
    .rx_ready_i       ( rx_ready                               )
);
assign uart_wbm_ack_o = ack_ff && wbm_uart_cyc_i && wbm_uart_stb_i;
endmodule