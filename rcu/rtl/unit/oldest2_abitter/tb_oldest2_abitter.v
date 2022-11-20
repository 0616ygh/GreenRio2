module tb_top;

parameter PRIORITY_WIDTH = 4;
parameter SEL_WIDTH = 16;

reg clk;
reg rst_n, flag;
reg [PRIORITY_WIDTH-1:0] priority_fix;
reg [SEL_WIDTH-1:0] req;
reg [PRIORITY_WIDTH-1:0] first_grant_index;
reg [PRIORITY_WIDTH-1:0] second_grant_index;
reg first_grant_valid, second_grant_valid;

initial begin
    clk = 0;
    rst_n = 0;
    #100
    rst_n = 1;
    priority_fix = 0;
    #2000
    priority_fix = 1;
    #2000
    priority_fix = 2;
    #2000
    priority_fix = 3;
    #2000
    priority_fix = 4;
    #2000
    priority_fix = 5;
    #2000
    priority_fix = 6;
    #2000
    priority_fix = 7;
    #100000
    $finish;
end

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

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        req <= 0;
    end else if (req <= {SEL_WIDTH{1'b1}}) begin
        req <= req + 1;
        flag <= 1;
    end else begin
        req <= 0;
        flag <= 0;
    end
end

// always @(posedge clk) begin
//     if (!rst_n) begin
//         priority_fix <= 0;
//     end else if(!flag) begin
//         priority_fix = priority_fix + 1;
//     end
// end

always #10 clk = ~clk;

oldest2_abitter #(
    .SEL_WIDTH(SEL_WIDTH),
    .PRIORITY_WIDTH(PRIORITY_WIDTH)
)oldest2_abitter_u(
    .priority_fix_i(priority_fix),
    .req_i(req),
    .first_grant_valid_o(first_grant_valid),
    .first_grant_index_o(first_grant_index),
    .second_grant_valid_o(second_grant_valid),
    .second_grant_index_o(second_grant_index)
);

endmodule
