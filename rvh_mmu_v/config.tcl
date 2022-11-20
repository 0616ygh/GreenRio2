set ::env(PDK) "sky130A"
set script_dir $::env(DESIGN_DIR)
set ::env(MAGIC_ZEROIZE_ORIGIN) 0
set ::env(FP_SIZING) absolute
set ::env(DIE_AREA) "0 0 1920 1920"
set ::env(PL_TARGET_DENSITY) 0.36
set ::env(DESIGN_NAME) rvh_monolithic_mmu
set ::env(VERILOG_FILES) "\
$script_dir/rvh_dtlb.v \
$script_dir/rvh_itlb.v \
$script_dir/rvh_mmu.v \
$script_dir/rvh_mmu_mshr.v \
$script_dir/rvh_monolithic_mmu.v \
$script_dir/rvh_ptw.v \
$script_dir/rvh_pmp/rvh_pmp.v \
$script_dir/rvh_pmp/rvh_pmp_entry.v \
$script_dir/../utils/commoncell/src/Queue/hw/QueueManager.v \
$script_dir/../utils/commoncell/src/Basic/hw/PLRU.v \
$script_dir/../utils/commoncell/src/Basic/hw/OH2UInt.v \
$script_dir/../utils/commoncell/src/StdDFF/hw/DFF.v \
$script_dir/../utils/commoncell/src/StdDFF/hw/DFFE.v \
$script_dir/../utils/commoncell/src/StdDFF/hw/DFFR.v \
$script_dir/../utils/commoncell/src/StdDFF/hw/DFFRE.v \
"
## Clock configurations
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "12.5"
set ::env(RT_MAX_LAYER) {met4}
set ::env(FP_PDN_CHECK_NODES) 0
set ::env(PL_RESIZER_DESIGN_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(PL_RESIZER_BUFFER_INPUT_PORTS) 0
set ::env(PL_RESIZER_BUFFER_OUTPUT_PORTS) 0
set ::env(FP_PDN_ENABLE_RAILS) 0
set ::env(DIODE_INSERTION_STRATEGY) 3
set ::env(FILL_INSERTION) 1
set ::env(TAP_DECAP_INSERTION) 1
set ::env(CLOCK_TREE_SYNTH) 0
set ::env(QUIT_ON_LVS_ERROR) "0"
set ::env(QUIT_ON_MAGIC_DRC) "0"
set ::env(QUIT_ON_NEGATIVE_WNS) "0"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"
set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
set ::env(ROUTING_CORES) "52"
set ::env(LVS_CONNECT_BY_LABEL) "1"
set ::env(YOSYS_REWRITE_VERILOG) "1"
set ::env(RUN_KLAYOUT_XOR) "0"
set ::env(KLAYOUT_XOR_GDS) "0"
set ::env(KLAYOUT_XOR_XML) "0"
set ::env(RUN_KLAYOUT) "0"
set ::env(RUN_MAGIC_DRC) 1
set ::env(RUN_KLAYOUT_DRC) 0
