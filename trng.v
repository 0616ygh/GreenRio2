//======================================================================
//
// trng.v
// --------
// Top level wrapper for the True Random Number Generator.
//
//
// Author: Joachim Strombergson
// Copyright (c) 2014, NORDUnet A/S
// All rights reserved.
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

module trng(
            // Clock and reset.
            input wire           clk,
            input wire           reset_n,

            input wire           avalanche_noise,

            input wire           cs,
            input wire           we,
            input wire  [11 : 0] address,
            input wire  [31 : 0] write_data,
            output wire [31 : 0] read_data,
            output wire          error,

            output wire  [7 : 0] debug,
            input wire           debug_update,

            output wire          security_error
           );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam TRNG_PREFIX             = 4'h0;
  localparam ENTROPY1_PREFIX         = 4'h1;
  localparam ENTROPY2_PREFIX         = 4'h2;
  localparam MIXER_PREFIX            = 4'h3;
  localparam CSPRNG_PREFIX           = 4'h4;

  localparam DEBUG_ENTROPY0          = 3'h0;
  localparam DEBUG_ENTROPY1          = 3'h1;
  localparam DEBUG_ENTROPY2          = 3'h2;
  localparam DEBUG_MIXER             = 3'h3;
  localparam DEBUG_CSPRNG            = 3'h4;

  localparam ADDR_NAME0              = 8'h00;
  localparam ADDR_NAME1              = 8'h01;
  localparam ADDR_VERSION            = 8'h02;

  localparam ADDR_TRNG_CTRL          = 8'h08;
  localparam TRNG_CTRL_DISCARD_BIT   = 0;
  localparam TRNG_CTRL_TEST_MODE_BIT = 1;

  localparam ADDR_TRNG_STATUS        = 8'h09;

  localparam ADDR_DEBUG_CTRL         = 8'h12;
  localparam ADDR_DEBUG_DELAY        = 8'h13;

  localparam TRNG_NAME0              = 32'h74726e67; // "trng"
  localparam TRNG_NAME1              = 32'h20202020; // "    "
  localparam TRNG_VERSION            = 32'h302e3531; // "0.51"

  // 20x/s @ 50 MHz.
  localparam DEFAULT_DEBUG_DELAY     = 32'h002625a0;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg discard_reg;
  reg discard_new;

  reg test_mode_reg;
  reg test_mode_new;
  reg test_mode_we;

  reg [7 : 0] debug_out_reg;
  reg         debug_out_we;

  reg [2 : 0] debug_mux_reg;
  reg [2 : 0] debug_mux_new;
  reg         debug_mux_we;

  reg [31 : 0] debug_delay_ctr_reg;
  reg [31 : 0] debug_delay_ctr_new;
  reg          debug_delay_ctr_we;

  reg [31 : 0] debug_delay_reg;
  reg [31 : 0] debug_delay_new;
  reg          debug_delay_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  wire           trng_api_cs = cs && (addr_core_num == TRNG_PREFIX);
  wire           trng_api_we = we;
  reg [31 : 0]   trng_api_read_data;
  reg            trng_api_error;

  wire           mixer_more_seed;
  wire [511 : 0] mixer_seed_data;
  wire           mixer_seed_syn;
  wire           mixer_seed_ack;
  wire           mixer_api_cs = cs && (addr_core_num == MIXER_PREFIX);
  wire           mixer_api_we = we;
  wire [31 : 0]  mixer_api_read_data;
  wire           mixer_api_error;
  wire           mixer_security_error;
  wire [7 : 0]   mixer_debug;
  reg            mixer_debug_update;

  wire           csprng_more_seed;
  wire           csprng_seed_ack;
  wire           csprng_api_cs = cs && (addr_core_num == CSPRNG_PREFIX);
  wire           csprng_api_we = we;
  wire [31 : 0]  csprng_api_read_data;
  wire           csprng_api_error;
  wire [7 : 0]   csprng_debug;
  reg            csprng_debug_update;
  wire           csprng_security_error;

  wire           entropy0_entropy_enabled;
  wire [31 : 0]  entropy0_entropy_data;
  wire           entropy0_entropy_syn;
  wire           entropy0_entropy_ack;

  wire           entropy1_api_cs = cs && (addr_core_num == ENTROPY1_PREFIX);
  wire           entropy1_api_we = we;
  wire [31 : 0]  entropy1_api_read_data;
  wire           entropy1_api_error;
  wire           entropy1_entropy_enabled;
  wire [31 : 0]  entropy1_entropy_data;
  wire           entropy1_entropy_syn;
  wire           entropy1_entropy_ack;
  //wire           entropy1_test_mode;
  wire [7 : 0]   entropy1_debug;
  reg            entropy1_debug_update;
  wire           entropy1_security_error;

  wire           entropy2_api_cs = cs && (addr_core_num == ENTROPY2_PREFIX);
  wire           entropy2_api_we = we;
  wire [31 : 0]  entropy2_api_read_data;
  wire           entropy2_api_error;
  wire           entropy2_entropy_enabled;
  wire [31 : 0]  entropy2_entropy_data;
  wire           entropy2_entropy_syn;
  wire           entropy2_entropy_ack;
  //wire           entropy2_test_mode;
  wire [7 : 0]   entropy2_debug;
  reg            entropy2_debug_update;
  wire           entropy2_security_error;

  wire [7 : 0]   api_address = addr_core_reg;
  reg [31 : 0]   tmp_read_data;
  reg            tmp_error;
  reg [7 : 0]    tmp_debug;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data      = tmp_read_data;
  assign error          = tmp_error;
  assign security_error = entropy1_security_error | entropy2_security_error;
  assign debug          = debug_out_reg;

  // Patches to get our first version to work.
  assign entropy0_entropy_enabled = 0;
  assign entropy0_entropy_syn     = 0;
  assign entropy0_entropy_data    = 32'h00000000;


  //----------------------------------------------------------------
  // Address Decoder
  //----------------------------------------------------------------
  // upper 4 bits specify core being addressed.
  wire [3 : 0] addr_core_num = address[11 : 8];

  // lower 8 bits specify register offset in core.
  wire [7 : 0] addr_core_reg = address[7 : 0];


  //----------------------------------------------------------------
  // core instantiations.
  //----------------------------------------------------------------
  trng_mixer mixer_inst(
                        .clk(clk),
                        .reset_n(reset_n),

                        .cs(mixer_api_cs),
                        .we(mixer_api_we),
                        .address(api_address),
                        .write_data(write_data),
                        .read_data(mixer_api_read_data),
                        .error(mixer_api_error),

                        .discard(discard_reg),
                        .test_mode(test_mode_reg),
                        .security_error(mixer_security_error),

                        .more_seed(csprng_more_seed),

                        .entropy0_enabled(entropy0_entropy_enabled),
                        .entropy0_syn(entropy0_entropy_syn),
                        .entropy0_data(entropy0_entropy_data),
                        .entropy0_ack(entropy0_entropy_ack),

                        .entropy1_enabled(entropy1_entropy_enabled),
                        .entropy1_syn(entropy1_entropy_syn),
                        .entropy1_data(entropy1_entropy_data),
                        .entropy1_ack(entropy1_entropy_ack),

                        .entropy2_enabled(entropy2_entropy_enabled),
                        .entropy2_syn(entropy2_entropy_syn),
                        .entropy2_data(entropy2_entropy_data),
                        .entropy2_ack(entropy2_entropy_ack),

                        .seed_data(mixer_seed_data),
                        .seed_syn(mixer_seed_syn),
                        .seed_ack(csprng_seed_ack),

                        .debug(mixer_debug),
                        .debug_update(mixer_debug_update)
                       );

  trng_csprng csprng_inst(
                          .clk(clk),
                          .reset_n(reset_n),

                          .cs(csprng_api_cs),
                          .we(csprng_api_we),
                          .address(api_address),
                          .write_data(write_data),
                          .read_data(csprng_api_read_data),
                          .error(csprng_api_error),

                          .discard(discard_reg),
                          .test_mode(test_mode_reg),
                          .security_error(csprng_security_error),

                          .more_seed(csprng_more_seed),

                          .seed_data(mixer_seed_data),
                          .seed_syn(mixer_seed_syn),
                          .seed_ack(csprng_seed_ack),

                          .debug(csprng_debug),
                          .debug_update(csprng_debug_update)
                         );

  avalanche_entropy entropy1(
                             .clk(clk),
                             .reset_n(reset_n),

                             .noise(avalanche_noise),

                             .cs(entropy1_api_cs),
                             .we(entropy1_api_we),
                             .address(api_address),
                             .write_data(write_data),
                             .read_data(entropy1_api_read_data),
                             .error(entropy1_api_error),

                             .discard(discard_reg),
                             .test_mode(test_mode_reg),
                             .security_error(entropy1_security_error),

                             .entropy_enabled(entropy1_entropy_enabled),
                             .entropy_data(entropy1_entropy_data),
                             .entropy_valid(entropy1_entropy_syn),
                             .entropy_ack(entropy1_entropy_ack),

                             .debug(entropy1_debug),
                             .debug_update(entropy1_debug_update)
                            );

  rosc_entropy entropy2(
                        .clk(clk),
                        .reset_n(reset_n),

                        .cs(entropy2_api_cs),
                        .we(entropy2_api_we),
                        .address(api_address),
                        .write_data(write_data),
                        .read_data(entropy2_api_read_data),
                        .error(entropy2_api_error),

                        .discard(discard_reg),
                        .test_mode(test_mode_reg),
                        .security_error(entropy2_security_error),

                        .entropy_enabled(entropy2_entropy_enabled),
                        .entropy_data(entropy2_entropy_data),
                        .entropy_valid(entropy2_entropy_syn),
                        .entropy_ack(entropy2_entropy_ack),

                        .debug(entropy2_debug),
                        .debug_update(entropy2_debug_update)
                       );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with asynchronous
  // active low reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          discard_reg            <= 1'h0;
          test_mode_reg          <= 1'h0;
          debug_mux_reg          <= DEBUG_CSPRNG;
          debug_delay_reg        <= DEFAULT_DEBUG_DELAY;
          debug_delay_ctr_reg    <= 32'h00000000;
          debug_out_reg          <= 8'h0;
        end
      else
        begin
          discard_reg            <= discard_new;
          debug_delay_ctr_reg    <= debug_delay_ctr_new;

          if (debug_out_we)
            debug_out_reg <= tmp_debug;

          if (test_mode_we)
            test_mode_reg <= test_mode_new;

          if (debug_mux_we)
            debug_mux_reg <= debug_mux_new;

          if (debug_delay_we)
            debug_delay_reg <= debug_delay_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // core_mux
  //
  // This is a simple decoder that looks at the top 4 bits of
  // the given api address and selects which of the sub modules
  // or the top level mux that gets to handle any API
  // operations.
  //----------------------------------------------------------------
  always @*
    begin : core_mux
      case (address[11 : 8])
        TRNG_PREFIX:
          begin
            tmp_read_data = trng_api_read_data;
            tmp_error     = trng_api_error;
          end

        ENTROPY1_PREFIX:
          begin
            tmp_read_data   = entropy1_api_read_data;
            tmp_error       = entropy1_api_error;
          end

        ENTROPY2_PREFIX:
          begin
            tmp_read_data   = entropy2_api_read_data;
            tmp_error       = entropy2_api_error;
          end

        MIXER_PREFIX:
          begin
            tmp_read_data = mixer_api_read_data;
            tmp_error     = mixer_api_error;
          end

        CSPRNG_PREFIX:
          begin
            tmp_read_data = csprng_api_read_data;
            tmp_error     = csprng_api_error;
          end

        default:
          begin
            tmp_read_data = {32{1'b0}};
            tmp_error     = 0;
          end
      endcase // case (address[11 : 8])
    end // core_mux


  //----------------------------------------------------------------
  // debug_update_logic
  //
  // Debug update counter and update logic.
  //----------------------------------------------------------------
  always @*
    begin : debug_update_logic
      if (debug_delay_ctr_reg == debug_delay_reg)
        begin
          debug_out_we        = 1;
          debug_delay_ctr_new = 32'h00000000;
        end
      else
        begin
          debug_out_we        = 0;
          debug_delay_ctr_new = debug_delay_ctr_reg + 1'b1;
        end
    end // debug_update


  //----------------------------------------------------------------
  // debug_mux
  //
  // Select which of the sub modules that are connected to
  // the debug port.
  //----------------------------------------------------------------
  always @*
    begin : debug_mux
      entropy1_debug_update = 0;
      entropy2_debug_update = 0;
      mixer_debug_update    = 0;
      csprng_debug_update   = 0;

      tmp_debug = 8'h00;

      case(debug_mux_reg)
        DEBUG_ENTROPY1:
          begin
            entropy1_debug_update = debug_update;
            tmp_debug             = entropy1_debug;
          end

        DEBUG_ENTROPY2:
          begin
            entropy2_debug_update = debug_update;
            tmp_debug             = entropy2_debug;
          end

        DEBUG_MIXER:
          begin
            mixer_debug_update = debug_update;
            tmp_debug          = mixer_debug;
          end

        DEBUG_CSPRNG:
          begin
            csprng_debug_update = debug_update;
            tmp_debug           = csprng_debug;
          end

        default:
          begin

          end
      endcase // case (debug_mux_reg)
    end // debug_mux


  //----------------------------------------------------------------
  // trng_api_logic
  //
  // Implementation of the top level api logic.
  //----------------------------------------------------------------
  always @*
    begin : trng_api_logic
      discard_new            = 0;
      test_mode_new          = 0;
      test_mode_we           = 0;
      debug_mux_new          = 3'h0;
      debug_mux_we           = 0;
      debug_delay_new        = 32'h00000000;
      debug_delay_we         = 0;
      trng_api_read_data     = 32'h00000000;
      trng_api_error         = 0;

      if (trng_api_cs)
        begin
          if (trng_api_we)
            begin
              case (api_address)
                ADDR_TRNG_CTRL:
                  begin
                    discard_new   = write_data[TRNG_CTRL_DISCARD_BIT];
                    test_mode_new = write_data[TRNG_CTRL_TEST_MODE_BIT];
                    test_mode_we  = 1;
                  end

                ADDR_DEBUG_CTRL:
                  begin
                    debug_mux_new = write_data[2 : 0];
                    debug_mux_we  = 1;
                  end

                ADDR_DEBUG_DELAY:
                  begin
                    debug_delay_new = write_data;
                    debug_delay_we  = 1;
                  end

                default:
                  trng_api_error = 1;
              endcase // case (address)
            end // if (we)

          else
            begin
              case (api_address)
                ADDR_NAME0:
                  trng_api_read_data = TRNG_NAME0;

                ADDR_NAME1:
                  trng_api_read_data = TRNG_NAME1;

                ADDR_VERSION:
                  trng_api_read_data = TRNG_VERSION;

                ADDR_TRNG_CTRL:
                  trng_api_read_data = {30'h0000000, test_mode_reg, discard_reg};

                ADDR_TRNG_STATUS:
                  begin
                    // No error caused by reading status.
                  end

                ADDR_DEBUG_CTRL:
                  trng_api_read_data = {29'h0000000, debug_mux_new};

                ADDR_DEBUG_DELAY:
                  trng_api_read_data = debug_delay_reg;

                default:
                  trng_api_error = 1;
              endcase // case (address)
            end
        end
    end // trng_api_logic
endmodule // trng

//======================================================================
// EOF trng.v
//======================================================================
