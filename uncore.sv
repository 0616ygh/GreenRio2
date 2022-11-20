`ifdef USE_VERILATOR
`include "./params.vh"
`include "./include/riscv_pkg.sv"
`include "./include/rvh_pkg.sv"
`include "./include/rvh_l1d_pkg.sv"
`include "./include/uop_encoding_pkg.sv"
`endif //USE_VERILATOR
module uncore
import rvh_pkg::*;
    import riscv_pkg::*;
    import uop_encoding_pkg::*;
    // import rvh_lsu_pkg::*;
    import rvh_l1d_pkg::*;
#(
  parameter PAGETABLE_BASE_ADDR = 56'h10000000,
  parameter EBI_WIDTH = 16

)
(
    // <> top
    input                                                                                                                       clk,
    input                                                                                                                       rst,
    input                                                                                                                       flush,

    // <> RCU               
    output                                                                                                                      lsu_rcu_rdy_o,
    input                                                                                                                       rcu_lsu_vld_i,
    input                                                                                                                       rcu_lsu_ls_i,
    input  [LDU_OP_WIDTH - 1 : 0]                                                                                               rcu_lsu_ld_opcode_i,
    input  [STU_OP_WIDTH - 1 : 0]                                                                                               rcu_lsu_st_opcode_i,
    input                                                                                                                       rcu_lsu_fenced_i,
    input  [XLEN - 1 : 0]                                                                                                       rcu_lsu_virt_base_i,
    input  [XLEN - 1 : 0]                                                                                                       rcu_lsu_virt_offset_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                                                            rcu_lsu_rob_index_i,
    input  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                                         rcu_lsu_rd_addr_i,
    input  [XLEN - 1 : 0]                                                                                                       rcu_lsu_data_i,
    input                                                                                                                       rcu_lsu_wakeup_vld_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                                                            rcu_lsu_wakeup_rob_index_i,
    output                                                                                                                      lsu_rcu_comm_vld_o,
    output [ROB_INDEX_WIDTH - 1 : 0]                                                                                            lsu_rcu_comm_rob_index_o,
    output [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                                         lsu_rcu_comm_rd_addr_o,
    output [XLEN - 1 : 0]                                                                                                       lsu_rcu_comm_data_o,
    output                                                                                                                      lsu_rcu_exception_vld_o,
    output [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                                                      lsu_rcu_ecause_o,
    //cache
    //AR
    input                                                 l2_req_if_arready_i,
    output                                                l2_req_if_arvalid_o,
    output   [PADDR_WIDTH-1:0]                            araddr_o,
    output   [3:0]                                        arsnoop_o,

    // AW                         
    input                                                 l2_req_if_awready_i,
    output                                                l2_req_if_awvalid_o,
    output   [PADDR_WIDTH-1:0]                            awaddr_o,
    output   [1:0]                                        awmesi_o,

    // W                          
    input                                                 l2_req_if_wready_i,
    output                                                l2_req_if_wvalid_o,
    output   [MEM_DATA_WIDTH-1:0]                             wdata_o,

    // R                          
    input                                                 l2_resp_if_rvalid_i,
    output                                                l2_resp_if_rready_o,
    input  [MEM_DATA_WIDTH-1:0]                               rdata_i,
    input  [1:0]                                          mesi_sta_i 
    );
localparam LSQ_ENTRY_NUM = 8;
localparam MEMORY_PORT_NUM = 1;
localparam REQ_ENQUE_BASE_DELAY = 100;
localparam REQ_ENQUE_MAX_DELAY = 1;



//                                                      
// <> PRF                                                       
wire                                                                                                lsu_rcu_prf_wb_vld;
wire  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                                  lsu_rcu_comm_rd_addr;
wire  [XLEN - 1 : 0]                                                                                lsu_rcu_comm_data;
    
// <> TLB                                                   
wire                                                                                                dtlb_lsu_rdy;
wire                                                                                                dtlb_lsu_vld; // should be the lsu_dtlb_iss_vld_o in last cycle
wire                                                                                                dtlb_lsu_hit;
wire  [PHYSICAL_ADDR_TAG_LEN - 1 : 0]                                                               dtlb_lsu_ptag;
wire                                                                                                dtlb_lsu_exception_vld;
wire  [EXCEPTION_CAUSE_WIDTH - 1 : 0]                                                               dtlb_lsu_ecause;
wire                                                                                                lsu_dtlb_iss_vld;
wire [VIRTUAL_ADDR_TAG_LEN - 1 : 0]                                                                 lsu_dtlb_iss_vtag;
wire [PMP_ACCESS_TYPE_WIDTH - 1 : 0]                                                                lsu_dtlb_iss_type;
    
// <> l1d   
// Load request                                                 
wire   [LSU_ADDR_PIPE_COUNT-1:0]                                                                    l1d_lsu_ld_req_rdy;
wire                                                                                                lsu_l1d_ld_req_vld;
wire  [     ROB_INDEX_WIDTH - 1 : 0]                                                                lsu_l1d_ld_req_rob_index;
wire  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                              lsu_l1d_ld_req_rd_addr; // no need
wire  [      LDU_OP_WIDTH - 1 : 0]                                                                  lsu_l1d_ld_req_opcode;
wire  [       ADDR_INDEX_LEN - 1 : 0]                                                               lsu_l1d_ld_req_index; 
wire  [      ADDR_OFFSET_LEN - 1 : 0]                                                               lsu_l1d_ld_req_offset; 
wire  [     VIRTUAL_ADDR_TAG_LEN -1 : 0]                                                            lsu_l1d_ld_req_vtag; 
// Store request                                                    
wire  [LSU_ADDR_PIPE_COUNT-1:0]                                                                     l1d_lsu_st_req_rdy;
wire                                                                                                lsu_l1d_st_req_vld;
wire                                                                                                lsu_l1d_st_req_is_fence;
wire  [     ROB_INDEX_WIDTH - 1 : 0]                                                                lsu_l1d_st_req_rob_index;
wire  [    PHY_REG_ADDR_WIDTH - 1 : 0]                                                              lsu_l1d_st_req_rd_addr;
wire  [      STU_OP_WIDTH - 1 : 0]                                                                  lsu_l1d_st_req_opcode; 
wire  [       PHYSICAL_ADDR_LEN - 1 : 0]                                                            lsu_l1d_st_req_paddr; 
wire  [              XLEN - 1 : 0]                                                                  lsu_l1d_st_req_data;
// ld replay: 1. mshr full or 2. stb partial hit                                                     
wire  [LSU_ADDR_PIPE_COUNT-1:0]                                                                     l1d_lsu_ld_replay_vld;
// wb       
wire  [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                           l1d_lsu_wb_vld;
wire  [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]                       l1d_lsu_wb_rob_index;
wire  [LSU_DATA_PIPE_COUNT - 1 : 0]                                                                 l1d_lsu_prf_wb_vld;
wire  [PHY_REG_ADDR_WIDTH * LSU_DATA_PIPE_COUNT - 1 : 0]                                            l1d_lsu_prf_wb_rd_addr;
wire  [XLEN*LSU_DATA_PIPE_COUNT - 1 : 0]                                                            l1d_lsu_prf_wb_data;
// kill                                                     
wire                                                                                                lsu_l1d_kill_req;

wire                                                                       ls_pipe_l1d_dtlb_resp_vld;
wire [         PPN_WIDTH-1:0]                                              ls_pipe_l1d_dtlb_resp_ppn;
wire                                                                       ls_pipe_l1d_dtlb_resp_excp_vld;
wire                                                                       ls_pipe_l1d_dtlb_resp_hit;
wire                                                                       ls_pipe_l1d_dtlb_resp_miss;

// mmu & dtlb
// priv lvl
wire       [                 1:0]                  priv_lvl;
// stap                 
wire       [                 3:0]                  satp_mode;
wire       [      ASID_WIDTH-1:0]                  satp_asid;
wire       [       PPN_WIDTH-1:0]                  satp_ppn;
                
wire       [            XLEN-1:0]                  misc_mstatus;

// PMP Configuration Port
wire                                               pmp_cfg_set_vld;
wire       [ PMPCFG_ID_WIDTH-1:0]                  pmp_cfg_set_addr;
wire       [                63:0]                  pmp_cfg_set_payload;
wire      [                63:0]                   pmp_cfg_origin_payload;
wire                                               pmp_addr_set_vld;
wire       [PMPADDR_ID_WIDTH-1:0]                  pmp_addr_set_addr;
wire       [                63:0]                  pmp_addr_set_payload;
wire      [                63:0]                   pmp_addr_origin_payload; 




// DTLB Translate Port -> Request
wire [TRANSLATE_WIDTH-1:0]                         dtlb_translate_req_vld;
wire [TRANSLATE_WIDTH-1:0][1:0]                    dtlb_translate_req_access_type;
wire [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0]          dtlb_translate_req_vpn;
wire [TRANSLATE_WIDTH-1:0]                         dtlb_translate_req_rdy;
// DTLB Translate Port -> Response
wire [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_vld;
wire [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0]          dtlb_translate_resp_ppn;
wire [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_excp_vld;
wire [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0]   dtlb_translate_resp_excp_cause;
wire [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_miss;
wire [TRANSLATE_WIDTH-1:0]                         dtlb_translate_resp_hit;

// ITLB Translate Port -> Request
wire [TRANSLATE_WIDTH-1:0]                         itlb_translate_req_vld;
// MODE == Read(Execute)
// wire [TRANSLATE_WIDTH-1:0][1:0] itlb_translate_req_access_type;
wire [TRANSLATE_WIDTH-1:0][VPN_WIDTH-1:0]          itlb_translate_req_vpn;
wire [TRANSLATE_WIDTH-1:0]                         itlb_translate_req_rdy;
// ITLB Translate Port -> Response
wire [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_vld;
wire [TRANSLATE_WIDTH-1:0][PPN_WIDTH-1:0]          itlb_translate_resp_ppn;
wire [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_excp_vld;
wire [TRANSLATE_WIDTH-1:0][EXCP_CAUSE_WIDTH-1:0]   itlb_translate_resp_excp_cause;
wire [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_miss;
wire [TRANSLATE_WIDTH-1:0]                         itlb_translate_resp_hit;


// dtlb shoot down
wire                                               dtlb_flush_vld;
wire                                               dtlb_flush_use_asid;
wire                                               dtlb_flush_use_vpn;
wire [VPN_WIDTH-1:0]                               dtlb_flush_vpn;
wire [ASID_WIDTH-1:0]                              dtlb_flush_asid;
wire                                               dtlb_flush_grant;
// itlb shoot down
wire                                               itlb_flush_vld;
wire                                               itlb_flush_use_asid;
wire                                               itlb_flush_use_vpn;
wire [VPN_WIDTH-1:0]                               itlb_flush_vpn;
wire [ASID_WIDTH-1:0]                              itlb_flush_asid;
wire                                               itlb_flush_grant;

wire                                               tlb_flush_grant;


// ptw walk request port
wire                                               ptw_walk_req_vld;
wire [PTW_ID_WIDTH-1:0]                            ptw_walk_req_id;
wire [PADDR_WIDTH-1:0]                             ptw_walk_req_addr;
wire                                               ptw_walk_req_rdy;
// ptw walk response port
wire                                               ptw_walk_resp_vld;
wire [PTE_WIDTH-1:0]                               ptw_walk_resp_pte;
wire                                               ptw_walk_resp_rdy;

logic              l1d_ebi_req_arvalid;
logic              l1d_ebi_req_arready;
cache_mem_if_ar_t  l1d_ebi_req_ar;
// ewrq -> mem bus
// AW 
logic              l1d_ebi_req_awvalid;
logic              l1d_ebi_req_awready;
cache_mem_if_aw_t  l1d_ebi_req_aw;
// W 
logic              l1d_ebi_req_wvalid;
logic              l1d_ebi_req_wready;
cache_mem_if_w_t   l1d_ebi_req_w;
// L1D -> L2 : Response
// B
/* verilator lint_off UNDRIVEN */
logic              ebi_l1d_resp_bvalid;
logic              ebi_l1d_resp_bready;
cache_mem_if_b_t   ebi_l1d_resp_b;
// mem bus -> mlfb
// R
logic              ebi_l1d_resp_rvalid;
logic              ebi_l1d_resp_rready;
cache_mem_if_r_t    ebi_l1d_resp_r;
/* verilator lint_on UNDRIVEN */



wire   [PADDR_WIDTH-1:0]    l1d_ebi_req_araddr;
wire   [PADDR_WIDTH-1:0]    l1d_ebi_req_awaddr;
wire   [MEM_DATA_WIDTH-1:0]           l1d_ebi_req_wdata;
wire   [MEM_DATA_WIDTH-1:0]           ebi_l1d_req_rdata;

assign l1d_ebi_req_araddr = l1d_ebi_req_ar.araddr;
assign l1d_ebi_req_awaddr = l1d_ebi_req_aw.awaddr;
assign l1d_ebi_req_wdata = l1d_ebi_req_w.wdata;
assign ebi_l1d_resp_r.err = 0;
assign ebi_l1d_resp_r.dat = ebi_l1d_req_rdata;


wire  [EBI_WIDTH-1:0]     ebi_i;
wire  [EBI_WIDTH-1:0]     ebi_o;
wire  [EBI_WIDTH-1:0]     ebi_oen;  // 0的时候为输出,默认为1
// master/slave switch
wire                      bus_switch_i;
wire                      bus_switch_o;
wire                      bus_switch_oen;  //slave输出,master监听

lsuv1 #(
    .LSQ_ENTRY_NUM(LSQ_ENTRY_NUM),
    .LSQ_ENTRY_NUM_WIDTH($clog2(LSQ_ENTRY_NUM))
)lsu(
    .clk(clk),
    .rst(rst),
    .flush('0),

    // <> top
    .lsu_rdy_o(lsu_rcu_rdy_o),
    .rcu_lsu_vld_i(rcu_lsu_vld_i),
    .rcu_lsu_ls_i(rcu_lsu_ls_i),
    .rcu_lsu_ld_opcode_i(rcu_lsu_ld_opcode_i),
    .rcu_lsu_st_opcode_i(rcu_lsu_st_opcode_i),
    .rcu_lsu_fenced_i(rcu_lsu_fenced_i),
    .rcu_agu_virt_base_i(rcu_lsu_virt_base_i),
    .rcu_agu_virt_offset_i(rcu_lsu_virt_offset_i),
    .rcu_lsu_rob_index_i(rcu_lsu_rob_index_i),
    .rcu_lsu_rd_addr_i(rcu_lsu_rd_addr_i),
    .rcu_lsu_data_i(rcu_lsu_data_i),
    .rcu_lsu_wakeup_i(rcu_lsu_wakeup_vld_i & lsu_rcu_rdy_o),
    .rcu_lsu_wakeup_rob_index_i(rcu_lsu_wakeup_rob_index_i),
    .lsu_rcu_comm_vld_o(lsu_rcu_comm_vld_o),
    .lsu_rcu_comm_rob_index_o(lsu_rcu_comm_rob_index_o),
    .lsu_rcu_comm_rd_addr_o(lsu_rcu_comm_rd_addr_o),
    .lsu_rcu_comm_data_o(lsu_rcu_comm_data_o),
    .lsu_rcu_exception_vld_o(lsu_rcu_exception_vld_o),
    .lsu_rcu_ecause_o(lsu_rcu_ecause_o),
    // <> dtlb
    .dtlb_lsu_rdy_i(dtlb_lsu_rdy),
    .dtlb_lsu_vld_i(dtlb_lsu_vld),
    .dtlb_lsu_hit_i(dtlb_lsu_hit),
    .dtlb_lsu_ptag_i(dtlb_lsu_ptag),
    .dtlb_lsu_exception_vld_i(dtlb_lsu_exception_vld),
    .dtlb_lsu_ecause_i(dtlb_lsu_ecause),
    .lsu_dtlb_iss_vld_o(lsu_dtlb_iss_vld),
    .lsu_dtlb_iss_vtag_o(lsu_dtlb_iss_vtag),
    .lsu_dtlb_iss_type_o(lsu_dtlb_iss_type),
    // <> l1d
    .l1d_lsu_ld_req_rdy_i(l1d_lsu_ld_req_rdy[0]),
    .lsu_l1d_ld_req_vld_o(lsu_l1d_ld_req_vld),
    .lsu_l1d_ld_req_rob_index_o(lsu_l1d_ld_req_rob_index),
    .lsu_l1d_ld_req_rd_addr_o(lsu_l1d_ld_req_rd_addr),
    .lsu_l1d_ld_req_opcode_o(lsu_l1d_ld_req_opcode),
    .lsu_l1d_ld_req_index_o(lsu_l1d_ld_req_index),
    .lsu_l1d_ld_req_offset_o(lsu_l1d_ld_req_offset),
    .lsu_l1d_ld_req_vtag_o(lsu_l1d_ld_req_vtag),

    .l1d_lsu_st_req_rdy_i(l1d_lsu_st_req_rdy[0]),
    .lsu_l1d_st_req_vld_o(lsu_l1d_st_req_vld),
    .lsu_l1d_st_req_is_fence_o(lsu_l1d_st_req_is_fence),
    .lsu_l1d_st_req_rob_index_o(lsu_l1d_st_req_rob_index),
    .lsu_l1d_st_req_rd_addr_o(lsu_l1d_st_req_rd_addr),
    .lsu_l1d_st_req_opcode_o(lsu_l1d_st_req_opcode),
    .lsu_l1d_st_req_paddr_o(lsu_l1d_st_req_paddr),
    .lsu_l1d_st_req_data_o(lsu_l1d_st_req_data),

    .l1d_lsu_ld_replay_vld_i(l1d_lsu_ld_replay_vld[0]),
    
    .l1d_lsu_wb_vld_i(l1d_lsu_wb_vld),
    .l1d_lsu_wb_rob_index_i(l1d_lsu_wb_rob_index),
    .l1d_lsu_prf_wb_vld_i(l1d_lsu_prf_wb_vld),
    .l1d_lsu_prf_wb_rd_addr_i(l1d_lsu_prf_wb_rd_addr),
    .l1d_lsu_prf_wb_data_i(l1d_lsu_prf_wb_data),

    .lsu_l1d_kill_req_o(lsu_l1d_kill_req),
/* verilator lint_off PINCONNECTEMPTY */
`ifdef LSU_DEBUG
    .lsu_debug_head_o(),
    .lsu_debug_tail_o(),
    .lsu_debug_issued_o(),
    .lsu_debug_iss_vld_o(),
    .lsu_debug_iss_is_fenced_o(),
    .lsu_debug_iss_lsq_index_o(),
    .lsu_debug_dtlb_miss_kill_o(),
    .lsu_debug_l1d_s1_kill_o(),
`endif // LSU_DEBUG   
/* verilator lint_on PINCONNECTEMPTY */

/* verilator lint_off PINCONNECTEMPTY */
    // <> bus
    .lsu_wb_cyc_o(),
    .lsu_wb_stb_o(),
    .lsu_wb_we_o(),
    .lsu_wb_adr_o(),
    .lsu_wb_dat_o(),
    .lsu_wb_sel_o(),
    .wb_lsu_ack_i('0),
    .wb_lsu_dat_i('0)
/* verilator lint_on PINCONNECTEMPTY */
);

rvh_l1d l1d(
    .ls_pipe_l1d_ld_req_vld_i({1'b0, lsu_l1d_ld_req_vld}),
    .ls_pipe_l1d_ld_req_io_i('0),
    .ls_pipe_l1d_ld_req_rob_tag_i({{ROB_TAG_WIDTH{1'b0}}, lsu_l1d_ld_req_rob_index}),
    .ls_pipe_l1d_ld_req_prd_i({{PHY_REG_ADDR_WIDTH{1'b0}}, lsu_l1d_ld_req_rd_addr}),
    .ls_pipe_l1d_ld_req_opcode_i({{LDU_OP_WIDTH{1'b0}}, lsu_l1d_ld_req_opcode}),
    .ls_pipe_l1d_ld_req_index_i({{L1D_INDEX_WIDTH{1'b0}}, lsu_l1d_ld_req_index}), //
    .ls_pipe_l1d_ld_req_offset_i({{L1D_OFFSET_WIDTH{1'b0}}, lsu_l1d_ld_req_offset}), //
    .ls_pipe_l1d_ld_req_vtag_i({{L1D_TAG_WIDTH{1'b0}}, lsu_l1d_ld_req_vtag}), // vtag
    .ls_pipe_l1d_ld_req_rdy_o(l1d_lsu_ld_req_rdy),

    // LS Pipe -> D$ : DTLB response
    .ls_pipe_l1d_dtlb_resp_vld_i({1'b0, ls_pipe_l1d_dtlb_resp_vld}),
    .ls_pipe_l1d_dtlb_resp_ppn_i({{PPN_WIDTH{1'b0}}, ls_pipe_l1d_dtlb_resp_ppn}),
    .ls_pipe_l1d_dtlb_resp_excp_vld_i({1'b0, ls_pipe_l1d_dtlb_resp_excp_vld}),
    .ls_pipe_l1d_dtlb_resp_hit_i({1'b0, ls_pipe_l1d_dtlb_resp_hit}),
    .ls_pipe_l1d_dtlb_resp_miss_i({1'b0, ls_pipe_l1d_dtlb_resp_miss}),

    // LS Pipe -> D$ : Store request
    .ls_pipe_l1d_st_req_vld_i({1'b0, lsu_l1d_st_req_vld}),
    .ls_pipe_l1d_st_req_io_i('0),
    .ls_pipe_l1d_st_req_is_fence_i({1'b0, lsu_l1d_st_req_is_fence}),
    .ls_pipe_l1d_st_req_rob_tag_i({{ROB_TAG_WIDTH{1'b0}}, lsu_l1d_st_req_rob_index}),
    .ls_pipe_l1d_st_req_prd_i({{PHY_REG_ADDR_WIDTH{1'b0}},lsu_l1d_st_req_rd_addr}),
    .ls_pipe_l1d_st_req_opcode_i({{STU_OP_WIDTH{1'b0}},lsu_l1d_st_req_opcode}),
   .ls_pipe_l1d_st_req_paddr_i({{PHYSICAL_ADDR_LEN{1'b0}},lsu_l1d_st_req_paddr}), //
   .ls_pipe_l1d_st_req_data_i({{XLEN{1'b0}},lsu_l1d_st_req_data}),
   .ls_pipe_l1d_st_req_rdy_o(l1d_lsu_st_req_rdy),
    // L1D -> LS Pipe ld replay: 1. mshr full or 2. stb partial hit 
    .l1d_ls_pipe_ld_replay_valid_o(l1d_lsu_ld_replay_vld),


    // LS Pipe -> L1D : Kill D-Cache Response
    .ls_pipe_l1d_kill_resp_i({1'b0, lsu_l1d_kill_req}),
    // D$ -> ROB : Write Back
    .l1d_rob_wb_vld_o(l1d_lsu_wb_vld),
    .l1d_rob_wb_rob_tag_o(l1d_lsu_wb_rob_index),
    // D$ -> Int PRF : Write Back
    .l1d_int_prf_wb_vld_o(l1d_lsu_prf_wb_vld),
    .l1d_int_prf_wb_tag_o(l1d_lsu_prf_wb_rd_addr),
    .l1d_int_prf_wb_data_o(l1d_lsu_prf_wb_data),


    // ptw walk request port
    .ptw_walk_req_vld_i(ptw_walk_req_vld),
    .ptw_walk_req_id_i('0),
    .ptw_walk_req_addr_i(ptw_walk_req_addr),
    .ptw_walk_req_rdy_o(ptw_walk_req_rdy),
    // ptw walk response port
    .ptw_walk_resp_vld_o(ptw_walk_resp_vld),
/* verilator lint_off PINCONNECTEMPTY */
    .ptw_walk_resp_id_o(),
/* verilator lint_on PINCONNECTEMPTY */
    .ptw_walk_resp_pte_o(ptw_walk_resp_pte),
    .ptw_walk_resp_rdy_i(ptw_walk_resp_rdy),

    // L1D -> L2 : Request
      // mshr -> mem bus
      // AR
    .l1d_l2_req_arvalid_o(l1d_ebi_req_arvalid),
    .l1d_l2_req_arready_i(l1d_ebi_req_arready),
    .l1d_l2_req_ar_o(l1d_ebi_req_ar),
      // ewrq -> mem bus
      // AW 
    .l1d_l2_req_awvalid_o(l1d_ebi_req_awvalid),
    .l1d_l2_req_awready_i(l1d_ebi_req_awready),
    .l1d_l2_req_aw_o(l1d_ebi_req_aw),
      // W 
    .l1d_l2_req_wvalid_o(l1d_ebi_req_wvalid),
    .l1d_l2_req_wready_i(l1d_ebi_req_wready),
    .l1d_l2_req_w_o(l1d_ebi_req_w),
    // L1D -> L2 : Response
      // B
    .l2_l1d_resp_bvalid_i(ebi_l1d_resp_bvalid),
    .l2_l1d_resp_bready_o(ebi_l1d_resp_bready),
    .l2_l1d_resp_b_i(ebi_l1d_resp_b),
      // mem bus -> mlfb
      // R
    .l2_l1d_resp_rvalid_i(ebi_l1d_resp_rvalid),
    .l2_l1d_resp_rready_o(ebi_l1d_resp_rready),
    .l2_l1d_resp_r_i(ebi_l1d_resp_r),


    .rob_flush_i('0),
/* verilator lint_off PINCONNECTEMPTY */
    .fencei_flush_vld_i('0),
    .fencei_flush_grant_o(),
/* verilator lint_on PINCONNECTEMPTY */

    .clk(clk),
    .rst(~rst)
);


assign dtlb_translate_req_vld = lsu_dtlb_iss_vld;
assign dtlb_translate_req_access_type = lsu_dtlb_iss_type;
assign dtlb_translate_req_vpn = lsu_dtlb_iss_vtag;
assign dtlb_lsu_rdy = dtlb_translate_req_rdy;
assign dtlb_lsu_vld = dtlb_translate_resp_vld; // should be the lsu_dtlb_iss_vld_o in last cycle
assign dtlb_lsu_hit = dtlb_translate_resp_hit;
assign dtlb_lsu_ptag = dtlb_translate_resp_ppn;
assign dtlb_lsu_exception_vld = dtlb_translate_resp_excp_vld;
assign dtlb_lsu_ecause = dtlb_translate_resp_excp_cause;
assign ls_pipe_l1d_dtlb_resp_vld = dtlb_translate_resp_vld;
assign ls_pipe_l1d_dtlb_resp_ppn = dtlb_translate_resp_ppn;
assign ls_pipe_l1d_dtlb_resp_excp_vld = dtlb_translate_resp_excp_vld;
assign ls_pipe_l1d_dtlb_resp_hit = dtlb_translate_resp_hit;
assign ls_pipe_l1d_dtlb_resp_miss = dtlb_translate_resp_miss;
rvh_monolithic_mmu #(
    .PADDR_WIDTH(PHYSICAL_ADDR_LEN)
) mmu
(
     // priv lvl
    .priv_lvl_i(2'b00),// u mode
    // stap
    .satp_mode_i(4'h8), // 
    .satp_asid_i('0),
    .satp_ppn_i((PAGETABLE_BASE_ADDR[PHYSICAL_ADDR_TAG_UPP - 1: PHYSICAL_ADDR_TAG_LOW])), 

    .misc_mstatus_i(0),

    // disable pmp
    // PMP Configuration Port
/* verilator lint_off PINCONNECTEMPTY */
    .pmp_cfg_set_vld_i(0),
    .pmp_cfg_set_addr_i(0),
    .pmp_cfg_set_payload_i(0),
    .pmp_cfg_origin_payload_o(),
    .pmp_addr_set_vld_i(0),
    .pmp_addr_set_addr_i(0),
    .pmp_addr_set_payload_i(0),
    .pmp_addr_origin_payload_o(), 
/* verilator lint_on PINCONNECTEMPTY */

    // DTLB Translate Port -> Request
    .dtlb_translate_req_vld_i(dtlb_translate_req_vld),
    .dtlb_translate_req_access_type_i(dtlb_translate_req_access_type),
    .dtlb_translate_req_vpn_i(dtlb_translate_req_vpn),
    .dtlb_translate_req_rdy_o(dtlb_translate_req_rdy),
    // DTLB Translate Port -> Response
    .dtlb_translate_resp_vld_o(dtlb_translate_resp_vld),
    .dtlb_translate_resp_ppn_o(dtlb_translate_resp_ppn),
    .dtlb_translate_resp_excp_vld_o(dtlb_translate_resp_excp_vld),
    .dtlb_translate_resp_excp_cause_o(dtlb_translate_resp_excp_cause),
    .dtlb_translate_resp_miss_o(dtlb_translate_resp_miss),
    .dtlb_translate_resp_hit_o(dtlb_translate_resp_hit),

    // ITLB Translate Port -> Request
    .itlb_translate_req_vld_i('0),
    // MODE == Read(Execute)
    // input [TRANSLATE_WIDTH-1:0][1:0] itlb_translate_req_access_type_i(),
    .itlb_translate_req_vpn_i('0),
/* verilator lint_off PINCONNECTEMPTY */
    .itlb_translate_req_rdy_o(),
    // ITLB Translate Port -> Response
    .itlb_translate_resp_vld_o(),
    .itlb_translate_resp_ppn_o(),
    .itlb_translate_resp_excp_vld_o(),
    .itlb_translate_resp_excp_cause_o(),
    .itlb_translate_resp_miss_o(),
    .itlb_translate_resp_hit_o(),


    // dtlb shoot down
    .dtlb_flush_vld_i('0),
    .dtlb_flush_use_asid_i('0),
    .dtlb_flush_use_vpn_i('0),
    .dtlb_flush_vpn_i('0),
    .dtlb_flush_asid_i('0),
    .dtlb_flush_grant_o(),
    // itlb shoot down
    .itlb_flush_vld_i('0),
    .itlb_flush_use_asid_i('0),
    .itlb_flush_use_vpn_i('0),
    .itlb_flush_vpn_i('0),
    .itlb_flush_asid_i('0),
    .itlb_flush_grant_o(),

    .tlb_flush_grant_o(),

/* verilator lint_on PINCONNECTEMPTY */

    // ptw walk request port
    .ptw_walk_req_vld_o(ptw_walk_req_vld),
    .ptw_walk_req_id_o(ptw_walk_req_id),
    .ptw_walk_req_addr_o(ptw_walk_req_addr),
    .ptw_walk_req_rdy_i(ptw_walk_req_rdy),
    // ptw walk response port
    .ptw_walk_resp_vld_i(ptw_walk_resp_vld),
    .ptw_walk_resp_pte_i(ptw_walk_resp_pte),
    .ptw_walk_resp_rdy_o(ptw_walk_resp_rdy),

    .clk(clk),
    .rstn(~rst)
);
inner_ebi #(
  .PADDR_WIDTH(PHYSICAL_ADDR_LEN)
)inner_ebi_u(
  //clk and rstn
    .clk(clk),
    .rst(rst),          
    
    .l2_req_if_arready_o(l1d_ebi_req_arready),
    .l2_req_if_arvalid_i(l1d_ebi_req_arvalid),
    .araddr_i(l1d_ebi_req_araddr),
    .arsnoop_i(0),

    
    .l2_req_if_awready_o(l1d_ebi_req_awready),
    .l2_req_if_awvalid_i(l1d_ebi_req_awvalid),
    .awaddr_i(l1d_ebi_req_awaddr),
    .awmesi_i(0),

    
    .l2_req_if_wready_o(l1d_ebi_req_wready),
    .l2_req_if_wvalid_i(l1d_ebi_req_wvalid),
    .wdata_i(l1d_ebi_req_wdata),

    
    .l2_resp_if_rvalid_o(ebi_l1d_resp_rvalid),
    .l2_resp_if_rready_i(ebi_l1d_resp_rready),
    .rdata_o(ebi_l1d_req_rdata),
    .mesi_sta_o(),

    
    .l2_req_if_snready_i(1),
    .l2_req_if_snvalid_o(),
    .sn_req_addr(),
    .sn_req_snoop(),

    
    .l2_resp_if_snready_o(),
    .l2_resp_if_snvalid_i(0),
    .sn_resp_has_data(),
    .sn_resp_dat(),
    .ack(),  // = ~sn_resp_has_data


    
    .ebi_i(ebi_i),
    .ebi_o(ebi_o),
    .ebi_oen(ebi_oen),  // 0的时候为输出(),默认为1

    
    .bus_switch_i(bus_switch_i),
    .bus_switch_o(bus_switch_o),
    .bus_switch_oen(bus_switch_oen)
);
outer_ebi#(
  .PADDR_WIDTH(PHYSICAL_ADDR_LEN)
)outer_ebi_u(
    //clk and rstn
    .clk(clk),
    .rst(rst),          
  
  
  
    .l2_req_if_arready_i(l2_req_if_arready_i),
    .l2_req_if_arvalid_o(l2_req_if_arvalid_o),
    .araddr_o(araddr_o),
    .arsnoop_o(arsnoop_o),
  
  
    .l2_req_if_awready_i(l2_req_if_awready_i),
    .l2_req_if_awvalid_o(l2_req_if_awvalid_o),
    .awaddr_o(awaddr_o),
    .awmesi_o(awmesi_o),
  
  
    .l2_req_if_wready_i(l2_req_if_wready_i),
    .l2_req_if_wvalid_o(l2_req_if_wvalid_o),
    .wdata_o(wdata_o),
  
  
    .l2_resp_if_rvalid_i(l2_resp_if_rvalid_i),
    .l2_resp_if_rready_o(l2_resp_if_rready_o),
    .rdata_i(rdata_i),
    .mesi_sta_i(mesi_sta_i),
  
  
    .l2_req_if_snready_o(),
    .l2_req_if_snvalid_i(0),
    .sn_req_addr(),
    .sn_req_snoop(),
  
  
    .l2_resp_if_snready_i(1),
    .l2_resp_if_snvalid_o(),
    .sn_resp_has_data(),
    .sn_resp_dat(),
    .ack(),  // = ~sn_resp_has_data
  
  
  
    .ebi_i(ebi_o),
    .ebi_o(ebi_i),
    .ebi_oen(ebi_oen),  // 0的时候为输出,默认为1
  
  
    .bus_switch_i(bus_switch_o),
    .bus_switch_o(bus_switch_i),
    .bus_switch_oen(bus_switch_oen)  //slave输出,master监听
);
endmodule
