`ifndef _LSU_LSQ_ENTRY_V_
`define _LSU_LSQ_ENTRY_V_
`ifdef VERILATOR
`include "params.vh"
`endif

module lsu_lsq_entry (
    // global
    input clk, rst, flush,
    // init
    input                                       lsq_entry_vld_i,
    input                                       lsq_entry_ls_i,
    input                                       lsq_entry_only_enque_i,
    input [VIRTUAL_ADDR_TAG_LEN - 1 : 0]        lsq_entry_vtag_i,
    input [LSQ_ENTRY_OPCODE_WIDTH - 1 : 0]      lsq_entry_opcode_i,
    input                                       lsq_entry_fenced_i,
    input [LSQ_ENTRY_INDEX_WIDTH -1 : 0]        lsq_entry_index_i,
    input [LSQ_ENTRY_OFFSET_WIDTH - 1 : 0]      lsq_entry_offset_i,
    input [LSQ_ENTRY_ROB_INDEX_WIDTH - 1 : 0]   lsq_entry_rob_index_i,
    input [LSQ_ENTRY_RD_ADDR_WIDTH - 1 : 0]     lsq_entry_rd_addr_i,
    input [XLEN - 1 : 0]                        lsq_entry_data_i,
    input                                       lsq_entry_exception_vld_i,
    input [EXCEPTION_CAUSE_WIDTH - 1 : 0]       lsq_entry_ecause_i,
    // tlb
    input                                       dtlb_lsq_entry_vld_i,
    input                                       dtlb_lsq_entry_virt_i,
    input [LSQ_ENTRY_TAG_WIDTH - 1 : 0]         dtlb_lsq_entry_tag_i,
    input                                       dtlb_lsq_entry_exception_vld_i,
    input [EXCEPTION_CAUSE_WIDTH - 1 : 0]       dtlb_lsq_entry_ecause_i,                                       
    // wakeup
    input                                       lsq_entry_awake_i,
    // issued
    input                                       lsq_entry_exec_i,
    input                                       lsq_entry_replay_i,
    // done
    input                                       lsq_entry_succ_i,
    // deque
    input                                       lsq_entry_invld_i,
    //output 
    output                                      lsq_entry_vld_o,
    output                                      lsq_entry_ls_o,
    output [LSQ_ENTRY_OPCODE_WIDTH - 1 : 0]     lsq_entry_opcode_o,
    output                                      lsq_entry_fenced_o,
    output [LSQ_ENTRY_TAG_WIDTH - 1 : 0]        lsq_entry_tag_o,
    output [LSQ_ENTRY_INDEX_WIDTH -1 : 0]       lsq_entry_index_o,
    output [LSQ_ENTRY_OFFSET_WIDTH - 1 : 0]     lsq_entry_offset_o,
    output [LSQ_ENTRY_ROB_INDEX_WIDTH - 1 : 0]  lsq_entry_rob_index_o,
    output                                      lsq_entry_virt_o,
    output                                      lsq_entry_awake_o,
    output                                      lsq_entry_exec_o,
    output                                      lsq_entry_succ_o,
    output [LSQ_ENTRY_RD_ADDR_WIDTH - 1 : 0]    lsq_entry_rd_addr_o,
    output [XLEN - 1 : 0]                       lsq_entry_data_o,
    output                                      lsq_entry_exception_vld_o,
    output [EXCEPTION_CAUSE_WIDTH - 1 : 0]      lsq_entry_ecause_o
);

wire                                        lsq_entry_vld_d;
wire                                        lsq_entry_ls_d;
wire [LSQ_ENTRY_OPCODE_WIDTH - 1 : 0]       lsq_entry_opcode_d;
wire                                        lsq_entry_fenced_d;
wire [LSQ_ENTRY_INDEX_WIDTH -1 : 0]         lsq_entry_index_d;
wire [LSQ_ENTRY_OFFSET_WIDTH - 1 : 0]       lsq_entry_offset_d;
wire [LSQ_ENTRY_ROB_INDEX_WIDTH - 1 : 0]    lsq_entry_rob_index_d;
wire [LSQ_ENTRY_RD_ADDR_WIDTH - 1 : 0]      lsq_entry_rd_addr_d;
wire [XLEN - 1 : 0]                         lsq_entry_data_d;
wire [LSQ_ENTRY_TAG_WIDTH - 1 : 0]          lsq_entry_tag_d;
wire                                        lsq_entry_virt_d;
wire                                        lsq_entry_awake_d;
wire                                        lsq_entry_exec_d;
wire                                        lsq_entry_succ_d;
wire                                        lsq_entry_exception_vld_d;
wire [EXCEPTION_CAUSE_WIDTH - 1 : 0]        lsq_entry_ecause_d;

wire                                        lsq_entry_tag_en;
wire                                        lsq_entry_virt_en;
wire                                        lsq_entry_awake_en;
wire                                        lsq_entry_exec_en;
wire                                        lsq_entry_succ_en;
wire                                        lsq_entry_exception_en;



reg                                         lsq_entry_vld_q;
reg                                         lsq_entry_ls_q;
reg[LSQ_ENTRY_OPCODE_WIDTH - 1 : 0]         lsq_entry_opcode_q;
reg                                         lsq_entry_fenced_q;
reg[LSQ_ENTRY_TAG_WIDTH - 1 : 0]            lsq_entry_tag_q;
reg[LSQ_ENTRY_INDEX_WIDTH -1 : 0]           lsq_entry_index_q;
reg[LSQ_ENTRY_OFFSET_WIDTH - 1 : 0]         lsq_entry_offset_q;
reg[LSQ_ENTRY_ROB_INDEX_WIDTH - 1 : 0]      lsq_entry_rob_index_q;
reg                                         lsq_entry_virt_q;
reg                                         lsq_entry_awake_q;
reg                                         lsq_entry_exec_q;
reg                                         lsq_entry_succ_q;
reg[LSQ_ENTRY_RD_ADDR_WIDTH - 1 : 0]        lsq_entry_rd_addr_q;
reg[XLEN - 1 : 0]                           lsq_entry_data_q;
reg                                         lsq_entry_exception_vld_q;
reg [EXCEPTION_CAUSE_WIDTH - 1 : 0]         lsq_entry_ecause_q;

assign lsq_entry_vld_d              = lsq_entry_vld_i | ~lsq_entry_invld_i;
assign lsq_entry_ls_d               = lsq_entry_ls_i;
assign lsq_entry_opcode_d           = lsq_entry_opcode_i;
assign lsq_entry_fenced_d           = lsq_entry_fenced_i;
assign lsq_entry_tag_d              = (lsq_entry_vld_i) ? {{(LSQ_ENTRY_TAG_WIDTH - VIRTUAL_ADDR_TAG_LEN){1'b0}}, lsq_entry_vtag_i} : dtlb_lsq_entry_tag_i;
assign lsq_entry_index_d            = lsq_entry_index_i;
assign lsq_entry_offset_d           = lsq_entry_offset_i;
assign lsq_entry_rob_index_d        = lsq_entry_rob_index_i;
assign lsq_entry_virt_d             = (lsq_entry_vld_i) ? 1 : dtlb_lsq_entry_virt_i;
assign lsq_entry_rd_addr_d          = lsq_entry_rd_addr_i;
assign lsq_entry_data_d             = lsq_entry_data_i;
assign lsq_entry_awake_d            = lsq_entry_awake_i;
assign lsq_entry_exec_d             = ~lsq_entry_replay_i & lsq_entry_exec_i;
assign lsq_entry_succ_d             = lsq_entry_vld_i ? 0 : lsq_entry_succ_i;
assign lsq_entry_exception_vld_d    = lsq_entry_vld_i ? lsq_entry_exception_vld_i : dtlb_lsq_entry_exception_vld_i;
assign lsq_entry_ecause_d           = lsq_entry_vld_i ? lsq_entry_ecause_i : dtlb_lsq_entry_ecause_i;
 
assign lsq_entry_vld_o              = lsq_entry_vld_q;
assign lsq_entry_ls_o               = lsq_entry_ls_q;
assign lsq_entry_opcode_o           = lsq_entry_opcode_q;
assign lsq_entry_fenced_o           = lsq_entry_fenced_q;
assign lsq_entry_tag_o              = lsq_entry_tag_q;
assign lsq_entry_index_o            = lsq_entry_index_q;
assign lsq_entry_offset_o           = lsq_entry_offset_q;
assign lsq_entry_rob_index_o        = lsq_entry_rob_index_q;
assign lsq_entry_virt_o             = lsq_entry_virt_q;
assign lsq_entry_awake_o            = lsq_entry_awake_q;
assign lsq_entry_exec_o             = lsq_entry_exec_q;
assign lsq_entry_succ_o             = lsq_entry_succ_q;
assign lsq_entry_rd_addr_o          = lsq_entry_rd_addr_q;
assign lsq_entry_data_o             = lsq_entry_data_q;
assign lsq_entry_exception_vld_o    = lsq_entry_exception_vld_q;
assign lsq_entry_ecause_o           = lsq_entry_ecause_q;

assign lsq_entry_tag_en             = dtlb_lsq_entry_vld_i | lsq_entry_vld_i;
assign lsq_entry_virt_en            = dtlb_lsq_entry_vld_i | lsq_entry_vld_i;
assign lsq_entry_awake_en           = lsq_entry_awake_i | lsq_entry_vld_i;
assign lsq_entry_exec_en            = lsq_entry_exec_i | lsq_entry_vld_i | lsq_entry_replay_i;
assign lsq_entry_succ_en            = lsq_entry_succ_i | lsq_entry_vld_i;
assign lsq_entry_exception_en       = lsq_entry_vld_i | dtlb_lsq_entry_vld_i & dtlb_lsq_entry_exception_vld_i;

always @(posedge clk) begin // valid bit
    if(rst | flush) begin
        lsq_entry_vld_q <= '0;
    end
    else begin
        if(lsq_entry_vld_i | lsq_entry_invld_i)begin
            lsq_entry_vld_q <= lsq_entry_vld_d;
        end
    end
end

always @(posedge clk) begin // initial data
    if(rst | flush) begin
        lsq_entry_ls_q <= '0;
        lsq_entry_opcode_q <= '0;
        lsq_entry_fenced_q <= '0;
        lsq_entry_index_q <= '0;
        lsq_entry_offset_q <= '0;
        lsq_entry_rob_index_q <= '0;
        lsq_entry_rd_addr_q <= '0;
        lsq_entry_data_q <= '0;
    end
    else begin
        if(lsq_entry_vld_i) begin
            lsq_entry_ls_q <= lsq_entry_ls_d;
            lsq_entry_opcode_q <= lsq_entry_opcode_d;
            lsq_entry_fenced_q <= lsq_entry_fenced_d;
            lsq_entry_index_q <= lsq_entry_index_d;
            lsq_entry_offset_q <= lsq_entry_offset_d;
            lsq_entry_rob_index_q <= lsq_entry_rob_index_d;
            lsq_entry_rd_addr_q <= lsq_entry_rd_addr_d;
            lsq_entry_data_q <= lsq_entry_data_d;
        end
    end 
end

always @(posedge clk) begin // tag
    if(rst | flush) begin
        lsq_entry_tag_q <= '0;
    end
    else begin
        if(lsq_entry_tag_en)begin
            lsq_entry_tag_q <= lsq_entry_tag_d;
        end
    end
end

always @(posedge clk) begin // tag
    if(rst | flush) begin
        lsq_entry_virt_q <= '0;
    end
    else begin
        if(lsq_entry_virt_en)begin
            lsq_entry_virt_q <= lsq_entry_virt_d;
        end
    end
end

always @(posedge clk) begin // awake
    if(rst | flush) begin
        lsq_entry_awake_q <= '0;
    end
    else begin
        if(lsq_entry_awake_en) begin
            lsq_entry_awake_q <= lsq_entry_awake_d;
        end
    end
end

always @(posedge clk) begin // exec
    if(rst | flush) begin
        lsq_entry_exec_q <= '0;
    end
    else begin
        if(lsq_entry_exec_en) begin
            lsq_entry_exec_q <= lsq_entry_exec_d;
        end
    end
end

always @(posedge clk) begin // succ
    if(rst | flush) begin
        lsq_entry_succ_q <= '0;
    end
    else begin
        if(lsq_entry_succ_en) begin
            lsq_entry_succ_q <= lsq_entry_succ_d;
        end
    end
end

always @(posedge clk) begin // succ
    if(rst | flush) begin
        lsq_entry_exception_vld_q <= 0;
        lsq_entry_ecause_q <= 0;
    end
    else begin
        if(lsq_entry_succ_en) begin
            lsq_entry_exception_vld_q <= lsq_entry_exception_vld_d;
            lsq_entry_ecause_q <= lsq_entry_ecause_d;
        end
    end
end

endmodule
`endif // _LSU_LSQ_ENTRY_V_
