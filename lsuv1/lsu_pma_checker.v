/////////////////////////
// Author: Peichen Guo //
//    RIOS Lab work    //
//      HeHe Core      //
/////////////////////////
// lsu router
`ifndef _LSU_PMA_CHECKER_V_
`define _LSU_PMA_CHECKER_V_
`ifdef VERILATOR
`include "params.vh"
`endif
module lsu_pma_checker(
    input                                   clk, 
    input                                   rst, 
    input                                   flush,
    
    input                                   lsq_lr_st_vld_i,
    input  [PHYSICAL_ADDR_LEN - 1 : 0]      lsq_lr_st_paddr_i,
    input                                   lsq_lr_ld_vld_i,  
    input                                   lsq_lr_ld_dtlb_hit_i,                            
    input  [PHYSICAL_ADDR_LEN - 1 : 0]      lsq_lr_ld_paddr_i,

    output                                  lr_lsq_is_io_o
);    

reg st_vld_q;
reg st_is_io_q;
reg ld_vld_q;

wire st_is_io_d;
wire ld_is_io;
/* verilator lint_off UNSIGNED */
assign st_is_io_d = (IO_ADDR_LOW <= lsq_lr_st_paddr_i) && (lsq_lr_st_paddr_i < IO_ADDR_UPP);
assign ld_is_io = (IO_ADDR_LOW <= lsq_lr_ld_paddr_i) && (lsq_lr_ld_paddr_i < IO_ADDR_UPP);
/* verilator lint_on UNSIGNED */
assign lr_lsq_is_io_o = st_vld_q ? st_is_io_q : ld_vld_q & lsq_lr_ld_dtlb_hit_i & ld_is_io;

always @(posedge clk) begin
    if(rst | flush) begin
        st_vld_q <= 0;
        st_is_io_q <= 0;
        ld_vld_q <= 0;
    end 
    else begin
        st_vld_q <= lsq_lr_st_vld_i;
        st_is_io_q <= st_is_io_d;
        ld_vld_q <= lsq_lr_ld_vld_i;
    end
end

endmodule

`endif // _LSU_PMA_CHECKER_V_
