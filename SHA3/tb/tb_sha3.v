// RCS HEADER -- DO NOT ERASE
// $Author: aragones $
// $Id: tb_sha3.v,v 0.01 2015/05/04 20:15:32 aragones Exp $
//*******************************************************************
//-----------------------------------------------------------------------------
// Title         : Testbench SHA3(256)
// Project       : 
//-----------------------------------------------------------------------------
// File          : tb_sha3.v
// Author        : Charles Aragones
// Created       : 17 Feb 2017
//-----------------------------------------------------------------------------
// Description :
//    Test Bench for SHA3
// 
//-----------------------------------------------------------------------------
// Copyright (c) 2017 by Envieta, LLC. This model is the confidential and
// proprietary property of Envieta, LLC. and the possession or use of this
// file requires a written license from Envieta, LLC.
//------------------------------------------------------------------------------
//
//

`include "default_parms.v" 

`define SHA3_MSGLEN       136544         /*  TB Message Length MAX from SHAKE128LongMsg.rsp vector set */  

module tb_sha3 #(`PARMS) ();

  // General I/O
  reg         clk_i                   ; // system clock
  reg         reset_i                 ; // async reset active low
  reg         squeeze                 ; // squeeze more md output for each clock cycle
  reg  [2:0]  mode_sel                ; // 0=shake128; 1=shake256; 2=sha3256
  wire        md_valid                ; // message digest valid pulse

  reg  [0 :`SHA3_B-1] sha3_data_i ;  // String input (1600 bits)
  wire [0 :`SHA3_D-1] md_data_o   ;  // String output (256 bits)
  reg  [`SHA3_BITLEN-1:0] bitlen      ;  // message length in bits

  reg  start ;
  wire sha3_ready;

  reg [20:0] Len;
  reg [0:`SHA3_MSGLEN-1] Msg;
  reg [0:`SHA3_D-1] MD;


//-------------------------------------------------
// instantiate module
//-------------------------------------------------
//

  sha3_core inst_sha3_core (
    .clk_i(clk_i) ,
    .reset_i(reset_i) ,
	.start_i(start),
	.squeeze_i(squeeze),
	.mode_sel_i(mode_sel),
	.bitlen_i(bitlen),
    .ready_o(sha3_ready),
    .md_ack_i(md_valid),
    .md_valid_o(md_valid),
    .data_i (sha3_data_i),
	.md_data_o (md_data_o)
    );

//-------------------------------------------------
// clock & reset
//-------------------------------------------------

initial
 begin
  clk_i=1;
   forever
    begin
    #10 clk_i=!clk_i;
    end
 end


initial
  begin
   reset_i=1;
   #50;
   reset_i=0;
  end

  //----------------------------------------------------------------
  // TEST signals
  //----------------------------------------------------------------

  integer test_count_total;
  integer test_count_shake128;
  integer test_count_shake256;
  integer test_count_sha3512;
  integer test_count_sha3384;
  integer test_count_sha3256;
  integer test_count_sha3224;
  reg mismatch_shake128;
  reg mismatch_shake256;
  reg mismatch_sha3512;
  reg mismatch_sha3384;
  reg mismatch_sha3256;
  reg mismatch_sha3224;
  reg mismatch_shake128_has_occurred;
  reg mismatch_shake256_has_occurred;
  reg mismatch_sha3512_has_occurred;
  reg mismatch_sha3384_has_occurred;
  reg mismatch_sha3256_has_occurred;
  reg mismatch_sha3224_has_occurred;

  //----------------------------------------------------------------
  // TASK verify_shake128   (MD=128bits)
  //----------------------------------------------------------------

  task automatic verify_shake128;
  input [0:`SHA3_D-1] md_expected;
   begin
	//if ( shake128_sel && (md_data_o[0:127] == md_expected[128:255]))   // SHAKE128
	if (md_data_o[0:127] == md_expected[128:255])   // SHAKE128
	 begin
	  $display("Passing SHAKE128 Message Digest MD @LEN = %d.",Len);
	  $display("     SHAKE128 MD actual   = %h", md_data_o[0:127]);
	  $display("     SHAKE128 MD expected = %h", md_expected[128:255]);
	  mismatch_shake128 = 1'b0;
	 end
	else
	 begin
	  $display("ERROR: SHAKE128 Message Digest mismatch at LEN = %d", Len);
	  $display("SHAKE128 MD actual   = %h", md_data_o[0:127]);
	  $display("SHAKE128 MD expected = %h", md_expected[128:255]);
	  mismatch_shake128 = 1'b1;
      mismatch_shake128_has_occurred = 1'b1;   // remain high once 1st mismatch occurs
	 end
	Msg = 0;   // clear Msg for next test
   end
  endtask

  //----------------------------------------------------------------
  // TASK verify_sha3_out256   (MD=256-bits)
  //----------------------------------------------------------------

  task automatic verify_sha3_out256;
  input [0:`SHA3_D-1] md_expected;
   begin 
	if ( md_data_o[0:`SHA3_D-1] == md_expected[0:`SHA3_D-1] )
	 begin
	  $display("Passing Message Digest MD @LEN = %d.",Len);
	  $display("     MD actual   = %h", md_data_o[0:`SHA3_D-1]);
	  $display("     MD expected = %h", md_expected[0:`SHA3_D-1]);
	  if (mode_sel==1)
	    mismatch_shake256 = 1'b0;
	  else
	    mismatch_sha3256 = 1'b0;
	 end
	else
	 begin
	  $display("ERROR: Message Digest mismatch at LEN = %d", Len);
	  $display("MD actual   = %h", md_data_o[0:`SHA3_D-1]);
	  $display("MD expected = %h", md_expected[0:`SHA3_D-1]);
	  if (mode_sel==1) begin
	    mismatch_shake256 = 1'b1;
        mismatch_shake256_has_occurred = 1'b1;   // remain high once 1st mismatch occurs
		end
      else begin
	    mismatch_sha3256 = 1'b1;
        mismatch_sha3256_has_occurred = 1'b1;   // remain high once 1st mismatch occurs
		end
	 end
	Msg = 0;   // clear Msg for next test
   end
  endtask

  //----------------------------------------------------------------
  // TASK verify_sha3224 (MD=224bits)
  //----------------------------------------------------------------

  task automatic verify_sha3224;
  input [0:255] md_expected;
   begin
	if ( md_data_o[0:223] == md_expected[0:223] )   // SHA3224
	 begin
	  $display("Passing SHA3224 Message Digest MD @LEN = %d.",Len);
	  $display("     SHA3224 MD actual   = %h", md_data_o[0:223]);
	  $display("     SHA3224 MD expected = %h", md_expected[0:223]);
	  mismatch_sha3224 = 1'b0;
	 end
	else
	 begin
	  $display("ERROR: SHA3224 Message Digest mismatch at LEN = %d", Len);
	  $display("SHA3224 MD actual   = %h", md_data_o[0:223]);
	  $display("SHA3224 MD expected = %h", md_expected[0:223]);
	  mismatch_sha3224 = 1'b1;
      mismatch_sha3224_has_occurred = 1'b1;   // remain high once 1st mismatch occurs
	 end
	Msg = 0;   // clear Msg for next test
   end
  endtask

 //----------------------------------------------------------------
  // TASK squeeze_play.  squeeze more md_data
  //----------------------------------------------------------------

  task automatic squeeze_play;
  input [4:0] num_cc;              // number of clock cycles to spin
   begin
    while (num_cc != 0)
	 begin
	  @(posedge clk_i);
	   squeeze = 1;
	  @(posedge clk_i);
	   squeeze = 0;  
	  @(posedge clk_i);
	   num_cc = num_cc-1;
	 end
   end
  endtask

  //----------------------------------------------------------------
  // TASK start_hash
  //----------------------------------------------------------------

  task automatic start_hash;
   begin
    wait (sha3_ready);
	@(posedge clk_i);
    start = 1;
    wait (~sha3_ready);
	//@(posedge clk_i);    // for multicycle start
    start = 0;
    wait (sha3_ready);
	@(posedge clk_i);
   end
  endtask

  /* below is ready_o as throttle
  task automatic start_hash;
   begin
    @(clk_i && sha3_ready);
    start = 1;
    wait (~sha3_ready);
    @(~clk_i);
    @(clk_i);
    start = 0;
    wait (sha3_ready);
    @(~clk_i && sha3_ready);
    @(clk_i && sha3_ready);
   end
  endtask  shake256(Len, Msg);
  */

  //----------------------------------------------------------------
  // TASK sha3_absorb
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic sha3_absorb;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
   reg   [10:0] RATEBITS;
   integer i;
	 begin
	  case (mode_sel)
       3'd0   : RATEBITS = 11'd1344;  // shake128
       3'd1   : RATEBITS = 11'd1088;  // shake256
       3'd2   : RATEBITS = 11'd576 ;  // sha3512
       3'd3   : RATEBITS = 11'd832 ;  // sha3384
       3'd4   : RATEBITS = 11'd1088;  // sha3256
       3'd5   : RATEBITS = 11'd1152;  // sha3224
	   default: RATEBITS = 11'd1088;  // sha3256
	  endcase

      test_count_total = test_count_total +1;                               // increment for each task call
	  if (bit_length < `SHA3_MSGLEN)
	    message_shift = (message << (`SHA3_MSGLEN-bit_length)); // shift message to left justified
	  else
	    message_shift =  message;
      while ( bit_length >= RATEBITS ) 
	   begin
        bitlen = RATEBITS; 
		for (i=0;i<RATEBITS;i=i+1)
		  sha3_data_i[i] = message_shift[i];
		start_hash;
		bit_length = bit_length - RATEBITS;
	    message_shift = (message_shift << RATEBITS);            // shift message left by 1088 bits, 0 fill
	   end // (end while)
	  //REMAINDER
	  bitlen = bit_length[`SHA3_BITLEN-1:0];
      for (i=0;i<RATEBITS;i=i+1)
        sha3_data_i[i] = message_shift[i];
	  start_hash;
	 end
  endtask


  //----------------------------------------------------------------
  // TASK shake128
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  // OUTPUT IS LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic shake128;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
	 begin
      mode_sel = 3'd0;
      test_count_shake128 = test_count_shake128 +1;                               // increment for each task call
      sha3_absorb(bit_length, message);
	  $display("     SHAKE128: ");
      verify_shake128(MD);
	 end
  endtask

  //----------------------------------------------------------------
  // TASK shake256
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  // OUTPUT IS LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic shake256;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
	 begin
      mode_sel = 3'd1;
      test_count_shake256 = test_count_shake256 +1;                               // increment for each task call
      sha3_absorb(bit_length, message);
	  $display("     SHAKE256: ");
	  verify_sha3_out256(MD);
	 end
  endtask


  //----------------------------------------------------------------
  // TASK sha3512
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic sha3512;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
	 begin
      mode_sel = 3'd2;
      test_count_sha3512 = test_count_sha3512 +1;                               // increment for each task call
      sha3_absorb(bit_length, message);
	  $display("     SHA3512: ");
	  verify_sha3_out256(MD);
	 end
  endtask


  //----------------------------------------------------------------
  // TASK sha3384
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic sha3384;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
	 begin
      mode_sel = 3'd3;
      test_count_sha3384 = test_count_sha3384 +1;                               // increment for each task call
      sha3_absorb(bit_length, message);
	  $display("     SHA3384: ");
	  verify_sha3_out256(MD);
	 end
  endtask


  //----------------------------------------------------------------
  // TASK sha3256
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic sha3256;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
	 begin
      mode_sel = 3'd4;
      test_count_sha3256 = test_count_sha3256 +1;                               // increment for each task call
      sha3_absorb(bit_length, message);
	  $display("     SHA3256: ");
	  verify_sha3_out256(MD);
	 end
  endtask

  //----------------------------------------------------------------
  // TASK sha3224
  // Input MSG MUST BE LEFT JUSTIFIED!!!!!
  //----------------------------------------------------------------

  task automatic sha3224;
   input [20:0] bit_length;
   input [0:`SHA3_MSGLEN-1] message;
   reg   [0:`SHA3_MSGLEN-1] message_shift;
	 begin
      mode_sel = 3'd5;
      test_count_sha3224 = test_count_sha3224 +1;                               // increment for each task call
      sha3_absorb(bit_length, message);
	  $display("     SHA3224: ");
	  verify_sha3224(MD);
	 end
  endtask


//////////////////////////////////////////////////////////////////////
// BEGIN TESTS
//////////////////////////////////////////////////////////////////////

initial
 begin
   Msg = 0;
   Len = 0;
   test_count_total = 0;
   test_count_shake128 = 0;
   test_count_shake256 = 0;
   test_count_sha3512 = 0;
   test_count_sha3384 = 0;
   test_count_sha3256 = 0;
   test_count_sha3224 = 0;
   mismatch_shake128 = 0;
   mismatch_shake256 = 0;
   mismatch_sha3512 = 0;
   mismatch_sha3384 = 0;
   mismatch_sha3256 = 0;
   mismatch_sha3224 = 0;
   mismatch_shake128_has_occurred = 0;
   mismatch_shake256_has_occurred = 0;
   mismatch_sha3512_has_occurred = 0;
   mismatch_sha3384_has_occurred = 0;
   mismatch_sha3256_has_occurred = 0;
   mismatch_sha3224_has_occurred = 0;

   start = 0;
   bitlen = 0;
   squeeze = 0;
   mode_sel = 0;
   sha3_data_i = 0; 
   wait (~reset_i);


//------------------------------------------
// SHAKE128
//------------------------------------------

$display("     SHAKE128 test results. ");

`include "test_shake128short.v"
`include "test_shake128long.v"

//------------------------------------------
// SHAKE256
//------------------------------------------


$display("     SHAKE256 test results. ");

`include "test_shake256short.v"
`include "test_shake256long.v"

// squeeze additional md_data_o without start pulse
squeeze_play(2);

//------------------------------------------
//*  SHA3256 TESTS
//------------------------------------------

$display("     SHA3(256) test results. ");

`include "test_sha3256short.v"
`include "test_sha3256long.v"

//------------------------------------------
//*  SHA3-512,384,224 TESTS
//------------------------------------------

$display("     SHA3(512, 384, 224) test results. ");

`include "test_sha384_512_224.v"

//==============================================================================
// END

 wait (1000);
 $display(".");
 $display("End of Test.  Summary of Tests:");
 $display(".");

 if (mismatch_shake128_has_occurred) 
	$display("A MISMATCH ERROR in shake128 test has been detected.");
 else
     $display("All %3d shake128 tests executed. Detected no errors.", test_count_shake128);

 if (mismatch_shake256_has_occurred) 
	$display("A MISMATCH ERROR in shake256 test has been detected.");
 else
     $display("All %3d shake256 tests executed. Detected no errors.", test_count_shake256);

 if (mismatch_sha3512_has_occurred) 
	$display("A MISMATCH ERROR in sha3512 test has been detected.");
 else
     $display("All %3d sha3512 tests executed. Detected no errors.", test_count_sha3512);

 if (mismatch_sha3384_has_occurred) 
	$display("A MISMATCH ERROR in sha3384 test has been detected.");
 else
     $display("All %3d sha3384 tests executed. Detected no errors.", test_count_sha3384);

 if (mismatch_sha3256_has_occurred) 
	$display("A MISMATCH ERROR in sha3256 test has been detected.");
 else
     $display("All %3d sha3256 tests executed. Detected no errors.", test_count_sha3256);

 if (mismatch_sha3224_has_occurred) 
	$display("A MISMATCH ERROR in sha3224 test has been detected.");
 else
     $display("All %3d sha3224 tests executed. Detected no errors.", test_count_sha3224);


 wait (1000);
 $display(".");
 $display("End of Test.  Total %0d tests were executed.", test_count_total);
 $display(".");
 $stop;

 end

endmodule // tb_sha3
