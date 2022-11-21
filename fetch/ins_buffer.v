`ifdef VERILATOR
`include "params.vh"
`endif
module ins_buffer #(
    parameter OFFSET_WIDTH = 4
) (
    input clk,
    input reset,
    input flush,
    input [PC_WIDTH-1:0] pc_in,
    // input [PC_WIDTH-1:0] next_pc_in,
    input exception_valid_in,
    input [EXCEPTION_CAUSE_WIDTH-1:0]ecause_in,
    // input [PADDR_WIDTH-1:0] pc_paddr_in,
    output reg ins_hit, // inst buffer hit
    output [PC_WIDTH-1:0] prefetch_vpc, // fetch need to prefetch this vpc's cacheline
    input [PC_WIDTH-1:0] pc_base,
    output refill_o, // whether prefetch in next cycle is needed
    input refill_i,
    output [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_line_number_o,
    input [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_line_number_i,

    // from icache
    input icache_prefetch_valid, // 1: last hit, fill in prefetch line; 0: last miss
    input l1i_fetch_if_resp_vld_i, // 1: icache_input_prefetch_line valid
    input [INS_BUFFER_DATA-1:0] icache_input_prefetch_line, // prefetch
    output reg ins_full, //to fetch
    output reg ins_empty, //to decode
    output whether_fetch_o,

    input single_rdy_i,
    input double_rdy_i,

    input icache_same,
    input fetch_l1i_if_req_vld_o,
    input fetch_l1i_if_req_rdy_i,
    input itlb_fetch_miss_i,

    output [PC_WIDTH-1:0] pc_first_o,
    output [PC_WIDTH-1:0] next_pc_first_o,
    output [31:0] instruction_first_o,
    output reg is_rv_first_o,
    output reg exception_valid_first_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o,
    output reg is_first_valid_o,

    output [PC_WIDTH-1:0] pc_second_o,
    output [PC_WIDTH-1:0] next_pc_second_o,
    output [31:0] instruction_second_o,
    output reg is_rv_second_o,
    output reg exception_valid_second_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o,
    output reg is_second_valid_o
);

reg [SIZE_ELEMENT-1:0] dff_inst_buffer[NUM_ELEMENTS-1:0];
reg [INS_BUFFER_SIZE-1:0] dff_excp_valid;
reg [EXCEPTION_CAUSE_WIDTH-1:0] dff_excp_cause[INS_BUFFER_SIZE-1:0];
// reg [PADDR_WIDTH-1:0] dff_base_pc[INS_BUFFER_SIZE-1:0];
reg [PC_WIDTH-1:0] dff_base_pc[INS_BUFFER_SIZE-1:0];
reg [INS_BUFFER_SIZE-1:0] dff_valid; // whether this line is valid
reg [INS_BUFFER_SIZE-1:0] dff_fetched;

reg[PTR_WIDTH:0] rff_ibuf_size;
reg[PTR_WIDTH:0] pop_size;
reg[PTR_WIDTH:0] push_size;

reg [PTR_WIDTH-1:0] rff_pop_ptr;
reg [PTR_WIDTH-1:0] next_pop_ptr;
reg [PTR_WIDTH-1:0] last_pop_ptr;
reg [PTR_WIDTH-1:0] pop_ptr_second_half;
reg [PTR_WIDTH-1:0] pop_ptr_third_half;
reg [PTR_WIDTH-1:0] pop_ptr_fourth_half;

reg [PTR_WIDTH-1:0] rff_push_ptr;
reg [INS_BUFFER_SIZE_WIDTH-1:0] push_line_ptr;

reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr;
reg [INS_BUFFER_SIZE_WIDTH-1:0] last_pop_line_ptr;
reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr_second_half;
reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr_third_half;
reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr_fourth_half;

wire haha;


wire [INS_BUFFER_SIZE_WIDTH-1:0] next_pop_line_ptr;
wire [PTR_WIDTH-1:0] second_next_line             ;
wire [PTR_WIDTH-1:0] third_next_line              ;
wire [PTR_WIDTH-1:0] fourth_next_line             ;

wire [INS_BUFFER_SIZE_WIDTH-1:0] prefetch_ins_line;
// reg [PC_WIDTH-1:0] dff_fetch_pc;

reg in_a_line;
wire has_first_inst_in_size;
wire has_full_inst_in_size;
wire is_ibuf_empty;
wire is_first_valid;
wire is_second_valid;
wire is_third_valid;
wire is_fourth_valid;
wire is_first_rvc;
wire is_second_rvc;
wire is_third_rvc;
reg has_first_inst;
reg has_full_inst;

reg [SIZE_ELEMENT-1:0] first_element;
reg [SIZE_ELEMENT-1:0] second_element;
reg [SIZE_ELEMENT-1:0] third_element;
reg [SIZE_ELEMENT-1:0] fourth_element;

wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] first_start;
wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] second_start;
wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] third_start;
wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] fourth_start;

reg is_half1_excp;
reg is_half2_excp;
reg is_half3_excp;
reg is_half4_excp;

reg [PC_WIDTH-1:0] next_cache_line;

wire ins_miss;
wire if_prefetch;

//wire [PTR_WIDTH:0] give_size = (&dff_valid) ? 16 : 0 ;
//assign rff_ibuf_size = rff_push_ptr - rff_pop_ptr + give_size;
wire [PTR_WIDTH-1:0] partial_size = 8 - {1'b0, rff_pop_ptr[PTR_WIDTH-2:0]};
wire [PTR_WIDTH:0] whole_size_1 = {1'b0, partial_size} + 5'b01000;
wire [PTR_WIDTH:0] whole_size_2 = {1'b0, partial_size};
assign ins_full = (&dff_valid);
assign ins_empty = ~(|dff_valid); // 0: not empty
always @(*) begin
    if (&dff_valid) begin
        rff_ibuf_size = whole_size_1;
    end else if (|dff_valid) begin
        if (dff_valid[pop_line_ptr]) begin
            rff_ibuf_size = whole_size_2;
        end else begin
            rff_ibuf_size = 8;
        end
    end else begin
        rff_ibuf_size = 0;
    end
end
// }}}

//==========================================================
// Hit miss logic {{{

// Since icache is VIPT, we need to lookup physical tag, and compare tag+index to IB's base_pc
// if icache_prefetch_valid == 0, indicating that the input cacheline contains current pc, so hit
// compare tag + index
// assign ins_hit = has_full_inst & (pc_paddr_in[PADDR_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr][PADDR_WIDTH-1:OFFSET_WIDTH] ? 1 : 0);
wire if_bypass = l1i_fetch_if_resp_vld_i & (pc_base[PC_WIDTH-1:OFFSET_WIDTH] == pc_in[PC_WIDTH-1:OFFSET_WIDTH]);
wire if_bypass_ne = l1i_fetch_if_resp_vld_i & (pc_base[PC_WIDTH-1:OFFSET_WIDTH] != pc_in[PC_WIDTH-1:OFFSET_WIDTH]);

// if last miss & this cycle cacheline fetched, set ins hit
assign ins_hit = ~reset && ~flush && (if_bypass | (pc_in[PC_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr][PC_WIDTH-1:OFFSET_WIDTH] && dff_valid[pop_line_ptr]));
assign ins_miss = flush |
                  if_bypass_ne | 
                  (dff_valid[pop_line_ptr] & (pc_in[PC_WIDTH-1:OFFSET_WIDTH] != dff_base_pc[pop_line_ptr][PC_WIDTH-1:OFFSET_WIDTH]));

assign if_prefetch = dff_fetched[pop_line_ptr] & (dff_valid[pop_line_ptr] | l1i_fetch_if_resp_vld_i) & !dff_fetched[next_pop_line_ptr];
assign if_fetch = !dff_fetched[pop_line_ptr];
assign whether_fetch_o = if_prefetch | if_fetch;
// if last cycle misses, this cycle's output inst and pc are invalid, because new cacheline has not been filled in IB
// assign ib_valid = icache_prefetch_valid;
// }}}

// always @(posedge clk) begin
//     if (fetch_l1i_if_req_vld_o & fetch_l1i_if_req_rdy_i) begin
//         dff_fetch_pc <= pc_in;
//     end
// end

//==========================================================
// Line valid logic {{{

always @(*) begin
    if (pop_line_ptr != pop_line_ptr_second_half) begin
        in_a_line = 0;
    end else if (pop_line_ptr_second_half != pop_line_ptr_third_half && (is_rv_first_o || is_rv_second_o)) begin
        in_a_line = 0;
    end else if (pop_line_ptr_third_half != pop_line_ptr_fourth_half && is_rv_first_o && is_rv_second_o) begin
        in_a_line = 0;
    end else begin
        in_a_line = 1;
    end
end

always @(*) begin
    // has full inst
    // ins_hit: (buffer hit && current line valid) || (buffer not hit but new line coming in)
    if (ins_hit && in_a_line) begin
        has_full_inst = double_rdy_i;
        has_first_inst = single_rdy_i;
    // refill_o: pc_in's next line's pc is in the next line and that line is valid
    end else if (ins_hit && dff_valid[next_pop_line_ptr]) begin
        has_full_inst = double_rdy_i;
        has_first_inst = single_rdy_i;
    // has first inst
    end else if (ins_hit && (is_first_rvc | (pop_line_ptr == pop_line_ptr_second_half))) begin
        has_first_inst = single_rdy_i;
        has_full_inst = 0;
    // only the first half of the first inst is found in IB
    end else if (ins_hit) begin
        has_first_inst = 0;
        has_full_inst = 0;
    end else begin
        has_first_inst = 0;
        has_full_inst = 0;
    end
end

// }}}

//==========================================================
// Buffer pop logic {{{

//----------------------------------------------------------
// Valid instruction check

assign is_ibuf_empty = (rff_ibuf_size == 0);
assign is_first_valid = ~(rff_ibuf_size == 0);
assign is_second_valid = ~((rff_ibuf_size == 0) | (rff_ibuf_size == 1));
assign is_third_valid = ~((rff_ibuf_size == 0) | (rff_ibuf_size == 1) | (rff_ibuf_size == 2));
assign is_fourth_valid = ~((rff_ibuf_size == 0) | (rff_ibuf_size == 1) | (rff_ibuf_size == 2) | (rff_ibuf_size == 3));

assign first_start = rff_pop_ptr[PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0];
assign second_start = first_start + 1;
assign third_start = second_start + 1;
assign fourth_start = third_start + 1;

assign next_pop_line_ptr = pop_line_ptr + 1;
assign second_next_line = {next_pop_line_ptr, second_start};
assign third_next_line = {next_pop_line_ptr, third_start};
assign fourth_next_line = {next_pop_line_ptr, fourth_start};

// if last cycle miss, this cycle's insts can be extracted directly from icache_input_prefetch_line
// issue: if icache_input_prefetch_line is not long enough to contain all the 4 elements, 
// we need to fetch new line in the next cycle?

// NOTICE: icache_input_prefetch_line VALID
/* verilator lint_off LATCH */

always @(*) begin
        // last miss
        // successfully fetched one cacheline from i$
    if (if_bypass) begin
        first_element = icache_input_prefetch_line[SIZE_ELEMENT*first_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
        second_element = icache_input_prefetch_line[SIZE_ELEMENT*second_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
        third_element = icache_input_prefetch_line[SIZE_ELEMENT*third_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
        fourth_element = icache_input_prefetch_line[SIZE_ELEMENT*fourth_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
        if (second_start == 0) begin
            second_element = dff_inst_buffer[second_next_line];
            third_element = dff_inst_buffer[third_next_line];
            fourth_element = dff_inst_buffer[fourth_next_line];
        end else if (third_start == 0) begin
            third_element = dff_inst_buffer[third_next_line];
            fourth_element = dff_inst_buffer[fourth_next_line];
        end else if (fourth_start == 0) begin
            fourth_element = dff_inst_buffer[fourth_next_line];
        end
    end else if (icache_prefetch_valid) begin
        // last hit
        first_element = dff_inst_buffer[rff_pop_ptr];
        second_element = dff_inst_buffer[pop_ptr_second_half];
        third_element = dff_inst_buffer[pop_ptr_third_half];
        fourth_element = dff_inst_buffer[pop_ptr_fourth_half];
    end
end
/* verilator lint_on LATCH */
// assign first_element = icache_prefetch_valid ? dff_inst_buffer[rff_pop_ptr] : icache_input_prefetch_line[first_start:second_start-1];
// assign second_element = icache_prefetch_valid ? dff_inst_buffer[pop_ptr_second_half] : icache_input_prefetch_line[second_start:third_start-1];
// assign third_element = icache_prefetch_valid ? dff_inst_buffer[pop_ptr_third_half] : icache_input_prefetch_line[third_start:fourth_start-1];
// assign fourth_element = icache_prefetch_valid ? dff_inst_buffer[pop_ptr_fourth_half] : icache_input_prefetch_line[fourth_start:fourth_start+SIZE_ELEMENT-1];

assign is_first_rvc = (first_element[1:0] != 2'b11);
assign is_second_rvc = (second_element[1:0] != 2'b11);
assign is_third_rvc = (third_element[1:0] != 2'b11);

assign has_first_inst_in_size = is_first_valid & (is_first_rvc | is_second_valid);
assign has_full_inst_in_size = is_first_valid & (is_first_rvc | is_second_valid & (is_second_rvc | is_third_valid & (is_third_rvc | is_fourth_valid)));
assign is_first_valid_o = has_first_inst;
assign is_second_valid_o = has_full_inst;
//----------------------------------------------------------
// Instruction buffer response


assign is_half1_excp = dff_excp_valid[pop_line_ptr];
assign is_half2_excp = dff_excp_valid[pop_line_ptr_second_half];
assign is_half3_excp = (is_first_rvc & is_second_rvc) ? '0 : dff_excp_valid[pop_line_ptr_third_half];
assign is_half4_excp = (is_first_rvc | is_second_rvc) ? '0 : dff_excp_valid[pop_line_ptr_fourth_half];

assign pc_first_o = pc_in;
assign pc_second_o = pc_in + (is_first_rvc ? 2 : 4);
assign next_pc_first_o = pc_in + (is_first_rvc ? 2 : 4);
assign next_pc_second_o = pc_second_o + (is_rv_second_o ? 4 : 2);
assign instruction_first_o = is_first_rvc ? {16'h0000, first_element} : {second_element, first_element};
assign instruction_second_o = is_first_rvc 
                            ? (is_second_rvc ? {16'h0000, second_element} : {third_element, second_element}) 
                            : (is_third_rvc ? {16'h0000, third_element} : {fourth_element, third_element});
assign is_rv_first_o = ~is_first_rvc;
assign is_rv_second_o = ~((is_first_rvc & is_second_rvc) | (~is_first_rvc & is_third_rvc));

/* verilator lint_off LATCH */
// ------------------------------------------------------------bypass exception------------------------------------------------------------
always @(*) begin
    if (is_half1_excp) begin
        exception_valid_first_o = '1;
        ecause_first_o = dff_excp_cause[pop_line_ptr];
    end else if (is_half2_excp) begin
        if (is_first_rvc) begin
            exception_valid_second_o = '1;
            ecause_second_o = dff_excp_cause[pop_line_ptr_second_half];
        end else begin
            exception_valid_first_o = '1;
            ecause_first_o = dff_excp_cause[pop_line_ptr_second_half];
        end
    end else if (is_half3_excp) begin
        exception_valid_second_o = '1;
        ecause_second_o = dff_excp_cause[pop_line_ptr_third_half];
    end else if (is_half4_excp) begin
        exception_valid_second_o = '1;
        ecause_second_o = dff_excp_cause[pop_line_ptr_fourth_half];
    end else begin
        exception_valid_first_o = '0;
        exception_valid_second_o = '0;
    end
end
/* verilator lint_on LATCH */
//----------------------------------------------------------
// Update pop ptr
always @(*) begin
    if (reset) begin
        next_pop_ptr = 0;
    end else if (flush) begin
        next_pop_ptr = {0,pc_in[OFFSET_WIDTH-1:1]};
    end else if (has_full_inst) begin
        if (~is_rv_first_o & ~is_rv_second_o) begin
            next_pop_ptr = rff_pop_ptr + 2;
            pop_size = 2;
        end else if (~is_rv_first_o | ~is_rv_second_o) begin
            next_pop_ptr = rff_pop_ptr + 3;
            pop_size = 3;
        end else begin
            next_pop_ptr = rff_pop_ptr + 4;
            pop_size = 4;
        end
    end else if (has_first_inst) begin
        if (~is_rv_first_o) begin
            next_pop_ptr = rff_pop_ptr + 1;
            pop_size = 1;
        end else begin
            next_pop_ptr = rff_pop_ptr + 2;
            pop_size = 2;
        end
    end else if (ins_hit) begin
        next_pop_ptr = rff_pop_ptr;
        pop_size = 0;
    end else begin
        next_pop_ptr = rff_pop_ptr;
        pop_size = {1'b0, pc_in[OFFSET_WIDTH-1:0]}; // notice: the update timing for pop_size and push_size
    end
end

// assign next_pop_ptr = rff_pop_ptr + (is_first_rvc & is_second_rvc) ? 2 
//                     : ((is_first_rvc | is_second_rvc) ? 3 
//                     : 4);
assign pop_ptr_second_half = rff_pop_ptr + 1;
assign pop_ptr_third_half = pop_ptr_second_half + 1;
assign pop_ptr_fourth_half = pop_ptr_third_half + 1;

//assign pop_size = (ins_hit) ? ((is_first_rvc & is_second_rvc) ? 2 : ((is_first_rvc | is_second_rvc) ? 3 : 4)) : '0;

assign pop_line_ptr = rff_pop_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];
assign last_pop_line_ptr = last_pop_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];
assign pop_line_ptr_second_half = pop_ptr_second_half[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];
assign pop_line_ptr_third_half = pop_ptr_third_half[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];
assign pop_line_ptr_fourth_half = pop_ptr_fourth_half[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];

always @(posedge clk) begin
    if (reset) begin
        rff_pop_ptr <= '0;
        last_pop_ptr <= 0;
    end else if (flush) begin
        last_pop_ptr <= rff_pop_ptr;
        rff_pop_ptr <= {0,pc_in[OFFSET_WIDTH-1:1]};
    end else begin
        if (ins_hit) begin
            last_pop_ptr <= rff_pop_ptr;
            rff_pop_ptr <= next_pop_ptr;
        end else begin
            last_pop_ptr <= rff_pop_ptr;
            rff_pop_ptr <= {pop_line_ptr,pc_in[OFFSET_WIDTH-1:1]};
        end
    end
end

// }}}

//==========================================================
// Buffer push logic {{{

//----------------------------------------------------------
// Get prefetch vpc and output to fetch


// offset: position in a line of 16Bytes, 4 bits to locate each byte
// index: index + 1, offset = 0 to fetch the beginning of the next line
assign next_cache_line = {{(PC_WIDTH-OFFSET_WIDTH-1){1'b0}}, 1'b1, {OFFSET_WIDTH{1'b0}}};
assign prefetch_vpc = ins_hit ? {pc_in[PC_WIDTH-1: OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}} + next_cache_line : pc_in;
//assign push_size = (icache_prefetch_valid & ~refill_i) ? NUM_ELEMENTS_PER_LINE : 0;

// last hit & no need to prefetch: no need to push
// (last hit & prefetch) | (last miss): fill in one line
// if ins_hit && next line is already in IB, next cycle no need to prefetch
// assign refill_o = pc_paddr_in[PADDR_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr + 1][PADDR_WIDTH-1:OFFSET_WIDTH];
// refill_o: 1 for no need to prefetch
assign refill_o = ~reset && ~flush && (prefetch_vpc[PC_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[next_pop_line_ptr][PC_WIDTH-1:OFFSET_WIDTH] && dff_fetched[next_pop_line_ptr]) |
                                      ((prefetch_vpc[PC_WIDTH-1:OFFSET_WIDTH] == pc_base[PC_WIDTH-1:OFFSET_WIDTH]) & haha & dff_fetched[next_pop_line_ptr]);
assign prefetch_line_number_o = pop_line_ptr + 1;
//----------------------------------------------------------

// push_ptr[high]
assign push_line_ptr = rff_push_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];

///*

always @(posedge clk) begin
    if (reset || flush) begin
        for (integer i = 0; i < NUM_ELEMENTS; i = i + 1) begin
            dff_inst_buffer[i] <= 0;
        end
    end else if (haha) begin
        for (integer i= 0; i < NUM_ELEMENTS_PER_LINE; i = i + 1) begin
            if (~push_line_ptr) begin
                dff_inst_buffer[i] <= icache_input_prefetch_line[SIZE_ELEMENT*i+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end else begin
                dff_inst_buffer[NUM_ELEMENTS_PER_LINE + i] <= icache_input_prefetch_line[SIZE_ELEMENT*i+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end
        end
    end
end

always @(posedge clk) begin
    if (reset || flush) begin
        for (int i = 0; i < INS_BUFFER_SIZE; i = i + 1) begin
            dff_excp_cause[i] <= 0;
        end
    end else if (haha) begin
        dff_excp_cause[push_line_ptr] <= ecause_in;
    end
end

always @(posedge clk) begin
    if (reset || flush) begin
        dff_excp_valid <= 0;
    end else if (haha) begin
        dff_excp_valid[push_line_ptr] <= exception_valid_in;
    end
end

always @(posedge clk) begin
    if (reset || flush) begin
        rff_push_ptr <= 0;
    end else if (haha) begin
        rff_push_ptr <= rff_push_ptr + 8;
    end
end

always @(posedge clk) begin
    if (reset || flush) begin
        dff_valid <= 0;
    end else if (next_pop_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1] != pop_line_ptr) begin
            dff_valid[pop_line_ptr] <= 0;
    end

    if ((next_pop_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1] != pop_line_ptr) & (pop_line_ptr == push_line_ptr)) begin
        dff_valid[push_line_ptr] <= 0;
    end else if (haha) begin
        dff_valid[push_line_ptr] <= 1;
    end
end


wire handshake;
assign handshake = fetch_l1i_if_req_rdy_i & fetch_l1i_if_req_vld_o;
always @(posedge clk) begin
    if (reset || flush) begin
        dff_fetched <= 0;
    end else begin
        if (handshake & ~itlb_fetch_miss_i) begin
            dff_fetched[prefetch_ins_line] <= 1;
        end
        if (next_pop_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1] != pop_line_ptr) begin
            dff_fetched[pop_line_ptr] <= 0;
        end
    end
end
assign prefetch_ins_line = dff_fetched[pop_line_ptr] ? pop_line_ptr + 1 : pop_line_ptr;
// fetch's process speed is faster than icache's response

assign haha = ~reset && ~flush && l1i_fetch_if_resp_vld_i;
// reg last_flush;

always @(posedge clk) begin
    if (reset || flush) begin
        dff_base_pc[0] <= 0;
        dff_base_pc[1] <= 0;
    end else if (haha) begin
        dff_base_pc[push_line_ptr] <= {pc_base[PC_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
    end
end

endmodule
