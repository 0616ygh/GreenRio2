#include <verilated.h>

#include <iostream>

#include "verilated_vcd_c.h"
#include "Vmd.h"
//#define CODING 0

const uint64_t MAX_TIME = 200;
uint64_t main_time = 0;
Vmd *tb;

void printInfo(Vmd * tb);

#ifdef CODING
int fu_md_prd_addr_i;
int fu_md_oprd1_i;
int fu_md_oprd2_i; //  v 1
int fu_md_rob_index_i;
int fu_md_md_op_i;    //  v 1
int fu_md_muldiv_i;   //  v 1
int fu_md_req_valid_i;    //  v 1
int fu_md_req_ready_o;    //  v 1
int  md_fu_wrb_prd_addr_o;
int md_fu_wrb_rob_index_o;
int  md_fu_wrb_data_o;   //  v  1
int  md_fu_wrb_resp_valid_o;    //  v  1

#endif


int main(int argc, char **argv, char **env) {
    Verilated::debug(0);
    Verilated::randReset(0);
    Verilated::traceEverOn(true);
    Verilated::commandArgs(argc, argv);
    VerilatedVcdC* tfp = new VerilatedVcdC();
    tb = new Vmd;
    tb->trace(tfp, 0);
    tfp->open("mdwave.vcd");
    //initialization
    tb->clk = 0;
    tb->rst = 0;
    tb->trap = 0;
    tb->fu_md_prd_addr_i = 0;
    tb->fu_md_oprd1_i = 0;
    tb->fu_md_oprd2_i = 0; //  v 1
    tb->fu_md_rob_index_i = 0;
    tb->fu_md_md_op_i = 0;    //  v 1
    tb->fu_md_muldiv_i = 0;   //  v 1
    tb->fu_md_req_valid_i = 0;    //  v 1
    tb->fu_md_req_ready_o = 0;    //  v 1
    tb->md_fu_wrb_prd_addr_o = 0;
    tb->md_fu_wrb_rob_index_o = 0;
    tb->md_fu_wrb_data_o = 0;   //  v  1
    tb->md_fu_wrb_resp_valid_o = 0;    //  v  1

    while (main_time < MAX_TIME) {
      if (main_time % 2 == 1) {
          tb->clk = 1;
      } else {
          tb->clk = 0;
      }

      switch(main_time) {
        case 2:{
          tb->rst = 1;
          break;
        }
        case 4:{ //2*3
         tb->rst = 0;
         tb->fu_md_prd_addr_i = 2;
         tb->fu_md_oprd1_i = 8;
         tb->fu_md_oprd2_i = 4;
         tb->fu_md_rob_index_i = 5;
         tb->fu_md_md_op_i = 4;
         tb->fu_md_muldiv_i = 1;
         tb->fu_md_req_valid_i = 1;
         break;
        }
        case 6:{
          tb->fu_md_req_valid_i = 0;
          break;
        }
      } 
      if(tb->md_fu_wrb_resp_valid_o== 1){
        if( !(
          tb->md_fu_wrb_prd_addr_o == 2 &&
          tb->md_fu_wrb_rob_index_o == 5 &&
          tb->md_fu_wrb_data_o == 2 &&
          tb->md_fu_wrb_resp_valid_o == 1
           )
          )
          printf("WRONG in Line 88  main_time %d\n", main_time);
        else
          printf("Pass!!!\nmain_time: %d\n ", main_time);
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
