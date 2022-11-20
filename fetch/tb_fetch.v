`define SYNTHESIS
module tb_top;


reg clk;
reg rst;
reg branch_valid_first_i;
reg branch_valid_second_i;
reg [PC_WIDTH-1:0] btb_req_pc_i;
reg [PC_WIDTH-1:0] btb_predict_target_i;
reg [PC_WIDTH-1:0] prev_pc_first_i;
reg prev_taken_first_i;
reg [PC_WIDTH-1:0] prev_pc_second_i;
reg prev_taken_second_i;
reg [PC_WIDTH-1:0] pc_first_o;
reg [PC_WIDTH-1:0] next_pc_first_o;
reg [PC_WIDTH-1:0] predict_pc_first_o;
reg [31:0] instruction_first_o;
reg is_rv_first_o;
reg is_first_valid_o;
reg [PC_WIDTH-1:0] pc_second_o;
reg [PC_WIDTH-1:0] next_pc_second_o;
reg [PC_WIDTH-1:0] predict_pc_second_o;
reg [31:0] instruction_second_o;
reg is_rv_second_o;
reg is_second_valid_o;
reg [PC_WIDTH-1:0] real_branch_i;
reg global_wfi_i;
reg global_ret_i;
reg global_trap_i;
reg global_predict_miss_i;
reg [PC_WIDTH-1:0] trap_vector_i;
reg [PC_WIDTH-1:0] mret_vector_i;
wire fetch_l1i_if_req_rdy_i;
wire fetch_decode_if_req_first_rdy_i;
wire fetch_decode_if_req_second_rdy_i;
reg l1i_fetch_if_resp_vld_i;
wire [FETCH_WIDTH-1:0] l1i_fetch_if_resp_data_i;
reg fetch_l1i_if_req_vld_o;
reg [L1I_INDEX_WIDTH-1:0] fetch_l1i_if_req_index_o;
reg [L1I_OFFSET_WIDTH-1:0] fetch_l1i_if_req_offset_o;
reg [L1I_TAG_WIDTH-1:0] fetch_l1i_if_req_vtag_o;
reg ins_empty_o;
reg exception_valid_first_o;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o;
reg exception_valid_second_o;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o;
reg [$clog2(IFQ_DEPTH)-1:0] l1i_fetch_if_resp_if_tag_i;
reg [$clog2(IFQ_DEPTH)-1:0] fetch_l1i_if_req_if_tag_o;

reg itlb_fetch_miss_i;
reg itlb_fetch_hit_i;
reg fetch_itlb_req_vld_o;
wire itlb_fetch_resp_excp_vld_i;
wire [EXCEPTION_CAUSE_WIDTH-1:0] itlb_fetch_resp_ecause_i;

assign itlb_fetch_resp_excp_vld_i = 0;
assign itlb_fetch_resp_ecause_i = 0;

wire [15:0] rvc_inst = 16'haaa0;
wire [31:0] rv_inst = 32'haaa3aaa3;
wire [127:0] cacheline_0 = {rv_inst, rv_inst, rv_inst, rv_inst};
wire [127:0] cacheline_1 = {rvc_inst, rvc_inst, rvc_inst, rvc_inst, rvc_inst, rvc_inst, rvc_inst, rvc_inst};
wire [127:0] cacheline_2 = {rvc_inst, rv_inst, rvc_inst, rv_inst, rvc_inst, rvc_inst};
wire [127:0] cacheline_3 = {rv_inst, rv_inst, rvc_inst, rvc_inst, rv_inst};
wire [127:0] icache[3:0];
assign icache[0] = cacheline_0;
assign icache[1] = cacheline_1;
assign icache[2] = cacheline_2;
assign icache[3] = cacheline_3;

wire [PC_WIDTH-1:0] vpc_0 = {{{PC_WIDTH-6}{1'b0}}, 6'b000000};
wire [PC_WIDTH-1:0] vpc_1 = {{{PC_WIDTH-6}{1'b0}}, 6'b010000};
wire [PC_WIDTH-1:0] vpc_2 = {{{PC_WIDTH-6}{1'b0}}, 6'b100000};
wire [PC_WIDTH-1:0] vpc_3 = {{{PC_WIDTH-6}{1'b0}}, 6'b110000};

initial begin
    clk = 0;
    rst = 1;
    branch_valid_first_i = 0;
    branch_valid_second_i = 0;
    btb_req_pc_i = 0;
    btb_predict_target_i = 0;
    prev_pc_first_i = 0;
    prev_taken_first_i = 0;
    prev_pc_second_i = 0;
    prev_taken_second_i = 0;
    real_branch_i = 0;
    global_wfi_i = 0;
    global_ret_i = 0;
    global_trap_i = 0;
    global_predict_miss_i = 0;
    trap_vector_i = 0;
    mret_vector_i = 0;
    #100
    rst = 0;
    #200
    //global_trap_i = 1;
    #1 @(posedge clk)
    global_trap_i = 0;
    #400
    global_predict_miss_i = 1;
    real_branch_i = 32'h0000000c;
    #1 @(posedge clk)
    global_predict_miss_i = 0;
    #10000
    $finish;
end


always #20 clk = ~clk;

wire [128-1:0] dram_wdata     ;
wire [128-1:0] dram_rdata     ;
wire [PC_WIDTH-1:0] dram_waddr  ;
wire [PC_WIDTH-1:0] dram_raddr  ;


dpram64 #(
    .SIZE(1 << 16)         , // byte
    .AXI_DATA_WIDTH(128)   ,
    .mem_clear(1)          ,
    .mem_simple_seq(0)     ,
    .memfile("/work/stu/qyang/workspace/2tapeout/hehecore-2-0/src_new/fetch/selftest/tb_with_depend_2.data")          
) dram_u (
    .clk(clk)           ,
    .we(16'hFFFF)       ,
    .din(dram_wdata)    ,
    .waddr(dram_waddr)  ,
    .raddr(dram_raddr)  ,
    .dout(dram_rdata)   
);

assign fetch_l1i_if_req_rdy_i = 1;
assign fetch_decode_if_req_first_rdy_i = 1;
assign fetch_decode_if_req_second_rdy_i = 1;
reg dff_fetch_l1i_if_req_vld_o = 0;
reg dff_itlb_fetch_hit_i = 0;
always @(posedge clk) begin
    if (rst) begin
        l1i_fetch_if_resp_vld_i <= 0;
        l1i_fetch_if_resp_if_tag_i <= 0;
        itlb_fetch_hit_i <= 0;
        itlb_fetch_miss_i <= 1;
    end else if (fetch_l1i_if_req_vld_o) begin 
        dff_fetch_l1i_if_req_vld_o <= fetch_l1i_if_req_vld_o;
        l1i_fetch_if_resp_vld_i <= dff_fetch_l1i_if_req_vld_o;

        l1i_fetch_if_resp_if_tag_i <= fetch_l1i_if_req_if_tag_o;

        dff_itlb_fetch_hit_i <= 1;
        itlb_fetch_hit_i <= dff_itlb_fetch_hit_i;
        itlb_fetch_miss_i <= ~dff_itlb_fetch_hit_i;
    end else begin
        l1i_fetch_if_resp_vld_i <= 0;
        l1i_fetch_if_resp_if_tag_i <= 0;
        itlb_fetch_hit_i <= 0;
        itlb_fetch_miss_i <= 1;
    end
end
assign l1i_fetch_if_resp_data_i = dram_rdata;
assign dram_raddr = fetch_l1i_if_req_index_o;
///*

fetch fetch_u(
    .clk(clk),
    .rst(rst),
    .branch_valid_first_i(branch_valid_first_i),
    .branch_valid_second_i(branch_valid_second_i),
    .btb_req_pc_i(btb_req_pc_i),
    .btb_predict_target_i(btb_predict_target_i),
    .prev_pc_first_i(prev_pc_first_i),
    .prev_taken_first_i(prev_taken_first_i),
    .prev_pc_second_i(prev_pc_second_i),
    .prev_taken_second_i(prev_taken_second_i),
    .single_rdy_i(fetch_decode_if_req_first_rdy_i),
    .double_rdy_i(fetch_decode_if_req_second_rdy_i),
    .pc_first_o(pc_first_o),
    .next_pc_first_o(next_pc_first_o),
    .predict_pc_first_o(predict_pc_first_o),
    .instruction_first_o(instruction_first_o),
    .is_rv_first_o(is_rv_first_o),
    .is_first_valid_o(is_first_valid_o),
    .pc_second_o(pc_second_o),
    .next_pc_second_o(next_pc_second_o),
    .predict_pc_second_o(predict_pc_second_o),
    .instruction_second_o(instruction_second_o),
    .is_rv_second_o(is_rv_second_o),
    .is_second_valid_o(is_second_valid_o),
    .real_branch_i(real_branch_i),
    .global_wfi_i(global_wfi_i),
    .global_ret_i(global_ret_i),
    .global_trap_i(global_trap_i),
    .global_predict_miss_i(global_predict_miss_i),
    .trap_vector_i(trap_vector_i),
    .mret_vector_i(mret_vector_i),
    .fetch_l1i_if_req_rdy_i(fetch_l1i_if_req_rdy_i),
    .l1i_fetch_if_resp_vld_i(l1i_fetch_if_resp_vld_i),
    .l1i_fetch_if_resp_if_tag_i(l1i_fetch_if_resp_if_tag_i),
    .l1i_fetch_if_resp_data_i(l1i_fetch_if_resp_data_i),
    .fetch_l1i_if_req_vld_o(fetch_l1i_if_req_vld_o),
    .fetch_l1i_if_req_index_o(fetch_l1i_if_req_index_o),
    .fetch_l1i_if_req_if_tag_o(fetch_l1i_if_req_if_tag_o),
    .fetch_l1i_if_req_offset_o(fetch_l1i_if_req_offset_o),
    .fetch_l1i_if_req_vtag_o(fetch_l1i_if_req_vtag_o),
    .itlb_fetch_miss_i(itlb_fetch_miss_i),
    .itlb_fetch_hit_i(itlb_fetch_hit_i),
    .fetch_itlb_req_vld_o(fetch_itlb_req_vld_o),
    .itlb_fetch_resp_excp_vld_i(itlb_fetch_resp_excp_vld_i),
    .itlb_fetch_resp_ecause_i(itlb_fetch_resp_ecause_i),
    .ins_empty_o(ins_empty_o),
    .exception_valid_first_o(exception_valid_first_o),
    .ecause_first_o(ecause_first_o),
    .exception_valid_second_o(exception_valid_second_o),
    .ecause_second_o(ecause_second_o)
);
//*/

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
