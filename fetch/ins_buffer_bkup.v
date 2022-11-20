// 2 lines, 16*8 in each line, configurable
`include "params.vh"

module ins_buffer #(
    parameter INS_BUFFER_DATA = 128,
    parameter INS_BUFFER_SIZE = 2,
    parameter INS_BUFFER_SIZE_WIDTH = 1,
    parameter PADDR_WIDTH = 40,
    parameter OFFSET_WIDTH = 4,
    parameter INDEX_WIDTH = 8,
    parameter SIZE_ELEMENT = 16,
    parameter NUM_ELEMENTS = INS_BUFFER_SIZE * INS_BUFFER_DATA / SIZE_ELEMENT,
    parameter PTR_WIDTH = $clog2(NUM_ELEMENTS),
    parameter NUM_ELEMENTS_PER_LINE = NUM_ELEMENTS / INS_BUFFER_SIZE
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

reg[PTR_WIDTH:0] rff_ibuf_size;
reg[PTR_WIDTH:0] pop_size;
reg[PTR_WIDTH:0] push_size;

reg [PTR_WIDTH-1:0] rff_pop_ptr;
reg [PTR_WIDTH-1:0] next_pop_ptr;
reg [PTR_WIDTH-1:0] pop_ptr_second_half;
reg [PTR_WIDTH-1:0] pop_ptr_third_half;
reg [PTR_WIDTH-1:0] pop_ptr_fourth_half;

reg [PTR_WIDTH-1:0] rff_push_ptr;

reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr;
reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr_second_half;
reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr_third_half;
reg [INS_BUFFER_SIZE_WIDTH-1:0] pop_line_ptr_fourth_half;

//==========================================================
// Size {{{

/*
always @(posedge clk) begin
    if (reset) begin
        rff_ibuf_size <= '0;
    end else begin
        if (flush) begin
            rff_ibuf_size <= '0;
        end else begin
            rff_ibuf_size <= rff_ibuf_size + push_size - pop_size;
        end
    end
end
*/


assign ins_full = (rff_ibuf_size == 16);
assign ins_empty = (rff_ibuf_size == 0);
// }}}

//==========================================================
// Hit miss logic {{{

// Since icache is VIPT, we need to lookup physical tag, and compare tag+index to IB's base_pc
// if icache_prefetch_valid == 0, indicating that the input cacheline contains current pc, so hit
// compare tag + index
// assign ins_hit = has_full_inst & (pc_paddr_in[PADDR_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr][PADDR_WIDTH-1:OFFSET_WIDTH] ? 1 : 0);

// if last miss & this cycle cacheline fetched, set ins hit
assign ins_hit = ~reset && ~flush && ((~icache_prefetch_valid & l1i_fetch_if_resp_vld_i) | pc_in[PC_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr][PC_WIDTH-1:OFFSET_WIDTH] && dff_valid[pop_line_ptr]) ? 1 : 0;
// if last cycle misses, this cycle's output inst and pc are invalid, because new cacheline has not been filled in IB
// assign ib_valid = icache_prefetch_valid;
// }}}

//==========================================================
// Line valid logic {{{

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

always @(*) begin
    if (pop_line_ptr != pop_line_ptr_second_half) begin
        in_a_line = 0;
    end else if (pop_line_ptr_second_half != pop_line_ptr_third_half && !(is_first_rvc && is_second_rvc)) begin
        in_a_line = 0;
    end else if (pop_line_ptr_third_half != pop_line_ptr_fourth_half && !(is_first_rvc || is_second_rvc)) begin
        in_a_line = 0;
    end else begin
        in_a_line = 1;
    end
end

always @(*) begin
    // has full inst
    if (ins_hit && in_a_line && has_full_inst_in_size) begin
        has_full_inst = 1;
        has_first_inst = 1;
    end else if (ins_hit && refill_o && has_full_inst_in_size) begin
        has_full_inst = 1;
        has_first_inst = 1;
    // has first inst
    end else if (ins_hit && (is_first_rvc | (pop_line_ptr == pop_line_ptr_second_half)) && has_first_inst_in_size) begin
        has_first_inst = 1;
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

reg [SIZE_ELEMENT-1:0] first_element;
reg [SIZE_ELEMENT-1:0] second_element;
reg [SIZE_ELEMENT-1:0] third_element;
reg [SIZE_ELEMENT-1:0] fourth_element;

wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] first_start;
wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] second_start;
wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] third_start;
wire [PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0] fourth_start;


assign is_ibuf_empty = (rff_ibuf_size == 0);
assign is_first_valid = ~(rff_ibuf_size == 0);
assign is_second_valid = ~((rff_ibuf_size == 0) | (rff_ibuf_size == 1));
assign is_third_valid = ~((rff_ibuf_size == 0) | (rff_ibuf_size == 1) | (rff_ibuf_size == 2));
assign is_fourth_valid = ~((rff_ibuf_size == 0) | (rff_ibuf_size == 1) | (rff_ibuf_size == 2) | (rff_ibuf_size == 3));

assign first_start = rff_pop_ptr[PTR_WIDTH-INS_BUFFER_SIZE_WIDTH-1:0];
assign second_start = first_start + 1;
assign third_start = second_start + 1;
assign fourth_start = third_start + 1;

wire [INS_BUFFER_SIZE_WIDTH-1:0] next_pop_line_ptr = pop_line_ptr + 1;
wire [PTR_WIDTH-1:0] second_next_line = {next_pop_line_ptr, second_start};
wire [PTR_WIDTH-1:0] third_next_line = {next_pop_line_ptr, third_start};
wire [PTR_WIDTH-1:0] fourth_next_line = {next_pop_line_ptr, fourth_start};

// if last cycle miss, this cycle's insts can be extracted directly from icache_input_prefetch_line
// issue: if icache_input_prefetch_line is not long enough to contain all the 4 elements, 
// we need to fetch new line in the next cycle?

// NOTICE: icache_input_prefetch_line VALID
/* verilator lint_off LATCH */
always @(*) begin
    if (icache_prefetch_valid) begin
        // last hit
        first_element = dff_inst_buffer[rff_pop_ptr];
        second_element = dff_inst_buffer[pop_ptr_second_half];
        third_element = dff_inst_buffer[pop_ptr_third_half];
        fourth_element = dff_inst_buffer[pop_ptr_fourth_half];
    end else begin
        // last miss
        // successfully fetched one cacheline from i$
        if (l1i_fetch_if_resp_vld_i) begin
            first_element = icache_input_prefetch_line[SIZE_ELEMENT*first_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            if (second_start == 0) begin
                second_element = dff_inst_buffer[second_next_line];
                third_element = dff_inst_buffer[third_next_line];
                fourth_element = dff_inst_buffer[fourth_next_line];
            end else if (third_start == 0) begin
                third_element = dff_inst_buffer[third_next_line];
                fourth_element = dff_inst_buffer[fourth_next_line];
            end else if (fourth_start == 0) begin
                fourth_element = dff_inst_buffer[fourth_next_line];
            end else begin
                second_element = icache_input_prefetch_line[SIZE_ELEMENT*second_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
                third_element = icache_input_prefetch_line[SIZE_ELEMENT*third_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
                fourth_element = icache_input_prefetch_line[SIZE_ELEMENT*fourth_start+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end
        end
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

reg is_half1_excp;
reg is_half2_excp;
reg is_half3_excp;
reg is_half4_excp;

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
    if (has_full_inst) begin
        if (is_first_rvc & is_second_rvc) begin
            next_pop_ptr = rff_pop_ptr + 2;
            pop_size = 2;
        end else if (is_first_rvc | is_second_rvc) begin
            next_pop_ptr = rff_pop_ptr + 3;
            pop_size = 3;
        end else begin
            next_pop_ptr = rff_pop_ptr + 4;
            pop_size = 4;
        end
    end else if (has_first_inst) begin
        if (is_first_rvc) begin
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
        pop_size = 8; // notice: the update timing for pop_size and push_size
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
assign pop_line_ptr_second_half = pop_ptr_second_half[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];
assign pop_line_ptr_third_half = pop_ptr_third_half[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];
assign pop_line_ptr_fourth_half = pop_ptr_fourth_half[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1];

always @(posedge clk) begin
    if (reset || flush) begin
        rff_pop_ptr <= '0;
        dff_valid <= 0;
    end else begin
        if (~icache_prefetch_valid) begin
            // last miss
            rff_pop_ptr <= rff_pop_ptr;
        end else if (ins_hit) begin
            if (next_pop_ptr[PTR_WIDTH-1:PTR_WIDTH-1-INS_BUFFER_SIZE_WIDTH+1] != 
                pop_line_ptr) begin
                dff_valid[pop_line_ptr] <= 0;
            end
            rff_pop_ptr <= next_pop_ptr;
        end else begin
            // rff_pop_ptr <= {pop_line_ptr,miss_pc[OFFSET_WIDTH-1:INS_BUFFER_SIZE_WIDTH]};

            // ins buffer miss:
            // next cycle will refill current line
            // and the position of pop ptr should stay the same

            // miss: current line is invalid
            dff_valid[pop_line_ptr] <= 0;
            // rff_pop_ptr <= {pop_line_ptr,pc_in[OFFSET_WIDTH-1-INS_BUFFER_SIZE_WIDTH:0]};
            rff_pop_ptr <= rff_pop_ptr;
        end
    end
end

// }}}

//==========================================================
// Buffer push logic {{{

//----------------------------------------------------------
// Get prefetch vpc and output to fetch

reg [PC_WIDTH-1:0] next_cache_line;

// offset: position in a line of 16Bytes, 4 bits to locate each byte
// index: index + 1, offset = 0 to fetch the beginning of the next line
assign next_cache_line = {{(PC_WIDTH-OFFSET_WIDTH-1){1'b0}}, 1'b1, {OFFSET_WIDTH{1'b0}}};
assign prefetch_vpc = ins_hit ? {pc_in[PC_WIDTH-1: OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}} + next_cache_line : pc_in;
//assign push_size = (icache_prefetch_valid & ~refill_i) ? NUM_ELEMENTS_PER_LINE : 0;

// last hit & no need to prefetch: no need to push
// (last hit & prefetch) | (last miss): fill in one line
// if ins_hit && next line is already in IB, next cycle no need to prefetch
// assign refill_o = pc_paddr_in[PADDR_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr + 1][PADDR_WIDTH-1:OFFSET_WIDTH];
// refill_o: 0 for no need to prefetch
assign refill_o = prefetch_vpc[PC_WIDTH-1:OFFSET_WIDTH] == dff_base_pc[pop_line_ptr + 1][PC_WIDTH-1:OFFSET_WIDTH];
assign prefetch_line_number_o = pop_line_ptr + 1;
//----------------------------------------------------------
// Prefetch logic

always @(posedge clk) begin
    if (reset || flush) begin
        dff_inst_buffer[0] <= 0;
        dff_inst_buffer[1] <= 0;
        dff_excp_valid[0] <= 0;
        dff_excp_valid[1] <= 0;
        dff_base_pc[0] <= 0;
        dff_base_pc[1] <= 0;
        dff_valid[0] <= 0;
        dff_valid[1] <= 0;
        push_size <= 0;
    // if last cycle's IB hit and no refill and cacheline fetched, fill in cacheline to last cycle's next line
    end else if (icache_prefetch_valid & ~refill_i & l1i_fetch_if_resp_vld_i) begin
        // fill up one line

        // first line
        if (prefetch_line_number_i == 0) begin
            for (int i=0; i<NUM_ELEMENTS_PER_LINE; i++) begin
                dff_inst_buffer[i] <= icache_input_prefetch_line[SIZE_ELEMENT*i+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end

        // or second line
        end else begin
            for (int i=0; i<NUM_ELEMENTS_PER_LINE; i++) begin
                dff_inst_buffer[NUM_ELEMENTS_PER_LINE+i] <= icache_input_prefetch_line[SIZE_ELEMENT*i+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end
        end

        // Update exception and valid bits
        dff_excp_valid[prefetch_line_number_i] <= exception_valid_in;
        dff_excp_cause[prefetch_line_number_i] <= ecause_in;
        dff_base_pc[prefetch_line_number_i] <= {pc_in[PC_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
        dff_valid[prefetch_line_number_i] <= 1;
        push_size <= 8;

    // if last cycle's IB miss and cacheline fetched, fill in cacheline at current line number
    end else if (~icache_prefetch_valid & l1i_fetch_if_resp_vld_i) begin
        // fill up one line

        // first line
        if (pop_line_ptr == 0) begin
            for (int i=0; i<NUM_ELEMENTS_PER_LINE; i++) begin
                dff_inst_buffer[i] <= icache_input_prefetch_line[SIZE_ELEMENT*i+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end

        // or second line
        end else begin
            for (int i=0; i<NUM_ELEMENTS_PER_LINE; i++) begin
                dff_inst_buffer[NUM_ELEMENTS_PER_LINE+i] <= icache_input_prefetch_line[SIZE_ELEMENT*i+SIZE_ELEMENT-1-:SIZE_ELEMENT];
            end
        end

        // Update exception and valid bits
        dff_excp_valid[pop_line_ptr] <= exception_valid_in;
        dff_excp_cause[pop_line_ptr] <= ecause_in;
        dff_base_pc[pop_line_ptr] <= {pc_in[PC_WIDTH-1:OFFSET_WIDTH], {OFFSET_WIDTH{1'b0}}};
        dff_valid[pop_line_ptr] <= 1;
        push_size <= 8;
    end else begin
        push_size <= 0;
    end
end

endmodule
