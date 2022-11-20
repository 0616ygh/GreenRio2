module rvh_mmu_axi_wrapper #(
    parameter TRANS_ID_WIDTH = 3,
    parameter PADDR_WIDTH = 56,
    parameter EXCP_CAUSE_WIDTH = 64,
    parameter VPN_WIDTH = 27,
    parameter PMP_ENTRY_COUNT = 8,
    // AXI Config 
    parameter AXI_ID_WIDTH = 0,
    parameter AXI_ADDR_WIDTH = 64,
    parameter AXI_DATA_WIDTH = 512,
    // Local
    localparam PMPCFG_ENTRY_COUNT = PMP_ENTRY_COUNT / 8,
    localparam PMPADDR_ID_WIDTH = $clog2(PMP_ENTRY_COUNT),
    localparam PMPCFG_ID_WIDTH = PMPCFG_ENTRY_COUNT > 1 ? $clog2(PMPCFG_ENTRY_COUNT) : 1,
    localparam PAGE_LVL_WIDTH = $clog2(VPN_WIDTH / 9),
    localparam PPN_WIDTH = 44,
    localparam PTE_WIDTH = 64,
    localparam ASID_WIDTH = 16,
    localparam MODE_WIDTH = 4
) (
    // priv lvl
    input       [                 1:0] priv_lvl_i,
    // stap
    input       [                 3:0] satp_mode_i,
    input       [       PPN_WIDTH-1:0] satp_ppn_i,
    // PMP Configuration Port
    input                              pmp_cfg_set_vld_i,
    input       [ PMPCFG_ID_WIDTH-1:0] pmp_cfg_set_addr_i,
    input       [                63:0] pmp_cfg_set_payload_i,
    output      [                63:0] pmp_cfg_origin_payload_o,
    input                              pmp_addr_set_vld_i,
    input       [PMPADDR_ID_WIDTH-1:0] pmp_addr_set_addr_i,
    input       [                63:0] pmp_addr_set_payload_i,
    output      [                63:0] pmp_addr_origin_payload_o,
    // DTLB Miss -> To Next Level Request
    input                              dtlb_miss_req_vld_i,
    input       [  TRANS_ID_WIDTH-1:0] dtlb_miss_req_trans_id_i,
    input       [      ASID_WIDTH-1:0] dtlb_miss_req_asid_i,
    input       [       VPN_WIDTH-1:0] dtlb_miss_req_vpn_i,
    input       [                 1:0] dtlb_miss_req_access_type_i,
    output                             dtlb_miss_req_rdy_o,
    // DTLB Miss -> From Next Level Response
    output                             dtlb_miss_resp_vld_o,
    output      [  TRANS_ID_WIDTH-1:0] dtlb_miss_resp_trans_id_o,
    output      [      ASID_WIDTH-1:0] dtlb_miss_resp_asid_o,
    output      [       PTE_WIDTH-1:0] dtlb_miss_resp_pte_o,
    output      [  PAGE_LVL_WIDTH-1:0] dtlb_miss_resp_page_lvl_o,
    output      [       VPN_WIDTH-1:0] dtlb_miss_resp_vpn_o,
    output      [                 1:0] dtlb_miss_resp_access_type_o,
    output                             dtlb_miss_resp_access_fault_o,
    output                             dtlb_miss_resp_page_fault_o,
    // DTLB Entry Evict
    input                              dtlb_evict_vld_i,
    input       [       PTE_WIDTH-1:0] dtlb_evict_pte_i,
    input       [  PAGE_LVL_WIDTH-1:0] dtlb_evict_page_lvl_i,
    input       [       VPN_WIDTH-1:0] dtlb_evict_vpn_i,
    input       [      ASID_WIDTH-1:0] dtlb_evict_asid_i,
    // ITLB Miss -> To Next Level Request
    input                              itlb_miss_req_vld_i,
    input       [  TRANS_ID_WIDTH-1:0] itlb_miss_req_trans_id_i,
    input       [      ASID_WIDTH-1:0] itlb_miss_req_asid_i,
    input       [       VPN_WIDTH-1:0] itlb_miss_req_vpn_i,
    input       [                 1:0] itlb_miss_req_access_type_i,
    output                             itlb_miss_req_rdy_o,
    // ITLB Miss -> From Next Level Response
    output                             itlb_miss_resp_vld_o,
    output      [  TRANS_ID_WIDTH-1:0] itlb_miss_resp_trans_id_o,
    output      [      ASID_WIDTH-1:0] itlb_miss_resp_asid_o,
    output      [       PTE_WIDTH-1:0] itlb_miss_resp_pte_o,
    output      [  PAGE_LVL_WIDTH-1:0] itlb_miss_resp_page_lvl_o,
    output      [       VPN_WIDTH-1:0] itlb_miss_resp_vpn_o,
    output      [                 1:0] itlb_miss_resp_access_type_o,
    output                             itlb_miss_resp_access_fault_o,
    output                             itlb_miss_resp_page_fault_o,
    // ITLB Entry Evict
    input                              itlb_evict_vld_i,
    input       [       PTE_WIDTH-1:0] itlb_evict_pte_i,
    input       [  PAGE_LVL_WIDTH-1:0] itlb_evict_page_lvl_i,
    input       [       VPN_WIDTH-1:0] itlb_evict_vpn_i,
    input       [      ASID_WIDTH-1:0] itlb_evict_asid_i,
    //AW
    output wire [    AXI_ID_WIDTH-1:0] awid_o,
    output wire [  AXI_ADDR_WIDTH-1:0] awaddr_o,
    output wire [                 7:0] awlen_o,
    output wire [                 2:0] awsize_o,
    output wire [                 1:0] awburst_o,
    output wire                        awvalid_o,
    input  wire                        awready_i,
    //AR
    output wire [    AXI_ID_WIDTH-1:0] arid_o,
    output wire [  AXI_ADDR_WIDTH-1:0] araddr_o,
    output wire [                 7:0] arlen_o,
    output wire [                 2:0] arsize_o,
    output wire [                 1:0] arburst_o,
    output wire                        arvalid_o,
    input  wire                        arready_i,
    //W
    output wire [  AXI_DATA_WIDTH-1:0] wdata_o,
    output wire [                63:0] wstrb_o,
    output wire                        wlast_o,
    output wire                        wvalid_o,
    input  wire                        wready_i,
    //B
    input  wire [    AXI_ID_WIDTH-1:0] bid_i,
    input  wire [                 1:0] bresp_i,
    input  wire                        bvalid_i,
    output wire                        bready_o,
    //R
    input  wire [    AXI_ID_WIDTH-1:0] rid_i,
    input  wire [  AXI_DATA_WIDTH-1:0] rdata_i,
    input  wire [                 1:0] rresp_i,
    input  wire                        rlast_i,
    input  wire                        rvalid_i,
    output wire                        rready_o,

    // tlb shoot down
    input tlb_flush_vld_i,
    input tlb_flush_use_asid_i,
    input tlb_flush_use_vpn_i,
    input [VPN_WIDTH-1:0] tlb_flush_vpn_i,
    input [ASID_WIDTH-1:0] tlb_flush_asid_i,
    output tlb_flush_grant_o,
    input clk,
    input rstn
);

  wire ptw_walk_req_vld;
  wire [PADDR_WIDTH-1:0] ptw_walk_req_addr;
  wire ptw_walk_req_rdy;
  // ptw walk response port
  wire ptw_walk_resp_vld;
  wire [PTE_WIDTH-1:0] ptw_walk_resp_pte;
  wire ptw_walk_resp_rdy;

  // Ignore AW Channel
  assign awid_o = '0;
  assign awaddr_o = '0;
  assign awlen_o = '0;
  assign awsize_o = '0;
  assign awburst_o = '0;
  assign awvalid_o = '0;
  // Ignore W Channel
  assign wdata_o = '0;
  assign wstrb_o = '0;
  assign wlast_o = '0;
  assign wvalid_o = '0;
  // Ignore B Channel
  assign bready_o = '0;
  // AR
  assign arid_o = '0;
  assign araddr_o = ptw_walk_req_addr;
  assign arlen_o = '0;
  assign arsize_o = 3'b011;
  assign arburst_o = 2'b00;
  assign arvalid_o = ptw_walk_req_vld;
  assign ptw_walk_req_rdy = arready_i;
  // R
  assign ptw_walk_resp_vld = rvalid_i;
  assign ptw_walk_resp_pte = rdata_i[PTE_WIDTH-1:0];
  assign rready_o = ptw_walk_resp_rdy;


  rvh_mmu #(
      .TRANS_ID_WIDTH(TRANS_ID_WIDTH),
      .PADDR_WIDTH(PADDR_WIDTH),
      .EXCP_CAUSE_WIDTH(EXCP_CAUSE_WIDTH),
      .VPN_WIDTH(VPN_WIDTH),
      .PMP_ENTRY_COUNT(PMP_ENTRY_COUNT),
      .PMPCFG_ENTRY_COUNT(PMPCFG_ENTRY_COUNT),
      .PMPADDR_ID_WIDTH(PMPADDR_ID_WIDTH),
      .PMPCFG_ID_WIDTH(PMPCFG_ID_WIDTH),
      .PAGE_LVL_WIDTH(PAGE_LVL_WIDTH),
      .PPN_WIDTH(PPN_WIDTH),
      .PTE_WIDTH(PTE_WIDTH),
      .ASID_WIDTH(ASID_WIDTH),
      .MODE_WIDTH(MODE_WIDTH)
  ) u_rvh_mmu (
      .priv_lvl_i(priv_lvl_i),
      .pmp_cfg_set_vld_i(pmp_cfg_set_vld_i),
      .pmp_cfg_set_addr_i(pmp_cfg_set_addr_i),
      .pmp_cfg_set_payload_i(pmp_cfg_set_payload_i),
      .pmp_cfg_origin_payload_o(pmp_cfg_origin_payload_o),
      .pmp_addr_set_vld_i(pmp_addr_set_vld_i),
      .pmp_addr_set_addr_i(pmp_addr_set_addr_i),
      .pmp_addr_set_payload_i(pmp_addr_set_payload_i),
      .pmp_addr_origin_payload_o(pmp_addr_origin_payload_o),
      .satp_mode_i(satp_mode_i),
      .satp_ppn_i(satp_ppn_i),
      .dtlb_miss_req_vld_i(dtlb_miss_req_vld_i),
      .dtlb_miss_req_trans_id_i(dtlb_miss_req_trans_id_i),
      .dtlb_miss_req_asid_i(dtlb_miss_req_asid_i),
      .dtlb_miss_req_vpn_i(dtlb_miss_req_vpn_i),
      .dtlb_miss_req_access_type_i(dtlb_miss_req_access_type_i),
      .dtlb_miss_req_rdy_o(dtlb_miss_req_rdy_o),
      .dtlb_miss_resp_vld_o(dtlb_miss_resp_vld_o),
      .dtlb_miss_resp_trans_id_o(dtlb_miss_resp_trans_id_o),
      .dtlb_miss_resp_asid_o(dtlb_miss_resp_asid_o),
      .dtlb_miss_resp_pte_o(dtlb_miss_resp_pte_o),
      .dtlb_miss_resp_page_lvl_o(dtlb_miss_resp_page_lvl_o),
      .dtlb_miss_resp_vpn_o(dtlb_miss_resp_vpn_o),
      .dtlb_miss_resp_access_type_o(dtlb_miss_resp_access_type_o),
      .dtlb_miss_resp_access_fault_o(dtlb_miss_resp_access_fault_o),
      .dtlb_miss_resp_page_fault_o(dtlb_miss_resp_page_fault_o),
      .dtlb_evict_vld_i(dtlb_evict_vld_i),
      .dtlb_evict_pte_i(dtlb_evict_pte_i),
      .dtlb_evict_page_lvl_i(dtlb_evict_page_lvl_i),
      .dtlb_evict_vpn_i(dtlb_evict_vpn_i),
      .dtlb_evict_asid_i(dtlb_evict_asid_i),
      .itlb_miss_req_vld_i(itlb_miss_req_vld_i),
      .itlb_miss_req_trans_id_i(itlb_miss_req_trans_id_i),
      .itlb_miss_req_asid_i(itlb_miss_req_asid_i),
      .itlb_miss_req_vpn_i(itlb_miss_req_vpn_i),
      .itlb_miss_req_access_type_i(itlb_miss_req_access_type_i),
      .itlb_miss_req_rdy_o(itlb_miss_req_rdy_o),
      .itlb_miss_resp_vld_o(itlb_miss_resp_vld_o),
      .itlb_miss_resp_trans_id_o(itlb_miss_resp_trans_id_o),
      .itlb_miss_resp_asid_o(itlb_miss_resp_asid_o),
      .itlb_miss_resp_pte_o(itlb_miss_resp_pte_o),
      .itlb_miss_resp_page_lvl_o(itlb_miss_resp_page_lvl_o),
      .itlb_miss_resp_vpn_o(itlb_miss_resp_vpn_o),
      .itlb_miss_resp_access_type_o(itlb_miss_resp_access_type_o),
      .itlb_miss_resp_access_fault_o(itlb_miss_resp_access_fault_o),
      .itlb_miss_resp_page_fault_o(itlb_miss_resp_page_fault_o),
      .itlb_evict_vld_i(itlb_evict_vld_i),
      .itlb_evict_pte_i(itlb_evict_pte_i),
      .itlb_evict_page_lvl_i(itlb_evict_page_lvl_i),
      .itlb_evict_vpn_i(itlb_evict_vpn_i),
      .itlb_evict_asid_i(itlb_evict_asid_i),
      .ptw_walk_req_vld_o(ptw_walk_req_vld),
      .ptw_walk_req_addr_o(ptw_walk_req_addr),
      .ptw_walk_req_rdy_i(ptw_walk_req_rdy),
      .ptw_walk_resp_vld_i(ptw_walk_resp_vld),
      .ptw_walk_resp_pte_i(ptw_walk_resp_pte),
      .ptw_walk_resp_rdy_o(ptw_walk_resp_rdy),
      .tlb_flush_vld_i(tlb_flush_vld_i),
      .tlb_flush_use_asid_i(tlb_flush_use_asid_i),
      .tlb_flush_use_vpn_i(tlb_flush_use_vpn_i),
      .tlb_flush_vpn_i(tlb_flush_vpn_i),
      .tlb_flush_asid_i(tlb_flush_asid_i),
      .tlb_flush_grant_o(tlb_flush_grant_o),
      .clk(clk),
      .rstn(rstn)
  );

endmodule
