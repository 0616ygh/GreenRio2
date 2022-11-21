module fifo_for_freelist #( //p0 is not in the fifo
    parameter FIFO_DATA_WIDTH = 5,
    parameter FIFO_SIZE = 32,
    parameter FIFO_SIZE_WIDTH = 5
) (
    input clk                                               , 
    input rst                                               , 
    input wr_en_i                                             ,   
    input rd_en_i                                             ,   
    input [FIFO_DATA_WIDTH-1:0] wdata_i                       ,                         
    output reg [FIFO_DATA_WIDTH-1:0] rdata_o                  ,                              
    output reg fifo_full_o                                    ,            
    output reg fifo_empty_o                                   ,             
    output reg [FIFO_SIZE_WIDTH:0] fifo_num_o                                      
);
    wire wr_cnt_flag;
    wire rd_cnt_flag;
    wire cnt_cmp_greater;
    wire cnt_cmp_equal;
    wire [FIFO_SIZE_WIDTH-1:0] rd_line;                       
    wire [FIFO_SIZE_WIDTH-1:0] wr_line;
    wire wr_line_end;
    wire rd_line_end;
    wire fifo_turn_arroud; //to show wr and rd both count over a fifo queue size
    reg fifo_recount; //to record wr count over a fifo queue size
    reg [FIFO_DATA_WIDTH-1:0] fifo_queue[FIFO_SIZE-1:0];

    integer i;
    /* verilator lint_off WIDTH */
    //write fifo
    always @(posedge clk) begin            
        if (rst) begin
            for (i = 0; i < FIFO_SIZE ; i = i + 1) begin
                fifo_queue[i] <= i + 1; //initially no p0 in freelist
            end
        end else if (wr_cnt_flag) begin
            fifo_queue[wr_line] <= wdata_i;
        end
    end

    //read fifo
    always @(*) begin
        rdata_o = fifo_queue[rd_line];
    end

    //fifo number calculate
    always @(*) begin
        if (cnt_cmp_greater) begin
            fifo_num_o = wr_line - rd_line;
        end else if (cnt_cmp_equal) begin
            if (fifo_recount) begin
                fifo_num_o = FIFO_SIZE;
            end else begin
                fifo_num_o = 0;
            end
        end else begin
            fifo_num_o = FIFO_SIZE + wr_line - rd_line;
        end
    end

    assign cnt_cmp_greater = wr_line > rd_line;
    assign cnt_cmp_equal = wr_line == rd_line;

    always @(*) begin
        fifo_full_o = (fifo_num_o == FIFO_SIZE);
    end

    always @(*) begin
        fifo_empty_o = fifo_num_o == 0;
    end
    
    //fifo recount
    always @(posedge clk) begin
        if (rst) begin
            fifo_recount <= 1; //initially full in freelist
        end else if (wr_line_end) begin
            fifo_recount <= 1;
        end else if (fifo_turn_arroud) begin
            fifo_recount <= 0;
        end
    end

    assign fifo_turn_arroud = fifo_recount & rd_line_end;

    //write counter
    counter #(
        .CNT_SIZE(FIFO_SIZE),
        .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
    ) wr_cnt(
        .clk(clk),
        .rst(rst),
        .cnt_rst_vector_i(0),
        .cnt_add_flag_i(wr_cnt_flag),
        .cnt_o(wr_line),
        .cnt_end_o(wr_line_end)
    );

    assign wr_cnt_flag = wr_en_i & !fifo_full_o;

    //read counter
    counter #(
        .CNT_SIZE(FIFO_SIZE),
        .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
    ) rd_cnt(
        .clk(clk),
        .rst(rst),
        .cnt_rst_vector_i(0),
        .cnt_add_flag_i(rd_cnt_flag),
        .cnt_o(rd_line),
        .cnt_end_o(rd_line_end)
    );

    assign rd_cnt_flag = rd_en_i & !fifo_empty_o;
    /* verilator lint_on WIDTH */
endmodule

