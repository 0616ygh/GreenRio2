// | msg type class | msg type           | description                                                                                                                                                    |
// | -------------- | ------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
// | scu snoop req  | SnpShared          | Snoop request to obtain a copy of the cache line in Shared state while leaving any cached copy in Shared state. Must not leave the cache line in Unique state. |
// |                | SnpUnique          | Snoop request to obtain a copy of the cache line in Unique state while invalidating any cached copies. Must change the cache line to Invalid state.            |
// |                | SnpCleanInvalid    | Snoop request to Invalidate the cache line at the Snoopee and obtain any Dirty copy, used in SF eviction.                                                      |
`ifdef USE_VERILATOR
`include "./include/riscv_pkg.sv"
`include "./include/rvh_pkg.sv"
`include "./include/rvh_l1d_pkg.sv"
`include "./include/uop_encoding_pkg.sv"
`endif //USE_VERILATOR
/* verilator lint_off PINCONNECTEMPTY */

module rvh_l1d_snp_dec
   import rvh_l1d_pkg::*;
#(
)
(
  input  cache_mem_if_ac_t  snp_req_if_ac_i,
  output snp_req_buf_t      snp_req_buf_entry_o
);

  assign snp_req_buf_entry_o.snp_line_addr = snp_req_if_ac_i.acaddr;

  always_comb begin
    unique case (snp_req_if_ac_i.acsoop)
      ReadNotSharedDirty: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b0;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b1;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b1;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      end
      ReadUnique: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b1;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b0;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b1;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      end
      CleanInvalid: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b1;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b0;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b0;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      end
      default: begin
        snp_req_buf_entry_o.snp_leave_invalid     = 1'b0;
        snp_req_buf_entry_o.snp_leave_sharedclean = 1'b1;
        snp_req_buf_entry_o.snp_return_clean_data = 1'b1;
        snp_req_buf_entry_o.snp_return_dirty_data = 1'b1;
      end
    endcase
  end

endmodule
/* verilator lint_on PINCONNECTEMPTY */
