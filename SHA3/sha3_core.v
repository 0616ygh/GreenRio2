// RCS HEADER -- DO NOT ERASE
// $Author: aragones $
// $Id: sha3_core.v,v 0.01 2017/01/12 20:15:32 aragones Exp $
//*******************************************************************
//-----------------------------------------------------------------------------
// Title         : SHA3 core
// Project       : 
//-----------------------------------------------------------------------------
// File          : sha3_core.v
// Author        : Charles Aragones
// Created       : 12 January 2017
//-----------------------------------------------------------------------------
// Description :
//    NIST.FIPS.202 SHA3(256)
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by Envieta, Inc. This model is the confidential and
// proprietary property of Envieta, Inc. and the possession or use of this
// file requires a written license from Envieta, Inc.
//------------------------------------------------------------------------------

//
//
//
`include "default_parms.v"

module sha3_core (  
//module sha3_core #(`PARMS) (   // pass parameters here (SystemVerilog prob)

  input  clk_i                           ,  // system clk input
  input  reset_i                         ,  // async reset active high
  input  start_i                         ,  // pulse to start hashing next msg 
  input  squeeze_i                       ,  // squeeze output by 1 clock cycle. valid only when md_valid_o=1
  input  [2:0] mode_sel_i                ,  // 0=sha3256, 1=shake128, 2=shake256 
  input  md_ack_i                        ,  // ACK for md_valid_o (handshake)
  output wire ready_o                    ,  // sha3 is ready for next msg (level signal)
  output wire md_valid_o                 ,  // message digest valid.  clears by start_i or md_ack_i

  input  [`SHA3_BITLEN-1:0] bitlen_i     ,  // bit length 
  input  [0:`SHA3_B-1] data_i            ,  // String of data input (1600 bits)
  output wire [0:`SHA3_D-1] md_data_o       // message digest output (256 bits)

  );


  reg [10:0] RATEBITS ; 

   //-------------------------------------------------------
   // ena, round control
   //-------------------------------------------------------

   wire start = start_i & ready_o;        // start ignored when ready_o=0
   wire squeeze = squeeze_i & ready_o ;   // squeeze ignored when ready_o=0

   reg ena;
   reg md_valid;
   reg md_last;
   reg [4:0] round ;
   wire round_tc = (round == `SHA3_NROUNDS-1);  // 23 rounds
   reg init_reg;
   reg start_reg;
   reg squeeze_reg;

   wire init = start && md_last ; //&& md_valid ;  // initialize state register of next msg

    always @(posedge clk_i or posedge reset_i)
    if (reset_i)
	  begin
	    ena <= 1'b0;
        round <= 5'd0;
		md_valid <= 1'b0;
		md_last <= 1'b1;
		init_reg <= 1'b0;
		start_reg <= 1'b0;
		squeeze_reg <= 1'b0;
	  end
    else
	  begin
	    if (start)
	      ena <= 1'b1;
		else if (round_tc)
	      ena <= 1'b0;

		if (round_tc || start)
          round <= 5'd0;
        else if ((ena || squeeze) && ~start)
          round <= round + 5'd1;

		if (round_tc && (bitlen_i < RATEBITS))
          md_valid <= 1'b1;
		else if (md_ack_i || start)
          md_valid <= 1'b0;

		if (start_reg && ~start && (bitlen_i < RATEBITS) )                    // first start bitlen < RATE
	      md_last <= 1'b1;
	    else if (start_reg && ~start && (bitlen_i == RATEBITS) )              // first start bitlen >= RATE
	      md_last <= 1'b0;

		init_reg <= init;
		start_reg <= start;

		if (squeeze)
		  squeeze_reg <= 1'b1;
		else if (md_ack_i || start)
          squeeze_reg <= 1'b0;

	  end

   assign md_valid_o = (md_valid & md_last) | squeeze_reg;
   assign ready_o = ~ena;


   //-------------------------------------------------------
   // Padding  pad10*1
   //-------------------------------------------------------

  // ratebits
  localparam [10:0] SHAKE128_R = 11'd1344; 
  localparam [10:0] SHAKE256_R = 11'd1088; 
  localparam [10:0] SHA3512_R  = 11'd576; 
  localparam [10:0] SHA3384_R  = 11'd832; 
  localparam [10:0] SHA3256_R  = 11'd1088; 
  localparam [10:0] SHA3224_R  = 11'd1152; 
  localparam [ 7:0] PAD_END    =  8'h80;  // last byte padding (q>=2)

  reg [ 7:0] PAD_1ST;
  reg [ 7:0] PAD_Q1;
  reg [0:`SHA3_B-1] string ;   // String of data input (1600 bits)

  always @(*)
   begin
    string = 0;   // default. avoid latch
	case (mode_sel_i)

	3'd0 : begin                                                  // SHAKE128
	        RATEBITS = SHAKE128_R;
			PAD_1ST  = 8'h1F;                                     // first padding byte
			PAD_Q1   = 8'h9F;                                     // last byte padding for q=1

            if (bitlen_i >= SHAKE128_R)
              string[0:SHAKE128_R-1] = data_i[0:SHAKE128_R-1];    // bitlen_i >= RATEBITS

            else if (bitlen_i == SHAKE128_R-8) begin              // bitlen_i == RATEBITS-8
              string[0  : SHAKE128_R-8] = data_i[0:SHAKE128_R-8];  
	          string[SHAKE128_R-1 -: 8] = PAD_Q1 ;                // end of pad (shake128='h80 | 'h1F) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHAKE128_R - 16] = data_i[0:SHAKE128_R-16];// data
	          string[bitlen_i     +: 8] = PAD_1ST ;               // start of pad
	          string[SHAKE128_R-1 -: 8] = PAD_END ;               // end of pad = 'h80
			  end
	       end

	3'd1 : begin                                                  // SHAKE256
	        RATEBITS = SHAKE256_R;
			PAD_1ST  = 8'h1F;                                     // first padding byte
			PAD_Q1   = 8'h9F;                                     // last byte padding for q=1

            if (bitlen_i >= SHAKE256_R)
              string[0:SHAKE256_R-1] = data_i[0:SHAKE256_R-1];    // bitlen_i >= RATEBITS

            else if (bitlen_i == SHAKE256_R-8) begin              // bitlen_i == RATEBITS-8
              string[0  : SHAKE256_R-8] = data_i[0:SHAKE256_R-8];  
	          string[SHAKE256_R-1 -: 8] = PAD_Q1 ;                // end of pad (shake256='h80 | 'h1F) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHAKE256_R - 16] = data_i[0:SHAKE256_R-16];// data
	          string[bitlen_i     +: 8] = PAD_1ST ;               // start of pad
	          string[SHAKE256_R-1 -: 8] = PAD_END ;               // end of pad = 'h80
			  end

	       end

	3'd2 : begin                                                  // SHA3512
	        RATEBITS = SHA3512_R;
			PAD_1ST  = 8'h06;                                     // first padding byte
			PAD_Q1   = 8'h86;                                     // last byte padding for q=1

            if (bitlen_i >= SHA3512_R)
              string[0:SHA3512_R-1] = data_i[0:SHA3512_R-1];      // bitlen_i >= RATEBITS
			  
            else if (bitlen_i == SHA3512_R-8) begin               // bitlen_i == RATEBITS-8
              string[0  : SHA3512_R-8] = data_i[0:SHA3512_R-8];  
	          string[SHA3512_R-1 -: 8] = PAD_Q1 ;                 // end of pad (shake128='h80 | 'h06) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHA3512_R - 16] = data_i[0:SHA3512_R-16];  // data
	          string[bitlen_i    +: 8] = PAD_1ST ;                // start of pad
	          string[SHA3512_R-1 -: 8] = PAD_END ;                // end of pad = 'h80
			  end
	       end

	3'd3 : begin                                                  // SHA3384
	        RATEBITS = SHA3384_R;
			PAD_1ST  = 8'h06;                                     // first padding byte
			PAD_Q1   = 8'h86;                                     // last byte padding for q=1

            if (bitlen_i >= SHA3384_R)
              string[0:SHA3384_R-1] = data_i[0:SHA3384_R-1];      // bitlen_i >= RATEBITS

            else if (bitlen_i == SHA3384_R-8) begin               // bitlen_i == RATEBITS-8
              string[0:SHA3384_R -  8] = data_i[0:SHA3384_R-8];  
	          string[SHA3384_R-1 -: 8] = PAD_Q1 ;                 // end of pad ('h80 | 'h06) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHA3384_R - 16] = data_i[0:SHA3384_R-16];  // data
	          string[bitlen_i    +: 8] = PAD_1ST ;                // start of pad
	          string[SHA3384_R-1 -: 8] = PAD_END ;                // end of pad = 'h80
			  end
	       end

	3'd4 : begin                                                  // SHA3256
	        RATEBITS = SHA3256_R;
			PAD_1ST  = 8'h06;                                     // first padding byte
			PAD_Q1   = 8'h86;                                     // last byte padding for q=1

            if (bitlen_i >= SHA3256_R)
              string[0:SHA3256_R-1] = data_i[0:SHA3256_R-1];      // bitlen_i >= RATEBITS

            else if (bitlen_i == SHA3256_R-8) begin               // bitlen_i == RATEBITS-8
              string[0:SHA3256_R -  8] = data_i[0:SHA3256_R-8];  
	          string[SHA3256_R-1 -: 8] = PAD_Q1 ;                 // end of pad ('h80 | 'h06) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHA3256_R - 16] = data_i[0:SHA3256_R-16];  // data
	          string[bitlen_i    +: 8] = PAD_1ST ;                // start of pad
	          string[SHA3256_R-1 -: 8] = PAD_END ;                // end of pad = 'h80
			  end
	       end

	3'd5 : begin                                                  // SHA3224
	        RATEBITS = SHA3224_R;
			PAD_1ST  = 8'h06;                                     // first padding byte
			PAD_Q1   = 8'h86;                                     // last byte padding for q=1

            if (bitlen_i >= SHA3224_R)
              string[0:SHA3224_R-1] = data_i[0:SHA3224_R-1];      // bitlen_i >= RATEBITS

            else if (bitlen_i == SHA3224_R-8) begin               // bitlen_i == RATEBITS-8
              string[0:SHA3224_R -  8] = data_i[0:SHA3224_R-8];  
	          string[SHA3224_R-1 -: 8] = PAD_Q1 ;                 // end of pad ('h80 | 'h06) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHA3224_R - 16] = data_i[0:SHA3224_R-16];  // data
	          string[bitlen_i    +: 8] = PAD_1ST ;                // start of pad
	          string[SHA3224_R-1 -: 8] = PAD_END ;                // end of pad = 'h80
			  end
	       end

    default : begin                                               // SHA3256
	        RATEBITS = SHA3256_R;
			PAD_1ST  = 8'h06;                                     // first padding byte
			PAD_Q1   = 8'h86;                                     // last byte padding for q=1

            if (bitlen_i >= SHA3256_R)
              string[0:SHA3256_R-1] = data_i[0:SHA3256_R-1];      // bitlen_i >= RATEBITS

            else if (bitlen_i == SHA3256_R-8) begin               // bitlen_i == RATEBITS-8
              string[0:SHA3256_R -  8] = data_i[0:SHA3256_R-8];  
	          string[SHA3256_R-1 -: 8] = PAD_Q1 ;                 // end of pad ('h80 | 'h06) 
			  end

            else begin                                            // bitlen_i <  RATEBITS-8
              string[0:SHA3256_R - 16] = data_i[0:SHA3256_R-16];  // data
	          string[bitlen_i    +: 8] = PAD_1ST ;                // start of pad
	          string[SHA3256_R-1 -: 8] = PAD_END ;                // end of pad = 'h80
			  end
	       end
    endcase
  end

// below, Altera complained of "loop with non-constant loop condition"
// thus method above.
/*
   integer j;

   always @(*)
	begin
      string = 0;   // default. avoid latch
      if (bitlen_i < RATEBITS)
	    begin
          for (j=0; j<RATEBITS-8; j=j+1)
            string[j] = data_i[j];
          if (bitlen_i == RATEBITS-8)              // bitlen_i = last byte of R
	        string[RATEBITS-1 -: 8] = PAD_Q1 ;     // end of pad (shake128='h80 | 'h1F) 
			                                       // or         (sha3256 ='h80 | 'h06)
          else
		    begin                                  // not last byte of R
	          string[bitlen_i   +: 8] = PAD_1ST ;    // start of pad
	          string[RATEBITS-1 -: 8] = PAD_END;   // end of pad = 'h80
			end
        end
      else
        for (j=0; j<RATEBITS; j=j+1)
          string[j] = data_i[j];                   // bitlen_i >= RATEBITS
	end
*/
   //-------------------------------------------------------
   // Endian Byte Swap
   //-------------------------------------------------------

   // function to endian byte swap (64-bit)
   function [0:`SHA3_W-1] byteswap(input [0:`SHA3_W-1] data);
    byteswap = { data[56:63],
                 data[48:55],
                 data[40:47],
                 data[32:39],
                 data[24:31],
                 data[16:23],
                 data[ 8:15],
                 data[ 0: 7]
	           };
   endfunction

   // convert data_i to a_array to be able to (Endian) byte swap

   wire [0:`SHA3_W-1] a_array [0:`SHA3_L-1] ;  // 5x5 (x,y) array [0:63]

   assign a_array[ 0] = byteswap(string[   0:  63]);
   assign a_array[ 1] = byteswap(string[  64: 127]);
   assign a_array[ 2] = byteswap(string[ 128: 191]);
   assign a_array[ 3] = byteswap(string[ 192: 255]);
   assign a_array[ 4] = byteswap(string[ 256: 319]);
   assign a_array[ 5] = byteswap(string[ 320: 383]);
   assign a_array[ 6] = byteswap(string[ 384: 447]);
   assign a_array[ 7] = byteswap(string[ 448: 511]);
   assign a_array[ 8] = byteswap(string[ 512: 575]);
   assign a_array[ 9] = byteswap(string[ 576: 639]);
   assign a_array[10] = byteswap(string[ 640: 703]);
   assign a_array[11] = byteswap(string[ 704: 767]);
   assign a_array[12] = byteswap(string[ 768: 831]);
   assign a_array[13] = byteswap(string[ 832: 895]);
   assign a_array[14] = byteswap(string[ 896: 959]);
   assign a_array[15] = byteswap(string[ 960:1023]);
   assign a_array[16] = byteswap(string[1024:1087]);
   assign a_array[17] = byteswap(string[1088:1151]);
   assign a_array[18] = byteswap(string[1152:1215]);
   assign a_array[19] = byteswap(string[1216:1279]);
   assign a_array[20] = byteswap(string[1280:1343]);
   assign a_array[21] = byteswap(string[1344:1407]);
   assign a_array[22] = byteswap(string[1408:1471]);
   assign a_array[23] = byteswap(string[1472:1535]);
   assign a_array[24] = byteswap(string[1536:1599]);

   // convert array back to string to pass into rnd_a()

  wire  [0:`SHA3_B-1] a_string;  // String of data  (1600 bits)
  assign a_string = { a_array[ 0], a_array[ 1], a_array[ 2], a_array[ 3], a_array[ 4], 
                      a_array[ 5], a_array[ 6], a_array[ 7], a_array[ 8], a_array[ 9], 
                      a_array[10], a_array[11], a_array[12], a_array[13], a_array[14], 
                      a_array[15], a_array[16], a_array[17], a_array[18], a_array[19], 
                      a_array[20], a_array[21], a_array[22], a_array[23], a_array[24]
                     };
 

   //-------------------------------------------------------
   // Instantiate SHA3_RND_A
   //-------------------------------------------------------

   // assign variables (match C code) from a_string 
   // [x,y] = [{o,u,a,e,i},{m,s,b,g,k}]
   // 5x5[x,y] cube config, where Aba=(0,0), Abe=(1,0) .. Aga=(0,1),Age=(1,1),Asu=(4,4)
   // 
   wire [0:`SHA3_W-1] Ako, Aku, Aka, Ake, Aki;     // x={3,4,0,1,2} ; y=2
   wire [0:`SHA3_W-1] Ago, Agu, Aga, Age, Agi;     // x={3,4,0,1,2} ; y=1
   wire [0:`SHA3_W-1] Abo, Abu, Aba, Abe, Abi;     // x={3,4,0,1,2} ; y=0
   wire [0:`SHA3_W-1] Aso, Asu, Asa, Ase, Asi;     // x={3,4,0,1,2} ; y=4
   wire [0:`SHA3_W-1] Amo, Amu, Ama, Ame, Ami;     // x={3,4,0,1,2} ; y=3

   // feedback state_array
   wire [0:`SHA3_B-1] state_reg ;       // state array output (25lanes x 64bits)
   wire [0:`SHA3_B-1] string_xor_state =                             init_reg ?             a_string : 
                                      ( start_reg && (round==0) && ~md_last ) ? state_reg ^ a_string : 
									                                            state_reg            ;
	                                     
  sha3_rnd_a inst_sha3_rnd_a(
    .clk_i (clk_i),
	.reset_i (reset_i),
	.round_i (round),
	.string_i (string_xor_state),
    .Aba_o (Aba),    // (0,0)
    .Abe_o (Abe),    // (1,0)
    .Abi_o (Abi),    // (2,0)
    .Abo_o (Abo),    // (3,0)
    .Abu_o (Abu),    // (4,0)
    .Aga_o (Aga),    // (0,1)
    .Age_o (Age),    // (1,1)
    .Agi_o (Agi),    // (2,1)
    .Ago_o (Ago),    // (3,1)
    .Agu_o (Agu),    // (4,1)
    .Aka_o (Aka),    // (0,2)
    .Ake_o (Ake),    // (1,2)
    .Aki_o (Aki),    // (2,2)
    .Ako_o (Ako),    // (3,2)
    .Aku_o (Aku),    // (4,2)
    .Ama_o (Ama),    // (0,3)
    .Ame_o (Ame),    // (1,3)
    .Ami_o (Ami),    // (2,3)
    .Amo_o (Amo),    // (3,3)
    .Amu_o (Amu),    // (4,3)
    .Asa_o (Asa),    // (0,4)
    .Ase_o (Ase),    // (1,4)
    .Asi_o (Asi),    // (2,4)
    .Aso_o (Aso),    // (3,4)
    .Asu_o (Asu)     // (3,4)
   );


   //-------------------------------------------------------
   // State Register
   //-------------------------------------------------------


   integer i;
   reg [0:`SHA3_W-1] state_array [0:`SHA3_L-1] ;  // 5x5 (x,y) array [0:63]

    always @(posedge clk_i or posedge reset_i)
    if (reset_i)
      for (i=0; i<`SHA3_L; i=i+1)
        state_array[i] <= 0;
    else
	 if (init)
      for (i=0; i<`SHA3_L; i=i+1)
        //state_array[i] <= a_array[i];    // SEED
        state_array[i] <= 'd0;             // initialize 0, no seed
     else if ((ena || squeeze) && ~start)
	   begin
        state_array[0] <= Aba;
        state_array[1] <= Abe;
        state_array[2] <= Abi;
        state_array[3] <= Abo;
        state_array[4] <= Abu;

        state_array[5] <= Aga;
        state_array[6] <= Age;
        state_array[7] <= Agi;
        state_array[8] <= Ago;
        state_array[9] <= Agu;

        state_array[10] <= Aka;
        state_array[11] <= Ake;
        state_array[12] <= Aki;
        state_array[13] <= Ako;
        state_array[14] <= Aku;

        state_array[15] <= Ama;
        state_array[16] <= Ame;
        state_array[17] <= Ami;
        state_array[18] <= Amo;
        state_array[19] <= Amu;

        state_array[20] <= Asa;
        state_array[21] <= Ase;
        state_array[22] <= Asi;
        state_array[23] <= Aso;
        state_array[24] <= Asu;
      end

  // feedback state_array into rnd(a) .
  assign state_reg = {state_array[ 0], state_array[ 1], state_array[ 2], state_array[ 3], state_array[ 4], 
                      state_array[ 5], state_array[ 6], state_array[ 7], state_array[ 8], state_array[ 9], 
                      state_array[10], state_array[11], state_array[12], state_array[13], state_array[14], 
                      state_array[15], state_array[16], state_array[17], state_array[18], state_array[19], 
                      state_array[20], state_array[21], state_array[22], state_array[23], state_array[24]
                     };
                    

  //-------------------------------------------------------
  // String Output (256) 
  // Convert Little Endian to Big endian bytes
  // Message digest (256)
  //-------------------------------------------------------

// SHA3256 MD = md_data_o[0:255];  SHAKE128 MD = md_data_o[0:127]; SHA3512 MD = md_data_o[0:511] 

  assign md_data_o = { state_array[0][56:63], state_array[0][48:55], state_array[0][40:47], state_array[0][32:39], state_array[0][24:31], state_array[0][16:23], state_array[0][8:15], state_array[0][0:7], 
                       state_array[1][56:63], state_array[1][48:55], state_array[1][40:47], state_array[1][32:39], state_array[1][24:31], state_array[1][16:23], state_array[1][8:15], state_array[1][0:7], 
                       state_array[2][56:63], state_array[2][48:55], state_array[2][40:47], state_array[2][32:39], state_array[2][24:31], state_array[2][16:23], state_array[2][8:15], state_array[2][0:7], 
                       state_array[3][56:63], state_array[3][48:55], state_array[3][40:47], state_array[3][32:39], state_array[3][24:31], state_array[3][16:23], state_array[3][8:15], state_array[3][0:7]
                    // For MD512, uncomment state_array[4:7]
                       //state_array[4][56:63], state_array[4][48:55], state_array[4][40:47], state_array[4][32:39], state_array[4][24:31], state_array[4][16:23], state_array[4][8:15], state_array[4][0:7], 
                       //state_array[5][56:63], state_array[5][48:55], state_array[5][40:47], state_array[5][32:39], state_array[5][24:31], state_array[5][16:23], state_array[5][8:15], state_array[5][0:7], 
                       //state_array[6][56:63], state_array[6][48:55], state_array[6][40:47], state_array[6][32:39], state_array[6][24:31], state_array[6][16:23], state_array[6][8:15], state_array[6][0:7], 
                       //state_array[7][56:63], state_array[7][48:55], state_array[7][40:47], state_array[7][32:39], state_array[7][24:31], state_array[7][16:23], state_array[7][8:15], state_array[7][0:7]  
                     };

endmodule

