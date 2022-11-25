//======================================================================
//
// avalanche_entropy_core.v
// ------------------------
// Core functionality for the entropy provider core based on
// an external avalanche noise based source. (or any other source that
// can toggle a single bit input).
//
// Currently the design consists of a counter running at clock speeed.
// When a positive flank event is detected in the noise source the
// current LSB value of the counter is pushed into a 32bit
// entropy collection shift register.
//
// The core provides functionality to measure the time betwee
// positive flank events counted as number of clock cycles. There
// is also access ports for the collected entropy.
//
// No post-processing is currently performed done on the entropy.
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

module avalanche_entropy_core(
                              input wire           clk,
                              input wire           reset_n,

                              input wire           noise,

                              input wire           enable,

                              output wire          entropy_enabled,
                              output wire [31 : 0] entropy_data,
                              output wire          entropy_valid,
                              input wire           entropy_ack,

                              output wire [31 : 0] delta,

                              output wire [7 : 0]  debug,
                              input wire           debug_update
                             );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  // 1M cycles warmup delay.
  localparam WARMUP_CYCLES    = 24'h0f4240;
  localparam DEBUG_DELAY      = 32'h002c4b40;
  localparam MIN_ENTROPY_BITS = 6'h20;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [23 : 0] warmup_cycle_ctr_reg;
  reg [23 : 0] warmup_cycle_ctr_new;
  reg          warmup_cycle_ctr_we;
  reg          warmup_done;

  reg          noise_sample0_reg;
  reg          noise_sample_reg;

  reg          flank0_reg;
  reg          flank1_reg;

  reg          entropy_bit_reg;

  reg [31 : 0] entropy_reg;
  reg [31 : 0] entropy_new;
  reg          entropy_we;

  reg          entropy_valid_reg;
  reg          entropy_valid_new;

  reg [5 :  0] bit_ctr_reg;
  reg [5 :  0] bit_ctr_new;
  reg          bit_ctr_inc;
  reg          bit_ctr_we;

  reg          enable_reg;

  reg [31 : 0] cycle_ctr_reg;
  reg [31 : 0] cycle_ctr_new;

  reg [31 : 0] delta_reg;
  reg          delta_we;

  reg [31 : 0] debug_delay_ctr_reg;
  reg [31 : 0] debug_delay_ctr_new;
  reg          debug_delay_ctr_we;

  reg [7 : 0]  debug_reg;
  reg          debug_we;

  reg          debug_update_reg;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign entropy_valid   = entropy_valid_reg & warmup_done;
  assign entropy_data    = entropy_reg;
  assign entropy_enabled = enable_reg & warmup_done;

  assign delta           = delta_reg;
  assign debug           = debug_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          noise_sample0_reg    <= 1'h0;
          noise_sample_reg     <= 1'h0;
          flank0_reg           <= 1'h0;
          flank1_reg           <= 1'h0;
          entropy_valid_reg    <= 1'h0;
          entropy_reg          <= 32'h0;
          entropy_bit_reg      <= 1'h0;
          bit_ctr_reg          <= 6'h0;
          cycle_ctr_reg        <= 32'h0;
          delta_reg            <= 32'h0;
          debug_delay_ctr_reg  <= 32'h0;
          warmup_cycle_ctr_reg <= WARMUP_CYCLES;
          debug_reg            <= 8'h0;
          debug_update_reg     <= 1'h0;
          enable_reg           <= 1'h0;
        end
      else
        begin
          noise_sample0_reg <= noise;
          noise_sample_reg  <= noise_sample0_reg;

          flank0_reg        <= noise_sample_reg;
          flank1_reg        <= flank0_reg;

          entropy_valid_reg <= entropy_valid_new;
          entropy_bit_reg   <= ~entropy_bit_reg;
          cycle_ctr_reg     <= cycle_ctr_new;

          debug_update_reg  <= debug_update;

          enable_reg        <= enable;

          if (warmup_cycle_ctr_we)
            warmup_cycle_ctr_reg <= warmup_cycle_ctr_new;

          if (delta_we)
            begin
              delta_reg <= cycle_ctr_reg;
            end

          if (bit_ctr_we)
            begin
              bit_ctr_reg <= bit_ctr_new;
            end

          if (entropy_we)
            begin
              entropy_reg <= entropy_new;
            end

          if (debug_delay_ctr_we)
            begin
              debug_delay_ctr_reg <= debug_delay_ctr_new;
            end

          if (debug_we)
            begin
              debug_reg <= entropy_reg[7 : 0];
            end
        end
    end // reg_update


  //----------------------------------------------------------------
  // debug_out
  //
  // Logic that updates the debug port.
  //----------------------------------------------------------------
  always @*
    begin : debug_out
      debug_delay_ctr_new = 32'h00000000;
      debug_delay_ctr_we  = 0;
      debug_we            = 0;

      if (debug_update_reg)
        begin
          debug_delay_ctr_new = debug_delay_ctr_reg + 1'b1;
          debug_delay_ctr_we  = 1;
        end

      if (debug_delay_ctr_reg == DEBUG_DELAY)
        begin
          debug_delay_ctr_new = 32'h00000000;
          debug_delay_ctr_we  = 1;
          debug_we            = 1;
        end
    end


  //----------------------------------------------------------------
  // warmup_ctr
  //
  // Logic for the warmup counter. This counter starts
  // decreasing when reset lifts and decreases until reaching zero.
  // At zero the counter stops and asserts warmup_done.
  //----------------------------------------------------------------
  always @*
    begin : warmup_ctr
      if (warmup_cycle_ctr_reg == 0)
        begin
          warmup_cycle_ctr_new = 24'h000000;
          warmup_cycle_ctr_we  = 0;
          warmup_done          = 1;
        end
      else
        begin
          warmup_cycle_ctr_new = warmup_cycle_ctr_reg - 1'b1;
          warmup_cycle_ctr_we  = 1;
          warmup_done          = 0;
        end
    end


  //----------------------------------------------------------------
  // entropy_collect
  //
  // We collect entropy by adding the current state of the
  // entropy bit register the entropy shift register every time
  // we detect a positive flank in the noise source.
  //----------------------------------------------------------------
  always @*
    begin : entropy_collect
      entropy_new   = 32'h00000000;
      entropy_we    = 1'b0;
      bit_ctr_inc   = 1'b0;

      if ((flank0_reg) && (!flank1_reg))
        begin
          entropy_new   = {entropy_reg[30 : 0], entropy_bit_reg};
          entropy_we    = 1'b1;
          bit_ctr_inc   = 1'b1;
        end
    end // entropy_collect


  //----------------------------------------------------------------
  // delta_logic
  //
  // The logic implements the delta time measuerment system.
  //----------------------------------------------------------------
  always @*
    begin : delta_logic
      cycle_ctr_new      = cycle_ctr_reg + 1'b1;
      delta_we           = 1'b0;

      if ((flank0_reg) && (!flank1_reg))
        begin
          cycle_ctr_new = 32'h00000000;
          delta_we      = 1'b1;
        end
    end // delta_logic


  //----------------------------------------------------------------
  // entropy_ack_logic
  //
  // The logic needed to handle detection that entropy has been
  // read and ensure that we collect more than 32 entropy
  // bits beforeproviding more entropy.
  //----------------------------------------------------------------
  always @*
    begin : entropy_ack_logic
      bit_ctr_new       = 6'h00;
      bit_ctr_we        = 1'b0;
      entropy_valid_new = 1'b0;

      if (bit_ctr_reg == MIN_ENTROPY_BITS)
        begin
          entropy_valid_new = 1'b1;
        end

      if ((bit_ctr_inc) && (bit_ctr_reg < 6'h20))
        begin
          bit_ctr_new = bit_ctr_reg + 1'b1;
          bit_ctr_we  = 1'b1;
        end
      else if (entropy_ack)
        begin
          bit_ctr_new = 6'h00;
          bit_ctr_we  = 1'b1;
        end
      end // entropy_ack_logic

endmodule 