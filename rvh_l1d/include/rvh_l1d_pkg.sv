`ifndef __RVH_L1D_PKG_SV__
`define __RVH_L1D_PKG_SV__
`ifdef USE_VERILATOR
`include "./rvh_pkg.sv"
`include "./uop_encoding_pkg.sv"
`endif //USE_VERILATOR
package rvh_l1d_pkg;
import rvh_pkg::*;
import uop_encoding_pkg::*;
localparam L1D_BANK_LINE_DATA_SIZE = L1D_LINE_SIZE * 8; // bits

localparam L1D_BANK_SET_NUM = L1D_BANK_SET_COUNT; // sets
localparam L1D_BANK_WAY_NUM = L1D_WAY_COUNT;
localparam L1D_BANK_ID_NUM = L1D_BANK_COUNT;

localparam L1D_STB_ENTRY_NUM = 8;

// localparam INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);
localparam L1D_INDEX_WIDTH  = $clog2(L1D_BANK_SET_NUM*L1D_BANK_ID_NUM);
localparam L1D_OFFSET_WIDTH = $clog2(L1D_BANK_LINE_DATA_SIZE/8);
localparam L1D_BIT_OFFSET_WIDTH = $clog2(L1D_BANK_LINE_DATA_SIZE);
localparam L1D_TAG_WIDTH    = PADDR_WIDTH-L1D_INDEX_WIDTH-L1D_OFFSET_WIDTH;

localparam L1D_STB_ID_NUM = 8;
localparam L1D_STB_ID_WIDTH = $clog2(L1D_STB_ID_NUM);
localparam L1D_STB_DATA_WIDTH = 512;
localparam L1D_STB_LINE_ADDR_SIZE = PADDR_WIDTH-L1D_OFFSET_WIDTH;
localparam L1D_OFFSET_BIT_DIFF_STB_SEG = $clog2(L1D_BANK_LINE_DATA_SIZE/L1D_STB_DATA_WIDTH);

localparam L1D_BANK_SET_INDEX_WIDTH = $clog2(L1D_BANK_SET_NUM);
localparam L1D_BANK_ID_INDEX_WIDTH  = $clog2(L1D_BANK_ID_NUM);
localparam L1D_BANK_OFFSET_WIDTH  = L1D_OFFSET_WIDTH;
localparam L1D_BANK_TAG_WIDTH     = L1D_TAG_WIDTH;
localparam L1D_BANK_WAY_INDEX_WIDTH = $clog2(L1D_BANK_WAY_NUM);

localparam L1D_BANK_LINE_ADDR_SIZE = PADDR_WIDTH-L1D_OFFSET_WIDTH-L1D_BANK_ID_INDEX_WIDTH;
localparam L1D_BANK_PADDR_TAG_WIDTH = PADDR_WIDTH-L1D_BANK_SET_INDEX_WIDTH-L1D_BANK_ID_INDEX_WIDTH-L1D_BANK_OFFSET_WIDTH;
localparam L1D_BANK_TAG_RAM_WORD_WIDTH = L1D_BANK_PADDR_TAG_WIDTH; 


// s_axi_awsize    width(byte)
// 3'b000          1
// 3'b001          2
// 3'b010          4
// 3'b011          8
// 3'b100          16
// 3'b101          32
// 3'b110          64
// 3'b111          128
localparam MEM_DATA_WIDTH = 64;
localparam BURST_SIZE = L1D_BANK_LINE_DATA_SIZE/MEM_DATA_WIDTH;//8
localparam AXI_SIZE = $clog2(MEM_DATA_WIDTH/8);
localparam N_MSHR = 4; // num of MSHR
localparam N_MSHR_W = $clog2(N_MSHR);
// localparam PPN_WIDTH = 44;
localparam N_EWRQ = N_MSHR;
localparam N_MLFB = N_MSHR;


localparam MEMNOC_TID_MASTERID_SIZE  = 4;
localparam MEMNOC_TID_TID_SIZE       = 4;

`ifdef RUBY
// localparam RRV64_LSU_ID_WIDTH = LDQ_TAG_WIDTH + 2;
// parameter RT_TRANS_ID_NUM_W   = $clog2(RT_TRANS_ID_NUM);
localparam RRV64_LSU_ID_WIDTH = $clog2(32) + $clog2(LSU_ADDR_PIPE_COUNT);
`endif

  typedef logic [N_MSHR_W-1:0]   mshr_id_t;

  typedef enum logic [1:0] {
    INVALID,
    SHARED,
    EXCLUSIVE,
    MODIFIED
  } rrv64_mesi_type_e;

  typedef struct packed {
    logic [MEMNOC_TID_MASTERID_SIZE-1:0] bid; // cache bank id, the highest used for distinguish i$/d$
    logic [MEMNOC_TID_TID_SIZE-1:0] tid;      // mshr id in ar and r
  } mem_tid_t;
  typedef enum logic[1:0] {
    AXI_RESP_OKAY = 2'b00,
    AXI_RESP_EXOKAY = 2'b01,
    AXI_RESP_SLVERR = 2'b10,
    AXI_RESP_DECERR = 2'b11
  } axi4_resp_t;

  typedef struct packed {
    mem_tid_t awid;
    logic [PADDR_WIDTH-1:0]  awaddr;
    logic [7 : 0] awlen; // 8
    
    logic [2 : 0] awsize; // 3
    logic [1 : 0] awburst; // 2
    
} cache_mem_if_aw_t;

  typedef struct packed {
    logic [MEM_DATA_WIDTH-1:0]  wdata;
    logic wlast; // 1
    mem_tid_t wid; // 8
} cache_mem_if_w_t;

  typedef struct packed {
    mem_tid_t arid;
    logic [7  : 0] arlen;
    
    logic [2 : 0] arsize; // TODO: 
    logic [1 : 0] arburst; // TODO:
    
    logic [PADDR_WIDTH-1:0]  araddr;
  } cache_mem_if_ar_t;

  // typedef struct packed {
  //   mem_tid_t rid;
  //   logic [MEM_DATA_WIDTH-1:0]  rdata;
  //   axi4_resp_t rresp;
  //   logic rlast;
  // } cache_mem_if_r_t;

  typedef struct packed {
    mem_tid_t                        rid; // 
    logic [MEM_DATA_WIDTH-1:0]       dat; // 64 
    logic                            err; // 1
    rrv64_mesi_type_e                mesi_sta; // 2
    // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
    axi4_resp_t rresp; // 2
    logic rlast;  // 1
  //    logic                            l2_hit;
  } cache_mem_if_r_t;

  typedef struct packed {
    mem_tid_t bid;
    axi4_resp_t bresp;
  } cache_mem_if_b_t;

  // ace5 snoop channels
    // snoop addr
  typedef struct packed {
    // mem_tid_t acid;
    logic [L1D_STB_LINE_ADDR_SIZE-1:0]  acaddr;
    logic [3:0]              acsoop;
    logic [2:0]              acprot;
  } cache_mem_if_ac_t;

    // snoop resp
  typedef struct packed {
    logic WasUnique;
    logic IsShared;
    logic PassDirty;
    logic Error; // for ECC, not used
    logic DataTransfer;
  } cr_crresp_t;

  typedef struct packed {
    // mem_tid_t crid;
    cr_crresp_t crresp;
  } cache_mem_if_cr_t;

    // snoop data
  typedef struct packed {
    // mem_tid_t cdid;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0] cddata;
    logic                               cdlast;
  } cache_mem_if_cd_t;





  typedef enum logic [2:0] {
    AMOSWAP,
    AMOADD,
    AMOAND,
    AMOOR,
    AMOXOR,
    AMOMAX,
    AMOMIN
  } l1d_amo_type_e;

  typedef struct packed {
    logic          is_ld;
    logic          is_ptw_ld;
    logic          is_st;
    logic          is_amo;
    logic          amo_u;
    l1d_amo_type_e amo_type;
    logic          is_lr;
    logic          is_sc;
    logic          op_b;
    logic          op_hw;
    logic          op_w;
    logic          op_dw;
    logic          ld_u;
  } rrv64_l1d_req_type_dec_t;


typedef struct packed {
    rrv64_mesi_type_e [L1D_BANK_WAY_NUM-1:0] mesi_sta;
} rrv64_l1d_lst_t;

typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_req_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_req_prd;
  // logic [      LDU_OP_WIDTH-1:0] ls_pipe_l1d_req_opcode;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_req_lsu_tag;
`endif

  logic [L1D_BANK_SET_INDEX_WIDTH-1:0] ls_pipe_l1d_req_idx;
  logic [L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_req_offset;
  logic [L1D_BANK_TAG_WIDTH-1:0      ] ls_pipe_l1d_req_vtag; // for ld gen ptag when idx+offset<12
  
  logic [ L1D_BANK_PADDR_TAG_WIDTH-1:0 ] ls_pipe_l1d_st_req_tag; // for st: st paddr tag; for ptw: ptw ld paddr tag
  logic [       L1D_STB_DATA_WIDTH-1:0 ] ls_pipe_l1d_st_req_dat;
  logic [     L1D_STB_DATA_WIDTH/8-1:0 ] ls_pipe_l1d_st_req_dat_byte_mask;
  
  rrv64_l1d_lst_t                    lst_dat; // mesi, cover valid & dirty bit
  // logic                              is_lsu_ld_req;
  rrv64_l1d_req_type_dec_t           req_type_dec;
  
  logic                              is_evict;
  logic [L1D_BANK_WAY_NUM-1:0]       evict_way_idx;

  logic                              sc_rt_check_succ; // sc
} l1d_pipe_s1_t;

typedef struct packed {
  // stage 2
//  logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_PADDR_TAG_WIDTH-1:0]               tram_rdat;
//  logic [L1D_BANK_WAY_NUM-1:0][L1D_BANK_LINE_DATA_SIZE/L1D_BANK_WAY_NUM-1:0]  dram_rdat;
//  logic [L1D_BANK_WAY_NUM-1:0]                                    vram_rdat;
  logic [     ROB_TAG_WIDTH-1:0] ls_pipe_l1d_req_rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] ls_pipe_l1d_req_prd;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] ls_pipe_l1d_req_lsu_tag;
`endif

  logic                                     tag_compare_hit;
  logic [L1D_BANK_WAY_NUM-1:0]              tag_compare_hit_per_way;
  // logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]      tag_compare_hit_way_idx;
  logic                                     ld_tlb_hit;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0]       line_data;  // 1. for ld req: lsu_ld_hit_dat; 2. for st req: ls_pipe_l1d_st_req_dat; 3. for amo req: 
  logic [XLEN-1:0]                          amo_st_data; // for amo rs2 data

  rrv64_l1d_req_type_dec_t           req_type_dec;
  logic                              is_evict;

  // logic [       PADDR_WIDTH-1:0 ]           ls_pipe_l1d_ld_req_paddr;
  logic [       L1D_BANK_PADDR_TAG_WIDTH-1:0] ls_pipe_l1d_req_tag;
  logic [L1D_BANK_SET_INDEX_WIDTH-1:0    ] ls_pipe_l1d_req_idx;
  logic [       L1D_BANK_OFFSET_WIDTH-1:0   ] ls_pipe_l1d_req_offset;

  // logic [       L1D_STB_DATA_WIDTH-1:0 ] ls_pipe_l1d_st_req_dat;
  logic [     L1D_STB_DATA_WIDTH/8-1:0 ] ls_pipe_l1d_st_req_dat_byte_mask;

  // rrv64_mesi_type_e                     lst_mesi_sta;

  // snoop
  rrv64_l1d_lst_t                   lst_dat; // mesi, cover valid & dirty bit

  logic                             sc_rt_check_succ; // sc
} l1d_pipe_s2_t;

typedef struct packed {
  // stage 1
  l1d_pipe_s1_t s1;
  // stage 2
  l1d_pipe_s2_t s2;
} l1d_pipe_reg_t;

// fencei flush fsm
typedef enum logic [2:0] {
  FLUSH_IDLE,
  FLUSH_PENDING,
  FLUSH_READ_LST,                 // read lst and judge whether need to read data ram
  FLUSH_READ_DATA_RAM_WRITE_LST,  // read data ram if needed, write lst if needed
  FLUSH_ENQUEUE_EVICT_QUEUE,      // put the dirty data into evict queue if needed
  FLUSH_WAIT_EVICT_QUEUE_CLEAN,   // wait for evict queue clear
  FLUSH_FINISH
} l1d_bank_fencei_flush_state_t;

typedef enum logic [2:0] {
  FENCEI_IDLE,
  FENCEI_WAITING_FOR_STB_HSK,
  FENCEI_WAITING_FOR_STB_DONE,
  FENCEI_REQ_TO_BANK,
  FENCEI_WAITING_FOR_BANK_GRANT,
  FENCEI_FINISH
} l1d_fencei_state_t;

// ------------------------------
// store buffer
// st req pipe
typedef struct packed {
    logic [          ROB_TAG_WIDTH-1:0] rob_tag;
    logic [         PREG_TAG_WIDTH-1:0] prd;
    logic [           STU_OP_WIDTH-1:0] opcode;
    logic [ L1D_STB_LINE_ADDR_SIZE-1:0] line_paddr;
    logic [     L1D_STB_DATA_WIDTH-1:0] line_data;
    logic [   L1D_STB_DATA_WIDTH/8-1:0] write_byte_mask;
`ifdef RUBY
    logic [     RRV64_LSU_ID_WIDTH-1:0] lsu_tag;
`endif
    // sc
    logic                               sc_rt_check_succ;
    logic [       L1D_OFFSET_WIDTH-1:0] amo_offset; // offset used for amo & lr
  } stb_entry_t;

typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0]  rob_tag;
  logic [    PREG_TAG_WIDTH-1:0]  prd;
  logic [      STU_OP_WIDTH-1:0]  opcode;
  logic [       PADDR_WIDTH-1:0]  paddr;
  logic [              XLEN-1:0]  data;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH-1:0]  lsu_tag;
`endif
  
  logic                           stb_hit;
  logic [L1D_STB_ENTRY_NUM-1:0]   stb_hit_entry_mask; // equals to N_STB
  
  // ===== TODO: here only work for 2 input ports ======
  logic                           hit_the_same_cache_line;
  // ===================================================

  // sc
  logic                           sc_rt_check_succ;
} l1d_stb_st_pipe_s1_t;

typedef struct packed {
  // stage 1
  l1d_stb_st_pipe_s1_t s1;
} l1d_stb_st_pipe_reg_t;

// ld req pipe
typedef struct packed {
  // stage 1
  logic [     ROB_TAG_WIDTH-1:0] rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] prd;
  logic [      LDU_OP_WIDTH-1:0] opcode;
  logic                          is_ptw_ld;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif

  logic [L1D_TAG_WIDTH-1:0    ] vtag; // for ld gen ptag when idx+offset<12 // for ptw, it is ptag
  logic [L1D_INDEX_WIDTH-1:0  ] index;
  logic [L1D_OFFSET_WIDTH-1:0 ] offset;
} l1d_stb_ld_pipe_s1_t;

typedef struct packed {
  // stage 2
  logic [     ROB_TAG_WIDTH-1:0] rob_tag;
  logic [    PREG_TAG_WIDTH-1:0] prd;
  logic [      LDU_OP_WIDTH-1:0] opcode;
  logic                          is_ptw_ld;
`ifdef RUBY
  logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
  logic [L1D_OFFSET_WIDTH-1:0 ] offset;

  logic                         stb_hit;
  logic [L1D_STB_ENTRY_NUM-1:0] stb_hit_per_entry; // equals to N_STB
} l1d_stb_ld_pipe_s2_t;

typedef struct packed {
  // stage 1
  l1d_stb_ld_pipe_s1_t s1;
  // stage 2
  l1d_stb_ld_pipe_s2_t s2;
} l1d_stb_ld_pipe_reg_t;

// eviction fsm
typedef enum logic [1:0] {
  IDLE,
  IN_AGE_EVICT,     // stb full; 
  SELECTED_EVICT,   // load partial hit; coherence snoop hit;
  FLUSH             // stb flush (evict all);
} l1d_stb_evict_state_t;

  //------------------------------------------------------
  // MSHR definition
  typedef enum logic [2:0] {
    MSHR_WAIT_WRITE_BACK,
    MSHR_WRITE_BACK,
    MSHR_WAIT_ALLOCATE
  } mshr_state_t;

  typedef struct packed {
    // logic                 valid;

//    tid_t                 tid; // transaction id to the cpu side
    logic [ROB_TAG_WIDTH-1:0]  rob_tag;
    logic [PREG_TAG_WIDTH-1:0] prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
    
    logic                       rw; // read or write miss
    logic                       flush;
    logic                       no_write_alloc;
    logic [L1D_BANK_PADDR_TAG_WIDTH-1:0]  new_tag; // read addr 
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  bank_index; // bank index (index - bank_id)
    logic [L1D_BANK_OFFSET_WIDTH-1:0]     offset;
    
    logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] way_id; // way id // TODO: store after mshr read tag
    logic [L1D_STB_DATA_WIDTH-1:0]      data; // data to write (for write miss)
    logic [L1D_STB_DATA_WIDTH/8-1:0 ]   data_byte_mask;
    rrv64_l1d_req_type_dec_t    req_type_dec;
//    cpu_byte_mask_t       byte_mask; // data read/write mask

    // snoop
    rrv64_mesi_type_e             old_lst_state;

    // amo
    logic [XLEN-1:0]              amo_st_data;
  } mshr_t;

  typedef struct packed {
    // axi bus status
    logic                   waddr;
    logic                   wdata;
  } mshr_mem_state_t;

  // wdata pipeline registers
  // typedef struct packed {
  //   // bank_index_t                            waddr;
  //   // mshr_id_t                               wid;
  //   //logic                                   flush;
  //   logic                                   wvalid;
  //   //logic                                   wlast;
  //   //logic [$clog2(N_WAY)-1:0]               way_id;
  // } wdata_pipe_t;

  typedef struct packed {
    // cache data write pipeline
    logic                                   wvalid;
    // wdata_pipe_t                            wdata_pipe;
    logic [$clog2(BURST_SIZE)-1:0]          wdata_offset;
    //mshr_mem_state_t [N_MSHR-1:0]           mem_state;
    //mem_offset_t rdata_offset;

    // data output pipeline
  //  cpu_resp_t  rdata_pipe;
    // logic       rdata_pipe_valid;
  } mem_fsm_reg_t;

  typedef struct packed {
    mshr_id_t id;
    logic     rw;
    logic     no_write_alloc;
    logic     flush;
    logic     valid;
  } mshr_req_t; // request interface pipeline registers


// ------ mlfb ------// 
  typedef struct packed {
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0] set_idx;
    logic [L1D_BANK_WAY_NUM-1:0] way_idx;
} rrv64_l1d_evict_req_t;

  typedef struct packed {
    logic [L1D_BANK_PADDR_TAG_WIDTH-1:0]      tag;
    logic [L1D_BANK_LINE_DATA_SIZE-1:0]    dat;
    logic [L1D_BANK_SET_INDEX_WIDTH-1:0]  set_idx;
    logic [L1D_BANK_WAY_NUM-1:0]  way_idx;
    rrv64_mesi_type_e                mesi_sta;
    logic                            is_lr;
    logic                            is_ld;

    logic [L1D_BANK_OFFSET_WIDTH-1:0]         offset;
    logic [ROB_TAG_WIDTH-1:0]         rob_tag;
    logic [PREG_TAG_WIDTH-1:0]        prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif
    rrv64_l1d_req_type_dec_t        req_type_dec;
    logic                             ld_no_resp;

    // amo
    logic [XLEN-1:0]              amo_st_data;
  } rrv64_l1d_refill_req_t;





typedef struct packed {
    logic                             valid;
    logic [N_MSHR_W -1:0]       mshr_idx;
    logic                             err;
    rrv64_mesi_type_e                 mesi_sta;

    logic [PADDR_WIDTH-1:0]           paddr;
    logic [ROB_TAG_WIDTH-1:0]         rob_tag;
    logic [PREG_TAG_WIDTH-1:0]        prd;
`ifdef RUBY
    logic [RRV64_LSU_ID_WIDTH -1:0] lsu_tag;
`endif

    logic                             peek_done;
    logic                             check_done;
    logic                             evict_done;
    logic                             refill_done;
//    logic                             stb_dat_done;
    logic  [L1D_BANK_LINE_DATA_SIZE -1:0]   line_dat;
    logic  [L1D_STB_DATA_WIDTH-1:0]       st_dat;
    logic  [L1D_STB_DATA_WIDTH/8-1:0 ]    st_dat_byte_mask;
//    logic                             is_st;
    rrv64_l1d_req_type_dec_t           req_type_dec;
//    logic  [RRV64_L1D_DATA_ECC_W* RRV64_L1D_WAY_N -1:0] dat_ecc_ckbit;
//    logic  [RRV64_L1D_TAG_ECC_W -1:0] tag_ecc_ckbit;
    logic  [L1D_BANK_WAY_NUM -1:0] avail_way_idx;
    logic  [L1D_BANK_WAY_NUM -1:0] victim_way_idx;
    logic                             victim_set_full;
    logic                             victim_way_clean;
//    logic  [RRV64_SCU_SST_IDX_W -1:0] sst_idx;
//    logic                             stb_alloc;
//    logic                             l2_hit;

    logic                             ld_no_resp;
    // amo
    logic [XLEN-1:0]              amo_st_data;
} rrv64_l1d_mlfb_head_buf_t;

typedef struct packed {
  logic [N_MSHR_W-1:0]             mshr_idx;
  logic                            err;
  rrv64_mesi_type_e                mesi_sta;
  // logic [RRV64_SCU_SST_IDX_W-1:0]  sst_idx;
//  logic                            l2_hit;
} rrv64_l1d_mlfb_t;

typedef struct packed {
  logic [PTW_ID_WIDTH-1:0]       id;
  logic [PADDR_WIDTH-1:0 ]       paddr;
} ptw_req_buffer_t;


// ------ snp ctrl ------//
typedef enum logic [3:0] {
  ReadShared          = 4'b0000,
  ReadClean           = 4'b0001,
  ReadNotSharedDirty  = 4'b0010, // need support
  ReadUnique          = 4'b0111, // need support
  CleanShared         = 4'b1000,
  CleanInvalid        = 4'b1001, // need support
  MakeInvalid         = 4'b1101,
  DVM_Complete        = 4'b1110,
  DVM_Message         = 4'b1111
} ace_acsoop_type_e;

typedef struct packed {
  logic [L1D_STB_LINE_ADDR_SIZE-1:0]   snp_line_addr;
  logic                     snp_leave_invalid;
  logic                     snp_leave_sharedclean;
  logic                     snp_return_clean_data;
  logic                     snp_return_dirty_data;
} snp_req_buf_t;

typedef struct packed {
  snp_req_buf_t   snp_req;

  logic           s1_conflict_check_done;
  // logic         s1_dataless_resp_i; // SnpResp_I

  logic           s2_read_tag_lst_done;
  rrv64_l1d_lst_t s2_lst_dat; // line state per way, read from lst

  logic           s3_rd_data_wr_lst_done;
  logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  s3_tag_compare_match_id;
  logic           s3_data_resp;  // resp with data
  logic           s3_resp_inv;   // SnpResp_I
  logic           s3_resp_sc;    // SnpResp_SC
  logic           s3_resp_pd;    // pass dirty
  logic           s3_was_unique;

  logic           s4_snp_resp_done;
  logic           cr_hsk_done;
  logic           cd_hsk_done;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0] cd_data_hold; // if cd channel not hsk immediately, buffer the data
  } snp_req_head_buf_t;

typedef struct packed {
  logic                                            s1_st_req_tag_hit;      // s0_1
  logic                                            s1_valid;               // s0_2 pipeline s1 vld
  logic                                            s2_valid;               // s0_2 pipeline s2 vld
  l1d_pipe_reg_t                                   cur;                    // s0_2 pipeline
  logic  [L1D_BANK_PADDR_TAG_WIDTH-1:0]            s1_tag_used_to_compare; // s0_2 pipeline for vipt s1 ptag
  logic  [N_MSHR-1:0]                              mshr_bank_valid;        // s0_2 mshr vld
  logic  [N_MSHR-1:0]                              mshr_bank_sent;         // s0_2 mshr sent
  mshr_t [N_MSHR-1:0]                              mshr_bank;              // s0_2 mshr
  logic  [N_EWRQ-1:0]                              ewrq_vld;               // s0_2 ewrq
  logic  [N_EWRQ-1:0][L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_addr;              // s0_2 addr
} snp_l1d_bank_snp_s0_t;

typedef struct packed {
  rrv64_l1d_lst_t               lst_dat; // line state per way, read from lst
} snp_l1d_bank_snp_s1_t;

typedef struct packed {
  logic [L1D_BANK_WAY_NUM-1:0]  tag_compare_result_per_way;
} snp_l1d_bank_snp_s2_t;

endpackage
`endif // __RVH_L1D_PKG_SV__
