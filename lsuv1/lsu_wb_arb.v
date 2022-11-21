`ifndef _LSU_WB_ARB_V_
`define _LSU_WB_ARB_V_
`ifdef VERILATOR
`include "params.vh"
`endif
module lsu_wb_arb (
    // global 
    input clk, rst, flush,
    // <> d$ 
    input  [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT - 1 : 0]                                  l1d_wb_arb_wb_vld_i,
    input  [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) * ROB_INDEX_WIDTH - 1 : 0]              l1d_wb_arb_wb_rob_index_i,

    input  [LSU_DATA_PIPE_COUNT - 1 : 0]                                                        l1d_wb_arb_prf_wb_vld_i,
    input  [PHY_REG_ADDR_WIDTH * LSU_DATA_PIPE_COUNT - 1 : 0]                                   l1d_wb_arb_prf_wb_rd_addr_i,
    input  [XLEN * LSU_DATA_PIPE_COUNT - 1 : 0]                                                 l1d_wb_arb_prf_wb_data_i,

    // <> Bus                                               
    input                                                                                       bus_wb_arb_wb_vld_i,
    input  [ROB_INDEX_WIDTH - 1 : 0]                                                            bus_wb_arb_wb_rob_index_i,
    input                                                                                       bus_wb_arb_prf_wb_vld_i,
    input  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                         bus_wb_arb_prf_wb_rd_addr_i,
    input  [XLEN - 1 : 0]                                                                       bus_wb_arb_prf_wb_data_i,
    output                                                                                      wb_arb_bus_rdy_o,

    // <> LSQ
    output [LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT : 0]                                      wb_arb_lsq_wb_vld_o, // last one for bus
    output [(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT + 1) * ROB_INDEX_WIDTH - 1: 0]           wb_arb_lsq_wb_rob_index_o, // last one for bus
    output                                                                                      wb_arb_rdy_o,

    // <> PRF
    output                                                                                      wb_arb_prf_wb_vld_o,
    output  [PHY_REG_ADDR_WIDTH - 1 : 0]                                                        wb_arb_prf_wb_rd_addr_o,
    output  [XLEN - 1 : 0]                                                                      wb_arb_prf_wb_data_o
);

wire  [PHY_REG_ADDR_WIDTH - 1 : 0]                                      fifo_prf_wb_rd_addr_enque;
wire  [XLEN - 1 : 0]                                                    fifo_prf_wb_data_enque;
wire  [PHY_REG_ADDR_WIDTH - 1 : 0]                                      fifo_prf_wb_rd_addr_deque;
wire  [XLEN - 1 : 0]                                                    fifo_prf_wb_data_deque;
wire                                                                    fifo_enque_vld;
wire                                                                    fifo_enque_rdy;
wire                                                                    fifo_deque_vld;
wire                                                                    fifo_deque_rdy;
// lsq wb
// lsq wb for l1d, 4 entry(LSU_ADDR_PIPE_COUNT + LSU_DATA_PIPE_COUNT) + 1 bus entry
assign wb_arb_bus_rdy_o = ~(|l1d_wb_arb_wb_vld_i) & (~bus_wb_arb_prf_wb_vld_i | bus_wb_arb_prf_wb_vld_i & ~(|l1d_wb_arb_prf_wb_vld_i | fifo_deque_vld));
assign wb_arb_lsq_wb_vld_o = {(~(|l1d_wb_arb_wb_vld_i) & ~fifo_deque_vld & bus_wb_arb_wb_vld_i), l1d_wb_arb_wb_vld_i};
assign wb_arb_lsq_wb_rob_index_o = {bus_wb_arb_wb_rob_index_i, l1d_wb_arb_wb_rob_index_i};

// prf wb

// FIXME: only works for 2 prf wb
assign fifo_enque_vld = &l1d_wb_arb_prf_wb_vld_i;
assign fifo_prf_wb_rd_addr_enque = l1d_wb_arb_prf_wb_rd_addr_i[PHY_REG_ADDR_WIDTH +: PHY_REG_ADDR_WIDTH];
assign fifo_prf_wb_data_enque = l1d_wb_arb_prf_wb_data_i[XLEN +: XLEN];
assign fifo_deque_rdy = ~(|l1d_wb_arb_prf_wb_vld_i);

   
assign wb_arb_prf_wb_vld_o = |l1d_wb_arb_prf_wb_vld_i | fifo_deque_vld | bus_wb_arb_prf_wb_vld_i;
assign wb_arb_prf_wb_rd_addr_o = |l1d_wb_arb_prf_wb_vld_i ? (
                                            l1d_wb_arb_prf_wb_vld_i[0] ? l1d_wb_arb_prf_wb_rd_addr_i[0 +: PHY_REG_ADDR_WIDTH] :
                                                                            l1d_wb_arb_prf_wb_rd_addr_i[PHY_REG_ADDR_WIDTH +: PHY_REG_ADDR_WIDTH]
                                        ) :
                                    fifo_deque_vld ? fifo_prf_wb_rd_addr_deque :
                                    bus_wb_arb_prf_wb_vld_i ? bus_wb_arb_prf_wb_rd_addr_i :
                                    0;
assign wb_arb_prf_wb_data_o = |l1d_wb_arb_prf_wb_vld_i ? (
                                            l1d_wb_arb_prf_wb_vld_i[0] ? l1d_wb_arb_prf_wb_data_i[0 +: XLEN] :
                                                                            l1d_wb_arb_prf_wb_data_i[XLEN +: XLEN]
                                    ) :
                                fifo_deque_vld ? fifo_prf_wb_data_deque :
                                bus_wb_arb_prf_wb_vld_i ? bus_wb_arb_prf_wb_data_i :
                                0;

assign wb_arb_rdy_o = fifo_enque_rdy;
MultiPortStreamFIFO #(
    .Depth(LSQ_DEPTH / 2),
    .DataWidth(PHY_REG_ADDR_WIDTH + XLEN),
    .EnqWidth(1),
    .DeqWidth(1)
) prf_wb_fifo(
    .enq_vld_i(fifo_enque_vld),
    .enq_payload_i({fifo_prf_wb_rd_addr_enque, fifo_prf_wb_data_enque}),
    .enq_rdy_o(fifo_enque_rdy),
    .deq_vld_o(fifo_deque_vld),
    .deq_payload_o({fifo_prf_wb_rd_addr_deque, fifo_prf_wb_data_deque}),
    .deq_rdy_i(fifo_deque_rdy),
    .flush_i(flush),
    .clk(clk),
    .rstn(~rst)
);

endmodule
`endif // _LSU_WB_ARB_V_
