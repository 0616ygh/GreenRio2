// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.
//
// ----------------------------
// AXI to SRAM Adapter
// ----------------------------
// Author: Florian Zaruba (zarubaf@iis.ee.ethz.ch)
//
// Description: Manages AXI transactions
//              Supports all burst accesses but only on aligned addresses and with full data width.
//              Assertions should guide you if there is something unsupported happening.
//
`default_nettype wire
module axi2mem #(
    parameter int unsigned ID_WIDTH          = 10,//10
    parameter int unsigned AXI_ADDR_WIDTH    = 32,
    parameter int unsigned AXI_DATA_WIDTH    = 64,
    parameter int unsigned AXI_USER_WIDTH    = 10//10
)(
   input logic                         clk_i,    // Clock
   input logic                         rst_ni,  // Asynchronous reset active low
//AW
   input wire [ID_WIDTH-1:0]  slave_aw_id,
   input wire [AXI_ADDR_WIDTH-1:0] 	      slave_aw_addr,
   input wire [7:0] 	      slave_aw_len,
   input wire [2:0] 	      slave_aw_size,
   input wire [1:0] 	      slave_aw_burst,
   input wire     		      slave_aw_valid,
   output reg 	     	      slave_aw_ready,
//AR
   input wire [ID_WIDTH-1:0]  slave_ar_id,
   input wire [AXI_ADDR_WIDTH-1:0] 	      slave_ar_addr,
   input wire [7:0] 	      slave_ar_len,
   input wire [2:0] 	      slave_ar_size,
   input wire [1:0] 	      slave_ar_burst,
   input wire 		          slave_ar_valid,
   output reg 		          slave_ar_ready,
//W
   input wire [AXI_DATA_WIDTH-1:0] 	      slave_w_data,
   input wire [AXI_DATA_WIDTH-1:0] 	      slave_w_strb,
   input wire 		          slave_w_last,
   input wire 		          slave_w_valid,
   output reg 		          slave_w_ready,
//B
   output reg [ID_WIDTH-1:0]  slave_b_id,
   output reg [1:0] 	      slave_b_resp,
   output reg 		          slave_b_valid,
   input wire 		          slave_b_ready,
//R
   output reg [ID_WIDTH-1:0]  slave_r_id,
   output reg [AXI_DATA_WIDTH-1:0] 	      slave_r_data,
   output reg [1:0] 	      slave_r_resp,
   output reg 		          slave_r_last,
   output reg 		          slave_r_valid,
   input wire 		          slave_r_ready,

   output logic                        req_o,//没用
   output logic                        we_o,//是1时表示写 是0时表示读 
   output logic [AXI_ADDR_WIDTH-1:0]   addr_o,//地址 最后6位是0 因为we_o决定选哪个
   output logic [AXI_DATA_WIDTH/8-1:0] be_o,//写的时候选择哪个byte
   output logic [AXI_DATA_WIDTH-1:0]   data_o,//write to mem
   input  logic [AXI_DATA_WIDTH-1:0]   data_i//read form mem
);

    // AXI has the following rules governing the use of bursts:
    // - for wrapping bursts, the burst length must be 2, 4, 8, or 16
    // - a burst must not cross a 4KB address boundary
    // - early termination of bursts is not supported.
    typedef enum logic [1:0] { FIXED = 2'b00, INCR = 2'b01, WRAP = 2'b10} axi_burst_t;

    localparam LOG_NR_BYTES = $clog2(AXI_DATA_WIDTH/8);

    typedef struct packed {
        logic [ID_WIDTH-1:0]       id;
        logic [AXI_ADDR_WIDTH-1:0] addr;
        logic [7:0]                len;
        logic [2:0]                size;
        axi_burst_t                burst;
    } ax_req_t;

    // Registers
    enum logic [2:0] { IDLE, READ, WRITE, SEND_B, WAIT_WVALID }  state_d, state_q;
    ax_req_t                   ax_req_d, ax_req_q;
    logic [AXI_ADDR_WIDTH-1:0] req_addr_d, req_addr_q;
    logic [7:0]                cnt_d, cnt_q;

    function automatic logic [AXI_ADDR_WIDTH-1:0] get_wrap_boundary (input logic [AXI_ADDR_WIDTH-1:0] unaligned_address, input logic [7:0] len);
        logic [AXI_ADDR_WIDTH-1:0] warp_address = '0;
        //  for wrapping transfers ax_len can only be of size 1, 3, 7 or 15
        if (len == 4'b1)
            warp_address[AXI_ADDR_WIDTH-1:1+LOG_NR_BYTES] = unaligned_address[AXI_ADDR_WIDTH-1:1+LOG_NR_BYTES];
        else if (len == 4'b11)
            warp_address[AXI_ADDR_WIDTH-1:2+LOG_NR_BYTES] = unaligned_address[AXI_ADDR_WIDTH-1:2+LOG_NR_BYTES];
        else if (len == 4'b111)
            warp_address[AXI_ADDR_WIDTH-1:3+LOG_NR_BYTES] = unaligned_address[AXI_ADDR_WIDTH-3:2+LOG_NR_BYTES];
        else if (len == 4'b1111)
            warp_address[AXI_ADDR_WIDTH-1:4+LOG_NR_BYTES] = unaligned_address[AXI_ADDR_WIDTH-3:4+LOG_NR_BYTES];
    
        return warp_address;
    endfunction
    
    logic [AXI_ADDR_WIDTH-1:0] aligned_address;
    logic [AXI_ADDR_WIDTH-1:0] wrap_boundary;
    logic [AXI_ADDR_WIDTH-1:0] upper_wrap_boundary;
    logic [AXI_ADDR_WIDTH-1:0] cons_addr;
    
    always_comb begin
        // address generation
        aligned_address = {ax_req_q.addr[AXI_ADDR_WIDTH-1:LOG_NR_BYTES], {{LOG_NR_BYTES}{1'b0}}};//每次要读一个cache_line 所以变一下地址
        wrap_boundary = get_wrap_boundary(ax_req_q.addr, ax_req_q.len);
        // this will overflow
        upper_wrap_boundary = wrap_boundary + ((ax_req_q.len + 1) << LOG_NR_BYTES);
        // calculate consecutive address
        cons_addr = aligned_address + (cnt_q << LOG_NR_BYTES);// 每读一个cache line后 地址增加一个cache line

        // Transaction attributes
        // default assignments
        state_d    = state_q;
        ax_req_d   = ax_req_q;
        req_addr_d = req_addr_q;
        cnt_d      = cnt_q;
        // Memory default assignments
        data_o = slave_w_data;
        be_o   = slave_w_strb;
        we_o   = 1'b0;
        req_o  = 1'b0;
        addr_o = '0;
        // AXI assignments
        // request
        slave_aw_ready = 1'b0;
        slave_ar_ready = 1'b0;
        // read response channel
        slave_r_valid  = 1'b0;
        slave_r_data   = data_i;
        slave_r_resp   = '0;
        slave_r_last   = '0;
        slave_r_id     = ax_req_q.id;
        // slave write data channel
        slave_w_ready  = 1'b0;
        // write response channel
        slave_b_valid  = 1'b0;
        slave_b_resp   = 1'b0;
        slave_b_id     = 1'b0;
//      slave_b_user   = 1'b0;

        case (state_q)

            IDLE: begin
                // Wait for a read or write
                // ------------
                // Read
                // ------------
                if (slave_ar_valid) begin
                    slave_ar_ready = 1'b1;
                    // sample ax
                    ax_req_d       = {slave_ar_id, slave_ar_addr, slave_ar_len, slave_ar_size, slave_ar_burst};
                    state_d        = READ;
                    //  we can request the first address, this saves us time
                    req_o          = 1'b1;
                    addr_o         = slave_ar_addr;
                    // save the address
                    req_addr_d     = slave_ar_addr;
                    // save the ar_len
                    cnt_d          = 1;
                // ------------
                // Write
                // ------------
                end else if (slave_aw_valid) begin
                    slave_aw_ready = 1'b1;
                    slave_w_ready  = 1'b1;
                    addr_o         = slave_aw_addr;
                    // sample ax
                    ax_req_d       = {slave_aw_id, slave_aw_addr, slave_aw_len, slave_aw_size, slave_aw_burst};
                    // we've got our first w_valid so start the write process
                    if (slave_w_valid) begin
                        req_o          = 1'b1;
                        we_o           = 1'b1;
                        state_d        = (slave_w_last) ? SEND_B : WRITE;
                        cnt_d          = 1;
                    // we still have to wait for the first w_valid to arrive
                    end else
                        state_d = WAIT_WVALID;
                end
            end

            // ~> we are still missing a w_valid
            WAIT_WVALID: begin
                slave_w_ready = 1'b1;
                addr_o = ax_req_q.addr;
                // we can now make our first request
                if (slave_w_valid) begin
                    req_o          = 1'b1;
                    we_o           = 1'b1;
                    state_d        = (slave_w_last) ? SEND_B : WRITE;
                    cnt_d          = 1;
                end
            end

            READ: begin
                // keep request to memory high
                req_o  = 1'b1;
                addr_o = req_addr_q;
                // send the response
                slave_r_valid = 1'b1;
                slave_r_data  = data_i;
                slave_r_id    = ax_req_q.id;
                slave_r_last  = (cnt_q == ax_req_q.len + 1);

                // check that the master is ready, the slave must not wait on this
                if (slave_r_ready) begin
                    // ----------------------------
                    // Next address generation
                    // ----------------------------
                    // handle the correct burst type
                    case (ax_req_q.burst)
                        FIXED, INCR: addr_o = cons_addr;
                        WRAP:  begin
                            // check if the address reached warp boundary
                            if (cons_addr == upper_wrap_boundary) begin
                                addr_o = wrap_boundary;
                            // address warped beyond boundary
                            end else if (cons_addr > upper_wrap_boundary) begin
                                addr_o = ax_req_q.addr + ((cnt_q - ax_req_q.len) << LOG_NR_BYTES);
                            // we are still in the incremental regime
                            end else begin
                                addr_o = cons_addr;
                            end
                        end
                    endcase
                    // we need to change the address here for the upcoming request
                    // we sent the last byte -> go back to idle
                    if (slave_r_last) begin
                        state_d = IDLE;
                        // we already got everything
                        req_o = 1'b0;
                    end
                    // save the request address for the next cycle
                    req_addr_d = addr_o;
                    // we can decrease the counter as the master has consumed the read data
                    cnt_d = cnt_q + 1;
                    // TODO: configure correct byte-lane
                end
            end
            // ~> we already wrote the first word here
            WRITE: begin

                slave_w_ready = 1'b1;

                // consume a word here
                if (slave_w_valid) begin
                    req_o         = 1'b1;
                    we_o          = 1'b1;
                    // ----------------------------
                    // Next address generation
                    // ----------------------------
                    // handle the correct burst type
                    case (ax_req_q.burst)

                        FIXED, INCR: addr_o = cons_addr;
                        WRAP:  begin
                            // check if the address reached warp boundary
                            if (cons_addr == upper_wrap_boundary) begin
                                addr_o = wrap_boundary;
                            // address warped beyond boundary
                            end else if (cons_addr > upper_wrap_boundary) begin
                                addr_o = ax_req_q.addr + ((cnt_q - ax_req_q.len) << LOG_NR_BYTES);
                            // we are still in the incremental regime
                            end else begin
                                addr_o = cons_addr;
                            end
                        end
                    endcase
                    // save the request address for the next cycle
                    req_addr_d = addr_o;
                    // we can decrease the counter as the master has consumed the read data
                    cnt_d = cnt_q + 1;

                    if (slave_w_last)
                        state_d = SEND_B;
                end
            end
            // ~> send a write acknowledge back
            SEND_B: begin
                slave_b_valid = 1'b1;
                slave_b_id    = ax_req_q.id;
                if (slave_b_ready)
                    state_d = IDLE;
            end

        endcase
    end

    // --------------
    // Registers
    // --------------
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (~rst_ni) begin
            state_q    <= IDLE;
            ax_req_q  <= '0;
            req_addr_q <= '0;
            cnt_q      <= '0;
        end else begin
            state_q    <= state_d;
            ax_req_q   <= ax_req_d;
            req_addr_q <= req_addr_d;
            cnt_q      <= cnt_d;
        end
    end
endmodule


