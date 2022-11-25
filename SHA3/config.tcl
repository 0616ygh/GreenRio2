set ::env(DESIGN_NAME) "sha3_core"
set ::env(DESIGN_IS_CORE) 1
set ::env(CLOCK_PERIOD) "40"
set ::env(CLOCK_PORT) "clk"
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(ROUTING_CORES) 48
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 15600 1600"
set ::env(PL_TARGET_DENSITY) 0.28
set ::env(DIODE_INSERTION_STRATEGY) 4
set ::env(SYNTH_STRATEGY) "AREA 0"
set ::env(SYNTH_MAX_FANOUT) 20
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(RUN_SPEF_EXTRACTION) 0
set ::env(GRT_ALLOW_CONGESTION) 1
set ::env(VERILOG_FILES) "\
         $::env(DESIGN_DIR)/../../verilog/SHA3/hdl/default_parms.v \
         $::env(DESIGN_DIR)/../../verilog/SHA3/hdl/sha3_rnd_a.v \
         $::env(DESIGN_DIR)/../../verilog/SHA3/hdl/sha3_core.v "
 set ::env(LEC_ENABLE) 0
 set ::env(RUN_CVC) 0
 set ::env(USE_ARC_ANTENNA_CHECK) "1"
 set ::env(RT_MAX_LAYER) {met5}
 set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
 set ::env(QUIT_ON_MAGIC_DRC) "0"
 set ::env(QUIT_ON_LVS_ERROR) "0"
 set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
 set ::env(RUN_KLAYOUT_XOR) "0"
 set ::env(KLAYOUT_XOR_GDS) "0"
 set ::env(KLAYOUT_XOR_XML) "0"
 set ::env(RUN_KLAYOUT) "0"
 set ::env(RUN_MAGIC_DRC) 0
 set ::env(RUN_KLAYOUT_DRC) 0