// SPDX-License-Identifier: Apache-2.0
// Copyright 2019 Western Digital Corporation or its affiliates.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

//********************************************************************************
// $Id$
//
// Function: Basic RAM model with separate read/write ports and byte-wise write enable
// Comments:
//
//********************************************************************************
`ifdef VERILATOR
`include "params.vh"
`endif
module dpram64_2r1w
  #(parameter SIZE=0, // byte
    parameter AXI_DATA_WIDTH=520,
    parameter mem_clear = 0,
    parameter mem_simple_seq = 0,
    parameter memfile = "",
    parameter INDEX_NUM    = SIZE/(AXI_DATA_WIDTH/8),
    parameter INDEX_WIDTH  = $clog2(INDEX_NUM),
    parameter LSU_ADDR_WIDTH = 56,
    parameter LSU_DATA_WIDTH = 64
    )
  (input wire                           clk,
   input wire                           rst,
   input wire [LSU_DATA_WIDTH/8-1:0]    we,
   input wire [LSU_DATA_WIDTH-1:0] 		din_d,
   input wire [LSU_ADDR_WIDTH-1:0]      waddr_d,
   input wire [1:0]                     rsize_d,
   input wire                           unsign_d,
   input wire [AXI_DATA_WIDTH/8+INDEX_WIDTH-1:0]         raddr_i,
   input wire [LSU_ADDR_WIDTH-1:0]      raddr_d,
   output reg [AXI_DATA_WIDTH-1:0] 		dout_i,
   output reg [LSU_DATA_WIDTH-1:0] 		dout_d
   );

    // from_host
    reg haha;
    wire [LSU_ADDR_WIDTH-1:0] from_host_addr = 'h1040;

   reg [AXI_DATA_WIDTH-1:0] 			 mem [0:INDEX_NUM-1] /* verilator public */;

   integer 	 i;
   wire [AXI_DATA_WIDTH/8+INDEX_WIDTH-$clog2(AXI_DATA_WIDTH/8)-1:0] wadd = waddr_d[AXI_DATA_WIDTH/8+INDEX_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)];
   wire [INDEX_WIDTH-1:0] waddr_low = waddr_d[$clog2(AXI_DATA_WIDTH/8)-1:0];

    wire [55:0] mid_56 = unsign_d ? 56'b0 : {56{mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:0],3'b0}+7]}};
    wire [47:0] mid_48 = unsign_d ? 48'b0 : {48{mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:1],4'b0}+15]}};
    wire [31:0] mid_32 = unsign_d ? 32'b0 : {32{mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:2],5'b0}+31]}};


   always @(posedge clk) begin
      if (~haha) begin
        for(i = 0; i < LSU_DATA_WIDTH/8; i++) begin
            if (we[i]) mem[wadd][(waddr_low + i)*8+:8] <= din_d[ i*8+:8];
        end
      end else begin
        mem[from_host_addr[AXI_DATA_WIDTH/8+INDEX_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][from_host_addr[$clog2(AXI_DATA_WIDTH/8)-1:0]*8] <= 1;
      end
      dout_i <= mem[raddr_i[AXI_DATA_WIDTH/8+INDEX_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]];
      case(rsize_d)
        2'b00:
            dout_d <= {{mid_56},{mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:0],3'b0}+:8]}};
        2'b01:
            dout_d <= {{mid_48},{mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:1],4'b0}+:16]}};
        2'b10:
            dout_d <= {{mid_32},{mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:2],5'b0}+:32]}};
        2'b11:
            dout_d <= {mem[raddr_d[LSU_ADDR_WIDTH-1:$clog2(AXI_DATA_WIDTH/8)]][{raddr_d[$clog2(AXI_DATA_WIDTH/8)-1:3],6'b0}+:64]};
      endcase
   end


   generate
   initial begin
      if (mem_clear)
         for (i=0;i< SIZE/(AXI_DATA_WIDTH/8) ;i=i+1)
         mem[i] = {AXI_DATA_WIDTH{1'b0}};
      if (mem_simple_seq)
         for (i=0;i< SIZE/(AXI_DATA_WIDTH/8) ;i=i+1)
         mem[i] = {{(AXI_DATA_WIDTH-32){1'b0}}, i[32-1:0]};
      if(|memfile) begin
         $display("Preloading %m from %s", memfile);
         $readmemh(memfile, mem);
      end
   end
   endgenerate

// from host
always @(posedge clk) begin
    if (rst) begin
        haha <= 1;
    end else begin
        haha <= 0;
    end
end


endmodule
