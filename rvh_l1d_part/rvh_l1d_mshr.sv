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
module rvh_l1d_mshr
  import rvh_l1d_pkg::*;
#(
  parameter int BANK_ID=0
)
(
  //------------------------------------------------------
  // cache control logic
  input   logic               new_mshr_valid_i,
  input   mshr_t              new_mshr_i,
  input   mshr_id_t           new_mshr_id_i,
  input   logic               dirty, // one cycle late from new_mshr_i (pipeline delay)
  output  mshr_t [N_MSHR-1:0] mshr_bank_o,
  output  logic  [N_MSHR-1:0] mshr_bank_valid_o,
  output  logic  [N_MSHR-1:0] mshr_bank_no_resp_o,
  output  logic  [N_MSHR-1:0] mshr_bank_sent_o,
  // output  mshr_t              mshr_resp,

  //------------------------------------------------------
  // mlfb intf
  input  logic                           mlfb_mshr_dealloc_valid_i,
  input  logic[N_MSHR_W-1:0]             mlfb_mshr_dealloc_idx_i,
  output logic                           mlfb_mshr_dealloc_ready_o,

  //------------------------------------------------------
  // MEM NOC
  // AR
  output logic              l2_req_if_arvalid,
  input  logic              l2_req_if_arready,
  output cache_mem_if_ar_t  l2_req_if_ar,

  // kill all the load in pipeline, and mark all the load miss in mshr "no_resp"
  // if "no_resp" set, this load should refill but no resp to lsu(if set of clear for a store, no effect)
  input  logic              rob_flush_i,
  
  // else
  input  logic              rst, clk
);
  genvar i;

  mshr_t [N_MSHR-1:0] mshr_bank;

  logic [N_MSHR-1:0] mshr_bank_valid;
  logic [N_MSHR-1:0] mshr_bank_valid_nxt;
  logic [N_MSHR-1:0] mshr_bank_valid_set_nxt;
  logic [N_MSHR-1:0] mshr_bank_valid_clr_nxt;
  logic [N_MSHR-1:0] mshr_bank_valid_ena;

  logic [N_MSHR-1:0] mshr_bank_no_resp;
  logic [N_MSHR-1:0] mshr_bank_no_resp_nxt;
  logic [N_MSHR-1:0] mshr_bank_no_resp_nxt_ena;
  logic [N_MSHR-1:0] mshr_bank_no_resp_nxt_set;
  logic [N_MSHR-1:0] mshr_bank_no_resp_nxt_clr;

  logic [N_MSHR-1:0] mshr_bank_sent;
  logic [N_MSHR-1:0] mshr_bank_sent_nxt;
  logic [N_MSHR-1:0] mshr_bank_sent_nxt_ena;
  logic [N_MSHR-1:0] mshr_bank_sent_nxt_set;
  logic [N_MSHR-1:0] mshr_bank_sent_nxt_clr;

  logic   resp_ram_ready, req_ram_ready, is_mshr_word;
  //==========================================================
  // command fifo
  // {{{
  logic ar_fifo_re;
  // logic ar_fifo_empty;
  logic ar_fifo_dout_vld;
  logic ar_fifo_re_ff;
  logic ar_fifo_we;
  mshr_id_t  ar_fifo_din, ar_fifo_dout;

  // read address command fifo{{{
  // l2_cmd_fifo #(.WIDTH(N_MSHR_W), .DEPTH(N_MSHR)) AR_FIFO(.*,
  //   .din(ar_fifo_din),
  //   .we(ar_fifo_we),
  //   .re(ar_fifo_re),
  //   .empty(ar_fifo_empty),
  //   .dout(ar_fifo_dout)); 


    mp_fifo
    #(
        .PAYLOAD_WIDTH          (N_MSHR_W  ),
        .ENQUEUE_WIDTH      (1                                      ),
        .DEQUEUE_WIDTH      (1                                      ),
        .DEPTH              (N_MSHR                                 ),
        .MUST_TAKEN_ALL     (1                                      )
    )
    AR_FIFO
    (
        // Enqueue
        .enqueue_vld_i          (ar_fifo_we          ),
        .enqueue_payload_i      (ar_fifo_din         ),
        .enqueue_rdy_o          (                    ),
        // Dequeue
        .dequeue_vld_o          (ar_fifo_dout_vld    ),
        .dequeue_payload_o      (ar_fifo_dout        ),
        .dequeue_rdy_i          (ar_fifo_re          ),
        
        .flush_i                (1'b0                ),
        
        .clk                    (clk                 ),
        .rst                    (~rst                 )
    );
  
    // }}}
  // }}}

  //==========================================================
  // FIFO interface
  // {{{

  //==========================================================
  // ar fifo interface
  //==========================================================
  // logic  write_miss_no_write_alloc;
  mshr_t mshr_req;
  logic  mshr_req_valid;

  // Initiate a mem read for three cases.
  // Port0:
  // 1. read/write miss
  // 2. write miss in no write allocate mode  
  assign ar_fifo_we = new_mshr_valid_i & (new_mshr_i.no_write_alloc & new_mshr_i.rw | ~new_mshr_i.flush);

  // req_ff.id is allocated mshr entry ID
  assign ar_fifo_din = new_mshr_id_i;

  // Proceed to next mem read for following cases
  // 1. ar channel handshake completed
  // 2. the initiated mem read is originated from a flush request(flush miss dirty?) 
  //    which means the corresponding mshr_bank[ar_fifo_dout] is a flush
  // 3. the inititated mem read is originated from a write miss in no write allocate mode
  //     and the data/tag ram is ready for the corresponding way_id, which is the replace_way_id at s2 
  always_comb begin
    ar_fifo_re = l2_req_if_arvalid  & l2_req_if_arready                   | 
                 mshr_req_valid & mshr_req.flush & ar_fifo_dout_vld;// |
                //  write_miss_no_write_alloc & req_ram_ready;
  end
  // mshr_req  => mshr_bank[ar_fifo_dout] 
  // assign write_miss_no_write_alloc = mshr_req_valid & mshr_req.rw & mshr_req.no_write_alloc & ar_fifo_dout_vld;
 

  // }}}
  //==========================================================
  // Mem-NOC interface
  // {{{

  //==========================================================
  // AR channel
  //==========================================================
  // req to MEM NOC, addressed by output from read_address_fifo
  assign mshr_req = mshr_bank[ar_fifo_dout];
  assign mshr_req_valid = mshr_bank_valid[ar_fifo_dout] & ar_fifo_dout_vld;

    // As long as there is mem read req in ar_fifo and it's not a flush in mshr_bank[ar_fifo_dout]  
  // Basically drive ar channel for read or standard write allocate case. 
  // 1-cycle gap between consecutive l2_req_if_arvalid due to dff_ar_fifo_re 
  assign l2_req_if_arvalid = ar_fifo_dout_vld & ~mshr_req.no_write_alloc & ~mshr_req.flush & ~ar_fifo_re_ff; 
  // new_tag[16:15], the tag coming with req at the very first beginning + allocated mshr entry ID
  assign l2_req_if_ar.arid.tid = ar_fifo_dout;
  assign l2_req_if_ar.arid.bid = {1'b0, BANK_ID[MEMNOC_TID_MASTERID_SIZE-1-1:0]}; // msb 1 represents d$
  // tag + index that coming with req at the very first beginning 
  assign l2_req_if_ar.araddr  = {mshr_req.new_tag, mshr_req.bank_index, {L1D_BANK_OFFSET_WIDTH{1'b0}}};
  // read a full burst from memory(2'b11)
  assign l2_req_if_ar.arlen   = BURST_SIZE-1;
  assign l2_req_if_ar.arsize  = AXI_SIZE;
  assign l2_req_if_ar.arburst = 2'b01; // INCR mode
  
  std_dffr #(.WIDTH(1)) U_AR_FIFO_RE_FF (.clk(clk),.rstn(rst),.d(ar_fifo_re),.q(ar_fifo_re_ff));

  // }}}
  //==========================================================
  // FSM for mshr bank valid (de-allocation) 
  //==========================================================  
  // mlfb intf
  assign mlfb_mshr_dealloc_ready_o = 1'b1;
  always_comb begin
    mshr_bank_valid_nxt = mshr_bank_valid;
    for (int i=0; i<N_MSHR; i++) begin
        mshr_bank_valid_set_nxt[i] = new_mshr_valid_i & (new_mshr_id_i == N_MSHR_W'(i));
        mshr_bank_valid_clr_nxt[i] = mlfb_mshr_dealloc_valid_i & (mlfb_mshr_dealloc_idx_i[N_MSHR_W-1:0] == N_MSHR_W'(i));

        mshr_bank_valid_nxt[i] = (mshr_bank_valid[i] | mshr_bank_valid_set_nxt[i]) & ~mshr_bank_valid_clr_nxt[i];  // read/write miss with clean/dirty
        mshr_bank_valid_ena[i] = mshr_bank_valid_set_nxt[i] | mshr_bank_valid_clr_nxt[i];
    end
  end

  //==========================================================


  // mshr valid
  generate
    for(i = 0; i < N_MSHR; i++) begin: gen_mshr_bank_valid
      std_dffre #(.WIDTH(1)) U_MSHR_BANK_VALID (.clk(clk),.rstn(rst), .en(mshr_bank_valid_ena[i]), .d(mshr_bank_valid_nxt[i]),.q(mshr_bank_valid[i]));
    end
  endgenerate

  // mshr no_resp
  generate
    for(i = 0; i < N_MSHR; i++) begin: gen_mshr_bank_no_resp_nxt_ena
      assign mshr_bank_no_resp_nxt_ena[i] = mshr_bank_no_resp_nxt_set[i] | mshr_bank_no_resp_nxt_clr[i];
      assign mshr_bank_no_resp_nxt_set[i] = rob_flush_i;
      assign mshr_bank_no_resp_nxt_clr[i] = new_mshr_valid_i & (new_mshr_id_i == N_MSHR_W'(i));
    end
  endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) (mshr_bank_no_resp_nxt_clr & mshr_bank_no_resp_nxt_set != '0)|-> (new_mshr_i.rw | rob_flush_i))
    else $fatal("mshr: set and clr no_resp at the same cycle for a load req");
`endif

  always_comb begin
    for(int i = 0; i < N_MSHR; i++) begin
      mshr_bank_no_resp_nxt[i] = mshr_bank_no_resp[i];
      if(mshr_bank_no_resp_nxt_ena[i]) begin
        mshr_bank_no_resp_nxt[i] = mshr_bank_no_resp_nxt_set[i] | ~mshr_bank_no_resp_nxt_clr[i]; // set when rob_flush_i, clear when new_mshr_valid_i
      end
    end
  end

  generate
    for(i = 0; i < N_MSHR; i++) begin: gen_mshr_bank_no_resp
      std_dffre #(.WIDTH(1)) U_MSHR_BANK_NO_RESP (.clk(clk), .rstn(rst), .en(mshr_bank_no_resp_nxt_ena[i]), .d(mshr_bank_no_resp_nxt[i]),.q(mshr_bank_no_resp[i]));
    end
  endgenerate

  // mshr sent
  generate
    for(i = 0; i < N_MSHR; i++) begin: gen_mshr_bank_sent_nxt_ena
      assign mshr_bank_sent_nxt_ena[i] = mshr_bank_sent_nxt_set[i] | mshr_bank_sent_nxt_clr[i];
      assign mshr_bank_sent_nxt_set[i] = ar_fifo_re & ar_fifo_dout_vld & (ar_fifo_dout == N_MSHR_W'(i));
      assign mshr_bank_sent_nxt_clr[i] = new_mshr_valid_i & (new_mshr_id_i == N_MSHR_W'(i));
    end
  endgenerate

`ifndef SYNTHESIS
  assert property(@(posedge clk)disable iff(~rst) ((mshr_bank_sent_nxt_clr & mshr_bank_sent_nxt_set) == '0))
    else $fatal("mshr: set and clr mshr sent at the same cycle for a load req");
`endif

  always_comb begin
    for(int i = 0; i < N_MSHR; i++) begin
      mshr_bank_sent_nxt[i] = mshr_bank_sent[i];
      if(mshr_bank_sent_nxt_ena[i]) begin
        mshr_bank_sent_nxt[i] = mshr_bank_sent_nxt_set[i] | ~mshr_bank_sent_nxt_clr[i]; // set when axi ar channel hsk, clear when new_mshr_valid_i
      end
    end
  end

  generate
    for(i = 0; i < N_MSHR; i++) begin: gen_mshr_bank_sent
      std_dffre #(.WIDTH(1)) U_MSHR_BANK_SENT (.clk(clk), .rstn(rst), .en(mshr_bank_sent_nxt_ena[i]), .d(mshr_bank_sent_nxt[i]),.q(mshr_bank_sent[i]));
    end
  endgenerate

  // mshr
  generate
    for(i = 0; i < N_MSHR; i++) begin: gen_mshr_bank
      std_dffre #(.WIDTH($bits(mshr_t))) U_MSHR_BANK (.clk(clk), .rstn(rst), .en(mshr_bank_valid_set_nxt[i]), .d(new_mshr_i),.q(mshr_bank[i]));
    end
  endgenerate
  
  assign mshr_bank_o          = mshr_bank;
  assign mshr_bank_valid_o    = mshr_bank_valid;
  assign mshr_bank_no_resp_o  = mshr_bank_no_resp;
  assign mshr_bank_sent_o     = mshr_bank_sent;

endmodule
/* verilator lint_on PINCONNECTEMPTY */
