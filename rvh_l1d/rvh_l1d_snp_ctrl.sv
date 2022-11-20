`ifdef USE_VERILATOR
`include "./include/riscv_pkg.sv"
`include "./include/rvh_pkg.sv"
`include "./include/rvh_l1d_pkg.sv"
`include "./include/uop_encoding_pkg.sv"
`endif //USE_VERILATOR
/* verilator lint_off PINCONNECTEMPTY */
module rvh_l1d_snp_ctrl
  // import riscv_pkg::*;
  // import rvh_pkg::*;
  // import uop_encoding_pkg::*;
  import rvh_l1d_pkg::*;
#(
  parameter int unsigned SNOOP_REQ_BUFFER_DEPTH = 1,
  parameter int unsigned SNOOP_REQ_BUFFER_DEPTH_W = SNOOP_REQ_BUFFER_DEPTH > 1 ? $clog2(SNOOP_REQ_BUFFER_DEPTH) : 1
)
(
  // ace5 snoop channels
    // snoop addr
  input  logic              snp_req_if_acvalid_i,
  output logic              snp_req_if_acready_o,
  input  cache_mem_if_ac_t  snp_req_if_ac_i,
    // snoop resp
  output logic              snp_resp_if_crvalid_o,
  input  logic              snp_resp_if_crready_i,
  output cache_mem_if_cr_t  snp_resp_if_cr_o,
    // snoop data
  output logic              snp_resp_if_cdvalid_o,
  input  logic              snp_resp_if_cdready_i,
  output cache_mem_if_cd_t  snp_resp_if_cd_o,

  // snp ctrl <-> l1d bank intf
  output snp_req_head_buf_t snp_l1d_bank_snp_req_o,
    // s0 req
  output logic                  snp_l1d_bank_snp_s0_req_vld_o, // vld for: all_1
  output logic                  snp_l1d_bank_snp_s0_req_hsk_o,
  output logic                  snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_o, // all_2
  input  logic                  snp_l1d_bank_snp_s0_req_rdy_i,
  input  snp_l1d_bank_snp_s0_t  snp_l1d_bank_snp_s0_i,
    // s1 req
  output logic                  snp_l1d_bank_snp_s1_req_vld_o, // vld for: all_1
  output logic                  snp_l1d_bank_snp_s1_req_hsk_o, // hsk for: s1_1
  input  logic                  snp_l1d_bank_snp_s1_req_rdy_i,
  input  snp_l1d_bank_snp_s1_t  snp_l1d_bank_snp_s1_i,
  // s2 req
  output logic                  snp_l1d_bank_snp_s2_req_vld_o, // vld for: all_1
  output logic                  snp_l1d_bank_snp_s2_req_hsk_o, // hsk for: s2_3
  output rrv64_mesi_type_e      snp_l1d_bank_snp_s2_req_new_line_state_o,
  output logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  snp_l1d_bank_snp_s2_req_way_id_o,
  output logic                  snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o, // vld for: s2_2
  input  logic                  snp_l1d_bank_snp_s2_req_rdy_i,
  input  snp_l1d_bank_snp_s2_t  snp_l1d_bank_snp_s2_i,

  // s3 req
  output logic                  snp_l1d_bank_snp_s3_req_vld_o, // vld for: all_1
  output logic [L1D_BANK_WAY_INDEX_WIDTH-1:0] snp_l1d_bank_snp_s3_tag_compare_match_id_o,
  input  logic [L1D_BANK_LINE_DATA_SIZE-1:0] snp_l1d_bank_snp_s3_req_line_data_i,


  input  logic clk,
  input  logic rst
);
genvar i;

// ace5 snoop channels
  // snoop addr
logic snp_req_if_ac_hsk;
  // snoop resp
logic snp_resp_if_cr_hsk;
  // snoop data
logic snp_resp_if_cd_hsk;
logic snp_resp_if_cd_bypass; // dataless resp no need data

// snp req buf order fifo
logic                                 snp_req_buf_order_fifo_dq_vld;
logic                                 snp_req_buf_order_fifo_dq_rdy;
logic [SNOOP_REQ_BUFFER_DEPTH_W-1:0]  snp_req_buf_order_fifo_dq_pl;

// snoop head buffer
logic              snp_req_buf_snp_head_buf_hsk;
logic              snp_req_head_buf_valid, snp_req_head_buf_valid_nxt;
logic              snp_req_head_buf_valid_set, snp_req_head_buf_valid_clr;
logic              snp_req_head_buf_valid_ena;

snp_req_head_buf_t snp_req_head_buf;

snp_req_buf_t      snp_req_head_buf_snp_req, snp_req_head_buf_snp_req_nxt;
logic              snp_req_head_buf_snp_req_ena;

logic              snp_req_head_buf_s1_conflict_check_done;
logic              snp_req_head_buf_s1_conflict_check_done_nxt;
logic              snp_req_head_buf_s1_conflict_check_done_set, snp_req_head_buf_s1_conflict_check_done_clr;
logic              snp_req_head_buf_s1_ena;

logic              snp_req_head_buf_s2_read_tag_lst_done;
logic              snp_req_head_buf_s2_read_tag_lst_done_nxt;
logic              snp_req_head_buf_s2_read_tag_lst_done_set, snp_req_head_buf_s2_read_tag_lst_done_clr;
rrv64_l1d_lst_t    snp_req_head_buf_s2_lst_dat;
rrv64_l1d_lst_t    snp_req_head_buf_s2_lst_dat_nxt;
logic              snp_req_head_buf_s2_ena;

logic              snp_req_head_buf_s3_rd_data_wr_lst_done, snp_req_head_buf_s3_rd_data_wr_lst_done_nxt;
logic              snp_req_head_buf_s3_rd_data_wr_lst_done_set, snp_req_head_buf_s3_rd_data_wr_lst_done_clr;

logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  snp_req_head_buf_s3_tag_compare_match_id, snp_req_head_buf_s3_tag_compare_match_id_nxt;

logic              snp_req_head_buf_s3_data_resp, snp_req_head_buf_s3_data_resp_nxt;
logic              snp_req_head_buf_s3_data_resp_set, snp_req_head_buf_s3_data_resp_clr;

logic              snp_req_head_buf_s3_resp_inv, snp_req_head_buf_s3_resp_inv_nxt;
logic              snp_req_head_buf_s3_resp_inv_set, snp_req_head_buf_s3_resp_inv_clr;

logic              snp_req_head_buf_s3_resp_sc, snp_req_head_buf_s3_resp_sc_nxt;
logic              snp_req_head_buf_s3_resp_sc_set, snp_req_head_buf_s3_resp_sc_clr;

logic              snp_req_head_buf_s3_resp_pd, snp_req_head_buf_s3_resp_pd_nxt;
logic              snp_req_head_buf_s3_resp_pd_set, snp_req_head_buf_s3_resp_pd_clr;

logic              snp_req_head_buf_s3_was_unique, snp_req_head_buf_s3_was_unique_nxt;
logic              snp_req_head_buf_s3_was_unique_set, snp_req_head_buf_s3_was_unique_clr;

logic              snp_req_head_buf_s3_ena;

logic              snp_req_head_buf_s4_snp_resp_done, snp_req_head_buf_s4_snp_resp_done_nxt;
logic              snp_req_head_buf_s4_snp_resp_done_set, snp_req_head_buf_s4_snp_resp_done_clr;
logic              snp_req_head_buf_s4_snp_resp_done_ena;

logic              snp_req_head_buf_cr_hsk_done, snp_req_head_buf_cr_hsk_done_nxt;
logic              snp_req_head_buf_cr_hsk_done_set, snp_req_head_buf_cr_hsk_done_clr;
logic              snp_req_head_buf_cr_ena;

logic              snp_req_head_buf_cd_hsk_done, snp_req_head_buf_cd_hsk_done_nxt;
logic              snp_req_head_buf_cd_hsk_done_set, snp_req_head_buf_cd_hsk_done_clr;
logic              snp_req_head_buf_cd_ena;

logic [L1D_BANK_LINE_DATA_SIZE-1:0] snp_req_head_buf_cd_data_hold, snp_req_head_buf_cd_data_hold_nxt;
logic              snp_req_head_buf_cd_data_hold_ena;

// snp ctrl <-> l1d bank intf

// snoop req buffer
snp_req_buf_t [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf;
snp_req_buf_t                               snp_req_buf_new_entry;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_ena;

// snoop req buffer valid
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_nxt;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_set;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_clr;
logic         [SNOOP_REQ_BUFFER_DEPTH-1:0]  snp_req_buf_valid_ena;

logic                                       snp_req_buf_has_free_entry;
logic         [SNOOP_REQ_BUFFER_DEPTH_W-1:0]snp_req_buf_free_entry_id;
logic         [SNOOP_REQ_BUFFER_DEPTH_W:0]  snp_req_buf_free_entry_num;

// 1. ac (snoop addr) channel: receive snoop req from scu
assign snp_req_if_ac_hsk    = snp_req_if_acvalid_i & snp_req_if_acready_o;
assign snp_req_if_acready_o = snp_req_buf_has_free_entry;

// 2. snoop req buffer maintainence
// 2.1 ace ac channel decoder
rvh_l1d_snp_dec
rvh_l1d_snp_dec_u (
  .snp_req_if_ac_i      (snp_req_if_ac_i      ),
  .snp_req_buf_entry_o  (snp_req_buf_new_entry)
);

// 2.2 if the snoop req buffer has free entry, alloc new snoop req(for deadlock free, now the buffer depth is 1)
rvh_l1d_mshr_alloc
#(
  .INPUT_NUM    (SNOOP_REQ_BUFFER_DEPTH)
)
rvh_l1d_snp_req_buffer_alloc_u
(
  .mshr_bank_valid_i    (snp_req_buf_valid          ),
  .mshr_id_o            (snp_req_buf_free_entry_id  ),
  .has_free_mshr_o      (snp_req_buf_has_free_entry ),
  .free_mshr_num_o      (snp_req_buf_free_entry_num )
);

// 2.3 snp_req_buf alloc and dealloc
always_comb begin : comb_snp_req_buf_valid_set
  snp_req_buf_valid_set = '0;
  if(snp_req_if_ac_hsk) begin
    snp_req_buf_valid_set[snp_req_buf_free_entry_id] = 1'b1;
  end
end

always_comb begin : comb_snp_req_buf_valid_clr
  snp_req_buf_valid_clr = '0;
  if(snp_req_buf_snp_head_buf_hsk) begin
    snp_req_buf_valid_clr[snp_req_buf_order_fifo_dq_pl] = 1'b1;
  end
end

assign snp_req_buf_valid_nxt = (snp_req_buf_valid | snp_req_buf_valid_set) & ~snp_req_buf_valid_clr;
assign snp_req_buf_valid_ena = snp_req_buf_valid_set | snp_req_buf_valid_clr;
assign snp_req_buf_ena       = snp_req_buf_valid_set;


generate
  for(i = 0; i < SNOOP_REQ_BUFFER_DEPTH; i++) begin: gen_snp_req_buf_valid
    std_dffre
    #(.WIDTH(1))
    U_L1D_SNP_REQ_BUF_VALID_REG
    (
      .clk  (clk),
      .rstn (rst),
      .en   (snp_req_buf_valid_ena [i]),
      .d    (snp_req_buf_valid_nxt [i]),
      .q    (snp_req_buf_valid     [i])
    );
  end
  for(i = 0; i < SNOOP_REQ_BUFFER_DEPTH; i++) begin: gen_snp_req_buf
    std_dffe
    #(.WIDTH(snp_req_buf_t)) 
    U_L1D_SNP_REQ_BUF_REG
    (
      .clk(clk),
      .en (snp_req_buf_ena [i]  ),
      .d  (snp_req_buf_new_entry),
      .q  (snp_req_buf     [i]  )
    );
  end
endgenerate

// 2.4 send the snoop req to l1d bank in order
mp_fifo
#(
    .payload_t          (logic[SNOOP_REQ_BUFFER_DEPTH_W-1:0]    ),
    .ENQUEUE_WIDTH      (1                                      ),
    .DEQUEUE_WIDTH      (1                                      ),
    .DEPTH              (SNOOP_REQ_BUFFER_DEPTH                 ),
    .MUST_TAKEN_ALL     (1                                      )
)
l1d_snp_req_buf_order_fifo_u
(
    // Enqueue
    .enqueue_vld_i          (snp_req_if_ac_hsk          ),
    .enqueue_payload_i      (snp_req_buf_free_entry_id  ),
    .enqueue_rdy_o          (                    ),
    // Dequeue
    .dequeue_vld_o          (snp_req_buf_order_fifo_dq_vld   ),
    .dequeue_payload_o      (snp_req_buf_order_fifo_dq_pl    ),
    .dequeue_rdy_i          (snp_req_buf_order_fifo_dq_rdy   ),

    .flush_i                (1'b0                ),

    .clk                    (clk                 ),
    .rst                    (~rst                 )
);

// 3 head buf
// 3.1 when head buf is invalid, load a new snoop req from snp_req_buf
assign snp_req_buf_order_fifo_dq_rdy = ~snp_req_head_buf_valid;
assign snp_req_buf_snp_head_buf_hsk = snp_req_buf_order_fifo_dq_vld & snp_req_buf_order_fifo_dq_rdy;

// 3.1.1 head buf valid
assign snp_req_head_buf_valid_nxt = (snp_req_head_buf_valid | snp_req_head_buf_valid_set) & ~snp_req_head_buf_valid_clr;
assign snp_req_head_buf_valid_ena = snp_req_head_buf_valid_set | snp_req_head_buf_valid_clr;
assign snp_req_head_buf_valid_set = snp_req_buf_snp_head_buf_hsk;
assign snp_req_head_buf_valid_clr = (snp_req_head_buf_s4_snp_resp_done_set & snp_req_head_buf_cr_hsk_done_set & snp_req_head_buf_cd_hsk_done_set) | // hsk immediately at s4
                                    (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & snp_req_head_buf.cr_hsk_done & snp_req_head_buf.cd_hsk_done);

std_dffre#(.WIDTH(1))U_STA_REG_HEAD_BUF_VALID(.clk(clk),.rstn(rst),.en(snp_req_head_buf_valid_ena),.d(snp_req_head_buf_valid_nxt),.q(snp_req_head_buf_valid));


// 3.1.2 head buf, the head buf is linked to many regs with different enable signal
assign snp_req_head_buf.snp_req                 = snp_req_head_buf_snp_req;
assign snp_req_head_buf.s1_conflict_check_done  = snp_req_head_buf_s1_conflict_check_done;
// assign snp_req_head_buf.s1_dataless_resp_i      = snp_req_head_buf_s1_dataless_resp_i;
assign snp_req_head_buf.s2_read_tag_lst_done    = snp_req_head_buf_s2_read_tag_lst_done;
assign snp_req_head_buf.s3_rd_data_wr_lst_done  = snp_req_head_buf_s3_rd_data_wr_lst_done;
assign snp_req_head_buf.s3_tag_compare_match_id = snp_req_head_buf_s3_tag_compare_match_id;
assign snp_req_head_buf.s3_data_resp            = snp_req_head_buf_s3_data_resp;
assign snp_req_head_buf.s3_resp_inv             = snp_req_head_buf_s3_resp_inv;
assign snp_req_head_buf.s3_resp_sc              = snp_req_head_buf_s3_resp_sc;
assign snp_req_head_buf.s3_resp_pd              = snp_req_head_buf_s3_resp_pd;
assign snp_req_head_buf.s3_was_unique           = snp_req_head_buf_s3_was_unique;
assign snp_req_head_buf.s4_snp_resp_done        = snp_req_head_buf_s4_snp_resp_done;
assign snp_req_head_buf.cr_hsk_done             = snp_req_head_buf_cr_hsk_done;
assign snp_req_head_buf.cd_hsk_done             = snp_req_head_buf_cd_hsk_done;
assign snp_req_head_buf.cd_data_hold            = snp_req_head_buf_cd_data_hold;

// 3.1.3 head buf signals
// 3.1.3.1 snp_req
assign snp_req_head_buf_snp_req_nxt = snp_req_buf[snp_req_buf_order_fifo_dq_pl];
assign snp_req_head_buf_snp_req_ena = snp_req_head_buf_valid_set;

std_dffe#(.WIDTH($bits(snp_req_buf_t)))U_DAT_REG_HEAD_BUF_SNP_REQ(.clk(clk),.en(snp_req_head_buf_snp_req_ena),.d(snp_req_head_buf_snp_req_nxt),.q(snp_req_head_buf_snp_req));

// 4 snp ctrl -> l1d bank intf snoop transaction
logic snp_l1d_bank_snp_s0_req_rdy_internal;
logic snp_l1d_bank_snp_s1_req_rdy_internal;
logic snp_l1d_bank_snp_s2_req_rdy_internal;

assign snp_l1d_bank_snp_req_o         = snp_req_head_buf;

// 4.1 s0
// 4.1.1 snp req out to l1d bank
assign snp_l1d_bank_snp_s0_req_vld_o  = snp_req_head_buf_valid & ~snp_req_head_buf.s1_conflict_check_done;

// 4.1.2 check data from l1d bank
logic [L1D_BANK_PADDR_TAG_WIDTH-1:0] snp_addr_tag;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] snp_addr_idx;
logic [N_MSHR-1:0] snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry;
logic [N_MSHR-1:0] snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry_sent;
logic [N_EWRQ-1:0] snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry;
logic snp_l1d_bank_req_line_addr_hit_in_pipe;
logic snp_l1d_bank_req_line_addr_hit_in_mshr;
logic snp_l1d_bank_req_line_addr_hit_in_mshr_sent;
logic snp_l1d_bank_req_line_addr_hit_in_ewrq;

assign snp_addr_tag = snp_req_head_buf.snp_req.snp_line_addr[L1D_STB_LINE_ADDR_SIZE-1 -: L1D_BANK_PADDR_TAG_WIDTH];
assign snp_addr_idx = snp_req_head_buf.snp_req.snp_line_addr[L1D_BANK_ID_INDEX_WIDTH  +: L1D_BANK_SET_INDEX_WIDTH];

generate
  for(i = 0; i < N_MSHR; i++) begin: gen_snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry
      assign snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry[i] = snp_l1d_bank_snp_s0_i.mshr_bank_valid[i] & 
                                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.mshr_bank[i].new_tag) & // tag match
                                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.mshr_bank[i].bank_index); // bank idx match
      assign snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry_sent[i]     = snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry[i] & snp_l1d_bank_snp_s0_mshr_bank_sent_i[i];
  end
  for(i = 0; i < N_EWRQ; i++) begin: gen_snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry
      assign snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry[i] = snp_l1d_bank_snp_s0_i.ewrq_vld[i] &
                                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.ewrq_addr[i][L1D_BANK_LINE_ADDR_SIZE-1-:L1D_BANK_PADDR_TAG_WIDTH]) & // tag match
                                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.ewrq_addr[i][L1D_BANK_SET_INDEX_WIDTH-1:0]); // bank idx match
  end
endgenerate

assign snp_l1d_bank_req_line_addr_hit_in_pipe = (snp_l1d_bank_snp_s0_i.s1_valid &
                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.s1_tag_used_to_compare) & // tag match
                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.cur.s1.ls_pipe_l1d_req_idx) // bank idx match
                                                ) |
                                                (snp_l1d_bank_snp_s0_i.s2_valid &
                                                  (snp_addr_tag == snp_l1d_bank_snp_s0_i.cur.s2.ls_pipe_l1d_req_tag) & // tag match
                                                  (snp_addr_idx == snp_l1d_bank_snp_s0_i.cur.s2.ls_pipe_l1d_req_idx) // bank idx match
                                                );
assign snp_l1d_bank_req_line_addr_hit_in_mshr       = (|snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry);
assign snp_l1d_bank_req_line_addr_hit_in_mshr_sent  = (|snp_l1d_bank_req_line_addr_hit_in_mshr_per_entry_sent);
assign snp_l1d_bank_req_line_addr_hit_in_ewrq       = (|snp_l1d_bank_req_line_addr_hit_in_ewrq_per_entry);

// 4.1.3 s0 handshake
assign snp_l1d_bank_snp_s0_req_rdy_internal = ~snp_l1d_bank_snp_s0_i.s1_st_req_tag_hit     & // s0_1: if s1 is a store hit need to write data ram, wait for 1 cycle
                                              ~snp_l1d_bank_req_line_addr_hit_in_mshr_sent & // s0_2: in mshr sent out
                                              ~snp_l1d_bank_req_line_addr_hit_in_ewrq      & // s0_2: in ewrq
                                              ~snp_l1d_bank_req_line_addr_hit_in_pipe;       // s0_2: in pipeline
assign snp_l1d_bank_snp_s0_req_hsk_o  = snp_l1d_bank_snp_s0_req_vld_o &
                                        snp_l1d_bank_snp_s0_req_rdy_internal &
                                        snp_l1d_bank_snp_s0_req_rdy_i; // snp_l1d_bank_snp_s0_req_rdy_i not used, reserve for stall snoop transaction

assign snp_req_head_buf_s1_conflict_check_done_set  = snp_l1d_bank_snp_s0_req_hsk_o;
assign snp_req_head_buf_s1_conflict_check_done_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s1_conflict_check_done_nxt  = snp_req_head_buf_s1_conflict_check_done_set & (~snp_req_head_buf_s1_conflict_check_done_clr);
assign snp_req_head_buf_s1_ena                      = snp_req_head_buf_s1_conflict_check_done_set | snp_req_head_buf_s1_conflict_check_done_clr;

std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S1_CONFLICT_CHECK_DONE (.clk(clk),.en(snp_req_head_buf_s1_ena) ,.d(snp_req_head_buf_s1_conflict_check_done_nxt) ,.q(snp_req_head_buf_s1_conflict_check_done));

// 4.1.4 all_2: for s0, stall mlfb refill transaction [mlfb_cache_peek_valid, mlfb_cache_check_valid, mlfb_cache_evict_valid, mlfb_cache_evict_bypass, mlfb_cache_refill_valid] if no sent-out line addr hit in mshr(cond s0.3)
assign snp_l1d_bank_snp_s0_turn_down_refill_ready_vld_o = snp_l1d_bank_snp_s0_req_vld_o &
                                                          ~snp_l1d_bank_req_line_addr_hit_in_mshr_sent; // wait until the sent mshr get resp and removed

// 4.2 s1: read tag ram, read lst if needed, then goto s2
// 4.2.1 snp req out to l1d bank
assign snp_l1d_bank_snp_s1_req_vld_o  = snp_req_head_buf_valid & snp_req_head_buf.s1_conflict_check_done & ~snp_req_head_buf.s2_read_tag_lst_done;
// 4.2.2 s1 handshake
assign snp_l1d_bank_snp_s1_req_rdy_internal = 1'b1;
assign snp_l1d_bank_snp_s1_req_hsk_o = snp_l1d_bank_snp_s1_req_vld_o &
                                       snp_l1d_bank_snp_s1_req_rdy_internal &
                                       snp_l1d_bank_snp_s1_req_rdy_i;

assign snp_req_head_buf_s2_read_tag_lst_done_set = snp_l1d_bank_snp_s1_req_hsk_o;
assign snp_req_head_buf_s2_read_tag_lst_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s2_read_tag_lst_done_nxt = snp_req_head_buf_s2_read_tag_lst_done_set | (~snp_req_head_buf_s2_read_tag_lst_done_clr);
assign snp_req_head_buf_s2_lst_dat_nxt           = snp_l1d_bank_snp_s1_i.s2_lst_dat;
assign snp_req_head_buf_s2_ena                   = snp_req_head_buf_s2_read_tag_lst_done_set | snp_req_head_buf_s2_read_tag_lst_done_clr;

std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S2_READ_TAG_LST_DONE (.clk(clk),.en(snp_req_head_buf_s2_ena) ,.d(snp_req_head_buf_s2_read_tag_lst_done_nxt) ,.q(snp_req_head_buf_s2_read_tag_lst_done));
std_dffe #(.WIDTH($bits(rrv64_l1d_lst_t))) U_DAT_REG_HEAD_BUF_S2_LST_DAT (.clk(clk),.en(snp_req_head_buf_s2_ena) ,.d(snp_req_head_buf_s2_lst_dat_nxt) ,.q(snp_req_head_buf_s2_lst_dat));


// 4.3 s2: compare tag, check lst; read data ram if needed(cond s2.3, s2.4, s2.5)
// 4.3.1 compare tag, check lst
logic [L1D_BANK_WAY_NUM-1:0]          s2_tag_compare_result_per_way;
logic [L1D_BANK_WAY_INDEX_WIDTH-1:0]  s2_tag_compare_match_id;

logic s2_tag_miss;
logic s2_tag_hit_state_inv;
logic s2_tag_hit_state_sc;
logic s2_tag_hit_state_uc;
logic s2_tag_hit_state_ud;

assign s2_tag_compare_result_per_way = snp_l1d_bank_snp_s2_i.tag_compare_result_per_way;
always_comb begin
  s2_tag_compare_match_id = '0;
  for(int i = 0; i < L1D_BANK_WAY_NUM; i++) begin
    if(s2_tag_compare_result_per_way[i] == 1'b1) begin
      s2_tag_compare_match_id = i[L1D_BANK_WAY_INDEX_WIDTH-1:0];
    end
  end
end

assign s2_tag_miss  = ~(|s2_tag_compare_result_per_way);
assign s2_tag_hit_state_inv = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == INVALID);
assign s2_tag_hit_state_sc  = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == SHARED);
assign s2_tag_hit_state_uc  = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == EXCLUSIVE);
assign s2_tag_hit_state_ud  = ~s2_tag_miss & (snp_req_head_buf.s2_lst_dat.mesi_sta[s2_tag_compare_match_id] == MODIFIED);

  // need to read data ram
assign snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o = snp_req_head_buf.snp_req.snp_return_clean_data & (s2_tag_hit_state_sc | s2_tag_hit_state_uc) |
                                                   snp_req_head_buf.snp_req.snp_return_dirty_data & (s2_tag_hit_state_ud);

// 4.3.2 snp req out to l1d bank
assign snp_l1d_bank_snp_s2_req_vld_o  = snp_req_head_buf_valid &
                                        snp_req_head_buf.s1_conflict_check_done &
                                        snp_req_head_buf.s2_read_tag_lst_done &
                                        ~snp_req_head_buf.s3_rd_data_wr_lst_done;

assign snp_l1d_bank_snp_s2_req_new_line_state_o = snp_req_head_buf_s3_resp_sc_set ? SHARED : INVALID;
assign snp_l1d_bank_snp_s2_req_way_id_o         = s2_tag_compare_match_id;

// 4.3.3 s2 handshake
assign snp_l1d_bank_snp_s2_req_rdy_internal = 1'b1;
assign snp_l1d_bank_snp_s2_req_hsk_o = snp_l1d_bank_snp_s2_req_vld_o &
                                       snp_l1d_bank_snp_s2_req_rdy_internal &
                                       snp_l1d_bank_snp_s2_req_rdy_i;

assign snp_req_head_buf_s3_rd_data_wr_lst_done_set = snp_l1d_bank_snp_s2_req_hsk_o;
assign snp_req_head_buf_s3_rd_data_wr_lst_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_rd_data_wr_lst_done_nxt = snp_req_head_buf_s3_rd_data_wr_lst_done_set & (~snp_req_head_buf_s3_rd_data_wr_lst_done_clr);
assign snp_req_head_buf_s3_ena                     = snp_req_head_buf_s3_rd_data_wr_lst_done_set | snp_req_head_buf_s3_rd_data_wr_lst_done_clr;

  // pass s2 hit way id to s3
assign snp_req_head_buf_s3_tag_compare_match_id_nxt = s2_tag_compare_match_id;

  // need s3 data resp
assign snp_req_head_buf_s3_data_resp_set  = snp_l1d_bank_snp_s2_req_data_ram_rd_vld_o;
assign snp_req_head_buf_s3_data_resp_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_data_resp_nxt  = snp_req_head_buf_s3_data_resp_set & (~snp_req_head_buf_s3_data_resp_clr);

  // need s3 data resp SnpResp_I
assign snp_req_head_buf_s3_resp_inv_set  = snp_req_head_buf.snp_req.snp_leave_invalid |
                                           s2_tag_miss |
                                           s2_tag_hit_state_inv;
assign snp_req_head_buf_s3_resp_inv_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_resp_inv_nxt  = snp_req_head_buf_s3_resp_inv_set & (~snp_req_head_buf_s3_resp_inv_clr);

  // need s3 data resp SnpResp_SC
assign snp_req_head_buf_s3_resp_sc_set  = snp_req_head_buf.snp_req.snp_leave_sharedclean & (s2_tag_hit_state_sc | s2_tag_hit_state_uc);
assign snp_req_head_buf_s3_resp_sc_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_resp_sc_nxt  = snp_req_head_buf_s3_resp_sc_set & (~snp_req_head_buf_s3_resp_sc_clr);

  // need s3 data resp pass dirty
assign snp_req_head_buf_s3_resp_pd_set  = (s2_tag_hit_state_ud) & snp_req_head_buf.snp_req.snp_return_dirty_data;
assign snp_req_head_buf_s3_resp_pd_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_resp_pd_nxt  = snp_req_head_buf_s3_resp_pd_set & (~snp_req_head_buf_s3_resp_pd_clr);

  // the cache line was unqiue
assign snp_req_head_buf_s3_was_unique_set  = s2_tag_hit_state_ud | s2_tag_hit_state_uc;
assign snp_req_head_buf_s3_was_unique_clr  = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s3_was_unique_nxt  = snp_req_head_buf_s3_was_unique_set & (~snp_req_head_buf_s3_was_unique_clr);

  // s3 enable
assign snp_req_head_buf_s3_ena = snp_req_head_buf_s3_rd_data_wr_lst_done_set | snp_req_head_buf_s3_rd_data_wr_lst_done_clr;

std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RD_DATA_WR_LST_DONE (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_rd_data_wr_lst_done_nxt) ,.q(snp_req_head_buf_s3_rd_data_wr_lst_done));
std_dffe #(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH)) U_DAT_REG_HEAD_BUF_S3_TAG_COMPARE_MATCH_ID(.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_tag_compare_match_id_nxt) ,.q(snp_req_head_buf_s3_tag_compare_match_id));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_DATA_RESP (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_data_resp_nxt) ,.q(snp_req_head_buf_s3_data_resp));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RESP_INV  (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_resp_inv_nxt) ,.q(snp_req_head_buf_s3_resp_inv));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RESP_SC   (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_resp_sc_nxt) ,.q(snp_req_head_buf_s3_resp_sc));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_RESP_PD   (.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_resp_pd_nxt) ,.q(snp_req_head_buf_s3_resp_pd));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S3_WAS_UNIQUE(.clk(clk),.en(snp_req_head_buf_s3_ena) ,.d(snp_req_head_buf_s3_was_unique_nxt) ,.q(snp_req_head_buf_s3_was_unique));


// 4.4 s3: snoop resp

// 4.4.1 get data ram output for data resp
assign snp_l1d_bank_snp_s3_req_vld_o  = snp_req_head_buf_valid &
                                        snp_req_head_buf.s1_conflict_check_done &
                                        snp_req_head_buf.s2_read_tag_lst_done &
                                        snp_req_head_buf.s3_rd_data_wr_lst_done &
                                        ~snp_req_head_buf.s4_snp_resp_done;
assign snp_l1d_bank_snp_s3_tag_compare_match_id_o = snp_req_head_buf.s3_tag_compare_match_id;

// 4.4.2 do the snoop resp
assign snp_resp_if_crvalid_o  = snp_l1d_bank_snp_s3_req_vld_o | // first time send cr vld
                                (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & ~snp_req_head_buf.cr_hsk_done); // if cr hsk failed, continue to send cr vld
assign snp_resp_if_cr_hsk     = snp_resp_if_crvalid_o & snp_resp_if_crready_i;

assign snp_resp_if_cr_o.crresp.DataTransfer = snp_req_head_buf.s3_data_resp;
assign snp_resp_if_cr_o.crresp.Error        = 1'b0;
assign snp_resp_if_cr_o.crresp.PassDirty    = snp_req_head_buf.s3_resp_pd;
assign snp_resp_if_cr_o.crresp.IsShared     = snp_req_head_buf.s3_resp_sc;
assign snp_resp_if_cr_o.crresp.WasUnique    = snp_req_head_buf.s3_was_unique;

// 4.4.3 do the snoop data resp
assign snp_resp_if_cdvalid_o  = (snp_req_head_buf.s3_data_resp & snp_l1d_bank_snp_s3_req_vld_o) | // first time send cd vld
                                (snp_req_head_buf_valid & snp_req_head_buf.s4_snp_resp_done & ~snp_req_head_buf.cd_hsk_done); // if cd hsk failed, continue to send cd vld
assign snp_resp_if_cd_hsk     = snp_resp_if_crvalid_o & snp_resp_if_cdready_i;
assign snp_resp_if_cd_bypass  = snp_l1d_bank_snp_s3_req_vld_o & ~snp_req_head_buf.s3_data_resp;

assign snp_resp_if_cd_o.cddata = snp_l1d_bank_snp_s3_req_line_data_i;
assign snp_resp_if_cd_o.cdlast = 1'b1;

// 4.4.4 s3 handshake
assign snp_req_head_buf_s4_snp_resp_done_set = snp_l1d_bank_snp_s3_req_vld_o;
assign snp_req_head_buf_s4_snp_resp_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_s4_snp_resp_done_nxt = snp_l1d_bank_snp_s3_req_vld_o & (~snp_req_head_buf_s4_snp_resp_done_clr);
assign snp_req_head_buf_s4_snp_resp_done_ena = snp_req_head_buf_s4_snp_resp_done_set | snp_req_head_buf_s4_snp_resp_done_clr;

std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_S4_SNP_RESP_DONE (.clk(clk),.en(snp_req_head_buf_s4_snp_resp_done_ena) ,.d(snp_req_head_buf_s4_snp_resp_done_nxt) ,.q(snp_req_head_buf_s4_snp_resp_done));

// 4.4.5 check cr and cd hsk
assign snp_req_head_buf_cr_hsk_done_set = snp_resp_if_cr_hsk;
assign snp_req_head_buf_cr_hsk_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_cr_hsk_done_nxt = snp_req_head_buf_cr_hsk_done_set & (~snp_req_head_buf_cr_hsk_done_clr);
assign snp_req_head_buf_cr_ena          = snp_req_head_buf_cr_hsk_done_set | snp_req_head_buf_cr_hsk_done_clr;

assign snp_req_head_buf_cd_hsk_done_set = snp_resp_if_cd_hsk | snp_resp_if_cd_bypass;
assign snp_req_head_buf_cd_hsk_done_clr = snp_req_head_buf_valid_set;
assign snp_req_head_buf_cd_hsk_done_nxt = snp_req_head_buf_cd_hsk_done_set & (~snp_req_head_buf_cd_hsk_done_clr);
assign snp_req_head_buf_cd_ena          = snp_req_head_buf_cd_hsk_done_set | snp_req_head_buf_cd_hsk_done_clr;

std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_CR_HSK_DONE (.clk(clk),.en(snp_req_head_buf_cr_ena) ,.d(snp_req_head_buf_cr_hsk_done_nxt) ,.q(snp_req_head_buf_cr_hsk_done));
std_dffe #(.WIDTH(1)) U_STA_REG_HEAD_BUF_CD_HSK_DONE (.clk(clk),.en(snp_req_head_buf_cd_ena) ,.d(snp_req_head_buf_cd_hsk_done_nxt) ,.q(snp_req_head_buf_cd_hsk_done));

// 4.4.6 if cd channel not hsk immediately, buffer the data
assign snp_req_head_buf_cd_data_hold_nxt = snp_l1d_bank_snp_s3_req_line_data_i;
assign snp_req_head_buf_cd_data_hold_ena = snp_l1d_bank_snp_s3_req_vld_o &
                                           (~snp_req_head_buf_cd_hsk_done_nxt |
                                            snp_req_head_buf_cd_hsk_done_nxt & ~snp_resp_if_cd_o.cdlast
                                            );
std_dffe #(.WIDTH(L1D_BANK_LINE_DATA_SIZE)) U_DAT_REG_HEAD_BUF_CD_DATA_HOLD (.clk(clk),.en(snp_req_head_buf_cd_data_hold_ena) ,.d(snp_req_head_buf_cd_data_hold_nxt) ,.q(snp_req_head_buf_cd_data_hold));
endmodule
/* verilator lint_on PINCONNECTEMPTY */
