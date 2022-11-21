//
// RISu64
// Copyright 2022 Wenting Zhang
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//
//`include "../params.vh"

`ifdef VERILATOR
`include "params.vh"
`endif
module md(
    input  wire         clk,
    input  wire         rst,
    input  wire         trap,
    // To Issue
    input  wire [PHY_REG_ADDR_WIDTH-1:0]    fu_md_prd_addr_i,      //  v 1
    input  wire [63:0]                      fu_md_oprd1_i, //  v 1
    input  wire [63:0]                      fu_md_oprd2_i, //  v 1
    input  wire [ROB_INDEX_WIDTH-1 : 0]     fu_md_rob_index_i,
    input  wire [2:0]                       fu_md_func_sel_i,    //  v 1
    input  wire                             fu_md_muldiv_i,   //  v 1
    input  wire                             fu_md_req_valid_i,    //  v 1
    output wire                             fu_md_req_ready_o,    //  v 1
    // Hazard detection  for issue to detect hazard
    // To writeback
    output wire [PHY_REG_ADDR_WIDTH-1:0]    md_fu_wrb_prd_addr_o,
    output wire [ROB_INDEX_WIDTH-1 : 0]     md_fu_wrb_rob_index_o,
    output wire [XLEN - 1:0]                md_fu_wrb_data_o,   //  v  1
    output wire                             md_fu_wrb_resp_valid_o    //  v  1
//    input  wire         md_wb_ready,    //  v  1   always ready
    // Pipeline flush
);

    wire req_unit = fu_md_muldiv_i;
    wire md_fu_resp_valid_w;
    reg active_unit;
    reg active;
    reg [63:0] pc;
    reg [PHY_REG_ADDR_WIDTH - 1: 0] prd_addr;
    reg [ROB_INDEX_WIDTH - 1 : 0] rob_index;
    reg [4:0] dst;

    wire mul_req_ready;
    wire mul_resp_valid;
    wire [63:0] mul_resp_result;
    mul mul(
        .clk_i(clk),
        .rst_ni(rst | trap),
        .operand_a_i(fu_md_oprd1_i),
        .operand_b_i(fu_md_oprd2_i),
        .req_op_i(fu_md_func_sel_i[1:0]),
        .req_word_i(fu_md_func_sel_i[2]),
        .req_valid_i(fu_md_req_valid_i && (fu_md_muldiv_i == MD_MUL) && !trap && !active),
        .req_ready_o(mul_req_ready),
        .resp_valid_o(mul_resp_valid),
        .resp_value_o(mul_resp_result)
    );

    wire div_req_ready;
    wire div_resp_valid;
    wire [63:0] div_resp_result;
    div div(
        .clk(clk),
        .rst(rst | trap),
        .operand1(fu_md_oprd1_i),
        .operand2(fu_md_oprd2_i),
        .div_op(fu_md_func_sel_i),
        .req_valid(fu_md_req_valid_i && (fu_md_muldiv_i == MD_DIV) && !trap && !active),
        .req_ready(div_req_ready),
        .resp_result(div_resp_result),
        .resp_valid(div_resp_valid)
    );

    assign fu_md_req_ready_o = !active;

    assign md_fu_wrb_data_o = (active_unit == MD_MUL) ?
            (mul_resp_result) : (div_resp_result);
    assign md_fu_wrb_prd_addr_o = prd_addr;
    assign md_fu_wrb_rob_index_o = rob_index;
    assign md_fu_resp_valid_w = (active_unit == MD_MUL) ?
            (mul_resp_valid) : (div_resp_valid);
    assign md_fu_wrb_resp_valid_o = md_fu_resp_valid_w && !trap;

    // Abortion is only valid the 0th and 1st cycle it started.

    always @(posedge clk) begin
        if (rst | trap) begin
            active <= 0;
        end else if (!active) begin
            if (fu_md_req_valid_i && fu_md_req_ready_o && !trap) begin
                active <= 1'b1;
                // Only speculated instructions can be cancelle
                active_unit <= req_unit;
                prd_addr <= fu_md_prd_addr_i;
                rob_index <= fu_md_rob_index_i;
            end
        end else if (div_req_ready & mul_req_ready) begin
            active <= 1'b0;
        end
    end

endmodule

