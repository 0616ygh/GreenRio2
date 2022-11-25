//======================================================================
//
// rosc.v
// ------
// Digital ring oscillator used as entropy source. Based on the
// idea of using carry chain in adders as inverter by Bernd Paysan.
//
//
//
// Author: Bernd Paysan, Joachim Strombergson
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

module rosc #(parameter WIDTH = 2)
             (
              input wire                   clk,
              input wire                   reset_n,

              input wire                   we,

              input wire [(WIDTH - 1) : 0] opa,
              input wire [(WIDTH - 1) : 0] opb,

              output wire                  dout
             );

  //----------------------------------------------------------------
  // Registers.
  //----------------------------------------------------------------
  reg dout_reg;
  reg dout_new;


  //----------------------------------------------------------------
  // Concurrent assignment.
  //----------------------------------------------------------------
  assign dout = dout_reg;


  //----------------------------------------------------------------
  // reg_update
  //----------------------------------------------------------------
     always @ (posedge clk or negedge reset_n)
       begin
         if (!reset_n)
           begin
             dout_reg <= 1'b0;
           end
         else
           begin
             if (we)
               begin
                 dout_reg <= dout_new;
               end
           end
       end


  //----------------------------------------------------------------
  // adder_osc
  //
  // Adder logic that generates the oscillator.
  //
  // NOTE: This logic contains a combinational loop and does
  // not play well with an event driven simulator.
  //----------------------------------------------------------------
  always @*
    begin: adder_osc
      reg [WIDTH : 0] sum;
      reg             cin;

      cin = ~sum[WIDTH];
      sum = opa + opb + {{(WIDTH - 1){1'b0}}, cin};
      dout_new = sum[WIDTH];
    end
endmodule // rosc

//======================================================================
// EOF rosc.v
//======================================================================
