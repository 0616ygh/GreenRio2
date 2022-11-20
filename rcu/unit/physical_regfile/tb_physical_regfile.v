module tb_top;

parameter REG_SIZE = 48;
parameter REG_SIZE_WIDTH = 6;

reg clk                                            ;
reg rst                                            ;
reg [REG_SIZE_WIDTH-1:0] prs1_address_first_i      ;
reg [REG_SIZE_WIDTH-1:0] prs2_address_first_i      ;
reg [REG_SIZE_WIDTH-1:0] prs1_address_second_i     ;
reg [REG_SIZE_WIDTH-1:0] prs2_address_second_i     ;
reg [63:0] prs1_data_first_o                       ;
reg [63:0] prs2_data_first_o                       ;
reg [63:0] prs1_data_second_o                      ;
reg [63:0] prs2_data_second_o                      ;
reg [REG_SIZE_WIDTH-1:0] alu1_wrb_address_i        ;
reg [REG_SIZE_WIDTH-1:0] alu2_wrb_address_i        ;
reg [REG_SIZE_WIDTH-1:0] lsu_wrb_address_i         ;
reg [REG_SIZE_WIDTH-1:0] md_wrb_address_i          ;
reg [63:0] alu1_wrb_data_i                         ;
reg [63:0] alu2_wrb_data_i                         ;
reg [63:0] lsu_wrb_data_i                          ;
reg [63:0] md_wrb_data_i                           ;
reg alu1_rcu_resp_valid_i                          ;
reg alu2_rcu_resp_valid_i                          ;
reg lsu_rcu_resp_valid_i                           ;
reg md_rcu_resp_valid_i                            ;

initial begin
    clk = 0;
    rst = 1;
    #100
    rst = 0;
    #10000;
    $finish;
end

always #10 clk = ~clk;

always @(posedge clk) begin
    if(rst) begin
        prs1_address_first_i  <= 0;
        prs2_address_first_i  <= 0;
        prs1_address_second_i <= 0;
        prs2_address_second_i <= 0;
        alu1_wrb_address_i    <= 0;
        alu2_wrb_address_i    <= 0;
        lsu_wrb_address_i     <= 0;
        md_wrb_address_i      <= 0;
        alu1_wrb_data_i       <= 0;
        alu2_wrb_data_i       <= 0;
        lsu_wrb_data_i        <= 0;
        md_wrb_data_i         <= 0;
        alu1_rcu_resp_valid_i <= 0;
        alu2_rcu_resp_valid_i <= 0;
        lsu_rcu_resp_valid_i  <= 0;
        md_rcu_resp_valid_i   <= 0;
    end else begin
        prs1_address_first_i  <= {$random} % 48;    
        prs2_address_first_i  <= {$random} % 48;    
        prs1_address_second_i <= {$random} % 48;    
        prs2_address_second_i <= {$random} % 48;    
        alu1_wrb_address_i    <= {$random} % 48;    
        alu2_wrb_address_i    <= {$random} % 48;    
        lsu_wrb_address_i     <= {$random} % 48;    
        md_wrb_address_i      <= {$random} % 48;    
        alu1_wrb_data_i       <= {$random} % 1000000000;    
        alu2_wrb_data_i       <= {$random} % 1000000000;    
        lsu_wrb_data_i        <= {$random} % 1000000000;    
        md_wrb_data_i         <= {$random} % 1000000000;    
        alu1_rcu_resp_valid_i <= {$random} % 2 ;    
        alu2_rcu_resp_valid_i <= {$random} % 2 ;    
        lsu_rcu_resp_valid_i  <= {$random} % 2 ;    
        md_rcu_resp_valid_i   <= {$random} % 2 ;    
    end
end

physical_regfile #(
    .REG_SIZE(REG_SIZE),
    .REG_SIZE_WIDTH(REG_SIZE_WIDTH)
)physical_regfile_u(
    .clk                      (clk)                      ,
    .rst                      (rst)                      ,
    .prs1_address_first_i     (prs1_address_first_i)     ,
    .prs2_address_first_i     (prs2_address_first_i)     ,
    .prs1_address_second_i    (prs1_address_second_i)    ,
    .prs2_address_second_i    (prs2_address_second_i)    ,
    .prs1_data_first_o        (prs1_data_first_o)        ,
    .prs2_data_first_o        (prs2_data_first_o)        ,
    .prs1_data_second_o       (prs1_data_second_o)       ,
    .prs2_data_second_o       (prs2_data_second_o)       ,
    .alu1_wrb_address_i       (alu1_wrb_address_i)       ,
    .alu2_wrb_address_i       (alu2_wrb_address_i)       ,
    .lsu_wrb_address_i        (lsu_wrb_address_i)        ,
    .md_wrb_address_i         (md_wrb_address_i)         ,
    .alu1_wrb_data_i          (alu1_wrb_data_i)          ,
    .alu2_wrb_data_i          (alu2_wrb_data_i)          ,
    .lsu_wrb_data_i           (lsu_wrb_data_i)           ,
    .md_wrb_data_i            (md_wrb_data_i)            ,
    .alu1_rcu_resp_valid_i    (alu1_rcu_resp_valid_i)    ,
    .alu2_rcu_resp_valid_i    (alu2_rcu_resp_valid_i)    ,
    .lsu_rcu_resp_valid_i     (lsu_rcu_resp_valid_i)     ,
    .md_rcu_resp_valid_i      (md_rcu_resp_valid_i)                           
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
