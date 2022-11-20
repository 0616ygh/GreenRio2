#include<svdpi.h>

void lsu(
     const  svBit        clk                 ,
     const  svBit        lsu_rob_valid_i     ,
     const  long long   * lsu_rob_index_i     ,
     const  long long   * lsu_prd_address_i   ,
     const  long long   * lsu_rs1_data_i      ,
     const  long long   * lsu_rs2_data_i      ,
     const  long long   * lsu_imm_i           ,
     const  svBit        lsu_is_load_i       ,
     const  svBit        lsu_is_store_i      ,
     const  svBit        lsu_wakeup_i        ,
            svBit        lsu_rcu_valid_o     ,  
            svBit        lsu_rcu_ready_o     ,  
            long long   * lsu_prd_address_o   ,
            long long   * lsu_wrb_data_o      ,
            long long   * lsu_rob_index_o     ,
            svBit        lsu_rcu_excep_o     ,
            long long   * lsu_rcu_ecause_o    
    ){
      // wakeup queue to do
      typedef struct{
        svBit rob_valid_i   ;
        long long rob_index_i    ;
        long long prd_address_i  ;
        long long rs1_data_i     ;
        long long rs2_data_i     ;
        long long imm_i          ;
        svBit is_load_i     ;
        svBit is_store_i    ;
      }lsu_in_t;
      typedef struct{
        svBit valid_o       ;
        svBit ready_o       ;
        long long prd_address_o  ;
        long long wrb_data_o     ;
        long long index_o        ;
        svBit excep_o       ;
        long long ecause_o       ;
      }lsu_out_t;

      static int comb_lsu_valid_o       ;
      static int comb_lsu_ready_o       ;
      static long long comb_lsu_prd_address_o ;
      static long long comb_lsu_wrb_data_o    ;
      static long long comb_lsu_index_o       ;
      static int comb_lsu_excep_o       ;
      static long long comb_lsu_ecause_o      ;

      long long mem[5000];
      for (int i; i < 5000; i++){
        mem[i] = 0;
      }
      
      comb_lsu_ready_o = 1;

      if(clk) {
        if(lsu_is_load_i){
          comb_lsu_valid_o       =  lsu_rob_valid_i;
          comb_lsu_ready_o       = 1;                 //FIX when cooperate with wakeup signal
          comb_lsu_prd_address_o = * lsu_prd_address_i;
          comb_lsu_wrb_data_o    = mem[*lsu_rs1_data_i + *lsu_imm_i];
          comb_lsu_index_o       = * lsu_rob_index_i;
          comb_lsu_excep_o       = 0;
          comb_lsu_ecause_o      = 0;
        } else if(lsu_is_store_i) {
          comb_lsu_valid_o       =  lsu_rob_valid_i;
          comb_lsu_ready_o       = 1;
          comb_lsu_prd_address_o = * lsu_prd_address_i;
          mem[*lsu_rs1_data_i + *lsu_imm_i]    = * lsu_rs2_data_i;
          comb_lsu_index_o       = * lsu_rob_index_i;
          comb_lsu_excep_o       = 0;
          comb_lsu_ecause_o      = 0;
        } else {
          comb_lsu_valid_o       = 0;
          comb_lsu_ready_o       = 1;
          comb_lsu_prd_address_o = 0;
          comb_lsu_wrb_data_o    = 0;
          comb_lsu_index_o       = 0;
          comb_lsu_excep_o       = 0;
          comb_lsu_ecause_o      = 0;
        }
      } 
      if (!clk) {
         lsu_rcu_valid_o    = comb_lsu_valid_o       ;
         lsu_rcu_ready_o    = comb_lsu_ready_o       ;
        * lsu_prd_address_o = comb_lsu_prd_address_o ;
        * lsu_wrb_data_o    = comb_lsu_wrb_data_o    ;
        * lsu_rob_index_o   = comb_lsu_index_o       ;
         lsu_rcu_excep_o    = comb_lsu_excep_o       ;
        * lsu_rcu_ecause_o  = comb_lsu_ecause_o      ;
      }
    }