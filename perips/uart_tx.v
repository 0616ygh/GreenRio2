`include "perips_cfg.vh"

module uart_tx #(
    parameter BAUD_RATE = 115200
) (
    input  wire        clk,
    input  wire        rst,
    output reg         tx_o,
    input  wire        cfg_en_i,
    input  wire        cfg_stop_bits_i,
    input  wire [7:0]  tx_data_i,
    input  wire        tx_valid_i,
    output reg         tx_ready_o
);

localparam BAUD_CNT = `UART_CLK_FREQ/BAUD_RATE;
localparam [2:0] IDLE           = 0;
localparam [2:0] START_BIT      = 1;
localparam [2:0] DATA           = 2;
localparam [2:0] PARITY         = 3;
localparam [2:0] STOP_BIT_FIRST = 4;
localparam [2:0] STOP_BIT_LAST  = 5;

reg [2:0]  CS,NS;

reg [7:0]  reg_data;
reg [7:0]  reg_data_next;
reg [2:0]  reg_bit_count;
reg [2:0]  reg_bit_count_next;

reg        parity_bit;
reg        parity_bit_next;

reg        sampleData;

reg [8:0] baud_cnt;
reg        baudgen_en;
reg        bit_done;


always @(*) begin
    NS                 = CS; //next state / current state
    tx_o               = 1'b1;
    sampleData         = 1'b0;
    reg_bit_count_next = reg_bit_count;
    reg_data_next      = {1'b1, reg_data[7:1]};
    tx_ready_o         = 1'b0;
    baudgen_en         = 1'b0;
    parity_bit_next    = parity_bit;

    case (CS)
        IDLE: begin
            if (cfg_en_i)
                tx_ready_o = 1'b1;
            if (tx_valid_i) begin
                NS            = START_BIT;
                sampleData    = 1'b1;
                reg_data_next = tx_data_i;
            end
        end
        START_BIT: begin
            tx_o            = 1'b0;
            parity_bit_next = 1'b0;
            baudgen_en      = 1'b1;
            if (bit_done)
                NS = DATA;
        end
        DATA: begin
            tx_o            = reg_data[0];
            baudgen_en      = 1'b1;
            parity_bit_next = parity_bit ^ reg_data[0];
            if (bit_done) begin
                if (reg_bit_count == 'h7) begin
                    reg_bit_count_next = 'h0;
                    NS = PARITY;
                end else begin
                    reg_bit_count_next = reg_bit_count + 1;
                    sampleData         = 1'b1;
                end
            end
        end
        PARITY: begin
            tx_o = parity_bit;
            baudgen_en = 1'b1;
            if (bit_done)
                NS = STOP_BIT_FIRST;
        end
        STOP_BIT_FIRST: begin
            tx_o       = 1'b1;
            baudgen_en = 1'b1;
            if (bit_done) begin
                if (cfg_stop_bits_i)
                    NS = STOP_BIT_LAST;
                else
                    NS = IDLE;
            end
        end
        STOP_BIT_LAST: begin
            tx_o = 1'b1;
            baudgen_en = 1'b1;
            if (bit_done)
                NS = IDLE;
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
        reg_data   <= reg_data_next;
        reg_bit_count  <= reg_bit_count_next;
    if (cfg_en_i)
        CS <= NS;
    else
        CS <= IDLE;
    end
end

wire caonima = (baud_cnt == BAUD_CNT);

always @(posedge clk) begin
    if (rst) begin
        baud_cnt <= 'h0;
        bit_done <= 1'b0;
    end else if (baudgen_en) begin
        if (caonima) begin
            baud_cnt <= 'h0;
            bit_done <= 1'b1;
        end
        else begin
            baud_cnt <= baud_cnt + 1;
            bit_done <= 1'b0;
        end
    end else begin
        baud_cnt <= 'h0;
        bit_done <= 1'b0;
    end
end

endmodule
