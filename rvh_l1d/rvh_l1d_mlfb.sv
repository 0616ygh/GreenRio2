`ifdef USE_VERILATOR
`include "./include/riscv_pkg.sv"
`include "./include/rvh_pkg.sv"
`include "./include/rvh_l1d_pkg.sv"
`include "./include/uop_encoding_pkg.sv"
`endif //USE_VERILATOR
/* verilator lint_off PINCONNECTEMPTY */
module rvh_l1d_mlfb
    import rvh_pkg::*;
    import rvh_l1d_pkg::*;
#(
     parameter ENTRY_NUM=8
    ,parameter ENTRY_IDX=$clog2(ENTRY_NUM)
    ,parameter BANK_ID=0
)(
     input logic clk
    ,input logic rstn
    ,input logic rob_flush_i

    ,input logic l1d_l2_rd_resp_valid
    ,output logic l1d_l2_rd_resp_ready
    ,input cache_mem_if_r_t l1d_l2_rd_resp

    ,output logic mlfb_mshr_dealloc_valid
    ,input logic mlfb_mshr_dealloc_ready
    ,output logic[N_MSHR_W -1:0] mlfb_mshr_dealloc_idx
    
    ,output logic[N_MSHR_W -1:0]   mlfb_mshr_head_rd_idx
    ,input  mshr_t                  mlfb_mshr_head_rd_mshr_entry
    ,input  logic                   mlfb_mshr_head_rd_mshr_entry_no_resp
//    ,output logic[ENTRY_IDX-1:0]    mlfb_mshr_head_pending_rd_idx
//    ,input  mshr_t                  mlfb_mshr_head_pending_rd_mshr_entry
    
    ,output                           mlfb_lru_peek_valid
    ,output[L1D_BANK_SET_INDEX_WIDTH-1:0]  mlfb_lru_peek_set_idx
    ,input[L1D_BANK_WAY_INDEX_WIDTH-1:0]   mlfb_lru_peek_dat
    
    ,output[L1D_BANK_SET_INDEX_WIDTH-1:0]  mlfb_lst_peek_set_idx
    ,input rrv64_l1d_lst_t  mlfb_lst_peek_dat
    ,input [L1D_BANK_WAY_INDEX_WIDTH-1:0] mlfb_lst_peek_avail_way_idx
    
    ,output   mlfb_lst_check_valid
    ,output   [L1D_BANK_SET_INDEX_WIDTH-1:0]  mlfb_lst_check_set_idx
    ,output   [L1D_BANK_WAY_INDEX_WIDTH-1:0]  mlfb_lst_check_way_idx
    ,input    mlfb_lst_check_ready

    // ,output mlfb_lst_lock_wr_en
    // ,output[L1D_BANK_SET_INDEX_WIDTH-1:0] mlfb_lst_lock_wr_set_idx
    // ,output[L1D_BANK_WAY_INDEX_WIDTH-1:0] mlfb_lst_lock_wr_way_idx
    // ,output[1:0] mlfb_lst_lock_wr_dat
    
    ,output logic  mlfb_cache_evict_req_valid
    ,input  logic  mlfb_cache_evict_req_ready
    ,output rrv64_l1d_evict_req_t mlfb_cache_evict_req
    
    ,output logic mlfb_cache_refill_req_valid
    ,input logic  mlfb_cache_refill_req_ready
    ,output rrv64_l1d_refill_req_t mlfb_cache_refill_req

//    ,output logic mlfb_stb_rd_resp_valid
//    ,output rrv64_l1d_cache_stb_rd_resp_t mlfb_stb_rd_resp
//    ,output[L1D_BANK_LINE_DATA_SIZE-1:0] mlfb_stb_rd_resp_line_dat
    
//    ,output logic l1d_scu_rnsd_coh_ack_valid
//    ,output rrv64_l1d_scu_coh_ack_t l1d_scu_rnsd_coh_ack
//    ,output logic mlfb_head_buf_valid
    ,input logic                    s1_valid
    ,input logic[PADDR_WIDTH-1:0]   s1_paddr
    ,input logic                    s2_valid
    ,input logic[PADDR_WIDTH-1:0]   s2_paddr

    // snoop req: stall mlfb refill transaction if no sent-out line addr hit in mshr(cond s0.3)
    ,input logic                    snoop_stall_refill_i
);
//mlfb tail update, wr side
logic[$clog2(BURST_SIZE) -1:0] line_seg_wr_cnt;
logic[$clog2(BURST_SIZE) -1:0] line_seg_wr_cnt_nxt;
logic                                      line_seg_wr_cnt_ena;
logic[BURST_SIZE-1:0]          line_seg_wr_ena;

logic[ENTRY_NUM-1:0]                       mlfb_mshr_info_set;
logic[ENTRY_NUM-1:0][N_MSHR_W-1:0]        mlfb_mshr_idx_nxt;
logic[ENTRY_NUM-1:0][N_MSHR_W-1:0]        mlfb_mshr_idx;
logic[ENTRY_NUM-1:0]                       mlfb_err_nxt;
logic[ENTRY_NUM-1:0]                       mlfb_err;
logic[ENTRY_NUM-1:0][$bits(rrv64_mesi_type_e)-1:0] mlfb_mesi_sta_nxt;
logic[ENTRY_NUM-1:0][$bits(rrv64_mesi_type_e)-1:0] mlfb_mesi_sta;
// logic[ENTRY_NUM-1:0][RRV64_SCU_SST_IDX_W-1:0] mlfb_sst_idx_nxt;
// logic[ENTRY_NUM-1:0][RRV64_SCU_SST_IDX_W-1:0] mlfb_sst_idx;
// logic[ENTRY_NUM-1:0] mlfb_l2_hit_nxt;
// logic[ENTRY_NUM-1:0] mlfb_l2_hit;

//mlfb head read, rd side
logic[BURST_SIZE-1:0] fifo_head_valid;
logic[BURST_SIZE-1:0][MEM_DATA_WIDTH-1:0] head_seg_dat;
logic[L1D_BANK_LINE_DATA_SIZE-1:0] head_full_dat;
//mlfb fifo
rrv64_l1d_mlfb_t[ENTRY_NUM-1:0] mlfb_fifo;
logic[BURST_SIZE-1:0][ENTRY_IDX-1:0] tail_idx;
logic[BURST_SIZE-1:0][ENTRY_IDX-1:0] head_idx;
//mlfb head buf
rrv64_l1d_mlfb_head_buf_t head_buf;
//sta
logic head_buf_valid_set;
logic head_buf_valid_clr;
logic head_buf_valid_ena;
logic head_buf_valid_nxt;
logic head_buf_valid;
logic head_buf_peek_done_set;
logic head_buf_peek_done_clr;
logic head_buf_peek_done_ena;
logic head_buf_peek_done_nxt;
logic head_buf_peek_done;
logic head_buf_evict_done_set;
logic head_buf_evict_done_clr;
logic head_buf_evict_done_ena;
logic head_buf_evict_done_nxt;
logic head_buf_evict_done;
logic head_buf_check_done_set;
logic head_buf_check_done_clr;
logic head_buf_check_done_ena;
logic head_buf_check_done_nxt;
logic head_buf_check_done;
logic head_buf_refill_done_set;
logic head_buf_refill_done_clr;
logic head_buf_refill_done_ena;
logic head_buf_refill_done_nxt;
logic head_buf_refill_done;
logic [L1D_BANK_LINE_DATA_SIZE -1:0] mlfb_refill_dat_tmp;
logic [L1D_BANK_LINE_DATA_SIZE -1:0] mlfb_refill_dat_tmp_bit_mask;
logic head_buf_lsu_resp_done_set;
logic head_buf_lsu_resp_done_clr;
logic head_buf_lsu_resp_done_ena;
logic head_buf_lsu_resp_done_nxt;
logic head_buf_lsu_resp_done;
logic head_buf_stb_dat_done_set;
logic head_buf_stb_dat_done_clr;
logic head_buf_stb_dat_done_ena;
logic head_buf_stb_dat_done_nxt;
logic head_buf_stb_dat_done;
//dat
logic[L1D_BANK_LINE_DATA_SIZE-1:0] head_buf_line_dat_nxt;
logic[N_MSHR_W-1:0] head_buf_mshr_idx_nxt;
logic head_buf_err_nxt ;
rrv64_mesi_type_e head_buf_mesi_sta_nxt ;
rrv64_l1d_req_type_dec_t head_buf_lsu_req_type_dec_nxt;
// logic[RRV64_SCU_SST_IDX_W-1:0] head_buf_sst_idx_nxt ;
logic head_buf_l2_hit_nxt ;
logic[PADDR_WIDTH-1:0]  head_buf_paddr_nxt ;
logic [ROB_TAG_WIDTH-1:0]       head_buf_rob_tag_nxt;
logic [PREG_TAG_WIDTH-1:0]      head_buf_prd_nxt;
`ifdef RUBY
logic [RRV64_LSU_ID_WIDTH -1:0] head_buf_lsu_tag_nxt;
`endif
logic[L1D_STB_DATA_WIDTH-1:0]  head_buf_st_dat_nxt ;
logic[L1D_STB_DATA_WIDTH/8-1:0] head_buf_st_data_byte_mask_nxt;
rrv64_l1d_req_type_dec_t head_buf_req_type_dec_nxt ;
logic head_buf_no_resp_nxt;
logic [XLEN-1:0] head_buf_amo_st_data_nxt;
logic head_buf_stb_alloc_nxt;

logic[L1D_BANK_WAY_INDEX_WIDTH -1:0] head_buf_victim_way_idx_nxt;
logic[L1D_BANK_WAY_INDEX_WIDTH -1:0] head_buf_victim_way_idx;
logic head_buf_victim_set_full_nxt;
logic head_buf_victim_set_full;
logic head_buf_victim_way_clean_nxt;
logic head_buf_victim_way_clean;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] head_buf_avail_way_idx_nxt;
logic[L1D_BANK_WAY_INDEX_WIDTH-1:0] head_buf_avail_way_idx;
logic[L1D_BANK_WAY_NUM-1:0] lst_peek_valid_way;
logic mlfb_cache_peek_valid;
logic mlfb_cache_check_valid;
logic mlfb_cache_evict_valid ;
logic mlfb_cache_evict_bypass ;
logic mlfb_cache_refill_valid ;

logic mlfb_cache_peek_req_hsk;
logic mlfb_cache_evict_req_hsk;
logic mlfb_cache_refill_req_hsk;
logic mlfb_cache_lsu_resp_hsk;

logic op_b,op_hw,op_w,op_dw,ld_u;
logic[L1D_BANK_OFFSET_WIDTH-1:0] line_offset;
// logic[BURST_SIZE-1:0][ENTRY_IDX:0]entry_cnt;

wire mlfb_pipe_same_addr_haz;

logic clk_mlfb, clk_mlfb_en;
assign clk_mlfb_en = l1d_l2_rd_resp_valid | head_buf_valid_set;
rrv64_cell_clkgate U_ICG_MLFB (.clk_i(clk) ,.clk_enable_i(clk_mlfb_en) ,.clk_senable_i('0) ,.clk_gated_o(clk_mlfb));

logic [PADDR_WIDTH-L1D_BANK_OFFSET_WIDTH-1:0] head_buf_paddr_lineaddr;
logic [L1D_BANK_SET_INDEX_WIDTH-1:0] head_buf_paddr_idx;
logic [L1D_BANK_PADDR_TAG_WIDTH-1:0] head_buf_paddr_tag;
logic [L1D_BANK_OFFSET_WIDTH-1:0] head_buf_paddr_offset;

assign head_buf_paddr_lineaddr = head_buf.paddr[PADDR_WIDTH-1:L1D_BANK_OFFSET_WIDTH];
assign head_buf_paddr_idx      = head_buf.paddr[L1D_BANK_SET_INDEX_WIDTH+L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH-1:L1D_BANK_ID_INDEX_WIDTH+L1D_BANK_OFFSET_WIDTH];
assign head_buf_paddr_tag      = head_buf.paddr[PADDR_WIDTH-1-:L1D_BANK_PADDR_TAG_WIDTH];
assign head_buf_paddr_offset   = head_buf.paddr[L1D_BANK_OFFSET_WIDTH-1:0];

//main code
assign line_seg_wr_cnt_ena = l1d_l2_rd_resp_valid;
assign line_seg_wr_cnt_nxt = line_seg_wr_cnt + 1'b1;
std_dffre #(.WIDTH($clog2(BURST_SIZE))) U_STA_REG_LINE_SEG_RECEIVED (.clk(clk), .rstn(rstn), .en(line_seg_wr_cnt_ena), .d(line_seg_wr_cnt_nxt), .q(line_seg_wr_cnt));
genvar ii;
generate
for(ii=0; ii<BURST_SIZE; ii++) begin:GEN_MLFB_DATA_SEG

    assign line_seg_wr_ena[ii]=l1d_l2_rd_resp_valid&(line_seg_wr_cnt == ii);
    // sd_flop_fifo_rstn
    //     #(  .width($bits(l1d_l2_rd_resp.dat)),
    //         .depth(ENTRY_NUM)
    //     )
    //     U_RRV64_L1D_MLFB_DATA_SEG_FIFO
    //     (
    //     .clk (clk_mlfb),
    //     .rstn (rstn),
    //     .c_srdy(line_seg_wr_ena[ii]),//w valid
    //     .c_data(l1d_l2_rd_resp.dat), //w dat
    //     .p_srdy(fifo_head_valid[ii]), //not empty
    //     .p_drdy(head_buf_valid_set) ,//r valid
    //     .p_data(head_seg_dat[ii]),//r dat
    //     .usage (entry_cnt[ii]),
    //     .wr_addr(tail_idx[ii]),
    //     .rd_addr(head_idx[ii])
    // );

    mp_fifo_ptr_output
    #(
        .payload_t          (logic[$bits(l1d_l2_rd_resp.dat)-1:0]   ),
        .ENQUEUE_WIDTH      (1                                      ),
        .DEQUEUE_WIDTH      (1                                      ),
        .DEPTH              (ENTRY_NUM                              ),
        .MUST_TAKEN_ALL     (1                                      )
    )
    U_RRV64_L1D_MLFB_DATA_SEG_FIFO
    (
        // Enqueue
        .enqueue_vld_i          (line_seg_wr_ena[ii]    ),
        .enqueue_payload_i      (l1d_l2_rd_resp.dat     ),
        .enqueue_rdy_o          (                       ),
        // Dequeue
        .dequeue_vld_o          (fifo_head_valid[ii]   ),
        .dequeue_payload_o      (head_seg_dat[ii]       ),
        .dequeue_rdy_i          (head_buf_valid_set     ),

        // ptr output
        .enq_ptr_o              (tail_idx[ii]           ),
        .deq_ptr_o              (head_idx[ii]           ),
        
        .flush_i                (1'b0                   ),
        
        .clk                    (clk_mlfb               ),
        .rst                    (~rstn                  )
    );

    assign head_full_dat[MEM_DATA_WIDTH*ii +: MEM_DATA_WIDTH] = head_seg_dat[ii];
end
endgenerate

genvar jj;
generate
for(jj=0; jj<ENTRY_NUM; jj++)begin:GEN_MLFB_ENTRY
    assign mlfb_mshr_info_set[jj]   = line_seg_wr_ena[0] & (jj==tail_idx[0]);
    assign mlfb_mshr_idx_nxt[jj]    = l1d_l2_rd_resp.rid.tid;
    assign mlfb_err_nxt[jj]         = l1d_l2_rd_resp.err;
    assign mlfb_mesi_sta_nxt[jj]    = l1d_l2_rd_resp.mesi_sta;
    // assign mlfb_sst_idx_nxt[jj]     = l1d_l2_rd_resp.sst_idx;
//    assign mlfb_l2_hit_nxt[jj]      = l1d_l2_rd_resp.l2_hit;
    std_dffe #(.WIDTH(N_MSHR_W)) U_DAT_REG_MSHR_IDX (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_mshr_idx_nxt[jj]), .q((mlfb_mshr_idx[jj])));
    std_dffe #(.WIDTH(1)) U_DAT_REG_ERR (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_err_nxt[jj]), .q((mlfb_err[jj])));
    std_dffe #(.WIDTH($bits(rrv64_mesi_type_e))) U_DAT_REG_MESI_STA (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_mesi_sta_nxt[jj]), .q(mlfb_mesi_sta[jj]));
    // std_dffe #(.WIDTH(RRV64_SCU_SST_IDX_W)) U_DAT_REG_SST_IDX (.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_sst_idx_nxt[jj]), .q(mlfb_sst_idx[jj]));
    // std_dffe #(.WIDTH(1))U_DAT_REG_L2_HIT(.clk(clk), .en(mlfb_mshr_info_set[jj]), .d(mlfb_l2_hit_nxt[jj]), .q(mlfb_l2_hit[jj]));
    
    assign mlfb_fifo[jj].mshr_idx   = mlfb_mshr_idx[jj];
    assign mlfb_fifo[jj].err        = mlfb_err[jj];
    assign mlfb_fifo[jj].mesi_sta   = rrv64_mesi_type_e'(mlfb_mesi_sta[jj]);
    // assign mlfb_fifo[jj].sst_idx    = mlfb_sst_idx[jj];
//    assign mlfb_fifo[jj].l2_hit     = mlfb_l2_hit[jj];
end
endgenerate
//head buf
//valid
assign head_buf_valid_set = &fifo_head_valid & (~head_buf_valid | head_buf_valid_clr) & ~rob_flush_i; //TODO back to back
assign head_buf_valid_clr = head_buf.valid & head_buf.refill_done & mlfb_mshr_dealloc_ready;
assign head_buf_valid_ena = head_buf_valid_set | head_buf_valid_clr;
assign head_buf_valid_nxt = head_buf_valid_set ? 1'b1 : (~head_buf_valid_clr);
std_dffre#(.WIDTH(1)) U_STA_REG_HEAD_BUF_VALID(.clk(clk), .rstn(rstn), .en(head_buf_valid_ena), .d(head_buf_valid_nxt), .q(head_buf_valid));
assign head_buf.valid = head_buf_valid;
//data
assign head_buf_line_dat_nxt = head_full_dat;
assign head_buf_mshr_idx_nxt = mlfb_fifo[head_idx[0]].mshr_idx;
assign head_buf_err_nxt      = mlfb_fifo[head_idx[0]].err;
assign head_buf_mesi_sta_nxt = mlfb_fifo[head_idx[0]].mesi_sta;
// assign head_buf_sst_idx_nxt  = mlfb_fifo[head_idx[0]].sst_idx;
//assign head_buf_l2_hit_nxt   = mlfb_fifo[head_idx[0]].l2_hit;
// assign head_buf_srq_idx_nxt  = mlfb_mshr_head_rd_mshr_entry.srq_idx;
// assign head_buf_lsu_req_nxt  = mlfb_mshr_head_rd_mshr_entry.mshr_req.lsu_req;
// assign head_buf_lsu_req_type_dec_nxt = mlfb_mshr_head_rd_mshr_entry.mshr_req.lsu_req_type_dec;
assign head_buf_paddr_nxt = {mlfb_mshr_head_rd_mshr_entry.new_tag, mlfb_mshr_head_rd_mshr_entry.bank_index, mlfb_mshr_head_rd_mshr_entry.offset};
assign head_buf_rob_tag_nxt = mlfb_mshr_head_rd_mshr_entry.rob_tag;
assign head_buf_prd_nxt = mlfb_mshr_head_rd_mshr_entry.prd;
`ifdef RUBY
assign head_buf_lsu_tag_nxt = mlfb_mshr_head_rd_mshr_entry.lsu_tag;
`endif
assign head_buf_st_dat_nxt = mlfb_mshr_head_rd_mshr_entry.data;
assign head_buf_st_data_byte_mask_nxt = mlfb_mshr_head_rd_mshr_entry.data_byte_mask;
assign head_buf_req_type_dec_nxt   = mlfb_mshr_head_rd_mshr_entry.req_type_dec;

assign head_buf_no_resp_nxt   = mlfb_mshr_head_rd_mshr_entry_no_resp | rob_flush_i;

assign head_buf_amo_st_data_nxt = mlfb_mshr_head_rd_mshr_entry.amo_st_data;
 
//assign mlfb_refill_dat_tmp_mask   = head_buf.req_type_dec.op_b  ? {{(XLEN/8-1){1'b0}}, 1'b1}  :
//                                    head_buf.req_type_dec.op_hw ? {{(XLEN/8-2){1'b0}}, 2'b11} :
//                                    head_buf.req_type_dec.op_w  ? {{(XLEN/8-4){1'b0}}, 4'b1111} :
//                                    head_buf.req_type_dec.op_dw ? {{(XLEN/8-8){1'b0}}, 8'b11111111} : '0;
generate
    for(ii = 0; ii < L1D_BANK_LINE_DATA_SIZE/8; ii++) begin
        assign mlfb_refill_dat_tmp_bit_mask[ii*8 +: 8] = {8{head_buf.st_dat_byte_mask[ii]}};
    end
endgenerate
assign mlfb_refill_dat_tmp = head_buf.req_type_dec.is_st ? (head_buf.line_dat & ~mlfb_refill_dat_tmp_bit_mask) | head_buf.st_dat & mlfb_refill_dat_tmp_bit_mask
                                                         : head_buf.line_dat; 

std_dffe #(.WIDTH(L1D_BANK_LINE_DATA_SIZE)) U_DAT_REG_HEAD_BUF_LINE_DAT (.clk(clk), .en(head_buf_valid_set),  .d(head_buf_line_dat_nxt), .q(head_buf.line_dat));
std_dffe #(.WIDTH(N_MSHR_W))U_DAT_REG_HEAD_BUF_MSHR_IDX (.clk(clk), .en(head_buf_valid_set),  .d(head_buf_mshr_idx_nxt), .q(head_buf.mshr_idx));
std_dffe #(.WIDTH(1))U_DAT_REG_HEAD_BUF_LINE_ERR (.clk(clk), .en(head_buf_valid_set), .d(head_buf_err_nxt), .q(head_buf.err));
std_dffe #(.WIDTH($bits(rrv64_mesi_type_e)))U_DAT_REG_MESI_STA(.clk(clk), .en(head_buf_valid_set), .d(head_buf_mesi_sta_nxt), .q(head_buf.mesi_sta));
//std_dffe #(.WIDTH(RRV64_L1D_DATA_ECC_W * L1D_BANK_WAY_NUM))U_DAT_REG_HEAD_BUF_LINE_DAT_ECC_CKBIT (.clk(clk), .en(head_buf_valid_set),.d(head_buf_line_dat_ecc_ckbit_nxt), .q(head_buf.dat_ecc_ckbit));
//std_dffe #(.WIDTH(RRV64_L1D_TAG_ECC_W))U_DAT_REG_HEAD_BUF_LINE_TAG_ECC_CKBIT(.clk(clk), .en(head_buf_valid_set),.d(head_buf_line_tag_ecc_ckbit_nxt),.q(head_buf.tag_ecc_ckbit));
// std_dffe #(.WIDTH($bits(rrv64_lsu_l1d_req_t)))U_DAT_REG_HEAD_BUF_LSU_REQ (.clk(clk), .en(head_buf_valid_set),.d(head_buf_lsu_req_nxt),.q(head_buf_lsu_req));
// std_dffe #(.WIDTH($bits(rrv64_l1d_req_type_dec_t)))U_DAT_REG_HEAD_BUF_LSU_REQ_TYPE_DEC (.clk(clk),.en(head_buf_valid_set),.d(head_buf_lsu_req_type_dec_nxt),.q(head_buf_lsu_req_type_dec));
// std_dffe#(.WIDTH(RRV64_L1D_SRQ_IDX_W))U_DAT_REG_HEAD_BUF_SRQ_IDX (.clk(clk),.en(head_buf_valid_set),.d(head_buf_srq_idx_nxt),.q(head_buf_srq_idx));
//std_dffe#(.WIDTH(RRV64_SCU_SST_IDX_W))U_DAT_REG_HEAD_BUF_SST_IDX (.clk(clk),.en(head_buf_valid_set),.d(head_buf_sst_idx_nxt),.q(head_buf.sst_idx));
std_dffe#(.WIDTH($bits(head_buf_paddr_nxt)))U_DAT_REG_HEAD_BUF_PADDR(.clk(clk),.en(head_buf_valid_set),.d(head_buf_paddr_nxt),.q(head_buf.paddr));
std_dffe#(.WIDTH($bits(head_buf_rob_tag_nxt)))U_DAT_REG_HEAD_BUF_ROB_TAG(.clk(clk),.en(head_buf_valid_set),.d(head_buf_rob_tag_nxt),.q(head_buf.rob_tag));
std_dffe#(.WIDTH($bits(head_buf_prd_nxt)))U_DAT_REG_HEAD_BUF_PRD(.clk(clk),.en(head_buf_valid_set),.d(head_buf_prd_nxt),.q(head_buf.prd));
`ifdef RUBY
std_dffe#(.WIDTH($bits(head_buf_lsu_tag_nxt)))U_DAT_REG_HEAD_BUF_LSU_TAG(.clk(clk),.en(head_buf_valid_set),.d(head_buf_lsu_tag_nxt),.q(head_buf.lsu_tag));
`endif
std_dffe#(.WIDTH(L1D_STB_DATA_WIDTH))U_DAT_REG_HEAD_BUF_ST_DATA(.clk(clk),.en(head_buf_valid_set & head_buf_req_type_dec_nxt.is_st),.d(head_buf_st_dat_nxt),.q(head_buf.st_dat));
std_dffe#(.WIDTH(L1D_STB_DATA_WIDTH/8))U_DAT_REG_HEAD_BUF_ST_DATA_BYTE_MASK(.clk(clk),.en(head_buf_valid_set & head_buf_req_type_dec_nxt.is_st),.d(head_buf_st_data_byte_mask_nxt),.q(head_buf.st_dat_byte_mask));
std_dffe#(.WIDTH($bits(rrv64_l1d_req_type_dec_t)))U_DAT_REG_HEAD_BUF_REQ_TYPE(.clk(clk),.en(head_buf_valid_set),.d(head_buf_req_type_dec_nxt),.q(head_buf.req_type_dec));
std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_NO_RESP(.clk(clk),.en(head_buf_valid_set | rob_flush_i),.d(head_buf_no_resp_nxt),.q(head_buf.ld_no_resp));
std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_AMO_ST_DATA(.clk(clk),.en(head_buf_valid_set),.d(head_buf_amo_st_data_nxt),.q(head_buf.amo_st_data));

// std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_L2_HIT (.clk(clk),.en(head_buf_valid_set),.d(head_buf_l2_hit_nxt), .q(head_buf_l2_hit));
//assign head_buf.stb_alloc = mlfb_mshr_head_pending_rd_mshr_entry.stb_alloc;
//std_dffe#(.WIDTH(1))U_DAT_REG_HEAD_BUF_L2_HIT(.clk(clk),.en(head_buf_valid_set),.d(head_buf_l2_hit_nxt),.q(head_buf.l2_hit));

//line back operation: dat done/peek/evict/refill/response
assign mlfb_pipe_same_addr_haz = s1_valid & (s1_paddr[PADDR_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == head_buf_paddr_lineaddr) |
                                 s2_valid & (s2_paddr[PADDR_WIDTH-1:L1D_BANK_OFFSET_WIDTH] == head_buf_paddr_lineaddr) ;
///peek
assign head_buf_peek_done_set = mlfb_cache_peek_valid;
assign head_buf_peek_done_clr = head_buf_valid_clr;
assign head_buf_peek_done_ena = head_buf_peek_done_set | head_buf_peek_done_clr;
assign head_buf_peek_done_nxt = head_buf_peek_done_set & (~head_buf_peek_done_clr);
std_dffre#(.WIDTH(1))U_STA_REG_PEEK_DONE(.clk(clk), .rstn(rstn),.en(head_buf_peek_done_ena),.d(head_buf_peek_done_nxt),.q(head_buf_peek_done));
assign head_buf.peek_done = head_buf_peek_done;
//victim way
genvar kk;
generate
for(kk=0; kk<L1D_BANK_WAY_NUM; kk++) begin:GEN_MLFB_LST_PEEK_STA
    assign lst_peek_valid_way[kk] = (mlfb_lst_peek_dat.mesi_sta[kk]!=INVALID);
end
endgenerate
assign head_buf_avail_way_idx_nxt = mlfb_lst_peek_avail_way_idx;
assign head_buf_victim_way_idx_nxt = mlfb_lru_peek_dat;
assign head_buf_victim_set_full_nxt = &lst_peek_valid_way;
assign head_buf_victim_way_clean_nxt = (mlfb_lst_peek_dat.mesi_sta[mlfb_lru_peek_dat] != MODIFIED);
std_dffe#(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH))U_STA_REG_PEEK_AVAIL (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_avail_way_idx_nxt),.q(head_buf_avail_way_idx));
std_dffe#(.WIDTH(L1D_BANK_WAY_INDEX_WIDTH))U_STA_REG_PEEK_VICTIM (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_victim_way_idx_nxt), .q(head_buf_victim_way_idx));
std_dffe#(.WIDTH(1)) U_STA_REG_PEEK_SET_FULL (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_victim_set_full_nxt),.q(head_buf_victim_set_full));
std_dffe#(.WIDTH(1)) U_STA_REG_PEEK_WAY_CLEAN (.clk(clk),.en(head_buf_peek_done_set),.d(head_buf_victim_way_clean_nxt),.q(head_buf_victim_way_clean));
assign head_buf.victim_set_full     = head_buf_victim_set_full;
assign head_buf.victim_way_idx      = head_buf_victim_way_idx;
assign head_buf.avail_way_idx       = head_buf_avail_way_idx;
assign head_buf.victim_way_clean    = head_buf_victim_way_clean;

///check
assign head_buf_check_done_set = mlfb_cache_check_valid & (|mlfb_lst_check_ready);
assign head_buf_check_done_clr = head_buf_valid_clr;
assign head_buf_check_done_ena = head_buf_check_done_set | head_buf_check_done_clr;
assign head_buf_check_done_nxt = head_buf_check_done_set & (~head_buf_check_done_clr);
std_dffre #(.WIDTH(1)) U_STA_REG_CHECK_DONE (.clk(clk) ,.rstn(rstn) ,.en(head_buf_check_done_ena) ,.d(head_buf_check_done_nxt) ,.q(head_buf_check_done));
assign head_buf.check_done = head_buf_check_done;

//evict
assign head_buf_evict_done_set = mlfb_cache_evict_req_hsk |
                                 mlfb_cache_evict_bypass ;
assign head_buf_evict_done_clr = head_buf_valid_clr;
assign head_buf_evict_done_ena = head_buf_evict_done_set | head_buf_evict_done_clr;
assign head_buf_evict_done_nxt = head_buf_evict_done_set & (~head_buf_evict_done_clr);
std_dffre#(.WIDTH(1))U_STA_REG_EVICT_DONE(.clk(clk), .rstn(rstn), .en(head_buf_evict_done_ena), .d(head_buf_evict_done_nxt), .q(head_buf_evict_done));
assign head_buf.evict_done= head_buf_evict_done;

//refill
assign head_buf_refill_done_set = mlfb_cache_refill_req_hsk;
assign head_buf_refill_done_clr = head_buf_valid_clr;
assign head_buf_refill_done_ena = head_buf_refill_done_set | head_buf_refill_done_clr;
assign head_buf_refill_done_nxt = head_buf_refill_done_set & (~head_buf_refill_done_clr);
std_dffre#(.WIDTH(1))U_STA_REG_REFILL_DONE(.clk(clk), .rstn(rstn), .en(head_buf_refill_done_ena), .d(head_buf_refill_done_nxt),.q(head_buf_refill_done));
assign head_buf.refill_done= head_buf_refill_done;

// //response to lsu
// assign head_buf_lsu_resp_done_set = mlfb_cache_lsu_resp_hsk;
// assign head_buf_lsu_resp_done_clr = head_buf_valid_clr;
// assign head_buf_lsu_resp_done_ena = head_buf_lsu_resp_done_set | head_buf_lsu_resp_done_clr;
// assign head_buf_lsu_resp_done_nxt = head_buf_lsu_resp_done_set & (~head_buf_lsu_resp_done_clr);
// std_dffre#(.WIDTH(1))U_STA_REG_LSU_RESP_DONE(.clk(clk), .rstn(rstn), .en(head_buf_lsu_resp_done_ena), .d(head_buf_lsu_resp_done_nxt), .q(head_buf_lsu_resp_done));
// assign head_buf.lsu_resp_done= head_buf_lsu_resp_done;

// //srq dat
// assign head_buf_srq_dat_done_set = mlfb_srq_return_upd_valid;
// assign head_buf_srq_dat_done_clr = head_buf_valid_clr;
// assign head_buf_srq_dat_done_ena = head_buf_srq_dat_done_set | head_buf_srq_dat_done_clr;
// assign head_buf_srq_dat_done_nxt = head_buf_srq_dat_done_set & (~head_buf_srq_dat_done_clr);
// std_dffre#(.WIDTH(1))U_STA_REG_SRQ_DAT_DONE(.clk(clk), .rstn(rstn),.en(head_buf_srq_dat_done_ena),.d(head_buf_srq_dat_done_nxt),.q(head_buf_srq_dat_done));
// assign head_buf.srq_dat_done = head_buf_srq_dat_done;

//MSHR intf
assign mlfb_mshr_dealloc_valid = head_buf_valid_clr;
assign mlfb_mshr_dealloc_idx = head_buf.mshr_idx;
assign mlfb_mshr_head_rd_idx = mlfb_fifo[head_idx[0]].mshr_idx;
// assign mlfb_mshr_head_pending_rd_idx = head_buf.mshr_idx;

//Cache intf
assign mlfb_cache_peek_valid   = head_buf.valid & ~snoop_stall_refill_i & (~head_buf.peek_done);
assign mlfb_cache_check_valid  = head_buf.valid & ~snoop_stall_refill_i & head_buf.peek_done & ~head_buf.check_done;
assign mlfb_cache_evict_valid  = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & head_buf.victim_set_full & ~head_buf.victim_way_clean;
assign mlfb_cache_evict_bypass = head_buf.valid & ~snoop_stall_refill_i & head_buf.check_done & (~head_buf.evict_done) & (~head_buf.victim_set_full | head_buf.victim_way_clean);
assign mlfb_cache_refill_valid = head_buf.valid & ~snoop_stall_refill_i & head_buf.evict_done & (~head_buf.refill_done) & ~mlfb_pipe_same_addr_haz;


//peek req
assign mlfb_lru_peek_set_idx = head_buf_paddr_idx;
assign mlfb_lst_peek_set_idx = head_buf_paddr_idx;
assign mlfb_lst_check_set_idx = head_buf_paddr_idx; 
assign mlfb_lst_check_way_idx = head_buf.victim_set_full ? head_buf.victim_way_idx : head_buf.avail_way_idx;

//evict req
assign mlfb_cache_evict_req_hsk = mlfb_cache_evict_req_valid & mlfb_cache_evict_req_ready;
assign mlfb_cache_evict_req.set_idx = head_buf_paddr_idx;
assign mlfb_cache_evict_req.way_idx = head_buf.victim_way_idx;
//refill req
assign mlfb_cache_refill_req_hsk = mlfb_cache_refill_req_valid & mlfb_cache_refill_req_ready;
assign mlfb_cache_refill_req.set_idx = head_buf_paddr_idx;
assign mlfb_cache_refill_req.way_idx = head_buf.victim_set_full ? head_buf.victim_way_idx : head_buf.avail_way_idx;
assign mlfb_cache_refill_req.tag     = head_buf_paddr_tag;
assign mlfb_cache_refill_req.dat     = mlfb_refill_dat_tmp;
assign mlfb_cache_refill_req.mesi_sta= head_buf.req_type_dec.is_st ? MODIFIED : head_buf.mesi_sta; // TODO: it is only for single core
assign mlfb_cache_refill_req.is_lr   = head_buf.req_type_dec.is_lr;
assign mlfb_cache_refill_req.is_ld   = head_buf.req_type_dec.is_ld;
assign mlfb_cache_refill_req.offset  = head_buf_paddr_offset;
assign mlfb_cache_refill_req.rob_tag = head_buf.rob_tag;
assign mlfb_cache_refill_req.prd     = head_buf.prd;
`ifdef RUBY
assign mlfb_cache_refill_req.lsu_tag = head_buf.lsu_tag;
`endif
assign mlfb_cache_refill_req.req_type_dec = head_buf.req_type_dec;
assign mlfb_cache_refill_req.ld_no_resp   = head_buf.ld_no_resp;
assign mlfb_cache_refill_req.amo_st_data  = head_buf.amo_st_data;
//assign mlfb_cache_refill_req.tag_ecc_ckbit = head_buf.tag_ecc_ckbit;
assign mlfb_lru_peek_valid = mlfb_cache_peek_valid;
assign mlfb_lst_check_valid = mlfb_cache_check_valid;
assign mlfb_cache_evict_req_valid = mlfb_cache_evict_valid;
assign mlfb_cache_refill_req_valid = mlfb_cache_refill_valid;

//stb intf
//assign mlfb_stb_rd_resp_valid = head_buf_valid_clr;
//assign mlfb_stb_rd_resp.cache_hit_mesi = head_buf.mesi_sta;
//assign mlfb_stb_rd_resp.id = '0;
//assign mlfb_stb_rd_resp.cache_hit_way_idx = head_buf.victim_set_full ? head_buf.victim_way_idx : head_buf.avail_way_idx;
//assign mlfb_stb_rd_resp.paddr = head_buf.paddr;
//assign mlfb_stb_rd_resp_line_dat =  head_buf.line_dat;

//axi
assign l1d_l2_rd_resp_ready = 1'b1;

//coherence resp
//assign l1d_scu_rnsd_coh_ack_valid   = head_buf_valid_clr & (~head_buf.l2_hit);//&(head_buf.lsu_req_type_dec.is_ld| head_buf.lsu_req_type_dec.is_lr);
//assign l1d_scu_rnsd_coh_ack.sst_idx = head_buf.sst_idx;
// assign mlfb_head_buf_valid          = head_buf_valid;
endmodule
/* verilator lint_on PINCONNECTEMPTY */
