#include <iostream>
#include <cstring>
#include <stdio.h>
#include <vector>
#include <memory>
#include <stdlib.h>
#include "verilated_vcd_c.h"
#include "Vtb_top.h"

#define HALF_CYCLE 10

struct CORE {
    Vtb_top* logic;
    VerilatedContext* contextp;
    VerilatedVcdC* tfp;
    void reset();
    void cycle();
    void init();
    void close();
};

void CORE::init(){
    contextp = new VerilatedContext;
    logic = new Vtb_top(contextp);
    tfp = new VerilatedVcdC;
    contextp->traceEverOn(true); 
    logic->trace(tfp, 0);
    // tfp->open("core_waves.vcd");
}

void CORE::cycle(){
    contextp->timeInc(HALF_CYCLE);
    logic->clk = 0;
    logic->eval();
    tfp->dump(contextp->time());
    contextp->timeInc(HALF_CYCLE);
    logic->clk = 1;
    logic->eval();
    tfp->dump(contextp->time());
}

void CORE::reset(){
    logic->clk = 1;
    logic->rst = 1;
    logic->eval();
    int i = 0;
    while (i < 10){
        cycle();
        i++;
    }
    contextp->timeInc(HALF_CYCLE*0.5);
    logic->rst = 0;
    logic->eval();
    tfp->dump(contextp->time());
}

void CORE::close(){
    logic->final();
    delete logic;
    tfp->close();
    delete contextp;
}

int main(){   
    CORE core;
    core.init();
    core.reset();
    for(int t = 0; t < 1000000000; t++){
        if (t % 100000 == 0)
            printf("run time: %d\n", t);
        core.cycle();
    }
    core.close();
    return 0;
}