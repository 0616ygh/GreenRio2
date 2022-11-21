`ifndef FETCH_V
`define FETCH_V
`ifdef VERILATOR
`include "params.vh"
`endif

module fetch (
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

    // IF<>ID
    input single_rdy_i,
    input double_rdy_i,

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
    input [$clog2(IFQ_DEPTH)-1:0] l1i_fetch_if_resp_if_tag_i, // notice
    input [FETCH_WIDTH-1:0] l1i_fetch_if_resp_data_i, // i$'s cacheline
    
    // FETCH -> I$ : IFETCH request
    output reg fetch_l1i_if_req_vld_o, // 1: fetch has req
    output [$clog2(IFQ_DEPTH)-1:0] fetch_l1i_if_req_if_tag_o, // notice
    output [L1I_INDEX_WIDTH-1:0] fetch_l1i_if_req_index_o,
    output [L1I_OFFSET_WIDTH-1:0] fetch_l1i_if_req_offset_o,
    output [L1I_TAG_WIDTH-1:0] fetch_l1i_if_req_vtag_o, // virtual tag

    // FETCH -> itlb: request
    input itlb_fetch_miss_i,
    input itlb_fetch_hit_i,
    input itlb_fetch_resp_excp_vld_i,
    input [EXCEPTION_CAUSE_WIDTH-1:0] itlb_fetch_resp_ecause_i,
    output reg fetch_itlb_req_vld_o,

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
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o
);

reg [PC_WIDTH-1:0] pc;
// wire fetch_l1i_if_itlb_resp_excp_vld_o = 0; // for test
// wire [EXCEPTION_CAUSE_WIDTH-1:0] ecause_itlb = 0; // for test

reg rff_icache_resp; //to match misfetch signal, make sure the next response from icache after branch should be ignore

reg [PC_WIDTH-1:0] predict_pc;
wire judge_from_gshare;
wire btb_taken;
wire [PC_WIDTH-1:0] pc_from_btb;
wire flush = global_ret_i | global_trap_i | global_predict_miss_i;

// issue: should exception from misalign be included ?
// wire exception_valid_in = pc[1:0] != 2'b00;
// wire [EXCEPTION_CAUSE_WIDTH-1:0] ecause_in = (pc[1:0] != 2'b00) ? EXCEPTION_INSTR_ADDR_MISALIGNED : 0;

wire whether_fetch;
wire buffer_full;
reg [PC_WIDTH-1:0] ins_pc_in;
wire [PC_WIDTH-1:0] ins_next_pc_in;
// wire [31:0] instruction_in;

reg rff_misfetch;
wire misfetch;
// wire pc_unpredict_taken;

reg [PC_WIDTH-1:0] prefetch_vpc;
reg [PC_WIDTH-1:0] prefetch_vpc_in;
wire ins_hit;
wire refill_i;
wire predict_pc_from_pred;

wire icache_same;

// teg gen
wire fetch_tag_wr_en                                ;
wire fetch_tag_rd_en                                ;
wire [$clog2(IFQ_DEPTH)-1:0] fetch_tag_wrdata       ;
wire [$clog2(IFQ_DEPTH)-1:0] fetch_tag_rdata        ;
wire fetch_tag_full                                 ;
wire fetch_tag_empty                                ;
wire [$clog2(IFQ_DEPTH):0] fetch_tag_num          ;
wire tag_hit                                        ;
reg [$clog2(IFQ_DEPTH)-1:0] dff_tag        ;


// FETCH -> I$ : IFETCH request
// inst buffer hit: prefetch needed; inst buffer miss: no prefetch, but fetch a line corresponding to current pc
// assign fetch_l1i_if_req_vld_o = (ins_hit & ~refill_i) | (~ins_hit);
assign fetch_l1i_if_req_offset_o = prefetch_vpc[L1I_OFFSET_WIDTH-1:0];
assign fetch_l1i_if_req_index_o = {prefetch_vpc[L1I_INDEX_WIDTH-1:L1I_OFFSET_WIDTH], {L1I_OFFSET_WIDTH{1'b0}}};
assign fetch_l1i_if_req_vtag_o = prefetch_vpc[PC_WIDTH-1:L1I_INDEX_WIDTH];
assign predict_pc_from_pred = btb_taken && !judge_from_gshare;

//next pc 
always @(*) begin
    if (global_wfi_i) begin
        predict_pc = pc;
    end else if (global_trap_i) begin
        predict_pc = trap_vector_i;
    end else if (global_ret_i) begin
        predict_pc = mret_vector_i;
    end else if (global_predict_miss_i) begin
        predict_pc = real_branch_i;
    end else if (predict_pc_from_pred) begin //need && judge_from_gshare
        predict_pc = pc_from_btb;
    end else begin
        if (is_second_valid_o) begin
            if (is_rv_first_o && is_rv_second_o) begin
                predict_pc = pc + 8;
            end else if (is_rv_first_o || is_rv_second_o) begin
                predict_pc = pc + 6;
            end else begin
                predict_pc = pc + 4;
            end
        end else if (is_first_valid_o) begin
            if (is_rv_first_o) begin
                predict_pc = pc + 4;
            end else begin
                predict_pc = pc + 2;
            end
        end else begin
            predict_pc = pc;
        end
    end
end

// assign pc_unpredict_taken = global_trap_i | global_ret_i | branch_predict_wrong;

//pc switch
always @(posedge clk) begin
    if (rst) begin
        pc <= RESET_VECTOR;
    end else if (ins_hit || flush) begin
        pc <= predict_pc;
    end
end

assign fetch_itlb_req_vld_o = fetch_l1i_if_req_vld_o;

// if fetch has req hosted by icache, and tlb hit, stop sending another req
// reg fsm = 1;
// flush: global_ret_i | global_trap_i | global_predict_miss_i;
always @(*) begin
    if (global_wfi_i || flush || rst || !whether_fetch) begin
        fetch_l1i_if_req_vld_o = 0;
    end else begin
        fetch_l1i_if_req_vld_o = 1;
    end
end

// assign icache_resp_ready = !global_wfi_i && !buffer_full;

// instr_buffer_wr_en not in use?
// wire instr_buffer_wr_en = icache_resp_ready && l1i_fetch_if_resp_vld_i && (icache_resp_address == ins_pc_in) && !misfetch; // resp_address can equal both ins_next_pc_in and pc 

btb #(
    .BTB_SIZE_1(3)
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

gshare gshare_u(
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

always @(posedge clk) begin
    if (rst) begin
        refill_o <= 0;
        icache_prefetch_valid_o <= 0;
        prefetch_line_number_o <= 0;
        prefetch_vpc_in <= 0;
    end else if (flush) begin
        refill_o <= 0;
        icache_prefetch_valid_o <= 0;
        prefetch_line_number_o <= 0;
        prefetch_vpc_in <= 0;
    end else begin
        refill_o <= refill_i;
        icache_prefetch_valid_o <= ins_hit;
        prefetch_line_number_o <= prefetch_line_number_i;
        prefetch_vpc_in <= prefetch_vpc;
    end
end

assign predict_pc_first_o = pc_second_o;
assign predict_pc_second_o = predict_pc;

reg [FETCH_WIDTH-1:0] last_fetch_line;
assign icache_same = last_fetch_line == l1i_fetch_if_resp_data_i;
always @(posedge clk) begin
    if (rst || flush) begin
        last_fetch_line <= 0;
        //last_flush <= 0;
    end else if (last_fetch_line != l1i_fetch_if_resp_data_i && l1i_fetch_if_resp_vld_i) begin
        last_fetch_line <= l1i_fetch_if_resp_data_i;
    end
end

ins_buffer #(
    .OFFSET_WIDTH(L1I_OFFSET_WIDTH)
) buffer_u(
    .clk(clk),
    .reset(rst),
    .flush(flush),
    .pc_in(pc),
    .exception_valid_in(itlb_fetch_resp_excp_vld_i), // exception from itlb
    .ecause_in(itlb_fetch_resp_ecause_i),
    .ins_hit(ins_hit),
    .prefetch_vpc(prefetch_vpc),
    .pc_base(prefetch_vpc_in),
    .refill_o(refill_i),
    .refill_i(refill_o),
    .prefetch_line_number_o(prefetch_line_number_i),
    .prefetch_line_number_i(prefetch_line_number_o),
    .icache_prefetch_valid(icache_prefetch_valid_o),
    .l1i_fetch_if_resp_vld_i(l1i_fetch_if_resp_vld_i), // write ins buffer: tag_hit & resp_vld
    .icache_input_prefetch_line(l1i_fetch_if_resp_data_i), // from icache: one cacheline
    .ins_full(buffer_full),
    .ins_empty(ins_empty_o),
    .whether_fetch_o(whether_fetch),
    .single_rdy_i(single_rdy_i),
    .double_rdy_i(double_rdy_i),
    .icache_same(icache_same),
    .fetch_l1i_if_req_vld_o(fetch_l1i_if_req_vld_o),
    .fetch_l1i_if_req_rdy_i(fetch_l1i_if_req_rdy_i),
    .itlb_fetch_miss_i(itlb_fetch_miss_i),
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
    .is_second_valid_o(is_second_valid_o)
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
