%%writefile config.tcl
set script_dir [file dirname [file normalize [info script]]]
# This makes sure that the core rings are outside the boundaries
# of your block.
set ::env(MAGIC_ZEROIZE_ORIGIN) 0
set ::env(RUN_CVC) 0
set ::unit 2.4
set ::env(FP_IO_VEXTEND) [expr 2*$::unit]
set ::env(FP_IO_HEXTEND) [expr 2*$::unit]
set ::env(FP_IO_VLENGTH) $::unit
set ::env(FP_IO_HLENGTH) $::unit
set ::env(FP_IO_VTHICKNESS_MULT) 4
set ::env(FP_IO_HTHICKNESS_MULT) 4
set ::env(FP_PDN_CORE_RING) 1
set ::env(FP_PDN_CORE_RING_VWIDTH) 3.1
set ::env(FP_PDN_CORE_RING_HWIDTH) 3.1
set ::env(FP_PDN_CORE_RING_VOFFSET) 12.45
set ::env(FP_PDN_CORE_RING_HOFFSET) $::env(FP_PDN_CORE_RING_VOFFSET)
set ::env(FP_PDN_CORE_RING_VSPACING) 1.7
set ::env(FP_PDN_CORE_RING_HSPACING) $::env(FP_PDN_CORE_RING_VSPACING)
set ::env(FP_PDN_VWIDTH) 3.1
set ::env(FP_PDN_HWIDTH) 3.1
set ::env(FP_PDN_VSPACING) [expr 5*$::env(FP_PDN_CORE_RING_VWIDTH)]
set ::env(FP_PDN_HSPACING) [expr 5*$::env(FP_PDN_CORE_RING_HWIDTH)]
set ::env(FP_PDN_VPITCH) 180
set ::env(FP_PDN_HPITCH) $::env(FP_PDN_VPITCH)
# PDN Offset 
set ::env(FP_PDN_VOFFSET) 5
set ::env(FP_PDN_HOFFSET) $::env(FP_PDN_VOFFSET)
set ::env(DESIGN_NAME) "core_top"
set ::env(DESIGN_IS_CORE) 1
# Timing configuration
set ::env(CLOCK_PERIOD) "25"
set ::env(CLOCK_PORT) "clk"
set ::env(CELL_PAD) 3
set ::env(GLB_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(ROUTING_CORES) 8
set ::env(FP_SIZING) "absolute"
set ::env(DIE_AREA) "0 0 3560 3560"
set ::env(PL_TARGET_DENSITY) 0.28
set ::env(DIODE_INSERTION_STRATEGY) 3
set ::env(SYNTH_STRATEGY) "AREA 3"
set ::env(SYNTH_MAX_FANOUT) 20
set ::env(PL_RESIZER_TIMING_OPTIMIZATIONS) 0
set ::env(RUN_SPEF_EXTRACTION) 0
set ::env(GRT_ALLOW_CONGESTION) 1
set ::env(VERILOG_FILES) "\
	  $::env(DESIGN_DIR)/../params.vh \
	  $::env(DESIGN_DIR)/../hehe_cfg.vh \
   	$::env(DESIGN_DIR)/../csr/csr_regfile.v \
    $::env(DESIGN_DIR)/../rcu/unit/counter/configurable_counter.v \
    $::env(DESIGN_DIR)/../rcu/unit/f2if2o/f2if2o.v \
	  $::env(DESIGN_DIR)/../decode/rvc_decoder.v \
    $::env(DESIGN_DIR)/../decode/rv_decoder.v \
    $::env(DESIGN_DIR)/../decode/decode.v \
	  $::env(DESIGN_DIR)/../csr/excep_ctrl.v \
  	$::env(DESIGN_DIR)/../rcu/unit/counter/counter.v \
    $::env(DESIGN_DIR)/../rcu/unit/fifo/fifo_for_freelist.v \
    $::env(DESIGN_DIR)/../fetch/btb.v \
    $::env(DESIGN_DIR)/../fetch/gshare.v \
   	$::env(DESIGN_DIR)/../fetch/ins_buffer.v \
    $::env(DESIGN_DIR)/../fetch/fetch.v \
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
    $::env(DESIGN_DIR)/../fu/alu.v \
    $::env(DESIGN_DIR)/../fu/div.v \
    $::env(DESIGN_DIR)/../fu/lowRisc_mul_fast.v \
    $::env(DESIGN_DIR)/../fu/md.v \
    $::env(DESIGN_DIR)/../fu/fu.v \
	  $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_ptw.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_tlb_arbiter.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_pmp/rvh_pmp.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_pmp/rvh_pmp_entry.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_dtlb.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_itlb.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_mmu_mshr.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_mmu.v \
    $::env(DESIGN_DIR)/../rvh_mmu_v/rvh_monolithic_mmu.v \
	  $::env(DESIGN_DIR)/../rcu/unit/physical_regfile/physical_regfile.sv \
    $::env(DESIGN_DIR)/../rcu/unit/f2if2o/f2if2o_freelist.v \
    $::env(DESIGN_DIR)/../rcu/unit/oldest2_abitter_bps/oldest2_abitter_bps.v \
    $::env(DESIGN_DIR)/../rcu/unit/oldest2_abitter_bps_lss/oldest2_abitter_bps_lss.v \
    $::env(DESIGN_DIR)/../rcu/rcu.sv \
    $::env(DESIGN_DIR)/../core.sv"
set ::env(SDC_FILE) $::env(DESIGN_DIR)/base.sdc
set ::env(LEC_ENABLE) 0
set ::env(RUN_CVC) 0
set ::env(USE_ARC_ANTENNA_CHECK) "0"
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