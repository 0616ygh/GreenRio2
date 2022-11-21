// RCS HEADER -- DO NOT ERASE
// $Author: aragones $
// $Id: sha3_rnd_a.v,v 0.01 2017/01/12 20:15:32 aragones Exp $
//*******************************************************************
//-----------------------------------------------------------------------------
// Title         : SHA3 core
// Project       : 
//-----------------------------------------------------------------------------
// File          : sha3_rnd_a.v
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

module sha3_rnd_a (   // pass parameters here
//module sha3_rnd_a #(`PARMS) (   // pass parameters here  (is this system verilog construct?)

  input  clk_i                                  ,  // system clk input
  input  reset_i                                ,  // async reset active high
  input  [4:0] round_i                          ,  // round #
  input  [0:`SHA3_B-1] string_i                 ,  // String of data input (1600 bits)
  output [0:`SHA3_W-1] Ako_o, Aku_o, Aka_o, Ake_o, Aki_o, // x={3,4,0,1,2} ; y=2
  output [0:`SHA3_W-1] Ago_o, Agu_o, Aga_o, Age_o, Agi_o, // x={3,4,0,1,2} ; y=1
  output [0:`SHA3_W-1] Abo_o, Abu_o, Aba_o, Abe_o, Abi_o, // x={3,4,0,1,2} ; y=0
  output [0:`SHA3_W-1] Aso_o, Asu_o, Asa_o, Ase_o, Asi_o, // x={3,4,0,1,2} ; y=4
  output [0:`SHA3_W-1] Amo_o, Amu_o, Ama_o, Ame_o, Ami_o  // x={3,4,0,1,2} ; y=3

  );


  wire [0:`SHA3_W-1] RoundConstants [0:23] ;         // 24 x 64bits 
  assign RoundConstants[ 0] = 64'h0000000000000001;
  assign RoundConstants[ 1] = 64'h0000000000008082;
  assign RoundConstants[ 2] = 64'h800000000000808a;
  assign RoundConstants[ 3] = 64'h8000000080008000;
  assign RoundConstants[ 4] = 64'h000000000000808b;
  assign RoundConstants[ 5] = 64'h0000000080000001;
  assign RoundConstants[ 6] = 64'h8000000080008081;
  assign RoundConstants[ 7] = 64'h8000000000008009;
  assign RoundConstants[ 8] = 64'h000000000000008a;
  assign RoundConstants[ 9] = 64'h0000000000000088;
  assign RoundConstants[10] = 64'h0000000080008009;
  assign RoundConstants[11] = 64'h000000008000000a;
  assign RoundConstants[12] = 64'h000000008000808b;
  assign RoundConstants[13] = 64'h800000000000008b;
  assign RoundConstants[14] = 64'h8000000000008089;
  assign RoundConstants[15] = 64'h8000000000008003;
  assign RoundConstants[16] = 64'h8000000000008002;
  assign RoundConstants[17] = 64'h8000000000000080;
  assign RoundConstants[18] = 64'h000000000000800a;
  assign RoundConstants[19] = 64'h800000008000000a;
  assign RoundConstants[20] = 64'h8000000080008081;
  assign RoundConstants[21] = 64'h8000000000008080;
  assign RoundConstants[22] = 64'h0000000080000001;
  assign RoundConstants[23] = 64'h8000000080008008;


   //-------------------------------------------------------
   // Convert String to State Array
   //-------------------------------------------------------

  wire [0:`SHA3_W-1] A_array [0:24] ;  // 5x5 (x,y) array [0:63]
                                         // 13 14 10 11 12
                                         //  8  9  5  6  7
                                         //  3  4  0  1  2
                                         // 23 24 20 21 22 
                                         // 18 19 15 16 17
                                         //
            // ( 4: 0) = { (4,0), (3,0), (2,0), (1,0), (0,0) } 
            // ( 9: 5) = { (4,1), (3,1), (2,1), (1,1), (0,1) } 
            // (14:10) = { (4,2), (3,2), (2,2), (1,2), (0,2) } 
            // (19:15) = { (4,3), (3,3), (2,3), (1,3), (0,3) } 
            // (24:20) = { (4,4), (3,4), (2,4), (1,4), (0,4) } 

   assign A_array[ 0] = string_i[  0: 63];
   assign A_array[ 1] = string_i[ 64:127];
   assign A_array[ 2] = string_i[128:191];
   assign A_array[ 3] = string_i[192:255];
   assign A_array[ 4] = string_i[256:319];
   assign A_array[ 5] = string_i[320:383];
   assign A_array[ 6] = string_i[384:447];
   assign A_array[ 7] = string_i[448:511];
   assign A_array[ 8] = string_i[512:575];
   assign A_array[ 9] = string_i[576:639];
   assign A_array[10] = string_i[640:703];
   assign A_array[11] = string_i[704:767];
   assign A_array[12] = string_i[768:831];
   assign A_array[13] = string_i[832:895];
   assign A_array[14] = string_i[896:959];
   assign A_array[15] = string_i[960:1023];
   assign A_array[16] = string_i[1024:1087];
   assign A_array[17] = string_i[1088:1151];
   assign A_array[18] = string_i[1152:1215];
   assign A_array[19] = string_i[1216:1279];
   assign A_array[20] = string_i[1280:1343];
   assign A_array[21] = string_i[1344:1407];
   assign A_array[22] = string_i[1408:1471];
   assign A_array[23] = string_i[1472:1535];
   assign A_array[24] = string_i[1536:1599];
      
   //-------------------------------------------------------
   // assign variables (match C code) from A_array 
   // [x,y] = [{o,u,a,e,i},{m,s,b,g,k}]
   // 5x5[x,y] where Aba=[0,0], Abe=[1,0] .. Aga=[0,1],Age=[1,1],Asu=[4,4]
   //-------------------------------------------------------
   // 
   // 5x5 Lanes of 64-bits each
   wire [0:`SHA3_W-1] Ako, Aku, Aka, Ake, Aki;     // x={3,4,0,1,2} ; y=2
   wire [0:`SHA3_W-1] Ago, Agu, Aga, Age, Agi;     // x={3,4,0,1,2} ; y=1
   wire [0:`SHA3_W-1] Abo, Abu, Aba, Abe, Abi;     // x={3,4,0,1,2} ; y=0
   wire [0:`SHA3_W-1] Aso, Asu, Asa, Ase, Asi;     // x={3,4,0,1,2} ; y=4
   wire [0:`SHA3_W-1] Amo, Amu, Ama, Ame, Ami;     // x={3,4,0,1,2} ; y=3

   // represents Lanes [0:24]   // (x,y)
   assign Aba = A_array[ 0];    // (0,0)
   assign Abe = A_array[ 1];    // (1,0)
   assign Abi = A_array[ 2];    // (2,0)
   assign Abo = A_array[ 3];    // (3,0)
   assign Abu = A_array[ 4];    // (4,0)
   assign Aga = A_array[ 5];    // (0,1)
   assign Age = A_array[ 6];    // (1,1)
   assign Agi = A_array[ 7];    // (2,1)
   assign Ago = A_array[ 8];    // (3,1)
   assign Agu = A_array[ 9];    // (4,1)
   assign Aka = A_array[10];    // (0,2)
   assign Ake = A_array[11];    // (1,2)
   assign Aki = A_array[12];    // (2,2)
   assign Ako = A_array[13];    // (3,2)
   assign Aku = A_array[14];    // (4,2)
   assign Ama = A_array[15];    // (0,3)
   assign Ame = A_array[16];    // (1,3)
   assign Ami = A_array[17];    // (2,3)
   assign Amo = A_array[18];    // (3,3)
   assign Amu = A_array[19];    // (4,3)
   assign Asa = A_array[20];    // (0,4)
   assign Ase = A_array[21];    // (1,4)
   assign Asi = A_array[22];    // (2,4)
   assign Aso = A_array[23];    // (3,4)
   assign Asu = A_array[24];    // (4,4)


   //-------------------------------------------------------
   // prepare theta  (XOR columns)
   // one-time per round; 
   //-------------------------------------------------------

   // column XOR of each bit of lanes of respective column bit
   // BC[x,z]=^(A[x,{0..4},z])
   wire [0:`SHA3_W-1] BCa = Aba^Aga^Aka^Ama^Asa;    // 0^5^10^15^20
   wire [0:`SHA3_W-1] BCe = Abe^Age^Ake^Ame^Ase;    // 1^6^11^16^21
   wire [0:`SHA3_W-1] BCi = Abi^Agi^Aki^Ami^Asi;    // 2^7^12^17^22
   wire [0:`SHA3_W-1] BCo = Abo^Ago^Ako^Amo^Aso;    // 3^8^13^18^23
   wire [0:`SHA3_W-1] BCu = Abu^Agu^Aku^Amu^Asu;    // 4^9^14^19^24

   //SHIFT circular Left 1-bit in Z axis
   wire [0:`SHA3_W-1] BCa_zminus1 = {BCa[1:`SHA3_W-1],BCa[0]};   // (z-1)mod w
   wire [0:`SHA3_W-1] BCe_zminus1 = {BCe[1:`SHA3_W-1],BCe[0]};   // (z-1)mod w
   wire [0:`SHA3_W-1] BCi_zminus1 = {BCi[1:`SHA3_W-1],BCi[0]};   // (z-1)mod w
   wire [0:`SHA3_W-1] BCo_zminus1 = {BCo[1:`SHA3_W-1],BCo[0]};   // (z-1)mod w
   wire [0:`SHA3_W-1] BCu_zminus1 = {BCu[1:`SHA3_W-1],BCu[0]};   // (z-1)mod w

   // pre theta (Dx)
   // D[x,z]=C[(x-1)mod5,z]^C[(x+1)mod5,(z-1)mod w]
   wire [0:`SHA3_W-1] Da = BCu^BCe_zminus1;    // D(x,z)=C(z)^C(z-1)
   wire [0:`SHA3_W-1] De = BCa^BCi_zminus1;    // D(x,z)=C(z)^C(z-1)
   wire [0:`SHA3_W-1] Di = BCe^BCo_zminus1;    // D(x,z)=C(z)^C(z-1)
   wire [0:`SHA3_W-1] Do = BCi^BCu_zminus1;    // D(x,z)=C(z)^C(z-1)
   wire [0:`SHA3_W-1] Du = BCo^BCa_zminus1;    // D(x,z)=C(z)^C(z-1)

   
  
   //-------------------------------------------------------
   // Theta : XOR each bit in the state with the parities of two columns in
   // the array. 
   // A'[x,y,z]=A[x,y,z]^D[x,z]
   //-------------------------------------------------------

   // 5x5 Lanes of 64-bits each
   wire [0:`SHA3_W-1] Ako_theta, Aku_theta, Aka_theta, Ake_theta, Aki_theta;    // x={3,4,0,1,2} ; y=2
   wire [0:`SHA3_W-1] Ago_theta, Agu_theta, Aga_theta, Age_theta, Agi_theta;    // x={3,4,0,1,2} ; y=1
   wire [0:`SHA3_W-1] Abo_theta, Abu_theta, Aba_theta, Abe_theta, Abi_theta;    // x={3,4,0,1,2} ; y=0
   wire [0:`SHA3_W-1] Aso_theta, Asu_theta, Asa_theta, Ase_theta, Asi_theta;    // x={3,4,0,1,2} ; y=4
   wire [0:`SHA3_W-1] Amo_theta, Amu_theta, Ama_theta, Ame_theta, Ami_theta;    // x={3,4,0,1,2} ; y=3

   assign Aba_theta = Aba ^ Da;    // xor with 2 adjacent columns
   assign Abe_theta = Abe ^ De;    // xor with 2 adjacent columns
   assign Abi_theta = Abi ^ Di;    // xor with 2 adjacent columns
   assign Abo_theta = Abo ^ Do;    // xor with 2 adjacent columns
   assign Abu_theta = Abu ^ Du;    // xor with 2 adjacent columns

   assign Aga_theta = Aga ^ Da;    // xor with 2 adjacent columns
   assign Age_theta = Age ^ De;    // xor with 2 adjacent columns
   assign Agi_theta = Agi ^ Di;    // xor with 2 adjacent columns
   assign Ago_theta = Ago ^ Do;    // xor with 2 adjacent columns
   assign Agu_theta = Agu ^ Du;    // xor with 2 adjacent columns

   assign Aka_theta = Aka ^ Da;    // xor with 2 adjacent columns
   assign Ake_theta = Ake ^ De;    // xor with 2 adjacent columns
   assign Aki_theta = Aki ^ Di;    // xor with 2 adjacent columns
   assign Ako_theta = Ako ^ Do;    // xor with 2 adjacent columns
   assign Aku_theta = Aku ^ Du;    // xor with 2 adjacent columns

   assign Ama_theta = Ama ^ Da;    // xor with 2 adjacent columns
   assign Ame_theta = Ame ^ De;    // xor with 2 adjacent columns
   assign Ami_theta = Ami ^ Di;    // xor with 2 adjacent columns
   assign Amo_theta = Amo ^ Do;    // xor with 2 adjacent columns
   assign Amu_theta = Amu ^ Du;    // xor with 2 adjacent columns

   assign Asa_theta = Asa ^ Da;    // xor with 2 adjacent columns
   assign Ase_theta = Ase ^ De;    // xor with 2 adjacent columns
   assign Asi_theta = Asi ^ Di;    // xor with 2 adjacent columns
   assign Aso_theta = Aso ^ Do;    // xor with 2 adjacent columns
   assign Asu_theta = Asu ^ Du;    // xor with 2 adjacent columns

   //-------------------------------------------------------
   // Rho  (shift Z-axis) 
   // A'[x,y,z] = A[x,y,(z-(t+1)(t+2)/2)mod w]
   // Assume SHA3(256) uses w=64
   // x = {3  4  0  1  2} right 
   // y
   // 2   25 39  3 10 43      Ako, Aku, Aka, Ake, Aki; 
   // 1   55 20 36 44  6      Ago, Agu, Aga, Age, Agi;
   // 0   28 27  0  1 62      Abo, Abu, Aba, Abe, Abi;
   // 4   56 14 18  2 61      Aso, Asu, Asa, Ase, Asi;
   // 3   21  8 41 45 15      Amo, Amu, Ama, Ame, Ami;
   //-------------------------------------------------------
   //
   // 5x5 Lanes of 64-bits each
   wire [0:`SHA3_W-1] Ako_rho, Aku_rho, Aka_rho, Ake_rho, Aki_rho;    // x={3,4,0,1,2} ; y=2
   wire [0:`SHA3_W-1] Ago_rho, Agu_rho, Aga_rho, Age_rho, Agi_rho;    // x={3,4,0,1,2} ; y=1
   wire [0:`SHA3_W-1] Abo_rho, Abu_rho, Aba_rho, Abe_rho, Abi_rho;    // x={3,4,0,1,2} ; y=0
   wire [0:`SHA3_W-1] Aso_rho, Asu_rho, Asa_rho, Ase_rho, Asi_rho;    // x={3,4,0,1,2} ; y=4
   wire [0:`SHA3_W-1] Amo_rho, Amu_rho, Ama_rho, Ame_rho, Ami_rho;    // x={3,4,0,1,2} ; y=3


   // SHIFT LEFT (circular)
   assign Aba_rho =  Aba_theta;                          // circular shift=0
   assign Abe_rho = {Abe_theta[ 1:63],Abe_theta[   0]};  // circular shift=1
   assign Abi_rho = {Abi_theta[62:63],Abi_theta[0:61]};  // circular shift=62
   assign Abo_rho = {Abo_theta[28:63],Abo_theta[0:27]};  // circular shift=28
   assign Abu_rho = {Abu_theta[27:63],Abu_theta[0:26]};  // circular shift=27

   assign Aga_rho = {Aga_theta[36:63],Aga_theta[0:35]};  // circular shift=36
   assign Age_rho = {Age_theta[44:63],Age_theta[0:43]};  // circular shift=44
   assign Agi_rho = {Agi_theta[ 6:63],Agi_theta[0: 5]};  // circular shift=6
   assign Ago_rho = {Ago_theta[55:63],Ago_theta[0:54]};  // circular shift=55
   assign Agu_rho = {Agu_theta[20:63],Agu_theta[0:19]};  // circular shift=20

   assign Aka_rho = {Aka_theta[ 3:63],Aka_theta[0: 2]};  // circular shift=3
   assign Ake_rho = {Ake_theta[10:63],Ake_theta[0: 9]};  // circular shift=10
   assign Aki_rho = {Aki_theta[43:63],Aki_theta[0:42]};  // circular shift=43
   assign Ako_rho = {Ako_theta[25:63],Ako_theta[0:24]};  // circular shift=25
   assign Aku_rho = {Aku_theta[39:63],Aku_theta[0:38]};  // circular shift=39

   assign Ama_rho = {Ama_theta[41:63],Ama_theta[0:40]};  // circular shift=41
   assign Ame_rho = {Ame_theta[45:63],Ame_theta[0:44]};  // circular shift=45
   assign Ami_rho = {Ami_theta[15:63],Ami_theta[0:14]};  // circular shift=15
   assign Amo_rho = {Amo_theta[21:63],Amo_theta[0:20]};  // circular shift=21
   assign Amu_rho = {Amu_theta[ 8:63],Amu_theta[0: 7]};  // circular shift=8

   assign Asa_rho = {Asa_theta[18:63],Asa_theta[0:17]};  // circular shift=18
   assign Ase_rho = {Ase_theta[ 2:63],Ase_theta[0: 1]};  // circular shift=2
   assign Asi_rho = {Asi_theta[61:63],Asi_theta[0:60]};  // circular shift=61
   assign Aso_rho = {Aso_theta[56:63],Aso_theta[0:55]};  // circular shift=56
   assign Asu_rho = {Asu_theta[14:63],Asu_theta[0:13]};  // circular shift=14


   //-------------------------------------------------------
   // Pi : rearrange positions of the lanes
   // A'(x,y)=A(y,(2x+3y)mod5)
   //-------------------------------------------------------

   // 5x5 Lanes of 64-bits each
   wire [0:`SHA3_W-1] Ako_pi, Aku_pi, Aka_pi, Ake_pi, Aki_pi;    // x={3,4,0,1,2} ; y=2
   wire [0:`SHA3_W-1] Ago_pi, Agu_pi, Aga_pi, Age_pi, Agi_pi;    // x={3,4,0,1,2} ; y=1
   wire [0:`SHA3_W-1] Abo_pi, Abu_pi, Aba_pi, Abe_pi, Abi_pi;    // x={3,4,0,1,2} ; y=0
   wire [0:`SHA3_W-1] Aso_pi, Asu_pi, Asa_pi, Ase_pi, Asi_pi;    // x={3,4,0,1,2} ; y=4
   wire [0:`SHA3_W-1] Amo_pi, Amu_pi, Ama_pi, Ame_pi, Ami_pi;    // x={3,4,0,1,2} ; y=3

   assign Aba_pi = Aba_rho ;
   assign Abe_pi = Age_rho ;   // from Age after rho
   assign Abi_pi = Aki_rho ;   // from Aki after rho
   assign Abo_pi = Amo_rho ;   // from Amo after rho
   assign Abu_pi = Asu_rho ;   // from Asu after rho

   assign Aga_pi = Abo_rho ;   // from Abo after rho
   assign Age_pi = Agu_rho ;   // from Agu after rho
   assign Agi_pi = Aka_rho ;   // from Aka after rho
   assign Ago_pi = Ame_rho ;   // from Ame after rho
   assign Agu_pi = Asi_rho ;   // from Asi after rho

   assign Aka_pi = Abe_rho ;   // from Abe after rho
   assign Ake_pi = Agi_rho ;   // from Agi after rho
   assign Aki_pi = Ako_rho ;   // from Ako after rho
   assign Ako_pi = Amu_rho ;   // from Amu after rho
   assign Aku_pi = Asa_rho ;   // from Asa after rho

   assign Ama_pi = Abu_rho ;   // from Abu after rho
   assign Ame_pi = Aga_rho ;   // from Aga after rho
   assign Ami_pi = Ake_rho ;   // from Ake after rho
   assign Amo_pi = Ami_rho ;   // from Ami after rho
   assign Amu_pi = Aso_rho ;   // from Aso after rho

   assign Asa_pi = Abi_rho ;   // from Abi after rho
   assign Ase_pi = Ago_rho ;   // from Ago after rho
   assign Asi_pi = Aku_rho ;   // from Aku after rho
   assign Aso_pi = Ama_rho ;   // from Ama after rho
   assign Asu_pi = Ase_rho ;   // from Ase after rho


   //-------------------------------------------------------
   // Chi : XOR each bit with a non-linear function of next two bits in its
   // row from *_pi
   // A'[x,y,z]=A[x,y,z]^( !A[(x+1)mod5,y,z] & A[(x+2)mod5,y,z] )
   //-------------------------------------------------------

   // 5x5 Lanes of 64-bits each
   wire [0:`SHA3_W-1] Ako_chi, Aku_chi, Aka_chi, Ake_chi, Aki_chi;    // x={3,4,0,1,2} ; y=2
   wire [0:`SHA3_W-1] Ago_chi, Agu_chi, Aga_chi, Age_chi, Agi_chi;    // x={3,4,0,1,2} ; y=1
   wire [0:`SHA3_W-1] Abo_chi, Abu_chi, Aba_chi, Abe_chi, Abi_chi;    // x={3,4,0,1,2} ; y=0
   wire [0:`SHA3_W-1] Aso_chi, Asu_chi, Asa_chi, Ase_chi, Asi_chi;    // x={3,4,0,1,2} ; y=4
   wire [0:`SHA3_W-1] Amo_chi, Amu_chi, Ama_chi, Ame_chi, Ami_chi;    // x={3,4,0,1,2} ; y=3

   assign Aba_chi = Aba_pi ^ ( ~Abe_pi & Abi_pi ) ;
   assign Abe_chi = Abe_pi ^ ( ~Abi_pi & Abo_pi ) ;
   assign Abi_chi = Abi_pi ^ ( ~Abo_pi & Abu_pi ) ;
   assign Abo_chi = Abo_pi ^ ( ~Abu_pi & Aba_pi ) ;
   assign Abu_chi = Abu_pi ^ ( ~Aba_pi & Abe_pi ) ;

   assign Aga_chi = Aga_pi ^ ( ~Age_pi & Agi_pi ) ;
   assign Age_chi = Age_pi ^ ( ~Agi_pi & Ago_pi ) ;
   assign Agi_chi = Agi_pi ^ ( ~Ago_pi & Agu_pi ) ;
   assign Ago_chi = Ago_pi ^ ( ~Agu_pi & Aga_pi ) ;
   assign Agu_chi = Agu_pi ^ ( ~Aga_pi & Age_pi ) ;

   assign Aka_chi = Aka_pi ^ ( ~Ake_pi & Aki_pi ) ;
   assign Ake_chi = Ake_pi ^ ( ~Aki_pi & Ako_pi ) ;
   assign Aki_chi = Aki_pi ^ ( ~Ako_pi & Aku_pi ) ;
   assign Ako_chi = Ako_pi ^ ( ~Aku_pi & Aka_pi ) ;
   assign Aku_chi = Aku_pi ^ ( ~Aka_pi & Ake_pi ) ;

   assign Ama_chi = Ama_pi ^ ( ~Ame_pi & Ami_pi ) ;
   assign Ame_chi = Ame_pi ^ ( ~Ami_pi & Amo_pi ) ;
   assign Ami_chi = Ami_pi ^ ( ~Amo_pi & Amu_pi ) ;
   assign Amo_chi = Amo_pi ^ ( ~Amu_pi & Ama_pi ) ;
   assign Amu_chi = Amu_pi ^ ( ~Ama_pi & Ame_pi ) ;

   assign Asa_chi = Asa_pi ^ ( ~Ase_pi & Asi_pi ) ;
   assign Ase_chi = Ase_pi ^ ( ~Asi_pi & Aso_pi ) ;
   assign Asi_chi = Asi_pi ^ ( ~Aso_pi & Asu_pi ) ;
   assign Aso_chi = Aso_pi ^ ( ~Asu_pi & Asa_pi ) ;
   assign Asu_chi = Asu_pi ^ ( ~Asa_pi & Ase_pi ) ;


   //-------------------------------------------------------
   // Iota : the effect is to modify some of the bits in Lane(0,0) in a manner
   // that depends on the round index ir.  The other 24 lanes are not 
   // affected.
   //-------------------------------------------------------
   //
   // select RoundConstant
   wire [0:`SHA3_W-1] rc = RoundConstants[round_i] ; 

   wire [0:`SHA3_W-1] Aba_rc;  // (0,0)
   assign Aba_rc = Aba_chi ^ rc ; 
    

   //-------------------------------------------------------
   // Output Assignment 
   //-------------------------------------------------------

   assign Aba_o = Aba_rc ;    // (0,0) , only one with RC
   assign Abe_o = Abe_chi;    // (1,0)
   assign Abi_o = Abi_chi;    // (2,0)
   assign Abo_o = Abo_chi;    // (3,0)
   assign Abu_o = Abu_chi;    // (4,0)
   assign Aga_o = Aga_chi;    // (0,1)
   assign Age_o = Age_chi;    // (1,1)
   assign Agi_o = Agi_chi;    // (2,1)
   assign Ago_o = Ago_chi;    // (3,1)
   assign Agu_o = Agu_chi;    // (4,1)
   assign Aka_o = Aka_chi;    // (0,2)
   assign Ake_o = Ake_chi;    // (1,2)
   assign Aki_o = Aki_chi;    // (2,2)
   assign Ako_o = Ako_chi;    // (3,2)
   assign Aku_o = Aku_chi;    // (4,2)
   assign Ama_o = Ama_chi;    // (0,3)
   assign Ame_o = Ame_chi;    // (1,3)
   assign Ami_o = Ami_chi;    // (2,3)
   assign Amo_o = Amo_chi;    // (3,3)
   assign Amu_o = Amu_chi;    // (4,3)
   assign Asa_o = Asa_chi;    // (0,4)
   assign Ase_o = Ase_chi;    // (1,4)
   assign Asi_o = Asi_chi;    // (2,4)
   assign Aso_o = Aso_chi;    // (3,4)
   assign Asu_o = Asu_chi;    // (4,4)


endmodule

