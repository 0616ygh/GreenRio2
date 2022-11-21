`ifndef _LSU_LSQ_V_
`define _LSU_LSQ_V_
`ifdef VERILATOR
`include "params.vh"
`endif

module lsu_lsq 
#(
    parameter LSQ_ENTRY_NUM = 8,
    parameter LSQ_ENTRY_NUM_WIDTH = 3
)(
    // global 
    input clk, rst, flush,
    output lsq_rdy_o,

    // <> RCU
    input                                           rcu_lsq_vld_i,
    input                                           rcu_lsq_ls_i,
    input  [LS_OPCODE_WIDTH - 1 : 0]                rcu_lsq_opcode_i,
    input                                           rcu_lsq_fenced_i,
    input  [VIRTUAL_ADDR_LEN - 1 : 0]               agu_lsq_virt_addr_i,
    input  [ASID_WIDTH - 1 : 0]                     rcu_lsq_sfence_vma_asid_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                rcu_lsq_rob_index_i,
    input  [PHY_REG_ADDR_WIDTH - 1 : 0]             rcu_lsq_rd_addr_i,
    input  [XLEN - 1 : 0]                           rcu_lsq_data_i,

    input                                           rcu_lsq_wakeup_i,
    input [ROB_INDEX_WIDTH - 1 : 0]                 rcu_lsq_wakeup_rob_index_i,

    output                                          lsq_rcu_comm_vld_o,
    output [ROB_INDEX_WIDTH - 1 : 0]                lsq_rcu_comm_rob_index_o,
    output [PHY_REG_ADDR_WIDTH - 1 : 0]             lsq_rcu_comm_rd_addr_o,
    output                                          lsq_rcu_comm_exception_vld_o,
    output [EXCEPTION_CAUSE_WIDTH - 1 : 0]          lsq_rcu_comm_ecause_o,
    // <> wb arbiter
    input [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT : 0]                                               wb_arb_lsq_wb_vld_i         ,
    input [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT + 1) * ROB_INDEX_WIDTH - 1: 0]                    wb_arb_lsq_wb_rob_index_i   ,
    input                                                                                               wb_arb_lsq_prf_wb_vld_i,
    input  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                 wb_arb_lsq_prf_wb_rd_addr_i,
    input                                                                                               wb_arb_rdy_i,

    // <> MC
    input                                           mc_lsq_exception_vld_i,
    input  [EXCEPTION_CAUSE_WIDTH - 1 : 0]          mc_lsq_ecause_i,

    // <> TLB
    input                                           dtlb_lsq_rdy_i,
    input                                           dtlb_lsq_vld_i, // should be the lsq_dtlb_iss_vld_o in last cycle
    input                                           dtlb_lsq_hit_i,
    input  [PHYSICAL_ADDR_TAG_LEN - 1 : 0]          dtlb_lsq_ptag_i,
    input                                           dtlb_lsq_exception_vld_i,
    input  [EXCEPTION_CAUSE_WIDTH - 1 : 0]          dtlb_lsq_ecause_i,


    output                                          lsq_dtlb_iss_vld_o,
    output [VIRTUAL_ADDR_TAG_LEN - 1 : 0]           lsq_dtlb_iss_vtag_o,
    output [PMP_ACCESS_TYPE_WIDTH - 1 : 0]          lsq_dtlb_iss_type_o,

    // <> d$
    // Load request
    input                                           l1d_lsq_ld_req_rdy_i,
    output                                          lsq_l1d_ld_req_vld_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]          lsq_l1d_ld_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]        lsq_l1d_ld_req_rd_addr_o, // no need
    output  [      LDU_OP_WIDTH - 1 : 0]            lsq_l1d_ld_req_opcode_o,
    output  [       ADDR_INDEX_LEN - 1 : 0]         lsq_l1d_ld_req_index_o, 
    output  [      ADDR_OFFSET_LEN - 1 : 0]         lsq_l1d_ld_req_offset_o, 
    output  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]      lsq_l1d_ld_req_vtag_o, 
    // Store request
    input                                           l1d_lsq_st_req_rdy_i,
    output                                          lsq_l1d_st_req_vld_o,
    output                                          lsq_l1d_st_req_is_fence_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]          lsq_l1d_st_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]        lsq_l1d_st_req_rd_addr_o,
    output  [      STU_OP_WIDTH - 1 : 0]            lsq_l1d_st_req_opcode_o,
    output  [       PHYSICAL_ADDR_LEN - 1 : 0]      lsq_l1d_st_req_paddr_o, 
    output  [              XLEN - 1 : 0]            lsq_l1d_st_req_data_o,
`ifdef DPRAM64_2R1W
    output   [LS_OPCODE_WIDTH - 1 : 0]              lsq_l1d_st_stu_opcode_o,
    output   [LS_OPCODE_WIDTH - 1 : 0]              lsq_l1d_ld_ldu_opcode_o,
`endif // DPRAM64_2R1W
    // ld replay: 1. mshr full or 2. stb partial hit 
    input                                           l1d_lsq_ld_replay_vld_i,
    // awake kill 
    output                                          lsq_l1d_wakeup_kill_o,
    // replay kill                      
    output                                          lsq_l1d_replay_kill_o,
    // l1d flush
    output                                          lsq_l1d_fencei_flush_vld_o,
    input                                           l1d_lsq_fencei_flush_grant_i,

    // <> l1i
    output                                          lsq_l1i_fencei_flush_vld_o,
    input                                           l1i_lsq_fencei_flush_grant_i,

    // <> mmu : flush dtlb/itlb
    // dtlb shoot down
    output                                                  lsq_dtlb_flush_vld_o,
    output                                                  lsq_dtlb_flush_use_asid_o,
    output                                                  lsq_dtlb_flush_use_vpn_o,
    output [VPN_WIDTH-1:0]                                  lsq_dtlb_flush_vpn_o,
    output [ASID_WIDTH-1:0]                                 lsq_dtlb_flush_asid_o,
    input                                                   dtlb_lsq_flush_grant_i,
    // itlb shoot down
    output                                                  lsq_itlb_flush_vld_o,
    output                                                  lsq_itlb_flush_use_asid_o,
    output                                                  lsq_itlb_flush_use_vpn_o,
    output [VPN_WIDTH-1:0]                                  lsq_itlb_flush_vpn_o,
    output [ASID_WIDTH-1:0]                                 lsq_itlb_flush_asid_o,
    input                                                   itlb_lsq_flush_grant_i,

    // <> PMA
    output                                          lsq_pma_dtlb_hit_o,
    output [     PHYSICAL_ADDR_LEN - 1 : 0]         lsq_pma_paddr_o,
    input                                           pma_lsq_is_io_i,
    // debug
`ifdef LSU_DEBUG
    output  [LSQ_ENTRY_NUM_WIDTH - 1 : 0]           lsq_debug_head_o,
    output  [LSQ_ENTRY_NUM_WIDTH - 1 : 0]           lsq_debug_tail_o,
    output  [LSQ_ENTRY_NUM_WIDTH - 1 : 0]           lsq_debug_issued_o,
    output                                          lsq_debug_iss_vld_o,
    output                                          lsq_debug_iss_is_fenced_o,
    output  [LSQ_ENTRY_NUM_WIDTH - 1 : 0]           lsq_debug_iss_lsq_index_o,
`endif // LSU_DEBUG
    // <> Bus controller
    //TODO: connect to wishbone bus later
    input                                           bus_ctrl_lsq_rdy_i,
    output                                          lsq_bus_ctrl_req_vld_o,
    output                                          lsq_bus_ctrl_req_load_or_store_o,
    output                                          lsq_bus_ctrl_req_is_fence_o,
    output  [     ROB_INDEX_WIDTH - 1 : 0]          lsq_bus_ctrl_req_rob_index_o,
    output  [    PHY_REG_ADDR_WIDTH - 1 : 0]        lsq_bus_ctrl_req_rd_addr_o,
    output  [      STU_OP_WIDTH - 1 : 0]            lsq_bus_ctrl_req_opcode_o,
    output  [       PHYSICAL_ADDR_LEN - 1 : 0]      lsq_bus_ctrl_req_paddr_o, 
    output  [              XLEN - 1 : 0]            lsq_bus_ctrl_req_data_o
);

genvar i;
genvar j;

wire  [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                          head;
wire  [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                          tail;
wire  [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                          issued;
reg   [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                          ld_issued_q;
reg   [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                          ld_issued_qq;
reg                                                                         ld_vld_q;
reg                                                                         ld_vld_qq;
reg   [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                        dtlb_vtag_q;

wire                                                                        lsq_enque;
wire                                                                        wb_enque_bypass;

wire                                                                        lsq_deque;
wire                                                                        wb_deque_bypass;
wire                                                                        lsq_entry_no_prf_wb;

wire [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                           issue_nxt = issued + 1;
wire[LSQ_ENTRY_NUM_WIDTH - 1: 0]                                            last_issue = (issued == 0) ? '1 : issued - 1;
wire                                                                        iss_issuedentry_bypass;
wire                                                                        iss_issued_entry_bypass_fenced_rdy;
wire                                                                        iss_nxt_entry_bypass;
wire                                                                        iss_nxt_entry_bypass_fenced_rdy;
wire [LSQ_ENTRY_NUM_WIDTH - 1: 0]                                           final_iss;
wire                                                                        final_iss_bypass;
wire                                                                        iss_issued_entry_bypass;
wire                                                                        lsq_issued_entry_awake;
wire                                                                        lsq_issued_entry_rdy;
wire                                                                        lsq_nxt_entry_rdy;
wire                                                                        lsq_last_iss_succ;   
reg                                                                         lsq_last_iss_succ_q;                                     
wire                                                                        lsq_l1d_last_iss_awake_check_pass;
wire                                                                        req_need_check_awake;
wire                                                                        lsq_l1d_last_iss_is_pa;
wire [     VIRTUAL_ADDR_TAG_LEN -1 : 0]                                     lsq_iss_vtag;

reg                                                                         fence_on_flight;
wire                                                                        fence_on_flight_set;
wire                                                                        fence_on_flight_clr;
reg                                                                         l1d_flush_done;
wire                                                                        l1d_flush_done_set;
wire                                                                        l1d_flush_done_clr;
reg                                                                         l1i_flush_done;
wire                                                                        l1i_flush_done_set;
wire                                                                        l1i_flush_done_clr;
reg                                                                         dtlb_flush_done;
wire                                                                        dtlb_flush_done_set;
wire                                                                        dtlb_flush_done_clr;
reg                                                                         itlb_flush_done;
wire                                                                        itlb_flush_done_set;
wire                                                                        itlb_flush_done_clr;
reg                                                                         sfence_vma_asid_vld_q;
reg [ASID_WIDTH - 1 : 0]                                                    sfence_vma_asid_q;
wire                                                                        sfence_vma_asid_set;
wire                                                                        sfence_vma_asid_clr;
wire                                                                        lsq_rcu_sfence_vma_rdy;

wire                                                                        bypass_req_is_fence_req;


wire [ROB_INDEX_WIDTH - 1 : 0]                                              wb_arb_lsq_wb_rob_index        [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT : 0];

wire                                                                        lsq_l1d_ld_iss_vld;
wire                                                                        lsq_l1d_st_iss_vld;
wire                                                                        lsq_l1d_iss_vld_d;
reg                                                                         lsq_l1d_iss_vld_q;
reg                                                                         lsq_l1d_st_iss_vld_q;
wire                                                                        lsq_l1d_iss_hsk_d;
reg                                                                         lsq_l1d_iss_hsk_q;

wire                                                                        bus_ctrl_rdy;
wire                                                                        lsq_bus_ctrl_iss_vld;
reg                                                                         lsq_bus_ctrl_iss_vld_q;
wire                                                                        lsq_bus_ctrl_iss_hsk_d;
reg                                                                         lsq_bus_ctrl_iss_hsk_q;

wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_init_vld_vec      ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_tag_in_vld_vec    ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_wakeup_vld_vec    ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_exec_vld_vec      ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_replay_vld_vec    ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_wb_vld_vec        ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_succ_vld_vec      ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_deque_vec         ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_head_vec          ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_enque_vec         ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_only_enque_vec    ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_fenced_rdy_vec    ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_fence_req_rdy_vec ; // one-hot or 0
wire      [LSQ_ENTRY_NUM - 1 : 0]                                           lsq_entry_no_prf_wb_vec     ; // one-hot or 0


// lsq entry vec                                
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_vld_vec_r;
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_fenced_vec_r;
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_head_vec_r; // one-hot or 0
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_first_fenced; // one-hot or 0
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_first_fenced_r; // one-hot or 0
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_first_fenced_s; // one-hot or 0
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_fenced_barrier; // one-hot or 0
wire  [LSQ_ENTRY_NUM - 1 : 0]                                               lsq_entry_fenced_barrier_s; // one-hot or 0
wire  [2 * LSQ_ENTRY_NUM - 1 : 0]                                           double_lsq_entry_first_fenced;
wire  [2 * LSQ_ENTRY_NUM - 1 : 0]                                           double_lsq_entry_first_fenced_s;
wire  [2 * LSQ_ENTRY_NUM - 1 : 0]                                           double_lsq_entry_fenced_barrier_s;
wire  [2 * LSQ_ENTRY_NUM - 1 : 0]                                           double_lsq_entry_fenced_barrier;

wire  [LSQ_ENTRY_NUM - 1 : 0]                                               prf_wb_rd_addr_match;
reg   [LSQ_ENTRY_NUM_WIDTH - 1 : 0]                                         prf_wb_entry;                             

wire                                                                        lsq_entry_vld_vec           [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_ls_vec            [LSQ_ENTRY_NUM - 1 : 0];
wire   [LSQ_ENTRY_OPCODE_WIDTH - 1 : 0]                                     lsq_entry_opcode_vec        [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_fenced_vec        [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_is_fence_req_vec  [LSQ_ENTRY_NUM - 1 : 0];
wire   [LSQ_ENTRY_TAG_WIDTH - 1 : 0]                                        lsq_entry_tag_vec           [LSQ_ENTRY_NUM - 1 : 0];
wire   [LSQ_ENTRY_INDEX_WIDTH -1 : 0]                                       lsq_entry_index_vec         [LSQ_ENTRY_NUM - 1 : 0];
wire   [LSQ_ENTRY_OFFSET_WIDTH - 1 : 0]                                     lsq_entry_offset_vec        [LSQ_ENTRY_NUM - 1 : 0];
wire   [LSQ_ENTRY_ROB_INDEX_WIDTH - 1 : 0]                                  lsq_entry_rob_index_vec     [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_virt_vec          [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_awake_vec         [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_exec_vec          [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_succ_vec          [LSQ_ENTRY_NUM - 1 : 0];
wire   [LSQ_ENTRY_RD_ADDR_WIDTH - 1 : 0]                                    lsq_entry_rd_addr_vec       [LSQ_ENTRY_NUM - 1 : 0];
wire   [XLEN - 1 : 0]                                                       lsq_entry_data_vec          [LSQ_ENTRY_NUM - 1 : 0];
wire                                                                        lsq_entry_exception_vld_vec [LSQ_ENTRY_NUM - 1 : 0]; // one-hot or 0
wire   [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                      lsq_entry_ecause_vec        [LSQ_ENTRY_NUM - 1 : 0]; // one-hot or 0
wire                                                                        lsq_entry_dtlb_virt;
wire [LSQ_ENTRY_TAG_WIDTH - 1 : 0]                                          lsq_entry_dtlb_tag;
wire [LSQ_ENTRY_OPCODE_WIDTH - 1 : 0]                                       lsq_entry_init_opcode;
wire [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                         lsq_entry_init_vtag;
wire [ADDR_INDEX_LEN - 1 : 0]                                               lsq_entry_init_index;
wire [ADDR_OFFSET_LEN - 1 : 0]                                              lsq_entry_init_offset;
// exception
wire                                                                        lsq_s1_exception_vld;
wire [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                        lsq_s1_ecause;
// kill
wire                                                                        l1d_lsq_ld_replay_vld;
wire                                                                        l1d_lsq_ld_replay_vld_d;
reg                                                                         l1d_lsq_ld_replay_vld_q;
assign l1d_lsq_ld_replay_vld_d = l1d_lsq_ld_replay_vld;
assign l1d_lsq_ld_replay_vld = l1d_lsq_ld_replay_vld_i & ~l1d_lsq_ld_replay_vld_q;

assign lsq_rdy_o =  (
                        (head != tail) | 
                        (head == tail) & lsq_deque |
                        (head == tail) & ~lsq_entry_vld_vec[head]
                    ) &
                    ~(rcu_lsq_vld_i & rcu_lsq_ls_i & (rcu_lsq_opcode_i == STU_SFENCE_VMA) & lsq_rcu_sfence_vma_rdy) // sfence vma reg full
                    ;

assign wb_deque_bypass = |(lsq_entry_succ_vld_vec & lsq_entry_head_vec); // the succ entry is head
assign wb_enque_bypass = (head == tail) & lsq_deque ;


assign lsq_rcu_comm_vld_o = ((lsq_deque & lsq_entry_no_prf_wb) | wb_arb_lsq_prf_wb_vld_i) & ~flush;
assign lsq_rcu_comm_rob_index_o = (lsq_deque & lsq_entry_no_prf_wb) ? lsq_entry_rob_index_vec[head] : lsq_entry_rob_index_vec[prf_wb_entry];
assign lsq_rcu_comm_rd_addr_o = wb_arb_lsq_prf_wb_vld_i ? wb_arb_lsq_prf_wb_rd_addr_i : 0;
assign lsq_rcu_comm_exception_vld_o = (lsq_deque & lsq_entry_no_prf_wb) ? lsq_entry_exception_vld_vec[head] : lsq_entry_exception_vld_vec[prf_wb_entry];
assign lsq_rcu_comm_ecause_o = (lsq_deque & lsq_entry_no_prf_wb) ? lsq_entry_ecause_vec[head] : lsq_entry_ecause_vec[prf_wb_entry];
     
assign lsq_entry_init_opcode = rcu_lsq_opcode_i;
assign lsq_entry_init_index = agu_lsq_virt_addr_i[ADDR_INDEX_UPP - 1 : ADDR_INDEX_LOW];
assign lsq_entry_init_offset = agu_lsq_virt_addr_i[ADDR_OFFSET_UPP - 1 : ADDR_OFFSET_LOW];
assign lsq_entry_init_vtag = agu_lsq_virt_addr_i[VIRTUAL_ADDR_TAG_UPP - 1 : VIRTUAL_ADDR_TAG_LOW];
assign lsq_entry_dtlb_virt = ~lsq_entry_ls_vec[issued] | // load 
                                lsq_entry_ls_vec[issued] & dtlb_lsq_vld_i & ~dtlb_lsq_hit_i; // store and tib is not hit
assign lsq_entry_dtlb_tag = ~lsq_entry_dtlb_virt ? dtlb_lsq_ptag_i : 
                                    {{LSQ_ENTRY_TAG_WIDTH - VIRTUAL_ADDR_TAG_LEN{1'b0}}, dtlb_vtag_q};

assign lsq_iss_vtag = (dtlb_lsq_vld_i & ~dtlb_lsq_hit_i) ? 
                                        dtlb_vtag_q :
                                        lsq_entry_tag_vec[issued][VIRTUAL_ADDR_TAG_LEN - 1 : 0];

assign lsq_enque = rcu_lsq_vld_i & 
                    (
                        ~lsq_entry_vld_vec[tail] | // tail is not valid
                        wb_enque_bypass 
                    );
                                
assign lsq_entry_no_prf_wb = lsq_entry_no_prf_wb_vec[head];
assign lsq_deque = lsq_entry_vld_vec[head] & // head is valid
                    lsq_entry_exec_vec[head] & 
                    lsq_entry_vld_vec[head] &
                    (lsq_entry_succ_vec[head] | wb_deque_bypass) &
                    (~wb_arb_lsq_prf_wb_vld_i & lsq_entry_no_prf_wb_vec[head] | ~lsq_entry_no_prf_wb_vec[head]) 
                    ;


assign lsq_l1d_iss_vld_d = lsq_l1d_ld_iss_vld | lsq_l1d_st_iss_vld;
assign lsq_l1d_iss_hsk_d = lsq_l1d_ld_iss_vld & l1d_lsq_ld_req_rdy_i |
                            lsq_l1d_st_iss_vld & l1d_lsq_st_req_rdy_i;

assign final_iss = ~lsq_last_iss_succ ? issued : issue_nxt;
assign final_iss_bypass = ~lsq_last_iss_succ ? 
                                iss_issued_entry_bypass : 
                                iss_nxt_entry_bypass;
assign iss_issued_entry_bypass = (tail == issued) & lsq_enque;
assign iss_issued_entry_bypass_fenced_rdy = (
                                                (head == issued) & rcu_lsq_fenced_i | 
                                                ~rcu_lsq_fenced_i
                                            ) &
                                            (
                                                (
                                                    lsq_entry_vld_vec[last_issue] & 
                                                    ~lsq_entry_fenced_vec[last_issue] & 
                                                    lsq_entry_fenced_rdy_vec[last_issue] 
                                                )
                                                |
                                                ~lsq_entry_vld_vec[last_issue]
                                            );
assign iss_nxt_entry_bypass = (tail == issue_nxt) & lsq_enque;
assign iss_nxt_entry_bypass_fenced_rdy =    (
                                                (head == issue_nxt) & rcu_lsq_fenced_i | ~rcu_lsq_fenced_i
                                            ) &
                                            (
                                                (
                                                    lsq_entry_vld_vec[issued] & 
                                                    ~lsq_entry_fenced_vec[issued] & 
                                                    lsq_entry_fenced_rdy_vec[issued] 
                                                )
                                                |    
                                                ~lsq_entry_vld_vec[issued]
                                            );
assign lsq_issued_entry_rdy =  lsq_entry_vld_vec[issued] & ~lsq_entry_exec_vec[issued] | 
                                iss_issued_entry_bypass;    
assign lsq_nxt_entry_rdy =  lsq_entry_vld_vec[issue_nxt] & ~lsq_entry_exec_vec[issue_nxt] | 
                            iss_nxt_entry_bypass;
assign req_need_check_awake = lsq_entry_vld_vec[issued] & (
                                (lsq_entry_opcode_vec[issued] != STU_FENCE) & (lsq_entry_opcode_vec[issued] != STU_SFENCE_VMA) & (lsq_entry_opcode_vec[issued] != STU_FENCE_I ) & lsq_entry_ls_vec[issued] | // st without fence 
                                pma_lsq_is_io_i & ~lsq_entry_ls_vec[issued] // io ld
                            );
assign lsq_l1d_last_iss_awake_check_pass = 
                                        lsq_issued_entry_awake & req_need_check_awake |
                                        ~req_need_check_awake;                  
assign lsq_l1d_last_iss_is_pa = (lsq_entry_ls_vec[issued] & lsq_entry_vld_vec[issued]) |
                            (~lsq_entry_ls_vec[issued] & lsq_entry_vld_vec[issued] & dtlb_lsq_vld_i & dtlb_lsq_hit_i); // no need to bypass
assign lsq_last_iss_succ =  lsq_l1d_iss_vld_q & lsq_l1d_iss_hsk_q & 
                                ~l1d_lsq_ld_replay_vld & 
                                lsq_l1d_last_iss_awake_check_pass & 
                                lsq_l1d_last_iss_is_pa & 
                                ~l1d_lsq_ld_replay_vld &
                                (~pma_lsq_is_io_i & lsq_entry_ls_vec[issued] & lsq_l1d_st_iss_vld_q | ~pma_lsq_is_io_i & ~lsq_entry_ls_vec[issued] & lsq_pma_dtlb_hit_o)
                            |
                            lsq_bus_ctrl_iss_vld_q & lsq_bus_ctrl_iss_hsk_q;

// issue to tlb
assign lsq_dtlb_iss_vld_o = (   // forward req
                                iss_issued_entry_bypass & iss_issued_entry_bypass_fenced_rdy & ~bypass_req_is_fence_req | 
                                // new req bypass
                                lsq_last_iss_succ &  
                                (iss_nxt_entry_bypass ? 
                                    iss_nxt_entry_bypass_fenced_rdy : 
                                    lsq_entry_fenced_rdy_vec[issue_nxt]
                                ) 
                                | // in-que loads
                                ~lsq_entry_ls_vec[issued] & lsq_entry_vld_vec[issued] & ~lsq_entry_exec_vec[issued] 
                                | // normal st
                                (
                                    lsq_entry_ls_vec[issued] & lsq_entry_vld_vec[issued] & ~lsq_entry_exec_vec[issued] &
                                    lsq_entry_virt_vec[issued] & ~(dtlb_lsq_hit_i & dtlb_lsq_vld_i) 
                                ) & ~lsq_entry_is_fence_req_vec[issued]
                                | // replay
                                l1d_lsq_ld_replay_vld
                            ) ; // for every st in the que, last tlb req must be sent by itself
assign lsq_dtlb_iss_vtag_o = l1d_lsq_ld_replay_vld ? lsq_entry_tag_vec[ld_issued_qq][VIRTUAL_ADDR_TAG_LEN - 1 : 0] :
                            ~lsq_last_iss_succ ? 
                            iss_issued_entry_bypass ? lsq_entry_init_vtag : lsq_iss_vtag :
                            iss_nxt_entry_bypass ? lsq_entry_init_vtag : lsq_entry_tag_vec[issue_nxt][VIRTUAL_ADDR_TAG_LEN - 1 : 0];
assign lsq_dtlb_iss_type_o = l1d_lsq_ld_replay_vld ? (lsq_entry_ls_vec[ld_issued_qq] ? PMP_ACCESS_TYPE_W : PMP_ACCESS_TYPE_R) :
                            ~lsq_last_iss_succ ? 
                                iss_issued_entry_bypass ? 
                                    rcu_lsq_ls_i ? PMP_ACCESS_TYPE_W : PMP_ACCESS_TYPE_R :
                                    lsq_entry_ls_vec[issued] ? PMP_ACCESS_TYPE_W : PMP_ACCESS_TYPE_R :
                                iss_nxt_entry_bypass ? 
                                    rcu_lsq_ls_i ? PMP_ACCESS_TYPE_W : PMP_ACCESS_TYPE_R :
                                    lsq_entry_ls_vec[issue_nxt] ? PMP_ACCESS_TYPE_W : PMP_ACCESS_TYPE_R;

// issue ld to d$
assign lsq_l1d_ld_iss_vld =     l1d_lsq_ld_replay_vld ? 1'b1 :
                                ~lsq_last_iss_succ ? 
                                (
                                    ~lsq_entry_ls_vec[issued] & lsq_entry_vld_vec[issued] & 
                                    ~lsq_entry_exec_vec[issued] &  lsq_entry_fenced_rdy_vec[issued] 
                                    | 
                                    iss_issued_entry_bypass & ~rcu_lsq_ls_i & iss_issued_entry_bypass_fenced_rdy
                                ) :
                                (
                                    ~lsq_entry_ls_vec[issue_nxt] & lsq_entry_vld_vec[issue_nxt] & 
                                    lsq_entry_fenced_rdy_vec[issue_nxt] & ~lsq_entry_exec_vec[issue_nxt]
                                    | 
                                    iss_nxt_entry_bypass & ~rcu_lsq_ls_i & iss_nxt_entry_bypass_fenced_rdy
                                );

assign lsq_l1d_ld_req_vld_o = lsq_l1d_ld_iss_vld & wb_arb_rdy_i;
assign lsq_l1d_ld_req_rob_index_o = l1d_lsq_ld_replay_vld ? lsq_entry_rob_index_vec[ld_issued_qq] : 
                                    final_iss_bypass ? rcu_lsq_rob_index_i : 
                                                        lsq_entry_rob_index_vec[final_iss];
assign lsq_l1d_ld_req_rd_addr_o =   l1d_lsq_ld_replay_vld ? lsq_entry_rd_addr_vec[ld_issued_qq] :
                                    final_iss_bypass ? rcu_lsq_rd_addr_i : 
                                                        lsq_entry_rd_addr_vec[final_iss];
assign lsq_l1d_ld_req_opcode_o = l1d_lsq_ld_replay_vld ? lsq_entry_opcode_vec[ld_issued_qq][LDU_OP_WIDTH - 1 : 0] :
                                final_iss_bypass ? rcu_lsq_opcode_i[LDU_OP_WIDTH - 1 : 0] : 
                                                        lsq_entry_opcode_vec[final_iss][LDU_OP_WIDTH - 1 : 0];
assign lsq_l1d_ld_req_index_o = l1d_lsq_ld_replay_vld ? lsq_entry_index_vec[ld_issued_qq] :
                                final_iss_bypass ? lsq_entry_init_index : 
                                                    lsq_entry_index_vec[final_iss];
assign lsq_l1d_ld_req_offset_o = l1d_lsq_ld_replay_vld ? lsq_entry_offset_vec[ld_issued_qq] :
                                    final_iss_bypass ? lsq_entry_init_offset : 
                                                        lsq_entry_offset_vec[final_iss];
assign lsq_l1d_ld_req_vtag_o =  l1d_lsq_ld_replay_vld ? lsq_entry_tag_vec[ld_issued_qq][VIRTUAL_ADDR_TAG_LEN - 1 : 0] :
                                ~lsq_last_iss_succ ? 
                                    iss_issued_entry_bypass ?  lsq_entry_init_vtag : lsq_iss_vtag : 
                                    iss_nxt_entry_bypass ? lsq_entry_init_vtag : lsq_entry_tag_vec[issue_nxt][VIRTUAL_ADDR_TAG_LEN - 1 : 0];

//issue st uses pa. will know if the st is success immediately. 
// do not have the case to forward the nxt req.
assign lsq_l1d_st_iss_vld = lsq_entry_is_fence_req_vec[issued] ?
                                lsq_entry_vld_vec[issued] & 
                                (lsq_entry_opcode_vec[issued] == STU_FENCE) & 
                                lsq_entry_fence_req_rdy_vec[issued] &
                                ~l1d_lsq_ld_replay_vld &
                                ~lsq_entry_exec_vec[issued] // fence req
                            :
                                ~lsq_last_iss_succ & lsq_entry_vld_vec[issued] & 
                                lsq_entry_ls_vec[issued] & 
                                ~lsq_entry_virt_vec[issued] & 
                                lsq_entry_fenced_rdy_vec[issued] & 
                                ~l1d_lsq_ld_replay_vld &
                                ~lsq_entry_exec_vec[issued] // st and amo
                            ;
assign lsq_l1d_st_req_vld_o = lsq_l1d_st_iss_vld & wb_arb_rdy_i & ~flush;

assign lsq_l1d_st_req_is_fence_o = lsq_entry_fenced_vec[issued];
assign lsq_l1d_st_req_rob_index_o = lsq_entry_rob_index_vec[issued];
assign lsq_l1d_st_req_rd_addr_o = lsq_entry_rd_addr_vec[issued];
assign lsq_l1d_st_req_opcode_o = lsq_entry_opcode_vec[issued];
assign lsq_l1d_st_req_data_o = lsq_entry_data_vec[issued];
assign lsq_l1d_st_req_paddr_o =  {lsq_entry_tag_vec[issued][PHYSICAL_ADDR_TAG_LEN - 1 : 0], 
                                lsq_entry_index_vec[issued], lsq_entry_offset_vec[issued]};

assign lsq_dtlb_flush_vld_o = lsq_l1d_st_iss_vld & (lsq_entry_opcode_vec[issued] == STU_SFENCE_VMA);
assign lsq_dtlb_flush_use_asid_o = (sfence_vma_asid_q != 0);
assign lsq_dtlb_flush_asid_o = sfence_vma_asid_q;
assign lsq_dtlb_flush_use_vpn_o = (lsq_entry_tag_vec[issued] != 0);
assign lsq_dtlb_flush_vpn_o = lsq_entry_tag_vec[issued][VIRTUAL_ADDR_TAG_LEN - 1 : 0];

assign lsq_itlb_flush_vld_o = lsq_l1d_st_iss_vld & (lsq_entry_opcode_vec[issued] == STU_SFENCE_VMA);
assign lsq_itlb_flush_use_asid_o = (sfence_vma_asid_q != 0);
assign lsq_itlb_flush_asid_o = sfence_vma_asid_q;
assign lsq_itlb_flush_use_vpn_o = (lsq_entry_tag_vec[issued] != 0);
assign lsq_itlb_flush_vpn_o = lsq_entry_tag_vec[issued][VIRTUAL_ADDR_TAG_LEN - 1 : 0];

assign lsq_l1i_fencei_flush_vld_o = lsq_l1d_st_iss_vld & (lsq_entry_opcode_vec[issued] == STU_FENCE_I);
assign lsq_l1d_fencei_flush_vld_o = lsq_l1d_st_iss_vld & (lsq_entry_opcode_vec[issued] == STU_FENCE_I);

`ifdef DPRAM64_2R1W
assign lsq_l1d_st_stu_opcode_o = lsq_entry_opcode_vec[issued];
assign lsq_l1d_ld_ldu_opcode_o = final_iss_bypass ? rcu_lsq_opcode_i : lsq_entry_opcode_vec[final_iss];
`endif // DPRAM64_2R1W
assign lsq_l1d_wakeup_kill_o = ~lsq_l1d_last_iss_awake_check_pass & lsq_l1d_iss_vld_q;
assign lsq_issued_entry_awake = (lsq_entry_awake_vec[issued] & lsq_entry_vld_vec[issued] | lsq_entry_wakeup_vld_vec[issued]);

assign lsq_l1d_replay_kill_o = lsq_l1d_iss_vld_q & l1d_lsq_ld_replay_vld;

assign lsq_bus_ctrl_iss_vld = pma_lsq_is_io_i & lsq_issued_entry_awake & lsq_entry_fenced_rdy_vec[issued] & ~lsq_last_iss_succ;
assign lsq_bus_ctrl_iss_hsk_d = lsq_bus_ctrl_iss_vld & bus_ctrl_rdy;

assign lsq_pma_dtlb_hit_o = dtlb_lsq_vld_i & dtlb_lsq_hit_i;
assign lsq_pma_paddr_o = {dtlb_lsq_ptag_i, lsq_entry_index_vec[issued], lsq_entry_offset_vec[issued]};

assign bus_ctrl_rdy = bus_ctrl_lsq_rdy_i;
assign lsq_bus_ctrl_req_vld_o = lsq_bus_ctrl_iss_vld;
assign lsq_bus_ctrl_req_load_or_store_o =lsq_entry_ls_vec[issued];
assign lsq_bus_ctrl_req_is_fence_o = lsq_entry_fenced_vec[issued];
assign lsq_bus_ctrl_req_rob_index_o = lsq_entry_rob_index_vec[issued];
assign lsq_bus_ctrl_req_rd_addr_o = lsq_entry_rd_addr_vec[issued];
assign lsq_bus_ctrl_req_opcode_o = lsq_entry_opcode_vec[issued];
assign lsq_bus_ctrl_req_paddr_o = {lsq_entry_tag_vec[issued][PHYSICAL_ADDR_TAG_LEN - 1 : 0], lsq_entry_index_vec[issued], lsq_entry_offset_vec[issued]};
assign lsq_bus_ctrl_req_data_o = lsq_entry_data_vec[issued];

`ifdef LSU_DEBUG
assign lsq_debug_head_o = head;
assign lsq_debug_tail_o = tail;
assign lsq_debug_issued_o = issued;
assign lsq_debug_iss_vld_o = lsq_bus_ctrl_req_vld_o | lsq_l1d_st_req_vld_o | lsq_l1d_ld_req_vld_o;
assign lsq_debug_iss_is_fenced_o = lsq_bus_ctrl_req_vld_o & lsq_bus_ctrl_req_is_fence_o | lsq_l1d_st_req_vld_o & lsq_l1d_st_req_is_fence_o;
assign lsq_debug_iss_lsq_index_o = lsq_l1d_ld_iss_vld ? final_iss : issued;
`endif // LSU_DEBUG

// exception
assign lsq_s1_exception_vld = mc_lsq_exception_vld_i;
assign lsq_s1_ecause = mc_lsq_exception_vld_i ? mc_lsq_ecause_i : 0;

// fence
assign bypass_req_is_fence_req = rcu_lsq_vld_i & rcu_lsq_ls_i & (rcu_lsq_opcode_i == STU_FENCE || rcu_lsq_opcode_i == STU_SFENCE_VMA || rcu_lsq_opcode_i == STU_FENCE_I);
assign lsq_rcu_sfence_vma_rdy = ~sfence_vma_asid_vld_q;

assign fence_on_flight_set = lsq_l1d_st_req_vld_o & l1d_lsq_st_req_rdy_i & lsq_entry_is_fence_req_vec[issued];
assign l1d_flush_done_set = fence_on_flight & l1d_lsq_fencei_flush_grant_i;
assign l1i_flush_done_set = fence_on_flight & l1i_lsq_fencei_flush_grant_i;
assign dtlb_flush_done_set = fence_on_flight & dtlb_lsq_flush_grant_i;
assign itlb_flush_done_set = fence_on_flight & itlb_lsq_flush_grant_i;

assign sfence_vma_asid_set = rcu_lsq_vld_i & lsq_rdy_o & rcu_lsq_ls_i & (rcu_lsq_opcode_i == STU_SFENCE_VMA);

assign fence_on_flight_clr = lsq_deque & lsq_entry_is_fence_req_vec[head];
assign l1d_flush_done_clr = lsq_deque & lsq_entry_is_fence_req_vec[head];
assign l1i_flush_done_clr = lsq_deque & lsq_entry_is_fence_req_vec[head];
assign dtlb_flush_done_clr = lsq_deque & lsq_entry_is_fence_req_vec[head];
assign itlb_flush_done_clr = lsq_deque & lsq_entry_is_fence_req_vec[head];

assign sfence_vma_asid_clr = lsq_deque & lsq_entry_ls_vec[head] & (lsq_entry_opcode_vec[head] == STU_SFENCE_VMA);

always @(posedge clk) begin
    if(rst | fence_on_flight_clr) begin
        fence_on_flight <= 0;
    end
    else if(fence_on_flight_set)begin
        fence_on_flight <= 1;
    end
end

always @(posedge clk) begin
    if(rst | l1d_flush_done_clr) begin
        l1d_flush_done <= 0;
    end
    else if(l1d_flush_done_set)begin
        l1d_flush_done <= 1;
    end
end

always @(posedge clk) begin
    if(rst | l1i_flush_done_clr) begin
        l1i_flush_done <= 0;
    end
    else if(l1i_flush_done_set)begin
        l1i_flush_done <= 1;
    end
end

always @(posedge clk) begin
    if(rst | dtlb_flush_done_clr) begin
        dtlb_flush_done <= 0;
    end
    else if(dtlb_flush_done_set)begin
        dtlb_flush_done <= 1;
    end
end

always @(posedge clk) begin
    if(rst | itlb_flush_done_clr) begin
        itlb_flush_done <= 0;
    end
    else if(itlb_flush_done_set)begin
        itlb_flush_done <= 1;
    end
end

always @(posedge clk) begin
    if(rst | sfence_vma_asid_clr) begin
        sfence_vma_asid_vld_q <= 0;
        sfence_vma_asid_q <= 0;
    end
    else if(sfence_vma_asid_set)begin
        sfence_vma_asid_vld_q <= 1;
        sfence_vma_asid_q <= rcu_lsq_sfence_vma_asid_i;
    end
end
// prf wb
// TODO: stupid code, fix it later
always @(*) begin
    prf_wb_entry = 0;
    for(integer k = 0; k < LSQ_ENTRY_NUM; k ++) begin
        if(prf_wb_rd_addr_match[k] == 1) begin
            prf_wb_entry = k[LSQ_ENTRY_NUM_WIDTH - 1 : 0];
        end
    end
end

always @(posedge clk) begin
    if(rst) begin
        ld_issued_q <= 0;
        ld_issued_qq <= 0;
        ld_vld_q <= 0;
        ld_vld_qq <= 0;
        
    end
    else begin
        if(l1d_lsq_ld_replay_vld) begin
            ld_issued_q <= ld_issued_qq;
        end
        else if(lsq_l1d_ld_req_vld_o) begin
            ld_issued_q <= final_iss_bypass ? tail : final_iss;
        end
        ld_vld_q <= lsq_l1d_ld_req_vld_o;
        ld_vld_qq <= ld_vld_q;
        ld_issued_qq <= ld_issued_q;
    end
end

always @(posedge clk) begin
    if(rst) begin
        l1d_lsq_ld_replay_vld_q <= 0;
    end
    else begin
        l1d_lsq_ld_replay_vld_q <= l1d_lsq_ld_replay_vld_d;
    end
end

generate
    for(i = 0; i < LSQ_ENTRY_NUM; i = i + 1) begin: gen_lsq
        lsu_lsq_entry lsq_entry(
            .clk(clk), 
            .rst(rst), 
            .flush(flush),
             // <> RCU
            .lsq_entry_vld_i(lsq_entry_init_vld_vec[i]),
            .lsq_entry_invld_i(lsq_entry_deque_vec[i]),
            .lsq_entry_only_enque_i(lsq_entry_only_enque_vec[i]),
            .lsq_entry_vtag_i(lsq_entry_init_vtag),
            .lsq_entry_ls_i(rcu_lsq_ls_i),
            .lsq_entry_opcode_i(lsq_entry_init_opcode),
            .lsq_entry_fenced_i(rcu_lsq_fenced_i),
            .lsq_entry_index_i(lsq_entry_init_index),
            .lsq_entry_offset_i(lsq_entry_init_offset),
            .lsq_entry_rd_addr_i(rcu_lsq_rd_addr_i),
            .lsq_entry_data_i(rcu_lsq_data_i),
            .lsq_entry_rob_index_i(rcu_lsq_rob_index_i),
            .lsq_entry_exception_vld_i(lsq_s1_exception_vld),
            .lsq_entry_ecause_i(lsq_s1_ecause),
            // from tlb
            .dtlb_lsq_entry_vld_i(lsq_entry_tag_in_vld_vec[i]),
            .dtlb_lsq_entry_virt_i(lsq_entry_dtlb_virt),
            .dtlb_lsq_entry_tag_i(lsq_entry_dtlb_tag), 
            .dtlb_lsq_entry_exception_vld_i(dtlb_lsq_exception_vld_i),
            .dtlb_lsq_entry_ecause_i(dtlb_lsq_ecause_i),

            .lsq_entry_awake_i(lsq_entry_wakeup_vld_vec[i]),
            .lsq_entry_exec_i(lsq_entry_exec_vld_vec[i]),
            .lsq_entry_replay_i(lsq_entry_replay_vld_vec[i]),
            .lsq_entry_succ_i(lsq_entry_succ_vld_vec[i]),

            .lsq_entry_vld_o(lsq_entry_vld_vec[i]),
            .lsq_entry_ls_o(lsq_entry_ls_vec[i]),
            .lsq_entry_opcode_o(lsq_entry_opcode_vec[i]),
            .lsq_entry_fenced_o(lsq_entry_fenced_vec[i]),
            .lsq_entry_tag_o(lsq_entry_tag_vec[i]),
            .lsq_entry_index_o(lsq_entry_index_vec[i]),
            .lsq_entry_offset_o(lsq_entry_offset_vec[i]),
            .lsq_entry_rob_index_o(lsq_entry_rob_index_vec[i]),
            .lsq_entry_virt_o(lsq_entry_virt_vec[i]),
            .lsq_entry_awake_o(lsq_entry_awake_vec[i]),
            .lsq_entry_exec_o(lsq_entry_exec_vec[i]),
            .lsq_entry_succ_o(lsq_entry_succ_vec[i]),
            .lsq_entry_rd_addr_o(lsq_entry_rd_addr_vec[i]),
            .lsq_entry_data_o(lsq_entry_data_vec[i]),
            .lsq_entry_exception_vld_o(lsq_entry_exception_vld_vec[i]),
            .lsq_entry_ecause_o(lsq_entry_ecause_vec[i])
        );
    end

    for(i = 0; i < LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT + 1; i = i + 1) begin
        assign wb_arb_lsq_wb_rob_index[i] = wb_arb_lsq_wb_rob_index_i[(i + 1) * ROB_INDEX_WIDTH - 1 : i * ROB_INDEX_WIDTH];
    end

    for(i = 0; i < LSQ_ENTRY_NUM; i = i + 1) begin: gen_lsq_entry_one_hot_vec
        assign lsq_entry_wakeup_vld_vec[i] = rcu_lsq_wakeup_i & lsq_entry_vld_vec[i] &
                                            (rcu_lsq_wakeup_rob_index_i == lsq_entry_rob_index_vec[i]) 
                                            |
                                            rcu_lsq_wakeup_i & (rcu_lsq_wakeup_rob_index_i == rcu_lsq_rob_index_i) &
                                            lsq_enque & (i == tail)
                                            ;
        // FIXME: only works for 5 
        assign lsq_entry_wb_vld_vec[i] = wb_arb_lsq_wb_vld_i[0] & lsq_entry_vld_vec[i] & lsq_entry_no_prf_wb_vec[i] & 
                                        (wb_arb_lsq_wb_rob_index[0] == lsq_entry_rob_index_vec[i])
                                        |
                                        wb_arb_lsq_wb_vld_i[1] & lsq_entry_vld_vec[i] & lsq_entry_no_prf_wb_vec[i] &
                                        (wb_arb_lsq_wb_rob_index[1] == lsq_entry_rob_index_vec[i])
                                        |
                                        wb_arb_lsq_wb_vld_i[2] & lsq_entry_vld_vec[i] & lsq_entry_no_prf_wb_vec[i] &
                                        (wb_arb_lsq_wb_rob_index[2] == lsq_entry_rob_index_vec[i])
                                        |
                                        wb_arb_lsq_wb_vld_i[3] & lsq_entry_vld_vec[i] & lsq_entry_no_prf_wb_vec[i] &
                                        (wb_arb_lsq_wb_rob_index[3] == lsq_entry_rob_index_vec[i])
                                        |
                                        wb_arb_lsq_wb_vld_i[4] & lsq_entry_vld_vec[i] & lsq_entry_no_prf_wb_vec[i] &
                                        (wb_arb_lsq_wb_rob_index[4] == lsq_entry_rob_index_vec[i])
                                        |
                                        ~lsq_entry_no_prf_wb_vec[i] & lsq_entry_vld_vec[i] & wb_arb_lsq_prf_wb_vld_i &
                                        (wb_arb_lsq_prf_wb_rd_addr_i == lsq_entry_rd_addr_vec[i]);
        assign lsq_entry_succ_vld_vec[i] =  lsq_entry_wb_vld_vec[i] & ~lsq_entry_is_fence_req_vec[i] 
                                            |
                                            (
                                                (lsq_entry_opcode_vec[i] == STU_FENCE) & lsq_entry_wb_vld_vec[i] |
                                                (lsq_entry_opcode_vec[i] == STU_SFENCE_VMA) & dtlb_flush_done & itlb_flush_done |
                                                (lsq_entry_opcode_vec[i] == STU_FENCE_I) & l1d_flush_done & l1i_flush_done
                                            ) & lsq_entry_is_fence_req_vec[i]
                                            ;
        assign lsq_entry_deque_vec[i] = lsq_deque & (i == head);
        assign lsq_entry_enque_vec[i] = lsq_enque & (i == tail);
        assign lsq_entry_only_enque_vec[i] = lsq_enque & (i == tail) & (
                                                ((final_iss != i) & ~lsq_entry_ls_vec[i]) | 
                                                ((issued != i) & lsq_entry_ls_vec[i])
                                            );
        assign lsq_entry_init_vld_vec[i] = lsq_enque & (i == tail);
        assign lsq_entry_tag_in_vld_vec[i] = dtlb_lsq_vld_i & (i == issued);
        assign lsq_entry_exec_vld_vec[i] = lsq_last_iss_succ & (i == issued) & 
                                            (~lsq_entry_is_fence_req_vec[i] | lsq_entry_is_fence_req_vec[i] & (lsq_entry_opcode_vec[i] == STU_FENCE)) 
                                            |
                                            (i == issued) & lsq_entry_is_fence_req_vec[i] & (lsq_entry_opcode_vec[i] != STU_FENCE);

        assign lsq_entry_replay_vld_vec[i] = l1d_lsq_ld_replay_vld & (i == ld_issued_qq);

        assign lsq_entry_head_vec[i] = (i == head);
        assign lsq_entry_fenced_rdy_vec[i] = lsq_entry_fenced_barrier[i] & ~lsq_entry_fenced_vec[i] | lsq_entry_fence_req_rdy_vec[i] ;
        assign lsq_entry_is_fence_req_vec[i] = lsq_entry_ls_vec[i] && (lsq_entry_opcode_vec[i] == STU_FENCE || lsq_entry_opcode_vec[i] == STU_SFENCE_VMA || lsq_entry_opcode_vec[i] == STU_FENCE_I);
        assign lsq_entry_fence_req_rdy_vec[i] = lsq_entry_fenced_vec[i] & lsq_entry_first_fenced[i] & lsq_entry_fenced_vec[i] & (head == i);
        assign lsq_entry_fenced_vec_r[LSQ_ENTRY_NUM - i - 1] = lsq_entry_fenced_vec[i];
        assign lsq_entry_head_vec_r[LSQ_ENTRY_NUM - i - 1] = lsq_entry_head_vec[i];
        assign lsq_entry_vld_vec_r[LSQ_ENTRY_NUM - i - 1] = lsq_entry_vld_vec[i];
        assign lsq_entry_first_fenced[i] = lsq_entry_first_fenced_r[LSQ_ENTRY_NUM - i - 1];
        assign prf_wb_rd_addr_match[i] = lsq_entry_vld_vec[i] & (lsq_entry_rd_addr_vec[i] == wb_arb_lsq_prf_wb_rd_addr_i);
        assign lsq_entry_no_prf_wb_vec[i] = lsq_entry_vld_vec[i] & lsq_entry_ls_vec[i] &
                            (
                                lsq_entry_opcode_vec[i] == STU_SB || lsq_entry_opcode_vec[i] == STU_SH ||
                                lsq_entry_opcode_vec[i] == STU_SW || lsq_entry_opcode_vec[i] == STU_SD ||
                                lsq_entry_opcode_vec[i] == STU_FENCE || 
                                lsq_entry_opcode_vec[i] == STU_SFENCE_VMA ||
                                lsq_entry_opcode_vec[i] == STU_FENCE_I
                            ); 
    end
    /* verilator lint_off UNOPTFLAT */
    for(i = 0; i < LSQ_ENTRY_NUM; i = i + 1) begin: gen_lsq_entry_fenced_barrier_q
        assign lsq_entry_fenced_barrier_s[i] = (i == 0) ? 1 :
                                                    lsq_entry_fenced_barrier_s[i - 1] & ~lsq_entry_first_fenced_s[i - 1];
    end
    /* verilator lint_on UNOPTFLAT */

endgenerate


assign double_lsq_entry_first_fenced = {lsq_entry_first_fenced, lsq_entry_first_fenced};
assign double_lsq_entry_first_fenced_s = double_lsq_entry_first_fenced >> head;
assign double_lsq_entry_fenced_barrier_s = {lsq_entry_fenced_barrier_s, lsq_entry_fenced_barrier_s};
assign double_lsq_entry_fenced_barrier = double_lsq_entry_fenced_barrier_s << head;
assign lsq_entry_first_fenced_s = double_lsq_entry_first_fenced_s[LSQ_ENTRY_NUM - 1 : 0];
assign lsq_entry_fenced_barrier = double_lsq_entry_fenced_barrier[2 * LSQ_ENTRY_NUM - 1 : LSQ_ENTRY_NUM];

always @(posedge clk) begin
    if(rst | flush) begin
        lsq_l1d_iss_vld_q <= 0;
        lsq_l1d_st_iss_vld_q <= 0;
        lsq_l1d_iss_hsk_q <= 0; 
        lsq_bus_ctrl_iss_vld_q <= 0; 
        lsq_bus_ctrl_iss_hsk_q <= 0; 
        lsq_last_iss_succ_q <= 0;
    end 
    else begin
        lsq_l1d_iss_vld_q <= lsq_l1d_iss_vld_d;
        lsq_l1d_st_iss_vld_q <= lsq_l1d_st_iss_vld;
        lsq_l1d_iss_hsk_q <= lsq_l1d_iss_hsk_d;
        lsq_bus_ctrl_iss_vld_q <= lsq_bus_ctrl_iss_vld;
        lsq_bus_ctrl_iss_hsk_q <= lsq_bus_ctrl_iss_hsk_d;
        lsq_last_iss_succ_q <= lsq_last_iss_succ;
    end
end

always @(posedge clk) begin
    if(rst | flush) begin
        dtlb_vtag_q <= '0;
    end 
    else begin
        if(lsq_dtlb_iss_vld_o) begin
            dtlb_vtag_q <= lsq_dtlb_iss_vtag_o;
        end
    end
end

// 1 finder
arbiter_base #(
    .NUM_REQ(LSQ_ENTRY_NUM)
) first_fenced_arb(
    .req(lsq_entry_vld_vec_r & lsq_entry_fenced_vec_r),
    .base(lsq_entry_head_vec_r),
    .gnt(lsq_entry_first_fenced_r)
);
// head pointer
counter #(
    .CNT_SIZE(LSQ_ENTRY_NUM),
    .CNT_SIZE_WIDTH(LSQ_ENTRY_NUM_WIDTH)
) queue_head_cnt(
    .clk(clk),
    .rst(rst | flush),
    .cnt_add_flag_i(lsq_deque), 
    .cnt_rst_vector_i(0),
    .cnt_o(head),
    /* verilator lint_off PINCONNECTEMPTY */
    .cnt_end_o()
    /* verilator lint_on PINCONNECTEMPTY */
);
// tail pointer
counter #(
    .CNT_SIZE(LSQ_ENTRY_NUM),
    .CNT_SIZE_WIDTH(LSQ_ENTRY_NUM_WIDTH)
) queue_tail_cnt(
    .clk(clk),
    .rst(rst | flush),
    .cnt_add_flag_i(lsq_enque),
    .cnt_rst_vector_i(0),
    .cnt_o(tail),
    /* verilator lint_off PINCONNECTEMPTY */
    .cnt_end_o()
    /* verilator lint_on PINCONNECTEMPTY */
);
// req_pt emit pointer
counter2 #(
    .CNT_SIZE(LSQ_ENTRY_NUM),
    .CNT_SIZE_WIDTH(LSQ_ENTRY_NUM_WIDTH)
) queue_req_cnt(
    .clk(clk),
    .rst(rst | flush),
    .cnt_add_flag_i(lsq_last_iss_succ),
    .cnt_set_flag_i(l1d_lsq_ld_replay_vld),
    .cnt_rst_vector_i(0),
    .cnt_set_vector_i(ld_issued_qq),
    .cnt_o(issued),
    /* verilator lint_off PINCONNECTEMPTY */
    .cnt_end_o()
    /* verilator lint_on PINCONNECTEMPTY */
);
`ifdef LOG_LV1
always @(posedge clk) begin
    if(lsq_last_iss_succ) begin
        $display($realtime, ":\tLSU req sent. %s-%d\t@ 0x%x\tfenced:%d\trob_index:%d\trd_addr:%d\tdata:%x", 
            lsq_entry_ls_vec[issued] ? "st" : "ld", 
            lsq_entry_opcode_vec[issued], 
            {lsq_entry_tag_vec[issued], lsq_entry_index_vec[issued], lsq_entry_offset_vec[issued]},
            lsq_entry_fenced_vec[issued], lsq_entry_rob_index_vec[issued], lsq_entry_rd_addr_vec[issued], 
            lsq_entry_data_vec[issued]
        );
    end 
`ifdef LOG_LV2
`endif // LOG_LV2
end
`endif //LOG_LV1
endmodule

`endif // _LSU_LSQ_V_
