
`ifndef _LSU_MC_V_
`define _LSU_MC_V_
`ifdef VERILATOR
`include "params.vh"
`endif
/* verilator lint_off UNUSED */
module lsu_mc (
    input                                       rcu_ac_valid_i,
    input                                       rcu_ac_ls_i,
    input  [LS_OPCODE_WIDTH - 1 : 0]            rcu_ac_opcode_i,
    input  [VIRTUAL_ADDR_LEN - 1 : 0]           agu_ac_addr_i,

    output [EXCEPTION_CAUSE_WIDTH - 1 : 0]      ac_ecause_o,
    output                                      ac_exception_vld_o
);
    wire ac_misalign_fault;
    wire ac_access_fault;
    
    assign ac_misalign_fault = 
        rcu_ac_ls_i ? // store
            (rcu_ac_opcode_i == STU_SH && agu_ac_addr_i[0] != 0) || // hw
            ((rcu_ac_opcode_i == STU_SW || rcu_ac_opcode_i == STU_AMOSWAPW || rcu_ac_opcode_i == STU_AMOADDW || 
                rcu_ac_opcode_i == STU_AMOANDW || rcu_ac_opcode_i == STU_AMOORW || rcu_ac_opcode_i == STU_AMOXORW ||
                rcu_ac_opcode_i == STU_AMOMAXW || rcu_ac_opcode_i == STU_AMOMAXUW || rcu_ac_opcode_i == STU_AMOMINW ||
                rcu_ac_opcode_i == STU_AMOMINUW || rcu_ac_opcode_i == STU_SCW || rcu_ac_opcode_i == STU_LRW
            )  & agu_ac_addr_i[1:0] != 0) || // w
            ((rcu_ac_opcode_i == STU_SD || rcu_ac_opcode_i == STU_AMOSWAPD || rcu_ac_opcode_i == STU_AMOADDD || 
                rcu_ac_opcode_i == STU_AMOANDD || rcu_ac_opcode_i == STU_AMOORD || rcu_ac_opcode_i == STU_AMOXORD ||
                rcu_ac_opcode_i == STU_AMOMAXD || rcu_ac_opcode_i == STU_AMOMAXUD || rcu_ac_opcode_i == STU_AMOMIND ||
                rcu_ac_opcode_i == STU_AMOMINUD || rcu_ac_opcode_i == STU_SCD || rcu_ac_opcode_i == STU_LRD
            )  & agu_ac_addr_i[2:0] != 0) // d
        : // load
            ((rcu_ac_opcode_i == LDU_LH || rcu_ac_opcode_i == LDU_LHU) 
            && agu_ac_addr_i[0] != 0) || // hw
            ((rcu_ac_opcode_i == LDU_LW || rcu_ac_opcode_i == LDU_LWU) 
            && agu_ac_addr_i[1:0] != 0) || // w
            ((rcu_ac_opcode_i == LDU_LD) 
            && agu_ac_addr_i[2:0] != 0) // dw
        ;

    assign ac_ecause_o = 
        ac_misalign_fault ? (rcu_ac_ls_i ? EXCEPTION_STORE_ADDR_MISALIGNED : EXCEPTION_LOAD_ADDR_MISALIGNED) :
        0; 
    assign ac_exception_vld_o = rcu_ac_valid_i & ac_misalign_fault;
endmodule
/* verilator lint_on UNUSED */
`endif // _LSU_MC_V_
