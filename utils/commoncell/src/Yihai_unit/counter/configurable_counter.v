module configurable_2mode_counter#(
    parameter CNT_SIZE = 32 + 8,
    parameter CNT_SIZE_WIDTH = 6
) (
    input clk,
    input rst,
    input [1:0] mode_i,
    input [CNT_SIZE_WIDTH-1:0] cnt_rst_vector_i,
    output [CNT_SIZE_WIDTH-1:0] cnt_o,
    output cnt_end_o
);
reg [CNT_SIZE_WIDTH-1:0] cnt_r;
wire cnt_add_flag;
assign cnt_o = cnt_r;
wire cnt_overflow_end, cnt_precise_end;

always @(posedge clk) begin
    if (rst) begin
        cnt_r <= cnt_rst_vector_i;
    end else if (cnt_add_flag) begin
        if (cnt_precise_end) begin
            cnt_r <= 0;
        end else if (cnt_overflow_end) begin
            cnt_r <= 1;   
        end else if ((mode_i == 2'b01) | (mode_i == 2'b10)) begin
            cnt_r <= cnt_r + 1;
        end else if (mode_i == 2'b11) begin
            cnt_r <= cnt_r + 2;
        end
    end
end

assign cnt_add_flag = (mode_i != 2'b00);
/* verilator lint_off WIDTH */
assign cnt_precise_end = ((mode_i == 2'b11) & (cnt_r == CNT_SIZE - 2)) |
                            (((mode_i == 2'b01) | (mode_i == 2'b10)) & (cnt_r == CNT_SIZE - 1));
assign cnt_overflow_end = (mode_i == 2'b11) & (cnt_r == CNT_SIZE - 1);
assign cnt_end_o = cnt_precise_end | cnt_overflow_end;
/* verilator lint_on WIDTH */
endmodule
