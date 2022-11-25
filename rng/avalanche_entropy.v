//======================================================================
//
// avalanche_entropy.v
// -------------------
// Top level wrapper of the entropy provider core based on an external
// avalanche noise based source. (or any other source that can
// toggle a single bit input).
//
// Currently the design consists of a free running counter. At every
// positive flank detected the LSB of the counter is pushed into
// a 32bit shift register.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2014, NORDUnet A/S All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
// - Redistributions of source code must retain the above copyright notice,
//   this list of conditions and the following disclaimer.
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

module avalanche_entropy(
                         input wire           clk,
                         input wire           reset_n,

                         input wire           noise,

                         input wire           cs,
                         input wire           we,
                         input wire  [7 : 0]  address,
                         input wire  [31 : 0] write_data,
                         output wire [31 : 0] read_data,
                         output wire          error,

                         input wire           discard,
                         input wire           test_mode,
                         output wire          security_error,

                         output wire          entropy_enabled,
                         output wire [31 : 0] entropy_data,
                         output wire          entropy_valid,
                         input wire           entropy_ack,

                         output wire [7 : 0]  debug,
                         input wire           debug_update
                        );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0       = 8'h00;
  localparam ADDR_NAME1       = 8'h01;
  localparam ADDR_VERSION     = 8'h02;

  localparam ADDR_CTRL        = 8'h08;
  localparam CTRL_ENABLE_BIT  = 0;

  localparam ADDR_STATUS      = 8'h09;
  localparam STATUS_VALID_BIT = 1;

  localparam ADDR_ENTROPY     = 8'h20;
  localparam ADDR_DELTA       = 8'h30;

  localparam CORE_NAME0       = 32'h6578746e; // "extn"
  localparam CORE_NAME1       = 32'h6f697365; // "oise"
  localparam CORE_VERSION     = 32'h302e3130; // "0.10"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg enable_reg;
  reg enable_new;
  reg enable_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0]  tmp_read_data;
  reg           tmp_error;

  wire [31 : 0] delta;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data       = tmp_read_data;
  assign error           = tmp_error;
  assign security_error  = 0;


  //----------------------------------------------------------------
  // Core instantiation.
  //----------------------------------------------------------------
  avalanche_entropy_core core(
                              .clk(clk),
                              .reset_n(reset_n),

                              .noise(noise),

                              .enable(enable_reg),

                              .entropy_data(entropy_data),
                              .entropy_enabled(entropy_enabled),
                              .entropy_valid(entropy_valid),
                              .entropy_ack(entropy_ack),

                              .delta(delta),

                              .debug(debug),
                              .debug_update(debug_update)
                             );


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          enable_reg <= 1'h1;
        end
      else
        begin
          if (enable_we)
            enable_reg <= enable_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // api_logic
  //----------------------------------------------------------------
  always @*
    begin : api_logic
      tmp_read_data = 32'h00000000;
      tmp_error          = 1'b0;
      enable_new         = 0;
      enable_we          = 0;

      if (cs)
        begin
          if (we)
            begin
              case (address)
                // Write operations.
                ADDR_CTRL:
                  begin
                    enable_new = write_data[CTRL_ENABLE_BIT];
                    enable_we  = 1;
                  end

                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (address)
            end // if (we)
          else
            begin
              case (address)
                ADDR_NAME0:
                  begin
                    tmp_read_data = CORE_NAME0;
                  end

                ADDR_NAME1:
                  begin
                    tmp_read_data = CORE_NAME1;
                  end

                ADDR_VERSION:
                  begin
                    tmp_read_data = CORE_VERSION;
                  end

                ADDR_CTRL:
                  begin
                    tmp_read_data[CTRL_ENABLE_BIT] = enable_reg;
                  end

                ADDR_STATUS:
                  begin
                    tmp_read_data[STATUS_VALID_BIT] = entropy_valid;
                  end

                ADDR_ENTROPY:
                  begin
                    tmp_read_data = entropy_data;
                  end

                ADDR_DELTA:
                  begin
                    tmp_read_data = delta;
                  end

                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (address)
            end // else: !if(we)
        end // if (cs)
    end // api_logic

endmodule // avalanche_entropy

//======================================================================
// EOF avalanche_entropy.v
//======================================================================
