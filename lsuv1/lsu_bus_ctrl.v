`ifndef _LSU_BUS_CTRL_
`define _LSU_BUS_CTRL_
`ifdef VERILATOR
`include "params.vh"
`endif
// TODO: do not support io amo operation
module lsu_bus_ctrl(
    input clk, rst, flush,
    // <> lsq
    output                                          bus_ctrl_lsq_rdy_o,
    input                                           lsq_bus_ctrl_req_vld_i,
    input                                           lsq_bus_ctrl_req_load_or_store_i,
    input                                           lsq_bus_ctrl_req_is_fence_i,
    input   [     ROB_INDEX_WIDTH - 1 : 0]          lsq_bus_ctrl_req_rob_index_i,
    input   [    PHY_REG_ADDR_WIDTH - 1 : 0]        lsq_bus_ctrl_req_rd_addr_i,
    input   [      STU_OP_WIDTH - 1 : 0]            lsq_bus_ctrl_req_opcode_i,
    input   [       PHYSICAL_ADDR_LEN - 1 : 0]      lsq_bus_ctrl_req_paddr_i, 
    input   [              XLEN - 1 : 0]            lsq_bus_ctrl_req_data_i,
    // <> wb bus
    output                                          bus_ctrl_wb_cyc_o,
    output                                          bus_ctrl_wb_stb_o,
    output                                          bus_ctrl_wb_we_o,
    output [PHYSICAL_ADDR_LEN - 1 : 0]              bus_ctrl_wb_adr_o,
    output [WB_DATA_LEN-1:0]                        bus_ctrl_wb_dat_o,
    output [WB_DATA_LEN/8-1:0]                      bus_ctrl_wb_sel_o,
    input                                           wb_bus_ctrl_ack_i,
    input  [WB_DATA_LEN -1:0]                       wb_bus_ctrl_dat_i,
    // <> wb arb
    output                                          bus_ctrl_wb_arb_wb_vld_o,
    output [ROB_INDEX_WIDTH - 1 : 0]                bus_ctrl_wb_arb_wb_rob_index_o,
    output                                          bus_ctrl_wb_arb_prf_wb_vld_o,
    output [PHY_REG_ADDR_WIDTH - 1 : 0]             bus_ctrl_wb_arb_prf_wb_rd_addr_o,
    output [XLEN - 1 : 0]                           bus_ctrl_wb_arb_prf_wb_data_o,
    input                                           wb_arb_bus_ctrl_rdy_i
);

wire                                                bus_ctrl_req_init_en;
wire                                                bus_ls_done;
wire                                                wb_hsk;

reg                                                 bus_ctrl_req_vld_q;
reg                                                 bus_ctrl_req_load_or_store_q;
reg                                                 bus_ctrl_req_is_fence_q;
reg   [     ROB_INDEX_WIDTH - 1 : 0]                bus_ctrl_req_rob_index_q;
reg   [    PHY_REG_ADDR_WIDTH - 1 : 0]              bus_ctrl_req_rd_addr_q;
reg   [      STU_OP_WIDTH - 1 : 0]                  bus_ctrl_req_opcode_q;
reg   [       PHYSICAL_ADDR_LEN - 1 : 0]            bus_ctrl_req_paddr_q; 
reg   [              XLEN - 1 : 0]                  bus_ctrl_req_data_q;
reg  [1:0]                                          bus_ctrl_req_ack_q;

wire [1:0]                                          bus_ctrl_req_ack_d;
wire                                                bus_ctrl_req_ack_en;
wire                                                bus_ctrl_req_data_en;
wire   [              XLEN - 1 : 0]                 bus_ctrl_req_data_d;
wire                                                bus_ctrl_req_vld_en;
wire                                                bus_ctrl_req_vld_d;
wire                                                bus_ctrl_req_unsigned;
wire  [1:0]                                         bus_ctrl_req_size;
wire                                                bus_ctrl_req_done;

assign bus_ls_done = wb_hsk & bus_ctrl_req_vld_q; 
assign wb_hsk = bus_ctrl_wb_arb_wb_vld_o & wb_arb_bus_ctrl_rdy_i;
assign bus_ctrl_req_init_en = lsq_bus_ctrl_req_vld_i & (~bus_ctrl_req_vld_q | bus_ctrl_req_vld_q & wb_hsk);
assign bus_ctrl_req_ack_d = bus_ctrl_req_init_en ? 2'b0 : bus_ctrl_req_ack_q + 1;
assign bus_ctrl_req_ack_en = bus_ctrl_req_init_en | wb_bus_ctrl_ack_i;
assign bus_ctrl_req_data_en = bus_ctrl_req_init_en | wb_bus_ctrl_ack_i & ~bus_ctrl_req_load_or_store_q;
assign bus_ctrl_req_data_d = bus_ctrl_req_init_en ? 
                                lsq_bus_ctrl_req_data_i : 
                                (bus_ctrl_req_ack_q == 2'b00) ? 
                                    {bus_ctrl_req_data_q[2 * WB_DATA_LEN - 1 : WB_DATA_LEN], wb_bus_ctrl_dat_i} :
                                    {wb_bus_ctrl_dat_i, bus_ctrl_req_data_q[WB_DATA_LEN-1:0]};
assign bus_ctrl_req_vld_en = bus_ctrl_req_init_en | bus_ls_done;
assign bus_ctrl_req_vld_d = bus_ctrl_req_init_en ? lsq_bus_ctrl_req_vld_i : 0;
assign bus_ctrl_lsq_rdy_o = ~bus_ctrl_req_vld_q | bus_ctrl_req_vld_q & wb_hsk;

assign bus_ctrl_req_size = (bus_ctrl_req_opcode_q == LDU_LB || bus_ctrl_req_opcode_q == LDU_LBU || bus_ctrl_req_opcode_q == STU_SB) ? 0 :
                            (bus_ctrl_req_opcode_q == LDU_LH || bus_ctrl_req_opcode_q == LDU_LHU || bus_ctrl_req_opcode_q == STU_SH) ? 1 :
                            (
                                bus_ctrl_req_opcode_q == LDU_LW || bus_ctrl_req_opcode_q == STU_LRW || bus_ctrl_req_opcode_q == STU_SW ||
                                bus_ctrl_req_opcode_q == STU_SCW || bus_ctrl_req_opcode_q == STU_AMOSWAPW || bus_ctrl_req_opcode_q == STU_AMOADDW ||
                                bus_ctrl_req_opcode_q == STU_AMOANDW || bus_ctrl_req_opcode_q == STU_AMOORW || bus_ctrl_req_opcode_q == STU_AMOXORW ||
                                bus_ctrl_req_opcode_q == STU_AMOMAXW || bus_ctrl_req_opcode_q == STU_AMOMAXUW || bus_ctrl_req_opcode_q == STU_AMOMINW ||
                                bus_ctrl_req_opcode_q == STU_AMOMINUW  || bus_ctrl_req_opcode_q == LDU_LWU
                            ) ? 2 :
                            (
                                bus_ctrl_req_opcode_q == LDU_LD || bus_ctrl_req_opcode_q == STU_LRD || bus_ctrl_req_opcode_q == STU_SD ||
                                bus_ctrl_req_opcode_q == STU_SCD || bus_ctrl_req_opcode_q == STU_AMOSWAPD || bus_ctrl_req_opcode_q == STU_AMOADDD ||
                                bus_ctrl_req_opcode_q == STU_AMOANDD || bus_ctrl_req_opcode_q == STU_AMOORD || bus_ctrl_req_opcode_q == STU_AMOXORD ||
                                bus_ctrl_req_opcode_q == STU_AMOMAXD || bus_ctrl_req_opcode_q == STU_AMOMAXUD || bus_ctrl_req_opcode_q == STU_AMOMIND ||
                                bus_ctrl_req_opcode_q == STU_AMOMINUD 
                            ) ? 3 : 
                            0;
assign bus_ctrl_req_unsigned = (
                                    bus_ctrl_req_opcode_q == LDU_LBU || bus_ctrl_req_opcode_q == LDU_LHU  || bus_ctrl_req_opcode_q == LDU_LWU ||
                                    bus_ctrl_req_opcode_q == STU_LRD || bus_ctrl_req_opcode_q == STU_AMOMAXUW  || bus_ctrl_req_opcode_q == STU_AMOMAXUD ||
                                    bus_ctrl_req_opcode_q == STU_AMOMINUW || bus_ctrl_req_opcode_q == STU_AMOMINUD 
                                );                             

assign bus_ctrl_wb_cyc_o = bus_ctrl_req_vld_q & ~bus_ctrl_req_done & ~wb_bus_ctrl_ack_i;
assign bus_ctrl_wb_stb_o = bus_ctrl_wb_cyc_o;
assign bus_ctrl_wb_we_o = bus_ctrl_req_load_or_store_q;
assign bus_ctrl_wb_adr_o = (bus_ctrl_req_size == 3 && bus_ctrl_req_ack_q == 2'b01) ? 
                                bus_ctrl_req_paddr_q + 4 :
                                bus_ctrl_req_paddr_q;
assign bus_ctrl_wb_dat_o = (bus_ctrl_req_size == 3 && bus_ctrl_req_ack_q == 2'b01) ? 
                                bus_ctrl_req_data_q[2 * WB_DATA_LEN - 1 : WB_DATA_LEN] :
                                bus_ctrl_req_data_q[WB_DATA_LEN - 1 : 0];
assign bus_ctrl_wb_sel_o = (bus_ctrl_req_size == 0) ? 4'b0001 :
                            (bus_ctrl_req_size == 1) ? 4'b0011 :
                            4'b1111;
assign bus_ctrl_req_done = (bus_ctrl_req_size == 3) ? 
                                (bus_ctrl_req_ack_q == 2'b10) : (bus_ctrl_req_ack_q == 2'b01);

assign bus_ctrl_wb_arb_wb_vld_o = bus_ctrl_req_done & bus_ctrl_req_vld_q;
assign bus_ctrl_wb_arb_wb_rob_index_o = bus_ctrl_req_rob_index_q;
assign bus_ctrl_wb_arb_prf_wb_vld_o = bus_ctrl_wb_arb_wb_vld_o & ~bus_ctrl_req_load_or_store_q;
assign bus_ctrl_wb_arb_prf_wb_rd_addr_o = bus_ctrl_req_rd_addr_q;
assign bus_ctrl_wb_arb_prf_wb_data_o = (bus_ctrl_req_unsigned | (bus_ctrl_req_size == 3)) ? bus_ctrl_req_data_q :
                                    (bus_ctrl_req_size == 0) ? {{(XLEN - 8){bus_ctrl_req_data_q[7]}}, (bus_ctrl_req_data_q[7:0])} : 
                                    (bus_ctrl_req_size == 1) ? {{(XLEN - 16){bus_ctrl_req_data_q[15]}}, (bus_ctrl_req_data_q[15:0])} :
                                    {{(XLEN - 32){bus_ctrl_req_data_q[31]}}, (bus_ctrl_req_data_q[31:0])};
always @(posedge clk) begin
    if(rst | flush) begin
        bus_ctrl_req_vld_q <= 0;
    end 
    else begin
        if(bus_ctrl_req_vld_en) begin
            bus_ctrl_req_vld_q <= bus_ctrl_req_vld_d;
        end
    end 
end
always @(posedge clk) begin
    if(rst | flush) begin
        bus_ctrl_req_load_or_store_q <= 0;
        bus_ctrl_req_is_fence_q <= 0;
        bus_ctrl_req_rob_index_q <= 0;
        bus_ctrl_req_rd_addr_q <= 0;
        bus_ctrl_req_opcode_q <= 0;
        bus_ctrl_req_paddr_q <= 0;
    end 
    else begin
        if(bus_ctrl_req_init_en) begin
            bus_ctrl_req_load_or_store_q <= lsq_bus_ctrl_req_load_or_store_i;
            bus_ctrl_req_is_fence_q <= lsq_bus_ctrl_req_is_fence_i;
            bus_ctrl_req_rob_index_q <= lsq_bus_ctrl_req_rob_index_i;
            bus_ctrl_req_rd_addr_q <= lsq_bus_ctrl_req_rd_addr_i;
            bus_ctrl_req_opcode_q <= lsq_bus_ctrl_req_opcode_i;
            bus_ctrl_req_paddr_q <= lsq_bus_ctrl_req_paddr_i;
        end
    end 
end
always @(posedge clk) begin
    if(rst | flush) begin
        bus_ctrl_req_ack_q <= 0;
    end 
    else begin
        if(bus_ctrl_req_ack_en) begin
            bus_ctrl_req_ack_q <= bus_ctrl_req_ack_d;
        end
    end 
end
always @(posedge clk) begin
    if(rst | flush) begin
        bus_ctrl_req_data_q <= 0;
    end 
    else begin
        if(bus_ctrl_req_data_en) begin
            bus_ctrl_req_data_q <= bus_ctrl_req_data_d;
        end
    end 
end
endmodule
`endif // _LSU_BUS_CTRL_
