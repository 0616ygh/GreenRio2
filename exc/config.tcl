set ::env(DESIGN_NAME) "excep_ctrl"
set ::env(DESIGN_IS_CORE) 0
set ::env(CLOCK_TREE_SYNTH) false
set ::env(CLOCK_PORT) null
set ::env(FP_CORE_UTIL) 22
set ::env(PL_TARGET_DENSITY) 0.24
set ::env(PL_RANDOM_GLB_PLACEMENT) true
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(ROUTING_CORES) 8
set ::env(GRT_ALLOW_CONGESTION) 0
set ::env(RUN_SPEF_EXTRACTION) 0
set script_dir $::env(DESIGN_DIR)
set ::env(VERILOG_FILES) "\
	$::env(DESIGN_DIR)/../params.vh \
    $::env(DESIGN_DIR)/../csr/excep_ctrl.v
	"
set ::env(LEC_ENABLE) 0
set ::env(RUN_CVC) 0
set ::env(USE_ARC_ANTENNA_CHECK) "0"
set ::env(RT_MAX_LAYER) {met4}
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