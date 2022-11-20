#include <verilated.h>

#include <iostream>

#include "verilated_vcd_c.h"
#include "Valu.h"

const uint64_t MAX_TIME = 10;
uint64_t main_time = 0;
Valu *tb;

void printInfo(Valu * tb);

int main(int argc, char **argv, char **env) {
    Verilated::debug(0);
    Verilated::randReset(0);
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);
    VerilatedVcdC* tfp = new VerilatedVcdC();
    tb = new Valu;
    tb->trace(tfp, 0);
    tfp->open("aluwave.vcd");
    //initialization
    tb->clk = 0;
    tb->rstn = 0;
    tb->wfi = 0;
    tb->trap = 0;
    tb->opr1_i = 0;
    tb->opr2_i = 0;
    tb->half_i = 0;
    tb->alu_function_select_i = 0;  //alu_function_out = 0;
    tb->function_modifier_i = 0;
    tb->rob_index_i = 0;
    tb->prd_addr_i = 0;
    tb->rcu_fu_alu_req_valid_i = 0;
    tb->rcu_fu_alu_req_ready_o = 0;

// branch
    tb->cmp_function_select_i = 0;
    tb->is_jump_i = 0;
    tb->is_branch_i = 0;
    tb->pc_i = 0;
    tb->next_pc_i = 0;  //pc +  = 0;
    while (main_time < MAX_TIME) {
      if (main_time % 2 == 1) {
          tb->clk = 1;
      } else {
          tb->clk = 0;
      }

      switch(main_time) {
        case 4:{ //123+456
          tb->pc_i = 20;
          tb->next_pc_i = 24;
          tb->opr1_i = 123;
          tb->opr2_i = 456;
          tb->alu_function_select_i = 000;
          tb->rob_index_i = 3;
          tb->prd_addr_i = 4;
          tb->rcu_fu_alu_req_valid_i = 1;
          break;
        }
        case 6: {
          if(!(
            tb->alu_result_o == 579 && 
            tb->prd_addr_o == 4 &&
            tb->rob_index_o == 3 &&
            tb->fu_rcu_alu_resp_valid_o == 1 &&
            tb->is_branch_o == 0 &&
            tb->is_jump_o == 0 &&
            tb->pc_o == 20 &&
            tb->next_pc_o == 24
            )
          ){
            printf("!!!!WRONG in case 6\n");
          }
          tb->pc_i = 24;
          tb->next_pc_i = 28;
          tb->opr1_i = 24;
          tb->opr2_i = -4;
          tb->alu_function_select_i = 000;
          tb->rob_index_i = 4;
          tb->prd_addr_i = 0;
          tb->rcu_fu_alu_req_valid_i = 1;
          tb->is_jump_i = 0;
          tb->is_branch_i = 1;
          tb->cmp_input_a_i = 2;
          tb->cmp_input_b_i = 3;
          tb->cmp_function_select_i = 0;
          break;
        }
        case 8 :{
          if(!(
              tb->alu_result_o == 20 &&
              tb->prd_addr_o == 0 &&
              tb->rob_index_o == 4 &&
              tb->fu_rcu_alu_resp_valid_o == 1 &&
              tb->is_branch_o == 1 &&
              tb->is_jump_o == 0 &&
              tb->pc_o == 24 &&
              tb->next_pc_o == 28
            )
          ){
            printf("FAULT IN CASE 8");
          }
          break;
        }
      } 
      printf("dump %d \n" , main_time);
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


void printInfo(Valu * tb){
  printf("alu_result_o : %d, prd_addr_o : %d, rob_index_o : %d,  fu_rcu_alu_resp_valid_o: %d,  is_branch_o: %d,  \
  is_jump_o : %d, pc_o : %d, next_pc_o : %d\n", 
  tb->alu_result_o, tb->prd_addr_o, tb->rob_index_o, tb->fu_rcu_alu_resp_valid_o, tb->is_branch_o, tb->is_jump_o,
  tb->pc_o, tb->next_pc_o);
}