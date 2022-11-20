
# Design
set ::env(DESIGN_NAME) "fu"
set ::env(DESIGN_IS_CORE) 0
set ::env(CLOCK_PERIOD) "20"
set ::env(CLOCK_PORT) "clk"
set ::env(ROUTING_CORES) 8
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 2860 1260"
set ::env(PL_TARGET_DENSITY) 0.36
set ::env(DIODE_INSERTION_STRATEGY) 4
set ::env(SYNTH_STRATEGY) "AREA 3"
set ::env(SYNTH_MAX_FANOUT) 20
set script_dir $::env(DESIGN_DIR)
set ::env(VERILOG_FILES) "\
	$::env(DESIGN_DIR)/../params.vh \
    $::env(DESIGN_DIR)/../utils/commoncell/counter.v \
    $::env(DESIGN_DIR)/../utils/commoncell/counter2.sv \
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
    $::env(DESIGN_DIR)/../utils/commoncell/src/StdDFF/hw/DFFRE.sv \
    $::env(DESIGN_DIR)/../rcu/unit/oldest2_abitter/arbiter_base.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_agu.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_bus_ctrl.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_lsq_entry.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_lsq.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_mc.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_pma_checker.v \
    $::env(DESIGN_DIR)/../lsuv1/lsu_wb_arb.v \
    $::env(DESIGN_DIR)/../lsuv1/lsuv1.v \
    $::env(DESIGN_DIR)/../csr/csr.sv \
    $::env(DESIGN_DIR)/alu.v \
    $::env(DESIGN_DIR)/div.v \
    $::env(DESIGN_DIR)/lowRisc_mul_fast.v \
    $::env(DESIGN_DIR)/md.v \
    $::env(DESIGN_DIR)/fu.v 
	"
set ::env(SDC_FILE) $::env(DESIGN_DIR)/base.sdc
set ::env(LEC_ENABLE) 0
set ::env(RUN_CVC) 0
set ::env(USE_ARC_ANTENNA_CHECK) "0"
set ::env(RT_MAX_LAYER) {met4}
set ::env(QUIT_ON_TIMING_VIOLATIONS) "0"
set ::env(QUIT_ON_MAGIC_DRC) "0"
set ::env(QUIT_ON_LVS_ERROR) "0"
set ::env(QUIT_ON_SLEW_VIOLATIONS) "0"