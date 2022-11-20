module rvh_ptw #(
    parameter TRANS_ID_WIDTH = 3,
    parameter PADDR_WIDTH = 56,
    parameter EXCP_CAUSE_WIDTH = 64,
    parameter VPN_WIDTH = 27,
    parameter ASID_WIDTH = 16,
    parameter PMP_ENTRY_COUNT = 8
    // localparam PMPCFG_ENTRY_COUNT = PMP_ENTRY_COUNT / 8,
    // localparam PMPADDR_ID_WIDTH = $clog2(PMP_ENTRY_COUNT),
    // localparam PMPCFG_ID_WIDTH = PMPCFG_ENTRY_COUNT > 1 ? $clog2(PMPCFG_ENTRY_COUNT) : 1,
    // localparam PAGE_LVL_WIDTH = $clog2(VPN_WIDTH / 9),
    // localparam PPN_WIDTH = 44,
    // localparam PTE_WIDTH = 64
) (
    // priv lvl
    input [1:0] priv_lvl_i,
    // PMP Configuration Port
    input pmp_cfg_set_vld_i,
    input [PMPCFG_ID_WIDTH-1:0] pmp_cfg_set_addr_i,
    input [63:0] pmp_cfg_set_payload_i,
    output [63:0] pmp_cfg_origin_payload_o,
    input pmp_addr_set_vld_i,
    input [PMPADDR_ID_WIDTH-1:0] pmp_addr_set_addr_i,
    input [63:0] pmp_addr_set_payload_i,
    output [63:0] pmp_addr_origin_payload_o,
    // stap
    input [3:0] satp_mode_i,
    input [PPN_WIDTH-1:0] satp_ppn_i,
    // translate request port
    input translate_req_vld_i,
    input [TRANS_ID_WIDTH-1:0] translate_req_trans_id_i,
    input [ASID_WIDTH-1:0] translate_req_asid_i,
    input [VPN_WIDTH-1:0] translate_req_vpn_i,
    input [1:0] translate_req_access_type_i,
    output translate_req_rdy_o,
    // translate response port
    output translate_resp_vld_o,
    output [ASID_WIDTH-1:0] translate_resp_asid_o,
    output [PTE_WIDTH-1:0] translate_resp_pte_o,
    output [PAGE_LVL_WIDTH-1:0] translate_resp_page_lvl_o,
    output [TRANS_ID_WIDTH-1:0] translate_resp_trans_id_o,
    output [VPN_WIDTH-1:0] translate_resp_vpn_o,
    output [1:0] translate_resp_access_type_o,
    output translate_resp_access_fault_o,
    output translate_resp_page_fault_o,
    // ptw walk request port
    output ptw_walk_req_vld_o,
    output [PADDR_WIDTH-1:0] ptw_walk_req_addr_o,
    input ptw_walk_req_rdy_i,
    // ptw walk response port
    input ptw_walk_resp_vld_i,
    input [PTE_WIDTH-1:0] ptw_walk_resp_pte_i,
    output ptw_walk_resp_rdy_o,

    input clk,
    input rstn
);

  // Exception Cause

  // Mode
  localparam MODE_BARE = 0;
  localparam MODE_SV39 = 8;
  localparam MODE_SV48 = 9;
  localparam MODE_SV57 = 10;

  // Sv39
  localparam SV39_LEVELS = 3;
  // Sv48
  localparam SV48_LEVELS = 4;
  // Sv57
  localparam SV57_LEVELS = 5;

  localparam PAGESIZE = 2 ** 12;
  localparam PTESIZE = 8;

  // PTW FSM
  localparam PTW_STATE_WIDTH = 2;
  localparam PTW_STATE_IDLE = 2'b00;
  localparam PTW_STATE_CHECK_PERMISSION = 2'b01;
  localparam PTW_STATE_INFLIGHT = 2'b11;

  reg [PAGE_LVL_WIDTH-1:0] highest_page_lvl;

  wire [PTW_STATE_WIDTH-1:0] ptw_state_d;
  reg [PTW_STATE_WIDTH-1:0] ptw_state_q;
  wire idle2checkpermission;
  wire checkpermission2inflight;
  wire checkpermission2idle;
  wire inflight2idle;
  wire inflight2checkpermission;

  wire [PPN_WIDTH-1:0] walking_page_root;
  wire [8:0] walking_page_offset;
  wire walking_payload_clk_en;
  wire [PAGE_LVL_WIDTH-1:0] walking_lvl_d;
  wire [PADDR_WIDTH-1:0] walking_paddr_d;
  reg [PAGE_LVL_WIDTH-1:0] walking_lvl_q;
  reg [PADDR_WIDTH-1:0] walking_paddr_q;

  // Start Walking
  wire translate_req_fire;
  wire [ASID_WIDTH-1:0] translate_req_asid_d;
  wire [VPN_WIDTH-1:0] translate_req_vpn_d;
  wire [TRANS_ID_WIDTH-1:0] translate_req_trans_id_d;
  wire [1:0] translate_req_access_type_d;
  reg [ASID_WIDTH-1:0] translate_req_asid_q;
  reg [VPN_WIDTH-1:0] translate_req_vpn_q;
  reg [TRANS_ID_WIDTH-1:0] translate_req_trans_id_q;
  reg [1:0] translate_req_access_type_q;

  // Check Permission
  wire permission_check_vld;
  wire [PADDR_WIDTH-1:0] permission_check_paddr;
  wire [1:0] permission_check_access_type;
  wire permission_check_fail;
  wire permission_check_pass;

  // Walk Response
  wire walk_response_fire;
  wire [63:63] PTE_N;
  wire [62:61] PTE_PBMT;
  wire [60:54] PTE_Reserved;
  wire [53:10] PTE_PPN;
  wire [9:8] PTE_RSW;
  wire [7:7] PTE_D;
  wire [6:6] PTE_A;
  wire [5:5] PTW_G;
  wire [4:4] PTE_U;
  wire [3:3] PTE_X;
  wire [2:2] PTE_W;
  wire [1:1] PTE_R;
  wire [0:0] PTE_V;
  wire raise_pagefault;
  wire found_page_leaf;
  wire check_legal_fail;
  wire check_legal_pass;
  wire walk_to_next_lvl;
  wire check_overflow_fail;
  wire check_overflow_pass;

  // assign highest_page_lvl = ({PAGE_LVL_WIDTH{(satp_mode_i == MODE_SV39)}} & SV39_LEVELS) | 
  //   ({PAGE_LVL_WIDTH{(satp_mode_i == MODE_SV48)}} & SV48_LEVELS) | 
  //   ({PAGE_LVL_WIDTH{(satp_mode_i == MODE_SV57)}} & SV57_LEVELS);
  assign highest_page_lvl = 3;

  // State Transfer
  assign idle2checkpermission = (ptw_state_q == PTW_STATE_IDLE) & translate_req_fire;
  assign checkpermission2inflight = (ptw_state_q == PTW_STATE_CHECK_PERMISSION) &
    (ptw_walk_req_vld_o & ptw_walk_req_rdy_i);
  assign checkpermission2idle = (ptw_state_q == PTW_STATE_CHECK_PERMISSION) & permission_check_fail;
  assign inflight2checkpermission = (ptw_state_q == PTW_STATE_INFLIGHT) &
    (walk_response_fire & walk_to_next_lvl & check_overflow_pass);
  assign inflight2idle = (ptw_state_q == PTW_STATE_INFLIGHT) &
    (walk_response_fire & (found_page_leaf | raise_pagefault));

  assign ptw_state_d = (idle2checkpermission | inflight2checkpermission) ? PTW_STATE_CHECK_PERMISSION : 
    checkpermission2inflight ? PTW_STATE_INFLIGHT :
    (checkpermission2idle | inflight2idle) ? PTW_STATE_IDLE :
    ptw_state_q;

  assign walking_page_root = idle2checkpermission ? satp_ppn_i : PTE_PPN;
  assign walking_page_offset = idle2checkpermission ? translate_req_vpn_i[walking_lvl_d*9 +: 9] :
    translate_req_vpn_q[walking_lvl_d*9 +: 9];
  assign walking_payload_clk_en = idle2checkpermission | inflight2checkpermission;
  assign walking_lvl_d = idle2checkpermission ? (highest_page_lvl - 1'b1) : (walking_lvl_q - 1'b1);
  assign walking_paddr_d = walking_page_root * PAGESIZE + walking_page_offset * PTESIZE;

  // Start Walking
  assign translate_req_rdy_o = ptw_state_q == PTW_STATE_IDLE;
  assign translate_req_fire = translate_req_vld_i & translate_req_rdy_o;
  assign translate_req_vpn_d = translate_req_vpn_i;
  assign translate_req_trans_id_d = translate_req_trans_id_i;
  assign translate_req_access_type_d = translate_req_access_type_i;
  assign translate_req_asid_d = translate_req_asid_i;

  // Check Permission
  assign permission_check_vld = ptw_state_q == PTW_STATE_CHECK_PERMISSION;
  assign permission_check_access_type = translate_req_access_type_q;
  assign permission_check_paddr = walking_paddr_q;
  assign permission_check_pass = ~permission_check_fail;

  // Inflight
  assign ptw_walk_req_vld_o = (ptw_state_q == PTW_STATE_CHECK_PERMISSION) & permission_check_pass;
  assign ptw_walk_req_addr_o = walking_paddr_q;

  // Walk response
  assign ptw_walk_resp_rdy_o = 1'b1;
  assign walk_response_fire = ptw_walk_resp_vld_i & ptw_walk_resp_rdy_o;
  assign {PTE_N,PTE_PBMT,PTE_Reserved,PTE_PPN,PTE_RSW,PTE_D,PTE_A,
    PTW_G,PTE_U,PTE_X,PTE_W,PTE_R,PTE_V} = ptw_walk_resp_pte_i;
  assign raise_pagefault = check_legal_fail | check_overflow_fail;
  assign check_legal_fail = ~PTE_V | (~PTE_R & PTE_W) | (PTE_N != 1'b0) | (PTE_PBMT != 2'b0) | 
    (PTE_Reserved != 7'b0) | (PTE_RSW != 2'b0);
  assign check_legal_pass = ~check_legal_fail;
  assign found_page_leaf = check_legal_pass & (PTE_R | PTE_X);
  assign walk_to_next_lvl = check_legal_pass & ~found_page_leaf;
  assign check_overflow_fail = walk_to_next_lvl & (walking_lvl_q == 0);
  assign check_overflow_pass = ~check_overflow_fail;

  // Translate Response
  assign translate_resp_vld_o = checkpermission2idle | inflight2idle;
  assign translate_resp_pte_o = ptw_walk_resp_pte_i;
  assign translate_resp_page_lvl_o = walking_lvl_q;
  assign translate_resp_asid_o = translate_req_asid_q;
  assign translate_resp_trans_id_o = translate_req_trans_id_q;
  assign translate_resp_vpn_o = translate_req_vpn_q;
  assign translate_resp_access_type_o = translate_req_access_type_q;
  assign translate_resp_access_fault_o = checkpermission2idle;
  assign translate_resp_page_fault_o = (inflight2idle & raise_pagefault);

  DFFE #(
      .Width($bits(walking_lvl_q) + $bits(walking_paddr_q))
  ) u_walking_payload_DFFE (
      .CLK(clk),
      .EN (walking_payload_clk_en),
      .D  ({walking_lvl_d, walking_paddr_d}),
      .Q  ({walking_lvl_q, walking_paddr_q})
  );

  DFFE #(
      .Width($bits(
          translate_req_vpn_q
      ) + $bits(
          translate_req_trans_id_q
      ) + $bits(
          translate_req_access_type_q
      ) + $bits(
          translate_req_asid_q
      ))
  ) u_tranlate_payload_DFFE (
      .CLK(clk),
      .EN(idle2checkpermission),
      .D({
        translate_req_vpn_d,
        translate_req_trans_id_d,
        translate_req_access_type_d,
        translate_req_asid_d
      }),
      .Q({
        translate_req_vpn_q,
        translate_req_trans_id_q,
        translate_req_access_type_q,
        translate_req_asid_q
      })
  );
  DFFRE #(
      .Width(PTW_STATE_WIDTH)
  ) u_ptw_fsm_DFFR (
      .CLK(clk),
      .RSTN(rstn),
      .DRST(PTW_STATE_IDLE),
      .EN(1'b1),
      .D(ptw_state_d),
      .Q(ptw_state_q)
  );
`ifndef DISABLE_PMP
  rvh_pmp #(
      .PMP_ENTRY_COUNT(PMP_ENTRY_COUNT),
      .PMPCFG_ENTRY_COUNT(PMPCFG_ENTRY_COUNT),
      .PADDR_WIDTH(PADDR_WIDTH),
      .PMPADDR_ID_WIDTH(PMPADDR_ID_WIDTH),
      .PMPCFG_ID_WIDTH(PMPCFG_ID_WIDTH),
      .INPUT_REGISTER(0)
  ) u_rvh_pmp (
      .priv_lvl_i(priv_lvl_i),
      .cfg_set_vld_i(pmp_cfg_set_vld_i),
      .cfg_set_addr_i(pmp_cfg_set_addr_i),
      .cfg_set_payload_i(pmp_cfg_set_payload_i),
      .cfg_origin_payload_o(pmp_cfg_origin_payload_o),
      .addr_set_vld_i(pmp_addr_set_vld_i),
      .addr_set_addr_i(pmp_addr_set_addr_i),
      .addr_set_payload_i(pmp_addr_set_payload_i),
      .addr_origin_payload_o(pmp_addr_origin_payload_o),
      .permission_check_vld_i(permission_check_vld),
      .permission_check_paddr_i(permission_check_paddr),
      .permission_check_access_type_i(permission_check_access_type),
      .permission_check_fail_o(permission_check_fail),
      .clk(clk),
      .rstn(rstn)
  );
`else // DISABLE_PMP
  assign permission_check_fail = 0;
  assign pmp_cfg_origin_payload_o = '0;
  assign pmp_addr_origin_payload_o = '0;
`endif // DISABLE_PMP

endmodule
