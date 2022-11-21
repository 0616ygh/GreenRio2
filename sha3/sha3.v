//======================================================================
// sha3
// ----
// keccak, SHA-3 winner
// derived from "readable keccak"
// 19-Nov-11  Markku-Juhani O. Saarinen <mjos@iki.fi>
// A baseline Keccak (3rd round) implementation.
// Verilog implementation (c) 2015 by Bernd Paysan
// Ported to Cryptech Alpha platform by Pavel Shatov
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

`define rotl64(x, r) ((({x, x}<<r)>>64)& 64'hffffffffffffffff)
`define rotci(i) ((rotc>>((23-i)*6)) & 6'h3f)
`define pilni(i) ((piln>>((23-i)*5)) & 5'h1f)
`define rndci(i) ((rndc>>((23-i)*64)) & 64'hffffffffffffffff)

`define SHA3_NUM_ROUNDS         5'd24

module sha3(    input wire          clk,
                input wire 	     nreset,
                input wire 	     w,
                input wire [ 8:2]    addr,
                input wire [32-1:0]  din,
                output wire [32-1:0] dout,
                input wire 	     init,
                input wire 	     next,
                output wire 	     ready);


   /*
    * The SHA-3 algorithm really wants everything to be little-endian,
    * which is at odds with everything else in our system (including the
    * register interface to sha3_wrapper). Rather than trying to rewrite
    * Bernd's beautiful code, I'll isolate it in its own little-endian
    * universe by byte-swapping all reads and writes.
    */

   reg [31:0]                       dout_swap;
   assign dout = {dout_swap[7:0], dout_swap[15:8], dout_swap[23:16], dout_swap[31:24]};

   wire [31:0]                      din_swap;
   assign din_swap = {din[7:0], din[15:8], din[23:16], din[31:24]};


   integer                          i, j;

   reg [64-1:0]                     blk[0:24],  // input block
                                    st [0:24],  // current state
                                    stn[0:24],  // new state
                                    bc [0: 4],  // intermediate values
                                    t;          // temporary variable

   reg [   4:0]                     round;      // counter value


   localparam   [ 4: 0] roundlimit = `SHA3_NUM_ROUNDS - 'b1;


   localparam   [24*6-1:0]      rotc =
                                      { 6'h01, 6'h03, 6'h06, 6'h0A, 6'h0F, 6'h15,
                                        6'h1C, 6'h24, 6'h2D, 6'h37, 6'h02, 6'h0E,
                                        6'h1B, 6'h29, 6'h38, 6'h08, 6'h19, 6'h2B,
                                        6'h3E, 6'h12, 6'h27, 6'h3D, 6'h14, 6'h2C};

   localparam   [24*5-1:0]      piln =
                                      { 5'h0A, 5'h07, 5'h0B, 5'h11, 5'h12, 5'h03,
                                        5'h05, 5'h10, 5'h08, 5'h15, 5'h18, 5'h04,
                                        5'h0F, 5'h17, 5'h13, 5'h0D, 5'h0C, 5'h02,
                                        5'h14, 5'h0E, 5'h16, 5'h09, 5'h06, 5'h01};

   localparam   [24*64-1:0]     rndc =
                                      { 64'h0000000000000001, 64'h0000000000008082,
                                        64'h800000000000808a, 64'h8000000080008000,
                                        64'h000000000000808b, 64'h0000000080000001,
                                        64'h8000000080008081, 64'h8000000000008009,
                                        64'h000000000000008a, 64'h0000000000000088,
                                        64'h0000000080008009, 64'h000000008000000a,
                                        64'h000000008000808b, 64'h800000000000008b,
                                        64'h8000000000008089, 64'h8000000000008003,
                                        64'h8000000000008002, 64'h8000000000000080,
                                        64'h000000000000800a, 64'h800000008000000a,
                                        64'h8000000080008081, 64'h8000000000008080,
                                        64'h0000000080000001, 64'h8000000080008008};

   /* input block buffer is mapped to the lower half of the
    address space, sponge state is mapped to the upper one */

   /* the lowest address bit determines what part of 64-bit word to return */

   always @*
     //
     dout_swap = addr[8] ?
                 (~addr[2] ? st [addr[7:3]][31:0] : st [addr[7:3]][63:32]) :
                 (~addr[2] ? blk[addr[7:3]][31:0] : blk[addr[7:3]][63:32]) ;


   always @* begin

      // theta1
      for (i=0; i<25; i=i+1)
        stn[i] = st[i];

      for (i=0; i<5; i=i+1)
        bc[i] = stn[i] ^ stn[i+5] ^ stn[i+10] ^ stn[i+15] ^ stn[i+20];

      // theta2
      for (i=0; i<5; i=i+1) begin

         t = bc[(i+4)%5] ^ `rotl64(bc[(i+1)%5], 1);

         for(j=i; j<25; j=j+5)
           stn[j] = t ^ stn[j];
      end

      // rophi
      t = stn[1];
      for(i=0; i<24; i=i+1) begin
         j = `pilni(i);
         { stn[j], t } = { `rotl64(t, `rotci(i)), stn[j] };
      end

      // chi
      for (j=0; j<25; j=j+5) begin

         for (i=0; i<5; i=i+1)
           bc[i] = stn[j + i];

         for (i=0; i<5; i=i+1)
           stn[j+i] = stn[j+i] ^ (~bc[(i+1)%5] & bc[(i+2)%5]);
      end

      // iota
      stn[0] = stn[0] ^ `rndci(round);
   end


   /* ready flag logic */

   reg  ready_reg = 'b1;
   assign ready = ready_reg;

   always @(posedge clk or negedge nreset)
     //
     if (!nreset)       ready_reg <= 'b1;
     else begin
        if (ready)      ready_reg <= !(init || next);
        else            ready_reg <= !(round < roundlimit);
     end

   /* state update logic */
   always @(posedge clk or negedge nreset)
     //
     if (!nreset) begin

        for (i=0; i<25; i=i+1) begin
           st[i]        <= 64'hX;       // wipe state
           blk[i]       <= 64'h0;       // wipe block
        end

        round           <= `SHA3_NUM_ROUNDS;

     end else begin

        if (!ready) begin

           for (i=0; i<25; i=i+1)
             st[i] <= stn[i];

           round <= round + 'd1;

        end else if (init || next) begin

           for (i=0; i<25; i=i+1)
             st[i] <= init ? blk[i] : st[i] ^ blk[i];   // init has priority over next

           round <= 'd0;

        end

        if (w)
          //
          case (addr[2])
            1: blk[addr[7:3]][63:32] <= din_swap;
            0: blk[addr[7:3]][31: 0] <= din_swap;
          endcase

     end


endmodule // sha3
//======================================================================
