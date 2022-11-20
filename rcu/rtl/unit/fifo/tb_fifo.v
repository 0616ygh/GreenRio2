module tb_top;

parameter FIFO_DATA_WIDTH = 5;
parameter FIFO_SIZE = 31;
parameter FIFO_SIZE_WIDTH = 5;

reg clk                           ;
reg rst                           ;
wire wr_en                        ;    
wire rd_en                        ;   
reg [FIFO_DATA_WIDTH-1:0] wdata   ;    
reg [FIFO_DATA_WIDTH-1:0] rdata   ;
reg fifo_full                     ;
reg fifo_empty                    ;
reg [FIFO_SIZE_WIDTH:0] fifo_num;

wire [FIFO_SIZE_WIDTH-1:0] wrdata_gen;
reg do_write, do_read;

initial begin
    clk = 0;
    rst = 1;
    do_read = 0;
    do_write = 0;
    wdata = 0;
    #100
    rst = 0;
    do_write = 1;
    #1000
    do_write = 0;
    do_read = 1; 
    #2000
    do_write = 1;
    #10000
    $finish;
end

always @(posedge clk) begin 
    if(rst) begin
        wdata <= 0;
    end else begin
        wdata <= wrdata_gen;
    end
end

assign wr_en = do_write & !fifo_full;
assign rd_en = do_read & !fifo_empty;

always #10 clk = ~clk;

counter #(
    .CNT_SIZE(FIFO_SIZE),
    .CNT_SIZE_WIDTH(FIFO_SIZE_WIDTH)
) rd_cnt(
    .clk(clk),
    .rst(rst),
    .cnt_rst_vector_i(0),
    .cnt_add_flag_i(!fifo_full),
    .cnt_o(wrdata_gen),
    .cnt_end_o(0)
);

// fifo #(
fifo_for_freelist #(
    .FIFO_DATA_WIDTH(FIFO_DATA_WIDTH),
    .FIFO_SIZE(FIFO_SIZE),
    .FIFO_SIZE_WIDTH(FIFO_SIZE_WIDTH)
) fifo(
    .clk(clk),
    .rst(rst),
    .wr_en_i(wr_en),
    .rd_en_i(rd_en),
    .wdata_i(wdata),
    .rdata_o(rdata),
    .fifo_full_o(fifo_full),
    .fifo_empty_o(fifo_empty),
    .fifo_num_o(fifo_num)
);

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

endmodule
