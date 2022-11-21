SRC_ROOT := .
DV_ROOT := ./dv
CORE_SRC := $(shell find $(SRC_ROOT)/rcu -type f -name '*v')
CORE_SRC += $(shell find $(SRC_ROOT)/fetch -type f -name '*v')
CORE_SRC += $(shell find $(SRC_ROOT)/decode -type f -name '*v')
CORE_SRC += $(shell find $(SRC_ROOT)/fu -type f -name '*v')
CORE_SRC += $(shell find $(SRC_ROOT)/csr -type f -name '*v')
CORE_SRC += $(shell find $(SRC_ROOT)/rvh_mmu_v -type f -name '*v')
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/CountOne.sv   
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/MuxOH.sv      
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/OH2UInt.sv    
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/PLRU.sv       
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/PLRUTree.sv   
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/PriorityMux.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/StreamFIFO.sv 
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Basic/hw/SyncFIFO.sv   
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Queue/hw/AgeMatrixSelector.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Queue/hw/QueueManager.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Queue/hw/StaticPrioritySelector.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Queue/hw/FIAO/FIAOWithAgeMatrix.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Queue/hw/FIAO/FIAOWithQueueManager.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/Queue/hw/FIFO/MultiPortStreamFIFO.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/StdDFF/dv/DFFUncertainChecker.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/StdDFF/hw/DFF.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/StdDFF/hw/DFFE.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/StdDFF/hw/DFFR.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/src/StdDFF/hw/DFFRE.sv
CORE_SRC += $(SRC_ROOT)/utils/commoncell/counter2.sv
CORE_SRC += $(shell find $(SRC_ROOT)/lsuv1 -type f -name '*v') params.vh utils/commoncell/dpram64_2r1w.v core.sv

# HEX_FILE ?= $(DV_ROOT)/isa/hex/rv64ui/beq.hex
# HEX_FILE ?= $(DV_ROOT)/torture/hex/test3.hex
HEX_FILE ?= $(DV_ROOT)/benchmark/hex/aha-mont64.hex
# HEX_FILE ?= $(DV_ROOT)/benchmark/hex/coremark.hex
DEFINE := VERILATOR+DPRAM64_2R1W+SYNTHESIS+LSU_V1+HEX_DIR="\"$(HEX_FILE)\""

VERIFLAGS := -Mdir build --timescale 1ns/1ps --timescale-override 1ns/1ps --prof-cfuncs -CFLAGS -DVL_DEBUG\
		  --Wno-WIDTH --Wno-PINMISSING --Wno-VARHIDDEN --Wno-UNUSED --Wno-STMTDLY --Wno-ASSIGNDLY --Wno-EOFNEWLINE\
		  --Wno-IMPLICIT --Wno-LITENDIAN --Wno-SELRANGE --Wno-UNOPTFLAT --Wno-WIDTHCONCAT --Wno-REDEFMACRO --Wno-REALCVT --Wno-LATCH --Wno-CASEINCOMPLETE\
		  --cc --trace --exe --build +define+$(DEFINE)

verilator ?= verilator

default: verify_core

.PHONY: verify_core debug

debug:
	$(info $(CORE_SRC))

verify_core:
	$(verilator) $(VERIFLAGS) --top-module tb_top $(SRC_ROOT)/tb_top.sv $(CORE_SRC) $(DV_ROOT)/core_sim.cpp
	-build/Vtb_top

soc_waves:
	gtkwave core_waves.vcd