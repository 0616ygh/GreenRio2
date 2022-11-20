`include "perips_cfg.vh"

module io_generic_fifo 
#(
    parameter DATA_WIDTH = 32,
    parameter BUFFER_DEPTH = 2,
    parameter LOG_BUFFER_DEPTH = $clog2(BUFFER_DEPTH)
) (
    input  wire                      clk,
    input  wire                      rst,
    input  wire                      clr_i,
    output wire [LOG_BUFFER_DEPTH:0] elements_o,
    output wire [DATA_WIDTH - 1:0]   data_o,
    output wire                      valid_o,
    input  wire                      ready_i,
    input  wire                      valid_i,
    input  wire [DATA_WIDTH - 1:0]   data_i,
    output wire                      ready_o
);
// Internal data structures
reg [LOG_BUFFER_DEPTH - 1:0] pointer_in;      // location to which we last wrote
reg [LOG_BUFFER_DEPTH - 1:0] pointer_out;     // location from which we last sent

reg [LOG_BUFFER_DEPTH:0]     elements;        // number of elements in the buffer
reg [DATA_WIDTH - 1:0]       buffer [BUFFER_DEPTH - 1:0];
wire                         full;


assign full       = (elements == BUFFER_DEPTH);
assign elements_o = elements;

always @(posedge clk) begin
    if (rst | clr_i)
        elements <= 0;
    // 只出不进
    else if ((ready_i && valid_o) && (!valid_i || full))
        elements <= elements - 1;
    // None out, one in
    else if (((!valid_o || !ready_i) && valid_i) && !full)
        elements <= elements + 1;
    // Else, either one out and one in, or none out and none in - stays unchanged
end

integer loop1;
always @(posedge clk) begin : buffers_sequential
    if (rst) begin
        for (loop1 = 0; loop1 < BUFFER_DEPTH; loop1 = loop1 + 1) begin
            buffer[loop1] <= 0;
        end
    end else if (valid_i && !full) begin
        buffer[pointer_in] <= data_i;     // Update the memory
    end
end

always @(posedge clk) begin : sequential
    if (rst | clr_i) begin
        pointer_out <= 0;
        pointer_in  <= 0;
    end else begin
        if (valid_i && !full) begin
            if (pointer_in == $unsigned(BUFFER_DEPTH - 1))
                pointer_in <= 0;
            else
                pointer_in <= pointer_in + 1;
        end
        if (ready_i && valid_o) begin
            if (pointer_out == $unsigned(BUFFER_DEPTH - 1))
                pointer_out <= 0;
            else
                pointer_out <= pointer_out + 1;
        end
    end
end

// Update output ports
assign data_o  = buffer[pointer_out];
assign valid_o = (elements != 0);
assign ready_o = ~full;

endmodule
