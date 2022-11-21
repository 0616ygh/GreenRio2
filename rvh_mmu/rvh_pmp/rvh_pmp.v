`ifdef VERILATOR
`include "params.vh"
`endif
module rvh_pmp #(
    parameter PMP_ENTRY_COUNT = 64,
    parameter PMPCFG_ENTRY_COUNT = 8,
    parameter PADDR_WIDTH = 56,
    parameter PMPADDR_ID_WIDTH = $clog2(PMP_ENTRY_COUNT),
    parameter PMPCFG_ID_WIDTH = $clog2(PMPCFG_ENTRY_COUNT),
    parameter INPUT_REGISTER = 0
) (
    // Priv level
    input [1:0] priv_lvl_i,
    // PMP Configuration Port
    input cfg_set_vld_i,
    input [PMPCFG_ID_WIDTH-1:0] cfg_set_addr_i,
    input [63:0] cfg_set_payload_i,
    output [63:0] cfg_origin_payload_o,
    input addr_set_vld_i,
    input [PMPADDR_ID_WIDTH-1:0] addr_set_addr_i,
    input [63:0] addr_set_payload_i,
    output [63:0] addr_origin_payload_o,
    // Permission Check Port
    input permission_check_vld_i,
    input [PADDR_WIDTH-1:0] permission_check_paddr_i,
    input [1:0] permission_check_access_type_i,
    output permission_check_fail_o,

    input clk,
    input rstn
);

  localparam PRIV_LVL_M = 3;
  localparam PRIV_LVL_S = 1;
  localparam PRIV_LVL_U = 0;

  genvar macro;

  wire [PMP_ENTRY_COUNT-1:0][63:0] pmpaddr;
  wire [PMPCFG_ENTRY_COUNT-1:0][63:0] pmpcfg;

  wire permission_check_vld;
  wire [PADDR_WIDTH-1:0] permission_check_paddr;
  wire [1:0] permission_check_access_type;


  wire [PMP_ENTRY_COUNT-1:0] pmpcfg_entry_set_vld;
  wire [PMP_ENTRY_COUNT-1:0] pmpaddr_entry_set_vld;

  wire [PMP_ENTRY_COUNT-1:0] pmp_entry_lock_formmer_entry;
  wire [PMP_ENTRY_COUNT-1:0] pmp_entry_lock_from_latter_entry;
  wire [PMP_ENTRY_COUNT-1:0][PADDR_WIDTH-1:2] pmp_entry_formmer_entry_addr;

  wire [PMP_ENTRY_COUNT-1:0] pmp_entry_range_match;
  wire [PMP_ENTRY_COUNT-1:0] pmp_entry_check_fail;

  generate
    if (INPUT_REGISTER) begin : gen_input_register
      wire permission_check_payload_clk_en;
      wire permission_check_vld_d;
      wire [PADDR_WIDTH-1:0] permission_check_paddr_d;
      wire [1:0] permission_check_access_type_d;
      reg permission_check_vld_q;
      reg [PADDR_WIDTH-1:0] permission_check_paddr_q;
      reg [1:0] permission_check_access_type_q;

      assign permission_check_payload_clk_en = permission_check_vld_i;
      assign permission_check_vld_d = permission_check_vld_i;
      assign permission_check_paddr_d = permission_check_paddr_i;
      assign permission_check_access_type_d = permission_check_access_type_i;

      assign permission_check_vld = permission_check_vld_q;
      assign permission_check_paddr = permission_check_paddr_q;
      assign permission_check_access_type = permission_check_access_type_q;
      DFFRE #(
          .Width(1)
      ) u_pmp_check_input_vld_DFFR (
          .CLK(clk),
          .RSTN(rstn),
          .DRST(1'b0),
          .EN(1'b1),
          .D(permission_check_vld_d),
          .Q(permission_check_vld_q)
      );

      DFFE #(
          .Width($bits(permission_check_paddr_q) + $bits(permission_check_access_type_q))
      ) u_pmp_check_input_payload_DFFE (
          .CLK(clk),
          .EN (permission_check_payload_clk_en),
          .D  ({permission_check_paddr_d, permission_check_access_type_d}),
          .Q  ({permission_check_paddr_q, permission_check_access_type_q})
      );
    end else begin : gen_other

      assign permission_check_vld = permission_check_vld_i;
      assign permission_check_paddr = permission_check_paddr_i;
      assign permission_check_access_type = permission_check_access_type_i;

    end
  endgenerate


  assign cfg_origin_payload_o = pmpcfg[cfg_set_addr_i];
  assign addr_origin_payload_o = pmpaddr[addr_set_addr_i];


  assign permission_check_fail_o = (|pmp_entry_check_fail) |
    ((&(~pmp_entry_range_match)) & (priv_lvl_i != PRIV_LVL_M));

  generate
    for (macro = 0; macro < PMP_ENTRY_COUNT; macro = macro + 1) begin : gen_pmp_entry

      assign pmpcfg_entry_set_vld[macro]  = cfg_set_vld_i & (cfg_set_addr_i == (macro >> 3));
      assign pmpaddr_entry_set_vld[macro] = addr_set_vld_i & (addr_set_addr_i == macro[PMPADDR_ID_WIDTH-1:0]);
      // assign pmpcfg_entry_set_vld[macro]  = cfg_set_vld_i & (cfg_set_addr_i == macro[PMPCFG_ID_WIDTH-1:0]);
      // assign pmpaddr_entry_set_vld[macro] = addr_set_vld_i & (addr_set_addr_i == (macro >> 3));

      if (macro == PMP_ENTRY_COUNT - 1) begin : gen_last_one
        assign pmp_entry_lock_from_latter_entry[macro] = 1'b0;
      end else begin : gen_others
        assign pmp_entry_lock_from_latter_entry[macro] = pmp_entry_lock_formmer_entry[macro+1];
      end

      if (macro == 0) begin : gen_first_one
        assign pmp_entry_formmer_entry_addr[macro] = {PADDR_WIDTH - 2{1'b0}};
      end else begin : gen_other
        assign pmp_entry_formmer_entry_addr[macro] = pmpaddr[macro-1][PADDR_WIDTH-1:2];
      end

      rvh_pmp_entry #(
          .PADDR_WIDTH(PADDR_WIDTH)
      ) u_rvh_pmp_entry (
          .cfg_set_vld_i(pmpcfg_entry_set_vld[macro]),
          .cfg_set_payload_i(cfg_set_payload_i[(macro%8+1)*8-1:(macro%8)*8]),
          .addr_set_vld_i(pmpaddr_entry_set_vld[macro]),
          .addr_set_payload_i(addr_set_payload_i),
          .pmpaddr_o(pmpaddr[macro]),
          .pmpcfg_o(pmpcfg[macro/8][(macro%8+1)*8-1:(macro%8)*8]),
          .lock_formmer_entry_o(pmp_entry_lock_formmer_entry[macro]),
          .lock_from_latter_entry_i(pmp_entry_lock_from_latter_entry[macro]),
          .formmer_entry_addr_i(pmp_entry_formmer_entry_addr[macro]),
          .permission_check_vld_i(permission_check_vld),
          .permission_check_paddr_i(permission_check_paddr),
          .permission_check_access_type_i(permission_check_access_type),
          .permission_check_entry_match_o(pmp_entry_range_match[macro]),
          .permission_check_fail_o(pmp_entry_check_fail[macro]),
          .clk(clk),
          .rstn(rstn)
      );

    end
  endgenerate



endmodule
