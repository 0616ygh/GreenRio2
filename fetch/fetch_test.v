`ifndef FETCH_V
`define FETCH_V
`include "params.vh"

module fetch #(
    parameter BTB_SIZE = 4,
    parameter BTB_WIDTH = 2, //log2(up)
    parameter GSHARE_WIDTH = 4,
    parameter PHT_LEN = 16,
    parameter INS_BUFFER_DATA = 96,
    parameter INS_BUFFER_SIZE = 2, //need to set to 8
    parameter INS_BUFFER_SIZE_WIDTH = 1, //log2 (up)
    parameter IFQ_DEPTH = 8,
    parameter FETCH_WIDTH = 128,
    parameter L1I_OFFSET_WIDTH = 4,
    parameter MODE_WIDTH = 4,
    parameter ASID_WIDTH = 16,
    parameter PPN_WIDTH = 44,
    parameter L1I_INDEX_WIDTH = 8,
    parameter L1I_TAG_WIDTH = PC_WIDTH - L1I_OFFSET_WIDTH - L1I_INDEX_WIDTH,
    parameter TRANS_ID_WIDTH = 3,
    parameter PTE_WIDTH = 64,
    parameter VPN_WIDTH = 27,
    parameter PAGE_LVL_WIDTH = $clog2(VPN_WIDTH/9)
) (
    // for itlb
    /* for test
    input [1:0] priv_lvl_i,
    input mstatus_mxr_i,
    input mstatus_sum_i,
    input [MODE_WIDTH-1:0] satp_mode_i,
    input [ASID_WIDTH-1:0] satp_asid_i,

    */
    //whole fetch
    input clk,
    input rst,
    input branch_valid_first_i, 
    input branch_valid_second_i, 

    //btb from fu
    input [PC_WIDTH-1:0] btb_req_pc_i, 
    input [PC_WIDTH-1:0] btb_predict_target_i, 

    //gshare from fu
    input [PC_WIDTH-1:0] prev_pc_first_i,
    input prev_taken_first_i,
    input [PC_WIDTH-1:0] prev_pc_second_i,
    input prev_taken_second_i,

    //instruction buffer
    // input rd_en_i,
    // first inst
    output reg [PC_WIDTH-1:0] pc_first_o,
    output reg [PC_WIDTH-1:0] next_pc_first_o,
    output reg [PC_WIDTH-1:0] predict_pc_first_o,
    output reg [31:0] instruction_first_o,
    output reg is_rv_first_o,
    output reg is_first_valid_o, 
    // second inst
    output reg [PC_WIDTH-1:0] pc_second_o,
    output reg [PC_WIDTH-1:0] next_pc_second_o,
    output reg [PC_WIDTH-1:0] predict_pc_second_o,
    output reg [31:0] instruction_second_o,
    output reg is_rv_second_o,
    output reg is_second_valid_o,

    // from fu
    input [PC_WIDTH-1:0] real_branch_i,
    
    // from exception ctrl
    // input trap_i,
    // input mret_i,
    input global_wfi_i,
    input global_ret_i,
    input global_trap_i,
    input global_predict_miss_i,

    // from csr
    input [PC_WIDTH-1:0] trap_vector_i,
    input [PC_WIDTH-1:0] mret_vector_i,

    // I$ -> FETCH : resp
    input fetch_l1i_if_req_rdy_i, // i$ has recv fetch's req
    input l1i_fetch_if_resp_vld_i, // i$ fetch a valid cacheline
    //input [$clog2(IFQ_DEPTH)-1:0] l1i_fetch_if_resp_if_tag_i, // notice
    input [FETCH_WIDTH-1:0] l1i_fetch_if_resp_data_i, // i$'s cacheline
    
    // FETCH -> I$ : IFETCH request
    output reg fetch_l1i_if_req_vld_o, // 1: fetch has req
    //output [$clog2(IFQ_DEPTH)-1:0] fetch_l1i_if_req_if_tag_o, // notice
    output [L1I_INDEX_WIDTH-1:0] fetch_l1i_if_req_index_o,
    output [L1I_OFFSET_WIDTH-1:0] fetch_l1i_if_req_offset_o,
    output [L1I_TAG_WIDTH-1:0] fetch_l1i_if_req_vtag_o, // virtual tag

    // FETCH -> I$ : ITLB response

    /* for test
    output fetch_l1i_if_itlb_resp_vld_o, // 1: itlb hit, 0: itlb miss
    output [PPN_WIDTH-1:0] fetch_l1i_if_itlb_resp_ppn_o,
    output fetch_l1i_if_itlb_resp_excp_vld_o, // 1: itlb miss, 0: itlb hit
    output fetch_l1i_if_itlb_resp_hit_o, // 1: itlb hit, 0: itlb miss
    */

    //for test
    output ins_empty_o,

    // exceptions
    output reg exception_valid_first_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o,
    output reg exception_valid_second_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o,

    output reg ins_hit_o,
    output reg test_ins_hit_o,
    output [PC_WIDTH-1:0] pc_out,
    output reg [2:0] predict_tag,
    output [PC_WIDTH-1:0] pc_from_btb_o
);

reg [PC_WIDTH-1:0] pc;
wire branch_predict_wrong;
wire fetch_l1i_if_itlb_resp_excp_vld_o = 0; // for test
wire [EXCEPTION_CAUSE_WIDTH-1:0] ecause_itlb = 0; // for test

reg rff_icache_resp; //to match misfetch signal, make sure the next response from icache after branch should be ignore

reg [PC_WIDTH-1:0] predict_pc;
wire judge_from_gshare;
wire btb_taken;
wire [PC_WIDTH-1:0] pc_from_btb;
assign branch_predict_wrong = branch_valid_first_i && ((real_branch_i != pc_first_o) || ins_empty_o);
wire flush = (branch_predict_wrong | global_ret_i | global_wfi_i | global_trap_i | global_predict_miss_i) & !ins_empty_o;

// issue: should exception from misalign be included ?
wire exception_valid_in = pc[1:0] != 2'b00;
wire [EXCEPTION_CAUSE_WIDTH-1:0] ecause_in = (pc[1:0] != 2'b00) ? EXCEPTION_INSTR_ADDR_MISALIGNED : 0;

wire buffer_full;
reg [PC_WIDTH-1:0] ins_pc_in;
wire [PC_WIDTH-1:0] ins_next_pc_in;
// wire [31:0] instruction_in;

reg rff_misfetch;
wire misfetch;
wire pc_unpredict_taken;

reg [PC_WIDTH-1:0] prefetch_vpc;
wire ins_hit;
wire refill_i;

// FETCH -> I$ : IFETCH request
// inst buffer hit: prefetch needed; inst buffer miss: no prefetch, but fetch a line corresponding to current pc
// assign fetch_l1i_if_req_vld_o = (ins_hit & ~refill_i) | (~ins_hit);
assign fetch_l1i_if_req_offset_o = prefetch_vpc[L1I_OFFSET_WIDTH-1:0];
assign fetch_l1i_if_req_index_o = prefetch_vpc[L1I_OFFSET_WIDTH+L1I_INDEX_WIDTH-1:L1I_OFFSET_WIDTH];
assign fetch_l1i_if_req_vtag_o = prefetch_vpc[PC_WIDTH-1:L1I_OFFSET_WIDTH+L1I_INDEX_WIDTH];

//next pc 
always @(*) begin
    if (global_wfi_i) begin
        predict_pc = pc;
        predict_tag = 0;
    end else if (global_trap_i) begin
        predict_pc = trap_vector_i;
        predict_tag = 1;
    end else if (global_ret_i) begin
        predict_pc = mret_vector_i;
        predict_tag = 2;
    end else if (branch_predict_wrong) begin
        predict_pc = real_branch_i;
        predict_tag = 3;
    end else if (btb_taken && !judge_from_gshare) begin //need && judge_from_gshare
        predict_pc = pc_from_btb;
        predict_tag = 4;
    end else begin
        if (is_rv_first_o) begin // notice: not sure if is_rv_first_o is obtained
            predict_pc = pc + 4;
            predict_tag = 5;
        end else begin 
            predict_pc = pc + 2;
            predict_tag = 6;
        end
    end
end

assign pc_unpredict_taken = global_trap_i | global_ret_i | branch_predict_wrong;
assign pc_from_btb_o = pc_from_btb;

//pc switch
always @(posedge clk) begin
    if (rst) begin
        pc <= RESET_VECTOR;
    end else if (ins_hit) begin
        pc <= predict_pc;
    end
end

always @(posedge clk) begin
    if (global_wfi_i || buffer_full || rst || (ins_hit & refill_i)) begin
        fetch_l1i_if_req_vld_o <= 0;
    end else begin
        fetch_l1i_if_req_vld_o <= 1;
    end
end

// ins_pc_in not in use
always @(posedge clk) begin
    if (rst) begin
        ins_pc_in <= RESET_VECTOR;
    end else if (branch_predict_wrong | global_trap_i | global_ret_i) begin 
        ins_pc_in <= predict_pc;
    end else if(fetch_l1i_if_req_rdy_i & fetch_l1i_if_req_vld_o) begin
        ins_pc_in <= pc; 
    end
end

wire icache_resp_ready;
always @(posedge clk) begin
    if (rst) begin
        rff_misfetch <= 0;
    end if ((branch_predict_wrong | global_trap_i | global_ret_i) && !(icache_resp_ready & l1i_fetch_if_resp_vld_i)) begin
        rff_misfetch <= 1;
    end else if (icache_resp_ready & l1i_fetch_if_resp_vld_i) begin
        rff_misfetch <= 0;
    end
end

assign misfetch = rff_misfetch | branch_predict_wrong | global_trap_i | global_ret_i;

// ins_next_pc_in not in use
assign ins_next_pc_in = ins_pc_in + 4;
// assign instruction_in = fetch_data;

assign icache_resp_ready = !global_wfi_i && !buffer_full;

// instr_buffer_wr_en not in use?
// wire instr_buffer_wr_en = icache_resp_ready && l1i_fetch_if_resp_vld_i && (icache_resp_address == ins_pc_in) && !misfetch; // resp_address can equal both ins_next_pc_in and pc 

btb #(
    .BTB_SIZE(BTB_SIZE),
    .BTB_WIDTH(BTB_WIDTH)
) btb_u(
    .clk(clk),
    .reset(rst),
    .pc_in(pc),
    .buffer_hit(btb_taken),
    .next_pc_out(pc_from_btb),
    .is_req_pc(branch_valid_first_i),
    .req_pc(btb_req_pc_i),
    .predict_target(btb_predict_target_i)
);

gshare #(
    .GSHARE_WIDTH(GSHARE_WIDTH),
    .PHT_LEN(PHT_LEN)
) gshare_u(
    .clk(clk),
    .reset(rst),
    .pc(pc),
    .prev_pc_first(prev_pc_first_i),
    .prev_branch_in_first(branch_valid_first_i),
    .prev_taken_first(prev_taken_first_i),
    .prev_pc_second(prev_pc_second_i),
    .prev_branch_in_second(branch_valid_second_i),
    .prev_taken_second(prev_taken_second_i),
    .cur_pred(judge_from_gshare)
);

reg refill_o;
reg icache_prefetch_valid_o;
reg [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_line_number_o;
reg [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_line_number_i;

assign ins_hit_o = ins_hit;
assign pc_out = pc;

always @(posedge clk) begin
    if (rst) begin
        refill_o <= 0;
        icache_prefetch_valid_o <= 0;
        prefetch_line_number_o <= 0;
    end else if (flush) begin
        refill_o <= 0;
        icache_prefetch_valid_o <= 0;
        prefetch_line_number_o <= 0;
    end else begin
        refill_o <= refill_i;
        icache_prefetch_valid_o <= ins_hit;
        prefetch_line_number_o <= prefetch_line_number_i;
    end
end

assign predict_pc_first_o = pc_second_o;
assign predict_pc_second_o = predict_pc;

ins_buffer #(
    .INS_BUFFER_DATA(FETCH_WIDTH),
    .OFFSET_WIDTH(L1I_OFFSET_WIDTH)
) buffer_u(
    .clk(clk),
    .reset(rst),
    .flush(flush),
    .pc_in(pc),
    .exception_valid_in(fetch_l1i_if_itlb_resp_excp_vld_o), // exception from itlb
    .ecause_in(ecause_itlb),
    .ins_hit(ins_hit),
    .prefetch_vpc(prefetch_vpc),
    .refill_o(refill_i),
    .refill_i(refill_o),
    .prefetch_line_number_o(prefetch_line_number_i),
    .prefetch_line_number_i(prefetch_line_number_o),
    .icache_prefetch_valid(icache_prefetch_valid_o),
    .l1i_fetch_if_resp_vld_i(l1i_fetch_if_resp_vld_i),
    .icache_input_prefetch_line(l1i_fetch_if_resp_data_i), // from icache: one cacheline
    .ins_full(buffer_full),
    .ins_empty(ins_empty_o),
    .pc_first_o(pc_first_o),
    .next_pc_first_o(next_pc_first_o),
    .instruction_first_o(instruction_first_o),
    .is_rv_first_o(is_rv_first_o),
    .exception_valid_first_o(exception_valid_first_o),
    .ecause_first_o(ecause_first_o),
    .is_first_valid_o(is_first_valid_o),
    .pc_second_o(pc_second_o),
    .next_pc_second_o(next_pc_second_o),
    .instruction_second_o(instruction_second_o),
    .is_rv_second_o(is_rv_second_o),
    .exception_valid_second_o(exception_valid_second_o),
    .ecause_second_o(ecause_second_o),
    .is_second_valid_o(is_second_valid_o),
    .test_ins_hit(test_ins_hit_o)
);

wire [PC_WIDTH-L1I_OFFSET_WIDTH-1:0] vpn_if2ic = icache_prefetch_valid_o ? prefetch_vpc[PC_WIDTH-1:L1I_OFFSET_WIDTH] : pc[PC_WIDTH-1:L1I_OFFSET_WIDTH];
// wire [PC_WIDTH-OFFSET_WIDTH-1:0] vpn_if2ib = pc[[PC_WIDTH-1:OFFSET_WIDTH];
// reg [PADDR_WIDTH-OFFSET_WIDTH-1:0] ppn_if2ib;
//reg [PADDR_WIDTH-1:0] ppc_if2ic;
// reg [PADDR_WIDTH-1:0] ppc_if2ib;

//assign ppc_if2ic = {fetch_l1i_if_itlb_resp_ppn_o, prefetch_vpc[OFFSET_WIDTH-1:0]};
// assign ppc_if2ib = {ppn_if2ib, pc[OFFSET_WIDTH-1:0]};

/* for test
reg next_lvl_req_rdy_i;
reg next_lvl_resp_vld_i;
reg [TRANS_ID_WIDTH-1:0] next_lvl_resp_trans_id_i;
reg [ASID_WIDTH-1:0] next_lvl_resp_asid_i;
reg [PTE_WIDTH-1:0] next_lvl_resp_pte_i;
reg [PAGE_LVL_WIDTH-1:0] next_lvl_resp_page_lvl_i;
reg [VPN_WIDTH-1:0] next_lvl_resp_vpn_i;
reg [1:0] next_lvl_resp_access_type_i;
reg next_lvl_resp_access_fault_i;
reg next_lvl_resp_page_fault_i;
reg tlb_flush_vld_i;
reg tlb_flush_use_asid_i;
reg tlb_flush_use_vpn_i;
reg [VPN_WIDTH-1:0] tlb_flush_vpn_i;
reg [ASID_WIDTH-1:0] tlb_flush_asid_i;

rvh_itlb #(
    .TRANSLATE_WIDTH(1)
) itlb_if2ic(
    .priv_lvl_i(priv_lvl_i),
    .mstatus_mxr(mstatus_mxr_i),
    .mstatus_sum(mstatus_sum_i),
    .satp_mode_i(satp_mode_i),
    .satp_asid_i(satp_asid_i),
    .translate_req_vld_i(fetch_l1i_if_req_vld_o), // req to i$ needs itlb
    .translate_req_vpn_i(vpn_if2ic), // virtual tag from vpc
    .translate_req_rdy_o(),
    .translate_resp_vld_o(fetch_l1i_if_itlb_resp_vld_o), 
    .translate_resp_ppn_o(fetch_l1i_if_itlb_resp_ppn_o), // translated physical
    .translate_resp_excp_vld_o(fetch_l1i_if_itlb_resp_excp_vld_o), // exception from itlb
    .translate_resp_excp_cause_o(ecause_itlb), // ecause from itlb
    .translate_resp_miss_o(),
    .translate_resp_hit_o(fetch_l1i_if_itlb_resp_hit_o), // itlb hit or miss
    // below: no use
    .next_lvl_req_vld_o(),
    .next_lvl_req_trans_id_o(),
    .next_lvl_req_asid_o(),
    .next_lvl_req_vpn_o(),
    .next_lvl_req_access_type_o(),
    .next_lvl_req_rdy_i(next_lvl_req_rdy_i),
    .next_lvl_resp_vld_i(next_lvl_resp_vld_i),
    .next_lvl_resp_trans_id_i(next_lvl_resp_trans_id_i),
    .next_lvl_resp_asid_i(next_lvl_resp_asid_i),
    .next_lvl_resp_pte_i(next_lvl_resp_pte_i),
    .next_lvl_resp_page_lvl_i(next_lvl_resp_page_lvl_i),
    .next_lvl_resp_vpn_i(next_lvl_resp_vpn_i),
    .next_lvl_resp_access_type_i(next_lvl_resp_access_type_i),
    .next_lvl_resp_access_fault_i(next_lvl_resp_access_fault_i),
    .next_lvl_resp_page_fault_i(next_lvl_resp_page_fault_i),
    .tlb_evict_vld_o(),
    .tlb_evict_pte_o(),
    .tlb_evict_page_lvl_o(),
    .tlb_evict_vpn_o(),
    .tlb_evict_asid_o(),
    .tlb_flush_vld_i(tlb_flush_vld_i),
    .tlb_flush_use_asid_i(tlb_flush_use_asid_i),
    .tlb_flush_use_vpn_i(tlb_flush_use_vpn_i),
    .tlb_flush_vpn_i(tlb_flush_vpn_i),
    .tlb_flush_asid_i(tlb_flush_asid_i),
    .tlb_flush_grant_o(),
    .clk(clk),
    .rstn(~rst)
);
*/

// wire if2ib_itlb_resp_vld;
// wire if2ib_itlb_resp_excp_vld;
// wire [EXCEPTION_CODE_WIDTH-1:0] if2ib_itlb_resp_excp_cause;
// wire if2ib_itlb_resp_hit;
/*
rvh_itlb #(
    .TRANSLATE_WIDTH(1)
) itlb_if2ib(
    .priv_lvl_i(priv_lvl_i),
    .mstatus_mxr(mstatus_mxr_i),
    .mstatus_sum(mstatus_sum_i),
    .satp_mode_i(satp_mode_i),
    .satp_asid_i(satp_asid_i),
    .translate_req_vld_i(),
    .translate_req_vpn_i(vpn_if2ib), // virtual tag from vpc
    .translate_req_rdy_o(),
    .translate_resp_vld_o(if2ib_itlb_vld), 
    .translate_resp_ppn_o(ppn_if2ib), // translated physical tag 
    .translate_resp_excp_vld_o(fetch_l1i_if_itlb_resp_excp_vld_o),
    .translate_resp_excp_cause_o(if2ib_itlb_resp_excp_cause),
    .translate_resp_miss_o(),
    .translate_resp_hit_o(if2ib_itlb_resp_hit),
    // no use below
    .next_lvl_req_vld_o(),
    .next_lvl_req_trans_id_o(),
    .next_lvl_req_asid_o(),
    .next_lvl_req_vpn_o(),
    .next_lvl_req_access_type_o(),
    .next_lvl_req_rdy_i(),
    .next_lvl_resp_vld_i(),
    .next_lvl_resp_trans_id_i(),
    .next_lvl_resp_asid_i(),
    .next_lvl_resp_pte_i(),
    .next_lvl_resp_page_lvl_i(),
    .next_lvl_resp_vpn_i(),
    .next_lvl_resp_access_type_i(),
    .next_lvl_resp_access_fault_i(),
    .next_lvl_resp_page_fault_i(),
    .tlb_evict_vld_o(),
    .tlb_evict_pte_o(),
    .tlb_evict_page_lvl_o(),
    .tlb_evict_vpn_o(),
    .tlb_evict_asid_o(),
    .tlb_flush_vld_i(),
    .tlb_flush_use_asid_i(),
    .tlb_flush_use_vpn_i(),
    .tlb_flush_vpn_i(),
    .tlb_flush_asid_i(),
    .tlb_flush_grant_o(),
    .clk(clk),
    .rstn(~reset)
);
*/
endmodule

`endif // FETCH_V
