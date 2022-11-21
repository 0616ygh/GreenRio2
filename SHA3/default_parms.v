// default_parms.sv
//`define NOXCVR
`define PARMS                                                         /*                                                                 */  
                                                                      /*                                                                 */  
`define SHA3_B             1600                                       /*  bit width of Keccak-p permuation                               */  
`define SHA3_W             64                                         /*  (64) lane size of Keccak-p permuation in bits                  */  
`define SHA3_NROUNDS       24                                         /*  Max rounds Keccak-p permutation 1600 = 12+2*SHA3_L =12+2*6 =24 */  
`define SHA3_D             256                                        /*  digest length for sha3                                         */  
`define SHA3_BITLEN        11                                         /*  Bit length {0..1088}                                           */  
`define SHA3_L             25                                         /*  Number of lanes of W-bits                                      */  

// good info but not used
//`define SHA3_RATEBIT_MAX   1344                                     /*  RATE in bits length                                            */  
//`define SHA3_R             21                                       /*  RATE in W-Bit length (RATEBIT/W)                               */  
//`define SHA3_L             $clog2(SHA3_W)                           /*  (6)  binary log of lane size (log2(w)) of Keccak-p permutation */  
//`define SHA3_256_C         512                                      /*  Capacity in bits= 2*DIGEST length = 2*256=512 for sha3(256)    */  
//`define SHA3_256_RATEBITS  1088                                     /*  Rate in bits =1600-Capacity =1600-512=1088 in bits for sha3(256) */  
//`define SHA3_256_RATEBYTE  136                                      /*  Rate in bytes = Ratebits/8 = 1088/8 = 136 in bytes for sha3(256) */  
//`define SHA128_RATEBITS  1344                                       /*  Rate in bits =1600-Capacity =1600-512=1088 in bits for sha3(256) */  
//`define SHA128_RATEBYTE  168                                        /*  Rate in bytes = Ratebits/8 = 1088/8 = 136 in bytes for sha3(256) */  
//`define SHA3256_R        17                                         /*  SpongeRate = Ratebits/W = 1088/64 = 17 (multiple of W and <1600) */  
//`define SHAKE128_R       21                                         /*  SpongeRate = Ratebits/W = 1088/64 = 17 (multiple of W and <1600) */  
                                                                      /*                                                                 */  
/* MISC                                                                                                                                  */
