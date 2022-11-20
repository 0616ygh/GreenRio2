sim_log = "./logs"
dump_on = 1
RV_ROOT = $(shell pwd)/..
INCLUDE = $(shell pwd)/include
# default:
# 	vcs +vcs+lic+wait -sverilog -kdb +vc +error+10 -CC "-I$(INCLUDE)" -F "$(FLIST)"  +lint=TFIPC-L -full64 -timescale=1ns/1ps -debug_access -l bld.log

VCS_MACRO = 
VCS_PARAM =
CC_FILE =
BLD = 
VCS_MODEL_OPTS = 
CC_INC = $(shell pwd)/include
CC_FLAGS = 
LDS_FILE = 
FILE_LIST = $(RV_ROOT)/flist.f
TOP_MODULE = tb_top

.PHONY: run wave clean

simv: $(wildcard ../*.sv ../*.v)
	vcs +vcs+lic+wait -sverilog -kdb $(VCS_MACRO) $(VCS_PARAM) \
		+vc+list +vpi $(CC_FILE) \
		-CFLAGS "$(CC_INC) $(CC_FLAGS)" \
		+lint=TFIPC-L -full64 -F ${FILE_LIST} \
		-top $(TOP_MODULE) -timescale=1ns/1ps \
		-v2k_generate -debug_access+all \
		+error+10 +lint=PCWM-L

run: simv
	-mkdir $(sim_log)
	time ./simv +dumpon=$(dump_on) +sim_log=$(sim_log)  2>&1 | tee run_2_$(debug_print_on).log

default: run

wave:
	Verdi-SX -ssf ./logs/waves.fsdb

clean:
	-rm bld.log simv ucli.key waves.*
	-rm -r csrc simv.daidir logs Verdi-SXLog
	-rm *.log
	-rm novas* .nfs* 
