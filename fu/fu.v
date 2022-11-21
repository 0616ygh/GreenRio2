`ifndef FU_V
`define FU_V
`ifdef VERILATOR
`include "params.vh"
`endif
module fu #(
    parameter LSQ_ENTRY_NUM = 8,
    parameter LSQ_ENTRY_NUM_WIDTH = 3
)(

    // global
    input clk,
    input rstn,
    input wfi,
    input global_trap,
    input global_ret,
    input global_predict_miss,
    // ALU from RCU

    input [XLEN - 1 : 0]                                                                            rcu_fu_alu1_rs1_i,
    input [XLEN - 1 : 0]                                                                            rcu_fu_alu2_rs1_i,
    input [XLEN - 1 : 0]                                                                            rcu_fu_alu1_rs2_i,
    input [XLEN - 1 : 0]                                                                            rcu_fu_alu2_rs2_i,
    input [IMM_LEN - 1 : 0]                                                                         rcu_fu_alu1_imm_data_i,               
    input [IMM_LEN - 1 : 0]                                                                         rcu_fu_alu2_imm_data_i,                        
    input [1 : 0]                                                                                   rcu_fu_alu1_opr1_sel_i,                
    input [1 : 0]                                                                                   rcu_fu_alu2_opr1_sel_i,                
    input [1 : 0]                                                                                   rcu_fu_alu1_opr2_sel_i,                
    input [1 : 0]                                                                                   rcu_fu_alu2_opr2_sel_i,             
                                                            
    input [ROB_INDEX_WIDTH - 1 : 0]                                                                 rcu_fu_alu1_rob_index_i,            
    input [ROB_INDEX_WIDTH - 1 : 0]                                                                 rcu_fu_alu2_rob_index_i,            
    input [PHY_REG_ADDR_WIDTH - 1 : 0]                                                              rcu_fu_alu1_prd_addr_i,             
    input [PHY_REG_ADDR_WIDTH - 1 : 0]                                                              rcu_fu_alu2_prd_addr_i,             
    input                                                                                           rcu_fu_alu1_is_branch_i, // if branch or jump, set 1
    input                                                                                           rcu_fu_alu2_is_branch_i, // if branch or jump, set 1
    input                                                                                           rcu_fu_alu1_is_jump_i, // if jump, set 1    
    input                                                                                           rcu_fu_alu2_is_jump_i, // if jump, set 1    
    input                                                                                           rcu_fu_alu1_req_valid_i,               
    input                                                                                           rcu_fu_alu2_req_valid_i,               
                                                            
    input                                                                                           rcu_fu_alu1_half_i,             
    input                                                                                           rcu_fu_alu2_half_i,             
    input [PC_WIDTH-1:0]                                                                            rcu_fu_alu1_pc_i,                   
    input [PC_WIDTH-1:0]                                                                            rcu_fu_alu2_pc_i,                   
    input [PC_WIDTH-1:0]                                                                            rcu_fu_alu1_next_pc_i, // for jal to wb  
    input [PC_WIDTH-1:0]                                                                            rcu_fu_alu2_next_pc_i, // for jal to wb  
    input [PC_WIDTH-1:0]                                                                            rcu_fu_alu1_predict_pc_i,
    input [PC_WIDTH-1:0]                                                                            rcu_fu_alu2_predict_pc_i,
    input [2:0]                                                                                     rcu_fu_alu1_func3_i,             //func3
    input [2:0]                                                                                     rcu_fu_alu2_func3_i,             //func3
    //input [2:0]                                                                                     rcu_fu_alu1_cmp_func_sel_i, 
    //input [2:0]                                                                                     rcu_fu_alu2_cmp_func_sel_i, 
    input                                                                                           rcu_fu_alu1_func_modifier_i,            
    input                                                                                           rcu_fu_alu2_func_modifier_i,            
    // alu to rcu                                                           
    output                                                                                          fu_rcu_alu1_resp_valid_o,  
    output                                                                                          fu_rcu_alu2_resp_valid_o,  
    output [ROB_INDEX_WIDTH-1:0]                                                                    fu_rcu_alu1_wrb_rob_index_o,
    output [ROB_INDEX_WIDTH-1:0]                                                                    fu_rcu_alu2_wrb_rob_index_o,
//    output                                                                                          fu_rcu_alu1_wrb_enable_o, 
//    output                                                                                          fu_rcu_alu2_wrb_enable_o, 
    output [PHY_REG_ADDR_WIDTH-1:0]                                                                 fu_rcu_alu1_wrb_prd_addr_o,
    output [PHY_REG_ADDR_WIDTH-1:0]                                                                 fu_rcu_alu2_wrb_prd_addr_o,
    output [XLEN - 1 : 0]                                                                           fu_rcu_alu1_wrb_data_o,
    output [XLEN - 1 : 0]                                                                           fu_rcu_alu2_wrb_data_o,
    output                                                                                          fu_rcu_alu1_branch_predict_miss_o,
    output                                                                                          fu_rcu_alu2_branch_predict_miss_o,
    output                                                                                          fu_rcu_alu1_branch_taken_o,
    output                                                                                          fu_rcu_alu2_branch_taken_o,
    output  [PC_WIDTH - 1 : 0]                                                                      fu_rcu_alu1_final_next_pc_o,
    output  [PC_WIDTH - 1 : 0]                                                                      fu_rcu_alu2_final_next_pc_o,
                                                            
    // Md from  rcu                                                         
//    input [PHY_REG_ADDR_WIDTH-1:0]                                                                  rcu_fu_md_prd_addr_i,      //  v 1
//    input [63:0]                                                                                    rcu_fu_md_oprd1_i, //  v 1
//    input [63:0]                                                                                    rcu_fu_md_oprd2_i, //  v 1
//    input [ROB_INDEX_WIDTH-1 : 0]                                                                   rcu_fu_md_rob_index_i,
//    input [2:0]                                                                                     rcu_fu_md_func_sel_i,    //  v 1
//    input                                                                                           ruc_fu_md_half_i,
    input  [MD_DATA_WIDTH - 1 : 0]                                                                  rcu_fu_md_package_i,
    input                                                                                           rcu_fu_md_req_valid_i,    //  v 1
    output                                                                                          rcu_fu_md_req_ready_o,    //  v 1
                                                            
    // md To rcu                                                            
    output [PHY_REG_ADDR_WIDTH-1:0]                                                                 fu_rcu_md_wrb_prd_addr_o,
    output [ROB_INDEX_WIDTH-1 : 0]                                                                  fu_rcu_md_wrb_rob_index_o,
    output [XLEN - 1:0]                                                                             fu_rcu_md_wrb_data_o,   //  v  1
    output                                                                                          fu_rcu_md_wrb_resp_valid_o,   //  v  2

//`ifdef LSU_DONE
    //LSU   
    output                                                                                          lsu_rdy_o,
//
    // <> RCU
    input                                                                                           rcu_fu_lsu_vld_i,
    input                                                                                           rcu_fu_lsu_ls_i,
    input  [LDU_OP_WIDTH - 1 : 0]                                                                   rcu_fu_lsu_ld_opcode_i,
    input  [STU_OP_WIDTH - 1 : 0]                                                                   rcu_fu_lsu_st_opcode_i,
    input                                                                                           rcu_fu_lsu_fenced_i,
    input  [XLEN - 1 : 0]                                                                           rcu_fu_agu_virt_base_i,
    input  [XLEN - 1 : 0]                                                                           rcu_fu_agu_virt_offset_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                                rcu_fu_lsu_rob_index_i,
    input  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                             rcu_fu_lsu_rd_addr_i,
    input  [XLEN - 1 : 0]                                                                           rcu_fu_lsu_data_i,
    input                                                                                           rcu_fu_lsu_wakeup_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                                rcu_fu_lsu_wakeup_rob_index_i,
    output                                                                                          fu_rcu_lsu_comm_vld_o,
    output [ROB_INDEX_WIDTH - 1 : 0]                                                                fu_rcu_lsu_comm_rob_index_o,
    output [PHY_REG_ADDR_WIDTH - 1 : 0]                                                             fu_rcu_lsu_comm_rd_addr_o,
    output [XLEN - 1 : 0]                                                                           fu_rcu_lsu_comm_data_o,
    output                                                                                          fu_rcu_lsu_exception_vld_o,
    output [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                          fu_rcu_lsu_ecause_o,
//                                             
//                                              
    // <> TLB                                               
    input                                                                                           dtlb_fu_lsu_rdy_i,
    input                                                                                           dtlb_fu_lsu_vld_i, // should be the lsu_dtlb_iss_vld_o in last cycle
    input                                                                                           dtlb_fu_lsu_hit_i,
    input  [PHYSICAL_ADDR_TAG_LEN - 1 : 0]                                                          dtlb_fu_lsu_ptag_i,
    input                                                                                           dtlb_fu_lsu_exception_vld_i,
    input  [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                          dtlb_fu_lsu_ecause_i,
    output                                                                                          fu_dtlb_lsu_iss_vld_o,
    output [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                                           fu_dtlb_lsu_iss_vtag_o,
    output [PMP_ACCESS_TYPE_WIDTH*2 - 1 : 0]                                                        fu_dtlb_lsu_iss_type_o,
//                                              
    // <> d$                                                
    // Load request                                             
    input                                                                                           l1d_fu_lsu_ld_req_rdy_i,
    output                                                                                          fu_l1d_lsu_ld_req_vld_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]                                                          fu_l1d_lsu_ld_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                        fu_l1d_lsu_ld_req_rd_addr_o, // no need
    output  [      LDU_OP_WIDTH - 1 : 0]                                                            fu_l1d_lsu_ld_req_opcode_o,
    output  [       ADDR_INDEX_LEN - 1 : 0]                                                         fu_l1d_lsu_ld_req_index_o, 
    output  [      ADDR_OFFSET_LEN - 1 : 0]                                                         fu_l1d_lsu_ld_req_offset_o, 
    output  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]                                                      fu_l1d_lsu_ld_req_vtag_o, 
    // Store request                                                
    input                                                                                           l1d_fu_lsu_st_req_rdy_i,
    output                                                                                          fu_l1d_lsu_st_req_vld_o,
    output                                                                                          fu_l1d_lsu_st_req_is_fence_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]                                                          fu_l1d_lsu_st_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                        fu_l1d_lsu_st_req_rd_addr_o,
    output  [      STU_OP_WIDTH - 1 : 0]                                                            fu_l1d_lsu_st_req_opcode_o,
    output  [       PHYSICAL_ADDR_LEN - 1 : 0]                                                      fu_l1d_lsu_st_req_paddr_o, 
    output  [              XLEN - 1 : 0]                                                            fu_l1d_lsu_st_req_data_o,
    // ld replay: 1. mshr full or 2. stb partial hit                                                 
    input                                                                                           l1d_fu_lsu_ld_replay_vld_i,
    // wb
    input  [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                      l1d_fu_lsu_wb_vld_i,
    input  [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                  l1d_fu_lsu_wb_rob_index_i,
    input  [LSU_DATA_PIPE_COUNT - 1 : 0]                                                            l1d_fu_lsu_prf_wb_vld_i,
    input  [PHY_REG_ADDR_WIDTH * LSU_DATA_PIPE_COUNT - 1 : 0]                                       l1d_fu_lsu_prf_wb_rd_addr_i,
    input  [XLEN*LSU_DATA_PIPE_COUNT - 1 : 0]                                                       l1d_fu_lsu_prf_wb_data_i,
    // kill                                                 
    output                                                                                          fu_l1d_lsu_kill_req_o,

    output                                                                                          lsu_l1d_fencei_flush_vld_o,
    input                                                                                           l1d_lsu_fencei_flush_grant_i,

    // <> l1i                                                   
    output                                                                                          lsu_l1i_fencei_flush_vld_o,
    input                                                                                           l1i_lsu_fencei_flush_grant_i,

    // <> mmu : flush dtlb/itlb
    // dtlb shoot down
    output                                                                                          lsu_dtlb_flush_vld_o,
    output                                                                                          lsu_dtlb_flush_use_asid_o,
    output                                                                                          lsu_dtlb_flush_use_vpn_o,
    output [VPN_WIDTH-1:0]                                                                          lsu_dtlb_flush_vpn_o,
    output [ASID_WIDTH-1:0]                                                                         lsu_dtlb_flush_asid_o,
    input                                                                                           dtlb_lsu_flush_grant_i,
    // itlb shoot down                                          
    output                                                                                          lsu_itlb_flush_vld_o,
    output                                                                                          lsu_itlb_flush_use_asid_o,
    output                                                                                          lsu_itlb_flush_use_vpn_o,
    output [VPN_WIDTH-1:0]                                                                          lsu_itlb_flush_vpn_o,
    output [ASID_WIDTH-1:0]                                                                         lsu_itlb_flush_asid_o,
    input                                                                                           itlb_lsu_flush_grant_i,
//
    // debug
//`ifdef NO_BUS
//    output                                          fu_debug_lsu_req_vld_o,
//    output                                          fu_debug_lsu_req_is_fence_o,
//    output  [     ROB_INDEX_WIDTH - 1 : 0]          fu_debug_lsu_req_rob_index_o,
//    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]        fu_debug_lsu_req_rd_addr_o,
//    output  [      STU_OP_WIDTH - 1 : 0]            fu_debug_lsu_req_opcode_o,
//    output  [       PHYSICAL_ADDR_LEN - 1 : 0]      fu_debug_lsu_req_paddr_o, 
//    output  [              XLEN - 1 : 0]            fu_debug_lsu_req_data_o,
//`endif // NO_BUS
    // <> Bus 
    output                                          fu_wb_lsu_cyc_o,
    output                                          fu_wb_lsu_stb_o,
    output                                          fu_wb_lsu_we_o,
    output [PHYSICAL_ADDR_LEN - 1 : 0]              fu_wb_lsu_adr_o,
    output [WB_DATA_LEN-1:0]                        fu_wb_lsu_dat_o,
    output [WB_DATA_LEN/8-1:0]                      fu_wb_lsu_sel_o,
    input                                           wb_fu_lsu_ack_i,
    input  [WB_DATA_LEN -1:0]                       wb_fu_lsu_dat_i,
//`endif //LSU_DOING
`ifdef DPRAM64_2R1W
    output wire [XLEN/8-1:0] 		                                                                    we,
    output wire [XLEN-1:0] 		                                                                        din,
    output wire [PHYSICAL_ADDR_LEN-1:0]                                                                 waddr,
    output wire [PHYSICAL_ADDR_LEN-1:0]                                                                 raddr_d,
    output wire [1:0]                                                                                   re_d,
    output                                                                                              runsigned_d,  
    output  [     ROB_INDEX_WIDTH - 1 : 0]                                                              wrob_index_d,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                            wrd_addr_d,                   
    output  [     ROB_INDEX_WIDTH - 1 : 0]                                                              rrob_index_d,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                            rrd_addr_d,                                   
`endif // DPRAM64_2R1W

    //from rcu
    input [ROB_INDEX_WIDTH-1:0]                     rcu_fu_csru_rob_index_i,
    input [PHY_REG_ADDR_WIDTH-1:0]                  rcu_fu_csru_prd_addr_i,
    input [2:0]                                     rcu_fu_csru_func3_i,
    input [XLEN-1:0]                                rcu_fu_csru_prs1_data_i,
    input [IMM_LEN-1:0]                             rcu_fu_csru_imm_i,
    input [CSR_ADDR_LEN-1:0]                        rcu_fu_csru_addr_i,
    input                                           rcu_fu_csru_do_read_i,
    input                                           rcu_fu_csru_do_write_i,
    //hand shake
    input wire                                      rcu_fu_csru_req_valid_i,

    //csr read
    output [CSR_ADDR_LEN-1:0]                       fu_csr_csru_raddr_o,
    input [XLEN-1:0]                                csr_fu_csru_rdata_i,
    input                                           csr_fu_csru_readable_i,
    input                                           csr_fu_csru_writable_i,
    
    //csr write
    output [CSR_ADDR_LEN-1:0]                       fu_csr_waddr_o,
    output                                          fu_do_csr_write_o,
    output [XLEN-1:0]                               fu_csr_wrdata_o,

    //rcu wrb
    output                                          fu_rcu_csr_resp_valid_o,
    output [ROB_INDEX_WIDTH-1:0]                           fu_rcu_csr_wrb_rob_index_o,
    output [PHY_REG_ADDR_WIDTH-1:0]                    fu_rcu_csr_wrb_addr_o,
    output [XLEN-1:0]                               fu_rcu_csr_wrb_data_o,
    output                                          fu_rcu_csr_exception_o,
    output [EXCEPTION_CAUSE_WIDTH-1:0]              fu_rcu_csr_ecause_o,


    output                                          fu_pmp_csru_cfg_vld_o,
    output [PMPCFG_ID_WIDTH-1:0]                    fu_pmp_csru_cfg_addr_o,
    output [XLEN-1:0]                               fu_pmp_csru_cfg_payload_o,
    input  [XLEN-1:0]                               pmp_fu_csru_cfg_origin_payload_i,
    output                                          fu_pmp_csru_addr_vld_o,
    output [PMPADDR_ID_WIDTH-1:0]                   fu_pmp_csru_addr_addr_o,
    output [XLEN-1:0]                               fu_pmp_csru_addr_payload_o,
    input  [XLEN-1:0]                               pmp_fu_csru_addr_origin_payload_i
);
//lsu
// wire lsu_exception_valid;
// wire [EXCEPTION_CODE_WIDTH - 1 : 0] lsu_exception_code;
// alu 
//parameter XLEN_M_IMMLEN = XLEN - IMM_LEN;
//parameter XLEN_M_PCWIDTH = XLEN - PC_WIDTH;



// alu => rcu
wire fu_alu1_req_ready;
wire fu_alu2_req_ready;
wire [XLEN - 1 : 0] alu1_result;
wire [XLEN - 1 : 0] alu2_result;
wire [PHY_REG_ADDR_WIDTH-1:0] alu1_prd_addr;
wire [PHY_REG_ADDR_WIDTH-1:0] alu2_prd_addr;
wire alu1_resp_valid;
wire alu2_resp_valid;
wire [ROB_INDEX_WIDTH - 1 : 0] alu1_wrb_rob_index;
wire [ROB_INDEX_WIDTH - 1 : 0] alu2_wrb_rob_index;
// wire alu_exception_valid;
// wire [EXCEPTION_CODE_WIDTH - 1 : 0] alu_exception_code;
// alu <> pc
wire alu1_is_jump;
wire alu2_is_jump;
wire alu1_is_branch;
wire alu2_is_branch;
wire [VIRTUAL_ADDR_LEN-1:0] alu1_pc;    //pc of the currently done instr
wire [VIRTUAL_ADDR_LEN-1:0] alu2_pc;    //pc of the currently done instr
wire [VIRTUAL_ADDR_LEN-1:0] alu1_next_pc;  //pc + 4 of the currently done instr
wire [VIRTUAL_ADDR_LEN-1:0] alu2_next_pc;  //pc + 4 of the currently done instr
reg [XLEN - 1 : 0] alu1_opr1;
reg [XLEN - 1 : 0] alu2_opr1;
reg [XLEN - 1 : 0] alu1_opr2;
reg [XLEN - 1 : 0] alu2_opr2;
// cmp => rcu
/*verilator lint_off UNUSED */
// wire cmp_ready;
// wire [PHY_REG_ADDR_WIDTH-1:0] cmp_rd_addr;
// wire cmp_done;
// wire [ROB_INDEX_WIDTH - 1 : 0] cmp_rob_index;
wire alu1_cmp_valid;
wire alu2_cmp_valid;
wire alu1_cmp_result;
wire alu2_cmp_result;
wire [63 : 0] alu1_imm_64;
wire [63 : 0] alu2_imm_64;
wire [63 : 0] alu1_pc_64;
wire [63 : 0] alu2_pc_64;

//wire alu1_gshare_pred_taken;
//wire alu2_gshare_pred_taken;
//wire [PC_WIDTH - 1 : 0] alu1_gshare_pred_pc;
//wire [PC_WIDTH - 1 : 0] alu2_gshare_pred_pc;
wire [PC_WIDTH - 1 : 0] alu1_final_next_pc;
wire [PC_WIDTH - 1 : 0] alu2_final_next_pc;
wire flush = global_predict_miss | global_ret | global_trap;

assign alu1_imm_64 = {{XLEN_M_IMMLEN{rcu_fu_alu1_imm_data_i[IMM_LEN-1]}}, rcu_fu_alu1_imm_data_i};
assign alu2_imm_64 = {{XLEN_M_IMMLEN{rcu_fu_alu2_imm_data_i[IMM_LEN-1]}}, rcu_fu_alu2_imm_data_i};
assign alu1_pc_64 = {{32'b0}, rcu_fu_alu1_pc_i};
assign alu2_pc_64 = {{32'b0}, rcu_fu_alu2_pc_i};

assign fu_rcu_alu1_resp_valid_o = alu1_resp_valid;
assign fu_rcu_alu2_resp_valid_o = alu2_resp_valid;
//assign fu_rcu_alu1_wrb_enable_o = 
//                        (alu1_is_branch & alu1_is_jump) |   // jump
//                        (~alu1_is_branch & alu1_resp_valid);  // op 
//assign fu_rcu_alu2_wrb_enable_o = 
//                        (alu2_is_branch & alu2_is_jump) |   // jump
//                        (~alu2_is_branch & alu2_resp_valid);  // op ssign fu_rcu_alu1_wrb_prd_addr_o =  alu1_prd_addr;
assign fu_rcu_alu1_wrb_data_o = (alu1_is_jump) ? {{XLEN_M_PCWIDTH{1'b0}}, alu1_next_pc} : // jal
                            alu1_result;  //op
assign fu_rcu_alu2_wrb_data_o = (alu2_is_jump) ? {{XLEN_M_PCWIDTH{1'b0}}, alu2_next_pc} : // jal
                            alu2_result;  //op*verilator lint_on UNUSED */
// assign exception_valid_o = alu_exception_valid | lsu_exception_valid;
// assign ecause_o = lsu_exception_valid ? lsu_exception_code : alu_exception_code; // lsu > alu, cuz lsu should be a ealier exception
// <> fetch
//assign fu_ft_btb_pc_o = rcu_fu_alu1_is_branch_i ? alu1_pc : alu2_pc;
//assign fu_ft_btb_pred_target_pc_o =  rcu_fu_alu1_is_branch_i ? alu1_result[VIRTUAL_ADDR_LEN - 1 : 0] : alu2_result[VIRTUAL_ADDR_LEN - 1 : 0];
// <> gshare
//assign alu1_gshare_pred_taken = (alu1_is_branch & ~ alu1_is_jump) ? alu1_cmp_result : alu1_is_jump;
//assign alu2_gshare_pred_taken = (alu2_is_branch & ~ alu2_is_jump) ? alu2_cmp_result : alu2_is_jump;
//assign fu_ft_gshare_pred_taken_o = alu1_resp_valid ? alu1_gshare_pred_taken : alu2_gshare_pred_taken;

//assign alu1_gshare_pred_pc = alu1_result[VIRTUAL_ADDR_LEN - 1 : 0];
//assign alu2_gshare_pred_pc = alu2_result[VIRTUAL_ADDR_LEN - 1 : 0];
//assign fu_ft_gshare_pred_pc_o = alu1_resp_valid ? alu1_gshare_pred_pc : alu2_gshare_pred_pc;
// <> PC_GEN   
assign alu1_final_next_pc = alu1_is_jump ? alu1_result[VIRTUAL_ADDR_LEN - 1 : 0]
                                         : (alu1_is_branch & alu1_cmp_result) ? alu1_result[VIRTUAL_ADDR_LEN - 1 : 0]  
                                                                              : alu1_next_pc;
assign alu2_final_next_pc = alu2_is_jump ? alu2_result[VIRTUAL_ADDR_LEN - 1 : 0]
                                         : (alu2_is_branch & alu2_cmp_result) ? alu2_result[VIRTUAL_ADDR_LEN - 1 : 0]  
                                                                              : alu2_next_pc;

assign fu_rcu_alu1_final_next_pc_o = alu1_final_next_pc;
assign fu_rcu_alu2_final_next_pc_o = alu2_final_next_pc;
assign fu_rcu_alu1_branch_predict_miss_o = alu1_final_next_pc != rcu_fu_alu1_predict_pc_i;
assign fu_rcu_alu2_branch_predict_miss_o = alu2_final_next_pc != rcu_fu_alu2_predict_pc_i;

// assign instr_buff_nxt_pc_valid_o = alu_branch;
// assign instr_buff_nxt_pc_o = alu_result[VIRTUAL_ADDR_LEN - 1 : 0];
// <> branch
// assign fu_ft_br_resp_valid_o =  (alu1_resp_valid & alu1_is_branch) | (alu2_resp_valid & alu2_is_branch);
// alu csr

// cmp 
assign alu1_cmp_valid = rcu_fu_alu1_is_branch_i & ~rcu_fu_alu1_is_jump_i;
assign alu2_cmp_valid = rcu_fu_alu2_is_branch_i & ~rcu_fu_alu2_is_jump_i;

reg [2:0] alu1_func_sel;
reg [2:0] alu2_func_sel;

wire fu_md_muldiv;
wire [2: 0] fu_md_func;
wire [2 : 0]                                fu_md_func3;
wire                                        fu_md_half;

assign fu_md_muldiv =   fu_md_func3[2];
assign fu_md_func = {fu_md_half, fu_md_func3[1: 0]};

assign fu_rcu_alu1_branch_taken_o = alu1_cmp_result;
assign fu_rcu_alu2_branch_taken_o = alu2_cmp_result;

wire [ROB_INDEX_WIDTH - 1 : 0]              fu_md_rob_index;
wire [PHY_REG_ADDR_WIDTH - 1 : 0]           fu_md_prd_addr;
wire [XLEN - 1 : 0]                         fu_md_oprd1;
wire [XLEN - 1 : 0]                         fu_md_oprd2;

assign {
    fu_md_rob_index,
    fu_md_prd_addr,
    fu_md_oprd1,
    fu_md_oprd2,
    fu_md_func3,
    fu_md_half
} = rcu_fu_md_package_i;

always @(*) begin
    if(rcu_fu_alu1_req_valid_i) begin
        case (rcu_fu_alu1_opr1_sel_i)
            ALU_SEL_REG : alu1_opr1 = rcu_fu_alu1_rs1_i;
            ALU_SEL_IMM : alu1_opr1 = 0; // FIXME: it seems that when this is 0, csrrxi and lui are settled
            ALU_SEL_PC  : alu1_opr1 = alu1_pc_64; 
            default : alu1_opr1 = 0;
        endcase
        case (rcu_fu_alu1_opr2_sel_i)
            ALU_SEL_REG : alu1_opr2 = rcu_fu_alu1_rs2_i;
            ALU_SEL_IMM : alu1_opr2 = alu1_imm_64; 
            ALU_SEL_PC  : alu1_opr2 = alu1_pc_64;
            default : alu1_opr2 = 0;
        endcase
    end
    else if(alu1_cmp_valid) begin
        alu1_opr1 = rcu_fu_alu1_rs1_i;
        alu1_opr2 = rcu_fu_alu1_rs2_i;
    end
    else begin
        alu1_opr1 = '0;
        alu1_opr2 = '0;
    end

    if(rcu_fu_alu1_is_branch_i) begin
        alu1_func_sel = ALU_ADD_SUB;
    end 
    else begin
        alu1_func_sel = rcu_fu_alu1_func3_i;
    end

    if(rcu_fu_alu2_is_branch_i) begin
        alu2_func_sel = ALU_ADD_SUB;
    end 
    else begin
        alu2_func_sel = rcu_fu_alu2_func3_i;
    end
end

always @(*) begin
    if(rcu_fu_alu2_req_valid_i) begin
        case (rcu_fu_alu2_opr1_sel_i)
            ALU_SEL_REG : alu2_opr1 = rcu_fu_alu2_rs1_i;
            ALU_SEL_IMM : alu2_opr1 = 0; // FIXME: it seems that when this is 0, csrrxi and lui are settled
            ALU_SEL_PC  : alu2_opr1 = alu2_pc_64;
            default : alu2_opr1 = 0;
        endcase
        case (rcu_fu_alu2_opr2_sel_i)
            ALU_SEL_REG : alu2_opr2 = rcu_fu_alu2_rs2_i;
            ALU_SEL_IMM : alu2_opr2 = alu2_imm_64; 
            ALU_SEL_PC  : alu2_opr2 = alu2_pc_64;
            default : alu2_opr2 = 0;
        endcase
    end
    else if (alu2_cmp_valid) begin
        alu2_opr1 = rcu_fu_alu2_rs1_i;
        alu2_opr2 = rcu_fu_alu2_rs2_i;
    end
    else begin
        alu2_opr1 = '0;
        alu2_opr2 = '0;
    end
end


alu alu1(
    .clk(clk),
    .rstn(rstn),
    .wfi(wfi),
    .trap(flush),

    .opr1_i(alu1_opr1),
    .opr2_i(alu1_opr2),
    .half_i(rcu_fu_alu1_half_i),
    .alu_function_select_i(alu1_func_sel),
    .function_modifier_i(rcu_fu_alu1_func_modifier_i),
    .rob_index_i(rcu_fu_alu1_rob_index_i),
    .prd_addr_i(rcu_fu_alu1_prd_addr_i),
    .rcu_fu_alu_req_valid_i(rcu_fu_alu1_req_valid_i),
    .cmp_input_a_i(rcu_fu_alu1_rs1_i),
    .cmp_input_b_i(rcu_fu_alu1_rs2_i),
    .cmp_function_select_i(rcu_fu_alu1_func3_i),
    .is_jump_i(rcu_fu_alu1_is_jump_i),
    .is_branch_i(rcu_fu_alu1_is_branch_i),
    .pc_i(rcu_fu_alu1_pc_i),
    .next_pc_i(rcu_fu_alu1_next_pc_i),

    // for frontend
    .is_jump_o(alu1_is_jump),
    .is_branch_o(alu1_is_branch),
    .pc_o(alu1_pc),
    .next_pc_o(alu1_next_pc),

    //for rcu
    .fu_rcu_alu_resp_valid_o(alu1_resp_valid),
    .prd_addr_o(fu_rcu_alu1_wrb_prd_addr_o),
    .rob_index_o(fu_rcu_alu1_wrb_rob_index_o),
    .alu_result_o(alu1_result),
    .cmp_result_o(alu1_cmp_result)
);
alu alu2(
    .clk(clk),
    .rstn(rstn),
    .wfi(wfi),
    .trap(flush),

    .opr1_i(alu2_opr1),
    .opr2_i(alu2_opr2),
    .half_i(rcu_fu_alu2_half_i),
    .alu_function_select_i(alu2_func_sel),
    .function_modifier_i(rcu_fu_alu2_func_modifier_i),
    .rob_index_i(rcu_fu_alu2_rob_index_i),
    .prd_addr_i(rcu_fu_alu2_prd_addr_i),
    .rcu_fu_alu_req_valid_i(rcu_fu_alu2_req_valid_i),
    .cmp_input_a_i(rcu_fu_alu2_rs1_i),
    .cmp_input_b_i(rcu_fu_alu2_rs2_i),
    .cmp_function_select_i(rcu_fu_alu2_func3_i),
    .is_jump_i(rcu_fu_alu2_is_jump_i),
    .is_branch_i(rcu_fu_alu2_is_branch_i),
    .pc_i(rcu_fu_alu2_pc_i),
    .next_pc_i(rcu_fu_alu2_next_pc_i),

    // for frontend
    .is_jump_o(alu2_is_jump),
    .is_branch_o(alu2_is_branch),
    .pc_o(alu2_pc),
    .next_pc_o(alu2_next_pc),

    //for rcu
    .fu_rcu_alu_resp_valid_o(alu2_resp_valid),
    .prd_addr_o(fu_rcu_alu2_wrb_prd_addr_o),
    .rob_index_o(fu_rcu_alu2_wrb_rob_index_o),
    .alu_result_o(alu2_result),
    .cmp_result_o(alu2_cmp_result)
);

md MulDiv(
    .clk(clk),
    .rst(rstn),
    .trap(flush),

    .fu_md_prd_addr_i(fu_md_prd_addr),
    .fu_md_oprd1_i(fu_md_oprd1),
    .fu_md_oprd2_i(fu_md_oprd2),
    .fu_md_rob_index_i(fu_md_rob_index),
    .fu_md_func_sel_i(fu_md_func),
    .fu_md_muldiv_i(fu_md_muldiv),
    .fu_md_req_valid_i(rcu_fu_md_req_valid_i),
    .fu_md_req_ready_o(rcu_fu_md_req_ready_o),
    .md_fu_wrb_prd_addr_o(fu_rcu_md_wrb_prd_addr_o),
    .md_fu_wrb_rob_index_o(fu_rcu_md_wrb_rob_index_o),
    .md_fu_wrb_data_o(fu_rcu_md_wrb_data_o),
    .md_fu_wrb_resp_valid_o(fu_rcu_md_wrb_resp_valid_o)
);

lsuv1 #(
    .LSQ_ENTRY_NUM(LSQ_ENTRY_NUM),
    .LSQ_ENTRY_NUM_WIDTH(LSQ_ENTRY_NUM_WIDTH)
)lsu(
    .clk(clk),
    .rst(rstn),
    .flush(flush),

    .lsu_rdy_o(lsu_rdy_o),
    
    .rcu_lsu_vld_i(rcu_fu_lsu_vld_i),
    .rcu_lsu_ls_i(rcu_fu_lsu_ls_i),
    .rcu_lsu_ld_opcode_i(rcu_fu_lsu_ld_opcode_i),
    .rcu_lsu_st_opcode_i(rcu_fu_lsu_st_opcode_i),
    .rcu_lsu_fenced_i(rcu_fu_lsu_fenced_i),
    .rcu_agu_virt_base_i(rcu_fu_agu_virt_base_i),
    .rcu_agu_virt_offset_i(rcu_fu_agu_virt_offset_i),
    .rcu_lsu_rob_index_i(rcu_fu_lsu_rob_index_i),
    .rcu_lsu_rd_addr_i(rcu_fu_lsu_rd_addr_i),
    .rcu_lsu_data_i(rcu_fu_lsu_data_i),
    .rcu_lsu_wakeup_i(rcu_fu_lsu_wakeup_i),
    .rcu_lsu_wakeup_rob_index_i(rcu_fu_lsu_wakeup_rob_index_i),
    .lsu_rcu_comm_vld_o(fu_rcu_lsu_comm_vld_o),
    .lsu_rcu_comm_rob_index_o(fu_rcu_lsu_comm_rob_index_o),
    .lsu_rcu_comm_rd_addr_o(fu_rcu_lsu_comm_rd_addr_o),
    .lsu_rcu_comm_data_o(fu_rcu_lsu_comm_data_o),
    .lsu_rcu_exception_vld_o(fu_rcu_lsu_exception_vld_o),
    .lsu_rcu_ecause_o(fu_rcu_lsu_ecause_o),

    .dtlb_lsu_rdy_i(dtlb_fu_lsu_rdy_i),
    .dtlb_lsu_vld_i(dtlb_fu_lsu_vld_i),
    .dtlb_lsu_hit_i(dtlb_fu_lsu_hit_i),
    .dtlb_lsu_ptag_i(dtlb_fu_lsu_ptag_i),
    .dtlb_lsu_exception_vld_i(dtlb_fu_lsu_exception_vld_i),
    .dtlb_lsu_ecause_i(dtlb_fu_lsu_ecause_i),
    .lsu_dtlb_iss_vld_o(fu_dtlb_lsu_iss_vld_o),
    .lsu_dtlb_iss_vtag_o(fu_dtlb_lsu_iss_vtag_o),
    .lsu_dtlb_iss_type_o(fu_dtlb_lsu_iss_type_o),

    .l1d_lsu_ld_req_rdy_i(l1d_fu_lsu_ld_req_rdy_i),
    .lsu_l1d_ld_req_vld_o(fu_l1d_lsu_ld_req_vld_o),
    .lsu_l1d_ld_req_rob_index_o(fu_l1d_lsu_ld_req_rob_index_o),
    .lsu_l1d_ld_req_rd_addr_o(fu_l1d_lsu_ld_req_rd_addr_o),
    .lsu_l1d_ld_req_opcode_o(fu_l1d_lsu_ld_req_opcode_o),
    .lsu_l1d_ld_req_index_o(fu_l1d_lsu_ld_req_index_o),
    .lsu_l1d_ld_req_offset_o(fu_l1d_lsu_ld_req_offset_o),
    .lsu_l1d_ld_req_vtag_o(fu_l1d_lsu_ld_req_vtag_o),

    .l1d_lsu_st_req_rdy_i(l1d_fu_lsu_st_req_rdy_i),
    .lsu_l1d_st_req_vld_o(fu_l1d_lsu_st_req_vld_o),
    .lsu_l1d_st_req_is_fence_o(fu_l1d_lsu_st_req_is_fence_o),
    .lsu_l1d_st_req_rob_index_o(fu_l1d_lsu_st_req_rob_index_o),
    .lsu_l1d_st_req_rd_addr_o(fu_l1d_lsu_st_req_rd_addr_o),
    .lsu_l1d_st_req_opcode_o(fu_l1d_lsu_st_req_opcode_o),
    .lsu_l1d_st_req_paddr_o(fu_l1d_lsu_st_req_paddr_o),
    .lsu_l1d_st_req_data_o(fu_l1d_lsu_st_req_data_o),

    .l1d_lsu_ld_replay_vld_i(l1d_fu_lsu_ld_replay_vld_i),
    
    .l1d_lsu_wb_vld_i(l1d_fu_lsu_wb_vld_i),
    .l1d_lsu_wb_rob_index_i(l1d_fu_lsu_wb_rob_index_i),
    .l1d_lsu_prf_wb_vld_i(l1d_fu_lsu_prf_wb_vld_i),
    .l1d_lsu_prf_wb_rd_addr_i(l1d_fu_lsu_prf_wb_rd_addr_i),
    .l1d_lsu_prf_wb_data_i(l1d_fu_lsu_prf_wb_data_i),

    .lsu_l1d_kill_req_o(fu_l1d_lsu_kill_req_o),

    .lsu_l1d_fencei_flush_vld_o(lsu_l1d_fencei_flush_vld_o),
    .l1d_lsu_fencei_flush_grant_i(l1d_lsu_fencei_flush_grant_i),

    .lsu_l1i_fencei_flush_vld_o(lsu_l1i_fencei_flush_vld_o),
    .l1i_lsu_fencei_flush_grant_i(l1i_lsu_fencei_flush_grant_i),

    .lsu_dtlb_flush_vld_o(lsu_dtlb_flush_vld_o),
    .lsu_dtlb_flush_use_asid_o(lsu_dtlb_flush_use_asid_o),
    .lsu_dtlb_flush_use_vpn_o(lsu_dtlb_flush_use_vpn_o),
    .lsu_dtlb_flush_vpn_o(lsu_dtlb_flush_vpn_o),
    .lsu_dtlb_flush_asid_o(lsu_dtlb_flush_asid_o),
    .dtlb_lsu_flush_grant_i(dtlb_lsu_flush_grant_i),

    .lsu_itlb_flush_vld_o(lsu_itlb_flush_vld_o),
    .lsu_itlb_flush_use_asid_o(lsu_itlb_flush_use_asid_o),
    .lsu_itlb_flush_use_vpn_o(lsu_itlb_flush_use_vpn_o),
    .lsu_itlb_flush_vpn_o(lsu_itlb_flush_vpn_o),
    .lsu_itlb_flush_asid_o(lsu_itlb_flush_asid_o),
    .itlb_lsu_flush_grant_i(itlb_lsu_flush_grant_i),

`ifdef LSU_DEBUG
/* verilator lint_off PINCONNECTEMPTY */
    .lsu_debug_head_o(),
    .lsu_debug_tail_o(),
    .lsu_debug_issued_o(),
    .lsu_debug_iss_vld_o(),
    .lsu_debug_iss_is_fenced_o(),
    .lsu_debug_iss_lsq_index_o(),
/* verilator lint_on PINCONNECTEMPTY */
`endif // LSU_DEBUG 
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

    .lsu_wb_cyc_o(fu_wb_lsu_cyc_o),
    .lsu_wb_stb_o(fu_wb_lsu_stb_o),
    .lsu_wb_we_o(fu_wb_lsu_we_o),
    .lsu_wb_adr_o(fu_wb_lsu_adr_o),
    .lsu_wb_dat_o(fu_wb_lsu_dat_o),
    .lsu_wb_sel_o(fu_wb_lsu_sel_o),
    .wb_lsu_ack_i(wb_fu_lsu_ack_i),
    .wb_lsu_dat_i(wb_fu_lsu_dat_i)
);

csr csru(
    .clk(clk),
    .rst(rstn),

    .rob_index_i(rcu_fu_csru_rob_index_i),
    .prd_addr_i(rcu_fu_csru_prd_addr_i),
    .func3_i(rcu_fu_csru_func3_i),
    .prs1_data_i(rcu_fu_csru_prs1_data_i),
    .imm_i(rcu_fu_csru_imm_i),
    .csr_addr_i(rcu_fu_csru_addr_i),
    .csr_do_read_i(rcu_fu_csru_do_read_i),
    .csr_do_write_i(rcu_fu_csru_do_write_i),

    .rcu_csr_req_valid_i(rcu_fu_csru_req_valid_i),


    .csr_raddr_o(fu_csr_csru_raddr_o),
    .csr_rdata_i(csr_fu_csru_rdata_i),
    .csr_readable_i(csr_fu_csru_readable_i),
    .csr_writable_i(csr_fu_csru_writable_i),
    
    .do_csr_write_o(fu_do_csr_write_o),
    .csr_waddr_o(fu_csr_waddr_o),
    .csr_wrdata_o(fu_csr_wrdata_o),


    .csr_rcu_resp_valid_o(fu_rcu_csr_resp_valid_o),
    .csr_rcu_wrb_rob_index_o(fu_rcu_csr_wrb_rob_index_o),
    .csr_rcu_wrb_addr_o(fu_rcu_csr_wrb_addr_o),
    .csr_rcu_wrb_data_o(fu_rcu_csr_wrb_data_o),
    .csr_exception_o(fu_rcu_csr_exception_o),
    .csr_ecause_o(fu_rcu_csr_ecause_o),

    .pmp_cfg_vld_o(fu_pmp_csru_cfg_vld_o),
    .pmp_cfg_addr_o(fu_pmp_csru_cfg_addr_o),
    .pmp_cfg_payload_o(fu_pmp_csru_cfg_payload_o),
    .pmp_cfg_origin_payload_i(pmp_fu_csru_cfg_origin_payload_i),
    .pmp_addr_vld_o(fu_pmp_csru_addr_vld_o),
    .pmp_addr_addr_o(fu_pmp_csru_addr_addr_o),
    .pmp_addr_payload_o(fu_pmp_csru_addr_payload_o),
    .pmp_addr_origin_payload_i(pmp_fu_csru_addr_origin_payload_i)

);

endmodule

`endif // FU_V
