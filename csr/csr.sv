//`include "../params.vh"
`ifdef VERILATOR
`include "params.vh"
`endif

module csr (
    input clk,
    input rst,

    //from rcu
    input [ROB_INDEX_WIDTH-1:0] rob_index_i,
    input [PHY_REG_ADDR_WIDTH-1:0] prd_addr_i,
    input [2:0] func3_i,
    input [XLEN-1:0] prs1_data_i,
    input [IMM_LEN-1:0] imm_i,
    input [CSR_ADDR_LEN-1:0] csr_addr_i,
    input csr_do_read_i,
    input csr_do_write_i,
    
    //hand shake
    input wire rcu_csr_req_valid_i,

    //csr read
    output [CSR_ADDR_LEN-1:0] csr_raddr_o,
    input [XLEN-1:0] csr_rdata_i,
    input csr_readable_i,
    input csr_writable_i,
    
    //csr write
    output [CSR_ADDR_LEN-1:0] csr_waddr_o,
    output do_csr_write_o,
    output [XLEN-1:0] csr_wrdata_o,

    //rcu wrb
    output csr_rcu_resp_valid_o,
    output [ROB_INDEX_WIDTH-1:0] csr_rcu_wrb_rob_index_o,
    output [PHY_REG_ADDR_WIDTH-1:0] csr_rcu_wrb_addr_o,
    output [XLEN-1:0] csr_rcu_wrb_data_o,
    output csr_exception_o,
    output [EXCEPTION_CAUSE_WIDTH-1:0] csr_ecause_o,

    //pmp
    output pmp_cfg_vld_o,
    output [PMPCFG_ID_WIDTH-1:0] pmp_cfg_addr_o,
    output [XLEN-1:0] pmp_cfg_payload_o,
    input  [XLEN-1:0] pmp_cfg_origin_payload_i,
    output pmp_addr_vld_o,
    output [PMPADDR_ID_WIDTH-1:0] pmp_addr_addr_o,
    output [XLEN-1:0] pmp_addr_payload_o,
    input  [XLEN-1:0] pmp_addr_origin_payload_i
    );

    reg [XLEN-1:0] csr_wr_data;
    reg illegal_csr;
    reg [EXCEPTION_CAUSE_WIDTH - 1 : 0] illegal_ecause;
    reg [XLEN - 1 : 0] imm_64;
    //PMP arbiter
    wire is_pmp, is_pmpcfg;
    reg [XLEN-1:0] csr_op_data_in;
    wire [CSR_ADDR_LEN- 1: 0] pmpaddr_base;
    assign is_pmpcfg = csr_addr_i[CSR_ADDR_LEN-1:4] == 8'h3A;
    assign is_pmp = csr_addr_i >= 12'h3B0 && csr_addr_i <= 12'h3EF;
    assign pmpaddr_base = csr_addr_i - 12'h3B0;

always @(*) begin
    if (is_pmpcfg) begin
        csr_op_data_in = pmp_cfg_origin_payload_i;
    end else if (is_pmp) begin
        csr_op_data_in = pmp_addr_origin_payload_i;
    end else begin
        csr_op_data_in = csr_rdata_i;
    end
end

always @(*) begin
    illegal_csr = 0;
    illegal_ecause = 0;
    csr_wr_data = csr_op_data_in;
    imm_64 = {{XLEN_M_IMMLEN{1'b0}}, imm_i};
    if (rcu_csr_req_valid_i) begin
        if ((csr_do_read_i & ~csr_readable_i) | (csr_do_write_i & ~csr_writable_i)) begin
            illegal_csr = 1;
            illegal_ecause = 2;
        end else begin	// CSR instructions
        case (func3_i)
            3'b001:
                csr_wr_data = prs1_data_i;
            3'b010:
                csr_wr_data = csr_op_data_in | prs1_data_i;
            3'b011:
                csr_wr_data = csr_op_data_in & ~prs1_data_i;
            3'b101:
                csr_wr_data = imm_64;
            3'b110:
                csr_wr_data = csr_op_data_in | imm_64;
            3'b111:
                csr_wr_data = csr_op_data_in & ~imm_64;
            default:
                csr_wr_data = csr_op_data_in;
        endcase
        end
    end
end

`ifdef COSIM

// import "DPI-C" function void csr_monitor(
//     int address,
//     logic csr_write_valid,
//     longint wrtie_data
// );

// int csr_w_addr = csr_waddr_o;
// logic csr_write = do_csr_write_o;
// longint csr_w_dara = csr_waddr_o;

// always @(posedge clk) begin
//     csr_monitor(csr_w_addr, csr_write, csr_w_dara);
// end

`endif

//to csr
assign csr_wrdata_o = csr_wr_data;
assign csr_raddr_o = csr_addr_i;
assign csr_waddr_o = csr_addr_i;

//to rcu
assign csr_exception_o = illegal_csr;
assign csr_ecause_o = illegal_ecause;
assign csr_rcu_resp_valid_o = rcu_csr_req_valid_i;
assign csr_rcu_wrb_rob_index_o = rob_index_i;
assign csr_rcu_wrb_addr_o = prd_addr_i;
assign csr_rcu_wrb_data_o = csr_op_data_in;
assign do_csr_write_o = csr_do_write_i & rcu_csr_req_valid_i;

//to pmp
assign pmp_cfg_vld_o            = rcu_csr_req_valid_i & is_pmpcfg;
assign pmp_cfg_addr_o           = csr_addr_i[PMPCFG_ID_WIDTH:1];
assign pmp_cfg_payload_o        = csr_wr_data;
assign pmp_addr_vld_o           = rcu_csr_req_valid_i & is_pmp;
assign pmp_addr_addr_o          = pmpaddr_base[PMPADDR_ID_WIDTH-1:0];
assign pmp_addr_payload_o       = csr_wr_data;

endmodule
