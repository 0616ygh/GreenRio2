#include <verilated.h>

#include <iostream>

#include "verilated_vcd_c.h"
#include "Vmul.h"
//#define CODING 0

const uint64_t MAX_TIME = 200;
uint64_t main_time = 0;
Vmul *tb;

void printInfo(Vmul * tb);
