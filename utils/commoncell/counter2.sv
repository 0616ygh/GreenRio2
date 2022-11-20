module counter2#(
    parameter CNT_SIZE = 32 + 8,
    parameter CNT_SIZE_WIDTH = 6
) (
    input clk,
    input rst,
    input cnt_add_flag_i,
    input [CNT_SIZE_WIDTH-1:0] cnt_rst_vector_i,
    input cnt_set_flag_i,
    input [CNT_SIZE_WIDTH-1:0] cnt_set_vector_i,
    output [CNT_SIZE_WIDTH-1:0] cnt_o,
    output cnt_end_o
);
wire cnt_start;
reg [CNT_SIZE_WIDTH-1:0] cnt_r;
assign cnt_o = cnt_r;

always @(posedge clk) begin
    if (rst) begin
        cnt_r <= cnt_rst_vector_i;
    end 
    else if(cnt_set_flag_i) begin
        cnt_r <= cnt_set_vector_i;
    end
    else if (cnt_add_flag_i) begin
        if (cnt_end_o) begin
            cnt_r <= 0;
        end else begin
            cnt_r <= cnt_r + 1;
        end
    end
end
/* verilator lint_off WIDTH */
assign cnt_end_o = cnt_o == CNT_SIZE - 1;
assign cnt_start = (cnt_o == 0);
/* verilator lint_on WIDTH */
endmodule
