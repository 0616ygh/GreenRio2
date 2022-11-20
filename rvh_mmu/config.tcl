set ::env(PDK) "sky130A"
set script_dir $::env(DESIGN_DIR)
set ::env(MAGIC_ZEROIZE_ORIGIN) 0
set ::env(FP_CORE_UTIL) 30
set ::env(PL_TARGET_DENSITY) 0.34
set ::env(DESIGN_NAME) rvh_monolithic_mmu
set ::env(VERILOG_FILES) "\
    $::env(DESIGN_DIR)/../params.vh \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/CountOne.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/MuxOH.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/OH2UInt.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/PLRU.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/PLRUTree.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/PriorityMux.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/StreamFIFO.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Basic/hw/SyncFIFO.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Queue/hw/AgeMatrixSelector.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Queue/hw/QueueManager.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Queue/hw/StaticPrioritySelector.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Queue/hw/FIAO/FIAOWithAgeMatrix.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Queue/hw/FIAO/FIAOWithQueueManager.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/Queue/hw/FIFO/MultiPortStreamFIFO.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/StdDFF/dv/DFFUncertainChecker.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/StdDFF/hw/DFF.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/StdDFF/hw/DFFE.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/StdDFF/hw/DFFR.v \
    $::env(DESIGN_DIR)/../utils/commoncell/src/StdDFF/hw/DFFRE.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_ptw.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_tlb_arbiter.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_pmp/rvh_pmp.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_pmp/rvh_pmp_entry.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_dtlb.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_itlb.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_mmu_mshr.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_mmu.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_monolithic_mmu.v 
    "
## Clock configurations
set ::env(CLOCK_PORT) "clk"
set ::env(CLOCK_PERIOD) "25"
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
