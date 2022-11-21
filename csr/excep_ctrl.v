`ifdef VERILATOR
`include "params.vh"
`endif
module excep_ctrl (
    //from rcu
    input rob_do_cmt_valid_i,
    input rob_do_cmt_second_valid_i,
    input [PC_WIDTH-1:0] rob_cmt_pc_i,
    input rob_cmt_mret_i,
    input rob_cmt_sret_i,
    input rob_cmt_wfi_i,
    input predict_miss_i,
    input [EXCEPTION_CAUSE_WIDTH - 1:0] rob_cmt_ecause_i,
    input rob_cmt_exp_i,

    input interrupt_i,

    // control pipeline signal
    output global_trap_o,
    output global_predict_miss_o,
    output global_ret_o,
    output global_wfi_o,

    // to csr
    output [PC_WIDTH-1:0] csr_pc_o,
    output [EXCEPTION_CAUSE_WIDTH-1:0] csr_ecause_o,
    // output [1:0] csr_retired_o,
    output global_mret_o,
    output global_sret_o
);

wire exception = rob_cmt_exp_i & rob_do_cmt_valid_i;

assign global_predict_miss_o = predict_miss_i;
assign global_trap_o = exception | interrupt_i;
assign csr_pc_o = rob_cmt_wfi_i ? (rob_cmt_pc_i + 4) : rob_cmt_pc_i;
// assign global_wfi_o = rob_do_cmt_valid_i & rob_cmt_wfi_i;
assign global_wfi_o = 0;

wire retire_first = rob_do_cmt_valid_i & !global_trap_o & !global_wfi_o;
wire retire_second = rob_do_cmt_second_valid_i & !global_trap_o & !global_wfi_o;
assign csr_retired_o = {retire_second, retire_first};

assign global_mret_o = rob_do_cmt_valid_i & rob_cmt_mret_i;
assign global_sret_o = rob_do_cmt_valid_i & rob_cmt_sret_i;
assign global_ret_o = rob_do_cmt_valid_i & (rob_cmt_mret_i | rob_cmt_sret_i);

assign csr_ecause_o = rob_cmt_ecause_i;

endmodule
