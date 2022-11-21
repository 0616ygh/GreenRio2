/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
`ifndef _LSU_AGU_V_
`define _LSU_AGU_V_
`ifdef VERILATOR
`include "params.vh"
`endif

module lsu_agu(
    input clk, 
    input [XLEN - 1 : 0] agu_base_i,
    input [XLEN - 1 : 0] agu_offset_i,

    output [VIRTUAL_ADDR_LEN - 1 : 0] agu_addr_o
);
    assign agu_addr_o = agu_base_i[VIRTUAL_ADDR_LEN - 1 : 0] + agu_offset_i[VIRTUAL_ADDR_LEN - 1 : 0];

endmodule

`endif // _LSU_AGU_V_
