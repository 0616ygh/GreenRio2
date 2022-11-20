`include "perips_cfg.vh"

module uart_rx #(
    parameter BAUD_RATE = 115200
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        rx_i,
    input  wire        cfg_en_i,
    output wire [7:0]  rx_data_o,
    output reg         rx_valid_o,
    input  wire        rx_ready_i
);

localparam BAUD_CNT = `UART_CLK_FREQ/BAUD_RATE;
localparam [2:0] IDLE      = 0;
localparam [2:0] START_BIT = 1;
localparam [2:0] DATA      = 2;
localparam [2:0] SAVE_DATA = 3;
localparam [2:0] PARITY    = 4;
localparam [2:0] STOP_BIT  = 5;

reg [2:0]  CS, NS;

reg [7:0]  reg_data;
reg [7:0]  reg_data_next;
reg [2:0]  reg_rx_sync;
reg [2:0]  reg_bit_count;
reg [2:0]  reg_bit_count_next;


reg        parity_bit;
reg        parity_bit_next;

reg        sampleData;

reg [8:0]  baud_cnt;
reg        baudgen_en;
reg        bit_done;

reg        start_bit;
wire       s_rx_fall;


always @(*) begin
    NS = CS;
    sampleData = 1'b0;
    reg_bit_count_next = reg_bit_count;
    reg_data_next = reg_data;
    rx_valid_o = 1'b0;
    baudgen_en = 1'b0;
    start_bit = 1'b0;
    parity_bit_next = parity_bit;
    case (CS)
        IDLE: begin
                if (s_rx_fall) begin
                    NS         = START_BIT;
                    baudgen_en = 1'b1;
                    start_bit  = 1'b1;
                end
        end
        START_BIT: begin
            parity_bit_next = 1'b0;
            baudgen_en      = 1'b1;
            start_bit       = 1'b1;
            if (bit_done) NS = DATA;
        end
        DATA: begin
            baudgen_en      = 1'b1;
            parity_bit_next = parity_bit ^ reg_rx_sync[2];
            reg_data_next = {reg_rx_sync[2], reg_data[7:1]};
            if (bit_done) begin
                sampleData = 1'b1;
                if (reg_bit_count == 'h7) begin
                    reg_bit_count_next = 'h0;
                    NS = SAVE_DATA;
                end else begin
                    reg_bit_count_next = reg_bit_count + 1;
                end
            end
        end
        SAVE_DATA: begin
            baudgen_en = 1'b1;
            rx_valid_o = 1'b1;
            if (rx_ready_i) begin
                NS = PARITY;
            end
        end
        PARITY: begin  
            baudgen_en = 1'b1;
            if (bit_done) begin
                NS = STOP_BIT;
            end
        end
        STOP_BIT: begin  // 接收数据时一位stop bit
            baudgen_en = 1'b1;
            if (bit_done) NS = IDLE;
        end
        default: NS = IDLE;
    endcase
end


always @(posedge clk) begin
    if (rst) begin
        CS            <= IDLE;
        reg_data      <= 8'hff;
        reg_bit_count <= 'h0;
        parity_bit    <= 1'b0;
    end else begin
        if (bit_done)
            parity_bit <= parity_bit_next;
        if (sampleData)
            reg_data <= reg_data_next;
            reg_bit_count <= reg_bit_count_next;
        if (cfg_en_i)
            CS <= NS;
        else
            CS <= IDLE;
    end
end

always @(posedge clk) begin
    if (rst)
        reg_rx_sync <= 3'b111;
    else if (cfg_en_i)
        reg_rx_sync <= {reg_rx_sync[1:0], rx_i};
    else
        reg_rx_sync <= 3'b111;
end

assign s_rx_fall = ~reg_rx_sync[1] & reg_rx_sync[2];

wire caonima = (baud_cnt == BAUD_CNT);
always @(posedge clk) begin
    if (rst) begin
        baud_cnt <= 'h0;
        bit_done <= 1'b0;
    end else if (baudgen_en) begin
        if (caonima) begin
            baud_cnt <= 'h0;
            bit_done <= 1'b1;
    end else begin
            baud_cnt <= baud_cnt + 1;
            bit_done <= 1'b0;
        end
    end else begin
        baud_cnt <= 'h0;
        bit_done <= 1'b0;
    end
end

assign rx_data_o = reg_data;

endmodule
