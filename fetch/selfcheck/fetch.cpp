#include <verilated.h>
#include <verilated_vcd_c.h>

#include <iostream>

#include "Vfetch.h"

const uint64_t MAX_TIME =50;
uint64_t main_time = 0;
Vfetch *tb;

int main(int argc, char **argv, char **env) {
  Verilated::debug(0);
  Verilated::randReset(0);
  Verilated::traceEverOn(true);
  Verilated::commandArgs(argc, argv);
  tb = new Vfetch;

  // initialize input
  tb->clk = 0;
  tb->rst = 1;
  tb->branch_valid_first_i = 0;
  tb->branch_valid_second_i = 0;
  tb->btb_req_pc_i = 0x80000000;
  tb->btb_predict_target_i = 0;
  tb->prev_pc_first_i = 0;
  tb->prev_taken_first_i = 0;
  tb->prev_pc_second_i = 0;
  tb->prev_taken_second_i = 0;
  tb->real_branch_i = 0;
  tb->global_wfi_i = 0;
  tb->global_ret_i = 0;
  tb->global_trap_i = 0;
  tb->global_predict_miss_i = 0;
  tb->trap_vector_i = 0x00000000;
  tb->mret_vector_i = 0x00000000;
  tb->fetch_l1i_if_req_rdy_i = 0;
  tb->l1i_fetch_if_resp_vld_i = 0;
  // notice
  tb->l1i_fetch_if_resp_data_i = VlWide<4>();
  while (main_time < MAX_TIME) {
    if (main_time % 2 == 1) {
      tb->clk = 1;
      tb->rst = 0;
    } else {
      tb->clk = 0;
      if (main_time != 0) {
        tb->rst = 0;
      }
    }
    printf("main_time: %d==============\n", main_time);
    // if (main_time == 2) {
    //   tb->reset = 0;
    // }

    switch (main_time) {
      // 测试1：

      case 4: {
        tb->l1i_fetch_if_resp_vld_i = 1;
        tb->fetch_l1i_if_req_rdy_i = 1;
        // tb->branch_valid_first_i = 1;
        tb->btb_req_pc_i = 0x80000008;
        tb->btb_predict_target_i = 0x70000000;
        for (int i = 0; i < 4; i++)
          tb->l1i_fetch_if_resp_data_i[i] = 0xaaa3;
        break;
      }
      case 10: {
        tb->l1i_fetch_if_resp_vld_i = 1;
        tb->fetch_l1i_if_req_rdy_i = 1;
        // tb->branch_valid_first_i = 1;
        tb->btb_req_pc_i = 0x70000004;
        tb->btb_predict_target_i = 0x80000024;
        for (int i = 0; i < 4; i++)
          tb->l1i_fetch_if_resp_data_i[i] = 0xaaa0;
        break;
      }

      case 20: {
        tb->real_branch_i = 0x70000000;
        tb->branch_valid_first_i = 1;
      }
    }
    tb->eval();
    printf( 
        "main_time: %d, l1i_fetch_if_resp_data_i[0]: %x, l1i_fetch_if_resp_vld_i: %d, fetch_l1i_if_req_rdy_i: %d, \n"
        "pc_first_o: %x, next_pc_first_o: %x, predict_pc_first_o: %x, instruction_first_o: %x, is_rv_first_o: %d, is_first_valid_o: %d, \n"
        "pc_second_o: %x, next_pc_second_o: %x, predict_pc_second_o: %x, instruction_second_o: %x, is_rv_second_o: %d, is_second_valid_o: %d, \n"
        "fetch_l1i_if_req_vld_o: %d, fetch_l1i_if_req_index_o: %x, fetch_l1i_if_req_offset_o: %x, fetch_l1i_if_req_vtag_o: %x, ins_empty_o: %d\n",
        main_time, tb->l1i_fetch_if_resp_data_i[0], tb->l1i_fetch_if_resp_vld_i, tb->fetch_l1i_if_req_rdy_i, 
        tb->pc_first_o, tb->next_pc_first_o, tb->predict_pc_first_o, tb->instruction_first_o, tb->is_rv_first_o, tb->is_first_valid_o, 
        tb->pc_second_o, tb->next_pc_second_o, tb->predict_pc_second_o, tb->instruction_second_o, tb->is_rv_second_o, tb->is_second_valid_o, 
        tb->fetch_l1i_if_req_vld_o, tb->fetch_l1i_if_req_index_o, tb->fetch_l1i_if_req_offset_o, tb->fetch_l1i_if_req_vtag_o, tb->ins_empty_o);
    main_time++;
  }

  tb->final();

  delete tb;
  tb = nullptr;
  return 0;
}
