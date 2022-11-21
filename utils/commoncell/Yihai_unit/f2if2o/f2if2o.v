module f2if2o #( //fifo for probable two input and probable two output
    parameter FIFO_DATA_WIDTH = 5,
    parameter FIFO_SIZE = 32,
    parameter FIFO_SIZE_WIDTH = 5
) (
    input clk                                               ,
    input rst                                               ,
    input wr_first_en_i                                     ,
    input wr_second_en_i                                    ,
    input rd_first_en_i                                     , 
    input rd_second_en_i                                    , 
    input [FIFO_DATA_WIDTH-1:0] wdata_first_i               ,                
    input [FIFO_DATA_WIDTH-1:0] wdata_second_i              ,                 
    output reg [FIFO_DATA_WIDTH-1:0] rdata_first_o          ,                           
    output reg [FIFO_DATA_WIDTH-1:0] rdata_second_o         ,                            
    output reg fifo_full_o                                  , 
    output reg fifo_almost_full_o                           , 
    output reg fifo_empty_o                                 ,  
    output reg fifo_almost_empty_o                          ,  
    output reg [FIFO_SIZE_WIDTH:0] fifo_num_o                          
);
    wire [1:0] wr_cnt_flag;
    wire [1:0] rd_cnt_flag;
    wire cnt_cmp_greater;
    wire cnt_cmp_equal;
    wire [FIFO_SIZE_WIDTH-1:0] rd_line;
    wire [FIFO_SIZE_WIDTH-1:0] rd_second_line;
    wire [FIFO_SIZE_WIDTH-1:0] wr_line;
    wire [FIFO_SIZE_WIDTH-1:0] wr_second_line;
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
                fifo_queue[i] <= 0;
            end
        end else if (wr_first_en_i & wr_second_en_i) begin
            fifo_queue[wr_line] <= wdata_first_i;
            fifo_queue[wr_second_line] <= wdata_second_i;
        end else if (wr_first_en_i) begin
            fifo_queue[wr_line] <= wdata_first_i;
        end else if (wr_second_en_i) begin
            fifo_queue[wr_line] <= wdata_second_i;
        end
    end
    assign wr_second_line = (wr_line == FIFO_SIZE - 1) ? 0 
                                                       : wr_line + 1;
    //read fifo
    always @(*) begin
        rdata_first_o = 0;
        rdata_second_o = 0;
        case({rd_second_en_i, rd_first_en_i})
            2'b01 : begin
                rdata_first_o = fifo_queue[rd_line];
            end
            2'b10 : begin
                rdata_second_o = fifo_queue[rd_line];
            end
            2'b11 : begin
                rdata_first_o = fifo_queue[rd_line];
                rdata_second_o = fifo_queue[rd_second_line];
            end
        endcase
    end
    assign rd_second_line = (rd_line == FIFO_SIZE - 1) ? 0 
                                                       : rd_line + 1;

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
        fifo_full_o = fifo_num_o == FIFO_SIZE;
        fifo_almost_full_o = fifo_num_o >= FIFO_SIZE - 1;
    end

    always @(*) begin
        fifo_empty_o = fifo_num_o == 0;
        fifo_almost_empty_o = fifo_num_o <= 1;
    end
    
    //fifo recount
    always @(posedge clk) begin 
        if (rst) begin
            fifo_recount <= 0;
        end else if (wr_line_end) begin
            fifo_recount <= 1;
        end else if (fifo_turn_arroud) begin
            fifo_recount <= 0;
        end
    end

    assign fifo_turn_arroud = fifo_recount & rd_line_end;

    //write counter
    configurable_2mode_counter #(
        .CNT_SIZE(FIFO_SIZE),
        .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
    ) wr_cnt(
        .clk(clk),
        .rst(rst),
        .mode_i(wr_cnt_flag),
        .cnt_rst_vector_i(0),
        .cnt_o(wr_line),
        .cnt_end_o(wr_line_end)
    );

    assign wr_cnt_flag = {wr_second_en_i, wr_first_en_i};
    // assign wr_cnt_flag = {wr_second_en_i, wr_first_en_i} & {!fifo_almost_full_o ,!fifo_full_o};

    //read counter
    configurable_2mode_counter #(
        .CNT_SIZE(FIFO_SIZE),
        .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
    ) rd_cnt(
        .clk(clk),
        .rst(rst),
        .mode_i(rd_cnt_flag),
        .cnt_rst_vector_i(0),
        .cnt_o(rd_line),
        .cnt_end_o(rd_line_end)
    );
    assign rd_cnt_flag = {rd_second_en_i, rd_first_en_i};
    // assign rd_cnt_flag = {rd_second_en_i, rd_first_en_i} & {!fifo_almost_empty_o ,!fifo_empty_o};
    /* verilator lint_on WIDTH */
endmodule

