`ifndef _LSUV1_V_
`define _LSUV1_V_
`ifdef VERILATOR
`include "hehe_cfg.vh"
`include "params.vh"
`endif
// TODO: need to support FENCE and AMO
module lsuv1 #(
    parameter LSQ_ENTRY_NUM = 8,
    parameter LSQ_ENTRY_NUM_WIDTH = 3
)(
    // global 
    input clk, rst, flush,
    output lsu_rdy_o,

    // <> RCU
    input                                                                                               rcu_lsu_vld_i,
    input                                                                                               rcu_lsu_ls_i,
    input  [LDU_OP_WIDTH - 1 : 0]                                                                       rcu_lsu_ld_opcode_i,
    input  [STU_OP_WIDTH - 1 : 0]                                                                       rcu_lsu_st_opcode_i,
    input                                                                                               rcu_lsu_fenced_i,
    input  [XLEN - 1 : 0]                                                                               rcu_agu_virt_base_i,
    input  [XLEN - 1 : 0]                                                                               rcu_agu_virt_offset_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                                    rcu_lsu_rob_index_i,
    input  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                 rcu_lsu_rd_addr_i,
    input  [XLEN - 1 : 0]                                                                               rcu_lsu_data_i,
    input                                                                                               rcu_lsu_wakeup_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                                    rcu_lsu_wakeup_rob_index_i,
    output                                                                                              lsu_rcu_comm_vld_o,
    output [ROB_INDEX_WIDTH - 1 : 0]                                                                    lsu_rcu_comm_rob_index_o,
    output [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                 lsu_rcu_comm_rd_addr_o,
    output [XLEN - 1 : 0]                                                                               lsu_rcu_comm_data_o,
    output                                                                                              lsu_rcu_exception_vld_o,
    output [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                              lsu_rcu_ecause_o,                                      
                                                    
    // <> TLB                                                   
    input                                                                                               dtlb_lsu_rdy_i,
    input                                                                                               dtlb_lsu_vld_i, // should be the lsu_dtlb_iss_vld_o in last cycle
    input                                                                                               dtlb_lsu_hit_i,
    input  [PHYSICAL_ADDR_TAG_LEN - 1 : 0]                                                              dtlb_lsu_ptag_i,
    input                                                                                               dtlb_lsu_exception_vld_i,
    input  [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                              dtlb_lsu_ecause_i,
    output                                                                                              lsu_dtlb_iss_vld_o,
    output [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                                               lsu_dtlb_iss_vtag_o,
    output [PMP_ACCESS_TYPE_WIDTH*2 - 1 : 0]                                                              lsu_dtlb_iss_type_o,
                                                    
    // <> d$                                                    
    // Load request                                                 
    input                                                                                               l1d_lsu_ld_req_rdy_i,
    output                                                                                              lsu_l1d_ld_req_vld_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]                                                              lsu_l1d_ld_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                            lsu_l1d_ld_req_rd_addr_o, // no need
    output  [      LDU_OP_WIDTH - 1 : 0]                                                                lsu_l1d_ld_req_opcode_o,
    output  [       ADDR_INDEX_LEN - 1 : 0]                                                             lsu_l1d_ld_req_index_o, 
    output  [      ADDR_OFFSET_LEN - 1 : 0]                                                             lsu_l1d_ld_req_offset_o, 
    output  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]                                                          lsu_l1d_ld_req_vtag_o, 
    // Store request                                                    
    input                                                                                               l1d_lsu_st_req_rdy_i,
    output                                                                                              lsu_l1d_st_req_vld_o,
    output                                                                                              lsu_l1d_st_req_is_fence_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]                                                              lsu_l1d_st_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                            lsu_l1d_st_req_rd_addr_o,
    output  [      STU_OP_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_opcode_o,
    output  [       PHYSICAL_ADDR_LEN - 1 : 0]                                                          lsu_l1d_st_req_paddr_o, 
    output  [              XLEN - 1 : 0]                                                                lsu_l1d_st_req_data_o,
    // ld replay: 1. mshr full or 2. stb partial hit                                                     
    input                                                                                               l1d_lsu_ld_replay_vld_i,
    // wb rob
    input  [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1: 0]                                           l1d_lsu_wb_vld_i,
    input  [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                      l1d_lsu_wb_rob_index_i,
    // wb prf
    input  [LSU_DATA_PIPE_COUNT - 1 : 0]                                                                l1d_lsu_prf_wb_vld_i,
    input  [PHY_REG_ADDR_WIDTH * LSU_DATA_PIPE_COUNT - 1 : 0]                                           l1d_lsu_prf_wb_rd_addr_i,
    input  [XLEN*LSU_DATA_PIPE_COUNT - 1 : 0]                                                           l1d_lsu_prf_wb_data_i,
    // kill                                                     
    output                                                                                              lsu_l1d_kill_req_o,
    // l1d flush
    output                                                                                              lsu_l1d_fencei_flush_vld_o,
    input                                                                                               l1d_lsu_fencei_flush_grant_i,

    // <> l1i                                                   
    output                                                                                              lsu_l1i_fencei_flush_vld_o,
    input                                                                                               l1i_lsu_fencei_flush_grant_i,

    // <> mmu : flush dtlb/itlb
    // dtlb shoot down
    output                                                                                              lsu_dtlb_flush_vld_o,
    output                                                                                              lsu_dtlb_flush_use_asid_o,
    output                                                                                              lsu_dtlb_flush_use_vpn_o,
    output [VPN_WIDTH-1:0]                                                                              lsu_dtlb_flush_vpn_o,
    output [ASID_WIDTH-1:0]                                                                             lsu_dtlb_flush_asid_o,
    input                                                                                               dtlb_lsu_flush_grant_i,
    // itlb shoot down                                          
    output                                                                                              lsu_itlb_flush_vld_o,
    output                                                                                              lsu_itlb_flush_use_asid_o,
    output                                                                                              lsu_itlb_flush_use_vpn_o,
    output [VPN_WIDTH-1:0]                                                                              lsu_itlb_flush_vpn_o,
    output [ASID_WIDTH-1:0]                                                                             lsu_itlb_flush_asid_o,
    input                                                                                               itlb_lsu_flush_grant_i,
    // debug
`ifdef LSU_DEBUG
    output  [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                                                lsu_debug_head_o,
    output  [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                                                lsu_debug_tail_o,
    output  [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                                                lsu_debug_issued_o,
    output                                                                                              lsu_debug_iss_vld_o,
    output                                                                                              lsu_debug_iss_is_fenced_o,
    output  [LSQ_ENTRY_NUM_WIDTH - 1 : 0]                                                               lsu_debug_iss_lsq_index_o,
    output                                                                                              lsu_debug_dtlb_miss_kill_o,
    output                                                                                              lsu_debug_l1d_s1_kill_o,
`endif // LSU_DEBUG                                                    
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
    // <> wb bus                                                    
    output                                                                                              lsu_wb_cyc_o,
    output                                                                                              lsu_wb_stb_o,
    output                                                                                              lsu_wb_we_o,
    output [PHYSICAL_ADDR_LEN - 1 : 0]                                                                  lsu_wb_adr_o,
    output [WB_DATA_LEN-1:0]                                                                            lsu_wb_dat_o,
    output [WB_DATA_LEN/8-1:0]                                                                          lsu_wb_sel_o,
    input                                                                                               wb_lsu_ack_i,
    input  [WB_DATA_LEN -1:0]                                                                           wb_lsu_dat_i
);
wire                                                                                                    lsq_rdy;
wire                                                                                                    wb_arb_rdy;
wire [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT : 0]                                                    wb_arb_lsq_wb_vld      ;
wire [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT + 1) * ROB_INDEX_WIDTH - 1: 0]                         wb_arb_lsq_wb_rob_index;
wire                                                                                                    pma_lsq_is_io;
wire [VIRTUAL_ADDR_LEN - 1 : 0]                                                                         agu_virt_addr;
wire [VIRTUAL_ADDR_LEN - 1 : 0]                                                                         lsq_vaddr;
wire                                                                                                    misalign_exception_en;
wire                                                                                                    misalign_exception_vld;
wire [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                                    misalign_ecause;
wire [LS_OPCODE_WIDTH - 1 : 0]                                                                          rcu_opcode;
wire                                                                                                    lsq_pma_dtlb_hit;
wire [     PHYSICAL_ADDR_LEN - 1 : 0]                                                                   lsq_pma_paddr;
wire                                                                                                    lsq_wakeup_kill;
wire                                                                                                    lsq_replay_kill;

wire                                                                                                    bus_ctrl_lsq_rdy;
wire                                                                                                    lsq_bus_ctrl_req_vld;
wire                                                                                                    lsq_bus_ctrl_req_load_or_store;
wire                                                                                                    lsq_bus_ctrl_req_is_fence;
wire   [     ROB_INDEX_WIDTH - 1 : 0]                                                                   lsq_bus_ctrl_req_rob_index;
wire   [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                                 lsq_bus_ctrl_req_rd_addr;
wire   [      STU_OP_WIDTH - 1 : 0]                                                                     lsq_bus_ctrl_req_opcode;
wire   [       PHYSICAL_ADDR_LEN - 1 : 0]                                                               lsq_bus_ctrl_req_paddr; 
wire   [              XLEN - 1 : 0]                                                                     lsq_bus_ctrl_req_data;

wire                                                                                                    bus_ctrl_wb_arb_wb_vld;
wire [ROB_INDEX_WIDTH - 1 : 0]                                                                          bus_ctrl_wb_arb_wb_rob_index;
wire                                                                                                    bus_ctrl_wb_arb_prf_wb_vld;
wire [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                       bus_ctrl_wb_arb_prf_wb_rd_addr;
wire [XLEN - 1 : 0]                                                                                     bus_ctrl_wb_arb_prf_wb_data;
wire                                                                                                    wb_arb_bus_ctrl_rdy;

wire                                                                                                    lsu_prf_wb_vld;
wire  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                      lsu_prf_wb_rd_addr;
wire  [XLEN - 1 : 0]                                                                                    lsu_prf_wb_data;

wire                                                                                                    req_is_sfence_vma;
wire  [ASID_WIDTH - 1 : 0]                                                                              rcu_lsq_sfence_vma_asid;

wire lsu_l1d_kill_req_d = lsq_wakeup_kill | 
                            lsq_replay_kill | 
                            pma_lsq_is_io
                            ;
reg lsu_l1d_kill_req_q;
always @(posedge clk) begin
    if(rst) begin
        lsu_l1d_kill_req_q <= 0;
    end
    else begin
        lsu_l1d_kill_req_q <= lsu_l1d_kill_req_d;
    end
end

assign lsu_rcu_comm_data_o = lsu_prf_wb_data;

assign rcu_opcode = rcu_lsu_ls_i ? rcu_lsu_st_opcode_i : {{(LS_OPCODE_WIDTH - LDU_OP_WIDTH){1'b0}}, rcu_lsu_ld_opcode_i};
assign lsu_rdy_o = lsq_rdy;
assign lsu_l1d_kill_req_o = lsu_l1d_kill_req_q;
assign lsu_debug_l1d_s1_kill_o = lsu_l1d_kill_req_d;

`ifdef LSU_DEBUG
assign lsu_debug_dtlb_miss_kill_o = dtlb_lsu_vld_i & ~dtlb_lsu_hit_i;
`endif // LSU_DEBUG
`ifdef DPRAM64_2R1W
wire [LS_OPCODE_WIDTH - 1 : 0] lsq_l1d_st_stu_opcode;
wire [LS_OPCODE_WIDTH - 1 : 0] lsq_l1d_ld_ldu_opcode;
assign we = 
    (lsq_l1d_st_stu_opcode == STU_SB ) ? {{(XLEN/8 - 1){1'b0}}, 1'b1} : 
    (lsq_l1d_st_stu_opcode == STU_SH ) ? {{(XLEN/8 - 2){1'b0}}, 2'b11} : 
    (lsq_l1d_st_stu_opcode == STU_SW ) ? {{(XLEN/8 - 4){1'b0}}, 4'b1111} :
    (lsq_l1d_st_stu_opcode == STU_FENCE ) ? FENCE_WE :
    (lsq_l1d_st_stu_opcode == STU_SD ) ? {(XLEN/8){1'b1}} :
    1;
assign din = lsu_l1d_st_req_data_o;
assign waddr = lsu_l1d_st_req_paddr_o;
assign wrob_index_d = lsu_l1d_st_req_rob_index_o;                 
assign wrd_addr_d = lsu_l1d_st_req_rd_addr_o;

// reg [     ROB_INDEX_WIDTH - 1 : 0]                                              rrob_index_d;
// reg [    PHY_REG_ADDR_WIDTH - 1 : 0]                                            rrd_addr_d;
// reg [PHYSICAL_ADDR_LEN-1:0]                                                     raddr_d;
// reg [1:0]                                                                       re_d;
// reg                                                                             runsigned_d;

assign rrob_index_d = lsu_l1d_ld_req_rob_index_o;
assign rrd_addr_d = lsu_l1d_ld_req_rd_addr_o;
assign raddr_d = {{(PHYSICAL_ADDR_LEN - VIRTUAL_ADDR_LEN){1'b0}}, lsu_l1d_ld_req_vtag_o, lsu_l1d_ld_req_index_o, lsu_l1d_ld_req_offset_o};
assign re_d = 
    (lsq_l1d_ld_ldu_opcode == LDU_LB || lsq_l1d_ld_ldu_opcode == LDU_LBU) ? 2'b00 : 
    (lsq_l1d_ld_ldu_opcode == LDU_LH || lsq_l1d_ld_ldu_opcode == LDU_LHU) ? 2'b01 : 
    (lsq_l1d_ld_ldu_opcode == LDU_LW || lsq_l1d_ld_ldu_opcode == LDU_LWU) ? 2'b10 :
    2'b11;
assign runsigned_d = (lsq_l1d_ld_ldu_opcode == LDU_LBU || lsq_l1d_ld_ldu_opcode == LDU_LHU || lsq_l1d_ld_ldu_opcode == LDU_LWU) ;  
`endif // DPRAM64_2R1W

assign req_is_sfence_vma = rcu_lsu_vld_i & rcu_lsu_ls_i & (rcu_lsu_st_opcode_i == STU_SFENCE_VMA);
assign rcu_lsq_sfence_vma_asid = req_is_sfence_vma ? rcu_agu_virt_offset_i[ASID_WIDTH - 1 : 0] : 0;
assign lsq_vaddr = req_is_sfence_vma ? (rcu_agu_virt_base_i[VIRTUAL_ADDR_LEN - 1 : 0] << (ADDR_OFFSET_LEN + ADDR_INDEX_LEN)) : agu_virt_addr;
lsu_agu agu(
    .clk(clk),
    .agu_base_i(rcu_agu_virt_base_i),
    .agu_offset_i(rcu_agu_virt_offset_i),

    .agu_addr_o(agu_virt_addr)
);

lsu_wb_arb lsu_wb_arb(
    // global 
    .clk(clk), 
    .rst(rst), 
    .flush(flush),
    // <> d$ 
    .l1d_wb_arb_wb_vld_i(l1d_lsu_wb_vld_i),
    .l1d_wb_arb_wb_rob_index_i(l1d_lsu_wb_rob_index_i),
    .l1d_wb_arb_prf_wb_vld_i(l1d_lsu_prf_wb_vld_i),
    .l1d_wb_arb_prf_wb_rd_addr_i(l1d_lsu_prf_wb_rd_addr_i),
    .l1d_wb_arb_prf_wb_data_i(l1d_lsu_prf_wb_data_i),

    // <> Bus
    .bus_wb_arb_wb_vld_i(bus_ctrl_wb_arb_wb_vld),
    .bus_wb_arb_wb_rob_index_i(bus_ctrl_wb_arb_wb_rob_index),
    .bus_wb_arb_prf_wb_vld_i(bus_ctrl_wb_arb_prf_wb_vld),
    .bus_wb_arb_prf_wb_rd_addr_i(bus_ctrl_wb_arb_prf_wb_rd_addr),
    .bus_wb_arb_prf_wb_data_i(bus_ctrl_wb_arb_prf_wb_data),
    .wb_arb_bus_rdy_o(wb_arb_bus_ctrl_rdy),

    // <> LSQ
    .wb_arb_lsq_wb_vld_o(wb_arb_lsq_wb_vld),
    .wb_arb_lsq_wb_rob_index_o(wb_arb_lsq_wb_rob_index),
    .wb_arb_rdy_o(wb_arb_rdy),

    // <> PRF
    .wb_arb_prf_wb_vld_o(lsu_prf_wb_vld),
    .wb_arb_prf_wb_rd_addr_o(lsu_prf_wb_rd_addr),
    .wb_arb_prf_wb_data_o(lsu_prf_wb_data)
);

lsu_mc lsu_misalign_checker(
    .rcu_ac_valid_i(rcu_lsu_vld_i & lsu_rdy_o),
    .rcu_ac_ls_i(rcu_lsu_ls_i),
    .rcu_ac_opcode_i(rcu_opcode),
    .agu_ac_addr_i(agu_virt_addr),
    .ac_ecause_o(misalign_ecause),
    .ac_exception_vld_o(misalign_exception_vld)
);

lsu_pma_checker lsu_pma_checker(
    .clk(clk), 
    .rst(rst), 
    .flush(flush),
    .lsq_lr_st_vld_i(lsu_l1d_st_req_vld_o),
    .lsq_lr_st_paddr_i(lsu_l1d_st_req_paddr_o),
    .lsq_lr_ld_vld_i(lsu_l1d_ld_req_vld_o),  
    .lsq_lr_ld_dtlb_hit_i(lsq_pma_dtlb_hit),                            
    .lsq_lr_ld_paddr_i(lsq_pma_paddr),
    .lr_lsq_is_io_o(pma_lsq_is_io)
);

lsu_bus_ctrl lsu_bus_ctrl(
    // global 
    .clk(clk), 
    .rst(rst), 
    .flush(flush),
    // <> lsq
    .bus_ctrl_lsq_rdy_o(bus_ctrl_lsq_rdy),
    .lsq_bus_ctrl_req_vld_i(lsq_bus_ctrl_req_vld),
    .lsq_bus_ctrl_req_load_or_store_i(lsq_bus_ctrl_req_load_or_store),
    .lsq_bus_ctrl_req_is_fence_i(lsq_bus_ctrl_req_is_fence),
    .lsq_bus_ctrl_req_rob_index_i(lsq_bus_ctrl_req_rob_index),
    .lsq_bus_ctrl_req_rd_addr_i(lsq_bus_ctrl_req_rd_addr),
    .lsq_bus_ctrl_req_opcode_i(lsq_bus_ctrl_req_opcode),
    .lsq_bus_ctrl_req_paddr_i(lsq_bus_ctrl_req_paddr), 
    .lsq_bus_ctrl_req_data_i(lsq_bus_ctrl_req_data),
    // <> lsq
    .bus_ctrl_wb_cyc_o(lsu_wb_cyc_o),
    .bus_ctrl_wb_stb_o(lsu_wb_stb_o),
    .bus_ctrl_wb_we_o(lsu_wb_we_o),
    .bus_ctrl_wb_adr_o(lsu_wb_adr_o),
    .bus_ctrl_wb_dat_o(lsu_wb_dat_o),
    .bus_ctrl_wb_sel_o(lsu_wb_sel_o),
    .wb_bus_ctrl_ack_i(wb_lsu_ack_i),
    .wb_bus_ctrl_dat_i(wb_lsu_dat_i),
    // <> wb arb
    .bus_ctrl_wb_arb_wb_vld_o(bus_ctrl_wb_arb_wb_vld),
    .bus_ctrl_wb_arb_wb_rob_index_o(bus_ctrl_wb_arb_wb_rob_index),
    .bus_ctrl_wb_arb_prf_wb_vld_o(bus_ctrl_wb_arb_prf_wb_vld),
    .bus_ctrl_wb_arb_prf_wb_rd_addr_o(bus_ctrl_wb_arb_prf_wb_rd_addr),
    .bus_ctrl_wb_arb_prf_wb_data_o(bus_ctrl_wb_arb_prf_wb_data),
    .wb_arb_bus_ctrl_rdy_i(wb_arb_bus_ctrl_rdy)
);

lsu_lsq  #(
    .LSQ_ENTRY_NUM(LSQ_ENTRY_NUM),
    .LSQ_ENTRY_NUM_WIDTH(LSQ_ENTRY_NUM_WIDTH)
)lsu_lsq_dut(
    // global 
    .clk(clk), 
    .rst(rst), 
    .flush(flush),

    .lsq_rdy_o(lsq_rdy),
    // <> RCU
    .rcu_lsq_vld_i(rcu_lsu_vld_i),
    .rcu_lsq_ls_i(rcu_lsu_ls_i),
    .rcu_lsq_opcode_i(rcu_opcode),
    .rcu_lsq_fenced_i(rcu_lsu_fenced_i),
    .agu_lsq_virt_addr_i(lsq_vaddr),
    .rcu_lsq_sfence_vma_asid_i(rcu_lsq_sfence_vma_asid),
    .rcu_lsq_rob_index_i(rcu_lsu_rob_index_i),
    .rcu_lsq_rd_addr_i(rcu_lsu_rd_addr_i),
    .rcu_lsq_data_i(rcu_lsu_data_i),

    .rcu_lsq_wakeup_i(rcu_lsu_wakeup_i),
    .rcu_lsq_wakeup_rob_index_i(rcu_lsu_wakeup_rob_index_i),

    .lsq_rcu_comm_vld_o(lsu_rcu_comm_vld_o),
    .lsq_rcu_comm_rob_index_o(lsu_rcu_comm_rob_index_o),
    .lsq_rcu_comm_rd_addr_o(lsu_rcu_comm_rd_addr_o),
    .lsq_rcu_comm_exception_vld_o(lsu_rcu_exception_vld_o),
    .lsq_rcu_comm_ecause_o(lsu_rcu_ecause_o),
    // Write Back (from bus or d$)
    .wb_arb_lsq_wb_vld_i(wb_arb_lsq_wb_vld),
    .wb_arb_lsq_wb_rob_index_i(wb_arb_lsq_wb_rob_index),
    .wb_arb_lsq_prf_wb_vld_i(lsu_prf_wb_vld),
    .wb_arb_lsq_prf_wb_rd_addr_i(lsu_prf_wb_rd_addr),
    .wb_arb_rdy_i(wb_arb_rdy),
    // <> MC
    .mc_lsq_exception_vld_i(misalign_exception_vld),
    .mc_lsq_ecause_i(misalign_ecause),
    // <> TLB
    .dtlb_lsq_rdy_i(dtlb_lsu_rdy_i),
    .dtlb_lsq_vld_i(dtlb_lsu_vld_i), // should be the lsq_dtlb_iss_vld_o in last cycle
    .dtlb_lsq_hit_i(dtlb_lsu_hit_i),
    .dtlb_lsq_ptag_i(dtlb_lsu_ptag_i),
    .dtlb_lsq_exception_vld_i(dtlb_lsu_exception_vld_i),
    .dtlb_lsq_ecause_i(dtlb_lsu_ecause_i),
    .lsq_dtlb_iss_vld_o(lsu_dtlb_iss_vld_o),
    .lsq_dtlb_iss_vtag_o(lsu_dtlb_iss_vtag_o),
    .lsq_dtlb_iss_type_o(lsu_dtlb_iss_type_o),

    // <> d$
    // Load request
    .l1d_lsq_ld_req_rdy_i(l1d_lsu_ld_req_rdy_i),
    .lsq_l1d_ld_req_vld_o(lsu_l1d_ld_req_vld_o),
    .lsq_l1d_ld_req_rob_index_o(lsu_l1d_ld_req_rob_index_o),
    .lsq_l1d_ld_req_rd_addr_o(lsu_l1d_ld_req_rd_addr_o), // no need
    .lsq_l1d_ld_req_opcode_o(lsu_l1d_ld_req_opcode_o),
    .lsq_l1d_ld_req_index_o(lsu_l1d_ld_req_index_o), 
    .lsq_l1d_ld_req_offset_o(lsu_l1d_ld_req_offset_o), 
    .lsq_l1d_ld_req_vtag_o(lsu_l1d_ld_req_vtag_o), 
    // Store request
    .l1d_lsq_st_req_rdy_i(l1d_lsu_st_req_rdy_i),
    .lsq_l1d_st_req_vld_o(lsu_l1d_st_req_vld_o),
    .lsq_l1d_st_req_is_fence_o(lsu_l1d_st_req_is_fence_o),
    .lsq_l1d_st_req_rob_index_o(lsu_l1d_st_req_rob_index_o),
    .lsq_l1d_st_req_rd_addr_o(lsu_l1d_st_req_rd_addr_o),
    .lsq_l1d_st_req_opcode_o(lsu_l1d_st_req_opcode_o),
    .lsq_l1d_st_req_paddr_o(lsu_l1d_st_req_paddr_o), 
    .lsq_l1d_st_req_data_o(lsu_l1d_st_req_data_o),
`ifdef DPRAM64_2R1W
    .lsq_l1d_st_stu_opcode_o(lsq_l1d_st_stu_opcode),
    .lsq_l1d_ld_ldu_opcode_o(lsq_l1d_ld_ldu_opcode),
`endif // DPRAM64_2R1W
    // ld replay: 1. mshr full or 2. stb partial hit 
    .l1d_lsq_ld_replay_vld_i(l1d_lsu_ld_replay_vld_i),
    
    // kill
    .lsq_l1d_wakeup_kill_o(lsq_wakeup_kill),
    .lsq_l1d_replay_kill_o(lsq_replay_kill),
    // l1d flush
    .lsq_l1d_fencei_flush_vld_o(lsu_l1d_fencei_flush_vld_o),
    .l1d_lsq_fencei_flush_grant_i(l1d_lsu_fencei_flush_grant_i),

    // <> l1i
    .lsq_l1i_fencei_flush_vld_o(lsu_l1i_fencei_flush_vld_o),
    .l1i_lsq_fencei_flush_grant_i(l1i_lsu_fencei_flush_grant_i),

    // <> mmu : flush dtlb/itlb
    // dtlb shoot down
    .lsq_dtlb_flush_vld_o(lsu_dtlb_flush_vld_o),
    .lsq_dtlb_flush_use_asid_o(lsu_dtlb_flush_use_asid_o),
    .lsq_dtlb_flush_use_vpn_o(lsu_dtlb_flush_use_vpn_o),
    .lsq_dtlb_flush_vpn_o(lsu_dtlb_flush_vpn_o),
    .lsq_dtlb_flush_asid_o(lsu_dtlb_flush_asid_o),
    .dtlb_lsq_flush_grant_i(dtlb_lsu_flush_grant_i),
    // itlb shoot down
    .lsq_itlb_flush_vld_o(lsu_itlb_flush_vld_o),
    .lsq_itlb_flush_use_asid_o(lsu_itlb_flush_use_asid_o),
    .lsq_itlb_flush_use_vpn_o(lsu_itlb_flush_use_vpn_o),
    .lsq_itlb_flush_vpn_o(lsu_itlb_flush_vpn_o),
    .lsq_itlb_flush_asid_o(lsu_itlb_flush_asid_o),
    .itlb_lsq_flush_grant_i(itlb_lsu_flush_grant_i),

    // <> PMA
    .lsq_pma_dtlb_hit_o(lsq_pma_dtlb_hit),
    .lsq_pma_paddr_o(lsq_pma_paddr),
    .pma_lsq_is_io_i(pma_lsq_is_io),
    // debug
`ifdef LSU_DEBUG
    .lsq_debug_head_o(lsu_debug_head_o),
    .lsq_debug_tail_o(lsu_debug_tail_o),
    .lsq_debug_issued_o(lsu_debug_issued_o),
    .lsq_debug_iss_vld_o(lsu_debug_iss_vld_o),
    .lsq_debug_iss_is_fenced_o(lsu_debug_iss_is_fenced_o),
    .lsq_debug_iss_lsq_index_o(lsu_debug_iss_lsq_index_o),
`endif // LSU_DEBUG
    // <> Bus 
    //TODO: connect to wishbone bus later
    .bus_ctrl_lsq_rdy_i(bus_ctrl_lsq_rdy),
    .lsq_bus_ctrl_req_vld_o(lsq_bus_ctrl_req_vld),
    .lsq_bus_ctrl_req_load_or_store_o(lsq_bus_ctrl_req_load_or_store),
    .lsq_bus_ctrl_req_is_fence_o(lsq_bus_ctrl_req_is_fence),
    .lsq_bus_ctrl_req_rob_index_o(lsq_bus_ctrl_req_rob_index),
    .lsq_bus_ctrl_req_rd_addr_o(lsq_bus_ctrl_req_rd_addr),
    .lsq_bus_ctrl_req_opcode_o(lsq_bus_ctrl_req_opcode),
    .lsq_bus_ctrl_req_paddr_o(lsq_bus_ctrl_req_paddr), 
    .lsq_bus_ctrl_req_data_o(lsq_bus_ctrl_req_data)
);
`ifdef LOG_LV1
always @(posedge clk) begin
    // if(lsu_rdy_o & rcu_lsu_vld_i) begin
    //     $display($realtime, ":\t LSU req recieved. %s-%d\t@ 0x%x\tfenced:%d\trob_index:%d\trd_addr:%d\tdata:%x", 
    //         rcu_lsu_ls_i ? "st" : "ld", rcu_lsu_ls_i ? rcu_lsu_st_opcode_i : rcu_lsu_ld_opcode_i, 
    //         agu_virt_addr,rcu_lsu_fenced_i, rcu_lsu_rob_index_i, rcu_lsu_rd_addr_i, rcu_lsu_data_i
    //     );
    // end 
    if(rcu_lsu_wakeup_i) begin
        $display($realtime, ":\twakeup @ %d", rcu_lsu_wakeup_rob_index_i);
    end
`ifdef LOG_LV2
    // if(lsu_l1d_ld_req_vld_o & l1d_lsu_ld_req_rdy_i) begin
    //     $display($realtime, ":\tLSU ld req sent. ld-%d\t@ 0x%x\trob_index:%d\trd_addr:%d", 
    //         lsu_l1d_ld_req_opcode_o, {lsu_l1d_ld_req_vtag_o, lsu_l1d_ld_req_index_o, lsu_l1d_ld_req_offset_o},
    //         lsu_l1d_ld_req_rob_index_o, lsu_l1d_ld_req_rd_addr_o
    //     );
    // end 
    // if(lsu_l1d_st_req_vld_o & l1d_lsu_st_req_rdy_i) begin
    //     $display($realtime, ":\tLSU st req sent. st-%d\t@ 0x%x\tfenced:%d\trob_index:%d\trd_addr:%d\tdata:%x", 
    //         lsu_l1d_st_req_opcode_o, lsu_l1d_st_req_paddr_o, lsu_l1d_st_req_is_fence_o, 
    //         lsu_l1d_st_req_rob_index_o, lsu_l1d_st_req_rd_addr_o, lsu_l1d_st_req_data_o
    //     );
    // end 
`endif // LOG_LV2
end
`endif //LOG_LV1
// always @(negedge clk) begin
//     if(rcu_lsu_vld_i & lsu_rdy_o) begin
//         $display("req @ %x in", rcu_agu_virt_base_i);
//     end 
// end
endmodule
`endif // _LSUV1_V_
