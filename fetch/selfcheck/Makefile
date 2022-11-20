SRC_DIR   := $(shell pwd)/..
SIM_DIR   := $(shell pwd)
SIM_SRC := $(shell find $(SIM_DIR) -type f -name '*.cpp')
VERILATOR := /work/stu/zxluan/verilator/bin/verilator
BUILD_DIR := $(shell pwd)/build
VERILOG_SRC := $(shell find $(SRC_DIR) -type f -name '*.v')
VERILOG_SRC += $(shell find $(SRC_DIR) -type f -name '*.vh')
VERIFLAGS := $(addprefix -I,$(shell find $(SRC_DIR) -type d)) -I/work/home/zxluan/verilator/share/verilator/include -Wall -Mdir $(BUILD_DIR)

#export PATH=$PATH:/work/stu/qyang/dev/ccache-3.6/bin
#export CPLUS_INCLUDE_PATH=/work/home/zxluan/verilator/share/verilator/include:/work/stu/qyang/workspace/2tapeout/hehecore-2-0/src_new/fetch/selfcheck/build

fetch: $(VERILOG_SRC) $(SIM_SRC)
	$(VERILATOR) $(VERIFLAGS) --trace --cc --exe --build -Wno-UNUSED -LDFLAGS -lelf $(SRC_DIR)/fetch.v $(SIM_DIR)/fetch.cpp