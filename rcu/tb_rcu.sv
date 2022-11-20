import "DPI-C" function void trans_var ( 
    output bit out,
    input bit in
    );

module tb_top;

reg clk;
reg rst;
reg [PC_WIDTH-1:0] pc_first_i;
reg [PC_WIDTH-1:0] pc_second_i;
reg [PC_WIDTH-1:0] next_pc_first_i;
reg [PC_WIDTH-1:0] next_pc_second_i;
reg [PC_WIDTH-1:0] predicted_pc_first_i;
reg [PC_WIDTH-1:0] predicted_pc_second_i;
reg is_rv_first_i;
reg is_rv_second_i;
reg [31:0] instruction_first_i;
reg [31:0] instruction_second_i;
reg exception_first_i;
reg exception_second_i;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_i;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_i;
reg fetch_deco_req_valid_first_i;
reg fetch_deco_req_valid_second_i;
reg deco_rob_req_ready_first_i;
reg deco_rob_req_ready_second_i;
reg global_wfi_i;
reg global_predict_miss_i;
reg sip_i;
reg tip_i;
reg eip_i;
reg [1:0] privilege_mode_i;
reg fetch_deco_req_ready_o;
reg uses_rs1_first_o;
reg uses_rs1_second_o;
reg uses_rs2_first_o;
reg uses_rs2_second_o;
reg uses_rd_first_o;
reg uses_rd_second_o;
reg uses_csr_first_o;
reg uses_csr_second_o;
reg [PC_WIDTH-1 :0] pc_first_o;
reg [PC_WIDTH-1 :0] pc_second_o;
reg [PC_WIDTH-1 :0] next_pc_first_o;
reg [PC_WIDTH-1 :0] next_pc_second_o;
reg [PC_WIDTH-1 :0] predicted_pc_first_o;
reg [PC_WIDTH-1 :0] predicted_pc_second_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_first_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_second_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_first_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_second_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_first_o;
reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_second_o;
reg [CSR_ADDR_LEN-1:0] csr_address_first_o;
reg [CSR_ADDR_LEN-1:0] csr_address_second_o;
reg mret_first_o;
reg mret_second_o;
reg sret_first_o;
reg sret_second_o;
reg wfi_first_o;
reg wfi_second_o;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o;
reg exception_first_o;
reg exception_second_o;
reg half_first_o;
reg half_second_o;
reg is_fence_first_o;
reg is_fence_second_o;
reg [1:0] fence_op_first_o;
reg [1:0] fence_op_second_o;
reg is_aext_first_o;
reg is_aext_second_o;
reg is_mext_first_o;
reg is_mext_second_o;
reg deco_rob_req_valid_first_o;
reg deco_rob_req_valid_second_o;
reg csr_read_first_o;
reg csr_read_second_o;
reg csr_write_first_o;
reg csr_write_second_o;
reg [31:0] imm_data_first_o;
reg [31:0] imm_data_second_o;
reg [2:0] fu_function_first_o;
reg [2:0] fu_function_second_o;
reg alu_function_modifier_first_o;
reg alu_function_modifier_second_o;
reg [1:0] fu_select_a_first_o;
reg [1:0] fu_select_a_second_o;
reg [1:0] fu_select_b_first_o;
reg [1:0] fu_select_b_second_o;
reg jump_first_o;
reg jump_second_o;
reg branch_first_o;
reg branch_second_o;
reg is_alu_first_o;
reg is_alu_second_o;
reg load_first_o;
reg load_second_o;
reg store_first_o;
reg store_second_o;
reg [LDU_OP_WIDTH-1:0] ldu_op_first_o;
reg [LDU_OP_WIDTH-1:0] ldu_op_second_o;
reg [STU_OP_WIDTH-1:0] stu_op_first_o;
reg [STU_OP_WIDTH-1:0] stu_op_second_o;
reg aq_first_o;
reg aq_second_o;
reg rl_first_o;
reg rl_second_o;

reg global_trap_i                                         ;
reg global_ret_i                                          ;
reg deco_rob_req_valid_first_i                            ;
reg deco_rob_req_valid_second_i                           ;
reg deco_rob_req_ready_first_o                            ;
reg deco_rob_req_ready_second_o                           ;
reg uses_rs1_first_i                                      ;
reg uses_rs1_second_i                                     ;
reg uses_rs2_first_i                                      ;
reg uses_rs2_second_i                                     ;
reg uses_rd_first_i                                       ;
reg uses_rd_second_i                                      ;
reg uses_csr_first_i                                      ;
reg uses_csr_second_i                                     ;
reg [PC_WIDTH-1:0] rcu_pc_first_i                         ;
reg [PC_WIDTH-1:0] rcu_pc_second_i                        ;
reg [PC_WIDTH-1:0] rcu_next_pc_first_i                    ;
reg [PC_WIDTH-1:0] rcu_next_pc_second_i                   ;
reg [PC_WIDTH-1:0] rcu_predict_pc_first_i                 ;
reg [PC_WIDTH-1:0] rcu_predict_pc_second_i                ;
reg [5:0] rs1_address_first_i                             ;
reg [5:0] rs1_address_second_i                            ;
reg [5:0] rs2_address_first_i                             ;
reg [5:0] rs2_address_second_i                            ;
reg [5:0] rd_address_first_i                              ;
reg [5:0] rd_address_second_i                             ;
reg [11:0] csr_address_first_i                            ;
reg [11:0] csr_address_second_i                           ;
reg mret_first_i                                          ;
reg mret_second_i                                         ;
reg sret_first_i                                          ;
reg sret_second_i                                         ;
reg wfi_first_i                                           ;
reg wfi_second_i                                          ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] rcu_ecause_first_i        ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] rcu_ecause_second_i       ;
reg rcu_exception_first_i                                 ;
reg rcu_exception_second_i                                ;
reg half_first_i                                          ;
reg half_second_i                                         ;
reg is_fence_first_i                                      ;
reg is_fence_second_i                                     ;
reg [1:0] fence_op_first_i                                ;
reg [1:0] fence_op_second_i                               ;
reg is_aext_first_i                                       ;
reg is_aext_second_i                                      ;
reg is_mext_first_i                                       ;
reg is_mext_second_i                                      ;
reg csr_read_first_i                                      ;
reg csr_read_second_i                                     ;
reg csr_write_first_i                                     ;
reg csr_write_second_i                                    ;
reg [31:0] imm_data_first_i                               ;
reg [31:0] imm_data_second_i                              ;
reg [2:0] fu_function_first_i                             ;
reg [2:0] fu_function_second_i                            ;
reg alu_function_modifier_first_i                         ;
reg alu_function_modifier_second_i                        ;
reg [1:0] fu_select_a_first_i                             ;
reg [1:0] fu_select_a_second_i                            ;
reg [1:0] fu_select_b_first_i                             ;
reg [1:0] fu_select_b_second_i                            ;
reg jump_first_i                                          ;
reg jump_second_i                                         ;
reg branch_first_i                                        ;
reg branch_second_i                                       ;
reg is_alu_first_i                                        ;
reg is_alu_second_i                                       ;
reg load_first_i                                          ;
reg load_second_i                                         ;
reg store_first_i                                         ;
reg store_second_i                                        ;
reg [LDU_OP_WIDTH-1:0] ldu_op_first_i                     ;
reg [LDU_OP_WIDTH-1:0] ldu_op_second_i                    ;
reg [STU_OP_WIDTH-1:0] stu_op_first_i                     ;
reg [STU_OP_WIDTH-1:0] stu_op_second_i                    ;
reg aq_first_i                                            ;
reg aq_second_i                                           ;
reg rl_first_i                                            ;
reg rl_second_i                                           ;
reg func_alu1_done_valid_i                                ;
reg func_alu2_done_valid_i                                ;
reg func_lsu_done_valid_i                                 ;
reg func_md_done_valid_i                                  ;
reg func_csru_done_valid_i                                ;
reg [PHY_REG_ADDR_WIDTH-1:0] physical_alu1_wrb_addr_i     ; 
reg [PHY_REG_ADDR_WIDTH-1:0] physical_csru_wrb_addr_i     ;
reg [PHY_REG_ADDR_WIDTH-1:0] physical_alu2_wrb_addr_i     ; 
reg [PHY_REG_ADDR_WIDTH-1:0] physical_lsu_wrb_addr_i      ; 
reg [PHY_REG_ADDR_WIDTH-1:0] physical_md_wrb_addr_i       ;
reg alu1_predict_miss_i                                   ;
reg alu1_branch_taken_i                                   ;
reg alu1_final_branch_pc_i                                ;
reg alu2_predict_miss_i                                   ;
reg alu2_branch_taken_i                                   ;
reg alu2_final_branch_pc_i                                ;
reg [ROB_INDEX_WIDTH-1:0] func_alu1_rob_index_i           ;
reg [ROB_INDEX_WIDTH-1:0] func_alu2_rob_index_i           ;
reg [ROB_INDEX_WIDTH-1:0] func_lsu_rob_index_i            ;
reg [ROB_INDEX_WIDTH-1:0] func_md_rob_index_i             ;
reg [ROB_INDEX_WIDTH-1:0] func_csru_rob_index_i           ;
reg [XLEN-1:0] physical_alu1_wrb_data_i                   ; 
reg [XLEN-1:0] physical_csru_wrb_data_i                   ; 
reg [XLEN-1:0] physical_alu2_wrb_data_i                   ; 
reg [XLEN-1:0] physical_lsu_wrb_data_i                    ; 
reg [XLEN-1:0] physical_md_wrb_data_i                     ;
reg func_wrb_alu1_exp_i                                   ;
reg func_wrb_alu2_exp_i                                   ;
reg func_wrb_lsu_exp_i                                    ;
reg func_wrb_md_exp_i                                     ;
reg func_wrb_csru_exp_i                                   ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_alu1_ecause_i    ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_alu2_ecause_i    ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_lsu_ecause_i     ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_md_ecause_i      ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_csru_ecause_i    ;
reg rcu_alu1_req_valid_o                                  ;
reg rcu_alu2_req_valid_o                                  ;
reg rcu_md_req_ready_i                                    ;
reg rcu_md_req_valid_o                                    ;
reg rcu_lsu_req_ready_i                                   ;
reg rcu_lsu_req_valid_o                                   ;
reg rcu_csr_req_valid_o                                   ;
reg rcu_lsu_wakeup_o                                      ;
reg [ROB_INDEX_WIDTH-1:0] rcu_lsu_wakeup_index_o          ;
reg [ROB_INDEX_WIDTH-1:0] rcu_alu1_rob_index_o            ;
reg [PHY_REG_ADDR_WIDTH-1:0] rcu_alu1_prd_address_o       ;
reg [2:0] rcu_alu1_func3_o                                ;
reg [PC_WIDTH-1:0] rcu_alu1_pc_o                          ;
reg [PC_WIDTH-1:0] rcu_alu1_next_pc_o                     ;
reg [PC_WIDTH-1:0] rcu_alu1_predict_pc_o                  ;
reg [IMM_LEN-1:0] rcu_alu1_imm_data_o                     ;
reg [1:0] rcu_alu1_select_a_o                             ;
reg [1:0] rcu_alu1_select_b_o                             ;
reg [XLEN-1:0] rcu_alu1_rs1_data_o                        ;
reg [XLEN-1:0] rcu_alu1_rs2_data_o                        ;
reg  rcu_alu1_jump_o                                      ;
reg  rcu_alu1_branch_o                                    ;
reg  rcu_alu1_half_o                                      ;
reg  rcu_alu1_func_modifier_o                             ;
reg [ROB_INDEX_WIDTH-1:0] rcu_alu2_rob_index_o            ;
reg [PHY_REG_ADDR_WIDTH-1:0] rcu_alu2_prd_address_o       ;
reg [2:0] rcu_alu2_func3_o                                ;
reg [PC_WIDTH-1:0] rcu_alu2_pc_o                          ;
reg [PC_WIDTH-1:0] rcu_alu2_next_pc_o                     ;
reg [PC_WIDTH-1:0] rcu_alu2_predict_pc_o                  ;
reg [IMM_LEN-1:0] rcu_alu2_imm_data_o                     ;
reg [1:0] rcu_alu2_select_a_o                             ;
reg [1:0] rcu_alu2_select_b_o                             ;
reg [XLEN-1:0] rcu_alu2_rs1_data_o                        ;
reg [XLEN-1:0] rcu_alu2_rs2_data_o                        ;
reg  rcu_alu2_jump_o                                      ;
reg  rcu_alu2_branch_o                                    ;
reg  rcu_alu2_half_o                                      ;
reg  rcu_alu2_func_modifier_o                             ;
reg [MD_DATA_WIDTH-1:0] rcu_md_package_o                  ;
reg [LSU_DATA_WIDTH-1:0] rcu_lsu_package_o                ;
reg [ROB_INDEX_WIDTH-1:0] rcu_csr_rob_index_o             ;
reg [PHY_REG_ADDR_WIDTH-1:0] rcu_csr_prd_address_o        ;
reg [2:0] rcu_csr_func3_o                                 ;
reg [XLEN-1:0] rcu_csr_rs1_data_o                         ;
reg [IMM_LEN-1:0] rcu_csr_imm_data_o                      ;
reg [CSR_ADDR_LEN-1:0] rcu_csr_address_o                  ;
reg rcu_csr_do_read_o                                     ;
reg rcu_csr_do_write_o                                    ;
reg rcu_bpu_cmt_is_branch_o                               ;
reg rcu_bpu_cmt_branch_taken_o                            ;
reg [PC_WIDTH-1:0] rcu_bpu_cmt_final_pc_o                 ;
reg [PC_WIDTH-1:0] rcu_bpu_cmt_pc_o                       ;
reg rcu_do_rob_commit_first_o                             ;
reg rcu_do_rob_commit_second_o                            ;
reg [PC_WIDTH-1:0] rcu_cmt_pc_o                           ;
reg predict_miss_o                                        ;
reg rcu_cmt_exception_o                                   ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] rcu_cmt_ecause_o          ;
reg rcu_cmt_is_mret                                       ;
reg rcu_cmt_is_sret                                       ;
reg rcu_cmt_is_wfi                                        ;

//lsu
wire lsu_rob_index      ;
wire lsu_prd_address    ;
wire lsu_rs1_data       ;
wire lsu_rs2_data       ;
wire lsu_imm            ;
wire lsu_is_load        ;
wire lsu_is_store       ;
wire lsu_ld_opcode      ;
wire lsu_st_opcode      ;
wire lsu_lsu_fence      ;
wire lsu_lsu_fence_op   ;
wire lsu_aext           ;
//: lsu

integer i;
integer j;
reg[31:0] instr_buffer[0:63];

// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_no_depend.data", instr_buffer); //no dependency
initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_with_depend.data", instr_buffer); //with dependency
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_depend_comb.data", instr_buffer); //both
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_c_depend_comb.data", instr_buffer); //both

initial begin
    clk                             = 0;
    rst                             = 1;
    pc_first_i                      = 32'h8000_0000;
    pc_second_i                     = 32'h8000_0004;
    next_pc_first_i                 = 32'h8000_0004;
    next_pc_second_i                = 32'h8000_0008;
    predicted_pc_first_i            = 32'h8000_0004;
    predicted_pc_second_i           = 32'h8000_0008;
    is_rv_first_i                   = 1;
    is_rv_second_i                  = 1;
    instruction_first_i             = 32'h0000_0013;
    instruction_second_i            = 32'h0000_0013;
    exception_first_i               = 0;
    exception_second_i              = 0;
    ecause_first_i                  = 0;
    ecause_second_i                 = 0;
    fetch_deco_req_valid_first_i    = 0;
    fetch_deco_req_valid_second_i   = 0;
    global_predict_miss_i           = 0;
    global_trap_i                   = 0;
    global_wfi_i                    = 0;
    global_ret_i                    = 0;
    sip_i                           = 0;
    tip_i                           = 0;
    eip_i                           = 0;
    privilege_mode_i                = 3;
    func_alu1_done_valid_i          = 0;
    func_alu2_done_valid_i          = 0;
    func_lsu_done_valid_i           = 0;
    func_md_done_valid_i            = 0;
    func_csru_done_valid_i          = 0;
    physical_alu1_wrb_addr_i        = 0;
    physical_csru_wrb_addr_i        = 0;
    physical_alu2_wrb_addr_i        = 0;
    physical_lsu_wrb_addr_i         = 0;
    physical_md_wrb_addr_i          = 0;
    alu1_predict_miss_i             = 0;
    alu1_branch_taken_i             = 0;
    alu1_final_branch_pc_i          = 0;
    alu2_predict_miss_i             = 0;
    alu2_branch_taken_i             = 0;
    alu2_final_branch_pc_i          = 0;
    func_alu1_rob_index_i           = 0;
    func_alu2_rob_index_i           = 0;
    func_lsu_rob_index_i            = 0;
    func_md_rob_index_i             = 0;
    func_csru_rob_index_i           = 0;
    physical_alu1_wrb_data_i        = 0;
    physical_csru_wrb_data_i        = 0;
    physical_alu2_wrb_data_i        = 0;
    physical_lsu_wrb_data_i         = 0;
    physical_md_wrb_data_i          = 0;
    func_wrb_alu1_exp_i             = 0;
    func_wrb_alu2_exp_i             = 0;
    func_wrb_lsu_exp_i              = 0;
    func_wrb_md_exp_i               = 0;
    func_wrb_csru_exp_i             = 0;
    func_wrb_alu1_ecause_i          = 0;
    func_wrb_alu2_ecause_i          = 0;
    func_wrb_lsu_ecause_i           = 0;
    func_wrb_md_ecause_i            = 0;
    func_wrb_csru_ecause_i          = 0;
    rcu_md_req_ready_i              = 0;
    rcu_lsu_req_ready_i             = 0;
    #80
    rst                             = 0;
    #10000
    $finish;
end

wire [31:0] count; 
reg [PC_WIDTH-1:0] pc_first, pc_second;

always @(posedge clk) begin
    if (rst) begin
        pc_first_i <= 0;
        pc_second_i <= 0;
        next_pc_first_i <= 0;
        next_pc_second_i <= 0;
        predicted_pc_first_i <= 0;
        predicted_pc_first_i <= 0;
        instruction_first_i <= 0;
        instruction_second_i <= 0;
        fetch_deco_req_valid_first_i <= 0;
        fetch_deco_req_valid_second_i <= 0;
    end else if(fetch_deco_req_ready_o) begin
        pc_first_i <= pc_first;
        pc_second_i <= pc_second;
        next_pc_first_i <= pc_first + (is_rv_first_i? 4 : 2);
        next_pc_second_i <= pc_second + (is_rv_second_i? 4 : 2);
        predicted_pc_first_i <= pc_first + (is_rv_first_i? 4 : 2);
        predicted_pc_first_i <= pc_second + (is_rv_second_i? 4 : 2);
        instruction_first_i <= instr_buffer[count];
        instruction_second_i <= instr_buffer[count + 1];
        fetch_deco_req_valid_first_i <= 1;
        fetch_deco_req_valid_second_i <= 1;
    end
end

assign pc_first = 32'h8000_0000 + count * (is_rv_first_i? 4 : 2);
assign pc_second = 32'h8000_0000 + (count + 1) * (is_rv_second_i? 4 : 2);

configurable_2mode_counter #(
    .CNT_SIZE(40),
    .CNT_SIZE_WIDTH(6)
) wr_cnt(
    .clk(clk),
    .rst(rst),
    .mode_i(2'b11 & {fetch_deco_req_ready_o, fetch_deco_req_ready_o}),
    .cnt_rst_vector_i(0),
    .cnt_o(count),
    .cnt_end_o()
);

always #20 clk = ~clk;

decode decode_u(
    .clk(clk),
    .rst(rst),
    .pc_first_i(pc_first_i),
    .pc_second_i(pc_second_i),
    .next_pc_first_i(next_pc_first_i),
    .next_pc_second_i(next_pc_second_i),
    .predicted_pc_first_i(predicted_pc_first_i),
    .predicted_pc_second_i(predicted_pc_second_i),
    .is_rv_first_i(is_rv_first_i),
    .is_rv_second_i(is_rv_second_i),
    .instruction_first_i(instruction_first_i),
    .instruction_second_i(instruction_second_i),
    .exception_first_i(exception_first_i),
    .exception_second_i(exception_second_i),
    .ecause_first_i(ecause_first_i),
    .ecause_second_i(ecause_second_i),
    .fetch_deco_req_valid_first_i(fetch_deco_req_valid_first_i),
    .fetch_deco_req_valid_second_i(fetch_deco_req_valid_second_i),
    .deco_rob_req_ready_first_i(deco_rob_req_ready_first_i),
    .deco_rob_req_ready_second_i(deco_rob_req_ready_second_i),
    .global_predict_miss_i(global_predict_miss_i),
    .global_ret_i(global_ret_i),
    .global_trap_i(global_trap_i),
    .global_wfi_i(global_wfi_i),
    .sip_i(sip_i),
    .tip_i(tip_i),
    .eip_i(eip_i),
    .fetch_deco_req_ready_o(fetch_deco_req_ready_o), 
    .uses_rs1_first_o(uses_rs1_first_o),
    .uses_rs1_second_o(uses_rs1_second_o),
    .uses_rs2_first_o(uses_rs2_first_o),
    .uses_rs2_second_o(uses_rs2_second_o),
    .uses_rd_first_o(uses_rd_first_o),
    .uses_rd_second_o(uses_rd_second_o),
    .uses_csr_first_o(uses_csr_first_o),
    .uses_csr_second_o(uses_csr_second_o),
    .pc_first_o(pc_first_o),
    .pc_second_o(pc_second_o),
    .next_pc_first_o(next_pc_first_o),
    .next_pc_second_o(next_pc_second_o),
    .predicted_pc_first_o(predicted_pc_first_o),
    .predicted_pc_second_o(predicted_pc_second_o),
    .rs1_address_first_o(rs1_address_first_o),
    .rs1_address_second_o(rs1_address_second_o),
    .rs2_address_first_o(rs2_address_first_o),
    .rs2_address_second_o(rs2_address_second_o),
    .rd_address_first_o(rd_address_first_o),
    .rd_address_second_o(rd_address_second_o),
    .csr_address_first_o(csr_address_first_o),
    .csr_address_second_o(csr_address_second_o),
    .mret_first_o(mret_first_o),
    .mret_second_o(mret_second_o),
    .sret_first_o(sret_first_o),
    .sret_second_o(sret_second_o),
    .wfi_first_o(wfi_first_o),
    .wfi_second_o(wfi_second_o),
    .ecause_first_o(ecause_first_o),
    .ecause_second_o(ecause_second_o),
    .exception_first_o(exception_first_o),
    .exception_second_o(exception_second_o),
    .half_first_o(half_first_o),
    .half_second_o(half_second_o),
    .is_fence_first_o(is_fence_first_o),
    .is_fence_second_o(is_fence_second_o),
    .fence_op_first_o(fence_op_first_o),
    .fence_op_second_o(fence_op_second_o),
    .is_aext_first_o(is_aext_first_o),
    .is_aext_second_o(is_aext_second_o),
    .is_mext_first_o(is_mext_first_o),
    .is_mext_second_o(is_mext_second_o),
    .deco_rob_req_valid_first_o(deco_rob_req_valid_first_o),
    .deco_rob_req_valid_second_o(deco_rob_req_valid_second_o),
    .csr_read_first_o(csr_read_first_o),
    .csr_read_second_o(csr_read_second_o),
    .csr_write_first_o(csr_write_first_o),
    .csr_write_second_o(csr_write_second_o),
    .imm_data_first_o(imm_data_first_o),
    .imm_data_second_o(imm_data_second_o),
    .fu_function_first_o(fu_function_first_o),
    .fu_function_second_o(fu_function_second_o),
    .alu_function_modifier_first_o(alu_function_modifier_first_o),
    .alu_function_modifier_second_o(alu_function_modifier_second_o),
    .fu_select_a_first_o(fu_select_a_first_o),
    .fu_select_a_second_o(fu_select_a_second_o),
    .fu_select_b_first_o(fu_select_b_first_o),
    .fu_select_b_second_o(fu_select_b_second_o),
    .jump_first_o(jump_first_o),
    .jump_second_o(jump_second_o),
    .branch_first_o(branch_first_o),
    .branch_second_o(branch_second_o),
    .is_alu_first_o(is_alu_first_o),
    .is_alu_second_o(is_alu_second_o),
    .load_first_o(load_first_o),
    .load_second_o(load_second_o),
    .store_first_o(store_first_o),
    .store_second_o(store_second_o),
    .ldu_op_first_o(ldu_op_first_o),
    .ldu_op_second_o(ldu_op_second_o),
    .stu_op_first_o(stu_op_first_o),
    .stu_op_second_o(stu_op_second_o),
    .aq_first_o(aq_first_o),
    .aq_second_o(aq_second_o),
    .rl_first_o(rl_first_o),
    .rl_second_o(rl_second_o)
);

rcu rcu_u(
    .clk(clk),
    .rst(rst),
    .global_wfi_i(global_wfi_i),
    .global_trap_i(global_trap_i),
    .global_ret_i(global_ret_i),
    .deco_rob_req_valid_first_i(deco_rob_req_valid_first_i),
    .deco_rob_req_valid_second_i(deco_rob_req_valid_second_i),
    .deco_rob_req_ready_first_o(deco_rob_req_ready_first_o),
    .deco_rob_req_ready_second_o(deco_rob_req_ready_second_o),
    .uses_rs1_first_i(uses_rs1_first_i),
    .uses_rs1_second_i(uses_rs1_second_i),
    .uses_rs2_first_i(uses_rs2_first_i),
    .uses_rs2_second_i(uses_rs2_second_i),
    .uses_rd_first_i(uses_rd_first_i),
    .uses_rd_second_i(uses_rd_second_i),
    .uses_csr_first_i (uses_csr_first_i),
    .uses_csr_second_i(uses_csr_second_i),
    .pc_first_i(rcu_pc_first_i),
    .pc_second_i(rcu_pc_second_i),
    .next_pc_first_i(rcu_next_pc_first_i),
    .next_pc_second_i(rcu_next_pc_second_i),
    .predict_pc_first_i(rcu_predict_pc_first_i),
    .predict_pc_second_i(rcu_predict_pc_second_i),
    .rs1_address_first_i(rs1_address_first_i),
    .rs1_address_second_i(rs1_address_second_i),
    .rs2_address_first_i(rs2_address_first_i),
    .rs2_address_second_i(rs2_address_second_i),
    .rd_address_first_i(rd_address_first_i),
    .rd_address_second_i(rd_address_second_i),
    .csr_address_first_i(csr_address_first_i),
    .csr_address_second_i(csr_address_second_i),
    .mret_first_i(mret_first_i),
    .mret_second_i(mret_second_i),
    .sret_first_i(sret_first_i),
    .sret_second_i(sret_second_i),
    .wfi_first_i(wfi_first_i),
    .wfi_second_i(wfi_second_i),
    .ecause_first_i(rcu_ecause_first_i),
    .ecause_second_i(rcu_ecause_second_i),
    .exception_first_i(rcu_exception_first_i),
    .exception_second_i(rcu_exception_second_i),
    .half_first_i(half_first_i),
    .half_second_i(half_second_i),
    .is_fence_first_i(is_fence_first_i),
    .is_fence_second_i(is_fence_second_i),
    .fence_op_first_i(fence_op_first_i),
    .fence_op_second_i(fence_op_second_i),
    .is_aext_first_i(is_aext_first_i),
    .is_aext_second_i(is_aext_second_i),
    .is_mext_first_i(is_mext_first_i),
    .is_mext_second_i(is_mext_second_i),
    .csr_read_first_i(csr_read_first_i),
    .csr_read_second_i(csr_read_second_i),
    .csr_write_first_i(csr_write_first_i),
    .csr_write_second_i(csr_write_second_i),
    .imm_data_first_i(imm_data_first_i),
    .imm_data_second_i(imm_data_second_i),
    .fu_function_first_i(fu_function_first_i),
    .fu_function_second_i(fu_function_second_i),
    .alu_function_modifier_first_i(alu_function_modifier_first_i),
    .alu_function_modifier_second_i(alu_function_modifier_second_i),
    .fu_select_a_first_i(fu_select_a_first_i),
    .fu_select_a_second_i(fu_select_a_second_i),
    .fu_select_b_first_i(fu_select_b_first_i),
    .fu_select_b_second_i(fu_select_b_second_i),
    .jump_first_i(jump_first_i),
    .jump_second_i(jump_second_i),
    .branch_first_i(branch_first_i),
    .branch_second_i(branch_second_i),
    .is_alu_first_i(is_alu_first_i),
    .is_alu_second_i(is_alu_second_i),
    .load_first_i(load_first_i),
    .load_second_i(load_second_i),
    .store_first_i(store_first_i),
    .store_second_i(store_second_i),
    .ldu_op_first_i(ldu_op_first_i),
    .ldu_op_second_i(ldu_op_second_i),
    .stu_op_first_i(stu_op_first_i),
    .stu_op_second_i(stu_op_second_i),
    .aq_first_i(aq_first_i),
    .aq_second_i(aq_second_i),
    .rl_first_i(rl_first_i),
    .rl_second_i(rl_second_i),
    .func_alu1_done_valid_i(func_alu1_done_valid_i),
    .func_alu2_done_valid_i(func_alu2_done_valid_i),
    .func_lsu_done_valid_i(func_lsu_done_valid_i),
    .func_md_done_valid_i(func_md_done_valid_i),
    .func_csru_done_valid_i(func_csru_done_valid_i),
    .physical_alu1_wrb_addr_i(physical_alu1_wrb_addr_i), 
    .physical_csru_wrb_addr_i(physical_csru_wrb_addr_i),
    .physical_alu2_wrb_addr_i(physical_alu2_wrb_addr_i), 
    .physical_lsu_wrb_addr_i(physical_lsu_wrb_addr_i), 
    .physical_md_wrb_addr_i(physical_md_wrb_addr_i),
    .alu1_predict_miss_i(alu1_predict_miss_i),
    .alu1_branch_taken_i(alu1_branch_taken_i),
    .alu1_final_branch_pc_i(alu1_final_branch_pc_i),
    .alu2_predict_miss_i(alu2_predict_miss_i),
    .alu2_branch_taken_i(alu2_branch_taken_i),
    .alu2_final_branch_pc_i(alu2_final_branch_pc_i),
    .func_alu1_rob_index_i(func_alu1_rob_index_i),
    .func_alu2_rob_index_i(func_alu2_rob_index_i),
    .func_lsu_rob_index_i(func_lsu_rob_index_i),
    .func_md_rob_index_i(func_md_rob_index_i),
    .func_csru_rob_index_i(func_csru_rob_index_i),
    .physical_alu1_wrb_data_i(physical_alu1_wrb_data_i), 
    .physical_csru_wrb_data_i(physical_csru_wrb_data_i), 
    .physical_alu2_wrb_data_i(physical_alu2_wrb_data_i), 
    .physical_lsu_wrb_data_i(physical_lsu_wrb_data_i), 
    .physical_md_wrb_data_i(physical_md_wrb_data_i),
    .func_wrb_alu1_exp_i(func_wrb_alu1_exp_i),
    .func_wrb_alu2_exp_i(func_wrb_alu2_exp_i),
    .func_wrb_lsu_exp_i(func_wrb_lsu_exp_i),
    .func_wrb_md_exp_i(func_wrb_md_exp_i),
    .func_wrb_csru_exp_i(func_wrb_csru_exp_i),
    .func_wrb_alu1_ecause_i(func_wrb_alu1_ecause_i),
    .func_wrb_alu2_ecause_i(func_wrb_alu2_ecause_i),
    .func_wrb_lsu_ecause_i(func_wrb_lsu_ecause_i),
    .func_wrb_md_ecause_i(func_wrb_md_ecause_i),
    .func_wrb_csru_ecause_i(func_wrb_csru_ecause_i),
    .rcu_alu1_req_valid_o(rcu_alu1_req_valid_o),
    .rcu_alu2_req_valid_o(rcu_alu2_req_valid_o),
    .rcu_md_req_ready_i(rcu_md_req_ready_i),
    .rcu_md_req_valid_o(rcu_md_req_valid_o),
    .rcu_lsu_req_ready_i(rcu_lsu_req_ready_i),
    .rcu_lsu_req_valid_o(rcu_lsu_req_valid_o),
    .rcu_csr_req_valid_o(rcu_csr_req_valid_o),
    .rcu_lsu_wakeup_o(rcu_lsu_wakeup_o),
    .rcu_lsu_wakeup_index_o(rcu_lsu_wakeup_index_o),
    .rcu_alu1_rob_index_o(rcu_alu1_rob_index_o),
    .rcu_alu1_prd_address_o(rcu_alu1_prd_address_o),
    .rcu_alu1_func3_o(rcu_alu1_func3_o),
    .rcu_alu1_pc_o(rcu_alu1_pc_o), 
    .rcu_alu1_next_pc_o(rcu_alu1_next_pc_o),
    .rcu_alu1_predict_pc_o(rcu_alu1_predict_pc_o),
    .rcu_alu1_imm_data_o(rcu_alu1_imm_data_o),
    .rcu_alu1_select_a_o(rcu_alu1_select_a_o),
    .rcu_alu1_select_b_o(rcu_alu1_select_b_o),
    .rcu_alu1_rs1_data_o(rcu_alu1_rs1_data_o),
    .rcu_alu1_rs2_data_o(rcu_alu1_rs2_data_o),
    .rcu_alu1_jump_o(rcu_alu1_jump_o),
    .rcu_alu1_branch_o(rcu_alu1_branch_o),
    .rcu_alu1_half_o(rcu_alu1_half_o),
    .rcu_alu1_func_modifier_o(rcu_alu1_func_modifier_o),
    .rcu_alu2_rob_index_o(rcu_alu2_rob_index_o),
    .rcu_alu2_prd_address_o(rcu_alu2_prd_address_o),
    .rcu_alu2_func3_o(rcu_alu2_func3_o),
    .rcu_alu2_pc_o(rcu_alu2_pc_o), 
    .rcu_alu2_next_pc_o(rcu_alu2_next_pc_o),
    .rcu_alu2_predict_pc_o(rcu_alu2_predict_pc_o),
    .rcu_alu2_imm_data_o(rcu_alu2_imm_data_o),
    .rcu_alu2_select_a_o(rcu_alu2_select_a_o),
    .rcu_alu2_select_b_o(rcu_alu2_select_b_o),
    .rcu_alu2_rs1_data_o(rcu_alu2_rs1_data_o),
    .rcu_alu2_rs2_data_o(rcu_alu2_rs2_data_o),
    .rcu_alu2_jump_o(rcu_alu2_jump_o),
    .rcu_alu2_branch_o(rcu_alu2_branch_o),
    .rcu_alu2_half_o(rcu_alu2_half_o),
    .rcu_alu2_func_modifier_o(rcu_alu2_func_modifier_o),
    .rcu_md_package_o(rcu_md_package_o),
    .rcu_lsu_package_o(rcu_lsu_package_o),
    .rcu_csr_rob_index_o(rcu_csr_rob_index_o),
    .rcu_csr_prd_address_o(rcu_csr_prd_address_o),
    .rcu_csr_func3_o(rcu_csr_func3_o),
    .rcu_csr_rs1_data_o(rcu_csr_rs1_data_o),
    .rcu_csr_imm_data_o(rcu_csr_imm_data_o),
    .rcu_csr_address_o(rcu_csr_address_o),
    .rcu_csr_do_read_o(rcu_csr_do_read_o),
    .rcu_csr_do_write_o(rcu_csr_do_write_o),
    .rcu_bpu_cmt_is_branch_o(rcu_bpu_cmt_is_branch_o),
    .rcu_bpu_cmt_branch_taken_o(rcu_bpu_cmt_branch_taken_o),
    .rcu_bpu_cmt_final_pc_o(rcu_bpu_cmt_final_pc_o),
    .rcu_bpu_cmt_pc_o(rcu_bpu_cmt_pc_o),
    .rcu_do_rob_commit_first_o(rcu_do_rob_commit_first_o),
    .rcu_do_rob_commit_second_o(rcu_do_rob_commit_second_o),
    .rcu_cmt_pc_o(rcu_cmt_pc_o),
    .predict_miss_o(predict_miss_o),
    .rcu_cmt_exception_o(rcu_cmt_exception_o),
    .rcu_cmt_ecause_o(rcu_cmt_ecause_o),
    .rcu_cmt_is_mret(rcu_cmt_is_mret),
    .rcu_cmt_is_sret(rcu_cmt_is_sret),
    .rcu_cmt_is_wfi(rcu_cmt_is_wfi)
);
//psudo alu
always @(*) begin
    func_alu1_done_valid_i = rcu_alu1_req_valid_o;
    physical_alu1_wrb_data_i = rcu_alu1_rs1_data_o;
    func_alu1_rob_index_i = rcu_alu1_rob_index_o;
    physical_alu1_wrb_addr_i = rcu_alu1_prd_address_o;
    func_wrb_alu1_exp_i = 0;
    func_wrb_alu1_ecause_i = 0;
end

always @(*) begin
    func_alu2_done_valid_i = rcu_alu2_req_valid_o;
    physical_alu2_wrb_data_i = rcu_alu2_rs1_data_o;
    func_alu2_rob_index_i = rcu_alu2_rob_index_o;
    physical_alu2_wrb_addr_i = rcu_alu2_prd_address_o;
    func_wrb_alu2_exp_i = 0;
    func_wrb_alu2_ecause_i = 0;
end
//: psudo alu

//pseudo lsu
assign {select_first_rob_index,
        select_first_prd_address,
        select_first_rs1_data,
        select_first_rs2_data,
        select_first_imm,
        select_first_is_load,
        select_first_is_store,
        select_first_ld_opcode,
        select_first_st_opcode,
        select_first_lsu_fence,
        select_first_lsu_fence_op,
        select_first_aext
        } = rcu_lsu_package_o;
//: pseudo lsu

assign deco_rob_req_valid_first_i = deco_rob_req_valid_first_o;
assign deco_rob_req_valid_second_i = deco_rob_req_valid_second_o;
assign deco_rob_req_ready_first_i = deco_rob_req_ready_first_o;
assign deco_rob_req_ready_second_i = deco_rob_req_ready_second_o;
assign uses_rs1_first_i = uses_rs1_first_o;
assign uses_rs1_second_i = uses_rs1_second_o;
assign uses_rs2_first_i = uses_rs2_first_o;
assign uses_rs2_second_i = uses_rs2_second_o;
assign uses_rd_first_i = uses_rd_first_o;
assign uses_rd_second_i = uses_rd_second_o;
assign uses_csr_first_i = uses_csr_first_o;
assign uses_csr_second_i = uses_csr_second_o;
assign rcu_pc_first_i = pc_first_o;
assign rcu_pc_second_i = pc_second_o;
assign rcu_next_pc_first_i = next_pc_first_o;
assign rcu_next_pc_second_i = next_pc_second_o;
assign rcu_predict_pc_first_i = predicted_pc_first_o;
assign rcu_predict_pc_second_i = predicted_pc_second_o;
assign rs1_address_first_i = rs1_address_first_o;
assign rs1_address_second_i = rs1_address_second_o;
assign rs2_address_first_i = rs2_address_first_o;
assign rs2_address_second_i = rs2_address_second_o;
assign rd_address_first_i = rd_address_first_o;
assign rd_address_second_i = rd_address_second_o;
assign csr_address_first_i = csr_address_first_o;
assign csr_address_second_i = csr_address_second_o;
assign mret_first_i = mret_first_o;
assign mret_second_i = mret_second_o;
assign sret_first_i = sret_first_o;
assign sret_second_i = sret_second_o;
assign wfi_first_i = wfi_first_o;
assign wfi_second_i = wfi_second_o;
assign rcu_ecause_first_i = ecause_first_o;
assign rcu_ecause_second_i = ecause_second_o;
assign rcu_exception_first_i = exception_first_o;
assign rcu_exception_second_i = exception_second_o;
assign half_first_i = half_first_o;
assign half_second_i = half_second_o;
assign is_fence_first_i = is_fence_first_o;
assign is_fence_second_i = is_fence_second_o;
assign fence_op_first_i = fence_op_first_o;
assign fence_op_second_i = fence_op_second_o;
assign is_aext_first_i = is_aext_first_o;
assign is_aext_second_i = is_aext_second_o;
assign is_mext_first_i = is_mext_first_o;
assign is_mext_second_i = is_mext_second_o;
assign csr_read_first_i = csr_read_first_o;
assign csr_read_second_i = csr_read_second_o;
assign csr_write_first_i = csr_write_first_o;
assign csr_write_second_i = csr_write_second_o;
assign imm_data_first_i = imm_data_first_o;
assign imm_data_second_i = imm_data_second_o;
assign fu_function_first_i = fu_function_first_o;
assign fu_function_second_i = fu_function_second_o;
assign alu_function_modifier_first_i = alu_function_modifier_first_o;
assign alu_function_modifier_second_i = alu_function_modifier_second_o;
assign fu_select_a_first_i = fu_select_a_first_o;
assign fu_select_a_second_i = fu_select_a_second_o;
assign fu_select_b_first_i = fu_select_b_first_o;
assign fu_select_b_second_i = fu_select_b_second_o;
assign jump_first_i = jump_first_o;
assign jump_second_i = jump_second_o;
assign branch_first_i = branch_first_o;
assign branch_second_i = branch_second_o;
assign is_alu_first_i = is_alu_first_o;
assign is_alu_second_i = is_alu_second_o;
assign load_first_i = load_first_o;
assign load_second_i = load_second_o;
assign store_first_i = store_first_o;
assign store_second_i = store_second_o;
assign ldu_op_first_i = ldu_op_first_o;
assign ldu_op_second_i = ldu_op_second_o;
assign stu_op_first_i = stu_op_first_o;
assign stu_op_second_i = stu_op_second_o;
assign aq_first_i = aq_first_o;
assign aq_second_i = aq_second_o;
assign rl_first_i = rl_first_o;
assign rl_second_i = rl_second_o;

initial begin
    int dumpon = 0;
    string log;
    string wav;
    $value$plusargs("dumpon=%d",dumpon);
    if ($value$plusargs("sim_log=%s",log)) begin
        $display("wave_log= %s",log);
    end
    wav = {log,"/waves.fsdb"};
    $display("wave_log= %s",wav);
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
