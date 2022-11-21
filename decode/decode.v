`ifndef DECODE_V
`define DECODE_V
`ifdef VERILATOR
`include "params.vh"
`endif
module decode (
    input clk,
    input rst,

    // from fetch & inst buffer
    input [PC_WIDTH-1:0] pc_first_i,
    input [PC_WIDTH-1:0] pc_second_i,
    input [PC_WIDTH-1:0] next_pc_first_i,
    input [PC_WIDTH-1:0] next_pc_second_i,
    input [PC_WIDTH-1:0] predicted_pc_first_i,
    input [PC_WIDTH-1:0] predicted_pc_second_i,
    input is_rv_first_i,
    input is_rv_second_i,
    input [31:0] instruction_first_i,
    input [31:0] instruction_second_i,
    input exception_first_i,
    input exception_second_i,
    input [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_i,
    input [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_i,
    input fetch_deco_req_valid_first_i,
    input fetch_deco_req_valid_second_i,

    // from rob
    input deco_rob_req_ready_first_i,
    input deco_rob_req_ready_second_i,

    // from exp_ctrl
    input global_trap_i,
    input global_wfi_i,
    input global_predict_miss_i,
    input global_ret_i,

    // from PLIC and CLINT
    input msip_i,    // software interrupt pending
    input ssip_i,    // software interrupt pending
    input mtip_i,    // timer
    input stip_i,    // timer
    input eip_i,    // external

    input tsr_i,
    input tvm_i,
    input tw_i ,

    // from csr_regfile
    input [1:0] privilege_mode_i,

    // to fetch
    output fetch_deco_req_single_ready_o, // FIFO has at least two available entries
    output fetch_deco_req_double_ready_o, // FIFO has at least two available entries
    // to rob
    output reg uses_rs1_first_o,
    output reg uses_rs1_second_o,
    output reg uses_rs2_first_o,
    output reg uses_rs2_second_o,
    output reg uses_rd_first_o,
    output reg uses_rd_second_o,
    output reg uses_csr_first_o,
    output reg uses_csr_second_o,
    output reg [PC_WIDTH-1:0] pc_first_o,
    output reg [PC_WIDTH-1:0] pc_second_o,
    output reg [PC_WIDTH-1:0] next_pc_first_o,
    output reg [PC_WIDTH-1:0] next_pc_second_o,
    output reg [PC_WIDTH-1:0] predicted_pc_first_o,
    output reg [PC_WIDTH-1:0] predicted_pc_second_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_first_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rs1_address_second_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_first_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rs2_address_second_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_first_o,
    output reg [VIR_REG_ADDR_WIDTH-1:0] rd_address_second_o,
    output reg [CSR_ADDR_LEN-1:0] csr_address_first_o,
    output reg [CSR_ADDR_LEN-1:0] csr_address_second_o,
    output reg mret_first_o,
    output reg mret_second_o,
    output reg sret_first_o,
    output reg sret_second_o,
    output reg wfi_first_o,
    output reg wfi_second_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_o,
    output reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_o,
    output reg exception_first_o,
    output reg exception_second_o,
    output reg half_first_o,
    output reg half_second_o,
    output reg is_fence_first_o,
    output reg is_fence_second_o,
    output reg [1:0] fence_op_first_o,
    output reg [1:0] fence_op_second_o,
    output reg is_aext_first_o,
    output reg is_aext_second_o,
    output reg is_mext_first_o,
    output reg is_mext_second_o,

    // to rob (control)
    output reg deco_rob_req_valid_first_o,
    output reg deco_rob_req_valid_second_o,

    // to rob (csr)
    output reg csr_read_first_o,
    output reg csr_read_second_o,
    output reg csr_write_first_o,
    output reg csr_write_second_o,

    // to rob (alu, mul/div)
    output reg [31:0] imm_data_first_o,
    output reg [31:0] imm_data_second_o,
    output reg [2:0] fu_function_first_o,
    output reg [2:0] fu_function_second_o,
    output reg alu_function_modifier_first_o,
    output reg alu_function_modifier_second_o,
    output reg [1:0] fu_select_a_first_o,
    output reg [1:0] fu_select_a_second_o,
    output reg [1:0] fu_select_b_first_o,
    output reg [1:0] fu_select_b_second_o,

    // to rob (branch)
    output reg jump_first_o,
    output reg jump_second_o,
    output reg branch_first_o,
    output reg branch_second_o,

    // to rob (lsu)
    output reg is_alu_first_o,
    output reg is_alu_second_o,
    output reg load_first_o,
    output reg load_second_o,
    output reg store_first_o,
    output reg store_second_o,
    output reg [LDU_OP_WIDTH-1:0] ldu_op_first_o,
    output reg [LDU_OP_WIDTH-1:0] ldu_op_second_o,
    output reg [STU_OP_WIDTH-1:0] stu_op_first_o,
    output reg [STU_OP_WIDTH-1:0] stu_op_second_o,
    output reg aq_first_o,
    output reg aq_second_o,
    output reg rl_first_o,
    output reg rl_second_o
);

wire [31:0] rv_inst_first;
wire [31:0] rv_inst_second;

rvc_decoder rvc_dec_first (
    .clk(clk),
    .rst(rst),
    .is_rv_i(is_rv_first_i),
    .instruction_i(instruction_first_i),
    .rv_inst_o(rv_inst_first)
);

rvc_decoder rvc_dec_second (
    .clk(clk),
    .rst(rst),
    .is_rv_i(is_rv_second_i),
    .instruction_i(instruction_second_i),
    .rv_inst_o(rv_inst_second)
);

wire uses_rs1_first_w, uses_rs2_first_w, uses_rd_first_w, uses_csr_first_w; 
wire [PC_WIDTH-1:0] pc_first_w, next_pc_first_w, predicted_pc_first_w;
wire [4:0] rs1_address_first_w, rs2_address_first_w, rd_address_first_w; 
wire [11:0] csr_address_first_w; 
wire mret_first_w, sret_first_w, wfi_first_w; 
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_first_w, ecause_first_mid_w; 
reg exception_first_w, exception_first_mid_w, half_first_w, is_fence_first_w; 
wire [1:0] fence_op_first_w; 
wire is_aext_first_w, is_mext_first_w, csr_read_first_w, csr_write_first_w; 
wire [31:0] imm_data_first_w; 
wire [2:0] fu_function_first_w;
wire alu_function_modifier_first_w; 
wire [1:0] fu_select_a_first_w, fu_select_b_first_w; 
wire jump_first_w, branch_first_w, is_alu_first_w, load_first_w, store_first_w; 
wire [LDU_OP_WIDTH-1:0] ldu_op_first_w; 
wire [STU_OP_WIDTH-1:0] stu_op_first_w; 
wire aq_first_w, rl_first_w;

wire uses_rs1_second_w, uses_rs2_second_w, uses_rd_second_w, uses_csr_second_w; 
wire [PC_WIDTH-1:0] pc_second_w, next_pc_second_w, predicted_pc_second_w;
wire [4:0] rs1_address_second_w, rs2_address_second_w, rd_address_second_w; 
wire [11:0] csr_address_second_w; 
wire mret_second_w, sret_second_w, wfi_second_w; 
reg [EXCEPTION_CAUSE_WIDTH-1:0] ecause_second_w, ecause_second_mid_w; 
reg exception_second_w, exception_second_mid_w, half_second_w, is_fence_second_w; 
wire [1:0] fence_op_second_w; 
wire is_aext_second_w, is_mext_second_w, csr_read_second_w, csr_write_second_w; 
wire [31:0] imm_data_second_w; 
wire [2:0] fu_function_second_w;
wire alu_function_modifier_second_w; 
wire [1:0] fu_select_a_second_w, fu_select_b_second_w; 
wire jump_second_w, branch_second_w, is_alu_second_w, load_second_w, store_second_w; 
wire [LDU_OP_WIDTH-1:0] ldu_op_second_w; 
wire [STU_OP_WIDTH-1:0] stu_op_second_w; 
wire aq_second_w, rl_second_w;

rv_decoder rv_dec_first (
    .clk(clk),
    .rst(rst),
    .tsr_i(tsr_i),
    .tvm_i(tvm_i),
    .tw_i (tw_i ),
    .pc_i(pc_first_i),
    .next_pc_i(next_pc_first_i),
    .predicted_pc_i(predicted_pc_first_i),
    .rv_inst_i(rv_inst_first),
    .exception_i(exception_first_i),
    .ecause_i(ecause_first_i),
    .privilege_mode_i(privilege_mode_i),
    .uses_rs1_o(uses_rs1_first_w),
    .uses_rs2_o(uses_rs2_first_w),
    .uses_rd_o(uses_rd_first_w),
    .uses_csr_o(uses_csr_first_w),
    .pc_o(pc_first_w),
    .next_pc_o(next_pc_first_w),
    .predicted_pc_o(predicted_pc_first_w),
    .rs1_address_o(rs1_address_first_w),
    .rs2_address_o(rs2_address_first_w),
    .rd_address_o(rd_address_first_w),
    .csr_address_o(csr_address_first_w),
    .mret_o(mret_first_w),
    .sret_o(sret_first_w),
    .wfi_o(wfi_first_w),
    .ecause_o(ecause_first_mid_w),
    .exception_o(exception_first_mid_w),
    .half_o(half_first_w),
    .is_fence_o(is_fence_first_w),
    .fence_op_o(fence_op_first_w),
    .is_aext_o(is_aext_first_w),
    .is_mext_o(is_mext_first_w),
    .csr_read_o(csr_read_first_w),
    .csr_write_o(csr_write_first_w),
    .imm_data_o(imm_data_first_w),
    .fu_function_o(fu_function_first_w),
    .alu_function_modifier_o(alu_function_modifier_first_w),
    .fu_select_a_o(fu_select_a_first_w),
    .fu_select_b_o(fu_select_b_first_w),
    .jump_o(jump_first_w),
    .branch_o(branch_first_w),
    .is_alu_o(is_alu_first_w),
    .load_o(load_first_w),
    .store_o(store_first_w),
    .ldu_op_o(ldu_op_first_w),
    .stu_op_o(stu_op_first_w),
    .aq_o(aq_first_w),
    .rl_o(rl_first_w)
);

rv_decoder rv_dec_second (
    .clk(clk),
    .rst(rst),
    .tsr_i(tsr_i),
    .tvm_i(tvm_i),
    .tw_i (tw_i ),
    .pc_i(pc_second_i),
    .next_pc_i(next_pc_second_i),
    .predicted_pc_i(predicted_pc_second_i),
    .rv_inst_i(rv_inst_second),
    .exception_i(exception_second_i),
    .ecause_i(ecause_second_i),
    .privilege_mode_i(privilege_mode_i),
    .uses_rs1_o(uses_rs1_second_w),
    .uses_rs2_o(uses_rs2_second_w),
    .uses_rd_o(uses_rd_second_w),
    .uses_csr_o(uses_csr_second_w),
    .pc_o(pc_second_w),
    .next_pc_o(next_pc_second_w),
    .predicted_pc_o(predicted_pc_second_w),
    .rs1_address_o(rs1_address_second_w),
    .rs2_address_o(rs2_address_second_w),
    .rd_address_o(rd_address_second_w),
    .csr_address_o(csr_address_second_w),
    .mret_o(mret_second_w),
    .sret_o(sret_second_w),
    .wfi_o(wfi_second_w),
    .ecause_o(ecause_second_mid_w),
    .exception_o(exception_second_mid_w),
    .half_o(half_second_w),
    .is_fence_o(is_fence_second_w),
    .fence_op_o(fence_op_second_w),
    .is_aext_o(is_aext_second_w),
    .is_mext_o(is_mext_second_w),
    .csr_read_o(csr_read_second_w),
    .csr_write_o(csr_write_second_w),
    .imm_data_o(imm_data_second_w),
    .fu_function_o(fu_function_second_w),
    .alu_function_modifier_o(alu_function_modifier_second_w),
    .fu_select_a_o(fu_select_a_second_w),
    .fu_select_b_o(fu_select_b_second_w),
    .jump_o(jump_second_w),
    .branch_o(branch_second_w),
    .is_alu_o(is_alu_second_w),
    .load_o(load_second_w),
    .store_o(store_second_w),
    .ldu_op_o(ldu_op_second_w),
    .stu_op_o(stu_op_second_w),
    .aq_o(aq_second_w),
    .rl_o(rl_second_w)
);

always @(*) begin
    if (eip_i) begin
        exception_first_w = 1;
        ecause_first_w = INTERRUPT_EXTERNAL                ;
    end else if (stip_i) begin
        exception_first_w = 1;
        ecause_first_w = INTERRUPT_TIMER_SUPERVISOR        ;
    end else if (mtip_i) begin
        exception_first_w = 1;
        ecause_first_w = INTERRUPT_TIMER_MACHINE;
    end else if (ssip_i) begin
        exception_first_w = 1;
        ecause_first_w = INTERRUPT_SOFTWARE_SUPERVISOR             ;
    end else if (msip_i) begin
        exception_first_w = 1;
        ecause_first_w = INTERRUPT_SOFTWARE_MACHINE        ;
    end else begin
        exception_first_w = exception_first_mid_w;
        ecause_first_w = ecause_first_mid_w;
    end
    if (eip_i) begin
        exception_second_w = 1;
        ecause_second_w = INTERRUPT_EXTERNAL                ;
    end else if (stip_i) begin
        exception_second_w = 1;
        ecause_second_w = INTERRUPT_TIMER_SUPERVISOR        ;
    end else if (mtip_i) begin
        exception_second_w = 1;
        ecause_second_w = INTERRUPT_TIMER_MACHINE;
    end else if (ssip_i) begin
        exception_second_w = 1;
        ecause_second_w = INTERRUPT_SOFTWARE_SUPERVISOR             ;
    end else if (msip_i) begin
        exception_second_w = 1;
        ecause_second_w = INTERRUPT_SOFTWARE_MACHINE        ;
    end else begin
        exception_second_w = exception_second_mid_w;
        ecause_second_w = ecause_second_mid_w;
    end      
end

wire fifo_full, fifo_almost_full;
wire fifo_empty, fifo_almost_empty;
wire [DEC_FIFO_SIZE_WIDTH:0] fifo_num;
wire [DEC_FIFO_DATA_WIDTH-1:0] rdata_first, rdata_second;

wire wr_first_en =  (fetch_deco_req_valid_first_i ^ fetch_deco_req_valid_second_i) ? 
    (!fifo_full) : (fetch_deco_req_valid_first_i & !fifo_full);
wire wr_second_en = (fetch_deco_req_valid_first_i ^ fetch_deco_req_valid_second_i) ? 
    1'b0 : (fetch_deco_req_valid_first_i & !fifo_almost_full);
wire rd_first_en =  (deco_rob_req_ready_first_i ^ deco_rob_req_ready_second_i) ? 
    (!fifo_empty) : (deco_rob_req_ready_first_i & !fifo_empty);
wire rd_second_en = (deco_rob_req_ready_first_i ^ deco_rob_req_ready_second_i) ? 
    1'b0 : (deco_rob_req_ready_first_i & !fifo_almost_empty);

wire [DEC_FIFO_DATA_WIDTH-1:0] wdata_first = {
    uses_rs1_first_w, uses_rs2_first_w, uses_rd_first_w, uses_csr_first_w, 
    pc_first_w, next_pc_first_w, predicted_pc_first_w,
    rs1_address_first_w, rs2_address_first_w, rd_address_first_w, csr_address_first_w, mret_first_w, sret_first_w,
    wfi_first_w, ecause_first_w, exception_first_w, half_first_w, is_fence_first_w, fence_op_first_w, 
    is_aext_first_w, is_mext_first_w, csr_read_first_w, csr_write_first_w, imm_data_first_w, fu_function_first_w,
    alu_function_modifier_first_w, fu_select_a_first_w, fu_select_b_first_w, jump_first_w, branch_first_w, 
    is_alu_first_w, load_first_w, store_first_w, ldu_op_first_w, stu_op_first_w, aq_first_w, rl_first_w
};
wire [DEC_FIFO_DATA_WIDTH-1:0] wdata_second = {
    uses_rs1_second_w, uses_rs2_second_w, uses_rd_second_w, uses_csr_second_w, 
    pc_second_w, next_pc_second_w, predicted_pc_second_w,
    rs1_address_second_w, rs2_address_second_w, rd_address_second_w, csr_address_second_w, mret_second_w, sret_second_w,
    wfi_second_w, ecause_second_w, exception_second_w, half_second_w, is_fence_second_w, fence_op_second_w, 
    is_aext_second_w, is_mext_second_w, csr_read_second_w, csr_write_second_w, imm_data_second_w, fu_function_second_w,
    alu_function_modifier_second_w, fu_select_a_second_w, fu_select_b_second_w, jump_second_w, branch_second_w, 
    is_alu_second_w, load_second_w, store_second_w, ldu_op_second_w, stu_op_second_w, aq_second_w, rl_second_w
};

assign fetch_deco_req_single_ready_o = !fifo_full & !global_wfi_i;
assign fetch_deco_req_double_ready_o = !fifo_almost_full & !global_wfi_i;
assign deco_rob_req_valid_first_o = !fifo_empty;
assign deco_rob_req_valid_second_o = !fifo_almost_empty;

f2if2o #(
    .FIFO_DATA_WIDTH(DEC_FIFO_DATA_WIDTH),
    .FIFO_SIZE(DEC_FIFO_SIZE),
    .FIFO_SIZE_WIDTH(DEC_FIFO_SIZE_WIDTH)
) fifo(
    .clk(clk)                                    ,       
    .rst(rst | global_trap_i | global_predict_miss_i | global_ret_i)                                    ,       
    .wr_first_en_i(wr_first_en)                  ,      
    .wr_second_en_i(wr_second_en)                ,      
    .rd_first_en_i(rd_first_en)                  ,      
    .rd_second_en_i(rd_second_en)                ,      
    .wdata_first_i(wdata_first)                  ,      
    .wdata_second_i(wdata_second)                ,      
    .rdata_first_o(rdata_first)                  ,      
    .rdata_second_o(rdata_second)                ,      
    .fifo_full_o(fifo_full)                      ,      
    .fifo_almost_full_o(fifo_almost_full)        ,      
    .fifo_empty_o(fifo_empty)                    ,      
    .fifo_almost_empty_o(fifo_almost_empty)      ,      
    .fifo_num_o(fifo_num)                              
);

assign {uses_rs1_first_o                 ,
        uses_rs2_first_o                 ,
        uses_rd_first_o                  ,
        uses_csr_first_o                 ,
        pc_first_o                       ,
        next_pc_first_o                  ,
        predicted_pc_first_o             ,
        rs1_address_first_o              ,
        rs2_address_first_o              ,
        rd_address_first_o               ,
        csr_address_first_o              ,
        mret_first_o                     ,
        sret_first_o                     ,
        wfi_first_o                      ,
        ecause_first_o                   ,
        exception_first_o                ,
        half_first_o                     ,
        is_fence_first_o                 ,
        fence_op_first_o                 ,
        is_aext_first_o                  ,
        is_mext_first_o                  ,
        csr_read_first_o                 ,
        csr_write_first_o                ,
        imm_data_first_o                 ,
        fu_function_first_o              ,
        alu_function_modifier_first_o    ,
        fu_select_a_first_o              ,
        fu_select_b_first_o              ,
        jump_first_o                     ,
        branch_first_o                   ,
        is_alu_first_o                   ,
        load_first_o                     ,
        store_first_o                    ,
        ldu_op_first_o                   ,
        stu_op_first_o                   ,
        aq_first_o                       ,
        rl_first_o                       } = rdata_first;

assign {uses_rs1_second_o                ,
        uses_rs2_second_o                ,
        uses_rd_second_o                 ,
        uses_csr_second_o                ,
        pc_second_o                      ,
        next_pc_second_o                 ,
        predicted_pc_second_o            ,
        rs1_address_second_o             ,
        rs2_address_second_o             ,
        rd_address_second_o              ,
        csr_address_second_o             ,
        mret_second_o                    ,
        sret_second_o                    ,
        wfi_second_o                     ,
        ecause_second_o                  ,
        exception_second_o               ,
        half_second_o                    ,
        is_fence_second_o                ,
        fence_op_second_o                ,
        is_aext_second_o                 ,
        is_mext_second_o                 ,
        csr_read_second_o                ,
        csr_write_second_o               ,
        imm_data_second_o                ,
        fu_function_second_o             ,
        alu_function_modifier_second_o   ,
        fu_select_a_second_o             ,
        fu_select_b_second_o             ,
        jump_second_o                    ,
        branch_second_o                  ,
        is_alu_second_o                  ,
        load_second_o                    ,
        store_second_o                   ,
        ldu_op_second_o                  ,
        stu_op_second_o                  ,
        aq_second_o                      ,
        rl_second_o                      } = rdata_second;

endmodule

`endif  // DECODE_V
