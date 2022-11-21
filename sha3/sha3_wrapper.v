//======================================================================
//
// Copyright (c) 2017, NORDUnet A/S All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions
// are met:
// - Redistributions of source code must retain the above copyright
//   notice, this list of conditions and the following disclaimer.
//
// - Redistributions in binary form must reproduce the above copyright
//   notice, this list of conditions and the following disclaimer in the
//   documentation and/or other materials provided with the distribution.
//
// - Neither the name of the NORDUnet nor the names of its contributors may
//   be used to endorse or promote products derived from this software
//   without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
// IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
// TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
// PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
// TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
// PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
// LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
// NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================

module sha3_wrapper
  (
   input wire          clk,
   input wire          rst_n,

   input wire          cs,
   input wire          we,

   input wire [7: 0]   address,
   input wire [31: 0]  write_data,
   output wire [31: 0] read_data
   );


   //
   // Address Decoder
   //
   localparam ADDR_MSB_REGS = 1'b0;
   localparam ADDR_MSB_CORE = 1'b1;

   wire [0:0] addr_msb = address[7];
   wire [6:0] addr_lsb = address[6:0];


   //
   // Output Mux
   //
   wire [31: 0] read_data_regs;
   wire [31: 0] read_data_core;


   //
   // Registers
   //
   localparam ADDR_NAME0        = 5'h00;
   localparam ADDR_NAME1        = 5'h01;
   localparam ADDR_VERSION      = 5'h02;

   localparam ADDR_CONTROL      = 5'h08;               // {next, init}
   localparam ADDR_STATUS       = 5'h09;               // {valid, ready}

   localparam CONTROL_INIT_BIT  = 0;
   localparam CONTROL_NEXT_BIT  = 1;

// localparam STATUS_READY_BIT  = 0; -- hardcoded to always read 1
   localparam STATUS_VALID_BIT  = 1;

   localparam CORE_NAME0        = 32'h73686133; // "sha3"
   localparam CORE_NAME1        = 32'h20202020; // "    " [four spaces]
   localparam CORE_VERSION      = 32'h302E3130; // "0.10"


   //
   // Registers
   //
   reg [ 1:0] reg_control;
   reg [ 1:0] reg_control_prev;


   //
   // Flags
   //
   wire       reg_control_init_posedge =
              reg_control[CONTROL_INIT_BIT] & ~reg_control_prev[CONTROL_INIT_BIT];

   wire       reg_control_next_posedge =
              reg_control[CONTROL_NEXT_BIT] & ~reg_control_prev[CONTROL_NEXT_BIT];


   //
   // Wires
   //
   wire reg_status_valid;


   //
   // SHA-3
   //
   sha3 sha3_inst
     (
      .clk                      (clk),
      .nreset                   (rst_n),

      .init                     (reg_control_init_posedge),
      .next                     (reg_control_next_posedge),

      .ready                    (reg_status_valid),

      .w                        (we && (addr_msb == ADDR_MSB_CORE)),
      .addr                     (addr_lsb),
      .din                      (write_data),
      .dout                     (read_data_core)
      );


   //
   // Read Latch
   //
   reg [31: 0]         tmp_read_data;


   //
   // Control Register Delay Block
   //
   always @(posedge clk)
     //
     if (!rst_n)        reg_control_prev <= 2'b00;
          else          reg_control_prev <= reg_control;


   //
   // Read/Write Interface
   //
   always @(posedge clk)
     //
     if (!rst_n) begin
        //
        reg_control <= 2'b00;
        //
     end else if (cs && we && (addr_msb == ADDR_MSB_REGS)) begin
        //
        // Write Handler
        //
        case (addr_lsb)
          //
          ADDR_CONTROL: reg_control <= write_data[CONTROL_NEXT_BIT:CONTROL_INIT_BIT];
          //
        endcase
        //
     end

   always @*
     if (cs && !we && (addr_msb == ADDR_MSB_REGS))
       //
       // Read Handler
       //
       case (address)
         //
         ADDR_NAME0:        tmp_read_data = CORE_NAME0;
         ADDR_NAME1:        tmp_read_data = CORE_NAME1;
         ADDR_VERSION:      tmp_read_data = CORE_VERSION;
         ADDR_CONTROL:      tmp_read_data = {{30{1'b0}}, reg_control};
         ADDR_STATUS:       tmp_read_data = {{30{1'b0}}, reg_status_valid, 1'b1};
         //
         default:           tmp_read_data = 32'h00000000;
         //
       endcase


   //
   // Register / Core Memory Selector
   //
   assign read_data = (addr_msb == ADDR_MSB_REGS) ? tmp_read_data : read_data_core;


endmodule
