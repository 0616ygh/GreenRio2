//======================================================================
//
// trng_csprng_fifo.v
// ------------------
// Output FIFO for the CSPRNG in the TRNG.
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

module trng_csprng_fifo(
                        // Clock and reset.
                        input wire           clk,
                        input wire           reset_n,

                        input wire [511 : 0] csprng_data,
                        input wire           csprng_data_valid,
                        input wire           discard,
                        output wire          more_data,

                        output wire          rnd_syn,
                        output wire [31 : 0] rnd_data,
                        input wire           rnd_ack
                       );


  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  localparam FIFO_ADDR_BITS = 2;
  localparam FIFO_ADDR_MAX  = (2**FIFO_ADDR_BITS) - 1;
  localparam FIFO_MAX       = (2 ** FIFO_ADDR_BITS);

  localparam WR_IDLE    = 0;
  localparam WR_WAIT    = 1;
  localparam WR_NEXT    = 2;
  localparam WR_DISCARD = 7;

  localparam RD_IDLE    = 0;
  localparam RD_ACK     = 1;
  localparam RD_DISCARD = 7;


  //----------------------------------------------------------------
  // Registers including update variables and write enable.
  //----------------------------------------------------------------
  reg [511 : 0] fifo_mem [0 : FIFO_ADDR_MAX];
  reg           fifo_mem_we;

  reg [3 : 0] mux_data_ptr_reg;
  reg [3 : 0] mux_data_ptr_new;
  reg         mux_data_ptr_inc;
  reg         mux_data_ptr_rst;
  reg         mux_data_ptr_we;

  reg [(FIFO_ADDR_BITS - 1) : 0] rd_ptr_reg;
  reg [(FIFO_ADDR_BITS - 1) : 0] rd_ptr_new;
  reg                            rd_ptr_inc;
  reg                            rd_ptr_rst;
  reg                            rd_ptr_we;

  reg [(FIFO_ADDR_BITS - 1) : 0] wr_ptr_reg;
  reg [(FIFO_ADDR_BITS - 1) : 0] wr_ptr_new;
  reg                            wr_ptr_inc;
  reg                            wr_ptr_rst;
  reg                            wr_ptr_we;

  reg [FIFO_ADDR_BITS : 0]       fifo_ctr_reg;
  reg [FIFO_ADDR_BITS : 0]       fifo_ctr_new;
  reg                            fifo_ctr_inc;
  reg                            fifo_ctr_dec;
  reg                            fifo_ctr_rst;
  reg                            fifo_ctr_we;
  reg                            fifo_empty;
  reg                            fifo_full;

  reg [31 : 0] rnd_data_reg;

  reg          rnd_syn_reg;
  reg          rnd_syn_new;
  reg          rnd_syn_we;

  reg [2 : 0]  rd_ctrl_reg;
  reg [2 : 0]  rd_ctrl_new;
  reg          rd_ctrl_we;

  reg [2 : 0]  wr_ctrl_reg;
  reg [2 : 0]  wr_ctrl_new;
  reg          wr_ctrl_we;

  reg          more_data_reg;
  reg          more_data_new;
  reg          more_data_we;


  //----------------------------------------------------------------
  // Wires.
  //----------------------------------------------------------------
  reg [31 : 0] muxed_data;


  //----------------------------------------------------------------
  // Concurrent connectivity for ports etc.
  //----------------------------------------------------------------
  assign rnd_data  = rnd_data_reg;
  assign rnd_syn   = rnd_syn_reg;
  assign more_data = more_data_reg;


  //----------------------------------------------------------------
  // reg_update
  //
  // Register update. All registers have asynchronous reset.
  //----------------------------------------------------------------
  always @ (posedge clk or negedge reset_n)
    begin : reg_update
      integer i;

      if (!reset_n)
        begin
          for (i = 0 ; i < FIFO_MAX ; i = i + 1)
            fifo_mem[i] <= 512'h0;

          mux_data_ptr_reg <= 4'h0;
          rd_ptr_reg       <= {(FIFO_ADDR_BITS){1'h0}};
          wr_ptr_reg       <= {(FIFO_ADDR_BITS){1'h0}};
          fifo_ctr_reg     <= {FIFO_ADDR_BITS{1'h0}};
          rnd_data_reg     <= 32'h0;
          rnd_syn_reg      <= 1'h0;
          more_data_reg    <= 1'h0;
          wr_ctrl_reg      <= WR_IDLE;
          rd_ctrl_reg      <= RD_IDLE;
        end
      else
        begin
          rnd_data_reg <= muxed_data;

          if (more_data_we)
            more_data_reg <= more_data_new;

          if (rnd_syn_we)
            rnd_syn_reg <= rnd_syn_new;

          if (fifo_mem_we)
            fifo_mem[wr_ptr_reg] <= csprng_data;

          if (mux_data_ptr_we)
            mux_data_ptr_reg <= mux_data_ptr_new;

          if (rd_ptr_we)
            rd_ptr_reg <= rd_ptr_new;

          if (wr_ptr_we)
            wr_ptr_reg <= wr_ptr_new;

          if (fifo_ctr_we)
            fifo_ctr_reg <= fifo_ctr_new;

          if (rd_ctrl_we)
            rd_ctrl_reg <= rd_ctrl_new;

          if (wr_ctrl_we)
            wr_ctrl_reg <= wr_ctrl_new;
        end
    end // reg_update


  //----------------------------------------------------------------
  // output_data_mux
  //
  // Logic that reads out a 512 bit word from the fifo memory
  // and then selects a 32-bit word as output data.
  //----------------------------------------------------------------
  always @*
    begin : output_data_mux
      reg [511 : 0] fifo_rd_data;

      fifo_rd_data = fifo_mem[rd_ptr_reg];
      muxed_data = fifo_rd_data[mux_data_ptr_reg * 32 +: 32];
    end // output_data_mux


  //----------------------------------------------------------------
  // mux_data_ptr
  //
  // Pointer for selecting output data word from the 512 bit
  // word currently being read in the FIFO.
  //----------------------------------------------------------------
  always @*
    begin : mux_data_ptr
      mux_data_ptr_new = 4'h0;
      mux_data_ptr_we  = 0;

      if (mux_data_ptr_rst)
        begin
          mux_data_ptr_new = 4'h0;
          mux_data_ptr_we  = 1;
        end

      if (mux_data_ptr_inc)
        begin
          mux_data_ptr_new = mux_data_ptr_reg + 1'b1;
          mux_data_ptr_we  = 1;
        end
    end // mux_data_ptr


  //----------------------------------------------------------------
  // fifo_rd_ptr
  //
  // Pointer that selects the current 512 bit word in the FIFO
  // to extract data from.
  //----------------------------------------------------------------
  always @*
    begin : fifo_rd_ptr
      rd_ptr_new   = {FIFO_ADDR_BITS{1'b0}};
      rd_ptr_we    = 0;
      fifo_ctr_dec = 0;

      if (rd_ptr_rst)
        begin
          rd_ptr_new = {FIFO_ADDR_BITS{1'b0}};
          rd_ptr_we  = 1;
        end

      if (rd_ptr_inc)
        begin
          fifo_ctr_dec = 1;
          rd_ptr_new   = rd_ptr_reg + 1'b1;
          rd_ptr_we    =  1;
        end
    end // fifo_rd_ptr


  //----------------------------------------------------------------
  // fifo_wr_ptr
  //
  // Pointer to where to store a new 512 bit word in the FIFO.
  //----------------------------------------------------------------
  always @*
    begin : fifo_wr_ptr
      wr_ptr_new   = {FIFO_ADDR_BITS{1'b0}};
      wr_ptr_we    = 0;
      fifo_ctr_inc = 0;

      if (wr_ptr_rst)
        begin
          wr_ptr_new   = {FIFO_ADDR_BITS{1'b0}};
          wr_ptr_we    = 1;
        end

      if (wr_ptr_inc)
        begin
          fifo_ctr_inc = 1;
          wr_ptr_new   = wr_ptr_reg + 1'b1;
          wr_ptr_we    = 1;
        end
    end // fifo_wr_ptr


  //----------------------------------------------------------------
  // fifo_ctr
  //
  // fifo counter tracks the number of 512 bit elements currently
  // in the fifp. The counter also signals the csprng when more
  // data is needed. The fifo also signals applications when
  // random numbers are available, that is there is at least
  // one elemnt in the fifo with 32-bit words not yet used.
  //----------------------------------------------------------------
  always @*
    begin : fifo_ctr
      fifo_ctr_new  = {(FIFO_ADDR_BITS + 1){1'b0}};
      fifo_ctr_we   = 0;
      fifo_empty    = 0;
      fifo_full     = 0;

      if (fifo_ctr_reg == 0)
        begin
          fifo_empty = 1;
        end

      if (fifo_ctr_reg == FIFO_MAX)
        begin
          fifo_full = 1;
        end

      if (fifo_ctr_rst)
        begin
          fifo_ctr_new  = {(FIFO_ADDR_BITS + 1){1'b0}};
          fifo_ctr_we = 1;
        end

      if (fifo_ctr_inc)
        begin
          fifo_ctr_new = fifo_ctr_reg + 1'b1;
          fifo_ctr_we  = 1;
        end

      if (fifo_ctr_dec)
        begin
          fifo_ctr_new = fifo_ctr_reg - 1'b1;
          fifo_ctr_we  = 1;
        end
    end // fifo_ctr


  //----------------------------------------------------------------
  // rd_ctrl
  //
  // Control FSM for reading data as requested by the consumers.
  //----------------------------------------------------------------
  always @*
    begin : rd_ctrl
      mux_data_ptr_rst = 0;
      mux_data_ptr_inc = 0;
      rnd_syn_new      = 0;
      rnd_syn_we       = 0;
      rd_ptr_inc       = 0;
      rd_ptr_rst       = 0;
      rd_ctrl_new      = RD_IDLE;
      rd_ctrl_we       = 0;

      case (rd_ctrl_reg)
        RD_IDLE:
          begin
            if (discard)
              begin
                rd_ctrl_new = RD_DISCARD;
                rd_ctrl_we  = 1;
              end
            else
              begin
                if (!fifo_empty)
                  begin
                    rnd_syn_new = 1;
                    rnd_syn_we  = 1;
                    rd_ctrl_new = RD_ACK;
                    rd_ctrl_we  = 1;
                  end
              end
          end

        RD_ACK:
          begin
            if (discard)
              begin
                rd_ctrl_new = RD_DISCARD;
                rd_ctrl_we  = 1;
              end
            else
              begin
                if (rnd_ack)
                  begin
                    if (mux_data_ptr_reg == 4'hf)
                      begin
                        rd_ptr_inc       = 1;
                        mux_data_ptr_rst = 1;
                      end
                    else
                      begin
                        mux_data_ptr_inc = 1;
                      end
                    rnd_syn_new  = 0;
                    rnd_syn_we   = 1;
                    rd_ctrl_new  = RD_IDLE;
                    rd_ctrl_we   = 1;
                  end
              end
          end

        RD_DISCARD:
          begin
            rnd_syn_new = 0;
            rnd_syn_we  = 1;
            rd_ptr_rst  = 1;
            rd_ctrl_new = RD_IDLE;
            rd_ctrl_we  = 1;
          end

      endcase // case (rd_ctrl_reg)
    end // rd_ctrl


  //----------------------------------------------------------------
  // wr_ctrl
  //
  // FSM for requesting data and writing new data to the fifo.
  //----------------------------------------------------------------
  always @*
    begin : wr_ctrl
      wr_ptr_inc    = 0;
      wr_ptr_rst    = 0;
      fifo_mem_we   = 0;
      fifo_ctr_rst  = 0;
      more_data_new = 0;
      more_data_we  = 0;
      wr_ctrl_new   = WR_IDLE;
      wr_ctrl_we    = 0;

      case (wr_ctrl_reg)
        WR_IDLE:
          begin
            if (discard)
              begin
                wr_ctrl_new = WR_DISCARD;
                wr_ctrl_we  = 1;
              end
            else
              begin
                if (!fifo_full)
                  begin
                    more_data_new = 1'b1;
                    more_data_we  = 1'b1;
                    wr_ctrl_new   = WR_WAIT;
                    wr_ctrl_we    = 1;
                  end
                else
                  begin
                    more_data_new = 1'b0;
                    more_data_we  = 1'b1;
                  end
              end
          end

        WR_WAIT:
          begin
            if (csprng_data_valid)
              begin
                fifo_mem_we = 1;
                wr_ptr_inc  = 1;
                wr_ctrl_new = WR_NEXT;
                wr_ctrl_we  = 1;
              end
          end

        WR_NEXT:
          begin
            more_data_new = 1'b0;
            more_data_we  = 1'b1;
            wr_ctrl_new   = WR_IDLE;
            wr_ctrl_we    = 1;
          end

        WR_DISCARD:
          begin
            fifo_ctr_rst = 1;
            wr_ptr_rst   = 1;
            wr_ctrl_new  = WR_IDLE;
            wr_ctrl_we   = 1;
          end
      endcase // case (wr_ctrl_reg)
    end // wr_ctrl

endmodule // trng_csprng_fifo

//======================================================================
// EOF trng_csprng_fifo.v
//======================================================================
