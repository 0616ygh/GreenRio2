// Copyright 2021 RISC-V International Open Source Laboratory (RIOS Lab). All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

`ifdef USE_VERILATOR
`include "./include/riscv_pkg.sv"
`include "./include/rvh_pkg.sv"
`include "./include/rvh_l1d_pkg.sv"
`include "./include/uop_encoding_pkg.sv"
`endif //USE_VERILATOR
/* verilator lint_off PINCONNECTEMPTY */
module rvh_l1d_ewrq
  import rvh_pkg::*;
  // import uop_encoding_pkg::*;
  import rvh_l1d_pkg::*;
#(
  parameter int BANK_ID=0
)
(
  //------------------------------------------------------
  // new ewrq req
  input  logic                      l1d_ewrq_new_ewrq_valid_i,
  input  logic [L1D_BANK_LINE_ADDR_SIZE-1:0] l1d_ewrq_new_ewrq_addr_i,
  input  logic [L1D_BANK_LINE_DATA_SIZE-1:0] l1d_ewrq_new_ewrq_dat_i,
  output logic                      l1d_ewrq_new_ewrq_ready_o,

  // output data and valid
  output logic[N_EWRQ-1:0][L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_addr_o,
  output logic[N_EWRQ-1:0]                     ewrq_vld_o,

  //------------------------------------------------------
  // MEM NOC
  // AW 
  output logic              l2_req_if_awvalid,
  input  logic              l2_req_if_awready,
  output cache_mem_if_aw_t  l2_req_if_aw,
  // W 
  output logic              l2_req_if_wvalid,
  input  logic              l2_req_if_wready,
  output cache_mem_if_w_t   l2_req_if_w,
  // B
  input  logic              l2_resp_if_bvalid,
  output logic              l2_resp_if_bready,
  input  cache_mem_if_b_t   l2_resp_if_b,

  // else
  input  logic              rst, clk
);

  mem_fsm_reg_t     mem_req_ff, mem_req_nxt;
  logic             wlast_ff;

  logic   resp_ram_ready, req_ram_ready, is_mshr_word;
  //==========================================================
  // command fifo
  // {{{
  logic aw_fifo_re, aw_fifo_we, aw_fifo_empty;
  logic w_fifo_re, w_fifo_we, w_fifo_empty;
  logic aw_fifo_re_ff, w_fifo_re_ff;
  logic [L1D_BANK_LINE_ADDR_SIZE-1:0] aw_fifo_din, aw_fifo_dout;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0] w_fifo_din, w_fifo_dout;

  logic aw_fifo_not_empty, w_fifo_not_empty;
  logic aw_fifo_enqueue_rdy, w_fifo_enqueue_rdy;
  
  assign aw_fifo_empty = ~aw_fifo_not_empty;
  assign w_fifo_empty  = ~w_fifo_not_empty;
  assign l1d_ewrq_new_ewrq_ready_o = aw_fifo_enqueue_rdy & w_fifo_enqueue_rdy;
  
  // write address command fifo{{{
  sp_fifo_dat_vld_output
  #(
    .payload_t      (logic[L1D_BANK_LINE_ADDR_SIZE-1:0]),
    // .ENQUEUE_WIDTH  (1),
    // .DEQUEUE_WIDTH  (1),
    .DEPTH          (N_EWRQ),
    .MUST_TAKEN_ALL (1)
  )
  AW_FIFO_U
  (
    // Enqueue
    .enqueue_vld_i          (aw_fifo_we         ),
    .enqueue_payload_i      (aw_fifo_din        ),
    .enqueue_rdy_o          (aw_fifo_enqueue_rdy),    
    // Dequeue
    .dequeue_vld_o          (aw_fifo_not_empty  ),
    .dequeue_payload_o      (aw_fifo_dout       ),
    .dequeue_rdy_i          (aw_fifo_re         ),
    
    // output data and valid
    .payload_dff            (ewrq_addr_o        ),
    .payload_vld_dff        (ewrq_vld_o         ),

    .flush_i                (1'b0               ),
    
    .clk                    (clk),
    .rst                    (~rst)
  );
  
  // write data command fifo{{{
  mp_fifo
  #(
    .payload_t      (logic[L1D_BANK_LINE_DATA_SIZE-1:0]),
    .ENQUEUE_WIDTH  (1),
    .DEQUEUE_WIDTH  (1),
    .DEPTH          (N_EWRQ),
    .MUST_TAKEN_ALL (1)
  )
  W_FIFO_U
  (
    // Enqueue
    .enqueue_vld_i          (w_fifo_we          ),
    .enqueue_payload_i      (w_fifo_din         ),
    .enqueue_rdy_o          (w_fifo_enqueue_rdy ),    
    // Dequeue
    .dequeue_vld_o          (w_fifo_not_empty   ),
    .dequeue_payload_o      (w_fifo_dout        ),
    .dequeue_rdy_i          (w_fifo_re          ),
    
    .flush_i                (1'b0               ),
    
    .clk                    (clk),
    .rst                    (~rst)
  );

  // sp_fifo_dat_vld_output
  // #(
  //   .payload_t      (logic[L1D_BANK_LINE_ADDR_SIZE-1:0]),
  //   // .ENQUEUE_WIDTH  (1),
  //   // .DEQUEUE_WIDTH  (1),
  //   .DEPTH          (N_EWRQ),
  //   .MUST_TAKEN_ALL (1)
  // )
  // W_FIFO_ARRD_VLD_U
  // (
  //   // Enqueue
  //   .enqueue_vld_i          (aw_fifo_we          ),
  //   .enqueue_payload_i      (aw_fifo_din         ),
  //   .enqueue_rdy_o          (   ),    
  //   // Dequeue
  //   .dequeue_vld_o          (   ),
  //   .dequeue_payload_o      (   ),
  //   .dequeue_rdy_i          (aw_fifo_re          ),
    
  //   // output data and valid
  //   .payload_dff            (ewrq_dat_o         ),
  //   .payload_vld_dff        (ewrq_vld_o         ),

  //   .flush_i                (1'b0               ),
    
  //   .clk                    (clk),
  //   .rst                    (~rst)
  // );
  
  //==========================================================
  // FIFO interface
  // {{{

  //==========================================================
  // aw fifo interface
  //==========================================================
  // Initiate a write back when a miss request occurs and the allocated $line is dirty, 
  // the allocated way_id is flop version of v.s3.way_id 
  assign aw_fifo_we  = l1d_ewrq_new_ewrq_valid_i & w_fifo_enqueue_rdy;
  // Allocated mshr entry ID for the req initiated the mem write 
  assign aw_fifo_din = l1d_ewrq_new_ewrq_addr_i;
  // Proceed to next mem write when aw channel handshake completed
  assign aw_fifo_re  = l2_req_if_awvalid & l2_req_if_awready;

  //==========================================================
  // w fifo interface
  //==========================================================
  // Initiate a write back data when a miss request occurs and the allocated $line is dirty, 
  // the allocated way_id is flop version of v.s3.way_id 
  assign w_fifo_we  = l1d_ewrq_new_ewrq_valid_i & aw_fifo_enqueue_rdy; 
  // allocated mshr entry ID for the req initiated the mem write 
  assign w_fifo_din = l1d_ewrq_new_ewrq_dat_i;
  // Proceed to next mem write when w channel handsake completed for either first or last burst
  assign w_fifo_re  = (~mem_req_ff.wvalid | l2_req_if_w.wlast) & l2_req_if_wvalid & l2_req_if_wready; 

  
  // }}}
  //==========================================================
  // Mem-NOC interface
  // {{{
  
  //==========================================================
  // AW channel
  //==========================================================
  logic [L1D_BANK_LINE_ADDR_SIZE-1:0] ewrq_aw;
  assign  ewrq_aw       = aw_fifo_dout;
  assign  l2_req_if_awvalid     = ~aw_fifo_empty & ~aw_fifo_re_ff; // remove dependency from w channel
  // cc_tag_pway[replace_way_id][16:15] + allocated mshr entry ID(ar_fifo_dout)
  assign  l2_req_if_aw.awid.tid     = '0;
  assign  l2_req_if_aw.awid.bid     = {1'b0, BANK_ID[MEMNOC_TID_MASTERID_SIZE-1-1:0]}; // msb 1 represents d$
  // mshr_bank[aw_fifo_dout]'s old tag, which is cc_tag_pway[replace_way_id] + bank_index
  assign  l2_req_if_aw.awaddr   = {aw_fifo_dout,  {L1D_BANK_OFFSET_WIDTH{1'b0}}};
  // write a full burst to memory
  assign  l2_req_if_aw.awlen    = BURST_SIZE-1;
  assign  l2_req_if_aw.awsize   = AXI_SIZE;
  assign  l2_req_if_aw.awburst  = 2'b01; // INCR mode


  //==========================================================
  // W channel
  //==========================================================
  logic [L1D_BANK_LINE_DATA_SIZE-1:0] data_ram_dout_ff, data_ram_dout;
  logic [L1D_BANK_LINE_DATA_SIZE-1:0] mshr_w;
  assign  mshr_w        = w_fifo_dout;
  //?? v.wvalid ?? 
  assign  l2_req_if_wvalid = mem_req_ff.wvalid & mem_req_nxt.wvalid & ~w_fifo_re_ff;
  // mshr_bank[w_fifo_dout]'s old tag[16:15], which is cc_tag_pway[replace_way_id][19:18] + allocated mshr entry ID
  assign  l2_req_if_w.wid.tid     = '1;
  assign  l2_req_if_w.wid.bid     = {1'b0, BANK_ID[MEMNOC_TID_MASTERID_SIZE-1-1:0]}; // msb 1 represents d$
  // send 256-bit data over 4 cycles
  assign  l2_req_if_w.wdata = mshr_w[MEM_DATA_WIDTH*mem_req_ff.wdata_offset +: MEM_DATA_WIDTH];
  assign  l2_req_if_w.wlast = &mem_req_ff.wdata_offset;


  //==========================================================
  // B channel
  //==========================================================
  assign l2_resp_if_bready = '1;


  // }}}
  //==========================================================
  // Write back data pipe 
  //==========================================================
  // {{{
  // Pipe valid for write back data pipe. Valid asserted for following cases.
  // first or after last burst 
  // no new transactions, w_fifo_empty happends after w_fifo_re which is the last l2_req_if_wready
  // mshr_w => mshr_bank[w_fifo_dout]
  // way_id    => replace_way_id at s2
  always_comb begin
    mem_req_nxt.wvalid = w_fifo_empty                                                ? 1'b0 : 
                                    (~mem_req_ff.wvalid | wlast_ff) & ~w_fifo_empty  ? 1'b1 :
                                                                                                  mem_req_ff.wvalid;
  end
  // Counter to indicate how many chunk of write back data is accepted. Updates it for
  // 1. W channel handshake completed, reset the offset
  // 2. Handshake completed and write data pipe is valid and not prceed to next mem write, increment offset  
  always_comb begin
    mem_req_nxt.wdata_offset = ((~mem_req_ff.wvalid | l2_req_if_w.wlast) & l2_req_if_wready) ? {L1D_BANK_OFFSET_WIDTH{1'b0}}      :
                                (l2_req_if_wready & mem_req_ff.wvalid & ~w_fifo_re_ff)       ?  mem_req_ff.wdata_offset + 1  :
                                                                                                mem_req_ff.wdata_offset;
  end




  //==========================================================
  // write data state machine
  always_ff @ (posedge clk) begin
    wlast_ff <= l2_req_if_wvalid & l2_req_if_w.wlast & l2_req_if_wready;
  end

  //==========================================================

  always_ff @ (posedge clk) begin
/* verilator lint_off SYNCASYNCNET */
    if (~rst) begin
/* verilator lint_on SYNCASYNCNET */
      mem_req_ff.wvalid <= '0;
      // mem_req_ff.waddr <= '0;
      mem_req_ff.wdata_offset <= '0;
      // mem_req_ff.rdata_pipe_valid <='0;

    end else begin
    
      mem_req_ff   <= mem_req_nxt;

    end

      aw_fifo_re_ff <= aw_fifo_re;
      w_fifo_re_ff  <= w_fifo_re;
  end

endmodule
/* verilator lint_on PINCONNECTEMPTY */
