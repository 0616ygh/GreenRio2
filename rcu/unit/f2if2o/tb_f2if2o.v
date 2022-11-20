
module tb_top;

parameter FIFO_DATA_WIDTH = 5;
parameter FIFO_SIZE = 32;
parameter FIFO_SIZE_WIDTH = 5;

reg clk                           ;
reg rst                           ;

reg fifo_full_o, fifo_almost_full_o;
reg fifo_empty_o, fifo_almost_empty_o;
reg [FIFO_SIZE_WIDTH:0] fifo_num_o;

wire [FIFO_SIZE_WIDTH-1:0] wrdata_gen_first, wrdata_gen_second;
wire wr_first_en_i, wr_second_en_i, rd_first_en_i, rd_second_en_i;
reg [FIFO_DATA_WIDTH-1:0] do_first_write, do_second_write, do_first_read, do_second_read;
reg [FIFO_DATA_WIDTH-1:0] rdata_first_o, rdata_second_o;
reg excep_rst, rd_excep_first_en_i, rd_excep_second_en_i;

initial begin
    clk = 0;
    rst = 1;
    excep_rst = 1;
    do_first_read = 0;
    do_second_read = 0;
    do_first_write = 0;
    do_second_write = 0;
    rd_excep_first_en_i = 0;
    rd_excep_second_en_i = 0;
    #100
    rst = 0;
    excep_rst = 0;
    //2_PORT_READ_WRITE
    /*
        do_first_write = 1;
        do_second_write = 1;
        #1000
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 1;
        #1000
        do_first_write = 1;
        do_second_write = 1;
    */
    //2_PORT_READ_WRITE
    //1_PORT_READ_WRITE
    /*
        //first port write
        do_first_write = 1;
        #1000
        do_first_write = 0;
        //first port read
        do_first_read = 1;
        #1000
        //first port read & write
        do_first_write = 1;
        #1000
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 0;
        #1000
        do_first_write = 0;
        do_second_write = 1;
        do_first_read = 0;
        do_second_read = 0;
        #1000
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 0;
        do_second_read = 1;
        #1000
        do_first_write = 0;
        do_second_write = 1;
        do_first_read = 1;
        do_second_read = 0;
    */
    //1_PORT_READ_WRITE
    //1_PORT_READ_2_PORT_WRITE
    /*
        do_first_write = 1;
        do_second_write = 1;
        do_first_read = 0;
        do_second_read = 0;
        #1000
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 0;
        #1000
        do_first_write = 1;
        do_second_write = 1;
        do_first_read = 1;
        do_second_read = 0;
        #1000
        do_first_write = 1;
        do_second_write = 1;
        do_first_read = 0;
        do_second_read = 1;
    */
    //1_PORT_READ_2_PORT_WRITE
    //2_PORT_READ_1_PORT_WRITE
    /*
        do_first_write = 1;
        do_second_write = 0;
        do_first_read = 0;
        do_second_read = 0;
        #1000
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 0;
        #1000
        do_first_write = 1;
        do_second_write = 0;
        do_first_read = 0;
        do_second_read = 0;
        #1000
        do_first_write = 0;
        do_second_write = 1;
        do_first_read = 1;
        do_second_read = 1;
    */
    //2_PORT_READ_1_PORT_WRITE
    //Free_list read
    /*
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 0;
        #100
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 1;
        #1000
        do_first_write = 0;
        do_second_write = 1;
        do_first_read = 1;
        do_second_read = 1;
    */
    //2_PORT_READ_1_PORT_WRITE
    //2_PORT_READ_1_PORT_WRITE
    //Free_list read
    // /*
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 0;
        #100
        excep_rst = 1;
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 0;
        #100
        excep_rst = 0;
        #1000
        do_first_write = 1;
        do_second_write = 1;
        do_first_read = 0;
        do_second_read = 0;
        #500
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 1;
        rd_excep_first_en_i = 1;
        rd_excep_second_en_i = 1;
        #100
        do_first_write = 0;
        do_second_write = 0;
        rd_excep_first_en_i = 0;
        rd_excep_second_en_i = 0;
        excep_rst = 1;
        #1000
        excep_rst = 0;
        do_first_write = 0;
        do_second_write = 0;
        do_first_read = 1;
        do_second_read = 1;
    // */
    //2_PORT_READ_1_PORT_WRITE
    #2000
    $finish;
end

assign wr_first_en_i =  (do_first_write ^ do_second_write) ? !fifo_full_o
                                                           : do_first_write & !fifo_full_o;
assign wr_second_en_i = (do_first_write ^ do_second_write) ? 1'b0
                                                           : do_first_write & !fifo_almost_full_o;
assign rd_first_en_i =  (do_first_read ^ do_second_read) ? !fifo_empty_o
                                                         : do_first_read & !fifo_empty_o;
assign rd_second_en_i = (do_first_read ^ do_second_read) ? 1'b0
                                                         : do_first_read & !fifo_almost_empty_o;

always #10 clk = ~clk;

configurable_2mode_counter #(
    .CNT_SIZE(FIFO_SIZE),
    .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
) wr_cnt_first(
    .clk(clk),
    .rst(rst),
    .mode_i({2{wr_first_en_i}}),
    .cnt_rst_vector_i(0),
    .cnt_o(wrdata_gen_first),
    .cnt_end_o(0)
);

configurable_2mode_counter #(
    .CNT_SIZE(FIFO_SIZE),
    .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
) wr_cnt_second(
    .clk(clk),
    .rst(rst),
    .mode_i({2{wr_first_en_i}}),
    .cnt_rst_vector_i(1),
    .cnt_o(wrdata_gen_second),
    .cnt_end_o(0)
);

f2if2o_freelist #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_SIZE(FIFO_SIZE),
    .FIFO_SIZE_WIDTH(FIFO_SIZE_WIDTH)
) fifo_u(
    .clk(clk)                                      ,       
    .rst(rst)                                      ,       
    .excep_rst_i(excep_rst)                        , 
    .wr_first_en_i(wr_first_en_i)                  ,      
    .wr_second_en_i(wr_second_en_i)                ,      
    .rd_first_en_i(rd_first_en_i)                  ,       
    .rd_excep_first_en_i(rd_excep_first_en_i)      ,       
    .rd_second_en_i(rd_second_en_i)                ,      
    .rd_excep_second_en_i(rd_excep_second_en_i)    ,      
    .wdata_first_i(wrdata_gen_first)               ,      
    .wdata_second_i(wrdata_gen_second)             ,      
    .rdata_first_o(rdata_first_o)                  ,      
    .rdata_second_o(rdata_second_o)                ,      
    .fifo_full_o(fifo_full_o)                      ,      
    .fifo_almost_full_o(fifo_almost_full_o)        ,      
    .fifo_empty_o(fifo_empty_o)                    ,      
    .fifo_almost_empty_o(fifo_almost_empty_o)      ,      
    .fifo_num_o(fifo_num_o)                              
);

/*
f2if2o #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_SIZE(FIFO_SIZE),
    .FIFO_SIZE_WIDTH(FIFO_SIZE_WIDTH)
) fifo(
    .clk(clk)                                      ,       
    .rst(rst)                                      ,       
    .wr_first_en_i(wr_first_en_i)                  ,      
    .wr_second_en_i(wr_second_en_i)                ,      
    .rd_first_en_i(rd_first_en_i)                  ,      
    .rd_second_en_i(rd_second_en_i)                ,      
    .wdata_first_i(wrdata_gen_first)               ,      
    .wdata_second_i(wrdata_gen_second)             ,      
    .rdata_first_o(rdata_first_o)                  ,      
    .rdata_second_o(rdata_second_o)                ,      
    .fifo_full_o(fifo_full_o)                      ,      
    .fifo_almost_full_o(fifo_almost_full_o)        ,      
    .fifo_empty_o(fifo_empty_o)                    ,      
    .fifo_almost_empty_o(fifo_almost_empty_o)      ,      
    .fifo_num_o(fifo_num_o)                              
);
*/

initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("!!!!!!!!!!wave_log= %s",log);
    end
    wav = {log,"/waves.fsdb"};
    $display("!!!!!!wave_log= %s",wav);
    if(dumpon > 0) begin
      $fsdbDumpfile(wav);
      $fsdbDumpvars(0,tb_top);
      $fsdbDumpvars("+struct");
      $fsdbDumpvars("+mda");
      $fsdbDumpvars("+all");
      $fsdbDumpon;
    end
end

endmodule : tb_top
