`define SYNTHESIS
`define DEBUGING

module tb_top(
input clk,
input rst,
//fetch
input                                           ft2l1i_if_req_rdy_i,
input                                           l1i2ft_if_resp_vld_i,
input                                           dtlb2fu_lsu_exception_vld,
input [$clog2(IFQ_DEPTH)-1:0]                   l1i2ft_if_resp_if_tag_i,
input [FETCH_WIDTH-1:0]                         l1i2ft_if_resp_data_i,
output                                          ft2l1i_if_req_vld_o,
output [L1I_INDEX_WIDTH-1:0]                    ft2l1i_if_req_index_o,
output [$clog2(IFQ_DEPTH)-1:0]                  ft2l1i_if_req_if_tag_o,
output [L1I_OFFSET_WIDTH-1:0]                   ft2l1i_if_req_offset_o,
output [L1I_TAG_WIDTH-1:0]                      ft2l1i_if_req_vtag_o,
input                                           itlb2ft_miss_i,
input                                           itlb2ft_hit_i,
output                                          ft2itlb_req_vld_o,


//decode
input                                           msip_i,
input                                           ssip_i,
input                                           mtip_i,
input                                           stip_i,
input                                           eip_i,


//fu

    //fu<->tlb
input [EXCEPTION_CAUSE_WIDTH - 1 : 0]           dtlb2fu_lsu_ecause,
output [PMP_ACCESS_TYPE_WIDTH - 1 : 0]          fu2dtlb_lsu_iss_type,
input                                           dtlb2fu_lsu_rdy,
input                                           dtlb2fu_lsu_vld, // should be the lsu_dtlb_iss_vld_o in last cycle
input                                           dtlb2fu_lsu_hit,
input [PHYSICAL_ADDR_TAG_LEN - 1 : 0]           dtlb2fu_lsu_ptag,
input [VIRTUAL_ADDR_TAG_LEN - 1 : 0]            dtlb2fu_lsu_vtag,
output                                          fu2dtlb_lsu_iss_vld,
output [VIRTUAL_ADDR_TAG_LEN - 1 : 0]           fu2dtlb_lsu_iss_vtag,

    //fu<->l1d cache
input                                           l1d2fu_lsu_ld_req_rdy_i,
output                                          fu2l1d_lsu_ld_req_vld_o,
output  [     ROB_INDEX_WIDTH - 1 : 0]          fu2l1d_lsu_ld_req_rob_index_o,
output  [    PHY_REG_ADDR_WIDTH - 1 : 0]        fu2l1d_lsu_ld_req_rd_addr_o, // no need
output  [      LDU_OP_WIDTH - 1 : 0]            fu2l1d_lsu_ld_req_opcode_o,
output  [       ADDR_INDEX_LEN - 1 : 0]         fu2l1d_lsu_ld_req_index_o, 
output  [      ADDR_OFFSET_LEN - 1 : 0]         fu2l1d_lsu_ld_req_offset_o,
output  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]      fu2l1d_lsu_ld_req_vtag_o, 
input                                           l1d2fu_lsu_st_req_rdy_i,
output                                          fu2l1d_lsu_st_req_vld_o,
output                                          fu2l1d_lsu_st_req_is_fence_o,
output   [     ROB_INDEX_WIDTH - 1 : 0]         fu2l1d_lsu_st_req_rob_index_o,
output   [    PHY_REG_ADDR_WIDTH - 1 : 0]       fu2l1d_lsu_st_req_rd_addr_o,
output   [      STU_OP_WIDTH - 1 : 0]           fu2l1d_lsu_st_req_opcode_o,
output   [       PHYSICAL_ADDR_LEN - 1 : 0]     fu2l1d_lsu_st_req_paddr_o, 
output   [              XLEN - 1 : 0]           fu2l1d_lsu_st_req_data_o,

input                                           l1d2fu_lsu_ld_replay_vld_i,

input [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                  l1d2fu_lsu_wb_vld_i,
input [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                l1d2fu_lsu_wb_rob_index_i,
input                                          l1d2fu_lsu_prf_wb_vld_i,
input [PHY_REG_ADDR_WIDTH - 1 : 0]             l1d2fu_lsu_prf_wb_rd_addr_i,
input [XLEN - 1 : 0]                           l1d2fu_lsu_prf_wb_data_i,
output                                         fu2l1d_lsu_kill_req_o,
    //fu <-> wb bus
output                                          fu2wb_lsu_cyc_o,
output                                          fu2wb_lsu_stb_o,
output                                          fu2wb_lsu_we_o,
output [PHYSICAL_ADDR_LEN - 1 : 0]              fu2wb_lsu_adr_o,
output [WB_DATA_LEN-1:0]                        fu2wb_lsu_dat_o,
output [WB_DATA_LEN/8-1:0]                      fu2wb_lsu_sel_o,
input                                          wb2fu_lsu_ack_i,
input [WB_DATA_LEN -1:0]                       wb2fu_lsu_dat_i,

    //fu <-> pmp
output                                             fu2pmp_csru_cfg_vld,
output    [PMPCFG_ID_WIDTH-1:0]                    fu2pmp_csru_cfg_addr,
output    [XLEN-1:0]                               fu2pmp_csru_cfg_payload,
input    [XLEN-1:0]                               pmp2fu_csru_cfg_origin_payload,
output                                             fu2pmp_csru_addr_vld,
output    [PMPADDR_ID_WIDTH-1:0]                   fu2pmp_csru_addr_addr,
output    [XLEN-1:0]                               fu2pmp_csru_addr_payload,
input    [XLEN-1:0]                               pmp2fu_csru_addr_origin_payload,

// csr_regfile to mmu
output      [XLEN - 1 : 0] satp_o,
output      [XLEN - 1 : 0] mstatus_o
);

reg [PC_WIDTH-1:0] ft2dec_pc_first;
reg [PC_WIDTH-1:0] ft2dec_pc_second;
reg [PC_WIDTH-1:0] ft2dec_next_pc_second;
reg [PC_WIDTH-1:0] ft2dec_next_pc_first;
reg [PC_WIDTH-1:0] ft2dec_predicted_pc_first;
reg [PC_WIDTH-1:0] fu2dec_predicted_pc_second;
reg ft2dec_is_rv_first;
reg ft2dec_is_rv_second;
reg [31:0] ft2dec_instruction_first;
reg [31:0] fu2dec_instruction_second;
reg ft2dec_excp_first;
reg ft2dec_excp_second;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ft2dec_ecause_first;
reg [EXCEPTION_CAUSE_WIDTH-1:0] ft2dec_ecause_second;
reg ft2dec_req_valid_first;
reg ft2dec_req_valid_second;
reg dec2rcu_req_ready_first;
reg dec2rcu_req_ready_second;
reg branch_back_i;
reg global_wfi;

reg [1:0] privilege_mode_i;
reg ft2dec_req_single_ready;
reg ft2dec_req_double_ready;
reg dec2rcu_uses_rs1_first;
reg dec2rcu_uses_rs1_second;
reg dec2rcu_uses_rs2_first;
reg dec2rcu_uses_rd_first;
reg dec2rcu_uses_rd_second;
reg dec2rcu_uses_csr_first;
reg dec2rcu_uses_csr_second;
reg [PC_WIDTH-1 :0] dec2rcu_pc_first;
reg [PC_WIDTH-1 :0] dec2rcu_pc_second;
reg [PC_WIDTH-1 :0] dec2rcu_next_pc_first;
reg [PC_WIDTH-1 :0] dec2rcu_next_pc_second;
reg [PC_WIDTH-1 :0] dec2rcu_predicted_pc_first;
reg [PC_WIDTH-1 :0] dec2rcu_predicted_pc_second;
reg [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs1_address_first;
reg [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs1_address_second;
reg [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs2_address_first;
reg [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs2_address_second;
reg [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rd_address_first;
reg [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rd_address_second;
reg [CSR_ADDR_LEN-1:0] dec2rcu_csr_address_first;
reg [CSR_ADDR_LEN-1:0] dec2rcu_csr_address_second;
reg dec2rcu_mret_first;
reg dec2rcu_mret_second;
reg dec2rcu_sret_first;
reg dec2rcu_sret_second;
reg dec2rcu_wfi_first;
reg dec2rcu_wfi_second;
reg [EXCEPTION_CAUSE_WIDTH-1:0] dec2rcu_ecause_first;
reg [EXCEPTION_CAUSE_WIDTH-1:0] dec2rcu_ecause_second;
reg dec2rcu_exception_first;
reg dec2rcu_exception_second;
reg dec2rcu_half_first;
reg dec2rcu_half_second;
reg dec2rcu_is_fence_first;
reg dec2rcu_is_fence_second;
reg [1:0] dec2rcu_fence_op_first;
reg [1:0] dec2rcu_fence_op_second;
reg dec2rcu_is_aext_first;
reg dec2rcu_is_aext_second;
reg dec2rcu_is_mext_first;
reg dec2rcu_is_mext_second;
reg dec2rcu_req_valid_first;
reg dec2rcu_req_valid_second;
reg dec2rcu_csr_read_first;
reg dec2rcu_csr_read_second;
reg dec2rcu_csr_write_first;
reg dec2rcu_csr_write_second;
reg [31:0] dec2rcu_imm_data_first;
reg [31:0] dec2rcu_imm_data_second;
reg [2:0] dec2rcu_fu_funtion_first;
reg [2:0] dec2rcu_fu_function_second;
reg dec2rcu_alu_function_modifier_first;
reg dec2rcu_alu_function_modifier_second;
reg [1:0] dec2rcu_fu_select_a_first;
reg [1:0] dec2rcu_fu_select_a_second;
reg [1:0] dec2rcu_fu_select_b_first;
reg [1:0] dec2rcu_fu_select_b_second;
reg dec2rcu_jump_first;
reg dec2rcu_jump_second;
reg dec2rcu_branch_first;
reg dec2rcu_branch_second;
reg dec2rcu_is_alu_first;
reg dec2rcu_is_alu_second;
reg dec2rcu_load_first;
reg dec2rcu_load_second;
reg dec2rcu_store_first;
reg dec2rcu_store_second;
reg [LDU_OP_WIDTH-1:0] dec2rcu_ldu_op_first;
reg [LDU_OP_WIDTH-1:0] dec2rcu_ldu_op_second;
reg [STU_OP_WIDTH-1:0] dec2rcu_stu_op_first;
reg [STU_OP_WIDTH-1:0] dec2rcu_stu_op_second;
reg dec2rcu_aq_first;
reg dec2rcu_aq_second;
reg dec2rcu_rl_first;
reg dec2rcu_rl_second;

wire [1:0] csr2decode_priv_mode                         ;
reg global_trap                                         ;
reg global_ret                                          ;
reg global_mret                                           ;
reg global_sret                                           ;
reg dec2rcu_uses_rs2_second                                     ;
reg fu2rcu_alu1_resp_valid                                ;
reg fu2rcu_alu2_resp_valid                                ;
reg func_lsu_done_valid_i                                 ;
reg fu2rcu_md_wrb_resp_valid                                  ;
reg fu2rcu_csr_resp_valid                                ;
reg [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_alu1_wrb_prd_addr     ; 
reg [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_csr_wrb_addr     ;
reg [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_alu2_wrb_prd_addr     ; 
reg [PHY_REG_ADDR_WIDTH-1:0] physical_lsu_wrb_addr_i      ; 
reg [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_md_wrb_prd_addr       ;
reg fu2rcu_alu1_predict_miss                                   ;
reg fu2rcu_alu1_branch_taken                                   ;
reg [PC_WIDTH-1:0] fu2rcu_alu1_final_branch_pc                                ;
reg fu2rcu_alu2_predict_miss                                   ;
reg fu2rcu_alu2_branch_taken                                   ;
reg [PC_WIDTH-1:0] fu2rcu_alu2_final_branch_pc                                ;
reg [ROB_INDEX_WIDTH-1:0] fu2rcu_alu1_wrb_rob_index           ; 
reg [ROB_INDEX_WIDTH-1:0] fu2rcu_alu2_wrb_rob_index           ;
reg [ROB_INDEX_WIDTH-1:0] func_lsu_rob_index_i            ;
reg [ROB_INDEX_WIDTH-1:0] fu2rcu_md_wrb_rob_index             ;
reg [ROB_INDEX_WIDTH-1:0] fu2rcu_csr_wrb_rob_index           ;
reg [XLEN-1:0] fu2rcu_alu1_wrb_data                   ; 
reg [XLEN-1:0] fu2rcu_csr_wrb_data                   ; 
reg [XLEN-1:0] fu2rcu_alu2_wrb_data                   ; 
reg [XLEN-1:0] fu2rcu_lsu_wrb_data                      ;
reg [XLEN-1:0] fu2rcu_md_wrb_data                     ;
reg func_wrb_alu1_exp_i                                   ;
reg func_wrb_alu2_exp_i                                   ;
reg func_wrb_lsu_exp_i                                    ;
reg func_wrb_md_exp_i                                     ;
reg fu2rcu_csr_exception                                   ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_alu1_ecause_i    ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_alu2_ecause_i    ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_lsu_ecause_i     ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_md_ecause_i      ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] fu2rcu_csr_ecause    ;
reg rcu2fu_alu1_req_valid                                  ;
reg rcu2fu_alu2_req_valid                                  ;
reg rcu2fu_md_req_ready                                    ;
reg rcu2fu_md_req_valid                                    ;
reg rcu_lsu_req_ready_i                                   ;
reg rcu_lsu_req_valid_o                                   ;
reg rcu2fu_csru_req_valid                                   ;
reg rcu_lsu_wakeup_o                                      ;
reg [ROB_INDEX_WIDTH-1:0] rcu2fu_lsu_wakeup_index          ;
reg [ROB_INDEX_WIDTH-1:0] rcu2fu_alu1_rob_index            ;
reg [PHY_REG_ADDR_WIDTH-1:0] rcu2fu_alu1_prd_addr       ;
reg [2:0] rcu2fu_alu1_func3                                ;
reg [PC_WIDTH-1:0] rcu2fu_alu1_pc                          ;
reg [PC_WIDTH-1:0] rcu2fu_alu1_next_pc                     ;
reg [PC_WIDTH-1:0] rcu2fu_alu1_predict_pc                  ;
reg [IMM_LEN-1:0] rcu2fu_alu1_imm_data                     ;
reg [1:0] rcu2fu_alu1_opr1_sel                             ;
reg [1:0] rcu2fu_alu1_opr2_sel                             ;
reg [XLEN-1:0] rcu2fu_alu1_rs1_data                        ;
reg [XLEN-1:0] rcu2fu_alu1_rs2_data                        ;
reg  rcu2fu_alu1_is_jump                                      ;
reg  rcu2fu_alu1_is_branch                                    ;
reg  rcu2fu_alu1_half                                      ;
reg  rcu2fu_alu1_func_modifier                             ;
reg [ROB_INDEX_WIDTH-1:0] rcu2fu_alu2_rob_index            ;
reg [PHY_REG_ADDR_WIDTH-1:0] rcu2fu_alu2_prd_addr       ;
reg [2:0] rcu2fu_alu2_func3                                ;
reg [PC_WIDTH-1:0] rcu2fu_alu2_pc                          ;
reg [PC_WIDTH-1:0] rcu2fu_alu2_next_pc                     ;
reg [PC_WIDTH-1:0] rcu2fu_alu2_predict_pc                  ;
reg [IMM_LEN-1:0] rcu2fu_alu2_imm_data                     ;
reg [1:0] rcu2fu_alu2_opr1_sel                             ;
reg [1:0] rcu2fu_alu2_opr2_sel                             ;
reg [XLEN-1:0] rcu2fu_alu2_rs1_data                        ;
reg [XLEN-1:0] rcu2fu_alu2_rs2_data                        ;
reg  rcu2fu_alu2_is_jump                                      ;
reg  rcu2fu_alu2_is_branch                                    ;
reg  rcu2fu_alu2_half                                      ;
reg  rcu2fu_alu2_func_modifier                             ;
reg [MD_DATA_WIDTH-1:0] rcu2fu_md_package                  ;
reg [LSU_DATA_WIDTH-1:0] rcu2fu_lsu_package                ;
reg [ROB_INDEX_WIDTH-1:0] rcu2fu_csru_rob_index             ;
reg [PHY_REG_ADDR_WIDTH-1:0] rcu2fu_csru_prd_addr        ;
reg [2:0] rcu2fu_csru_func3                                 ;
reg [XLEN-1:0] rcu2fu_csru_prs1_data                         ;
reg [IMM_LEN-1:0] rcu2fu_csru_imm                      ;
reg [CSR_ADDR_LEN-1:0] rcu2fu_csru_addr                  ;
reg rcu2fu_csru_do_read                                     ;
reg rcu2fu_csru_do_write                                    ;
reg rcu2ft_bpu_cmt_is_branch_first                               ;
reg rcu2ft_bpu_cmt_is_branch_second                         ;
reg rcu2ft_bpu_cmt_branch_taken_first                      ;
reg rcu2ft_bpu_cmt_branch_taken_second                      ;
reg [PC_WIDTH-1:0] rcu2ft_bpu_cmt_final_pc                  ;
reg [PC_WIDTH-1:0] rcu_bpu_cmt_final_pc_second_o           ;
reg [PC_WIDTH-1:0] rcu2ft_bpu_cmt_pc_first                 ;
reg [PC_WIDTH-1:0] rcu2ft_bpu_cmt_pc_second                 ;
reg [PC_WIDTH-1:0] rcu2ft_bpu_alu_result_pc                 ;
reg rcu_do_rob_commit_first                             ;
reg rcu_do_rob_commit_second                            ;
reg [PC_WIDTH-1:0] rcu2exp_cmt_pc                           ;
reg rcu2excp_predict_miss                                        ;
reg rcu2excp_cmt_exception                                   ;
reg [EXCEPTION_CAUSE_WIDTH-1:0] rcu2excp_cmt_ecause          ;
reg rcu2excp_cmt_is_mret                                       ;
reg rcu2excp_cmt_is_sret                                       ;
reg rcu2excp_cmt_is_wfi                                        ;
reg global_predict_miss                                   ;

reg  rcu2fu_lsu_req_valid        ;
reg  fu2rcu_lsu_done_valid_fix    ;
reg  fu2rcu_lsu_req_ready    ;
reg [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_lsu_wrb_addr_fix         ;
reg [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_lsu_wrb_addr         ;
reg [XLEN-1:0] lsu2rcu_wrb_data         ;
reg [ROB_INDEX_WIDTH-1:0] lsu2rcu_rob_index        ;

reg [ROB_INDEX_WIDTH-1:0] lsu_rob_index      ;
reg [PHY_REG_ADDR_WIDTH-1:0] lsu_prd_address    ;
reg [XLEN-1:0] lsu_rs1_data       ;
reg [XLEN-1:0] lsu_rs2_data       ;
reg [IMM_LEN-1:0] lsu_imm            ;
reg lsu_is_load        ;
reg lsu_is_store       ;
reg [LDU_OP_WIDTH-1:0] rcu2fu_lsu_ld_opcode      ;
reg [STU_OP_WIDTH-1:0] rcu2fu_lsu_st_opcode      ;
reg lsu_lsu_fence      ;
reg [1:0] lsu_lsu_fence_op   ;
reg lsu_aext           ;


//LSU
reg lsu_rdy_o                                             ;
reg                                          rcu2fu_lsu_vld;
reg                                          rcu2fu_lsu_ls;
reg [LS_OPCODE_WIDTH - 1 : 0]                rcu2fu_lsu_opcode;
reg                                          rcu2fu_lsu_fenced;
reg [XLEN - 1 : 0]                           rcu2fu_agu_virt_base;
reg [XLEN - 1 : 0]                           rcu2fu_agu_virt_offset;
reg [ROB_INDEX_WIDTH - 1 : 0]                rcu2fu_lsu_rob_index;
reg [PHY_REG_ADDR_WIDTH - 1 : 0]             rcu2fu_lsu_rd_addr;
reg [XLEN - 1 : 0]                           rcu2fu_lsu_data;
reg                                          rcu2fu_lsu_wakeup;
reg [ROB_INDEX_WIDTH - 1 : 0]                rcu2fu_lsu_wakeup_rob_index;
reg                                          fu2rcu_lsu_comm_vld_fix;
reg [ROB_INDEX_WIDTH - 1 : 0]                fu2rcu_lsu_comm_rob_index_fix;
reg                                          fu2rcu_lsu_exception_vld;
reg [EXCEPTION_CAUSE_WIDTH - 1 : 0]          fu2rcu_lsu_ecause;

reg  [PHY_REG_ADDR_WIDTH - 1 : 0]            fu2prf_lsu_wb_rd_addr;
// reg 


//
    // <> d$
    // Load request
    // wb

wire fu2csr_csru_do_write;
wire [CSR_ADDR_LEN-1:0] fu2csr_csru_waddr;
wire [CSR_ADDR_LEN-1:0] fu2csr_csru_raddr;
//`endif //LSU_DOING

//With CSR
reg   [CSR_ADDR_LEN-1:0]                       fu2csr_csru_addr;
reg  [XLEN-1:0]                                csr2fu_csru_rdata;
reg                                            csr2fu_csru_readable;
reg                                            csr2fu_csru_writable;
 
reg [XLEN-1:0]                               fu2csr_csru_wrdata;

// fetch: backend->fetch:
reg branch_valid_first_i;
reg branch_valid_second_i;
reg [PC_WIDTH-1:0] btb_req_pc_i;
reg [PC_WIDTH-1:0] btb_predict_target_i;
reg [PC_WIDTH-1:0] prev_pc_first_i;
reg prev_taken_first_i;
reg [PC_WIDTH-1:0] prev_pc_second_i;
reg prev_taken_second_i;
reg [PC_WIDTH-1:0] real_branch_i;
// fetch: exception ctrl
reg [PC_WIDTH-1:0] csr2fetch_trap_vector;
reg [PC_WIDTH-1:0] mret_vector_i;
// fetch: fetch<>I$
wire ins_empty_o;

//exception contol
wire [PC_WIDTH-1:0] excp2csr_pc;
wire [EXCEPTION_CAUSE_WIDTH-1:0] excp2csr_ecause;

wire tsr_o;




integer i;
integer j;
reg[31:0] instr_buffer[0:127];

// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_no_depend.data", instr_buffer); //no dependency
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_with_depend.data", instr_buffer); //with dependency
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_depend_comb.data", instr_buffer); //both
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_c_depend_comb.data", instr_buffer); //both
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_load_store.data", instr_buffer);
// initial	$readmemh("/work/stu/yzhang/workspace/hehecore-2-0/src_new/rcu/data/tb_branch.data", instr_buffer);
parameter DRAM_SIZE = 1 << 16;
parameter DRAM_AXI_DATA_WIDTH = 128;
parameter DRAM_INDEX_NUM = DRAM_SIZE/(DRAM_AXI_DATA_WIDTH/8);
parameter DRAM_INDEX_WIDTH = $clog2(DRAM_INDEX_NUM);

wire [128-1:0] dram_wdata     ;
wire [128-1:0] dram_rdata     ;
wire [DRAM_INDEX_WIDTH-1:0] dram_waddr  ;
wire [DRAM_INDEX_WIDTH-1:0] dram_raddr  ;

// omit fetch <> itlb for test simplicity
// fetch <> itlb can be restored through uncommenting related code in fetch.v
fetch fetch_u(
    .clk(clk),
    .rst(rst),
    .branch_valid_first_i(rcu_do_rob_commit_first & rcu2ft_bpu_cmt_is_branch_first),
    .branch_valid_second_i(rcu_do_rob_commit_second & rcu2ft_bpu_cmt_is_branch_second),
    .btb_req_pc_i(rcu2ft_bpu_cmt_pc_first),
    .btb_predict_target_i(rcu2ft_bpu_alu_result_pc),            
    .prev_pc_first_i(rcu2ft_bpu_cmt_pc_first),
    .prev_taken_first_i(rcu2ft_bpu_cmt_branch_taken_first),
    .prev_pc_second_i(rcu2ft_bpu_cmt_pc_second),
    .prev_taken_second_i(rcu2ft_bpu_cmt_branch_taken_second),
    .pc_first_o(ft2dec_pc_first),
    .next_pc_first_o(ft2dec_next_pc_first),
    .predict_pc_first_o(ft2dec_predicted_pc_first),
    .instruction_first_o(ft2dec_instruction_first),
    .is_rv_first_o(ft2dec_is_rv_first),
    .is_first_valid_o(ft2dec_req_valid_first),
    .pc_second_o(ft2dec_pc_second),
    .next_pc_second_o(ft2dec_next_pc_second),
    .predict_pc_second_o(fu2dec_predicted_pc_second),
    .instruction_second_o(fu2dec_instruction_second),
    .is_rv_second_o(ft2dec_is_rv_second),
    .is_second_valid_o(ft2dec_req_valid_second),
    .single_rdy_i(ft2dec_req_single_ready),
    .double_rdy_i(ft2dec_req_double_ready),
    .real_branch_i(rcu2ft_bpu_cmt_final_pc),      
    .global_wfi_i(global_wfi),
    .global_ret_i(global_ret),
    .global_trap_i(global_trap),
    .global_predict_miss_i(global_predict_miss),
    .trap_vector_i(csr2fetch_trap_vector),
    .mret_vector_i(csr2fetch_trap_vector),
    .fetch_l1i_if_req_rdy_i(ft2l1i_if_req_rdy_i),
    .l1i_fetch_if_resp_vld_i(l1i2ft_if_resp_vld_i),
    .l1i_fetch_if_resp_if_tag_i(l1i2ft_if_resp_if_tag_i),
    .l1i_fetch_if_resp_data_i(l1i2ft_if_resp_data_i),
    .fetch_l1i_if_req_vld_o(ft2l1i_if_req_vld_o),
    .fetch_l1i_if_req_index_o(ft2l1i_if_req_index_o),
    .fetch_l1i_if_req_if_tag_o(ft2l1i_if_req_if_tag_o),
    .fetch_l1i_if_req_offset_o(ft2l1i_if_req_offset_o),
    .fetch_l1i_if_req_vtag_o(ft2l1i_if_req_vtag_o),
    .itlb_fetch_miss_i(itlb2ft_miss_i),
    .itlb_fetch_hit_i(itlb2ft_hit_i),
    .fetch_itlb_req_vld_o(ft2itlb_req_vld_o),
    .ins_empty_o(ins_empty_o),                  //not used
    .exception_valid_first_o(ft2dec_excp_first),
    .ecause_first_o(ft2dec_ecause_first),
    .exception_valid_second_o(ft2dec_excp_second),
    .ecause_second_o(ft2dec_ecause_second)
);  //end fetch

decode decode_u(
    .clk(clk),
    .rst(rst),
    .pc_first_i(ft2dec_pc_first),
    .pc_second_i(ft2dec_pc_second),
    .next_pc_first_i(ft2dec_next_pc_first),
    .next_pc_second_i(ft2dec_next_pc_second),
    .predicted_pc_first_i(ft2dec_predicted_pc_first),
    .predicted_pc_second_i(fu2dec_predicted_pc_second),
    .is_rv_first_i(ft2dec_is_rv_first),
    .is_rv_second_i(ft2dec_is_rv_second),
    .instruction_first_i(ft2dec_instruction_first),
    .instruction_second_i(fu2dec_instruction_second),
    .exception_first_i(ft2dec_excp_first),
    .exception_second_i(ft2dec_excp_second),
    .ecause_first_i(ft2dec_ecause_first),
    .ecause_second_i(ft2dec_ecause_second),
    .privilege_mode_i(csr2decode_priv_mode),
    .fetch_deco_req_valid_first_i(ft2dec_req_valid_first),
    .fetch_deco_req_valid_second_i(ft2dec_req_valid_second),
    .deco_rob_req_ready_first_i(dec2rcu_req_ready_first),
    .deco_rob_req_ready_second_i(dec2rcu_req_ready_second),
    .global_predict_miss_i(global_predict_miss),
    .global_ret_i(global_ret),
    .global_trap_i(global_trap),
    .global_wfi_i(global_wfi),
    .msip_i(msip_i),                
    .ssip_i(ssip_i),
    .mtip_i(mtip_i),
    .stip_i(stip_i),
    .eip_i(eip_i),
    .fetch_deco_req_single_ready_o(ft2dec_req_single_ready),   
    .fetch_deco_req_double_ready_o(ft2dec_req_double_ready),   
    .uses_rs1_first_o(dec2rcu_uses_rs1_first),
    .uses_rs1_second_o(dec2rcu_uses_rs1_second),
    .uses_rs2_first_o(dec2rcu_uses_rs2_first),
    .uses_rs2_second_o(dec2rcu_uses_rs2_second),
    .uses_rd_first_o(dec2rcu_uses_rd_first),
    .uses_rd_second_o(dec2rcu_uses_rd_second),
    .uses_csr_first_o(dec2rcu_uses_csr_first),
    .uses_csr_second_o(dec2rcu_uses_csr_second),
    .pc_first_o(dec2rcu_pc_first),
    .pc_second_o(dec2rcu_pc_second),
    .next_pc_first_o(dec2rcu_next_pc_first),
    .next_pc_second_o(dec2rcu_next_pc_second),
    .predicted_pc_first_o(dec2rcu_predicted_pc_first),
    .predicted_pc_second_o(dec2rcu_predicted_pc_second),
    .rs1_address_first_o(dec2rcu_rs1_address_first),
    .rs1_address_second_o(dec2rcu_rs1_address_second),
    .rs2_address_first_o(dec2rcu_rs2_address_first),
    .rs2_address_second_o(dec2rcu_rs2_address_second),
    .rd_address_first_o(dec2rcu_rd_address_first),
    .rd_address_second_o(dec2rcu_rd_address_second),
    .csr_address_first_o(dec2rcu_csr_address_first),
    .csr_address_second_o(dec2rcu_csr_address_second),
    .mret_first_o(dec2rcu_mret_first),
    .mret_second_o(dec2rcu_mret_second),
    .sret_first_o(dec2rcu_sret_first),
    .sret_second_o(dec2rcu_sret_second),
    .wfi_first_o(dec2rcu_wfi_first),
    .wfi_second_o(dec2rcu_wfi_second),
    .ecause_first_o(dec2rcu_ecause_first),
    .ecause_second_o(dec2rcu_ecause_second),
    .exception_first_o(dec2rcu_exception_first),
    .exception_second_o(dec2rcu_exception_second),
    .half_first_o(dec2rcu_half_first),
    .half_second_o(dec2rcu_half_second),
    .is_fence_first_o(dec2rcu_is_fence_first),
    .is_fence_second_o(dec2rcu_is_fence_second),
    .fence_op_first_o(dec2rcu_fence_op_first),
    .fence_op_second_o(dec2rcu_fence_op_second),
    .is_aext_first_o(dec2rcu_is_aext_first),
    .is_aext_second_o(dec2rcu_is_aext_second),
    .is_mext_first_o(dec2rcu_is_mext_first),
    .is_mext_second_o(dec2rcu_is_mext_second),
    .deco_rob_req_valid_first_o(dec2rcu_req_valid_first),        
    .deco_rob_req_valid_second_o(dec2rcu_req_valid_second),
    .csr_read_first_o(dec2rcu_csr_read_first),
    .csr_read_second_o(dec2rcu_csr_read_second),
    .csr_write_first_o(dec2rcu_csr_write_first),
    .csr_write_second_o(dec2rcu_csr_write_second),
    .imm_data_first_o(dec2rcu_imm_data_first),
    .imm_data_second_o(dec2rcu_imm_data_second),
    .fu_function_first_o(dec2rcu_fu_funtion_first),
    .fu_function_second_o(dec2rcu_fu_function_second),
    .alu_function_modifier_first_o(dec2rcu_alu_function_modifier_first),
    .alu_function_modifier_second_o(dec2rcu_alu_function_modifier_second),
    .fu_select_a_first_o(dec2rcu_fu_select_a_first),
    .fu_select_a_second_o(dec2rcu_fu_select_a_second),
    .fu_select_b_first_o(dec2rcu_fu_select_b_first),
    .fu_select_b_second_o(dec2rcu_fu_select_b_second),
    .jump_first_o(dec2rcu_jump_first),
    .jump_second_o(dec2rcu_jump_second),
    .branch_first_o(dec2rcu_branch_first),
    .branch_second_o(dec2rcu_branch_second),
    .is_alu_first_o(dec2rcu_is_alu_first),
    .is_alu_second_o(dec2rcu_is_alu_second),
    .load_first_o(dec2rcu_load_first),
    .load_second_o(dec2rcu_load_second),
    .store_first_o(dec2rcu_store_first),
    .store_second_o(dec2rcu_store_second),
    .ldu_op_first_o(dec2rcu_ldu_op_first),
    .ldu_op_second_o(dec2rcu_ldu_op_second),
    .stu_op_first_o(dec2rcu_stu_op_first),
    .stu_op_second_o(dec2rcu_stu_op_second),
    .aq_first_o(dec2rcu_aq_first),
    .aq_second_o(dec2rcu_aq_second),
    .rl_first_o(dec2rcu_rl_first),
    .rl_second_o(dec2rcu_rl_second)
);      //end decode

assign lsu2rcu_rob_index = fu2rcu_lsu_comm_rob_index_fix;
assign fu2rcu_lsu_done_valid = fu2rcu_lsu_comm_vld_fix | fu2rcu_lsu_done_valid_fix;
assign fu2rcu_lsu_wrb_addr = fu2rcu_lsu_comm_vld_fix ? 0 : fu2rcu_lsu_wrb_addr_fix;

rcu rcu_u(
    .clk(clk),
    .rst(rst),
    .global_wfi_i(global_wfi),
    .global_trap_i(global_trap),
    .global_ret_i(global_ret),
    .deco_rob_req_valid_first_i(dec2rcu_req_valid_first),
    .deco_rob_req_valid_second_i(dec2rcu_req_valid_second),
    .deco_rob_req_ready_first_o(dec2rcu_req_ready_first),
    .deco_rob_req_ready_second_o(dec2rcu_req_ready_second),
    .uses_rs1_first_i(dec2rcu_uses_rs1_first),
    .uses_rs1_second_i(dec2rcu_uses_rs1_second),
    .uses_rs2_first_i(dec2rcu_uses_rs2_first),
    .uses_rs2_second_i(dec2rcu_uses_rs2_second),
    .uses_rd_first_i(dec2rcu_uses_rd_first),
    .uses_rd_second_i(dec2rcu_uses_rd_second),
    .uses_csr_first_i (dec2rcu_uses_csr_first),
    .uses_csr_second_i(dec2rcu_uses_csr_second),
    .pc_first_i(dec2rcu_pc_first),
    .pc_second_i(dec2rcu_pc_second),
    .next_pc_first_i(dec2rcu_next_pc_first),
    .next_pc_second_i(dec2rcu_next_pc_second),
    .predict_pc_first_i(dec2rcu_predicted_pc_first),
    .predict_pc_second_i(dec2rcu_predicted_pc_second),
    .rs1_address_first_i(dec2rcu_rs1_address_first),
    .rs1_address_second_i(dec2rcu_rs1_address_second),
    .rs2_address_first_i(dec2rcu_rs2_address_first),
    .rs2_address_second_i(dec2rcu_rs2_address_second),
    .rd_address_first_i(dec2rcu_rd_address_first),
    .rd_address_second_i(dec2rcu_rd_address_second),
    .csr_address_first_i(dec2rcu_csr_address_first),
    .csr_address_second_i(dec2rcu_csr_address_second),
    .mret_first_i(dec2rcu_mret_first),
    .mret_second_i(dec2rcu_mret_second),
    .sret_first_i(dec2rcu_sret_first),
    .sret_second_i(dec2rcu_sret_second),
    .wfi_first_i(dec2rcu_wfi_first),
    .wfi_second_i(dec2rcu_wfi_second),
    .ecause_first_i(dec2rcu_ecause_first),
    .ecause_second_i(dec2rcu_ecause_second),
    .exception_first_i(dec2rcu_exception_first),
    .exception_second_i(dec2rcu_exception_second),
    .half_first_i(dec2rcu_half_first),
    .half_second_i(dec2rcu_half_second),
    .is_fence_first_i(dec2rcu_is_fence_first),
    .is_fence_second_i(dec2rcu_is_fence_second),
    .fence_op_first_i(dec2rcu_fence_op_first),
    .fence_op_second_i(dec2rcu_fence_op_second),
    .is_aext_first_i(dec2rcu_is_aext_first),
    .is_aext_second_i(dec2rcu_is_aext_second),
    .is_mext_first_i(dec2rcu_is_mext_first),
    .is_mext_second_i(dec2rcu_is_mext_second),
    .csr_read_first_i(dec2rcu_csr_read_first),
    .csr_read_second_i(dec2rcu_csr_read_second),
    .csr_write_first_i(dec2rcu_csr_write_first),
    .csr_write_second_i(dec2rcu_csr_write_second),
    .imm_data_first_i(dec2rcu_imm_data_first),
    .imm_data_second_i(dec2rcu_imm_data_second),
    .fu_function_first_i(dec2rcu_fu_funtion_first),
    .fu_function_second_i(dec2rcu_fu_function_second),
    .alu_function_modifier_first_i(dec2rcu_alu_function_modifier_first),
    .alu_function_modifier_second_i(dec2rcu_alu_function_modifier_second),
    .fu_select_a_first_i(dec2rcu_fu_select_a_first),
    .fu_select_a_second_i(dec2rcu_fu_select_a_second),
    .fu_select_b_first_i(dec2rcu_fu_select_b_first),
    .fu_select_b_second_i(dec2rcu_fu_select_b_second),
    .jump_first_i(dec2rcu_jump_first),
    .jump_second_i(dec2rcu_jump_second),
    .branch_first_i(dec2rcu_branch_first),
    .branch_second_i(dec2rcu_branch_second),
    .is_alu_first_i(dec2rcu_is_alu_first),
    .is_alu_second_i(dec2rcu_is_alu_second),
    .load_first_i(dec2rcu_load_first),
    .load_second_i(dec2rcu_load_second),
    .store_first_i(dec2rcu_store_first),
    .store_second_i(dec2rcu_store_second),
    .ldu_op_first_i(dec2rcu_ldu_op_first),
    .ldu_op_second_i(dec2rcu_ldu_op_second),
    .stu_op_first_i(dec2rcu_stu_op_first),
    .stu_op_second_i(dec2rcu_stu_op_second),
    .aq_first_i(dec2rcu_aq_first),
    .aq_second_i(dec2rcu_aq_second),
    .rl_first_i(dec2rcu_rl_first),
    .rl_second_i(dec2rcu_rl_second),
    .func_alu1_done_valid_i(fu2rcu_alu1_resp_valid),
    .func_alu2_done_valid_i(fu2rcu_alu2_resp_valid),
    .func_lsu_done_valid_i(fu2rcu_lsu_done_valid),
    .func_md_done_valid_i(fu2rcu_md_wrb_resp_valid),
    .func_csru_done_valid_i(fu2rcu_csr_resp_valid),
    .physical_alu1_wrb_addr_i(fu2rcu_alu1_wrb_prd_addr), 
    .physical_csru_wrb_addr_i(fu2rcu_csr_wrb_addr),
    .physical_alu2_wrb_addr_i(fu2rcu_alu2_wrb_prd_addr), 
    .physical_lsu_wrb_addr_i(fu2rcu_lsu_wrb_addr), 
    .physical_md_wrb_addr_i(fu2rcu_md_wrb_prd_addr),
    .alu1_predict_miss_i(fu2rcu_alu1_predict_miss),
    .alu1_branch_taken_i(fu2rcu_alu1_branch_taken),
    .alu1_final_branch_pc_i(fu2rcu_alu1_final_branch_pc),
    .alu2_predict_miss_i(fu2rcu_alu2_predict_miss),
    .alu2_branch_taken_i(fu2rcu_alu2_branch_taken),
    .alu2_final_branch_pc_i(fu2rcu_alu2_final_branch_pc),
    .func_alu1_rob_index_i(fu2rcu_alu1_wrb_rob_index),
    .func_alu2_rob_index_i(fu2rcu_alu2_wrb_rob_index),
    .func_lsu_rob_index_i(fu2rcu_lsu_comm_rob_index_fix),
    .func_md_rob_index_i(fu2rcu_md_wrb_rob_index),
    .func_csru_rob_index_i(fu2rcu_csr_wrb_rob_index),
    .physical_alu1_wrb_data_i(fu2rcu_alu1_wrb_data), 
    .physical_csru_wrb_data_i(fu2rcu_csr_wrb_data), 
    .physical_alu2_wrb_data_i(fu2rcu_alu2_wrb_data), 
    .physical_lsu_wrb_data_i(fu2rcu_lsu_wrb_data), 
    .physical_md_wrb_data_i(fu2rcu_md_wrb_data),
    .func_wrb_alu1_exp_i(func_wrb_alu1_exp_i),
    .func_wrb_alu2_exp_i(func_wrb_alu2_exp_i),
    .func_wrb_lsu_exp_i(fu2rcu_lsu_exception_vld),
    .func_wrb_md_exp_i(func_wrb_md_exp_i),
    .func_wrb_csru_exp_i(fu2rcu_csr_exception),
    .func_wrb_alu1_ecause_i(func_wrb_alu1_ecause_i),
    .func_wrb_alu2_ecause_i(func_wrb_alu2_ecause_i),
    .func_wrb_lsu_ecause_i(fu2rcu_lsu_ecause),
    .func_wrb_md_ecause_i(func_wrb_md_ecause_i),
    .func_wrb_csru_ecause_i(fu2rcu_csr_ecause),
    .rcu_alu1_req_valid_o(rcu2fu_alu1_req_valid),
    .rcu_alu2_req_valid_o(rcu2fu_alu2_req_valid),
    .rcu_md_req_ready_i(rcu2fu_md_req_ready),
    .rcu_md_req_valid_o(rcu2fu_md_req_valid),
    .rcu_lsu_req_ready_i(fu2rcu_lsu_req_ready),
    .rcu_lsu_req_valid_o(rcu2fu_lsu_req_valid),
    .rcu_csr_req_valid_o(rcu2fu_csru_req_valid),
    .rcu_lsu_wakeup_o(rcu2fu_lsu_wakeup),
    .rcu_lsu_wakeup_index_o(rcu2fu_lsu_wakeup_index),
    .rcu_alu1_rob_index_o(rcu2fu_alu1_rob_index),
    .rcu_alu1_prd_address_o(rcu2fu_alu1_prd_addr),
    .rcu_alu1_func3_o(rcu2fu_alu1_func3),
    .rcu_alu1_pc_o(rcu2fu_alu1_pc), 
    .rcu_alu1_next_pc_o(rcu2fu_alu1_next_pc),
    .rcu_alu1_predict_pc_o(rcu2fu_alu1_predict_pc),
    .rcu_alu1_imm_data_o(rcu2fu_alu1_imm_data),
    .rcu_alu1_select_a_o(rcu2fu_alu1_opr1_sel),
    .rcu_alu1_select_b_o(rcu2fu_alu1_opr2_sel),
    .rcu_alu1_rs1_data_o(rcu2fu_alu1_rs1_data),
    .rcu_alu1_rs2_data_o(rcu2fu_alu1_rs2_data),
    .rcu_alu1_jump_o(rcu2fu_alu1_is_jump),
    .rcu_alu1_branch_o(rcu2fu_alu1_is_branch),
    .rcu_alu1_half_o(rcu2fu_alu1_half),
    .rcu_alu1_func_modifier_o(rcu2fu_alu1_func_modifier),
    .rcu_alu2_rob_index_o(rcu2fu_alu2_rob_index),
    .rcu_alu2_prd_address_o(rcu2fu_alu2_prd_addr),
    .rcu_alu2_func3_o(rcu2fu_alu2_func3),
    .rcu_alu2_pc_o(rcu2fu_alu2_pc), 
    .rcu_alu2_next_pc_o(rcu2fu_alu2_next_pc),
    .rcu_alu2_predict_pc_o(rcu2fu_alu2_predict_pc),
    .rcu_alu2_imm_data_o(rcu2fu_alu2_imm_data),
    .rcu_alu2_select_a_o(rcu2fu_alu2_opr1_sel),
    .rcu_alu2_select_b_o(rcu2fu_alu2_opr2_sel),
    .rcu_alu2_rs1_data_o(rcu2fu_alu2_rs1_data),
    .rcu_alu2_rs2_data_o(rcu2fu_alu2_rs2_data),
    .rcu_alu2_jump_o(rcu2fu_alu2_is_jump),
    .rcu_alu2_branch_o(rcu2fu_alu2_is_branch),
    .rcu_alu2_half_o(rcu2fu_alu2_half),
    .rcu_alu2_func_modifier_o(rcu2fu_alu2_func_modifier),
    .rcu_md_package_o(rcu2fu_md_package),
    .rcu_lsu_package_o(rcu2fu_lsu_package),
    .rcu_csr_rob_index_o(rcu2fu_csru_rob_index),
    .rcu_csr_prd_address_o(rcu2fu_csru_prd_addr),
    .rcu_csr_func3_o(rcu2fu_csru_func3),
    .rcu_csr_rs1_data_o(rcu2fu_csru_prs1_data),
    .rcu_csr_imm_data_o(rcu2fu_csru_imm),
    .rcu_csr_address_o(rcu2fu_csru_addr),
    .rcu_csr_do_read_o(rcu2fu_csru_do_read),
    .rcu_csr_do_write_o(rcu2fu_csru_do_write),
    .rcu_bpu_cmt_is_branch_first_o(rcu2ft_bpu_cmt_is_branch_first),
    .rcu_bpu_cmt_is_branch_second_o(rcu2ft_bpu_cmt_is_branch_second),
    .rcu_bpu_cmt_branch_taken_first_o(rcu2ft_bpu_cmt_branch_taken_first),
    .rcu_bpu_cmt_branch_taken_second_o(rcu2ft_bpu_cmt_branch_taken_second),
    .rcu_bpu_cmt_final_pc_first_o(rcu2ft_bpu_cmt_final_pc),   
    .rcu_bpu_cmt_final_pc_second_o(rcu_bpu_cmt_final_pc_second_o),  
    .rcu_bpu_cmt_pc_first_o(rcu2ft_bpu_cmt_pc_first),
    .rcu_bpu_cmt_pc_second_o(rcu2ft_bpu_cmt_pc_second),
    .rcu_bpu_alu_result_pc_o(rcu2ft_bpu_alu_result_pc),
    .rcu_do_rob_commit_first_o(rcu_do_rob_commit_first),
    .rcu_do_rob_commit_second_o(rcu_do_rob_commit_second),
    .rcu_cmt_pc_excp_o(rcu2exp_cmt_pc),
    .predict_miss_o(rcu2excp_predict_miss),
    .rcu_cmt_exception_o(rcu2excp_cmt_exception),
    .rcu_cmt_ecause_o(rcu2excp_cmt_ecause),
    .rcu_cmt_is_mret(rcu2excp_cmt_is_mret),
    .rcu_cmt_is_sret(rcu2excp_cmt_is_sret),
    .rcu_cmt_is_wfi(rcu2excp_cmt_is_wfi)
);          //end rcu
//psudo alu
//always @(*) begin
//    func_alu1_done_valid_i = rcu_alu1_req_valid_o;
//    physical_alu1_wrb_data_i = rcu2fu_alu1_rs1_data;
//    func_alu1_rob_index_i = rcu_alu1_rob_index_o;
//    physical_alu1_wrb_addr_i = rcu_alu1_prd_address_o;
//    func_wrb_alu1_exp_i = 0;
//    func_wrb_alu1_ecause_i = 0;
//end
//
//
assign  {rcu2fu_lsu_rob_index     , 
        rcu2fu_lsu_rd_addr    , 
        rcu2fu_agu_virt_base      , // rs1_data
        rcu2fu_lsu_data, 
        rcu2fu_agu_virt_offset           , //imm
        lsu_is_load        ,
        lsu_is_store       , 
        rcu2fu_lsu_ld_opcode      ,
        rcu2fu_lsu_st_opcode      ,
        rcu2fu_lsu_fenced     ,       
        lsu_lsu_fence_op   ,        //Not used
        lsu_aext           ,        //Not used
        rcu2fu_lsu_aq   ,
        rcu2fu_lsu_rl
        } = rcu2fu_lsu_package;

assign rcu2lsu_ls = lsu_is_store;
assign rcu2fu_lsu_fenced_final = rcu2fu_lsu_fenced | rcu2fu_lsu_aq   | rcu2fu_lsu_rl;
// always @(*) begin
//     lsu(
//         .clk               (clk),
//         .lsu_rob_valid_i   (rcu2fu_lsu_req_valid),
//         .lsu_rob_index_i   (lsu_rob_index),
//         .lsu_prd_address_i (lsu_prd_address),
//         .lsu_rs1_data_i    (lsu_rs1_data),
//         .lsu_rs2_data_i    (lsu_rs2_data),
//         .lsu_imm_i         (lsu_imm),
//         .lsu_is_load_i     (lsu_is_load),
//         .lsu_is_store_i    (lsu_is_store),
//         .lsu_wakeup_i      (rcu2fu_lsu_wakeup),
//         .lsu_rcu_valid_o   (fu2rcu_lsu_done_valid),
//         .lsu_rcu_ready_o   (lsu2rcu_lsu_req_ready),
//         .lsu_prd_address_o (lsu2rcu_wrb_addr),
//         .lsu_wrb_data_o    (lsu2rcu_wrb_data),
//         .lsu_rob_index_o   (lsu2rcu_rob_index),
//         .lsu_rcu_excep_o   (lsu2rcu_wrb_lsu_exp),
//         .lsu_rcu_ecause_o  (lsu2rcu_wrb_lsu_ecause)
//     );
// end

//reg [63:0] mem[5000:0];


//always @(posedge clk) begin
//    if(rst) begin
//        for (int i; i < 5000; i = i + 1) begin
//            mem[i] = 0;
//        end
//    end else if (lsu_is_load) begin
//        fu2rcu_lsu_done_valid    <= lsu_is_load;
//        lsu2rcu_lsu_req_ready    <= 1;
//        lsu2rcu_wrb_addr         <= lsu_prd_address;
//        lsu2rcu_wrb_data         <= mem[lsu_rs1_data + lsu_imm];
//        lsu2rcu_rob_index        <= lsu_rob_index;
//        lsu2rcu_wrb_lsu_exp      <= 0;
//        lsu2rcu_wrb_lsu_ecause   <= 0;
//    end else if (lsu_is_store) begin
//        fu2rcu_lsu_done_valid    <= lsu_is_store;
//        lsu2rcu_wrb_addr         <= lsu_prd_address;
//        mem[lsu_rs1_data + lsu_imm] <= lsu_rs2_data;
//        lsu2rcu_rob_index        <= lsu_rob_index;
//        lsu2rcu_wrb_lsu_exp      <= 0;
//        lsu2rcu_wrb_lsu_ecause   <= 0;
//    end else begin
//        fu2rcu_lsu_done_valid    <= 0;
//        lsu2rcu_lsu_req_ready    <= 1;
//        lsu2rcu_wrb_data         <= 0;
//        lsu2rcu_rob_index        <= 0;
//        lsu2rcu_wrb_lsu_exp      <= 0;
//        lsu2rcu_wrb_lsu_ecause   <= 0;
//    end
//end



fu fu(
    .clk(clk),
    .rstn(rst),
    .wfi(global_wfi),
    .global_trap(global_trap),
    .global_ret(global_ret),
    .global_predict_miss(global_predict_miss),


    .rcu_fu_alu1_rs1_i(rcu2fu_alu1_rs1_data),
    .rcu_fu_alu2_rs1_i(rcu2fu_alu2_rs1_data),
    .rcu_fu_alu1_rs2_i(rcu2fu_alu1_rs2_data),
    .rcu_fu_alu2_rs2_i(rcu2fu_alu2_rs2_data),
    .rcu_fu_alu1_imm_data_i(rcu2fu_alu1_imm_data),
    .rcu_fu_alu2_imm_data_i(rcu2fu_alu2_imm_data),
    .rcu_fu_alu1_opr1_sel_i(rcu2fu_alu1_opr1_sel),
    .rcu_fu_alu2_opr1_sel_i(rcu2fu_alu2_opr1_sel),
    .rcu_fu_alu1_opr2_sel_i(rcu2fu_alu1_opr2_sel),
    .rcu_fu_alu2_opr2_sel_i(rcu2fu_alu2_opr2_sel),

    .rcu_fu_alu1_rob_index_i(rcu2fu_alu1_rob_index),
    .rcu_fu_alu2_rob_index_i(rcu2fu_alu2_rob_index),
    .rcu_fu_alu1_prd_addr_i(rcu2fu_alu1_prd_addr),
    .rcu_fu_alu2_prd_addr_i(rcu2fu_alu2_prd_addr),
    .rcu_fu_alu1_is_branch_i(rcu2fu_alu1_is_branch),
    .rcu_fu_alu2_is_branch_i(rcu2fu_alu2_is_branch),
    .rcu_fu_alu1_is_jump_i(rcu2fu_alu1_is_jump),
    .rcu_fu_alu2_is_jump_i(rcu2fu_alu2_is_jump),
    .rcu_fu_alu1_req_valid_i(rcu2fu_alu1_req_valid),
    .rcu_fu_alu2_req_valid_i(rcu2fu_alu2_req_valid),

    .rcu_fu_alu1_half_i(rcu2fu_alu1_half),
    .rcu_fu_alu2_half_i(rcu2fu_alu2_half),
    .rcu_fu_alu1_pc_i(rcu2fu_alu1_pc),
    .rcu_fu_alu2_pc_i(rcu2fu_alu2_pc),
    .rcu_fu_alu1_next_pc_i(rcu2fu_alu1_next_pc),
    .rcu_fu_alu2_next_pc_i(rcu2fu_alu2_next_pc),
    .rcu_fu_alu1_predict_pc_i(rcu2fu_alu1_predict_pc),
    .rcu_fu_alu2_predict_pc_i(rcu2fu_alu2_predict_pc),
    .rcu_fu_alu1_func3_i(rcu2fu_alu1_func3),
    .rcu_fu_alu2_func3_i(rcu2fu_alu2_func3),
    .rcu_fu_alu1_func_modifier_i(rcu2fu_alu1_func_modifier),
    .rcu_fu_alu2_func_modifier_i(rcu2fu_alu2_func_modifier),

    .fu_rcu_alu1_resp_valid_o(fu2rcu_alu1_resp_valid),
    .fu_rcu_alu2_resp_valid_o(fu2rcu_alu2_resp_valid),
    .fu_rcu_alu1_wrb_rob_index_o(fu2rcu_alu1_wrb_rob_index),
    .fu_rcu_alu2_wrb_rob_index_o(fu2rcu_alu2_wrb_rob_index),
    .fu_rcu_alu1_wrb_prd_addr_o(fu2rcu_alu1_wrb_prd_addr),
    .fu_rcu_alu2_wrb_prd_addr_o(fu2rcu_alu2_wrb_prd_addr),
    .fu_rcu_alu1_wrb_data_o(fu2rcu_alu1_wrb_data),
    .fu_rcu_alu2_wrb_data_o(fu2rcu_alu2_wrb_data),
    .fu_rcu_alu1_branch_predict_miss_o(fu2rcu_alu1_predict_miss),
    .fu_rcu_alu2_branch_predict_miss_o(fu2rcu_alu2_predict_miss),
    .fu_rcu_alu1_branch_taken_o(fu2rcu_alu1_branch_taken),
    .fu_rcu_alu2_branch_taken_o(fu2rcu_alu2_branch_taken),
    .fu_rcu_alu1_final_next_pc_o(fu2rcu_alu1_final_branch_pc),
    .fu_rcu_alu2_final_next_pc_o(fu2rcu_alu2_final_branch_pc),

    .rcu_fu_md_package_i(rcu2fu_md_package),
    .rcu_fu_md_req_valid_i(rcu2fu_md_req_valid),
    .rcu_fu_md_req_ready_o(rcu2fu_md_req_ready),

    .fu_rcu_md_wrb_prd_addr_o(fu2rcu_md_wrb_prd_addr),
    .fu_rcu_md_wrb_rob_index_o(fu2rcu_md_wrb_rob_index),
    .fu_rcu_md_wrb_data_o(fu2rcu_md_wrb_data),
    .fu_rcu_md_wrb_resp_valid_o(fu2rcu_md_wrb_resp_valid),
    
    .lsu_rdy_o(fu2rcu_lsu_req_ready),          

    .rcu_fu_lsu_vld_i(rcu2fu_lsu_req_valid),
    .rcu_fu_lsu_ls_i(rcu2fu_lsu_ls),
    .rcu_fu_lsu_st_opcode_i(rcu2fu_lsu_st_opcode),
    .rcu_fu_lsu_ld_opcode_i(rcu2fu_lsu_ld_opcode),
    .rcu_fu_lsu_fenced_i(rcu2fu_lsu_fenced_final),
    .rcu_fu_agu_virt_base_i(rcu2fu_agu_virt_base),
    .rcu_fu_agu_virt_offset_i(rcu2fu_agu_virt_offset),
    .rcu_fu_lsu_rob_index_i(rcu2fu_lsu_rob_index),
    .rcu_fu_lsu_rd_addr_i(rcu2fu_lsu_rd_addr),
    .rcu_fu_lsu_data_i(rcu2fu_lsu_data),
    .rcu_fu_lsu_wakeup_i(rcu2fu_lsu_wakeup),
    .rcu_fu_lsu_wakeup_rob_index_i(rcu2fu_lsu_wakeup_rob_index),
    .fu_rcu_lsu_comm_vld_o(fu2rcu_lsu_comm_vld_fix),
    .fu_rcu_lsu_comm_rob_index_o(fu2rcu_lsu_comm_rob_index_fix),
    .fu_rcu_lsu_exception_vld_o(fu2rcu_lsu_exception_vld),
    .fu_rcu_lsu_ecause_o(fu2rcu_lsu_ecause),

    .fu_prf_lsu_wb_vld_o(fu2rcu_lsu_done_valid_fix),
    .fu_prf_lsu_wb_rd_addr_o(fu2rcu_lsu_wrb_addr_fix),
    .fu_prf_lsu_wb_data_o(fu2rcu_lsu_wrb_data),

    .dtlb_fu_lsu_exception_vld_i(dtlb2fu_lsu_exception_vld),
    .dtlb_fu_lsu_ecause_i(dtlb2fu_lsu_ecause),
    .fu_dtlb_lsu_iss_type_o(fu2dtlb_lsu_iss_type),
    .dtlb_fu_lsu_rdy_i(dtlb2fu_lsu_rdy),
    .dtlb_fu_lsu_vld_i(dtlb2fu_lsu_vld), // s
    .dtlb_fu_lsu_hit_i(dtlb2fu_lsu_hit),
    .dtlb_fu_lsu_ptag_i(dtlb2fu_lsu_ptag),
    .fu_dtlb_lsu_iss_vld_o(fu2dtlb_lsu_iss_vld),
    .fu_dtlb_lsu_iss_vtag_o(fu2dtlb_lsu_iss_vtag),


    .l1d_fu_lsu_ld_req_rdy_i(l1d2fu_lsu_ld_req_rdy_i),
    .fu_l1d_lsu_ld_req_vld_o(fu2l1d_lsu_ld_req_vld_o),
    .fu_l1d_lsu_ld_req_rob_index_o(fu2l1d_lsu_ld_req_rob_index_o),
    .fu_l1d_lsu_ld_req_rd_addr_o(fu2l1d_lsu_ld_req_rd_addr_o),
    .fu_l1d_lsu_ld_req_opcode_o(fu2l1d_lsu_ld_req_opcode_o),
    .fu_l1d_lsu_ld_req_index_o(fu2l1d_lsu_ld_req_index_o), 
    .fu_l1d_lsu_ld_req_offset_o(fu2l1d_lsu_ld_req_offset_o),
    .fu_l1d_lsu_ld_req_vtag_o(fu2l1d_lsu_ld_req_vtag_o), 

    .l1d_fu_lsu_st_req_rdy_i(l1d2fu_lsu_st_req_rdy_i),
    .fu_l1d_lsu_st_req_vld_o(fu2l1d_lsu_st_req_vld_o),
    .fu_l1d_lsu_st_req_is_fence_o(fu2l1d_lsu_st_req_is_fence_o),
    .fu_l1d_lsu_st_req_rob_index_o(fu2l1d_lsu_st_req_rob_index_o),
    .fu_l1d_lsu_st_req_rd_addr_o(fu2l1d_lsu_st_req_rd_addr_o),
    .fu_l1d_lsu_st_req_opcode_o(fu2l1d_lsu_st_req_opcode_o),
    .fu_l1d_lsu_st_req_paddr_o(fu2l1d_lsu_st_req_paddr_o), 
    .fu_l1d_lsu_st_req_data_o(fu2l1d_lsu_st_req_data_o),
     
    .l1d_fu_lsu_ld_replay_vld_i(l1d2fu_lsu_ld_replay_vld_i),
    // wb
    .l1d_fu_lsu_wb_vld_i(l1d2fu_lsu_wb_vld_i),
    .l1d_fu_lsu_wb_rob_index_i(l1d2fu_lsu_wb_rob_index_i),
    .l1d_fu_lsu_prf_wb_vld_i(l1d2fu_lsu_prf_wb_vld_i),
    .l1d_fu_lsu_prf_wb_rd_addr_i(l1d2fu_lsu_prf_wb_rd_addr_i),
    .l1d_fu_lsu_prf_wb_data_i(l1d2fu_lsu_prf_wb_data_i),
    // kill 
    .fu_l1d_lsu_kill_req_o(fu2l1d_lsu_kill_req_o),

    .fu_wb_lsu_cyc_o(fu2wb_lsu_cyc_o),
    .fu_wb_lsu_stb_o(fu2wb_lsu_stb_o),
    .fu_wb_lsu_we_o(fu2wb_lsu_we_o),
    .fu_wb_lsu_adr_o(fu2wb_lsu_adr_o),
    .fu_wb_lsu_dat_o(fu2wb_lsu_dat_o),
    .fu_wb_lsu_sel_o(fu2wb_lsu_sel_o),
    .wb_fu_lsu_ack_i(wb2fu_lsu_ack_i),
    .wb_fu_lsu_dat_i(wb2fu_lsu_dat_i),
//`endif //LSU_DOING

    //from rcu
    .rcu_fu_csru_rob_index_i(rcu2fu_csru_rob_index),
    .rcu_fu_csru_prd_addr_i(rcu2fu_csru_prd_addr),
    .rcu_fu_csru_func3_i(rcu2fu_csru_func3),
    .rcu_fu_csru_prs1_data_i(rcu2fu_csru_prs1_data),
    .rcu_fu_csru_imm_i(rcu2fu_csru_imm),
    .rcu_fu_csru_addr_i(rcu2fu_csru_addr),
    .rcu_fu_csru_do_read_i(rcu2fu_csru_do_read),
    .rcu_fu_csru_do_write_i(rcu2fu_csru_do_write),
    //hand shake
    .rcu_fu_csru_req_valid_i(rcu2fu_csru_req_valid),

    //csr read
    .fu_csr_csru_raddr_o(fu2csr_csru_raddr),
    .csr_fu_csru_rdata_i(csr2fu_csru_rdata),
    .csr_fu_csru_readable_i(csr2fu_csru_readable),
    .csr_fu_csru_writable_i(csr2fu_csru_writable),
    
    //csr write
    // output csr_addr_o,
    .fu_do_csr_write_o(fu2csr_csru_do_write),
    .fu_csr_waddr_o(fu2csr_csru_waddr),
    .fu_csr_wrdata_o(fu2csr_csru_wrdata),

    //rcu wrb
    .fu_rcu_csr_resp_valid_o(fu2rcu_csr_resp_valid),
    .fu_rcu_csr_wrb_rob_index_o(fu2rcu_csr_wrb_rob_index),
    .fu_rcu_csr_wrb_addr_o(fu2rcu_csr_wrb_addr),
    .fu_rcu_csr_wrb_data_o(fu2rcu_csr_wrb_data),
    .fu_rcu_csr_exception_o(fu2rcu_csr_exception),
    .fu_rcu_csr_ecause_o(fu2rcu_csr_ecause),


    .fu_pmp_csru_cfg_vld_o(fu2pmp_csru_cfg_vld),
    .fu_pmp_csru_cfg_addr_o(fu2pmp_csru_cfg_addr),
    .fu_pmp_csru_cfg_payload_o(fu2pmp_csru_cfg_payload),
    .pmp_fu_csru_cfg_origin_payload_i(pmp2fu_csru_cfg_origin_payload),
    .fu_pmp_csru_addr_vld_o(fu2pmp_csru_addr_vld),
    .fu_pmp_csru_addr_addr_o(fu2pmp_csru_addr_addr),
    .fu_pmp_csru_addr_payload_o(fu2pmp_csru_addr_payload),
    .pmp_fu_csru_addr_origin_payload_i(pmp2fu_csru_addr_origin_payload)

);          //end fu

csr_regfile csr_regfile_u(
    .clk(clk),
    .rst(rst),
    .csr_w_i(fu2csr_csru_do_write),
    .csr_addr_w_i(fu2csr_csru_waddr),
    .csr_addr_r_i(fu2csr_csru_raddr),
    .csr_data_w_i(fu2csr_csru_wrdata),

//  from exception ctrl
    .excp_pending_i(global_trap),
    .excp_cause_i(excp2csr_ecause),
    .excp_pc_i(excp2csr_pc),

    .m_ret_i(global_mret),
    .s_ret_i(global_mret),

// to csru
    .csr_data_r_o(csr2fu_csru_rdata),
    .readable_o(csr2fu_csru_readable),
    .writeable_o(csr2fu_csru_writeable),
// to fetch
    .excp_pc_o(csr2fetch_trap_vector),
// to decode
    .current_mode_o(csr2decode_priv_mode),
    .tsr_o(tsr_o),

    .mstatus_o(mstatus_o),
    .satp_o(satp_o)
);

excep_ctrl exception_control(
    .rob_do_cmt_valid_i(rcu_do_rob_commit_first),
    .rob_do_cmt_second_valid_i(rcu_do_rob_commit_second),
    .rob_cmt_pc_i(rcu2exp_cmt_pc),
    .rob_cmt_mret_i(rcu2excp_cmt_is_mret),
    .rob_cmt_sret_i(rcu2excp_cmt_is_sret),
    .rob_cmt_wfi_i(rcu2excp_cmt_is_wfi),
    .predict_miss_i(rcu2excp_predict_miss),
    .rob_cmt_ecause_i(rcu2excp_cmt_ecause),
    .rob_cmt_exp_i(rcu2excp_cmt_exception),
    
    .global_trap_o(global_trap),
    .global_predict_miss_o(global_predict_miss),
    .global_ret_o(global_ret),

    .csr_pc_o(excp2csr_pc),
    .csr_ecause_o(excp2csr_ecause),
    
    .global_mret_o(global_mret),
    .global_sret_o(global_sret),
    .global_wfi_o(global_wfi)
);

//rvh_monolithic_mmu mmu(
//    .clk(clk),
//    .rstn(rstn),
//
//    .priv_lvl_i(mmu_priv_lvl_i),
// 
//    .satp_mode_i(mmu_satp_mode_i),
//    .satp_asid_i(mmu_satp_asid_i),
//    .satp_ppn_i(mmu_satp_ppn_i),
//
//    .misc_mstatus_i(mmu_misc_mstatus_i),
//
//    .dtlb_translate_req_vld_i(dtlb2mmu_translate_req_vld_i),
//    .dtlb_translate_req_access_type_i(dtlb2mmu_translate_req_access_type_i),
//    .dtlb_translate_req_vpn_i(dtlb2mmu_translate_req_vpn_i),
//    output [TRANSLATE_WIDTH-1:0] dtlb_translate_req_rdy_o,
//    // DTLB Translate Port -> Response
//    output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_vld_o,
//    output [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] dtlb_translate_resp_ppn_o,
//    output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_excp_vld_o,
//    output [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0] dtlb_translate_resp_excp_cause_o,
//    output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_miss_o,
//    output [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_hit_o,
//
//    // ITLB Translate Port -> Request
//.itlb_translate_req_vld_i(itlb2mmu_translate_req_vld_i),
//    // MODE == Read(Execute)
//    // input [TRANSLATE_WIDTH-1:0][1:0] itlb_translate_req_access_type_i,
//.itlb_translate_req_vpn_i(itlb2mmu_translate_req_vpn_i),
//    output [TRANSLATE_WIDTH-1:0] itlb_translate_req_rdy_o,
//    // ITLB Translate Port -> Response
//    output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_vld_o,
//    output [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0] itlb_translate_resp_ppn_o,
//    output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_excp_vld_o,
//    output [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0] itlb_translate_resp_excp_cause_o,
//    output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_miss_o,
//    output [TRANSLATE_WIDTH-1:0] itlb_translate_resp_hit_o,
//
//
//    // dtlb shoot down
//.dtlb_flush_vld_i(dtlb2mmu_flush_vld_i),
//.dtlb_flush_use_asid_i(dtlb2mmu_flush_use_asid_i),
//.dtlb_flush_use_vpn_i(dtlb2mmu_flush_use_vpn_i),
//.dtlb_flush_vpn_i(dtlb2mmu_flush_vpn_i),
//.dtlb_flush_asid_i(dtlb2mmu_flush_asid_i),
//    output dtlb_flush_grant_o,
//    // itlb shoot down
//.itlb_flush_vld_i(itlb2mmu_flush_vld_i),
//.itlb_flush_use_asid_i(itlb2mmu_flush_use_asid_i),
//.itlb_flush_use_vpn_i(itlb2mmu_flush_use_vpn_i),
//.itlb_flush_vpn_i(itlb2mmu_flush_vpn_i),
//.itlb_flush_asid_i(itlb2mmu_flush_asid_i),
//    output itlb_flush_grant_o,
//
//    output tlb_flush_grant_o,
//
//
//    // ptw walk request port
//    output ptw_walk_req_vld_o,
//    output [PTW_ID_WIDTH-1:0] ptw_walk_req_id_o,
//    output [PADDR_WIDTH-1:0] ptw_walk_req_addr_o,
//.ptw_walk_req_rdy_i(ptw2mmu_walk_req_rdy_i),
//    // ptw walk response port
//.ptw_walk_resp_vld_i(ptw2mmu_walk_resp_vld_i),
//.ptw_walk_resp_pte_i(ptw2mmu_walk_resp_pte_i),
//    output ptw_walk_resp_rdy,
//
//
//);



always @(*) begin
    //fu2rcu_alu2_wrb_data = rcu_alu2_rs1_data_o;
    func_wrb_alu2_exp_i = 0;
    func_wrb_alu2_ecause_i = 0;
    func_wrb_alu1_exp_i = 0;
    func_wrb_alu1_ecause_i = 0;
    func_wrb_md_exp_i = 0;
    func_wrb_md_ecause_i = 0;
end
//: psudo alu

//assign alu_function_modifier_first_i = dec2rcu_alu_function_modifier_first;
  
//initial begin
//    int dumpon = 0;
//    string log;
//    string wav;
//    $value$plusargs("dumpon=%d",dumpon);
//    if ($value$plusargs("sim_log=%s",log)) begin
//        $display("wave_log= %s",log);
//    end
//    wav = {log,"/waves.fsdb"};
//    $display("wave_log= %s",wav);
//    if(dumpon > 0) begin
//      $fsdbDumpfile(wav);
//      $fsdbDumpvars(0,tb_top);
//      $fsdbDumpvars("+struct");
//      $fsdbDumpvars("+mda");
//      $fsdbDumpvars("+all");
//      $fsdbDumpon;
//    end
//end

endmodule : tb_top

