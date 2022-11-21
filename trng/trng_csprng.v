//======================================================================
//
// trng_csprng.v
// -------------
// CSPRNG for the TRNG.
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

module trng_csprng(
                   // Clock and reset.
                   input wire           clk,
                   input wire           reset_n,

                   input wire           cs,
                   input wire           we,
                   input wire  [7 : 0]  address,
                   input wire  [31 : 0] write_data,
                   output wire [31 : 0] read_data,
                   output wire          error,

                   input wire           discard,
                   input wire           test_mode,
                   output wire          more_seed,
                   output wire          security_error,

                   input [511 : 0]      seed_data,
                   input wire           seed_syn,
                   output wire          seed_ack,

                   output wire [7 : 0]  debug,
                   input wire           debug_update
                  );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam ADDR_NAME0            = 8'h00;
  localparam ADDR_NAME1            = 8'h01;
  localparam ADDR_VERSION          = 8'h02;

  localparam ADDR_CTRL             = 8'h08;
  localparam CTRL_ENABLE_BIT       = 0;
  localparam CTRL_SEED_BIT         = 1;

  localparam ADDR_STATUS           = 8'h09;
  localparam STATUS_RND_VALID_BIT  = 1;

  localparam ADDR_STAT_BLOCKS_LOW  = 8'h14;
  localparam ADDR_STAT_BLOCKS_HIGH = 8'h15;
  localparam ADDR_STAT_RESEEDS     = 8'h16;

  localparam ADDR_RND_DATA         = 8'h20;

  localparam ADDR_NUM_ROUNDS       = 8'h40;
  localparam ADDR_NUM_BLOCKS_LOW   = 8'h41;
  localparam ADDR_NUM_BLOCKS_HIGH  = 8'h42;

  localparam ADDR_TEST_SEED_W00    = 8'h80;
  localparam ADDR_TEST_SEED_W01    = 8'h81;
  localparam ADDR_TEST_SEED_W02    = 8'h82;
  localparam ADDR_TEST_SEED_W03    = 8'h83;
  localparam ADDR_TEST_SEED_W04    = 8'h84;
  localparam ADDR_TEST_SEED_W05    = 8'h85;
  localparam ADDR_TEST_SEED_W06    = 8'h86;
  localparam ADDR_TEST_SEED_W07    = 8'h87;
  localparam ADDR_TEST_SEED_W08    = 8'h88;
  localparam ADDR_TEST_SEED_W09    = 8'h89;
  localparam ADDR_TEST_SEED_W10    = 8'h8a;
  localparam ADDR_TEST_SEED_W11    = 8'h8b;
  localparam ADDR_TEST_SEED_W12    = 8'h8c;
  localparam ADDR_TEST_SEED_W13    = 8'h8d;
  localparam ADDR_TEST_SEED_W14    = 8'h8e;
  localparam ADDR_TEST_SEED_W15    = 8'h8f;

  localparam CIPHER_KEYLEN256  = 1'b1; // 256 bit key.
  localparam CIPHER_MAX_BLOCKS = 64'h0000000100000000;

  localparam CTRL_IDLE   = 4'h0;
  localparam CTRL_SEED0  = 4'h1;
  localparam CTRL_NSYN   = 4'h2;
  localparam CTRL_SEED1  = 4'h3;
  localparam CTRL_INIT0  = 4'h4;
  localparam CTRL_INIT1  = 4'h5;
  localparam CTRL_NEXT0  = 4'h6;
  localparam CTRL_NEXT1  = 4'h7;
  localparam CTRL_MORE   = 4'h8;
  localparam CTRL_CANCEL = 4'hf;

  localparam DEFAULT_NUM_ROUNDS = 5'h18;
  localparam DEFAULT_NUM_BLOCKS = 64'h0000000001000000;

  parameter CORE_NAME0     = 32'h63737072; // "cspr"
  parameter CORE_NAME1     = 32'h6e672020; // "ng  "
  parameter CORE_VERSION   = 32'h302e3530; // "0.50"


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [255 : 0] cipher_key_reg;
  reg [255 : 0] cipher_key_new;
  reg           cipher_key_we;

  reg [63 : 0]  cipher_iv_reg;
  reg [63 : 0]  cipher_iv_new;
  reg           cipher_iv_we;

  reg [63 : 0]  cipher_ctr_reg;
  reg [63 : 0]  cipher_ctr_new;
  reg           cipher_ctr_we;

  reg [511 : 0] cipher_block_reg;
  reg [511 : 0] cipher_block_new;
  reg           cipher_block_we;

  reg [63 : 0]  block_ctr_reg;
  reg [63 : 0]  block_ctr_new;
  reg           block_ctr_inc;
  reg           block_ctr_rst;
  reg           block_ctr_we;
  reg           block_ctr_max;

  reg [63 : 0]  block_stat_ctr_reg;
  reg [63 : 0]  block_stat_ctr_new;
  reg           block_stat_ctr_we;

  reg [31 : 0]  reseed_stat_ctr_reg;
  reg [31 : 0]  reseed_stat_ctr_new;
  reg           reseed_stat_ctr_inc;
  reg           reseed_stat_ctr_we;

  reg           ready_reg;
  reg           ready_new;
  reg           ready_we;

  reg           more_seed_reg;
  reg           more_seed_new;

  reg           seed_ack_reg;
  reg           seed_ack_new;

  reg           enable_reg;
  reg           enable_new;
  reg           enable_we;

  reg           seed_reg;
  reg           seed_new;

  reg [4 : 0]   num_rounds_reg;
  reg [4 : 0]   num_rounds_new;
  reg           num_rounds_we;

  reg [31 : 0]  num_blocks_low_reg;
  reg [31 : 0]  num_blocks_low_new;
  reg           num_blocks_low_we;

  reg [31 : 0]  num_blocks_high_reg;
  reg [31 : 0]  num_blocks_high_new;
  reg           num_blocks_high_we;

  reg [3 : 0]   csprng_ctrl_reg;
  reg [3 : 0]   csprng_ctrl_new;
  reg           csprng_ctrl_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg            tmp_error;

  reg            cipher_init;
  reg            cipher_next;

  wire [511 : 0] cipher_data_out;
  wire           cipher_data_out_valid;
  wire           cipher_ready;

  wire           fifo_more_data;
  reg            fifo_discard;
  wire           rnd_syn;
  wire [31 : 0]  rnd_data;
  reg            rnd_ack;
  reg            fifo_cipher_data_valid;

  wire           muxed_rnd_ack;

  reg [31 : 0]  tmp_read_data;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign read_data      = tmp_read_data;
  assign error          = tmp_error;
  assign seed_ack       = seed_ack_reg;
  assign more_seed      = more_seed_reg;
  assign debug          = rnd_data[7 : 0];
  assign security_error = 0;
  assign muxed_rnd_ack  = rnd_ack | debug_update;


  //----------------------------------------------------------------
  // core instantiation.
  //----------------------------------------------------------------
  chacha_core cipher_inst(
                          .clk(clk),
                          .reset_n(reset_n),

                          .init(cipher_init),
                          .next(cipher_next),

                          .key(cipher_key_reg),
                          .keylen(CIPHER_KEYLEN256),
                          .iv(cipher_iv_reg),
                          .ctr(cipher_ctr_reg),
                          .rounds(num_rounds_reg),

                          .data_in(cipher_block_reg),
                          .ready(cipher_ready),

                          .data_out(cipher_data_out),
                          .data_out_valid(cipher_data_out_valid)
                         );


  trng_csprng_fifo fifo_inst(
                             .clk(clk),
                             .reset_n(reset_n),

                             .csprng_data(cipher_data_out),
                             .csprng_data_valid(fifo_cipher_data_valid),
                             .discard(fifo_discard),
                             .more_data(fifo_more_data),

                             .rnd_syn(rnd_syn),
                             .rnd_data(rnd_data),
                             .rnd_ack(muxed_rnd_ack)
                            );


  //----------------------------------------------------------------
  // reg_update
  //
  // Update functionality for all registers in the core.
  // All registers are positive edge triggered with synchronous
  // active low reset. All registers have write enable.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin
      if (!reset_n)
        begin
          cipher_key_reg      <= 256'h0;
          cipher_iv_reg       <= 64'h0;
          cipher_ctr_reg      <= 64'h0;
          cipher_block_reg    <= 512'h0;
          block_ctr_reg       <= 64'h0;
          block_stat_ctr_reg  <= 64'h0;
          reseed_stat_ctr_reg <= 32'h0;
          more_seed_reg       <= 1'h0;
          seed_ack_reg        <= 1'h0;
          ready_reg           <= 1'h0;
          enable_reg          <= 1'h1;
          seed_reg            <= 1'h0;
          num_rounds_reg      <= DEFAULT_NUM_ROUNDS;
          num_blocks_low_reg  <= DEFAULT_NUM_BLOCKS[31 : 0];
          num_blocks_high_reg <= DEFAULT_NUM_BLOCKS[63 : 32];
          csprng_ctrl_reg     <= CTRL_IDLE;
        end
      else
        begin
          more_seed_reg <= more_seed_new;
          seed_ack_reg  <= seed_ack_new;
          seed_reg      <= seed_new;

          if (enable_we)
            enable_reg <= enable_new;

          if (cipher_key_we)
            cipher_key_reg <= cipher_key_new;

          if (cipher_iv_we)
            cipher_iv_reg <= cipher_iv_new;

          if (cipher_ctr_we)
            cipher_ctr_reg <= cipher_ctr_new;

          if (cipher_block_we)
            cipher_block_reg <= cipher_block_new;

          if (block_ctr_we)
            begin
              block_ctr_reg      <= block_ctr_new;
            end

          if (block_stat_ctr_we)
            begin
              block_stat_ctr_reg <= block_stat_ctr_new;
            end

          if (reseed_stat_ctr_we)
            reseed_stat_ctr_reg <= reseed_stat_ctr_new;

          if (ready_we)
            ready_reg <= ready_new;

          if (csprng_ctrl_we)
            csprng_ctrl_reg <= csprng_ctrl_new;

          if (num_rounds_we)
            num_rounds_reg <= num_rounds_new;

          if (num_blocks_low_we)
            num_blocks_low_reg <= num_blocks_low_new;

          if (num_blocks_high_we)
            num_blocks_high_reg <= num_blocks_high_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // csprng_api_logic
  //----------------------------------------------------------------
  always @*
    begin : csprng_api_logic
      enable_new          = 0;
      enable_we           = 0;
      seed_new            = 0;

      num_rounds_new      = 5'h00;
      num_rounds_we       = 0;

      num_blocks_low_new  = 32'h00000000;
      num_blocks_low_we   = 0;
      num_blocks_high_new = 32'h00000000;
      num_blocks_high_we  = 0;

      rnd_ack             = 0;

      tmp_read_data       = 32'h00000000;
      tmp_error           = 0;

      if (cs)
        begin
          if (we)
            begin
              // Write operations.
              case (address)
                // Write operations.
                ADDR_CTRL:
                  begin
                    enable_new = write_data[CTRL_ENABLE_BIT];
                    enable_we  = 1;
                    seed_new   = write_data[CTRL_SEED_BIT];
                  end

                ADDR_NUM_ROUNDS:
                  begin
                    num_rounds_new = write_data[4 : 0];
                    num_rounds_we  = 1;
                  end

                ADDR_NUM_BLOCKS_LOW:
                  begin
                    num_blocks_low_new = write_data;
                    num_blocks_low_we  = 1;
                  end

                ADDR_NUM_BLOCKS_HIGH:
                  begin
                    num_blocks_high_new = write_data;
                    num_blocks_high_we  = 1;
                  end

                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (address)
            end // if (we)

          else
            begin
              // Read operations.
              case (address)
                // Read operations.
                ADDR_NAME0:
                    tmp_read_data = CORE_NAME0;

                ADDR_NAME1:
                    tmp_read_data = CORE_NAME1;

                ADDR_VERSION:
                    tmp_read_data = CORE_VERSION;

                ADDR_CTRL:
                    tmp_read_data = {30'h00000000, seed_reg, enable_reg};

                ADDR_STATUS:
                    tmp_read_data = {30'h00000000, rnd_syn, ready_reg};

                ADDR_STAT_BLOCKS_LOW:
                  tmp_read_data = block_stat_ctr_reg[31 : 0];

                ADDR_STAT_BLOCKS_HIGH:
                    tmp_read_data = block_stat_ctr_reg[63 : 32];

                ADDR_STAT_RESEEDS:
                    tmp_read_data = reseed_stat_ctr_reg;

                ADDR_RND_DATA:
                  begin
                    tmp_read_data = rnd_data;
                    rnd_ack       = 1;
                  end

                ADDR_NUM_ROUNDS:
                    tmp_read_data = {27'h0000000, num_rounds_reg};

                ADDR_NUM_BLOCKS_LOW:
                    tmp_read_data = num_blocks_low_reg;

                ADDR_NUM_BLOCKS_HIGH:
                    tmp_read_data = num_blocks_high_reg;

                default:
                  begin
                    tmp_error = 1;
                  end
              endcase // case (address)
            end
        end
    end // cspng_api_logic


  //----------------------------------------------------------------
  // block_ctr
  //
  // Logic to implement the block counter. This includes the
  // ability to detect that maximum allowed number of blocks
  // has been reached. Either as defined by the application
  // or the hard coded CIPHER_MAX_BLOCKS value.
  //
  // The stat counter is a sepatate block counter updated in
  // sync with the block counter. It is only used to track the
  // number of blocks generated from the cipher as a metric
  // provided to the system. The stat counter is never reset.
  //----------------------------------------------------------------
  always @*
    begin : block_ctr
      block_ctr_new      = {2{32'h00000000}};
      block_ctr_we       = 1'b0;
      block_ctr_max      = 1'b0;
      block_stat_ctr_new = {2{32'h00000000}};
      block_stat_ctr_we = 1'b0;

      if (block_ctr_rst)
        begin
          block_ctr_new = {2{32'h00000000}};
          block_ctr_we  = 1'b1;
        end

      if (block_ctr_inc)
        begin
          block_ctr_new      = block_ctr_reg + 1'b1;
          block_ctr_we       = 1;
          block_stat_ctr_new = block_stat_ctr_reg + 1'b1;
          block_stat_ctr_we  = 1;
        end

      if ((block_ctr_reg == {num_blocks_high_reg, num_blocks_low_reg}) ||
          (block_ctr_reg == CIPHER_MAX_BLOCKS))
        begin
          block_ctr_max = 1'b1;
        end
    end // block_ctr


  //----------------------------------------------------------------
  // reseed_ctr
  //
  // A simple monotonically increasing counter that counts the
  // number of times the CSPRNG has been reseeded. is reseeded.
  // Note that the counter is 32-bit and it is up to SW to handle
  // wrap around issues.
  //----------------------------------------------------------------
  always @*
    begin : reseed_ctr
      reseed_stat_ctr_new = 32'h00000000;
      reseed_stat_ctr_we  = 0;

      if (reseed_stat_ctr_inc)
        begin
          reseed_stat_ctr_new = reseed_stat_ctr_reg + 1'b1;
          reseed_stat_ctr_we  = 1;
        end
    end // reseed_ctr


  //----------------------------------------------------------------
  // csprng_ctrl_fsm
  //
  // Control FSM for the CSPRNG.
  //----------------------------------------------------------------
  always @*
    begin : csprng_ctrl_fsm
      cipher_key_new         = {8{32'h00000000}};
      cipher_key_we          = 0;
      cipher_iv_new          = {2{32'h00000000}};
      cipher_iv_we           = 0;
      cipher_ctr_new         = {2{32'h00000000}};
      cipher_ctr_we          = 0;
      cipher_block_new       = {16{32'h00000000}};
      cipher_block_we        = 0;
      cipher_init            = 0;
      cipher_next            = 0;
      block_ctr_rst          = 0;
      block_ctr_inc          = 0;
      ready_new              = 0;
      ready_we               = 0;
      seed_ack_new           = 0;
      more_seed_new          = 0;
      fifo_discard           = 0;
      fifo_cipher_data_valid = 0;
      reseed_stat_ctr_inc    = 0;
      csprng_ctrl_new        = CTRL_IDLE;
      csprng_ctrl_we         = 0;

      case (csprng_ctrl_reg)
        CTRL_IDLE:
          begin
            if (!enable_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else if (fifo_more_data)
              begin
                more_seed_new   = 1;
                csprng_ctrl_new = CTRL_SEED0;
                csprng_ctrl_we  = 1;
              end
          end

        CTRL_SEED0:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else if (seed_syn)
              begin
                seed_ack_new     = 1;
                cipher_block_new = seed_data;
                cipher_block_we  = 1;
                csprng_ctrl_new  = CTRL_NSYN;
                csprng_ctrl_we   = 1;
              end
          end

        CTRL_NSYN:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else
              begin
                more_seed_new    = 1;
                csprng_ctrl_new  = CTRL_SEED1;
                csprng_ctrl_we   = 1;
              end
          end

        CTRL_SEED1:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else if (seed_syn)
              begin
                seed_ack_new    = 1;
                cipher_key_new  = seed_data[255 : 0];
                cipher_key_we   = 1;
                cipher_iv_new   = seed_data[319 : 256];
                cipher_iv_we    = 1;
                cipher_ctr_new  = seed_data[383 : 320];
                cipher_ctr_we   = 1;
                csprng_ctrl_new = CTRL_INIT0;
                csprng_ctrl_we  = 1;
              end
            else
              begin
                more_seed_new = 1;
              end
          end

        CTRL_INIT0:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else
              begin
                reseed_stat_ctr_inc = 1;
                cipher_init         = 1;
                block_ctr_rst       = 1;
                csprng_ctrl_new     = CTRL_INIT1;
                csprng_ctrl_we      = 1;
              end
          end

        CTRL_INIT1:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else if (cipher_ready)
              begin
                csprng_ctrl_new = CTRL_NEXT0;
                csprng_ctrl_we  = 1;
              end
          end

        CTRL_NEXT0:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else
              begin
                cipher_next     = 1;
                csprng_ctrl_new = CTRL_NEXT1;
                csprng_ctrl_we  = 1;
              end
          end

        CTRL_NEXT1:
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else if (cipher_ready && cipher_data_out_valid)
              begin
                block_ctr_inc          = 1;
                fifo_cipher_data_valid = 1;
                csprng_ctrl_new        = CTRL_MORE;
                csprng_ctrl_we         = 1;
              end

        CTRL_MORE:
          begin
            if ((!enable_reg) || seed_reg || discard)
              begin
                csprng_ctrl_new = CTRL_CANCEL;
                csprng_ctrl_we  = 1;
              end
            else if (fifo_more_data)
              begin
                if (block_ctr_max)
                  begin
                    more_seed_new   = 1;
                    csprng_ctrl_new = CTRL_SEED0;
                    csprng_ctrl_we  = 1;
                  end
                else
                  begin
                    csprng_ctrl_new = CTRL_NEXT0;
                    csprng_ctrl_we  = 1;
                  end
              end
          end

        CTRL_CANCEL:
          begin
            fifo_discard     = 1;
            cipher_key_new   = {8{32'h00000000}};
            cipher_key_we    = 1;
            cipher_iv_new    = {2{32'h00000000}};
            cipher_iv_we     = 1;
            cipher_ctr_new   = {2{32'h00000000}};
            cipher_ctr_we    = 1;
            cipher_block_new = {16{32'h00000000}};
            cipher_block_we  = 1;
            block_ctr_rst    = 1;
            csprng_ctrl_new  = CTRL_IDLE;
            csprng_ctrl_we   = 1;
          end

        default:
          begin
          end

      endcase // case (cspng_ctrl_reg)
    end // csprng_ctrl_fsm

endmodule // trng_csprng

//======================================================================
// EOF trng_csprng.v
//======================================================================
