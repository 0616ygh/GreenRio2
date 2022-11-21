SRC_ROOT := ./src_new
CORE_SRC := $(shell find $(SRC_ROOT)/perips -type f -name '*.[v]') params.vh

VERIFLAGS := -Mdir build --timescale 1ns/1ps --timescale-override 1ns/1ps --prof-cfuncs -CFLAGS -DVL_DEBUG\
		  --Wno-WIDTH --Wno-PINMISSING --Wno-VARHIDDEN --Wno-UNUSED --Wno-STMTDLY --Wno-ASSIGNDLY --Wno-EOFNEWLINE\
		  --Wno-IMPLICIT --Wno-LITENDIAN --Wno-SELRANGE --Wno-UNOPTFLAT --Wno-CASEINCOMPLETE --cc --trace --exe --build +define+VERIFY_SOC

verilator = ~/verilator/bin/verilator
.PHONY: verify_core

verify_core:
	$(verilator) $(VERIFLAGS) $(DV_ROOT)/soc_ut/soc_tb.v $(CORE_SRC) $(DV_ROOT)/soc_ut/soc_sim.cpp
	-build/Vsoc_tb

soc_waves:
	gtkwave soc_waves.vcd
