#include <verilated.h>

#include <iostream>

#include "verilated_vcd_c.h"
#include "Vfu.h"
#define CODING 0

const uint64_t MAX_TIME = 10;
uint64_t main_time = 0;
Vfu *tb;

void printInfo(Vfu * tb);

#ifdef CODING
int rcu_fu_alu1_rs1_i        ;
int rcu_fu_alu2_rs1_i        ;
int rcu_fu_alu1_rs2_i        ;
int rcu_fu_alu2_rs2_i        ;
int rcu_fu_alu1_imm_data_i   ;
int rcu_fu_alu2_imm_data_i   ;
int rcu_fu_alu1_opr1_sel_i   ;
int rcu_fu_alu2_opr1_sel_i   ;
int rcu_fu_alu1_opr2_sel_i   ;
int rcu_fu_alu2_opr2_sel_i   ;
int rcu_fu_alu1_opr1_i;
int rcu_fu_alu2_opr1_i;
int rcu_fu_alu1_opr2_i;
int rcu_fu_alu2_opr2_i;
int rcu_fu_alu1_cmp_opr1_i;
int rcu_fu_alu2_cmp_opr1_i;
int rcu_fu_alu1_cmp_opr2_i;
int rcu_fu_alu2_cmp_opr2_i;
int rcu_fu_alu1_rob_index_i;
int rcu_fu_alu2_rob_index_i;
int rcu_fu_alu1_prd_addr_i;
int rcu_fu_alu2_prd_addr_i;
int rcu_fu_alu1_is_branch_i;
int rcu_fu_alu2_is_branch_i;
int rcu_fu_alu1_is_jump_i  ;
int rcu_fu_alu2_is_jump_i  ;
int rcu_fu_alu1_req_valid_i;
int rcu_fu_alu2_req_valid_i;
int rcu_fu_alu1_pc_i;
int rcu_fu_alu2_pc_i;
int rcu_fu_alu1_next_pc_i;
int rcu_fu_alu2_next_pc_i;
int rcu_fu_alu1_func_sel_i;
int rcu_fu_alu2_func_sel_i;
int fu_rcu_alu1_resp_valid_o;
int fu_rcu_alu2_resp_valid_o;
int fu_rcu_alu1_wrb_rob_index_o;
int fu_rcu_alu2_wrb_rob_index_o;
int fu_rcu_alu1_wrb_enable_o;
int fu_rcu_alu2_wrb_enable_o;
int fu_rcu_alu1_wrb_prd_addr_o;
int fu_rcu_alu2_wrb_prd_addr_o;
int fu_rcu_alu1_wrb_data_o;
int fu_rcu_alu2_wrb_data_o;
int fu_ft_br_resp_valid_o;
int rcu_fu_alu1_predict_pc_i;
int rcu_fu_alu2_predict_pc_i;
int fu_rcu_alu1_branch_predict_miss_o;
#endif


int main(int argc, char **argv, char **env) {
    Verilated::debug(0);
    Verilated::randReset(0);
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);
    VerilatedVcdC* tfp = new VerilatedVcdC();
    tb = new Vfu;
    tb->trace(tfp, 0);
    tfp->open("fuwave.vcd");
    //initialization
    tb->clk = 0;
    tb->rstn = 0;
    tb->wfi = 0;
    tb->trap = 0;
   // <> RCU

    tb->rcu_fu_alu1_rob_index_i = 0;
    tb->rcu_fu_alu2_rob_index_i = 0;
    tb->rcu_fu_alu1_prd_addr_i = 0;
    tb->rcu_fu_alu2_prd_addr_i = 0;
    tb->rcu_fu_alu1_is_branch_i = 0; // if branch or jump, set 1
    tb->rcu_fu_alu2_is_branch_i = 0; // if branch or jump, set 1
    tb->rcu_fu_alu1_is_jump_i = 0; // if jump, set 1
    tb->rcu_fu_alu2_is_jump_i = 0; // if jump, set 1
    tb->rcu_fu_alu1_req_valid_i = 0;
    tb->rcu_fu_alu2_req_valid_i = 0;
    // alu & cmp
    tb->rcu_fu_alu1_half_i = 0;
    tb->rcu_fu_alu2_half_i = 0;
    tb->rcu_fu_alu1_pc_i = 0;
    tb->rcu_fu_alu2_pc_i = 0;
    tb->rcu_fu_alu1_next_pc_i, // for jal to w = 0;
    tb->rcu_fu_alu2_next_pc_i, // for jal to w = 0;
    tb->rcu_fu_alu1_func3_i = 0;
    tb->rcu_fu_alu2_func3_i = 0;
    tb->rcu_fu_alu1_func_modifier_i = 0;
    tb->rcu_fu_alu2_func_modifier_i = 0;
 
    while (main_time < MAX_TIME) {
      if (main_time % 2 == 1) {
          tb->clk = 1;
      } else {
          tb->clk = 0;
      }

      switch(main_time) {
        case 4:{ //123+456

          tb->rcu_fu_alu1_rs1_i = 10;
          tb->rcu_fu_alu2_rs1_i = 235;
          tb->rcu_fu_alu1_rs2_i = 6;
          tb->rcu_fu_alu2_rs2_i = 568;
          tb->rcu_fu_alu1_imm_data_i = 10;
          tb->rcu_fu_alu1_opr1_sel_i = 2;
          tb->rcu_fu_alu2_opr1_sel_i = 0;
          tb->rcu_fu_alu1_opr2_sel_i = 1;
          tb->rcu_fu_alu2_opr2_sel_i = 0;
          tb->rcu_fu_alu1_rob_index_i = 4;
          tb->rcu_fu_alu2_rob_index_i = 3;
          // tb->rcu_fu_alu1_prd_addr_i = 3;
          tb->rcu_fu_alu2_prd_addr_i = 1;
          tb->rcu_fu_alu1_is_branch_i = 1;
          tb->rcu_fu_alu2_is_branch_i = 0;
          tb->rcu_fu_alu1_is_jump_i = 0;
          tb->rcu_fu_alu2_is_jump_i = 0;
          tb->rcu_fu_alu1_req_valid_i = 1;
          tb->rcu_fu_alu2_req_valid_i  = 1;
          tb->rcu_fu_alu1_pc_i = 5;
          tb->rcu_fu_alu2_pc_i = 6;
          tb->rcu_fu_alu1_next_pc_i = 7;
          tb->rcu_fu_alu2_next_pc_i = 8;
          tb->rcu_fu_alu1_func3_i = 0;
          tb->rcu_fu_alu2_func3_i = 0;
          tb->rcu_fu_alu1_predict_pc_i = 15;

         break;
        }
        case 6: {
          if(!(
              tb->fu_rcu_alu1_resp_valid_o == 1 &&
              tb->fu_rcu_alu2_resp_valid_o == 1 &&
              tb->fu_rcu_alu1_wrb_rob_index_o == 4 &&
              tb->fu_rcu_alu2_wrb_rob_index_o == 3 &&
              tb->fu_rcu_alu1_wrb_enable_o == 0 &&
              tb->fu_rcu_alu2_wrb_enable_o == 1 &&
              tb->fu_rcu_alu2_wrb_prd_addr_o == 1 &&
              tb->fu_rcu_alu1_wrb_data_o == 15 &&
              tb->fu_rcu_alu2_wrb_data_o == 803 &&
              fu_rcu_alu1_branch_predict_miss_o == 0
            )
          ){
            printf("FAILED: Case 6");

          }
          printf("PASS!  Case 6");

          break;
        }
      } 
      tb->eval();
      tfp->dump(main_time);
    //  printInfo(tb);
      main_time ++;
    }
    
    printf("DONE\n");
    tb->final();
    tfp->close();
    delete tfp;
    delete tb;
    exit(0);
}
