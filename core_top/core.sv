module core_top(
    input clk,
    input rst,
    //fetch
    input                                           ft2l1i_if_req_rdy_i,
    input                                           l1i2ft_if_resp_vld_i,
    input [$clog2(IFQ_DEPTH)-1:0]                   l1i2ft_if_resp_if_tag_i,
    input [FETCH_WIDTH-1:0]                         l1i2ft_if_resp_data_i,
    output                                          ft2l1i_if_req_vld_o,
    output [L1I_INDEX_WIDTH-1:0]                    ft2l1i_if_req_index_o,
    output [$clog2(IFQ_DEPTH)-1:0]                  ft2l1i_if_req_if_tag_o,
    output [L1I_OFFSET_WIDTH-1:0]                   ft2l1i_if_req_offset_o,

    //decode
    input                                           msip_i,
    input                                           ssip_i,
    input                                           mtip_i,
    input                                           stip_i,
    input                                           eip_i,

    //fu

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
    input [LSU_DATA_PIPE_COUNT - 1 : 0]            l1d2fu_lsu_prf_wb_vld_i,
    input [PHY_REG_ADDR_WIDTH * LSU_DATA_PIPE_COUNT - 1 : 0]     l1d2fu_lsu_prf_wb_rd_addr_i,
    input [XLEN*LSU_DATA_PIPE_COUNT - 1 : 0]       l1d2fu_lsu_prf_wb_data_i,
    output                                         fu2l1d_lsu_kill_req_o,

    output                                         lsu_l1d_fencei_flush_vld_o,
    input                                          l1d_lsu_fencei_flush_grant_i,

    // <> l1i                                                   
    output                                         lsu_l1i_fencei_flush_vld_o,
    input                                          l1i_lsu_fencei_flush_grant_i,
    `ifdef DPRAM64_2R1W
    output [XLEN/8-1:0] 		                        we,
    output [XLEN-1:0] 		                            din,
    output [PHYSICAL_ADDR_LEN-1:0]                      waddr,
    output [PHYSICAL_ADDR_LEN-1:0]                      raddr_d,
    output [1:0]                                        re_d,
    output                                              runsigned_d,  
    output  [     ROB_INDEX_WIDTH - 1 : 0]              wrob_index_d,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]            wrd_addr_d,                   
    output  [     ROB_INDEX_WIDTH - 1 : 0]              rrob_index_d,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]            rrd_addr_d,                                   
    `endif // DPRAM64_2R1W
        //fu <-> wb bus
    output                                          fu2wb_lsu_cyc_o,
    output                                          fu2wb_lsu_stb_o,
    output                                          fu2wb_lsu_we_o,
    output [PHYSICAL_ADDR_LEN - 1 : 0]              fu2wb_lsu_adr_o,
    output [WB_DATA_LEN-1:0]                        fu2wb_lsu_dat_o,
    output [WB_DATA_LEN/8-1:0]                      fu2wb_lsu_sel_o,
    input                                          wb2fu_lsu_ack_i,
    input [WB_DATA_LEN -1:0]                       wb2fu_lsu_dat_i,

    //     //fu <-> pmp
    // output                                             fu2pmp_csru_cfg_vld_o,
    // output    [PMPCFG_ID_WIDTH-1:0]                    fu2pmp_csru_cfg_addr_o,
    // output    [XLEN-1:0]                               fu2pmp_csru_cfg_payload_o,
    // input    [XLEN-1:0]                               pmp2fu_csru_cfg_origin_payload_i,
    // output                                             fu2pmp_csru_addr_vld_o,
    // output    [PMPADDR_ID_WIDTH-1:0]                   fu2pmp_csru_addr_addr_o,
    // output    [XLEN-1:0]                               fu2pmp_csru_addr_payload_o,
    // input    [XLEN-1:0]                               pmp2fu_csru_addr_origin_payload_i,

    // // csr_regfile to mmu
    // output      [XLEN - 1 : 0] satp_o,
    // output      [XLEN - 1 : 0] mstatus_o,

    // mmu to cache
    // to icache
    output                          itlb2ic_if_resp_vld_o          ,
    output [         PPN_WIDTH-1:0] itlb2icache_ic_ptag_o          ,
    output                          itlb2ft_resp_excp_vld_o        ,
    output                          itlb_translate_resp_miss_o     ,
    output                          itlb_translate_resp_hit_o      ,
    // to dcache
    output [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_vld_o          ,
    output [LSU_ADDR_PIPE_COUNT*PPN_WIDTH-1:0]               dtlb2dcache_lsu_ptag_o         ,
    output [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_exception_vld_o,
    output [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_miss_o         ,
    output [LSU_ADDR_PIPE_COUNT-1:0]                         dtlb2dcache_lsu_hit_o          ,

    output                                              mmu2cache_ptw_walk_req_vld_o ,
    output [PTW_ID_WIDTH-1:0]                           mmu2cache_ptw_walk_req_id_o  ,
    output [PADDR_WIDTH-1:0]                            mmu2cache_ptw_walk_req_addr_o,
    input                                               mmu2cache_ptw_walk_req_rdy_i ,
    // ptw walk response port
    input                                               mmu2cache_ptw_walk_resp_vld_i,
    input [PTE_WIDTH-1:0]                               mmu2cache_ptw_walk_resp_pte_i,
    output                                              mmu2cache_ptw_walk_resp_rdy_o
);

wire [PC_WIDTH-1:0] ft2dec_pc_first;
wire [PC_WIDTH-1:0] ft2dec_pc_second;
wire [PC_WIDTH-1:0] ft2dec_next_pc_second;
wire [PC_WIDTH-1:0] ft2dec_next_pc_first;
wire [PC_WIDTH-1:0] ft2dec_predicted_pc_first;
wire [PC_WIDTH-1:0] fu2dec_predicted_pc_second;
wire ft2dec_is_rv_first;
wire ft2dec_is_rv_second;
wire [31:0] ft2dec_instruction_first;
wire [31:0] fu2dec_instruction_second;
wire ft2dec_excp_first;
wire ft2dec_excp_second;
wire [EXCEPTION_CAUSE_WIDTH-1:0] ft2dec_ecause_first;
wire [EXCEPTION_CAUSE_WIDTH-1:0] ft2dec_ecause_second;
wire ft2dec_req_valid_first;
wire ft2dec_req_valid_second;
wire dec2rcu_req_ready_first;
wire dec2rcu_req_ready_second;
wire global_wfi;

wire ft2dec_req_single_ready;
wire ft2dec_req_double_ready;
wire dec2rcu_uses_rs1_first;
wire dec2rcu_uses_rs1_second;
wire dec2rcu_uses_rs2_first;
wire dec2rcu_uses_rd_first;
wire dec2rcu_uses_rd_second;
wire dec2rcu_uses_csr_first;
wire dec2rcu_uses_csr_second;
wire [PC_WIDTH-1 :0] dec2rcu_pc_first;
wire [PC_WIDTH-1 :0] dec2rcu_pc_second;
wire [PC_WIDTH-1 :0] dec2rcu_next_pc_first;
wire [PC_WIDTH-1 :0] dec2rcu_next_pc_second;
wire [PC_WIDTH-1 :0] dec2rcu_predicted_pc_first;
wire [PC_WIDTH-1 :0] dec2rcu_predicted_pc_second;
wire [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs1_address_first;
wire [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs1_address_second;
wire [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs2_address_first;
wire [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rs2_address_second;
wire [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rd_address_first;
wire [VIR_REG_ADDR_WIDTH-1:0] dec2rcu_rd_address_second;
wire [CSR_ADDR_LEN-1:0] dec2rcu_csr_address_first;
wire [CSR_ADDR_LEN-1:0] dec2rcu_csr_address_second;
wire dec2rcu_mret_first;
wire dec2rcu_mret_second;
wire dec2rcu_sret_first;
wire dec2rcu_sret_second;
wire dec2rcu_wfi_first;
wire dec2rcu_wfi_second;
wire [EXCEPTION_CAUSE_WIDTH-1:0] dec2rcu_ecause_first;
wire [EXCEPTION_CAUSE_WIDTH-1:0] dec2rcu_ecause_second;
wire dec2rcu_exception_first;
wire dec2rcu_exception_second;
wire dec2rcu_half_first;
wire dec2rcu_half_second;
wire dec2rcu_is_fence_first;
wire dec2rcu_is_fence_second;
wire [1:0] dec2rcu_fence_op_first;
wire [1:0] dec2rcu_fence_op_second;
wire dec2rcu_is_aext_first;
wire dec2rcu_is_aext_second;
wire dec2rcu_is_mext_first;
wire dec2rcu_is_mext_second;
wire dec2rcu_req_valid_first;
wire dec2rcu_req_valid_second;
wire dec2rcu_csr_read_first;
wire dec2rcu_csr_read_second;
wire dec2rcu_csr_write_first;
wire dec2rcu_csr_write_second;
wire [31:0] dec2rcu_imm_data_first;
wire [31:0] dec2rcu_imm_data_second;
wire [2:0] dec2rcu_fu_funtion_first;
wire [2:0] dec2rcu_fu_function_second;
wire dec2rcu_alu_function_modifier_first;
wire dec2rcu_alu_function_modifier_second;
wire [1:0] dec2rcu_fu_select_a_first;
wire [1:0] dec2rcu_fu_select_a_second;
wire [1:0] dec2rcu_fu_select_b_first;
wire [1:0] dec2rcu_fu_select_b_second;
wire dec2rcu_jump_first;
wire dec2rcu_jump_second;
wire dec2rcu_branch_first;
wire dec2rcu_branch_second;
wire dec2rcu_is_alu_first;
wire dec2rcu_is_alu_second;
wire dec2rcu_load_first;
wire dec2rcu_load_second;
wire dec2rcu_store_first;
wire dec2rcu_store_second;
wire [LDU_OP_WIDTH-1:0] dec2rcu_ldu_op_first;
wire [LDU_OP_WIDTH-1:0] dec2rcu_ldu_op_second;
wire [STU_OP_WIDTH-1:0] dec2rcu_stu_op_first;
wire [STU_OP_WIDTH-1:0] dec2rcu_stu_op_second;
wire dec2rcu_aq_first;
wire dec2rcu_aq_second;
wire dec2rcu_rl_first;
wire dec2rcu_rl_second;

wire [1:0] csr2decode_priv_mode                         ;
wire [1:0] csr2mmu_priv_mode                         ;   
wire global_trap                                         ;
wire global_ret                                          ;
wire global_mret                                           ;
wire global_sret                                           ;
wire dec2rcu_uses_rs2_second                                     ;
wire fu2rcu_alu1_resp_valid                                ;
wire fu2rcu_alu2_resp_valid                                ;
wire fu2rcu_md_wrb_resp_valid                                  ;
wire fu2rcu_lsu_done_valid                                   ;
wire fu2rcu_csr_resp_valid                                ;
wire [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_alu1_wrb_prd_addr     ; 
wire [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_csr_wrb_addr     ;
wire [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_alu2_wrb_prd_addr     ; 
wire [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_md_wrb_prd_addr       ;
wire fu2rcu_alu1_predict_miss                                   ;
wire fu2rcu_alu1_branch_taken                                   ;
wire [PC_WIDTH-1:0] fu2rcu_alu1_final_branch_pc                                ;
wire fu2rcu_alu2_predict_miss                                   ;
wire fu2rcu_alu2_branch_taken                                   ;
wire [PC_WIDTH-1:0] fu2rcu_alu2_final_branch_pc                                ;
wire [ROB_INDEX_WIDTH-1:0] fu2rcu_alu1_wrb_rob_index           ; 
wire [ROB_INDEX_WIDTH-1:0] fu2rcu_alu2_wrb_rob_index           ;
wire [ROB_INDEX_WIDTH-1:0] fu2rcu_md_wrb_rob_index             ;
wire [ROB_INDEX_WIDTH-1:0] fu2rcu_csr_wrb_rob_index           ;
wire [XLEN-1:0] fu2rcu_alu1_wrb_data                   ; 
wire [XLEN-1:0] fu2rcu_csr_wrb_data                   ; 
wire [XLEN-1:0] fu2rcu_alu2_wrb_data                   ; 
wire [XLEN-1:0] fu2rcu_lsu_comm_data                      ;
wire [XLEN-1:0] fu2rcu_md_wrb_data                     ;
reg  func_wrb_alu1_exp_i                                   ;
reg  func_wrb_alu2_exp_i                                   ;
reg  func_wrb_md_exp_i                                     ;
wire fu2rcu_csr_exception                                   ;
reg  [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_alu1_ecause_i    ;
reg  [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_alu2_ecause_i    ;
reg  [EXCEPTION_CAUSE_WIDTH-1:0] func_wrb_md_ecause_i      ;
wire [EXCEPTION_CAUSE_WIDTH-1:0] fu2rcu_csr_ecause    ;
wire rcu2fu_alu1_req_valid                                  ;
wire rcu2fu_alu2_req_valid                                  ;
wire rcu2fu_md_req_ready                                    ;
wire rcu2fu_md_req_valid                                    ;
wire rcu2fu_csru_req_valid                                   ;
wire [ROB_INDEX_WIDTH-1:0] rcu2fu_alu1_rob_index            ;
wire [PHY_REG_ADDR_WIDTH-1:0] rcu2fu_alu1_prd_addr       ;
wire [2:0] rcu2fu_alu1_func3                                ;
wire [PC_WIDTH-1:0] rcu2fu_alu1_pc                          ;
wire [PC_WIDTH-1:0] rcu2fu_alu1_next_pc                     ;
wire [PC_WIDTH-1:0] rcu2fu_alu1_predict_pc                  ;
wire [IMM_LEN-1:0] rcu2fu_alu1_imm_data                     ;
wire [1:0] rcu2fu_alu1_opr1_sel                             ;
wire [1:0] rcu2fu_alu1_opr2_sel                             ;
wire [XLEN-1:0] rcu2fu_alu1_rs1_data                        ;
wire [XLEN-1:0] rcu2fu_alu1_rs2_data                        ;
wire  rcu2fu_alu1_is_jump                                      ;
wire  rcu2fu_alu1_is_branch                                    ;
wire  rcu2fu_alu1_half                                      ;
wire  rcu2fu_alu1_func_modifier                             ;
wire [ROB_INDEX_WIDTH-1:0] rcu2fu_alu2_rob_index            ;
wire [PHY_REG_ADDR_WIDTH-1:0] rcu2fu_alu2_prd_addr          ;
wire [2:0] rcu2fu_alu2_func3                                ;
wire [PC_WIDTH-1:0] rcu2fu_alu2_pc                          ;
wire [PC_WIDTH-1:0] rcu2fu_alu2_next_pc                     ;
wire [PC_WIDTH-1:0] rcu2fu_alu2_predict_pc                  ;
wire [IMM_LEN-1:0] rcu2fu_alu2_imm_data                     ;
wire [1:0] rcu2fu_alu2_opr1_sel                             ;
wire [1:0] rcu2fu_alu2_opr2_sel                             ;
wire [XLEN-1:0] rcu2fu_alu2_rs1_data                        ;
wire [XLEN-1:0] rcu2fu_alu2_rs2_data                        ;
wire  rcu2fu_alu2_is_jump                                      ;
wire  rcu2fu_alu2_is_branch                                    ;
wire  rcu2fu_alu2_half                                      ;
wire  rcu2fu_alu2_func_modifier                             ;
wire [MD_DATA_WIDTH-1:0] rcu2fu_md_package                  ;
wire [LSU_DATA_WIDTH-1:0] rcu2fu_lsu_package                ;
wire [ROB_INDEX_WIDTH-1:0] rcu2fu_csru_rob_index             ;
wire [PHY_REG_ADDR_WIDTH-1:0] rcu2fu_csru_prd_addr        ;
wire [2:0] rcu2fu_csru_func3                                 ;
wire [XLEN-1:0] rcu2fu_csru_prs1_data                         ;
wire [IMM_LEN-1:0] rcu2fu_csru_imm                      ;
wire [CSR_ADDR_LEN-1:0] rcu2fu_csru_addr                  ;
wire rcu2fu_csru_do_read                                     ;
wire rcu2fu_csru_do_write                                    ;
wire rcu2ft_bpu_cmt_is_branch_first                               ;
wire rcu2ft_bpu_cmt_is_branch_second                         ;
wire rcu2ft_bpu_cmt_branch_taken_first                      ;
wire rcu2ft_bpu_cmt_branch_taken_second                      ;
wire [PC_WIDTH-1:0] rcu2ft_bpu_cmt_final_pc                  ;
wire [PC_WIDTH-1:0] rcu_bpu_cmt_final_pc_second_o           ;
wire [PC_WIDTH-1:0] rcu2ft_bpu_cmt_pc_first                 ;
wire [PC_WIDTH-1:0] rcu2ft_bpu_cmt_pc_second                 ;
wire [PC_WIDTH-1:0] rcu2ft_bpu_alu_result_pc                 ;
wire rcu_do_rob_commit_first                             ;
wire rcu_do_rob_commit_second                            ;
wire [PC_WIDTH-1:0] rcu2exp_cmt_pc                           ;
wire rcu2excp_predict_miss                                        ;
wire rcu2excp_cmt_exception                                   ;
wire [EXCEPTION_CAUSE_WIDTH-1:0] rcu2excp_cmt_ecause          ;
wire rcu2excp_cmt_is_mret                                       ;
wire rcu2excp_cmt_is_sret                                       ;
wire rcu2excp_cmt_is_wfi                                        ;
wire global_predict_miss                                   ;

`ifdef REG_TEST
wire [5:0] rcu2prf_test_prd_first                 ;
wire [5:0] rcu2prf_test_prd_second                ;
wire [XLEN-1:0] rcu2prf_test_rdata_first               ;
wire [XLEN-1:0] rcu2prf_test_rdata_second              ;
`endif

wire [PHY_REG_ADDR_WIDTH-1:0]            rcu2prf_preg_prs1_address_first        ;
wire [PHY_REG_ADDR_WIDTH-1:0]            rcu2prf_preg_prs2_address_first        ;
wire [PHY_REG_ADDR_WIDTH-1:0]            rcu2prf_preg_prs1_address_second       ;
wire [PHY_REG_ADDR_WIDTH-1:0]            rcu2prf_preg_prs2_address_second       ;
wire [XLEN-1:0]                          prf2rcu_phyreg_first_rs1_data         ;
wire [XLEN-1:0]                          prf2rcu_phyreg_first_rs2_data          ;
wire [XLEN-1:0]                          prf2rcu_phyreg_second_rs1_data         ;
wire [XLEN-1:0]                          prf2rcu_phyreg_second_rs2_data         ;
wire [PHY_REG_ADDR_WIDTH-1:0]            rcu2prf_physical_alu1_csr_wrb_addr     ;
wire [XLEN-1:0]                          rcu2prf_physical_alu1_csr_wrb_data     ;
wire                                     rcu2prf_physical_alu1_csr_done_valid   ;

wire rcu2fu_lsu_req_valid        ;
wire fu2rcu_lsu_done_valid_fix    ;
wire fu2rcu_lsu_req_ready    ;
wire [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_lsu_comm_addr_fix         ;
wire [PHY_REG_ADDR_WIDTH-1:0] fu2rcu_lsu_wrb_addr         ;
wire [XLEN-1:0] lsu2rcu_wrb_data         ;
wire [ROB_INDEX_WIDTH-1:0] lsu2rcu_rob_index        ;

wire [ROB_INDEX_WIDTH-1:0] lsu_rob_index      ;
wire [PHY_REG_ADDR_WIDTH-1:0] lsu_prd_address    ;
wire [XLEN-1:0] lsu_rs1_data       ;
wire [XLEN-1:0] lsu_rs2_data       ;
wire [IMM_LEN-1:0] lsu_imm            ;
wire lsu_is_load        ;
wire lsu_is_store       ;
wire [LDU_OP_WIDTH-1:0] rcu2fu_lsu_ld_opcode      ;
wire [STU_OP_WIDTH-1:0] rcu2fu_lsu_st_opcode      ;
wire [1:0] lsu_lsu_fence_op   ;
wire lsu_aext           ;


//LSU
wire                                          rcu2fu_lsu_ls;     
wire                                          rcu2fu_lsu_fenced;
wire [XLEN - 1 : 0]                           rcu2fu_agu_virt_base;
wire [IMM_LEN - 1 : 0]                        lsu_imm;
wire [XLEN-1:0]                               rcu2fu_agu_virt_offset;
wire [ROB_INDEX_WIDTH - 1 : 0]                rcu2fu_lsu_rob_index;
wire [PHY_REG_ADDR_WIDTH - 1 : 0]             rcu2fu_lsu_rd_addr;
wire [XLEN - 1 : 0]                           rcu2fu_lsu_data;
wire                                          rcu2fu_lsu_wakeup;
wire [ROB_INDEX_WIDTH - 1 : 0]                rcu2fu_lsu_wakeup_rob_index;       
wire [ROB_INDEX_WIDTH - 1 : 0]                fu2rcu_lsu_comm_rob_index_fix;
wire                                          fu2rcu_lsu_exception_vld;
wire [EXCEPTION_CAUSE_WIDTH - 1 : 0]          fu2rcu_lsu_ecause;

// pmp
wire                                           fu2pmp_csru_cfg_vld;
wire  [PMPCFG_ID_WIDTH-1:0]                    fu2pmp_csru_cfg_addr;
wire  [XLEN-1:0]                               fu2pmp_csru_cfg_payload;
wire  [XLEN-1:0]                               pmp2fu_csru_cfg_origin_payload;
wire                                           fu2pmp_csru_addr_vld;
wire  [PMPADDR_ID_WIDTH-1:0]                   fu2pmp_csru_addr_addr;
wire  [XLEN-1:0]                               fu2pmp_csru_addr_payload;
wire  [XLEN-1:0]                               pmp2fu_csru_addr_origin_payload;

// mmu
wire lsu_dtlb_flush_vld;
wire lsu_dtlb_flush_use_asid;
wire lsu_dtlb_flush_use_vpn;
wire [VPN_WIDTH-1:0]  lsu_dtlb_flush_vpn;
wire [ASID_WIDTH-1:0] lsu_dtlb_flush_asid;
wire dtlb_lsu_flush_grant;
wire lsu_itlb_flush_vld;
wire lsu_itlb_flush_use_asid;
wire lsu_itlb_flush_use_vpn;
wire [VPN_WIDTH-1:0]  lsu_itlb_flush_vpn;
wire [ASID_WIDTH-1:0] lsu_itlb_flush_asid;
wire itlb_lsu_flush_grant;
wire tlb_flush_grant_o;
//
    // <> d$
    // Load request
    // wb

wire fu2csr_csru_do_write;
wire [CSR_ADDR_LEN-1:0] fu2csr_csru_waddr;
wire [CSR_ADDR_LEN-1:0] fu2csr_csru_raddr;
//`endif //LSU_DOING

//With CSR
wire  [XLEN-1:0]                                csr2fu_csru_rdata;
wire                                            csr2fu_csru_readable;
wire                                            csr2fu_csru_writeable;
wire                                            csr2excp_interrupt;

wire [XLEN-1:0]                               fu2csr_csru_wrdata;

// fetch: exception ctrl
wire [PC_WIDTH-1:0] csr2fetch_trap_vector;   //todo
// fetch: fetch<>I$
wire ins_empty_o;

//exception contol
wire [PC_WIDTH-1:0] excp2csr_pc;
wire [EXCEPTION_CAUSE_WIDTH-1:0] excp2csr_ecause;

wire csr2decode_tsr;
wire csr2decode_tvm;
wire csr2decode_tw;

wire [XLEN-1 : 0] csr2mmu_mstatus;
wire [XLEN-1 : 0] csr2mmu_satp;

wire                                           dtlb2fu_lsu_exception_vld;
wire [EXCEPTION_CAUSE_WIDTH - 1 : 0]           dtlb2fu_lsu_ecause;
wire  [2*PMP_ACCESS_TYPE_WIDTH - 1 : 0]          fu2dtlb_lsu_iss_type;
wire                                           dtlb2fu_lsu_rdy;
wire                                           dtlb2fu_lsu_vld; // should be the lsu_dtlb_iss_vld_o in last cycle
wire                                           dtlb2fu_lsu_hit;
wire                                           dtlb2fu_lsu_miss;
wire [PHYSICAL_ADDR_TAG_LEN - 1 : 0]           dtlb2fu_lsu_ptag;
wire                                           fu2dtlb_lsu_iss_vld;
wire  [VIRTUAL_ADDR_TAG_LEN - 1 : 0]           fu2dtlb_lsu_iss_vtag;


wire [TRANSLATE_WIDTH-1:0] dtlb_translate_resp_miss;

wire                                                   ft2itlb_req_vld;
wire [L1I_TAG_WIDTH-1:0]                               ft2itlb_if_req_vtag;
wire                                                   ft2itlb_if_req_rdy;
wire                                                   itlb2ft_if_resp_vld;
wire [TRANSLATE_WIDTH*PPN_WIDTH-1:0] itlb2icache_ic_ptag;


wire [TRANSLATE_WIDTH-1:0] itlb2ft_resp_excp_vld;            //to-do
wire [TRANSLATE_WIDTH*EXCP_CAUSE_WIDTH-1:0] itlb2ft_resp_excp_cause;    //to-do
wire [TRANSLATE_WIDTH-1:0] itlb_translate_resp_miss_o;        //fetch & cache
wire [TRANSLATE_WIDTH-1:0] itlb_translate_resp_hit_o;

wire itlb_translate_resp_miss_w;
wire itlb_translate_resp_hit_w;

wire branch_valid_first_w, branch_valid_second_w;

// omit fetch <> itlb for test simplicity
// fetch <> itlb can be restored through uncommenting related code in fetch.v
fetch fetch_u(
    .clk(clk),
    .rst(rst),
    .branch_valid_first_i(branch_valid_first_w),
    .branch_valid_second_i(branch_valid_first_w),
    .btb_req_pc_i(rcu2ft_bpu_cmt_pc_first),         //todo
    .btb_predict_target_i(rcu2ft_bpu_alu_result_pc),            
    .prev_pc_first_i(rcu2ft_bpu_cmt_pc_first),          //todo
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
    .fetch_l1i_if_req_vtag_o(ft2itlb_if_req_vtag),
    .itlb_fetch_miss_i(itlb2ft_miss),
    .itlb_fetch_hit_i(itlb2ft_hit),
    .fetch_itlb_req_vld_o(ft2itlb_req_vld),
    .ins_empty_o(ins_empty_o),                  //not used
    .itlb_fetch_resp_excp_vld_i(itlb2ft_resp_excp_vld),
    .itlb_fetch_resp_ecause_i(itlb2ft_resp_excp_cause),
    .exception_valid_first_o(ft2dec_excp_first),
    .ecause_first_o(ft2dec_ecause_first),
    .exception_valid_second_o(ft2dec_excp_second),
    .ecause_second_o(ft2dec_ecause_second)
);  //end fetch

routing routing_u(
    .rcu_do_rob_commit_first(rcu_do_rob_commit_first),
    .rcu2ft_bpu_cmt_is_branch_first(rcu2ft_bpu_cmt_is_branch_first),
    .rcu_do_rob_commit_second(rcu_do_rob_commit_second),
    .rcu2ft_bpu_cmt_is_branch_second(rcu2ft_bpu_cmt_is_branch_second),
    .branch_valid_first_w(branch_valid_first_w),
    .branch_valid_second_w(branch_valid_second_w),
    .lsu_imm(lsu_imm),
    .rcu2fu_lsu_fenced(rcu2fu_lsu_fenced),
    .rcu2fu_lsu_aq(rcu2fu_lsu_aq),
    .rcu2fu_lsu_rl(rcu2fu_lsu_rl),
    .rcu2fu_lsu_fenced_final(rcu2fu_lsu_fenced_final),
    .rcu2fu_agu_virt_offset(rcu2fu_agu_virt_offset),
    .func_wrb_alu2_exp_i(func_wrb_alu2_exp_i),
    .func_wrb_alu2_ecause_i(func_wrb_alu2_ecause_i),
    .func_wrb_alu1_exp_i(func_wrb_alu1_exp_i),
    .func_wrb_alu1_ecause_i(func_wrb_alu1_ecause_i),
    .func_wrb_md_exp_i(func_wrb_md_exp_i),
    .func_wrb_md_ecause_i(func_wrb_md_ecause_i)
);

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
    .tsr_i(csr2decode_tsr),
    .tvm_i(csr2decode_tvm),
    .tw_i(csr2decode_tw),
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

assign fu2rcu_lsu_comm_rob_index_fix = lsu2rcu_rob_index;
physical_regfile #(
    .REG_SIZE(PHY_REG_SIZE),
    .REG_SIZE_WIDTH(PHY_REG_ADDR_WIDTH)
)physical_regfile_u(
    .clk                      (clk)                            ,
    .rst                      (rst)                             ,

    `ifdef REG_TEST
    .test_prd_first_i         (rcu2prf_test_prd_first)                 ,
    .test_prd_second_i        (rcu2prf_test_prd_second)                ,
    .test_rdata_first_o       (rcu2prf_test_rdata_first )              ,
    .test_rdata_second_o      (rcu2prf_test_rdata_second)              ,
    `endif
    .prs1_address_first_i     (rcu2prf_preg_prs1_address_first)        ,
    .prs2_address_first_i     (rcu2prf_preg_prs2_address_first)        ,
    .prs1_address_second_i    (rcu2prf_preg_prs1_address_second)       ,
    .prs2_address_second_i    (rcu2prf_preg_prs2_address_second)       ,

    .prs1_data_first_o        (prf2rcu_phyreg_first_rs1_data)          ,
    .prs2_data_first_o        (prf2rcu_phyreg_first_rs2_data)          ,
    .prs1_data_second_o       (prf2rcu_phyreg_second_rs1_data)         ,
    .prs2_data_second_o       (prf2rcu_phyreg_second_rs2_data)         ,

    .alu1_wrb_address_i       (rcu2prf_physical_alu1_csr_wrb_addr)     ,
    .alu2_wrb_address_i       (fu2rcu_alu2_wrb_prd_addr)       ,
    .lsu_wrb_address_i        (fu2rcu_lsu_wrb_addr)        ,
    .md_wrb_address_i         (fu2rcu_md_wrb_prd_addr)         ,
    .alu1_wrb_data_i          (rcu2prf_physical_alu1_csr_wrb_data)     ,
    .alu2_wrb_data_i          (fu2rcu_alu2_wrb_data)       ,
    .lsu_wrb_data_i           (fu2rcu_lsu_comm_data)        ,
    .md_wrb_data_i            (fu2rcu_md_wrb_data)         ,
    .alu1_rcu_resp_valid_i    (rcu2prf_physical_alu1_csr_done_valid)   ,
    .alu2_rcu_resp_valid_i    (fu2rcu_alu2_resp_valid)     ,
    .lsu_rcu_resp_valid_i     (fu2rcu_lsu_done_valid)      ,
    .md_rcu_resp_valid_i      (fu2rcu_md_wrb_resp_valid)                           
);

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
    .physical_lsu_wrb_data_i(fu2rcu_lsu_comm_data), 
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
    .rcu_lsu_wakeup_index_o(rcu2fu_lsu_wakeup_rob_index),
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
    .rcu_cmt_is_wfi(rcu2excp_cmt_is_wfi),
    `ifdef REG_TEST
    .rcu_prf_test_prd_first_o(rcu2prf_test_prd_first)                 ,
    .rcu_prf_test_prd_second_o(rcu2prf_test_prd_second)                ,
    `endif
    .rcu_prf_preg_prs1_address_first_o(rcu2prf_preg_prs1_address_first)        ,
    .rcu_prf_preg_prs2_address_first_o(rcu2prf_preg_prs2_address_first)        ,
    .rcu_prf_preg_prs1_address_second_o(rcu2prf_preg_prs1_address_second)       ,
    .rcu_prf_preg_prs2_address_second_o(rcu2prf_preg_prs2_address_second)       ,
    .prf_rcu_phyreg_first_rs1_data_i(prf2rcu_phyreg_first_rs1_data)         ,
    .prf_rcu_phyreg_first_rs2_data_i(prf2rcu_phyreg_first_rs2_data)          ,
    .prf_rcu_phyreg_second_rs1_data_i(prf2rcu_phyreg_second_rs1_data)         ,
    .prf_rcu_phyreg_second_rs2_data_i(prf2rcu_phyreg_second_rs2_data)         ,
    .rcu_prf_physical_alu1_csr_wrb_addr_o(rcu2prf_physical_alu1_csr_wrb_addr)     ,
    .rcu_prf_physical_alu1_csr_wrb_data_o(rcu2prf_physical_alu1_csr_wrb_data)     ,
    .rcu_prf_physical_alu1_csr_done_valid_o(rcu2prf_physical_alu1_csr_done_valid)   
);          //end rcu
assign  {rcu2fu_lsu_rob_index     , 
        rcu2fu_lsu_rd_addr    , 
        rcu2fu_agu_virt_base      , // rs1_data
        rcu2fu_lsu_data, 
        lsu_imm           , //imm
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


assign rcu2fu_lsu_ls = lsu_is_store;

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
    .fu_rcu_lsu_comm_vld_o(fu2rcu_lsu_done_valid),
    .fu_rcu_lsu_comm_rob_index_o(lsu2rcu_rob_index),
    .fu_rcu_lsu_comm_rd_addr_o(fu2rcu_lsu_wrb_addr),
    .fu_rcu_lsu_comm_data_o(fu2rcu_lsu_comm_data),
    .fu_rcu_lsu_exception_vld_o(fu2rcu_lsu_exception_vld),
    .fu_rcu_lsu_ecause_o(fu2rcu_lsu_ecause),

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

    .lsu_l1d_fencei_flush_vld_o(lsu_l1d_fencei_flush_vld_o),
    .l1d_lsu_fencei_flush_grant_i(l1d_lsu_fencei_flush_grant_i),

    .lsu_l1i_fencei_flush_vld_o(lsu_l1i_fencei_flush_vld_o),
    .l1i_lsu_fencei_flush_grant_i(l1i_lsu_fencei_flush_grant_i),

    .lsu_dtlb_flush_vld_o(lsu_dtlb_flush_vld),
    .lsu_dtlb_flush_use_asid_o(lsu_dtlb_flush_use_asid),
    .lsu_dtlb_flush_use_vpn_o(lsu_dtlb_flush_use_vpn),
    .lsu_dtlb_flush_vpn_o(lsu_dtlb_flush_vpn),
    .lsu_dtlb_flush_asid_o(lsu_dtlb_flush_asid),
    .dtlb_lsu_flush_grant_i(dtlb_lsu_flush_grant),

    .lsu_itlb_flush_vld_o(lsu_itlb_flush_vld),
    .lsu_itlb_flush_use_asid_o(lsu_itlb_flush_use_asid),
    .lsu_itlb_flush_use_vpn_o(lsu_itlb_flush_use_vpn),
    .lsu_itlb_flush_vpn_o(lsu_itlb_flush_vpn),
    .lsu_itlb_flush_asid_o(lsu_itlb_flush_asid),
    .itlb_lsu_flush_grant_i(itlb_lsu_flush_grant),    

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
    .csr_fu_csru_writable_i(csr2fu_csru_writeable),
    
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
`ifdef DPRAM64_2R1W
    .we(we),
    .din(din),
    .waddr(waddr),
    .raddr_d(raddr_d),
    .re_d(re_d),
    .runsigned_d(runsigned_d),  
    .wrob_index_d(wrob_index_d),
    .wrd_addr_d(wrd_addr_d),                   
    .rrob_index_d(rrob_index_d),
    .rrd_addr_d(rrd_addr_d),
`endif // DPRAM64_2R1W
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
    
    .do_rob_commit_first(rcu_do_rob_commit_first),
    .do_rob_commit_second(rcu_do_rob_commit_second),

    .csr_w_i(fu2csr_csru_do_write),
    .csr_addr_w_i(fu2csr_csru_waddr),
    .csr_addr_r_i(fu2csr_csru_raddr),
    .csr_data_w_i(fu2csr_csru_wrdata),

//  from exception ctrl
    .excp_pending_i(global_trap),
    .excp_cause_i(excp2csr_ecause),
    .excp_pc_i(excp2csr_pc),

    .m_ret_i(global_mret),
    .s_ret_i(global_sret),

// to csru
    .csr_data_r_o(csr2fu_csru_rdata),
    .readable_o(csr2fu_csru_readable),
    .writeable_o(csr2fu_csru_writeable),
// to fetch
    .excp_pc_o(csr2fetch_trap_vector),
// to decode
    .current_mode_o(csr2decode_priv_mode),
    .tsr_o(csr2decode_tsr),
    .tvm_o(csr2decode_tvm),
    .tw_o(csr2decode_tw),

    .mstatus_o(csr2mmu_mstatus),
    .satp_o(csr2mmu_satp),

    .interrupt_o(csr2excp_interrupt)
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
    
    .interrupt_i(csr2excp_interrupt),

    .global_trap_o(global_trap),
    .global_predict_miss_o(global_predict_miss),
    .global_ret_o(global_ret),

    .csr_pc_o(excp2csr_pc),
    .csr_ecause_o(excp2csr_ecause),
    
    .global_mret_o(global_mret),
    .global_sret_o(global_sret),
    .global_wfi_o(global_wfi)
);

rvh_monolithic_mmu mmu(
    .clk(clk),
    .rstn(~rst),

    .priv_lvl_i(csr2mmu_priv_mode),
 
    .satp_mode_i(csr2mmu_satp[63:60]),
    .satp_asid_i(csr2mmu_satp[59:44]),
    .satp_ppn_i(csr2mmu_satp[43:0]),

    .misc_mstatus_i(csr2mmu_mstatus),

    .pmp_cfg_set_vld_i(fu2pmp_csru_cfg_vld),
    .pmp_cfg_set_addr_i(fu2pmp_csru_cfg_addr),
    .pmp_cfg_set_payload_i(fu2pmp_csru_cfg_payload),
    .pmp_cfg_origin_payload_o(pmp2fu_csru_cfg_origin_payload),
    .pmp_addr_set_vld_i(fu2pmp_csru_addr_vld),
    .pmp_addr_set_addr_i(fu2pmp_csru_addr_addr),
    .pmp_addr_set_payload_i(fu2pmp_csru_addr_payload),
    .pmp_addr_origin_payload_o(pmp2fu_csru_addr_origin_payload), 

    .dtlb_translate_req_vld_i(fu2dtlb_lsu_iss_vld),                    
    .dtlb_translate_req_access_type_i(fu2dtlb_lsu_iss_type),           
    .dtlb_translate_req_vpn_i(fu2dtlb_lsu_iss_vtag),                   
    .dtlb_translate_req_rdy_o(dtlb2fu_lsu_rdy),                        
    // DTLB Translate Port -> Response
    .dtlb_translate_resp_vld_o(dtlb2fu_lsu_vld),                       
    .dtlb_translate_resp_ppn_o(dtlb2fu_lsu_ptag),                      
    .dtlb_translate_resp_excp_vld_o(dtlb2fu_lsu_exception_vld),        
    .dtlb_translate_resp_excp_cause_o(dtlb2fu_lsu_ecause),             
    .dtlb_translate_resp_miss_o(dtlb2fu_lsu_miss),          // no use   
    .dtlb_translate_resp_hit_o(dtlb2fu_lsu_hit),                       

    .itlb_translate_req_vld_i(ft2itlb_req_vld),
    .itlb_translate_req_vpn_i(ft2itlb_if_req_vtag),                       
    .itlb_translate_req_rdy_o(ft2itlb_if_req_rdy),                        
    // ITLB Translate Port -> Response
    .itlb_translate_resp_vld_o(itlb2ft_if_resp_vld),               // to cache?        
    .itlb_translate_resp_ppn_o(itlb2icache_ic_ptag),    
    .itlb_translate_resp_excp_vld_o(itlb2ft_resp_excp_vld),              
    .itlb_translate_resp_excp_cause_o(itlb2ft_resp_excp_cause),          
    .itlb_translate_resp_miss_o(itlb_translate_resp_miss_w),             
    .itlb_translate_resp_hit_o(itlb_translate_resp_hit_w),          

    // dtlb shoot down
    .dtlb_flush_vld_i(lsu_dtlb_flush_vld),
    .dtlb_flush_use_asid_i(lsu_dtlb_flush_use_asid),
    .dtlb_flush_use_vpn_i(lsu_dtlb_flush_use_vpn),
    .dtlb_flush_vpn_i(lsu_dtlb_flush_vpn),
    .dtlb_flush_asid_i(lsu_dtlb_flush_asid),
    .dtlb_flush_grant_o(dtlb_lsu_flush_grant),
        // itlb shoot down
    .itlb_flush_vld_i(lsu_itlb_flush_vld),
    .itlb_flush_use_asid_i(lsu_itlb_flush_use_asid),
    .itlb_flush_use_vpn_i(lsu_itlb_flush_use_vpn),
    .itlb_flush_vpn_i(lsu_itlb_flush_vpn),
    .itlb_flush_asid_i(lsu_itlb_flush_asid),
    .itlb_flush_grant_o(itlb_lsu_flush_grant),

    .tlb_flush_grant_o(tlb_flush_grant_o),


        // ptw walk request port
    .ptw_walk_req_vld_o(mmu2cache_ptw_walk_req_vld_o),
    .ptw_walk_req_id_o(mmu2cache_ptw_walk_req_id_o),
    .ptw_walk_req_addr_o(mmu2cache_ptw_walk_req_addr_o),
    .ptw_walk_req_rdy_i(mmu2cache_ptw_walk_req_rdy_i),
        // ptw walk response port
    .ptw_walk_resp_vld_i(mmu2cache_ptw_walk_resp_vld_i),
    .ptw_walk_resp_pte_i(mmu2cache_ptw_walk_resp_pte_i),
    .ptw_walk_resp_rdy_o(mmu2cache_ptw_walk_resp_rdy_o)
);
// to dcache
assign dtlb2dcache_lsu_vld_o            = dtlb2fu_lsu_vld;
assign dtlb2dcache_lsu_ptag_o           = dtlb2fu_lsu_ptag;
assign dtlb2dcache_lsu_exception_vld_o  = dtlb2fu_lsu_exception_vld;
assign dtlb2dcache_lsu_miss_o           = dtlb2fu_lsu_miss;
assign dtlb2dcache_lsu_hit_o            = dtlb2fu_lsu_hit;
// to icache
assign itlb2ic_if_resp_vld_o            = itlb2ft_if_resp_vld        ;
assign itlb2icache_ic_ptag_o            = itlb2icache_ic_ptag        ;
assign itlb2ft_resp_excp_vld_o          = itlb2ft_resp_excp_vld      ;
assign itlb_translate_resp_miss_o       = itlb_translate_resp_miss_w ;
assign itlb_translate_resp_hit_o        = itlb_translate_resp_hit_w  ;

assign csr2mmu_priv_mode = csr2decode_priv_mode;
assign itlb2ft_miss = itlb_translate_resp_miss_w;
assign itlb2icache_miss_o = itlb_translate_resp_miss_w;
assign itlb2ft_hit = itlb_translate_resp_hit_w;
assign itlb2icache_hit_o = itlb_translate_resp_hit_w;

endmodule : core_top

